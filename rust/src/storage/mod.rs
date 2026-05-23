//! Storage module – library scanning and book cache.

pub mod library_scanner;
pub mod book_cache;
pub mod progress_store;

// Re‑export commonly used types.
pub use library_scanner::BookInfo;
