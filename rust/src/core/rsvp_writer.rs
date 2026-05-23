//! RSVP file writer – handles line wrapping, directives, and word limits.

use std::io::{Write, Result};
use std::cmp::min;

const WRAP_WIDTH: usize = 96;

pub struct RsvpWriter<W: Write> {
    writer: W,
    word_count: usize,
    max_words: usize,
    line_buffer: String,
    reached_limit: bool,
}

impl<W: Write> RsvpWriter<W> {
    pub fn new(writer: W, max_words: usize) -> Self {
        Self {
            writer,
            word_count: 0,
            max_words,
            line_buffer: String::with_capacity(WRAP_WIDTH + 32),
            reached_limit: false,
        }
    }

    /// Writes a single word (or punctuation token) to the output, respecting line width.
    pub fn write_word(&mut self, word: &str) -> Result<bool> {
        if self.reached_limit {
            return Ok(false);
        }
        if word.is_empty() {
            return Ok(true);
        }
        // Trim whitespace
        let trimmed = word.trim();
        if trimmed.is_empty() {
            return Ok(true);
        }

        // Check if we've reached the word limit
        if self.max_words > 0 && self.word_count >= self.max_words {
            self.flush_line()?;
            self.reached_limit = true;
            return Ok(false);
        }

        // Check if adding this word would exceed line width
        let new_len = if self.line_buffer.is_empty() {
            trimmed.len()
        } else {
            self.line_buffer.len() + 1 + trimmed.len()
        };
        if new_len > WRAP_WIDTH {
            self.flush_line()?;
        }

        // Append to line buffer
        if !self.line_buffer.is_empty() {
            self.line_buffer.push(' ');
        }
        self.line_buffer.push_str(trimmed);
        self.word_count += 1;
        Ok(true)
    }

    /// Flushes the current line buffer to the writer.
    fn flush_line(&mut self) -> Result<()> {
        if !self.line_buffer.is_empty() {
            // If the line starts with '@', we need to output it literally, but the writer should not add an extra '@'
            // Actually, the original code does: if line starts with '@', it prints '@' separately? No, it writes the line as is.
            // We'll just write the line.
            writeln!(self.writer, "{}", self.line_buffer)?;
            self.line_buffer.clear();
        }
        Ok(())
    }

    /// Writes a chapter marker.
    pub fn write_chapter(&mut self, title: &str) -> Result<()> {
        self.flush_line()?;
        // Clean title: remove extra spaces, maybe truncate
        let clean = title.trim();
        if !clean.is_empty() {
            writeln!(self.writer, "@chapter {}", clean)?;
        }
        Ok(())
    }

    /// Writes a paragraph break.
    pub fn write_paragraph(&mut self) -> Result<()> {
        self.flush_line()?;
        writeln!(self.writer, "@para")?;
        Ok(())
    }

    /// Writes the RSVP header (version, title, author, source).
    pub fn write_header(&mut self, title: &str, author: &str, source_path: &str) -> Result<()> {
        writeln!(self.writer, "@rsvp 1")?;
        if !title.is_empty() {
            writeln!(self.writer, "@title {}", title)?;
        }
        if !author.is_empty() {
            writeln!(self.writer, "@author {}", author)?;
        }
        if !source_path.is_empty() {
            writeln!(self.writer, "@source {}", source_path)?;
        }
        writeln!(self.writer)?;
        Ok(())
    }

    /// Finishes writing (flushes remaining line).
    pub fn finish(&mut self) -> Result<()> {
        self.flush_line()
    }

    /// Returns current word count.
    pub fn word_count(&self) -> usize { self.word_count }
    pub fn reached_limit(&self) -> bool { self.reached_limit }
}
