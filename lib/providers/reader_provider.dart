import 'dart:async';
import 'package:flutter/material.dart';
import 'package:verse/src/rust/api/reader.dart';
import 'package:verse/src/rust/api/library.dart' as lib;

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

  ReaderState get state => _state;
  bool get isPlaying => _state.isPlaying;

  Future<void> loadBook(String? bookPath) async {
    _currentBookPath = bookPath;
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

  @override
  void dispose() {
    saveProgress();
    _timer?.cancel();
    super.dispose();
  }
}
