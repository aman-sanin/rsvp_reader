//! Word pacing calculations for RSVP.
//! Implements length bonus, complexity bonus, punctuation pause, and final duration.

use crate::core::text::{
    approximate_syllable_groups, is_abbreviation, is_lowercase, is_uppercase, is_vowel,
    readable_character_count, to_lowercase, uppercase_letter_count,
};

// -----------------------------------------------------------------------------
// Constants (from ReadingLoop.cpp)
// -----------------------------------------------------------------------------

// Length bonus tiers
const LONG_WORD_AFTER_CHARS: usize = 6;
const LONG_WORD_PERCENT_PER_CHAR: u16 = 6;
const VERY_LONG_WORD_AFTER_CHARS: usize = 10;
const VERY_LONG_WORD_PERCENT_PER_CHAR: u16 = 9;
const ULTRA_LONG_WORD_AFTER_CHARS: usize = 14;
const ULTRA_LONG_WORD_PERCENT_PER_CHAR: u16 = 12;
const LONG_WORD_MAX_PERCENT: u16 = 170;

// Compound word bonus
const COMPOUND_JOINER_PERCENT: u16 = 14;
const LONG_COMPOUND_WORD_PERCENT: u16 = 18;
const TECHNICAL_CONNECTOR_PERCENT: u16 = 8;

// Syllable complexity
const SYLLABLE_BONUS_AFTER_COUNT: usize = 2;
const SYLLABLE_BONUS_PERCENT_PER_GROUP: u16 = 10;
const SYLLABLE_BONUS_MAX_PERCENT: u16 = 50;

// All-caps complexity
const ALL_CAPS_COMPLEXITY_PERCENT: u16 = 14;
const MIXED_TOKEN_COMPLEXITY_PERCENT: u16 = 22;
const NUMERIC_TOKEN_COMPLEXITY_PERCENT: u16 = 10;
const DENSE_CONNECTOR_COMPLEXITY_PERCENT: u16 = 12;
const COMPLEX_WORD_MAX_PERCENT: u16 = 85;

// Punctuation pauses
const COMMA_PAUSE_PERCENT: u16 = 45;
const DASH_PAUSE_PERCENT: u16 = 60;
const CLAUSE_PAUSE_PERCENT: u16 = 80;
const ELLIPSIS_PAUSE_PERCENT: u16 = 110;
const SENTENCE_PAUSE_PERCENT: u16 = 135;
const STRONG_SENTENCE_PAUSE_PERCENT: u16 = 150;

// Pacing delay limits
const MAX_PACING_DELAY_MS: u16 = 600;

// -----------------------------------------------------------------------------
// PacingConfig
// -----------------------------------------------------------------------------

/// Configuration for word pacing delays and scaling factors.
#[derive(Debug, Clone, Copy)]
pub struct PacingConfig {
    pub long_word_delay_ms: u16,
    pub complex_word_delay_ms: u16,
    pub punctuation_delay_ms: u16,
    pub long_word_scale_percent: u8,
    pub complex_word_scale_percent: u8,
    pub punctuation_scale_percent: u8,
}

impl Default for PacingConfig {
    fn default() -> Self {
        Self {
            long_word_delay_ms: 200,
            complex_word_delay_ms: 200,
            punctuation_delay_ms: 200,
            long_word_scale_percent: 100,
            complex_word_scale_percent: 100,
            punctuation_scale_percent: 100,
        }
    }
}

impl PacingConfig {
    /// Clamps all delay values to the valid range [0, MAX_PACING_DELAY_MS].
    pub fn clamp_delays(&mut self) {
        self.long_word_delay_ms = self.long_word_delay_ms.min(MAX_PACING_DELAY_MS);
        self.complex_word_delay_ms = self.complex_word_delay_ms.min(MAX_PACING_DELAY_MS);
        self.punctuation_delay_ms = self.punctuation_delay_ms.min(MAX_PACING_DELAY_MS);
    }

    /// Clamps scaling percentages to at least 25 (minimum effective scale).
    pub fn clamp_scales(&mut self) {
        self.long_word_scale_percent = self.long_word_scale_percent.max(25);
        self.complex_word_scale_percent = self.complex_word_scale_percent.max(25);
        self.punctuation_scale_percent = self.punctuation_scale_percent.max(25);
    }
}

// -----------------------------------------------------------------------------
// Helper functions
// -----------------------------------------------------------------------------

/// Scales a base percent by a scaling factor (clamped to at least 25).
fn scale_percent(base_percent: u16, scale_percent: u8) -> u16 {
    let scale = scale_percent.max(25) as u32;
    (base_percent as u32 * scale / 100) as u16
}

/// Scales a delay value (clamped) and applies a bonus percent.
fn scaled_delay_ms(bonus_percent: u16, delay_ms: u16) -> u32 {
    let delay = delay_ms.min(MAX_PACING_DELAY_MS) as u32;
    delay * bonus_percent as u32 / 100
}

// -----------------------------------------------------------------------------
// Length bonus
// -----------------------------------------------------------------------------

/// Computes the length‑based bonus percent for a word.
/// Based on number of readable characters and compound/technical connectors.
fn length_bonus_percent(word: &str) -> u16 {
    let readable_len = readable_character_count(word);
    if readable_len == 0 {
        return 0;
    }

    let mut bonus = 0;

    // Tier 1: long words
    if readable_len > LONG_WORD_AFTER_CHARS {
        let extra = (readable_len - LONG_WORD_AFTER_CHARS) as u16;
        bonus += extra * LONG_WORD_PERCENT_PER_CHAR;
    }

    // Tier 2: very long words
    if readable_len > VERY_LONG_WORD_AFTER_CHARS {
        let extra = (readable_len - VERY_LONG_WORD_AFTER_CHARS) as u16;
        bonus += extra * VERY_LONG_WORD_PERCENT_PER_CHAR;
    }

    // Tier 3: ultra long words
    if readable_len > ULTRA_LONG_WORD_AFTER_CHARS {
        let extra = (readable_len - ULTRA_LONG_WORD_AFTER_CHARS) as u16;
        bonus += extra * ULTRA_LONG_WORD_PERCENT_PER_CHAR;
    }

    // Compound word joiners (e.g., hyphens between word chars)
    let joiner_count = compound_joiner_count(word);
    if joiner_count > 0 {
        bonus += joiner_count as u16 * COMPOUND_JOINER_PERCENT;
        if readable_len >= VERY_LONG_WORD_AFTER_CHARS {
            bonus += LONG_COMPOUND_WORD_PERCENT;
        }
    }

    // Technical connectors (e.g., slashes, dots inside words)
    let tech_connector_count = technical_connector_count(word);
    if tech_connector_count > joiner_count {
        bonus += (tech_connector_count - joiner_count) as u16 * TECHNICAL_CONNECTOR_PERCENT;
    }

    bonus.min(LONG_WORD_MAX_PERCENT)
}

/// Counts characters that are segment separators (hyphen, slash, underscore) inside a word.
fn compound_joiner_count(word: &str) -> usize {
    let chars: Vec<char> = word.chars().collect();
    let mut count = 0;
    for i in 1..chars.len() - 1 {
        let c = chars[i];
        if matches!(c, '-' | '/' | '_') {
            // Check if surrounded by word characters
            if is_word_char(chars[i - 1]) && is_word_char(chars[i + 1]) {
                count += 1;
            }
        }
    }
    count
}

/// Counts technical connectors (e.g., hyphens, slashes, dots, plus, backslash) inside a word.
fn technical_connector_count(word: &str) -> usize {
    let chars: Vec<char> = word.chars().collect();
    let mut count = 0;
    for i in 1..chars.len() - 1 {
        let c = chars[i];
        if matches!(c, '-' | '/' | '_' | '.' | '+' | '\\') {
            if is_word_char(chars[i - 1]) && is_word_char(chars[i + 1]) {
                count += 1;
            }
        }
    }
    count
}

/// Returns true if the character is considered a word character (for connector detection).
fn is_word_char(c: char) -> bool {
    c.is_alphanumeric()
}

// -----------------------------------------------------------------------------
// Complexity bonus
// -----------------------------------------------------------------------------

/// Computes the complexity‑based bonus percent for a word.
/// Factors: syllable groups, mixed alphanumeric, all-caps, dense connectors.
fn complexity_bonus_percent(word: &str) -> u16 {
    let mut bonus = 0;

    // Syllable groups
    let syllable_groups = approximate_syllable_groups(word);
    if syllable_groups > SYLLABLE_BONUS_AFTER_COUNT {
        let extra_groups = syllable_groups - SYLLABLE_BONUS_AFTER_COUNT;
        let add = (extra_groups as u16 * SYLLABLE_BONUS_PERCENT_PER_GROUP)
            .min(SYLLABLE_BONUS_MAX_PERCENT);
        bonus += add;
    }

    // Mixed alphanumeric (letters + digits)
    let has_letters = word.chars().any(|c| c.is_alphabetic());
    let has_digits = word.chars().any(|c| c.is_numeric());
    if has_letters && has_digits {
        bonus += MIXED_TOKEN_COMPLEXITY_PERCENT;
    } else if digit_count(word) >= 3 {
        bonus += NUMERIC_TOKEN_COMPLEXITY_PERCENT;
    }

    // All-caps word (all letters uppercase)
    let letter_count = word.chars().filter(|c| c.is_alphabetic()).count();
    let uppercase_count = uppercase_letter_count(word);
    if letter_count >= 2 && uppercase_count == letter_count {
        bonus += ALL_CAPS_COMPLEXITY_PERCENT;
    }

    // Dense technical connectors (>= 2 connectors)
    let tech_count = technical_connector_count(word);
    if tech_count >= 2 {
        bonus += (tech_count as u16 - 1) * DENSE_CONNECTOR_COMPLEXITY_PERCENT;
    }

    bonus.min(COMPLEX_WORD_MAX_PERCENT)
}

/// Counts the number of digit characters in a word.
fn digit_count(word: &str) -> usize {
    word.chars().filter(|c| c.is_numeric()).count()
}

// -----------------------------------------------------------------------------
// Punctuation pause
// -----------------------------------------------------------------------------

/// Computes the punctuation‑based pause percent for a word.
/// Depends on the last meaningful character and whether the next word starts lowercase.
fn punctuation_pause_percent(word: &str, next_starts_lowercase: bool) -> u16 {
    if word.is_empty() {
        return 0;
    }

    // Check for ellipsis
    if word.ends_with("...") {
        return ELLIPSIS_PAUSE_PERCENT;
    }

    // Find last meaningful character (ignore trailing quotes, brackets)
    let last_char = last_meaningful_char(word);
    match last_char {
        ',' => COMMA_PAUSE_PERCENT,
        '-' => DASH_PAUSE_PERCENT,
        ';' | ':' => CLAUSE_PAUSE_PERCENT,
        '.' => {
            if !is_abbreviation(word, next_starts_lowercase) {
                SENTENCE_PAUSE_PERCENT
            } else {
                0
            }
        }
        '!' | '?' => STRONG_SENTENCE_PAUSE_PERCENT,
        _ => 0,
    }
}

/// Returns the last meaningful character of a word, ignoring trailing quotes, brackets, etc.
fn last_meaningful_char(word: &str) -> char {
    let mut chars: Vec<char> = word.chars().collect();
    while let Some(&last) = chars.last() {
        if matches!(last, '"' | '\'' | ')' | ']' | '}') {
            chars.pop();
        } else {
            break;
        }
    }
    chars.last().copied().unwrap_or('\0')
}

// -----------------------------------------------------------------------------
// Combined bonus and duration
// -----------------------------------------------------------------------------

/// Computes the total pacing bonus (in milliseconds) for a word.
pub fn pacing_bonus_ms(word: &str, next_starts_lowercase: bool, config: &PacingConfig) -> u32 {
    if word.is_empty() {
        return 0;
    }

    let length_bonus = scale_percent(length_bonus_percent(word), config.long_word_scale_percent);
    let complexity_bonus = scale_percent(
        complexity_bonus_percent(word),
        config.complex_word_scale_percent,
    );
    let punctuation_bonus = scale_percent(
        punctuation_pause_percent(word, next_starts_lowercase),
        config.punctuation_scale_percent,
    );

    scaled_delay_ms(length_bonus, config.long_word_delay_ms)
        + scaled_delay_ms(complexity_bonus, config.complex_word_delay_ms)
        + scaled_delay_ms(punctuation_bonus, config.punctuation_delay_ms)
}

/// Returns the base interval between words (in milliseconds) for a given WPM.
pub fn word_interval_ms(wpm: u16) -> u32 {
    if wpm == 0 {
        return 0;
    }
    60_000 / wpm as u32
}

/// Computes the total display duration for a word (base interval + pacing bonus).
pub fn word_duration_ms(
    word: &str,
    next_starts_lowercase: bool,
    wpm: u16,
    config: &PacingConfig,
) -> u32 {
    let base = word_interval_ms(wpm);
    if base == 0 {
        return 0;
    }
    base + pacing_bonus_ms(word, next_starts_lowercase, config)
}

// -----------------------------------------------------------------------------
// Tests (ported from rsvpnano test_pacing.cpp)
// -----------------------------------------------------------------------------

#[cfg(test)]
mod tests {
    use super::*;

    fn config() -> PacingConfig {
        PacingConfig::default()
    }

    #[test]
    fn test_word_interval() {
        assert_eq!(word_interval_ms(300), 200);
        assert_eq!(word_interval_ms(600), 100);
    }

    #[test]
    fn test_short_word_no_bonus() {
        let dur = word_duration_ms("a", false, 300, &config());
        assert_eq!(dur, 200);
    }

    #[test]
    fn test_comma_pause() {
        let dur = word_duration_ms("hi,", false, 300, &config());
        // base 200 + 45% of 200 = 200 + 90 = 290
        assert_eq!(dur, 290);
    }

    #[test]
    fn test_sentence_pause() {
        // "done." next uppercase -> sentence pause 135%
        let dur = word_duration_ms("done.", false, 300, &config());
        assert_eq!(dur, 470); // 200 + 270
    }

    #[test]
    fn test_strong_sentence_pause() {
        let dur = word_duration_ms("yes!", false, 300, &config());
        assert_eq!(dur, 500); // 200 + 300
    }

    #[test]
    fn test_abbreviation_suppresses_sentence_pause() {
        let dur = word_duration_ms("Mr.", true, 300, &config());
        assert_eq!(dur, 200);
    }

    #[test]
    fn test_long_word_bonus() {
        let dur = word_duration_ms("strength", false, 300, &config());
        // length bonus 12% -> 200 + 24 = 224
        assert_eq!(dur, 224);
    }

    #[test]
    fn test_all_caps_complexity() {
        let dur = word_duration_ms("NASA", false, 300, &config());
        // all-caps +14% -> 200 + 28 = 228
        assert_eq!(dur, 228);
    }

    #[test]
    fn test_compound_word_bonus() {
        let dur = word_duration_ms("well-known", false, 300, &config());
        // length 9 -> 18% + joiner 14% = 32% -> 200 + 64 = 264
        assert_eq!(dur, 264);
    }
}
