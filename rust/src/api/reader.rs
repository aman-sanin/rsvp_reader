use flutter_rust_bridge::frb;
use std::path::PathBuf;
use std::time::Duration;

use crate::core::book_parser::parse_rsvp_file;
use crate::core::indexed_store::IndexedBookStore;
use crate::core::pacing::PacingConfig;
use crate::core::reading_loop::{DemoWordSource, ReadingLoop, WordSource};

/// Handle to an active RSVP reader.
// Add opaque marker
#[frb(opaque)]
pub struct ReaderHandle {
    loop_: ReadingLoop,
    playing: bool,
}

#[frb(dart_metadata=("freezed"))]
pub enum ReaderCommand {
    Play,
    Pause,
    SeekTo(usize),
    Scrub(i32),
    RewindSentence,
    AdjustWpm(i32),
    SetWpm(u16),
}

#[frb(dart_metadata=("freezed"))]
pub struct ReaderState {
    pub current_word: String,
    pub current_index: usize,
    pub total_words: usize,
    pub wpm: u16,
    pub is_playing: bool,
    pub at_end: bool,
    pub progress_percent: u8,
}

/// Creates a new reader.
/// If `book_path` is `None`, loads a built-in demo.
/// Supports `.rsvp` (parsed into memory) and `.ridx` (indexed store).
#[frb]
pub fn create_reader(book_path: Option<String>) -> ReaderHandle {
    let word_source: Box<dyn WordSource> = match book_path {
        Some(path) => {
            let path = PathBuf::from(path);
            let ext = path.extension().and_then(|e| e.to_str()).unwrap_or("");
            match ext {
                "ridx" => match IndexedBookStore::open(&path) {
                    Ok(store) => Box::new(store),
                    Err(_) => fallback_demo(),
                },
                "rsvp" => match parse_rsvp_file(&path) {
                    Ok(content) => Box::new(DemoWordSource::new(content.words)),
                    Err(_) => fallback_demo(),
                },
                _ => fallback_demo(),
            }
        }
        None => fallback_demo(),
    };

    let mut loop_ = ReadingLoop::new(word_source);
    loop_.set_pacing_config(PacingConfig::default());

    ReaderHandle {
        loop_,
        playing: false,
    }
}

fn fallback_demo() -> Box<dyn WordSource> {
    let demo_words = vec![
        "Welcome".to_string(),
        "to".to_string(),
        "RSVP".to_string(),
        "reader!".to_string(),
        "This".to_string(),
        "is".to_string(),
        "a".to_string(),
        "demo.".to_string(),
        "Swipe".to_string(),
        "up".to_string(),
        "/".to_string(),
        "down".to_string(),
        "to".to_string(),
        "change".to_string(),
        "speed.".to_string(),
    ];
    Box::new(DemoWordSource::new(demo_words))
}

/// Update the reader’s internal timer. Call frequently with current timestamp in ms.
/// Returns `true` if the current word changed.
#[frb]
pub fn reader_update(handle: &mut ReaderHandle, now_ms: u64) -> bool {
    if handle.playing {
        let now = Duration::from_millis(now_ms);
        handle.loop_.update(now)
    } else {
        false
    }
}

/// Send a command to the reader.
#[frb]
pub fn reader_command(handle: &mut ReaderHandle, cmd: ReaderCommand, now_ms: u64) {
    let now = Duration::from_millis(now_ms);
    match cmd {
        ReaderCommand::Play => {
            if !handle.playing {
                handle.playing = true;
                handle.loop_.start(now);
            }
        }
        ReaderCommand::Pause => {
            if handle.playing {
                handle.playing = false;
                handle.loop_.pause();
            }
        }
        ReaderCommand::SeekTo(idx) => handle.loop_.seek_to(idx),
        ReaderCommand::Scrub(steps) => handle.loop_.scrub(steps),
        ReaderCommand::RewindSentence => handle.loop_.rewind_sentence(),
        ReaderCommand::AdjustWpm(delta) => handle.loop_.adjust_wpm(delta),
        ReaderCommand::SetWpm(wpm) => handle.loop_.set_wpm(wpm),
    }
}

/// Get the current state of the reader.
#[frb]
pub fn reader_state(handle: &mut ReaderHandle) -> ReaderState {
    let total = handle.loop_.word_count();
    let current = handle.loop_.current_index();
    let progress = if total > 0 {
        ((current * 100) / total) as u8
    } else {
        0
    };
    ReaderState {
        current_word: handle.loop_.current_word().to_string(),
        current_index: current,
        total_words: total,
        wpm: handle.loop_.wpm(),
        is_playing: handle.playing,
        at_end: handle.loop_.at_end(),
        progress_percent: progress,
    }
}

/// Set the pacing configuration (delays and scales).
#[frb]
pub fn set_pacing_config(handle: &mut ReaderHandle, config: PacingConfig) {
    handle.loop_.set_pacing_config(config);
}
