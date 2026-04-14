# Verse (RSVP Reader)

A lightning-fast, highly efficient Rapid Serial Visual Presentation (RSVP) reader, built with Flutter and Rust. 

Verse is designed to help you read faster and comprehend better by minimizing eye movement. By presenting words sequentially at a fixed central location, the app eliminates the time spent on saccades (eye movements) and cognitive load associated with tracking lines of text.


## 🚀 Features

- **Rapid Serial Visual Presentation:** Read texts at unprecedented speeds with adjustable Words Per Minute (WPM).
- **Format Support:** Seamlessly read native `.epub` and `.pdf` files.
- **High Performance:** Core text extraction, parsing, and chunking logic is powered by a custom **Rust** backend, ensuring smooth and instant text processing even for large books.
- **Cross-Platform:** Built with Flutter, enabling a beautiful and consistent experience across Android, iOS, Windows, macOS, and Linux.
- **Clean UI/UX:** Distraction-free reading environment optimized for deep focus.

## 🛠 Tech Stack

- **Frontend:** [Flutter](https://flutter.dev/) & Dart
  - UI framework tailored for high frame-rate rendering.
  - Features `freezed` for state management/models and `google_fonts` for typography.
- **Backend:** [Rust](https://www.rust-lang.org/)
  - Uses `flutter_rust_bridge` for zero-copy, seamless interop with Dart.
### Prerequisites

Ensure you have the following installed on your system:
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (version 3.10.7 or higher recommended)
- [Rust Toolchain](https://rustup.rs/)
- Required platform build tools (e.g., Xcode for iOS/macOS, Android Studio for Android).

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/rsvp_reader.git
   cd rsvp_reader
   ```

2. **Install Flutter Dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate Rust Bridge Code (if needed)**
   *(Usually handled automatically by the `cargokit` build tool/`flutter_rust_bridge` configuration during the build phase.)*

4. **Run the App**
   ```bash
   flutter run
   ```

## 🏗 Architecture

Verse utilizes a hybrid architecture:
1. **Dart/Flutter Layer:** Handles user input, routing, storage interactions, and the high-performance UI loop rendering incoming text chunks.
2. **Rust Layer:** Handles file I/O, heavy parsing constraints (like extracting text from nested ePub HTML or complex PDFs), and advanced string tokenization, passing clean, presentation-ready streams back to the UI.

