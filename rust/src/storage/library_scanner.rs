//! Library scanner – finds books in a directory and extracts basic metadata.

use crate::core::text::normalize_display_text;
use flutter_rust_bridge::frb;
use std::fs;
use std::io::{BufRead, BufReader};
use std::path::Path;

/// Information about a book (or article) in the library.
#[frb(non_opaque)]
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct BookInfo {
    /// Full path to the file (as a String for FFI).
    pub path: String,
    /// Display title (cleaned).
    pub title: String,
    /// Author (if known).
    pub author: String,
    /// File size in bytes.
    pub size_bytes: u64,
    /// Type of book: "rsvp", "txt", or "epub".
    pub file_type: String,
    /// Category: "book" or "article".
    pub category: String,
    /// Progress percentage (0-100) if previously read, else None.
    pub progress_percent: Option<u8>,
}

/// Scans a directory recursively for supported book files.
pub fn scan_library(root: &Path) -> Vec<BookInfo> {
    let mut books = Vec::new();
    if !root.exists() || !root.is_dir() {
        return books;
    }
    walk_directory(root, &mut books);
    books.sort_by(|a, b| a.title.to_lowercase().cmp(&b.title.to_lowercase()));
    books
}

fn walk_directory(dir: &Path, out: &mut Vec<BookInfo>) {
    if let Ok(entries) = fs::read_dir(dir) {
        for entry in entries.flatten() {
            let path = entry.path();
            if let Some(name) = path.file_name().and_then(|n| n.to_str()) {
                if name.starts_with('.') {
                    continue;
                }
            }
            if path.is_dir() {
                walk_directory(&path, out);
            } else if is_supported_file(&path) {
                if let Some(info) = extract_book_info(&path) {
                    out.push(info);
                }
            }
        }
    }
}

fn is_supported_file(path: &Path) -> bool {
    path.extension()
        .and_then(|ext| ext.to_str())
        .map(|ext| matches!(ext.to_lowercase().as_str(), "rsvp" | "txt" | "epub"))
        .unwrap_or(false)
}

fn extract_book_info(path: &Path) -> Option<BookInfo> {
    let metadata = fs::metadata(path).ok()?;
    let size_bytes = metadata.len();
    let extension = path.extension().and_then(|e| e.to_str()).unwrap_or("");
    let file_type = extension.to_lowercase();

    let (title, author) = if file_type == "rsvp" {
        read_rsvp_metadata(path)
    } else {
        let name = path
            .file_stem()
            .unwrap_or_default()
            .to_string_lossy()
            .to_string();
        (name, String::new())
    };

    Some(BookInfo {
        path: path.to_string_lossy().to_string(),
        title: normalize_display_text(&title),
        author,
        size_bytes,
        file_type,
        category: infer_category(path),
        progress_percent: None,
    })
}

fn read_rsvp_metadata(path: &Path) -> (String, String) {
    let file = match fs::File::open(path) {
        Ok(f) => f,
        Err(_) => return (String::new(), String::new()),
    };
    let reader = BufReader::new(file);
    let mut title = String::new();
    let mut author = String::new();
    let mut lines_read = 0;

    for line in reader.lines().take(30) {
        let line = match line {
            Ok(l) => l,
            Err(_) => break,
        };
        lines_read += 1;
        let trimmed = line.trim();
        if trimmed.is_empty() {
            continue;
        }
        if trimmed.starts_with("@title") {
            title = trimmed[6..].trim().to_string();
        } else if trimmed.starts_with("@author") {
            author = trimmed[7..].trim().to_string();
        } else if !trimmed.starts_with('@') && lines_read > 5 {
            break;
        }
        if !title.is_empty() && !author.is_empty() {
            break;
        }
    }

    if title.is_empty() {
        title = path
            .file_stem()
            .unwrap_or_default()
            .to_string_lossy()
            .to_string();
    }
    (title, author)
}

fn infer_category(path: &Path) -> String {
    let path_str = path.to_string_lossy();
    if path_str.contains("/books/books/") {
        "book".to_string()
    } else if path_str.contains("/books/articles/") {
        "article".to_string()
    } else {
        String::new()
    }
}
