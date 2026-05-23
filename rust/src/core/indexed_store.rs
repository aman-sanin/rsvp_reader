//! Indexed word store for efficient random access to large books.
//! Uses two files: `.ridx` (index) and `.rdat` (concatenated word data).

use super::reading_loop::WordSource;
use std::collections::VecDeque;
use std::fs::File;
use std::io::{self, Read, Seek, SeekFrom};
use std::path::Path;
use std::sync::Mutex; // <-- add this

pub const RIDX_MAGIC: u32 = 0x58444952;
pub const RIDX_VERSION: u32 = 4;
pub const DEFAULT_WORD_CACHE_SIZE: usize = 256;

#[repr(C, packed)]
#[derive(Debug, Clone, Copy)]
pub struct RidxHeader {
    pub magic: u32,
    pub version: u32,
    pub header_size: u32,
    pub record_size: u32,
    pub source_size: u32,
    pub source_fingerprint: u32,
    pub word_count: u32,
    pub paragraph_count: u32,
    pub chapter_count: u32,
    pub records_offset: u32,
    pub paragraphs_offset: u32,
    pub chapters_offset: u32,
    pub data_size: u32,
}
impl RidxHeader {
    pub const SIZE: usize = std::mem::size_of::<Self>();
}

#[repr(C, packed)]
#[derive(Debug, Clone, Copy)]
pub struct WordRecord {
    pub offset: u32,
    pub length: u16,
    pub flags: u16,
}
impl WordRecord {
    pub const SIZE: usize = std::mem::size_of::<Self>();
}

#[repr(C, packed)]
#[derive(Debug, Clone)]
pub struct ChapterRecord {
    pub word_index: u32,
    pub title_length: u32,
    pub title: [u8; 64],
}
impl ChapterRecord {
    pub const SIZE: usize = std::mem::size_of::<Self>();
}

pub struct IndexedBookStore {
    index_file: Mutex<File>,
    data_file: Mutex<File>,
    header: RidxHeader,
    cache: Mutex<VecDeque<(usize, String)>>,
    cache_start: Mutex<usize>,
    cache_size: usize,
}

impl IndexedBookStore {
    pub fn open(idx_path: &Path) -> io::Result<Self> {
        let mut index_file = File::open(idx_path)?;
        let mut header_bytes = [0u8; RidxHeader::SIZE];
        index_file.read_exact(&mut header_bytes)?;
        let header: RidxHeader = unsafe { std::ptr::read(header_bytes.as_ptr() as *const _) };

        if header.magic != RIDX_MAGIC
            || header.version != RIDX_VERSION
            || header.header_size != RidxHeader::SIZE as u32
            || header.record_size != WordRecord::SIZE as u32
            || header.word_count == 0
        {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                "Invalid index file header",
            ));
        }

        let data_path = idx_path.with_extension("rdat");
        let data_file = File::open(data_path)?;
        let data_size = data_file.metadata()?.len();
        if data_size < header.data_size as u64 {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                "Data file too small",
            ));
        }

        Ok(Self {
            index_file: Mutex::new(index_file),
            data_file: Mutex::new(data_file),
            header,
            cache: Mutex::new(VecDeque::with_capacity(DEFAULT_WORD_CACHE_SIZE)),
            cache_start: Mutex::new(0),
            cache_size: DEFAULT_WORD_CACHE_SIZE,
        })
    }

    fn load_window(&self, start_index: usize) -> io::Result<()> {
        let count = self.header.word_count as usize;
        if start_index >= count {
            return Ok(());
        }
        let window_size = self.cache_size.min(count - start_index);
        let record_offset =
            self.header.records_offset as u64 + (start_index as u64) * (WordRecord::SIZE as u64);
        {
            let mut idx_file = self.index_file.lock().unwrap();
            idx_file.seek(SeekFrom::Start(record_offset))?;
        }
        let mut records = vec![
            WordRecord {
                offset: 0,
                length: 0,
                flags: 0
            };
            window_size
        ];
        for rec in &mut records {
            let mut buf = [0u8; WordRecord::SIZE];
            self.index_file.lock().unwrap().read_exact(&mut buf)?;
            *rec = unsafe { std::ptr::read(buf.as_ptr() as *const _) };
        }
        let data_start = records.first().unwrap().offset;
        let data_end = records.last().unwrap().offset + records.last().unwrap().length as u32;
        let data_len = (data_end - data_start) as usize;
        let mut data_buf = vec![0u8; data_len];
        {
            let mut data_file = self.data_file.lock().unwrap();
            data_file.seek(SeekFrom::Start(data_start as u64))?;
            data_file.read_exact(&mut data_buf)?;
        }
        let mut new_cache = VecDeque::with_capacity(window_size);
        for rec in records {
            let offset_in_buf = (rec.offset - data_start) as usize;
            let word = String::from_utf8_lossy(
                &data_buf[offset_in_buf..offset_in_buf + rec.length as usize],
            )
            .to_string();
            new_cache.push_back((start_index + new_cache.len(), word));
        }
        *self.cache.lock().unwrap() = new_cache;
        *self.cache_start.lock().unwrap() = start_index;
        Ok(())
    }

    fn get_word(&self, index: usize) -> io::Result<String> {
        {
            let cache = self.cache.lock().unwrap();
            let cache_start = *self.cache_start.lock().unwrap();
            if index >= cache_start && index < cache_start + cache.len() {
                let local_idx = index - cache_start;
                if local_idx < cache.len() {
                    return Ok(cache[local_idx].1.clone());
                }
            }
        }
        // Not in cache, load window
        self.load_window(index)?;
        let cache = self.cache.lock().unwrap();
        let cache_start = *self.cache_start.lock().unwrap();
        let local_idx = index - cache_start;
        if local_idx < cache.len() {
            Ok(cache[local_idx].1.clone())
        } else {
            Err(io::Error::new(
                io::ErrorKind::InvalidInput,
                "Index out of range",
            ))
        }
    }
}

impl WordSource for IndexedBookStore {
    fn word_count(&self) -> usize {
        self.header.word_count as usize
    }
    fn word_at(&self, index: usize) -> String {
        self.get_word(index).unwrap_or_default()
    }
    fn prefetch_around(&self, index: usize) {
        let _ = self.get_word(index);
    }
}
