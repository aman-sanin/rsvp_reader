// We do NOT use #[frb] here. We define the logic, processor.rs handles the struct.
pub struct SplitWord {
    pub left: String,
    pub center: String,
    pub right: String,
    pub delay: f32,
}

pub fn convert_text_to_rsvp(text: String) -> Vec<SplitWord> {
    let text_merged = text.replace("-\r\n", "").replace("-\n", ""); 
    let clean_text = text_merged.replace("-", "- ").replace("—", " — ");

    clean_text.split_whitespace().map(|word| {
        let len = word.chars().count();
        
        let pivot_idx = if len == 1 { 0 } else { (len as f32 * 0.35).floor() as usize };
        let safe_pivot = pivot_idx.min(len.saturating_sub(1));

        let chars: Vec<char> = word.chars().collect();
        let left: String = chars[..safe_pivot].iter().collect();
        let center: String = chars[safe_pivot].to_string();
        let right: String = chars[safe_pivot + 1..].iter().collect();

        let mut delay = 1.0;
        if word.ends_with('.') || word.ends_with('!') || word.ends_with('?') { delay = 2.0; }
        else if word.ends_with(',') || word.ends_with(':') || word.ends_with(';') { delay = 1.5; }
        else if len > 10 { delay = 1.3; }

        SplitWord { left, center, right, delay }
    }).collect()
}
