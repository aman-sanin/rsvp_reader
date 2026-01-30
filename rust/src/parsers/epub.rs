use anyhow::{Context, Result};
use std::fs::File;
use std::io::Read;
use std::path::Path;
use zip::ZipArchive;

pub fn parse_epub(path: &Path) -> Result<String> {
    // 1. Initialize Debug Trace
    let mut trace = String::new();
    trace.push_str(&format!("Start: Opening via RAW ZIP SCAN: {:?}\n", path));

    let mut log = |msg: String| {
        trace.push_str(&msg);
        trace.push('\n');
    };

    // 2. Open as a Zip Archive (ignores broken EPUB metadata)
    let file = match File::open(path) {
        Ok(f) => f,
        Err(e) => {
            return Err(anyhow::anyhow!(
                "File Open Failed.\nTrace:\n{}\nError: {}",
                trace,
                e
            ))
        }
    };

    let mut archive = match ZipArchive::new(file) {
        Ok(a) => a,
        Err(e) => {
            return Err(anyhow::anyhow!(
                "Zip Open Failed.\nTrace:\n{}\nError: {}",
                trace,
                e
            ))
        }
    };

    let mut full_text = String::new();
    let mut found_files = 0;

    log(format!(
        "Zip opened successfully. Contains {} files.",
        archive.len()
    ));

    // 3. Iterate over EVERY file in the archive
    for i in 0..archive.len() {
        let mut zip_file = match archive.by_index(i) {
            Ok(f) => f,
            Err(_) => continue,
        };

        let name = zip_file.name().to_string();

        // 4. Strict Filter: Only look at HTML/XHTML files
        if !name.ends_with(".xhtml") && !name.ends_with(".html") && !name.ends_with(".htm") {
            continue;
        }

        // Skip "system" files that usually contain no real text
        if name.contains("nav.xhtml") || name.contains("toc.xhtml") || name.contains("cover") {
            log(format!("[Skip] System file: {}", name));
            continue;
        }

        // 5. Read the content
        let mut buffer = Vec::new();
        if let Err(e) = zip_file.read_to_end(&mut buffer) {
            log(format!("[Error] Could not read {}: {}", name, e));
            continue;
        }

        // 6. Convert & Strip
        // We use lossy conversion to survive bad characters
        let content = String::from_utf8_lossy(&buffer);
        let stripped = strip_html_content(&content);

        if !stripped.trim().is_empty() {
            log(format!(
                "[Hit] Found content in '{}' ({} chars)",
                name,
                stripped.len()
            ));
            full_text.push_str(&stripped);
            full_text.push_str("\n\n");
            found_files += 1;
        } else {
            log(format!(
                "[Empty] '{}' contained no text after stripping.",
                name
            ));
        }
    }

    log(format!(
        "Finished. Scraped {} text files. Total Length: {}",
        found_files,
        full_text.len()
    ));

    // 7. Final Check
    if full_text.trim().is_empty() {
        return Err(anyhow::anyhow!(
            "EPUB (Zip) scanned but 0 text found.\n\n=== RUST DEBUG TRACE ===\n{}",
            trace
        ));
    }

    Ok(full_text)
}

fn strip_html_content(content: &str) -> String {
    // Attempt 1: Smart Strip (Best quality)
    if let Ok(plain) = html2text::from_read(content.as_bytes(), 1000) {
        if !plain.trim().is_empty() {
            return plain.trim().to_string();
        }
    }

    // Attempt 2: Brute Force (Vacuum Cleaner)
    let mut output = String::new();
    let mut inside_tag = false;
    for c in content.chars() {
        if c == '<' {
            inside_tag = true;
            output.push(' ');
        } else if c == '>' {
            inside_tag = false;
        } else if !inside_tag {
            output.push(c);
        }
    }
    output.split_whitespace().collect::<Vec<&str>>().join(" ")
}
