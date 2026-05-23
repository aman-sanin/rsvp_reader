//! Tokenization of normalized text into RSVP‑ready word tokens.

use crate::core::text::{is_word_char, normalize_display_text};

/// Represents a single token (word or punctuation) ready for RSVP display.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Token {
    pub text: String,
}

/// Tokenizes a line of normalized text into a sequence of RSVP tokens.
/// The input should already be normalized (e.g., via `normalize_display_text`).
///
/// Rules:
/// - Words are split by whitespace and punctuation boundaries.
/// - Hyphens inside a word are kept as part of the word (e.g., "state-of-the-art").
/// - Standalone hyphens become a single "-" token.
/// - Ellipsis "..." becomes a single token "...".
/// - Tokens with no readable characters (e.g., "----") are skipped.
pub fn tokenize_line(line: &str) -> Vec<Token> {
    let line = normalize_display_text(line);
    let mut tokens = Vec::new();
    let mut current = String::new();
    let mut pending_hyphen = false;
    let chars: Vec<char> = line.chars().collect();
    let mut i = 0;

    while i < chars.len() {
        let c = chars[i];

        // Word boundary (space or punctuation that separates words)
        if is_word_boundary(c) {
            flush_current(&mut current, &mut pending_hyphen, &mut tokens);
            i += 1;
            continue;
        }

        // Handle hyphens: inline vs standalone
        if c == '-' {
            // Check if this hyphen is inside a word (inline)
            if is_inline_hyphen(&chars, i) {
                current.push(c);
                i += 1;
                continue;
            }

            // Standalone hyphen (or series of hyphens)
            flush_current(&mut current, &mut pending_hyphen, &mut tokens);
            let mut hyphen_count = 0;
            while i < chars.len() && chars[i] == '-' {
                hyphen_count += 1;
                i += 1;
            }
            // Emit a single "-" token if any hyphens were found
            if hyphen_count > 0 {
                // Check if we already have a pending hyphen token from a previous dash?
                // For simplicity, emit one token per run.
                // But rsvpnano would emit just "-". We'll follow that.
                push_token("-", &mut tokens);
            }
            continue;
        }

        // Handle ellipsis: three or more dots in a row
        if c == '.' && i + 2 < chars.len() && chars[i + 1] == '.' && chars[i + 2] == '.' {
            flush_current(&mut current, &mut pending_hyphen, &mut tokens);
            let mut dot_count = 0;
            while i < chars.len() && chars[i] == '.' {
                dot_count += 1;
                i += 1;
            }
            if dot_count >= 3 {
                push_token("...", &mut tokens);
                // Skip any extra dots? They're already consumed.
            } else {
                // Less than three dots: treat as punctuation? But ellipsis is only for 3+.
                // For completeness, we could push a single '.' token per dot, but that's rare.
                // We'll just ignore them; they'll be picked up as word boundary later.
            }
            continue;
        }

        // Regular character: accumulate into current token
        current.push(c);
        i += 1;
    }

    flush_current(&mut current, &mut pending_hyphen, &mut tokens);
    tokens
}

/// Returns true if the character is a word boundary (i.e., should separate tokens).
/// This includes whitespace and punctuation except hyphens and apostrophes inside words.
fn is_word_boundary(c: char) -> bool {
    c.is_whitespace()
        || matches!(
            c,
            '.' | ','
                | ';'
                | ':'
                | '!'
                | '?'
                | '"'
                | '\''
                | '('
                | ')'
                | '['
                | ']'
                | '{'
                | '}'
                | '/'
                | '\\'
                | '_'
                | '|'
                | '@'
                | '#'
                | '$'
                | '%'
                | '^'
                | '&'
                | '*'
                | '+'
                | '='
                | '<'
                | '>'
        )
}

/// Determines if a hyphen at position `i` in the character slice is part of a word
/// (inline hyphen) or a standalone separator.
/// Example: "well-known" -> hyphen between 'l' and 'k' -> inline -> true.
/// Example: "- " -> standalone -> false.
fn is_inline_hyphen(chars: &[char], i: usize) -> bool {
    if chars[i] != '-' {
        return false;
    }
    // Needs at least one character before and after
    if i == 0 || i + 1 >= chars.len() {
        return false;
    }
    let prev = chars[i - 1];
    let next = chars[i + 1];
    // Hyphen is inline if both sides are word characters (letters/digits) and they are not hyphens themselves.
    is_word_char(prev) && is_word_char(next)
}

/// Flushes the accumulated `current` token, handling ellipsis and hyphen tokens correctly.
/// The `pending_hyphen` flag is not used in this simplified version (we emit standalone hyphens immediately).
fn flush_current(current: &mut String, _pending_hyphen: &mut bool, tokens: &mut Vec<Token>) {
    if current.is_empty() {
        return;
    }

    // Clean up: trim (though shouldn't be needed)
    let trimmed = current.trim();
    if trimmed.is_empty() {
        current.clear();
        return;
    }

    // Check if the token is a pure ellipsis token (three or more dots)
    if trimmed.chars().all(|c| c == '.') && trimmed.len() >= 3 {
        push_token("...", tokens);
        current.clear();
        return;
    }

    // Check if token is a pure hyphen token (one or more hyphens)
    if trimmed.chars().all(|c| c == '-') {
        push_token("-", tokens);
        current.clear();
        return;
    }

    // Normal token: push as is
    push_token(trimmed, tokens);
    current.clear();
}

/// Adds a token to the list only if it has at least one readable character (letter/digit)
/// or it's a standalone rhythm token (like "-").
fn push_token(text: &str, tokens: &mut Vec<Token>) {
    let trimmed = text.trim();
    if trimmed.is_empty() {
        return;
    }

    // Check if token has any alphanumeric character
    let has_readable = trimmed.chars().any(|c| c.is_alphanumeric());
    // Check if it's a standalone hyphen or ellipsis
    let is_rhythm = trimmed == "-" || trimmed == "...";
    if has_readable || is_rhythm {
        tokens.push(Token {
            text: trimmed.to_string(),
        });
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn text(s: &str) -> Vec<String> {
        tokenize_line(s).into_iter().map(|t| t.text).collect()
    }

    #[test]
    fn test_simple_words() {
        assert_eq!(text("Hello world"), vec!["Hello", "world"]);
        assert_eq!(text("This is a test."), vec!["This", "is", "a", "test."]);
    }

    #[test]
    fn test_punctuation() {
        // Period attached to word stays with word.
        assert_eq!(text("Hello."), vec!["Hello."]);
        // Comma attached.
        assert_eq!(text("Hello, world"), vec!["Hello,", "world"]);
    }

    #[test]
    fn test_inline_hyphen() {
        assert_eq!(text("state-of-the-art"), vec!["state-of-the-art"]);
        assert_eq!(text("well-known"), vec!["well-known"]);
        // Standalone hyphen should become a token.
        assert_eq!(text("- "), vec!["-"]);
        assert_eq!(text(" - hello"), vec!["-", "hello"]);
    }

    #[test]
    fn test_ellipsis() {
        assert_eq!(text("And... then"), vec!["And...", "then"]);
        assert_eq!(text("One... two..."), vec!["One...", "two..."]);
        // Should not split inside a word.
        assert_eq!(text("dot..dot"), vec!["dot..dot"]);
    }

    #[test]
    fn test_multiple_hyphens() {
        // Multiple hyphens in a row become a single "-" token (rsvpnano behavior).
        assert_eq!(text("-- hello"), vec!["-", "hello"]);
        assert_eq!(text("---"), vec!["-"]);
    }

    #[test]
    fn test_skipping_rhythm_only() {
        // Tokens with only punctuation but not hyphen or ellipsis are skipped.
        assert_eq!(text("!!!"), Vec::<String>::new());
        assert_eq!(text("???"), Vec::<String>::new());
        assert_eq!(text("..."), vec!["..."]);
        assert_eq!(text("---"), vec!["-"]);
    }
}
