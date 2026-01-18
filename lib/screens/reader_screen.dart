// lib/screens/reader_screen.dart
import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:rsvp_reader/src/rust/api/processor.dart';
import 'package:rsvp_reader/widgets/rsvp_display.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  List<RsvpWord> _words = [];
  int _currentIndex = 0;
  bool _isPlaying = false;
  double _wpm = 300;
  double _fontSize = 40.0;
  Timer? _timer;
  bool _isLoading = false;
  String _currentFileName = "No File Selected";

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _pickAndLoadFile() async {
    try {
      // 1. Pick the file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'pdf', 'epub'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _isLoading = true;
          _isPlaying = false;
          _timer?.cancel();
        });

        final path = result.files.single.path!;
        final fileName = result.files.single.name;

        // 2. RUST CALL: Read file bytes -> String
        // This runs on a background thread in Rust!
        final rawText = await readFileContent(path: path);

        // 3. RUST CALL: Process String -> RSVP Words
        final processedWords = await parseTextToRsvp(text: rawText);

        if (mounted) {
          setState(() {
            _words = processedWords;
            _currentIndex = 0;
            _currentFileName = fileName;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _startReading() {
    if (_words.isEmpty) return;
    setState(() => _isPlaying = true);
    _scheduleNextWord();
  }

  void _stopReading() {
    _timer?.cancel();
    setState(() => _isPlaying = false);
  }

  void _scheduleNextWord() {
    if (!_isPlaying || _currentIndex >= _words.length) {
      _stopReading();
      return;
    }

    final baseMs = 60000 / _wpm;
    final durationMs = baseMs * _words[_currentIndex].delayFactor;

    _timer = Timer(Duration(milliseconds: durationMs.toInt()), () {
      if (mounted) {
        setState(() {
          _currentIndex++;
        });
        _scheduleNextWord();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_currentFileName), centerTitle: true),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickAndLoadFile,
        child: const Icon(Icons.folder_open),
      ),
      body: SafeArea(
        child: OrientationBuilder(
          builder: (context, orientation) {
            final isPortrait = orientation == Orientation.portrait;

            // 1. UPDATE: Pass _fontSize to the widget
            final displayWidget = _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _words.isEmpty
                ? const Center(child: Text("Open a file to start reading"))
                : _currentIndex < _words.length
                ? RsvpDisplay(
                    word: _words[_currentIndex],
                    fontSize: _fontSize, // <-- PASS IT HERE
                  )
                : const Center(child: Text("Done!"));

            // 2. UPDATE: Add Font Slider to Controls
            final controlsWidget = _words.isEmpty || _isLoading
                ? const SizedBox.shrink()
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // SPEED CONTROL
                      Text(
                        "Speed: ${_wpm.round()} WPM",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Slider(
                        min: 100,
                        max: 1000,
                        divisions: 18,
                        value: _wpm,
                        onChanged: (v) => setState(() => _wpm = v),
                      ),

                      // FONT SIZE CONTROL (NEW)
                      Text(
                        "Size: ${_fontSize.round()} px",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Slider(
                        min: 20,
                        max: 100,
                        divisions: 16,
                        value: _fontSize,
                        onChanged: (v) => setState(() => _fontSize = v),
                      ),

                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: _isPlaying ? _stopReading : _startReading,
                        icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                        label: Text(_isPlaying ? "PAUSE" : "READ"),
                      ),
                    ],
                  ); // 3. The Adaptive Switch
            if (isPortrait) {
              // PORTRAIT: Vertical Column
              return Column(
                children: [
                  Expanded(flex: 3, child: displayWidget),
                  Expanded(flex: 1, child: controlsWidget),
                ],
              );
            } else {
              // LANDSCAPE: Horizontal Row
              // This gives the controls full height (no overflow) but restricts width
              return Row(
                children: [
                  Expanded(flex: 3, child: displayWidget),
                  // Add a vertical divider for visual separation
                  VerticalDivider(width: 1, color: Colors.grey.shade800),
                  Expanded(flex: 1, child: controlsWidget),
                ],
              );
            }
          },
        ),
      ),
    );
  }
}
