// rust/src/api/processor.rs
use anyhow::{Context, Result};
use flutter_rust_bridge::frb;
use std::fs;
use std::path::Path;

// 1. THE DATA CONTRACT
#[frb(dart_metadata=("freezed"))]
pub struct RsvpWord {
    pub left: String,
    pub center: String,
    pub right: String,
    pub delay_factor: f32,
}

// 2. THE FILE READER
pub fn read_file_content(path: String) -> Result<String> {
    let file_path = Path::new(&path);
    let extension = file_path
        .extension()
        .and_then(|e| e.to_str())
        .unwrap_or("")
        .to_lowercase();

    match extension.as_str() {
        "txt" => fs::read_to_string(file_path).context("Could not read TXT"),
        "pdf" => {
            let bytes = fs::read(file_path)?;
            pdf_extract::extract_text_from_mem(&bytes)
                .map_err(|e| anyhow::anyhow!("PDF Error: {:?}", e))
        }
        "epub" => read_epub_file(file_path),
        _ => Err(anyhow::anyhow!("Unsupported format: .{}", extension)),
    }
}

// Helper for EPUBs
fn read_epub_file(path: &Path) -> Result<String> {
    let mut doc =
        epub::doc::EpubDoc::new(path).map_err(|e| anyhow::anyhow!("EPUB Error: {}", e))?;

    let mut full_text = String::new();

    // FIX: go_next() returns bool, so we check it directly
    // We use a do-while style logic or simply iterate
    // doc.get_current_str() gives the first chapter immediately

    loop {
        // FIX: get_current_str returns Option<(String, String)> -> (Mime, Content)
        if let Some((_mime, content)) = doc.get_current_str() {
            let clean = content.replace("<p>", "\n").replace("</p>", "");
            let clean = clean
                .chars()
                .filter(|c| *c != '<' && *c != '>')
                .collect::<String>();
            full_text.push_str(&clean);
            full_text.push(' ');
        }

        if !doc.go_next() {
            break;
        }
    }
    Ok(full_text)
}

// 3. THE SEGMENTATION LOGIC
pub fn parse_text_to_rsvp(text: String) -> Vec<RsvpWord> {
    // 1. DE-HYPHENATION (The Fix)
    // We look for a hyphen followed by a newline (Unix or Windows style)
    // and replace it with an empty string to merge the parts.
    let text_merged = text
        .replace("-\r\n", "") // Windows line break
        .replace("-\n", ""); // Unix/Linux line break

    // 2. STANDARD CLEANUP
    // Now we treat remaining hyphens as "hard" hyphens (like "long-term")
    // and ensure they split into two frames.
    let clean_text = text_merged.replace("-", "- ").replace("—", " — ");

    clean_text
        .split_whitespace()
        .map(|word| {
            let len = word.chars().count();

            // --- PIVOT LOGIC (Same as before) ---
            let pivot_idx = if len == 1 {
                0
            } else {
                (len as f32 * 0.35).floor() as usize
            };
            let pivot_idx = pivot_idx.min(len.saturating_sub(1));

            let chars: Vec<char> = word.chars().collect();
            let left: String = chars[..pivot_idx].iter().collect();
            let center: String = chars[pivot_idx].to_string();
            let right: String = chars[pivot_idx + 1..].iter().collect();

            // --- DELAY LOGIC (Same as before) ---
            let mut delay = 1.0;

            if word.ends_with('.') || word.ends_with('!') || word.ends_with('?') {
                delay = 2.0;
            } else if word.ends_with(',')
                || word.ends_with(':')
                || word.ends_with(';')
                || word.ends_with('-')
                || word == "—"
            {
                delay = 1.5;
            } else if len > 10 {
                delay = 1.3;
            }

            RsvpWord {
                left,
                center,
                right,
                delay_factor: delay,
            }
        })
        .collect()
}
