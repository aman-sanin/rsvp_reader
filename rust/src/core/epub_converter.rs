//! EPUB to RSVP converter
//! Uses the `zip` crate for ZIP handling and `flate2` for DEFLATE.

use crate::core::rsvp_writer::RsvpWriter;
use crate::core::text::normalize_display_text;
use crate::core::tokenizer::tokenize_line;
use encoding_rs::UTF_8;
use std::collections::HashMap;
use std::fs::File;
use std::io::{BufWriter, Read, Write};
use std::path::Path;
use zip::ZipArchive;

// -----------------------------------------------------------------------------
// Error type
// -----------------------------------------------------------------------------

#[derive(Debug, thiserror::Error)]
pub enum EpubError {
    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),
    #[error("Zip error: {0}")]
    Zip(#[from] zip::result::ZipError),
    #[error("Missing container.xml")]
    MissingContainer,
    #[error("Missing rootfile in container.xml")]
    MissingRootfile,
    #[error("Missing OPF file")]
    MissingOpf,
    #[error("No content files found")]
    NoContent,
    #[error("UTF-8 decoding error")]
    Utf8Error,
    #[error("Word limit reached")]
    WordLimitReached,
}

pub type Result<T> = std::result::Result<T, EpubError>;

// -----------------------------------------------------------------------------
// Main conversion function
// -----------------------------------------------------------------------------

/// Convert an EPUB file to RSVP format.
///
/// # Arguments
/// * `epub_path` – path to the EPUB file.
/// * `rsvp_path` – path where the `.rsvp` file will be written.
/// * `max_words` – maximum number of words to extract (0 = unlimited).
/// * `_progress_callback` – optional progress callback (currently disabled).
pub fn convert_epub_to_rsvp<P: AsRef<Path>>(
    epub_path: P,
    rsvp_path: P,
    max_words: usize,
    _progress_callback: Option<&mut dyn FnMut(u32)>,
) -> Result<()> {
    let epub_file = File::open(epub_path.as_ref())?;
    let mut archive = ZipArchive::new(epub_file)?;

    // 1. Read container.xml
    let container_xml = read_zip_entry(&mut archive, "META-INF/container.xml")?;
    let rootfile_path = parse_rootfile_path(&container_xml)?;

    // 2. Read OPF file
    let opf_xml = read_zip_entry(&mut archive, &rootfile_path)?;
    let opf_data = parse_opf(&opf_xml)?;
    let base_dir = Path::new(&rootfile_path).parent().unwrap_or(Path::new(""));

    // 3. Build reading order
    let reading_order = build_reading_order(&mut archive, &opf_data, base_dir)?;
    if reading_order.is_empty() {
        return Err(EpubError::NoContent);
    }

    // 4. Prepare output RSVP file
    let output_file = File::create(rsvp_path.as_ref())?;
    let mut writer = BufWriter::new(output_file);
    let mut rsvp_writer = RsvpWriter::new(&mut writer, max_words);

    // Write header
    let title = if opf_data.title.is_empty() {
        epub_path
            .as_ref()
            .file_stem()
            .unwrap_or_default()
            .to_string_lossy()
            .to_string()
    } else {
        opf_data.title.clone()
    };
    rsvp_writer.write_header(
        &title,
        &opf_data.author,
        epub_path.as_ref().to_str().unwrap_or(""),
    )?;

    // 5. Process each content file
    for entry_path in &reading_order {
        let content = read_zip_entry(&mut archive, entry_path)?;
        extract_text_from_html(&content, &mut rsvp_writer)?;
        if rsvp_writer.reached_limit() {
            break;
        }
    }

    rsvp_writer.finish()?;
    Ok(())
}

// -----------------------------------------------------------------------------
// Helper functions
// -----------------------------------------------------------------------------

/// Read a single entry from the ZIP archive as a UTF-8 string.
fn read_zip_entry(archive: &mut ZipArchive<File>, path: &str) -> Result<String> {
    let mut entry = archive.by_name(path)?;
    let mut bytes = Vec::new();
    entry.read_to_end(&mut bytes)?;
    let (cow, _) = UTF_8.decode_without_bom_handling(&bytes);
    Ok(cow.into_owned())
}

/// Parse container.xml to find the rootfile path.
fn parse_rootfile_path(container_xml: &str) -> Result<String> {
    let tag = "<rootfile";
    let mut start = 0;
    while let Some(pos) = container_xml[start..].find(tag) {
        let idx = start + pos;
        let end = container_xml[idx..]
            .find('>')
            .ok_or(EpubError::MissingRootfile)?;
        let fragment = &container_xml[idx..idx + end];
        if let Some(href_start) = fragment.find("full-path=\"") {
            let value_start = href_start + 11;
            let end_quote = fragment[value_start..]
                .find('"')
                .ok_or(EpubError::MissingRootfile)?;
            let path = &fragment[value_start..value_start + end_quote];
            return Ok(path.to_string());
        }
        start = idx + 1;
    }
    Err(EpubError::MissingRootfile)
}

/// Data extracted from OPF.
#[derive(Debug, Default)]
struct OpfData {
    title: String,
    author: String,
    manifest: HashMap<String, String>, // id -> href
    spine: Vec<String>,                // list of idrefs
}

/// Parse OPF XML to extract manifest, spine, title, author.
fn parse_opf(opf_xml: &str) -> Result<OpfData> {
    let mut data = OpfData::default();

    // Extract manifest
    if let Some(manifest) = extract_tag_content(opf_xml, "manifest", None) {
        let mut start = 0;
        while let Some(item_start) = manifest[start..].find("<item") {
            let idx = start + item_start;
            let end = find_tag_end(&manifest[idx..]).unwrap_or(manifest.len());
            let fragment = &manifest[idx..idx + end];
            if let (Some(id), Some(href)) =
                (extract_attr(fragment, "id"), extract_attr(fragment, "href"))
            {
                data.manifest.insert(id.to_string(), href.to_string());
            }
            start = idx + end;
        }
    }

    // Extract spine
    if let Some(spine) = extract_tag_content(opf_xml, "spine", None) {
        let mut start = 0;
        while let Some(itemref_start) = spine[start..].find("<itemref") {
            let idx = start + itemref_start;
            let end = find_tag_end(&spine[idx..]).unwrap_or(spine.len());
            let fragment = &spine[idx..idx + end];
            if let Some(idref) = extract_attr(fragment, "idref") {
                data.spine.push(idref.to_string());
            }
            start = idx + end;
        }
    }

    // Extract title and author from metadata
    if let Some(metadata) = extract_tag_content(opf_xml, "metadata", None) {
        data.title = extract_dc(&metadata, "title");
        data.author = extract_dc(&metadata, "creator");
    }

    Ok(data)
}

/// Extract content between two XML tags (simple).
fn extract_tag_content(xml: &str, tag: &str, close_tag: Option<&str>) -> Option<String> {
    let open = format!("<{}", tag);
    let close_str = format!("</{}>", tag);
    let close = close_tag.unwrap_or(&close_str);
    let start = xml.find(&open)?;
    let tag_end = xml[start..].find('>')?;
    let inner_start = start + tag_end + 1;
    let inner_end = xml[inner_start..].find(close)?;
    Some(xml[inner_start..inner_start + inner_end].to_string())
}

/// Find the index of the closing '>' of a tag, handling self-closing tags.
fn find_tag_end(fragment: &str) -> Option<usize> {
    let mut depth = 0;
    for (i, c) in fragment.chars().enumerate() {
        if c == '<' {
            depth += 1;
        } else if c == '>' {
            depth -= 1;
            if depth == 0 {
                return Some(i + 1);
            }
        }
    }
    None
}

/// Extract an attribute value from a tag fragment.
fn extract_attr<'a>(fragment: &'a str, attr: &str) -> Option<&'a str> {
    let pattern = format!("{}=\"", attr);
    let start = fragment.find(&pattern)?;
    let value_start = start + pattern.len();
    let end = fragment[value_start..].find('"')?;
    Some(&fragment[value_start..value_start + end])
}

/// Extract Dublin Core metadata.
fn extract_dc(metadata: &str, tag: &str) -> String {
    let open = format!("<dc:{}", tag);
    let close = format!("</dc:{}>", tag);
    if let Some(start) = metadata.find(&open) {
        let tag_end = metadata[start..].find('>').unwrap_or(0);
        let inner_start = start + tag_end + 1;
        if let Some(end) = metadata[inner_start..].find(&close) {
            return metadata[inner_start..inner_start + end].trim().to_string();
        }
    }
    String::new()
}

/// Build reading order: resolve manifest IDs to paths, collapse relative paths.
fn build_reading_order(
    archive: &mut ZipArchive<File>,
    opf: &OpfData,
    base_dir: &Path,
) -> Result<Vec<String>> {
    let mut order = Vec::new();
    for idref in &opf.spine {
        if let Some(href) = opf.manifest.get(idref) {
            let resolved = base_dir.join(href).to_string_lossy().replace('\\', "/");
            // Check if the file exists in archive (case‑insensitive fallback)
            if archive.by_name(&resolved).is_ok() {
                order.push(resolved);
            } else {
                // Try case‑insensitive match
                for name in archive.file_names() {
                    if name.to_lowercase() == resolved.to_lowercase() {
                        order.push(name.to_string());
                        break;
                    }
                }
            }
        }
    }
    Ok(order)
}

/// Extract plain text from an HTML/XHTML fragment and write tokens to the RSVP writer.
fn extract_text_from_html<W: Write>(html: &str, rsvp_writer: &mut RsvpWriter<W>) -> Result<()> {
    let mut skip_depth = 0;
    let mut in_heading = false;
    let mut heading = String::new();
    let mut line_buffer = String::new();

    let mut chars = html.chars().peekable();
    while let Some(c) = chars.next() {
        if c == '<' {
            // Read tag
            let mut tag = String::new();
            while let Some(&ch) = chars.peek() {
                tag.push(ch);
                if ch == '>' {
                    chars.next();
                    break;
                }
                chars.next();
            }
            let tag_lower = tag.to_lowercase();
            let (is_closing, tag_name) = parse_tag_name(&tag_lower);

            if is_skip_tag(&tag_name) {
                if !is_closing && skip_depth == 0 {
                    skip_depth = 1;
                } else if is_closing && skip_depth > 0 {
                    skip_depth -= 1;
                }
                continue;
            }
            if skip_depth > 0 {
                continue;
            }
            if is_heading_tag(&tag_name) {
                if is_closing {
                    if !heading.is_empty() {
                        rsvp_writer.write_chapter(&heading)?;
                        heading.clear();
                    }
                    in_heading = false;
                } else {
                    in_heading = true;
                    heading.clear();
                    flush_line_buffer(&mut line_buffer, rsvp_writer)?;
                }
                continue;
            }
            if is_block_tag(&tag_name) && (is_closing || tag_name == "br" || tag_name == "hr") {
                flush_line_buffer(&mut line_buffer, rsvp_writer)?;
                rsvp_writer.write_paragraph()?;
                continue;
            }
            if !in_heading {
                line_buffer.push(' ');
            }
        } else if c == '&' {
            // Entity decoding
            let mut entity = String::new();
            while let Some(&ch) = chars.peek() {
                entity.push(ch);
                if ch == ';' {
                    chars.next();
                    break;
                }
                chars.next();
            }
            let decoded = decode_entity(&entity);
            if in_heading {
                heading.push_str(&decoded);
            } else {
                line_buffer.push_str(&decoded);
            }
        } else {
            if skip_depth > 0 {
                continue;
            }
            if in_heading {
                heading.push(c);
            } else {
                line_buffer.push(c);
                if line_buffer.len() > 200 {
                    flush_line_buffer(&mut line_buffer, rsvp_writer)?;
                }
            }
        }
    }
    flush_line_buffer(&mut line_buffer, rsvp_writer)?;
    Ok(())
}

/// Parse tag name and detect if it's closing.
fn parse_tag_name(tag: &str) -> (bool, &str) {
    let mut chars = tag.chars();
    let is_closing = chars.next() == Some('/');
    let name = if is_closing { chars.as_str() } else { tag };
    let end = name.find(|c| c == ' ' || c == '>').unwrap_or(name.len());
    (is_closing, &name[..end])
}

fn is_skip_tag(name: &str) -> bool {
    matches!(name, "head" | "script" | "style" | "svg" | "math" | "nav")
}

fn is_heading_tag(name: &str) -> bool {
    name.len() == 2 && name.starts_with('h') && name[1..].parse::<u8>().is_ok()
}

fn is_block_tag(name: &str) -> bool {
    matches!(
        name,
        "p" | "div"
            | "section"
            | "article"
            | "blockquote"
            | "li"
            | "tr"
            | "br"
            | "hr"
            | "dd"
            | "dt"
    )
}

/// Decode HTML entities to plain text (simplified).
fn decode_entity(entity: &str) -> String {
    match entity {
        "amp;" => "&".to_string(),
        "lt;" => "<".to_string(),
        "gt;" => ">".to_string(),
        "quot;" => "\"".to_string(),
        "apos;" => "'".to_string(),
        "nbsp;" => " ".to_string(),
        "ndash;" | "mdash;" => " - ".to_string(),
        "hellip;" => "...".to_string(),
        _ => {
            if entity.starts_with('#') {
                let num_str = &entity[1..entity.len() - 1];
                let codepoint = if num_str.starts_with('x') {
                    u32::from_str_radix(&num_str[1..], 16).unwrap_or(0)
                } else {
                    num_str.parse().unwrap_or(0)
                };
                char::from_u32(codepoint)
                    .map(|c| c.to_string())
                    .unwrap_or_else(|| "?".to_string())
            } else {
                format!("&{}", entity)
            }
        }
    }
}

/// Flush the line buffer: tokenise and write words.
fn flush_line_buffer<W: Write>(buffer: &mut String, writer: &mut RsvpWriter<W>) -> Result<()> {
    if buffer.is_empty() {
        return Ok(());
    }
    let normalized = normalize_display_text(buffer);
    let tokens = tokenize_line(&normalized);
    for token in tokens {
        if !writer.write_word(&token.text)? {
            return Err(EpubError::WordLimitReached);
        }
    }
    buffer.clear();
    Ok(())
}
