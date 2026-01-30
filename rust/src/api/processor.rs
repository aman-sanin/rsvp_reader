use anyhow::{Context, Result};
use flutter_rust_bridge::frb;
use std::fs;
use std::path::Path;

// Import our new modules
use crate::logic::rsvp;
use crate::parsers::{epub, pdf};

// The struct exposed to Dart
#[frb(dart_metadata=("freezed"))]
pub struct RsvpWord {
    pub left: String,
    pub center: String,
    pub right: String,
    pub delay_factor: f32,
}

pub fn read_file_content(path: String) -> Result<String> {
    let file_path = Path::new(&path);
    let extension = file_path
        .extension()
        .and_then(|e| e.to_str())
        .unwrap_or("")
        .to_lowercase();

    println!("RUST: Dispatching file: {}", path);

    match extension.as_str() {
        "txt" => fs::read_to_string(file_path).context("Could not read TXT"),
        "pdf" => pdf::parse_pdf(file_path),
        "epub" => epub::parse_epub(file_path),
        _ => Err(anyhow::anyhow!("Unsupported format: .{}", extension)),
    }
}

pub fn parse_text_to_rsvp(text: String) -> Vec<RsvpWord> {
    // Call the pure logic module
    let internal_words = rsvp::convert_text_to_rsvp(text);

    // Convert internal struct to API struct (Dart-compatible)
    internal_words
        .into_iter()
        .map(|w| RsvpWord {
            left: w.left,
            center: w.center,
            right: w.right,
            delay_factor: w.delay,
        })
        .collect()
}
