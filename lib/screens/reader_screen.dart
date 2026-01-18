// lib/screens/reader_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:rsvp_reader/src/rust/api/processor.dart';
import 'package:rsvp_reader/widgets/rsvp_display.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  // State
  List<RsvpWord> _words = [];
  int _currentIndex = 0;
  bool _isPlaying = false;
  double _wpm = 300;

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadDemoText(); // Load data on start
  }

  Future<void> _loadDemoText() async {
    // For Phase 1, we simulate a file read with a hardcoded string
    // In Phase 2, we will use a FilePicker here.
    const demo =
        "Welcome to your new Rust powered speed reader. "
        "This text is being processed by Rust code, segmented, and "
        "sent back to Flutter for rendering. Punctuation pauses automatically.";

    final processed = await parseTextToRsvp(text: demo);
    setState(() => _words = processed);
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

    // 1. Calculate duration based on current word's delay factor
    // Base MS per word = 60,000 / WPM
    final baseMs = 60000 / _wpm;
    final durationMs = baseMs * _words[_currentIndex].delayFactor;

    // 2. Schedule the update
    _timer = Timer(Duration(milliseconds: durationMs.toInt()), () {
      setState(() {
        _currentIndex++;
      });
      _scheduleNextWord(); // Recursive loop
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("RSVP Reader")),
      body: Column(
        children: [
          // THE DISPLAY AREA
          Expanded(
            flex: 3,
            child: _words.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _currentIndex < _words.length
                ? RsvpDisplay(word: _words[_currentIndex])
                : const Center(child: Text("Done!")),
          ),

          // THE CONTROLS
          Expanded(
            flex: 1,
            child: Column(
              children: [
                Text("${_wpm.round()} WPM"),
                Slider(
                  min: 100,
                  max: 1000,
                  value: _wpm,
                  onChanged: (v) => setState(() => _wpm = v),
                ),
                ElevatedButton(
                  onPressed: _isPlaying ? _stopReading : _startReading,
                  child: Text(_isPlaying ? "PAUSE" : "READ"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
