//! Character handling and text normalization for RSVP.
//! All logic is Unicode‑aware and uses standard Rust string operations.

/// Checks if a character is considered a "word character" for RSVP tokenization.
/// This includes letters, digits, apostrophe, and hyphen (inside words).
pub fn is_word_char(c: char) -> bool {
    c.is_alphanumeric() || c == '\'' || c == '-' || c == '_'
}

/// Checks if a character is a letter (Unicode category Letter).
pub fn is_letter(c: char) -> bool {
    c.is_alphabetic()
}

/// Checks if a character is a digit (Unicode category Number).
pub fn is_digit(c: char) -> bool {
    c.is_numeric()
}

/// Returns true if the character is uppercase (Unicode).
pub fn is_uppercase(c: char) -> bool {
    c.is_uppercase()
}

/// Returns true if the character is lowercase (Unicode).
pub fn is_lowercase(c: char) -> bool {
    c.is_lowercase()
}

/// Returns the lowercase version of a character.
pub fn to_lowercase(c: char) -> char {
    c.to_lowercase().next().unwrap_or(c)
}

/// Simple vowel detection for English-like words (a, e, i, o, u, and y when it sounds like a vowel).
/// For RSVP complexity, we only need basic vowels.
pub fn is_vowel(c: char) -> bool {
    match c.to_ascii_lowercase() {
        'a' | 'e' | 'i' | 'o' | 'u' | 'y' => true,
        _ => false,
    }
}

/// Normalizes display text:
/// - Trims leading/trailing whitespace
/// - Replaces multiple whitespace characters with a single space
/// - Replaces common Unicode punctuation with ASCII equivalents
/// - Removes zero‑width spaces and other invisible characters
pub fn normalize_display_text(text: &str) -> String {
    let mut result = String::with_capacity(text.len());
    let mut last_was_space = false;
    let mut chars = text.chars().peekable();

    while let Some(c) = chars.next() {
        // Skip zero‑width and other invisible characters
        if c == '\u{200B}' || c == '\u{FEFF}' || c == '\u{00AD}' {
            continue;
        }

        // Replace various dash/quote characters
        let normalized = match c {
            ' ' | '\u{00A0}' => ' ', // non‑breaking spaces
            '—' | '–' | '‐' | '‑' => '-',
            '‘' | '’' | '‚' | '‛' => '\'',
            '“' | '”' | '„' | '‟' => '"',
            '…' => '.', // ellipsis becomes single dot; tokenizer will handle "..."
            _ => c,
        };

        if normalized.is_whitespace() {
            if !last_was_space {
                result.push(' ');
                last_was_space = true;
            }
        } else {
            result.push(normalized);
            last_was_space = false;
        }
    }

    // Remove trailing space if any
    if result.ends_with(' ') {
        result.pop();
    }

    result
}

/// Heuristic to detect if a word ending with '.' is likely an abbreviation.
/// Used to avoid false sentence breaks.
pub fn is_abbreviation(word: &str, next_word_starts_lowercase: bool) -> bool {
    let trimmed = word.trim();
    if !trimmed.ends_with('.') {
        return false;
    }

    // Known common abbreviations (could be extended)
    let known = [
        "mr.", "mrs.", "ms.", "dr.", "prof.", "sr.", "jr.", "st.", "vs.", "etc.",
        "e.g.", "i.e.", "cf.", "no.", "fig.", "eq.", "inc.", "ltd.", "co.", "dept.",
        "mt.", "ft.",
    ];
    let lower = trimmed.to_lowercase();
    if known.contains(&lower.as_str()) {
        return true;
    }

    // Short word (≤ 4 characters) followed by lowercase – likely abbreviation
    let chars: Vec<char> = trimmed.chars().collect();
    let letter_count = chars.iter().filter(|c| c.is_alphabetic()).count();
    if letter_count <= 4 && next_word_starts_lowercase {
        return true;
    }

    // Initialism like "U.S.A." – contains dots between letters
    if trimmed.matches('.').count() >= 2 {
        let without_dots: String = trimmed.chars().filter(|&c| c != '.').collect();
        if without_dots.chars().all(|c| c.is_alphabetic()) {
            return true;
        }
    }

    false
}

/// Counts the number of readable characters (letters and digits) in a word.
pub fn readable_character_count(word: &str) -> usize {
    word.chars().filter(|c| c.is_alphanumeric()).count()
}

/// Counts the number of uppercase letters in a word.
pub fn uppercase_letter_count(word: &str) -> usize {
    word.chars().filter(|c| c.is_uppercase()).count()
}

/// Approximates the number of syllable groups in a word (very crude).
/// Used for complexity bonus.
pub fn approximate_syllable_groups(word: &str) -> usize {
    let word_lower = word.to_lowercase();
    let mut groups = 0;
    let mut previous_vowel = false;
    for c in word_lower.chars() {
        if is_vowel(c) && !previous_vowel {
            groups += 1;
            previous_vowel = true;
        } else if !is_vowel(c) {
            previous_vowel = false;
        }
    }
    // Minimum 1 group if any letters
    if groups == 0 && word_lower.chars().any(|c| c.is_alphabetic()) {
        groups = 1;
    }
    groups
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_word_char() {
        assert!(is_word_char('a'));
        assert!(is_word_char('Z'));
        assert!(is_word_char('3'));
        assert!(is_word_char('\''));
        assert!(is_word_char('-'));
        assert!(!is_word_char(' '));
        assert!(!is_word_char('.'));
    }

    #[test]
    fn test_normalize() {
        assert_eq!(normalize_display_text("  Hello   world  "), "Hello world");
        assert_eq!(normalize_display_text("Hello—world"), "Hello-world");
        assert_eq!(normalize_display_text("“Quote”"), "\"Quote\"");
        assert_eq!(normalize_display_text("A\u{00A0}B"), "A B");
    }

    #[test]
    fn test_abbreviation() {
        assert!(is_abbreviation("Mr.", true));
        assert!(is_abbreviation("e.g.", false));
        assert!(is_abbreviation("U.S.A.", true));
        assert!(!is_abbreviation("Hello.", true));
        assert!(!is_abbreviation("Dr.", false)); // next uppercase, so not abbreviation
    }

    #[test]
    fn test_syllable_groups() {
        assert_eq!(approximate_syllable_groups("hello"), 2);
        assert_eq!(approximate_syllable_groups("strength"), 1);
        assert_eq!(approximate_syllable_groups("information"), 4);
        assert_eq!(approximate_syllable_groups("a"), 1);
    }
}
