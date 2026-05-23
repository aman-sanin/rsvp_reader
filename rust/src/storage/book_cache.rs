//! Persistent cache for book metadata (title, author, size, mtime).

use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::fs;
use std::io;
use std::path::{Path, PathBuf};

use super::library_scanner::BookInfo;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CachedBook {
    pub title: String,
    pub author: String,
    pub size_bytes: u64,
    pub modified_secs: u64,
    pub file_type: String,
}

#[derive(Debug, Default, Serialize, Deserialize)]
pub struct BookCache {
    map: HashMap<String, CachedBook>, // key is path as String
}

impl BookCache {
    pub fn load(path: &Path) -> io::Result<Self> {
        match fs::read_to_string(path) {
            Ok(data) => {
                let map = serde_json::from_str(&data)?;
                Ok(BookCache { map })
            }
            Err(e) if e.kind() == io::ErrorKind::NotFound => Ok(BookCache::default()),
            Err(e) => Err(e),
        }
    }

    pub fn save(&self, path: &Path) -> io::Result<()> {
        let data = serde_json::to_string_pretty(self)?;
        fs::write(path, data)
    }

    pub fn get(&self, path: &str) -> Option<CachedBook> {
        self.map.get(path).cloned().and_then(|cached| {
            let p = Path::new(path);
            fs::metadata(p).ok().and_then(|meta| {
                let mtime = meta.modified().ok()?;
                let mtime_secs = mtime.duration_since(std::time::UNIX_EPOCH).ok()?.as_secs();
                if mtime_secs == cached.modified_secs && meta.len() == cached.size_bytes {
                    Some(cached)
                } else {
                    None
                }
            })
        })
    }

    pub fn insert(&mut self, path: String, cached: CachedBook) {
        self.map.insert(path, cached);
    }

    pub fn remove(&mut self, path: &str) {
        self.map.remove(path);
    }

    pub fn update_from_scan(&mut self, scan_results: &[BookInfo]) -> io::Result<()> {
        for book in scan_results {
            let path = Path::new(&book.path);
            let metadata = fs::metadata(path)?;
            let mtime = metadata.modified().unwrap_or(std::time::UNIX_EPOCH);
            let mtime_secs = mtime
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap_or_default()
                .as_secs();

            let fresh = self.get(&book.path).is_some();
            if !fresh {
                let cached = CachedBook {
                    title: book.title.clone(),
                    author: book.author.clone(),
                    size_bytes: metadata.len(),
                    modified_secs: mtime_secs,
                    file_type: book.file_type.clone(),
                };
                self.insert(book.path.clone(), cached);
            }
        }
        self.map.retain(|path_str, _| Path::new(path_str).exists());
        Ok(())
    }

    pub fn iter(&self) -> impl Iterator<Item = (&String, &CachedBook)> {
        self.map.iter()
    }
}
