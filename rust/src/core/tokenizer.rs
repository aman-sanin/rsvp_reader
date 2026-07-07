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
    let chars: Vec<char> = line.chars().collect();
    let mut i = 0;

    while i < chars.len() {
        let c = chars[i];

        // 1. Handle ellipsis: three or more dots in a row
        if c == '.' && i + 2 < chars.len() && chars[i + 1] == '.' && chars[i + 2] == '.' {
            let mut dot_count = 0;
            while i < chars.len() && chars[i] == '.' {
                dot_count += 1;
                i += 1;
            }
            if dot_count >= 3 {
                if !current.is_empty() {
                    current.push_str("...");
                    flush_current(&mut current, &mut tokens);
                } else {
                    push_token("...", &mut tokens);
                }
            }
            continue;
        }

        // 2. Handle hyphens: inline vs standalone
        if c == '-' {
            if is_inline_hyphen(&chars, i) {
                current.push(c);
                i += 1;
                continue;
            }

            // Standalone hyphen or sequence of hyphens
            flush_current(&mut current, &mut tokens);
            while i < chars.len() && chars[i] == '-' {
                i += 1;
            }
            push_token("-", &mut tokens);
            continue;
        }

        // 3. Handle whitespace: word boundary
        if c.is_whitespace() {
            flush_current(&mut current, &mut tokens);
            i += 1;
            continue;
        }

        // 4. Handle special punctuation boundaries
        if is_special_punctuation(c) {
            // Trailing punctuation attached to the end of a word is preserved (e.g., "Hello.")
            if !current.is_empty() && (c == '.' || c == ',' || c == '!' || c == '?' || c == ';' || c == ':') {
                current.push(c);
                i += 1;
                continue;
            } else {
                flush_current(&mut current, &mut tokens);
                i += 1;
                continue;
            }
        }

        // 5. Regular character: accumulate into current token
        current.push(c);
        i += 1;
    }

    flush_current(&mut current, &mut tokens);
    tokens
}

/// Returns true if the character is a special punctuation boundary.
fn is_special_punctuation(c: char) -> bool {
    matches!(
        c,
        '.' | ','
            | ';'
            | ':'
            | '!'
            | '?'
            | '"'
            | '('
            | ')'
            | '['
            | ']'
            | '{'
            | '}'
            | '/'
            | '\\'
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

/// Flushes the accumulated `current` token.
fn flush_current(current: &mut String, tokens: &mut Vec<Token>) {
    if current.is_empty() {
        return;
    }

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
