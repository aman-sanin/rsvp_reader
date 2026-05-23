//! Core RSVP logic: text processing, pacing, reading loop, book parsing, and indexing.

pub mod book_parser;
pub mod epub_converter;
pub mod indexed_store;
pub mod pacing;
pub mod reading_loop;
pub mod rsvp_writer;
pub mod text;
pub mod tokenizer;

// Re-export commonly used types
pub use book_parser::{parse_rsvp_file, BookContent};
pub use indexed_store::IndexedBookStore;
pub use pacing::PacingConfig;
pub use reading_loop::{ReadingLoop, WordSource};
