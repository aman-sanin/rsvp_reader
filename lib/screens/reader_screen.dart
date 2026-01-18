// lib/screens/reader_screen.dart
import 'dart:async';
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
  bool _showSettings = false; // Default to hidden/collapsed
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

  void _rewind() {
    setState(() {
      // Go back 10 words, but don't go below 0
      _currentIndex = (_currentIndex - 10).clamp(0, _words.length - 1);
    });
  }

  void _fastForward() {
    setState(() {
      // Go forward 10 words, but don't go past the end
      _currentIndex = (_currentIndex + 10).clamp(0, _words.length - 1);
    });
  }

  void _goHome() {
    _stopReading(); // Stop the timer
    setState(() {
      _words = []; // Clear the data
      _currentIndex = 0;
      _currentFileName = "RSVP Reader"; // Reset title
      _isLoading = false;
      _showSettings = false; // Collapse settings if open
    });
  }

  @override
  Widget build(BuildContext context) {
    // Boolean to check if we are in "Reading Mode"
    final bool isReading = _words.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        // DYNAMIC TITLE: Shows filename if reading, else App Name
        title: Text(
          isReading ? _currentFileName : "RSVP Reader",
          style: const TextStyle(fontSize: 16),
        ),

        // BACK BUTTON LOGIC
        automaticallyImplyLeading: false, // Don't show default back button
        leading: isReading
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: "Close File",
                onPressed: _goHome, // Calls the reset function
              )
            : null, // Hide if on Home screen
      ),

      // FAB LOGIC: Only show "Open File" when on Home screen
      floatingActionButton: isReading
          ? null // Hide FAB while reading
          : FloatingActionButton.extended(
              onPressed: _pickAndLoadFile,
              icon: const Icon(Icons.folder_open),
              label: const Text("Open File"),
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
                : Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 1. COLLAPSIBLE SETTINGS PANEL
                          AnimatedSize(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            child: _showSettings
                                ? Column(
                                    children: [
                                      // SPEED SLIDER
                                      Text(
                                        "Speed: ${_wpm.round()} WPM",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Slider(
                                        min: 100,
                                        max: 1000,
                                        divisions: 18,
                                        value: _wpm,
                                        onChanged: (v) =>
                                            setState(() => _wpm = v),
                                      ),
                                      // FONT SLIDER
                                      Text(
                                        "Size: ${_fontSize.round()} px",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Slider(
                                        min: 20,
                                        max: 100,
                                        divisions: 16,
                                        value: _fontSize,
                                        onChanged: (v) =>
                                            setState(() => _fontSize = v),
                                      ),
                                      const Divider(), // Visual separator
                                    ],
                                  )
                                : const SizedBox.shrink(), // Hides completely when false
                          ),

                          // 2. MINIMAL INFO (Visible when settings are collapsed)
                          if (!_showSettings)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Text(
                                "${_wpm.round()} WPM  •  ${_fontSize.round()} px",
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 12,
                                ),
                              ),
                            ),

                          // 3. PLAYBACK CONTROLS (ADAPTIVE)
                          Flex(
                            direction: isPortrait
                                ? Axis.horizontal
                                : Axis.vertical,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // REWIND
                              IconButton.filledTonal(
                                onPressed: _rewind,
                                icon: const Icon(Icons.replay_10),
                                tooltip: "Back 10 words",
                              ),

                              // Adaptive Spacer (Width in Portrait, Height in Landscape)
                              SizedBox(
                                width: isPortrait ? 15 : 0,
                                height: isPortrait ? 0 : 15,
                              ),

                              // PLAY / PAUSE
                              ElevatedButton.icon(
                                onPressed: _isPlaying
                                    ? _stopReading
                                    : _startReading,
                                icon: Icon(
                                  _isPlaying ? Icons.pause : Icons.play_arrow,
                                ),
                                label: Text(_isPlaying ? "PAUSE" : "READ"),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 25,
                                    vertical: 15,
                                  ),
                                ),
                              ),

                              SizedBox(
                                width: isPortrait ? 15 : 0,
                                height: isPortrait ? 0 : 15,
                              ),

                              // FAST FORWARD
                              IconButton.filledTonal(
                                onPressed: _fastForward,
                                icon: const Icon(Icons.forward_10),
                                tooltip: "Forward 10 words",
                              ),

                              SizedBox(
                                width: isPortrait ? 15 : 0,
                                height: isPortrait ? 0 : 15,
                              ),

                              // SETTINGS TOGGLE
                              IconButton(
                                onPressed: () => setState(
                                  () => _showSettings = !_showSettings,
                                ),
                                icon: Icon(
                                  _showSettings
                                      ? Icons.expand_less
                                      : Icons.tune,
                                ),
                                tooltip: "Toggle Settings",
                                style: _showSettings
                                    ? IconButton.styleFrom(
                                        backgroundColor: Colors.white10,
                                      )
                                    : null,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
            // 3. The Adaptive Switch
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
