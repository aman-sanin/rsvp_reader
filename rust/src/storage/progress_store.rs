//! Persistent store for reading progress per book.

use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::fs;
use std::io;
use std::path::{Path, PathBuf};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProgressEntry {
    pub word_index: usize,
    pub word_count: usize,
    pub updated_at: u64,
}

#[derive(Debug, Default, Serialize, Deserialize)]
pub struct ProgressStore {
    map: HashMap<String, ProgressEntry>,
}

impl ProgressStore {
    pub fn load(path: &Path) -> io::Result<Self> {
        match fs::read_to_string(path) {
            Ok(data) => {
                let map = serde_json::from_str(&data)?;
                Ok(ProgressStore { map })
            }
            Err(e) if e.kind() == io::ErrorKind::NotFound => Ok(ProgressStore::default()),
            Err(e) => Err(e),
        }
    }

    pub fn save(&self, path: &Path) -> io::Result<()> {
        let data = serde_json::to_string_pretty(self)?;
        fs::write(path, data)
    }

    pub fn get(&self, book_path: &str) -> Option<&ProgressEntry> {
        self.map.get(book_path)
    }

    pub fn set(&mut self, book_path: String, word_index: usize, word_count: usize) {
        let updated_at = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap_or_default()
            .as_secs();
        let entry = ProgressEntry {
            word_index,
            word_count,
            updated_at,
        };
        self.map.insert(book_path, entry);
    }

    pub fn remove(&mut self, book_path: &str) {
        self.map.remove(book_path);
    }

    pub fn sorted_by_recent(&self) -> Vec<(&String, &ProgressEntry)> {
        let mut entries: Vec<_> = self.map.iter().collect();
        entries.sort_by(|a, b| b.1.updated_at.cmp(&a.1.updated_at));
        entries
    }

    pub fn prune(&mut self, existing_paths: &[String]) {
        self.map.retain(|path, _| existing_paths.contains(path));
    }
}
