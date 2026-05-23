//! FFI functions for library management.

use flutter_rust_bridge::frb;
use once_cell::sync::Lazy;
use std::path::{Path, PathBuf};
use std::sync::Mutex;

use crate::core::epub_converter::convert_epub_to_rsvp;
use crate::storage::book_cache::BookCache;
use crate::storage::library_scanner::{scan_library, BookInfo};
use crate::storage::progress_store::{ProgressEntry, ProgressStore};

static BOOK_CACHE: Lazy<Mutex<Option<BookCache>>> = Lazy::new(|| Mutex::new(None));
static PROGRESS_STORE: Lazy<Mutex<Option<ProgressStore>>> = Lazy::new(|| Mutex::new(None));
static CACHE_PATH: Lazy<Mutex<Option<PathBuf>>> = Lazy::new(|| Mutex::new(None));
static PROGRESS_PATH: Lazy<Mutex<Option<PathBuf>>> = Lazy::new(|| Mutex::new(None));

#[frb]
pub fn init_library(cache_file: String, progress_file: String) -> Result<(), String> {
    let cache_path = PathBuf::from(cache_file);
    let progress_path = PathBuf::from(progress_file);

    let cache = BookCache::load(&cache_path).map_err(|e| format!("Failed to load cache: {}", e))?;
    let progress = ProgressStore::load(&progress_path)
        .map_err(|e| format!("Failed to load progress: {}", e))?;

    *BOOK_CACHE.lock().unwrap() = Some(cache);
    *PROGRESS_STORE.lock().unwrap() = Some(progress);
    *CACHE_PATH.lock().unwrap() = Some(cache_path);
    *PROGRESS_PATH.lock().unwrap() = Some(progress_path);
    Ok(())
}

#[frb]
pub fn get_library(root_dir: String) -> Vec<BookInfo> {
    let root = Path::new(&root_dir);
    let mut books = scan_library(root);

    if let Some(progress) = PROGRESS_STORE.lock().unwrap().as_ref() {
        for book in &mut books {
            if let Some(entry) = progress.get(&book.path) {
                let percent = if entry.word_count > 0 {
                    ((entry.word_index * 100) / entry.word_count) as u8
                } else {
                    0
                };
                book.progress_percent = Some(percent);
            }
        }
    }
    books
}

#[frb]
pub fn save_progress(
    book_path: String,
    word_index: usize,
    word_count: usize,
) -> Result<(), String> {
    let mut guard = PROGRESS_STORE.lock().unwrap();
    let progress = guard.as_mut().ok_or("Progress store not initialised")?;
    progress.set(book_path, word_index, word_count);
    if let Some(progress_path) = PROGRESS_PATH.lock().unwrap().as_ref() {
        progress
            .save(progress_path)
            .map_err(|e| format!("Failed to save progress: {}", e))?;
    }
    Ok(())
}

#[frb]
pub fn get_progress(book_path: String) -> Option<ProgressEntry> {
    let guard = PROGRESS_STORE.lock().unwrap();
    guard.as_ref().and_then(|p| p.get(&book_path)).cloned()
}

#[frb]
pub fn delete_book(book_path: String) -> Result<(), String> {
    let path = Path::new(&book_path);
    if !path.exists() {
        return Err("Book does not exist".to_string());
    }
    std::fs::remove_file(path).map_err(|e| format!("Failed to delete file: {}", e))?;

    if let Some(cache) = BOOK_CACHE.lock().unwrap().as_mut() {
        cache.remove(&book_path);
        if let Some(cache_path) = CACHE_PATH.lock().unwrap().as_ref() {
            cache
                .save(cache_path)
                .map_err(|e| format!("Failed to save cache: {}", e))?;
        }
    }
    if let Some(progress) = PROGRESS_STORE.lock().unwrap().as_mut() {
        progress.remove(&book_path);
        if let Some(progress_path) = PROGRESS_PATH.lock().unwrap().as_ref() {
            progress
                .save(progress_path)
                .map_err(|e| format!("Failed to save progress: {}", e))?;
        }
    }
    Ok(())
}

#[frb]
pub fn convert_epub(epub_path: String, max_words: usize) -> Result<String, String> {
    let epub_path = PathBuf::from(&epub_path);
    if !epub_path.exists() || epub_path.extension().and_then(|e| e.to_str()) != Some("epub") {
        return Err("Invalid EPUB file".to_string());
    }
    let rsvp_path = epub_path.with_extension("rsvp");
    let result = convert_epub_to_rsvp(&epub_path, &rsvp_path, max_words, None);
    match result {
        Ok(_) => Ok(rsvp_path.to_string_lossy().to_string()),
        Err(e) => Err(format!("Conversion failed: {}", e)),
    }
}

#[frb]
pub fn refresh_cache(root_dir: String) -> Result<(), String> {
    let root = Path::new(&root_dir);
    let books = scan_library(root);
    let mut cache_guard = BOOK_CACHE.lock().unwrap();
    let cache = cache_guard.as_mut().ok_or("Cache not initialised")?;
    cache
        .update_from_scan(&books)
        .map_err(|e| format!("Cache update failed: {}", e))?;
    if let Some(cache_path) = CACHE_PATH.lock().unwrap().as_ref() {
        cache
            .save(cache_path)
            .map_err(|e| format!("Failed to save cache: {}", e))?;
    }
    Ok(())
}
