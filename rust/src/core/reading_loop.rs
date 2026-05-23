//! RSVP reading loop state machine.

use crate::core::pacing::{word_duration_ms, word_interval_ms, PacingConfig};
use crate::core::text::is_abbreviation;
use std::time::Duration;

/// Provides access to words for the reading loop.
pub trait WordSource: Send + Sync {
    fn word_count(&self) -> usize;
    fn word_at(&self, index: usize) -> String;
    fn prefetch_around(&self, _index: usize) {}
}

/// In-memory word source (for demos or small books).
pub struct DemoWordSource {
    words: Vec<String>,
}

impl DemoWordSource {
    pub fn new(words: Vec<String>) -> Self {
        Self { words }
    }
}

impl WordSource for DemoWordSource {
    fn word_count(&self) -> usize {
        self.words.len()
    }
    fn word_at(&self, index: usize) -> String {
        self.words.get(index).cloned().unwrap_or_default()
    }
}

/// The main RSVP state machine.
pub struct ReadingLoop {
    word_source: Box<dyn WordSource>,
    current_index: usize,
    wpm: u16,
    pacing_config: PacingConfig,
    last_advance_time: Option<Duration>,
    paused: bool,
    current_word: String,
}

impl ReadingLoop {
    pub fn new(word_source: Box<dyn WordSource>) -> Self {
        let mut this = Self {
            word_source,
            current_index: 0,
            wpm: 300,
            pacing_config: PacingConfig::default(),
            last_advance_time: None,
            paused: true,
            current_word: String::new(),
        };
        this.set_current_word_from_index();
        this
    }

    pub fn start(&mut self, now: Duration) {
        self.paused = false;
        self.last_advance_time = Some(now);
    }

    pub fn pause(&mut self) {
        self.paused = true;
    }

    pub fn update(&mut self, now: Duration) -> bool {
        if self.paused || self.word_source.word_count() == 0 {
            return false;
        }
        let last = match self.last_advance_time {
            Some(t) => t,
            None => {
                self.last_advance_time = Some(now);
                return false;
            }
        };
        let next_lowercase = self.next_word_starts_lowercase(self.current_index);
        let duration_ms = word_duration_ms(
            &self.current_word,
            next_lowercase,
            self.wpm,
            &self.pacing_config,
        );
        let elapsed = now.as_millis() as u64 - last.as_millis() as u64;
        if elapsed >= duration_ms as u64 {
            let next_index = self.current_index + 1;
            if next_index < self.word_source.word_count() {
                self.current_index = next_index;
                self.set_current_word_from_index();
                self.last_advance_time = Some(last + Duration::from_millis(duration_ms as u64));
                self.word_source.prefetch_around(self.current_index);
                return true;
            } else {
                self.paused = true;
                return false;
            }
        }
        false
    }

    pub fn seek_to(&mut self, index: usize) {
        let count = self.word_source.word_count();
        if count == 0 {
            return;
        }
        self.current_index = index.min(count - 1);
        self.set_current_word_from_index();
        self.word_source.prefetch_around(self.current_index);
        self.last_advance_time = None;
    }

    pub fn scrub(&mut self, steps: i32) {
        let count = self.word_source.word_count();
        if count == 0 {
            return;
        }
        let new_index = self.current_index as i32 + steps;
        self.current_index = new_index.clamp(0, (count - 1) as i32) as usize;
        self.set_current_word_from_index();
        self.word_source.prefetch_around(self.current_index);
        self.last_advance_time = None;
    }

    pub fn rewind_sentence(&mut self) {
        let count = self.word_source.word_count();
        if count == 0 {
            return;
        }
        let start = self.sentence_start_at_or_before(self.current_index);
        if start == self.current_index && self.current_index > 0 {
            self.seek_to(self.sentence_start_at_or_before(self.current_index - 1));
        } else {
            self.seek_to(start);
        }
    }

    pub fn adjust_wpm(&mut self, delta: i32) {
        if delta == 0 {
            return;
        }
        let mut new_wpm = self.wpm as i32;
        if delta > 0 {
            new_wpm += if new_wpm < 100 { 10 } else { 25 };
            if new_wpm > 100 && self.wpm < 100 {
                new_wpm = 100;
            }
        } else {
            new_wpm -= if new_wpm <= 100 { 10 } else { 25 };
            if new_wpm < 100 && self.wpm > 100 {
                new_wpm = 100;
            }
        }
        self.wpm = new_wpm.clamp(10, 1000) as u16;
    }

    pub fn set_wpm(&mut self, wpm: u16) {
        self.wpm = wpm.clamp(10, 1000);
    }

    pub fn set_pacing_config(&mut self, config: PacingConfig) {
        self.pacing_config = config;
    }

    pub fn current_word(&self) -> &str {
        &self.current_word
    }

    pub fn current_index(&self) -> usize {
        self.current_index
    }

    pub fn word_count(&self) -> usize {
        self.word_source.word_count()
    }

    pub fn wpm(&self) -> u16 {
        self.wpm
    }

    pub fn word_interval_ms(&self) -> u32 {
        word_interval_ms(self.wpm)
    }

    pub fn current_word_duration_ms(&self) -> u32 {
        let next_lowercase = self.next_word_starts_lowercase(self.current_index);
        word_duration_ms(
            &self.current_word,
            next_lowercase,
            self.wpm,
            &self.pacing_config,
        )
    }

    pub fn word_pacing_bonus_ms_at(&self, index: usize) -> u32 {
        if index >= self.word_source.word_count() {
            return 0;
        }
        let word = self.word_at(index);
        let next_lowercase = self.next_word_starts_lowercase(index);
        crate::core::pacing::pacing_bonus_ms(&word, next_lowercase, &self.pacing_config)
    }

    pub fn current_word_ends_sentence(&self) -> bool {
        self.word_ends_sentence_at(self.current_index)
    }

    pub fn at_end(&self) -> bool {
        self.word_source.word_count() == 0
            || self.current_index + 1 >= self.word_source.word_count()
    }

    // Private helpers
    fn word_at(&self, index: usize) -> String {
        if index < self.word_source.word_count() {
            self.word_source.word_at(index)
        } else {
            String::new()
        }
    }

    fn set_current_word_from_index(&mut self) {
        if self.word_count() == 0 {
            self.current_word.clear();
            return;
        }
        self.word_source.prefetch_around(self.current_index);
        self.current_word = self.word_at(self.current_index);
    }

    fn next_word_starts_lowercase(&self, index: usize) -> bool {
        let next = index + 1;
        if next >= self.word_source.word_count() {
            return false;
        }
        let next_word = self.word_at(next);
        next_word
            .chars()
            .next()
            .map(|c| c.is_lowercase())
            .unwrap_or(false)
    }

    fn word_ends_sentence_at(&self, index: usize) -> bool {
        let word = self.word_at(index);
        if word.is_empty() {
            return false;
        }
        let last_char = word.chars().last().unwrap();
        match last_char {
            '!' | '?' => true,
            '.' => !is_abbreviation(&word, self.next_word_starts_lowercase(index)),
            _ => false,
        }
    }

    fn sentence_start_at_or_before(&self, index: usize) -> usize {
        let mut idx = index;
        while idx > 0 {
            if self.word_ends_sentence_at(idx - 1) {
                break;
            }
            idx -= 1;
        }
        idx
    }
}
