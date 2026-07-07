import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:verse/src/rust/api/reader.dart';
import 'package:verse/src/rust/core/pacing.dart';
import 'package:verse/src/rust/api/library.dart' as lib;

class BookChapter {
  final int wordIndex;
  final String title;
  const BookChapter(this.wordIndex, this.title);
}

class ReaderProvider extends ChangeNotifier {
  ReaderHandle? _handle;
  ReaderState _state = ReaderState(
    currentWord: '',
    currentIndex: BigInt.zero,
    totalWords: BigInt.zero,
    wpm: 300,
    isPlaying: false,
    atEnd: false,
    progressPercent: 0,
  );
  Timer? _timer;
  String? _currentBookPath;
  List<String> _words = [];
  List<BookChapter> _chapters = [];

  ReaderState get state => _state;
  bool get isPlaying => _state.isPlaying;
  List<String> get words => _words;
  List<BookChapter> get chapters => _chapters;

  String get currentChapterTitle {
    if (_chapters.isEmpty) return 'Chapter 1';
    final idx = _state.currentIndex.toInt();
    String title = _chapters[0].title;
    for (final chap in _chapters) {
      if (idx >= chap.wordIndex) {
        title = chap.title;
      } else {
        break;
      }
    }
    return title;
  }

  void nextChapter() {
    if (_chapters.isEmpty) return;
    final idx = _state.currentIndex.toInt();
    for (final chap in _chapters) {
      if (chap.wordIndex > idx) {
        seekTo(chap.wordIndex);
        return;
      }
    }
  }

  void prevChapter() {
    if (_chapters.isEmpty) return;
    final idx = _state.currentIndex.toInt();
    int currentChapIdx = 0;
    for (int i = 0; i < _chapters.length; i++) {
      if (idx >= _chapters[i].wordIndex) {
        currentChapIdx = i;
      } else {
        break;
      }
    }
    if (currentChapIdx > 0) {
      seekTo(_chapters[currentChapIdx - 1].wordIndex);
    } else {
      seekTo(0);
    }
  }

  Future<void> _loadWords(String? bookPath) async {
    _chapters = [];
    if (bookPath == null) {
      _words = [
        "Welcome", "to", "RSVP", "reader!", "This", "is", "a", "demo.",
        "Swipe", "up", "/", "down", "to", "change", "speed."
      ];
      _chapters = [const BookChapter(0, "Welcome")];
      return;
    }
    try {
      final file = File(bookPath);
      if (!await file.exists()) {
        _words = [];
        return;
      }
      final lines = await file.readAsLines();
      final List<String> parsedWords = [];
      final List<BookChapter> parsedChapters = [];
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;
        if (trimmed.startsWith('@')) {
          if (trimmed.startsWith('@chapter')) {
            final title = trimmed.substring(8).trim();
            parsedChapters.add(BookChapter(parsedWords.length, title));
          }
          continue;
        }
        final tokens = trimmed.split(RegExp(r'\s+'));
        for (final token in tokens) {
          final t = token.trim();
          if (t.isEmpty) continue;
          final hasAlphanumeric = t.contains(RegExp(r'[a-zA-Z0-9]'));
          if (!hasAlphanumeric && t != "..." && t != "-") {
            continue;
          }
          parsedWords.add(t);
        }
      }
      _words = parsedWords;
      _chapters = parsedChapters;
      if (_chapters.isEmpty) {
        _chapters = [const BookChapter(0, "Chapter 1")];
      }
    } catch (e) {
      debugPrint("Error parsing RSVP file: $e");
      _words = [];
      _chapters = [const BookChapter(0, "Chapter 1")];
    }
  }

  Future<void> loadBook(String? bookPath) async {
    _currentBookPath = bookPath;
    await _loadWords(bookPath);
    _handle = await createReader(bookPath: bookPath);
    _startTimer();
    await _updateState();
    await readerCommand(
      handle: _handle!,
      cmd: ReaderCommand.play(),
      nowMs: BigInt.from(DateTime.now().millisecondsSinceEpoch),
    );
    notifyListeners();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      _onTimerTick();
    });
  }

  Future<void> _onTimerTick() async {
    if (_handle == null) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    await readerUpdate(handle: _handle!, nowMs: BigInt.from(now));
    await _updateState();
  }

  Future<void> _updateState() async {
    if (_handle == null) return;
    final newState = await readerState(handle: _handle!);
    if (newState.currentWord != _state.currentWord ||
        newState.currentIndex != _state.currentIndex ||
        newState.isPlaying != _state.isPlaying ||
        newState.wpm != _state.wpm ||
        newState.progressPercent != _state.progressPercent) {
      _state = newState;
      notifyListeners();
    }
  }

  Future<void> play() async {
    if (_handle != null && !_state.isPlaying) {
      await readerCommand(
        handle: _handle!,
        cmd: ReaderCommand.play(),
        nowMs: BigInt.from(DateTime.now().millisecondsSinceEpoch),
      );
      await _updateState();
    }
  }

  Future<void> pause() async {
    if (_handle != null && _state.isPlaying) {
      await readerCommand(
        handle: _handle!,
        cmd: ReaderCommand.pause(),
        nowMs: BigInt.from(DateTime.now().millisecondsSinceEpoch),
      );
      await _updateState();
    }
  }

  Future<void> togglePlayPause() async {
    if (_state.isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> seekTo(int index) async {
    if (_handle != null) {
      await readerCommand(
        handle: _handle!,
        cmd: ReaderCommand.seekTo(BigInt.from(index)),
        nowMs: BigInt.from(DateTime.now().millisecondsSinceEpoch),
      );
      await _updateState();
    }
  }

  Future<void> scrub(int steps) async {
    if (_handle != null) {
      await readerCommand(
        handle: _handle!,
        cmd: ReaderCommand.scrub(steps),
        nowMs: BigInt.from(DateTime.now().millisecondsSinceEpoch),
      );
      await _updateState();
    }
  }

  Future<void> rewindSentence() async {
    if (_handle != null) {
      await readerCommand(
        handle: _handle!,
        cmd: ReaderCommand.rewindSentence(),
        nowMs: BigInt.from(DateTime.now().millisecondsSinceEpoch),
      );
      await _updateState();
    }
  }

  Future<void> adjustWpm(int delta) async {
    if (_handle != null) {
      await readerCommand(
        handle: _handle!,
        cmd: ReaderCommand.adjustWpm(delta),
        nowMs: BigInt.from(DateTime.now().millisecondsSinceEpoch),
      );
      await _updateState();
    }
  }

  Future<void> setWpm(int wpm) async {
    if (_handle != null) {
      await readerCommand(
        handle: _handle!,
        cmd: ReaderCommand.setWpm(wpm),
        nowMs: BigInt.from(DateTime.now().millisecondsSinceEpoch),
      );
      await _updateState();
    }
  }

  Future<void> saveProgress() async {
    if (_handle != null &&
        _state.totalWords > BigInt.zero &&
        _currentBookPath != null) {
      await lib.saveProgress(
        bookPath: _currentBookPath!,
        wordIndex: _state.currentIndex,
        wordCount: _state.totalWords,
      );
    }
  }

  Future<void> setPacing(PacingConfig config) async {
    if (_handle != null) {
      await setPacingConfig(handle: _handle!, config: config);
    }
  }

  @override
  void dispose() {
    saveProgress();
    _timer?.cancel();
    super.dispose();
  }
}
