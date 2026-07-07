//! Parser for RSVP (.rsvp) files. Produces in‑memory book content.

use std::fs::File;
use std::io::{BufRead, BufReader};
use std::path::Path;

use crate::core::text::normalize_display_text;
use crate::core::tokenizer::tokenize_line;

/// Metadata and word list for a book.
#[derive(Debug, Default, Clone)]
pub struct BookContent {
    pub title: String,
    pub author: String,
    pub words: Vec<String>,
    pub chapters: Vec<(usize, String)>, // (word_index, title)
    pub paragraph_starts: Vec<usize>,
}

/// Errors that can occur during parsing.
#[derive(Debug, thiserror::Error)]
pub enum ParseError {
    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),
    #[error("Invalid RSVP format: {0}")]
    InvalidFormat(String),
    #[error("No words found")]
    NoWords,
}

pub type Result<T> = std::result::Result<T, ParseError>;

/// Parse an RSVP file into a `BookContent`.
pub fn parse_rsvp_file(path: &Path) -> Result<BookContent> {
    let file = File::open(path)?;
    let reader = BufReader::new(file);
    let mut content = BookContent::default();

    let mut line_buffer = String::new();
    let mut paragraph_pending = true;
    let mut in_paragraph = false;
    let mut last_was_empty = false;

    for line_result in reader.lines() {
        let line = line_result?;
        let trimmed = line.trim();

        // Handle empty lines
        if trimmed.is_empty() {
            if in_paragraph {
                // End of current paragraph
                flush_line_buffer(&mut line_buffer, &mut content, &mut in_paragraph)?;
            }
            paragraph_pending = true;
            last_was_empty = true;
            continue;
        }

        // RSVP directives
        if trimmed.starts_with('@') {
            // Before processing directive, flush any pending line
            if in_paragraph {
                flush_line_buffer(&mut line_buffer, &mut content, &mut in_paragraph)?;
            }

            let directive = trimmed;
            if directive.starts_with("@rsvp") {
                // version check – ignore
            } else if directive.starts_with("@title") {
                content.title = normalize_display_text(&directive[6..].trim());
            } else if directive.starts_with("@author") {
                content.author = normalize_display_text(&directive[7..].trim());
            } else if directive.starts_with("@chapter") {
                let title = normalize_display_text(&directive[8..].trim());
                let word_idx = content.words.len();
                content.chapters.push((word_idx, title));
                paragraph_pending = true;
            } else if directive.starts_with("@para") {
                // Force a paragraph break
                if in_paragraph {
                    flush_line_buffer(&mut line_buffer, &mut content, &mut in_paragraph)?;
                }
                paragraph_pending = true;
            } else if directive.starts_with("@@") {
                // Legacy paragraph marker: treat as regular text but with forced break
                if in_paragraph {
                    flush_line_buffer(&mut line_buffer, &mut content, &mut in_paragraph)?;
                }
                paragraph_pending = true;
                let rest = &directive[1..]; // remove one '@' – the other is part of the text
                process_text_line(
                    rest,
                    &mut line_buffer,
                    &mut content,
                    &mut in_paragraph,
                    &mut paragraph_pending,
                )?;
            } else {
                // Unknown directive – ignore
            }
            last_was_empty = false;
            continue;
        }

        // Regular text line
        process_text_line(
            &line,
            &mut line_buffer,
            &mut content,
            &mut in_paragraph,
            &mut paragraph_pending,
        )?;
        last_was_empty = false;
    }

    // Flush remaining line buffer
    if in_paragraph {
        flush_line_buffer(&mut line_buffer, &mut content, &mut in_paragraph)?;
    }

    if content.words.is_empty() {
        return Err(ParseError::NoWords);
    }

    // Ensure at least one paragraph start
    if content.paragraph_starts.is_empty() {
        content.paragraph_starts.push(0);
    }

    Ok(content)
}

/// Process a line of text: tokenize and add to the line buffer, possibly flushing.
fn process_text_line(
    line: &str,
    line_buffer: &mut String,
    content: &mut BookContent,
    in_paragraph: &mut bool,
    paragraph_pending: &mut bool,
) -> Result<()> {
    let normalized = normalize_display_text(line);
    if normalized.is_empty() {
        return Ok(());
    }

    if *paragraph_pending {
        // Start a new paragraph
        let word_len = content.words.len();
        if content.paragraph_starts.is_empty() {
            content.paragraph_starts.push(0);
        } else if content.paragraph_starts.last() != Some(&word_len) {
            content.paragraph_starts.push(word_len);
        }
        *paragraph_pending = false;
        *in_paragraph = true;
    }

    // Append to line buffer (adding a space if not empty)
    if !line_buffer.is_empty() && !line_buffer.ends_with(' ') {
        line_buffer.push(' ');
    }
    line_buffer.push_str(&normalized);

    // If buffer is long, flush to words
    if line_buffer.len() > 200 {
        flush_line_buffer(line_buffer, content, in_paragraph)?;
    }

    Ok(())
}

/// Flush the line buffer: tokenise and append words.
fn flush_line_buffer(
    line_buffer: &mut String,
    content: &mut BookContent,
    in_paragraph: &mut bool,
) -> Result<()> {
    if line_buffer.is_empty() {
        return Ok(());
    }

    let tokens = tokenize_line(line_buffer);
    for token in tokens {
        // Skip tokens that are only punctuation and not a sentence‑ending ellipsis or dash
        if token.text.chars().all(|c| !c.is_alphanumeric())
            && token.text != "..."
            && token.text != "-"
        {
            continue;
        }
        content.words.push(token.text);
    }

    line_buffer.clear();
    *in_paragraph = false; // after flushing, we are between paragraphs
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::io::Write;
    use tempfile::NamedTempFile;

    fn write_temp_rsvp(content: &str) -> NamedTempFile {
        let mut file = NamedTempFile::new().unwrap();
        write!(file, "{}", content).unwrap();
        file
    }

    #[test]
    fn test_parse_simple() {
        let file = write_temp_rsvp(
            "@rsvp 1\n\
             @title My Book\n\
             @author Me\n\
             \n\
             Hello world. This is a test.\n\
             \n\
             @chapter First Chapter\n\
             Another paragraph.",
        );
        let book = parse_rsvp_file(file.path()).unwrap();
        assert_eq!(book.title, "My Book");
        assert_eq!(book.author, "Me");
        assert_eq!(
            book.words,
            vec![
                "Hello",
                "world.",
                "This",
                "is",
                "a",
                "test.",
                "Another",
                "paragraph."
            ]
        );
        assert_eq!(book.chapters.len(), 1);
        assert_eq!(book.chapters[0].1, "First Chapter");
        assert_eq!(book.chapters[0].0, 6); // word index after first paragraph
        assert_eq!(book.paragraph_starts, vec![0, 6]);
    }

    #[test]
    fn test_no_words_returns_error() {
        let file = write_temp_rsvp("@rsvp 1\n@title Empty\n\n");
        let result = parse_rsvp_file(file.path());
        assert!(matches!(result, Err(ParseError::NoWords)));
    }

    #[test]
    fn test_tokenisation() {
        let file = write_temp_rsvp("Hello, world! This is a test...");
        let book = parse_rsvp_file(file.path()).unwrap();
        assert_eq!(
            book.words,
            vec!["Hello,", "world!", "This", "is", "a", "test..."]
        );
    }
}
