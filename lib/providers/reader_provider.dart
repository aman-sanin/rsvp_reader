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
  List<int> _paragraphStarts = [];
  int _lastSavedIndex = -1;
  int _lastSavedTimeMs = 0;

  ReaderState get state => _state;
  bool get isPlaying => _state.isPlaying;
  List<String> get words => _words;
  List<BookChapter> get chapters => _chapters;
  List<int> get paragraphStarts => _paragraphStarts;

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

  void goToParagraphStart() {
    if (_paragraphStarts.isEmpty) return;
    final idx = _state.currentIndex.toInt();
    int currentParaIdx = 0;
    for (int i = 0; i < _paragraphStarts.length; i++) {
      if (idx >= _paragraphStarts[i]) {
        currentParaIdx = i;
      } else {
        break;
      }
    }
    final startOfCurrent = _paragraphStarts[currentParaIdx];
    if (idx - startOfCurrent <= 3 && currentParaIdx > 0) {
      seekTo(_paragraphStarts[currentParaIdx - 1]);
    } else {
      seekTo(startOfCurrent);
    }
  }

  List<String> _tokenizeLine(String line) {
    final List<String> tokens = [];
    String current = '';
    final chars = line.split('');
    int i = 0;

    bool isInlineHyphen(int idx) {
      if (idx == 0 || idx + 1 >= chars.length) return false;
      final prev = chars[idx - 1];
      final next = chars[idx + 1];
      final reg = RegExp(r'[a-zA-Z0-9]');
      return reg.hasMatch(prev) && reg.hasMatch(next);
    }

    bool isSpecialPunctuation(String c) {
      return const {
        '.', ',', ';', ':', '!', '?', '"', '(', ')', '[', ']', '{', '}',
        '/', '\\', '|', '@', '#', '\$', '%', '^', '&', '*', '+', '=', '<', '>'
      }.contains(c);
    }

    void flushCurrent() {
      if (current.isEmpty) return;
      final trimmed = current.trim();
      if (trimmed.isEmpty) {
        current = '';
        return;
      }
      
      if (trimmed.split('').every((ch) => ch == '.') && trimmed.length >= 3) {
        tokens.add('...');
        current = '';
        return;
      }
      if (trimmed.split('').every((ch) => ch == '-')) {
        tokens.add('-');
        current = '';
        return;
      }

      tokens.add(trimmed);
      current = '';
    }

    while (i < chars.length) {
      final c = chars[i];

      // 1. Ellipsis
      if (c == '.' && i + 2 < chars.length && chars[i + 1] == '.' && chars[i + 2] == '.') {
        int dotCount = 0;
        while (i < chars.length && chars[i] == '.') {
          dotCount++;
          i++;
        }
        if (dotCount >= 3) {
          if (current.isNotEmpty) {
            current += '...';
            flushCurrent();
          } else {
            tokens.add('...');
          }
        }
        continue;
      }

      // 2. Hyphen
      if (c == '-') {
        if (isInlineHyphen(i)) {
          current += c;
          i++;
          continue;
        }
        flushCurrent();
        while (i < chars.length && chars[i] == '-') {
          i++;
        }
        tokens.add('-');
        continue;
      }

      // 3. Whitespace
      if (RegExp(r'\s').hasMatch(c)) {
        flushCurrent();
        i++;
        continue;
      }

      // 4. Special Punctuation
      if (isSpecialPunctuation(c)) {
        if (current.isNotEmpty) {
          if (const {'.', ',', '!', '?', ';', ':'}.contains(c)) {
            current += c;
            i++;
            continue;
          } else {
            flushCurrent();
          }
        }

        // Standalone punctuation/symbol (group consecutive identical characters)
        String symbol = '';
        final startChar = c;
        while (i < chars.length && chars[i] == startChar) {
          symbol += chars[i];
          i++;
        }
        tokens.add(symbol);
        continue;
      }

      // 5. Regular char
      current += c;
      i++;
    }

    flushCurrent();
    return tokens;
  }

  Future<void> _loadWords(String? bookPath) async {
    _chapters = [];
    _paragraphStarts = [];
    if (bookPath == null) {
      _words = [
        "Welcome", "to", "RSVP", "reader!", "This", "is", "a", "demo.",
        "Swipe", "up", "/", "down", "to", "change", "speed."
      ];
      _chapters = [const BookChapter(0, "Welcome")];
      _paragraphStarts = [0];
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
      final List<int> parsedParagraphs = [];
      
      bool paragraphPending = true;

      void checkParagraphPending() {
        if (paragraphPending) {
          final idx = parsedWords.length;
          if (parsedParagraphs.isEmpty) {
            parsedParagraphs.add(0);
          } else if (parsedParagraphs.last != idx) {
            parsedParagraphs.add(idx);
          }
          paragraphPending = false;
        }
      }

      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) {
          paragraphPending = true;
          continue;
        }
        if (trimmed.startsWith('@')) {
          if (trimmed.startsWith('@chapter')) {
            final title = trimmed.substring(8).trim();
            parsedChapters.add(BookChapter(parsedWords.length, title));
            paragraphPending = true;
          } else if (trimmed.startsWith('@para')) {
            paragraphPending = true;
          } else if (trimmed.startsWith('@@')) {
            paragraphPending = true;
            final rest = trimmed.substring(1);
            final tokens = _tokenizeLine(rest);
            if (tokens.isNotEmpty) {
              checkParagraphPending();
              parsedWords.addAll(tokens);
            }
          }
          continue;
        }
        final tokens = _tokenizeLine(trimmed);
        if (tokens.isNotEmpty) {
          checkParagraphPending();
          parsedWords.addAll(tokens);
        }
      }
      _words = parsedWords;
      _chapters = parsedChapters;
      _paragraphStarts = parsedParagraphs;
      if (_chapters.isEmpty) {
        _chapters = [const BookChapter(0, "Chapter 1")];
      }
      if (_paragraphStarts.isEmpty) {
        _paragraphStarts = [0];
      }
    } catch (e) {
      debugPrint("Error parsing RSVP file: $e");
      _words = [];
      _chapters = [const BookChapter(0, "Chapter 1")];
      _paragraphStarts = [0];
    }
  }

  Future<void> loadBook(String? bookPath) async {
    _currentBookPath = bookPath;
    _lastSavedIndex = -1;
    _lastSavedTimeMs = 0;
    await _loadWords(bookPath);
    _handle = await createReader(bookPath: bookPath);
    
    // Load saved progress index if available
    if (bookPath != null && !bookPath.endsWith('.rsvp_pasted.rsvp')) {
      try {
        final progress = await lib.getProgress(bookPath: bookPath);
        if (progress != null && progress.wordIndex > BigInt.zero) {
          await readerCommand(
            handle: _handle!,
            cmd: ReaderCommand.seekTo(BigInt.from(progress.wordIndex.toInt())),
            nowMs: BigInt.from(DateTime.now().millisecondsSinceEpoch),
          );
        }
      } catch (e) {
        debugPrint("Failed to load saved progress: $e");
      }
    }

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

  Future<void> _saveProgressIfNeeded() async {
    if (_handle == null || _currentBookPath == null || _state.totalWords == BigInt.zero) return;
    final currentIdx = _state.currentIndex.toInt();
    final now = DateTime.now().millisecondsSinceEpoch;

    // Save if it's the first time, or index moved by 20+ words, or 5 seconds have passed
    if (_lastSavedIndex == -1 ||
        (currentIdx - _lastSavedIndex).abs() >= 20 ||
        (now - _lastSavedTimeMs) >= 5000) {
      _lastSavedIndex = currentIdx;
      _lastSavedTimeMs = now;
      await saveProgress();
    }
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
      await _saveProgressIfNeeded();
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
      await saveProgress();
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
      await saveProgress();
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
      await saveProgress();
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
      await saveProgress();
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
      if (_currentBookPath!.endsWith('.rsvp_pasted.rsvp')) {
        return;
      }
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
