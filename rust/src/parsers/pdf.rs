use anyhow::{Result, Context};
use std::fs;
use std::path::Path;

pub fn parse_pdf(path: &Path) -> Result<String> {
    let bytes = fs::read(path).context("Failed to read PDF file bytes")?;
    pdf_extract::extract_text_from_mem(&bytes)
        .map_err(|e| anyhow::anyhow!("PDF Parse Error: {:?}", e))
}
