import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:verse/providers/settings_store.dart';
import 'package:verse/providers/reader_provider.dart';
import 'package:verse/src/theme_system.dart';
import 'package:verse/widgets/rsvp_display.dart';
import 'package:verse/widgets/settings_panel.dart';

class ReaderPage extends StatefulWidget {
  final String? bookPath;

  const ReaderPage({Key? key, this.bookPath}) : super(key: key);

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  late ReaderProvider _provider;
  final FocusNode _focusNode = FocusNode();

  // Auto-hide controls timer
  Timer? _autoHideTimer;
  double _controlsOpacity = 1.0;

  // Gesture toasts state
  int? _wpmToastValue;
  Timer? _wpmToastTimer;

  int? _fontSizeToastValue;
  Timer? _fontSizeToastTimer;

  // Cumulative drag offsets
  double _scaleStartFontSize = 36;
  double _cumulativeVerticalDrag = 0;
  double _cumulativeHorizontalDrag = 0;

  // Keyboard shortcut tracking
  bool _settingsOpen = false;

  @override
  void initState() {
    super.initState();
    _provider = ReaderProvider();
    _provider.loadBook(widget.bookPath).then((_) {
      // Sync WPM speed from settings store to Rust reader loop
      final settings = Provider.of<SettingsStore>(context, listen: false);
      _provider.setWpm(settings.wpm);
      _provider.setPacing(settings.pacingConfig);
    });

    _resetAutoHideTimer();
    // Focus the node to start receiving keyboard events
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _autoHideTimer?.cancel();
    _wpmToastTimer?.cancel();
    _fontSizeToastTimer?.cancel();
    _focusNode.dispose();
    _provider.dispose();
    super.dispose();
  }

  void _resetAutoHideTimer() {
    final settings = Provider.of<SettingsStore>(context, listen: false);
    _autoHideTimer?.cancel();
    if (mounted && _controlsOpacity != 1.0) {
      setState(() {
        _controlsOpacity = 1.0;
      });
    }

    if (settings.autoHideControls) {
      _autoHideTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _controlsOpacity = 0.15;
          });
        }
      });
    }
  }

  void _showWpmToast(int wpm) {
    _wpmToastTimer?.cancel();
    setState(() {
      _wpmToastValue = wpm;
    });
    _wpmToastTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _wpmToastValue = null;
        });
      }
    });
  }

  void _showFontSizeToast(int size) {
    _fontSizeToastTimer?.cancel();
    setState(() {
      _fontSizeToastValue = size;
    });
    _fontSizeToastTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _fontSizeToastValue = null;
        });
      }
    });
  }

  void _openSettingsPanel(SettingsStore settings) {
    _provider.pause();
    setState(() => _settingsOpen = true);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.75,
          child: SettingsPanel(
            onPastedTextChanged: (rsvpPath) {
              _provider.loadBook(rsvpPath).then((_) {
                _provider.setWpm(settings.wpm);
                _provider.setPacing(settings.pacingConfig);
              });
            },
          ),
        );
      },
    ).then((_) {
      setState(() => _settingsOpen = false);
      _focusNode.requestFocus();
    });
  }

  void _handleKeyEvent(KeyEvent event, SettingsStore settings) {
    if (event is! KeyDownEvent) return;

    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.space) {
      _provider.togglePlayPause();
      _resetAutoHideTimer();
    } else if (key == LogicalKeyboardKey.arrowRight || key == LogicalKeyboardKey.keyL) {
      _provider.scrub(5);
      _resetAutoHideTimer();
    } else if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.keyJ) {
      _provider.scrub(-5);
      _resetAutoHideTimer();
    } else if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.keyK) {
      final newWpm = settings.wpm + 25;
      settings.setWpm(newWpm);
      _provider.setWpm(newWpm);
      _showWpmToast(newWpm);
      _resetAutoHideTimer();
    } else if (key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.semicolon) {
      final newWpm = settings.wpm - 25;
      settings.setWpm(newWpm);
      _provider.setWpm(newWpm);
      _showWpmToast(newWpm);
      _resetAutoHideTimer();
    } else if (key == LogicalKeyboardKey.equal || key == LogicalKeyboardKey.add) {
      settings.setFontSize(settings.fontSize + 2);
      _showFontSizeToast(settings.fontSize.round());
      _resetAutoHideTimer();
    } else if (key == LogicalKeyboardKey.minus) {
      settings.setFontSize(settings.fontSize - 2);
      _showFontSizeToast(settings.fontSize.round());
      _resetAutoHideTimer();
    } else if (key == LogicalKeyboardKey.escape) {
      if (_settingsOpen) {
        Navigator.pop(context);
      } else {
        _provider.pause();
      }
      _resetAutoHideTimer();
    } else if (key == LogicalKeyboardKey.keyS) {
      _openSettingsPanel(settings);
    } else if (key == LogicalKeyboardKey.keyR) {
      _provider.seekTo(0);
      _resetAutoHideTimer();
    } else if (key == LogicalKeyboardKey.keyT) {
      // Cycle Theme Option
      final nextIndex = (settings.themeMode.index + 1) % ThemeModeOption.values.length;
      settings.setThemeMode(ThemeModeOption.values[nextIndex]);
      _resetAutoHideTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsStore>(context);
    final theme = Theme.of(context);

    // Sync speed limit settings into Rust loop
    _provider.setWpm(settings.wpm);
    _provider.setPacing(settings.pacingConfig);

    return AnimatedTheme(
      duration: const Duration(milliseconds: 600),
      data: settings.themeMode == ThemeModeOption.dark
          ? ThemeSystem.getDarkTheme()
          : settings.themeMode == ThemeModeOption.light
              ? ThemeSystem.getLightTheme()
              : ThemeSystem.getSepiaTheme(),
      child: ChangeNotifierProvider<ReaderProvider>.value(
        value: _provider,
        child: Scaffold(
          // Drawer sliding from the right for chapters list
          endDrawer: Drawer(
            backgroundColor: theme.colorScheme.surface,
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      'CHAPTERS',
                      style: getGoogleFontStyle(
                        settings.fontPair.uiFontFamily,
                        textStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: theme.colorScheme.primary,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: Consumer<ReaderProvider>(
                      builder: (context, provider, child) {
                        final currentTitle = provider.currentChapterTitle;
                        return ListView.builder(
                          itemCount: provider.chapters.length,
                          itemBuilder: (context, idx) {
                            final chap = provider.chapters[idx];
                            final isSelected = chap.title == currentTitle;
                            return ListTile(
                              selected: isSelected,
                              selectedColor: theme.colorScheme.primary,
                              title: Text(
                                chap.title,
                                style: getGoogleFontStyle(
                                  settings.fontPair.uiFontFamily,
                                  textStyle: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              trailing: Text(
                                'Word ${chap.wordIndex}',
                                style: getGoogleFontStyle(
                                  settings.fontPair.uiFontFamily,
                                  textStyle: TextStyle(
                                    fontSize: 11,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              onTap: () {
                                _resetAutoHideTimer();
                                provider.seekTo(chap.wordIndex);
                                Navigator.pop(context); // Close drawer
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          body: Focus(
            focusNode: _focusNode,
            autofocus: true,
            onKeyEvent: (node, event) {
              _handleKeyEvent(event, settings);
              return KeyEventResult.handled;
            },
            child: Stack(
              children: [
                // Layer 1 - Background Stage (Solid plain color for reader)
                Positioned.fill(
                  child: Container(color: theme.colorScheme.surface),
                ),

                // Layer 2 - Reader Stage & Gesture Handler
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () {
                      _provider.togglePlayPause();
                      _resetAutoHideTimer();
                    },
                    onDoubleTap: () => _openSettingsPanel(settings),
                    onLongPress: () => _openSettingsPanel(settings),
                    onScaleStart: (details) {
                      _scaleStartFontSize = settings.fontSize;
                      _cumulativeVerticalDrag = 0;
                      _cumulativeHorizontalDrag = 0;
                      _resetAutoHideTimer();
                    },
                    onScaleUpdate: (details) {
                      _resetAutoHideTimer();
                      if (details.pointerCount == 2) {
                        // Pinch-zoom scales font size
                        final newSize = _scaleStartFontSize * details.scale;
                        settings.setFontSize(newSize);
                        _showFontSizeToast(settings.fontSize.round());
                      } else if (details.pointerCount == 1) {
                        // One-finger drag
                        final dx = details.focalPointDelta.dx;
                        final dy = details.focalPointDelta.dy;

                        if (dy.abs() > dx.abs()) {
                          // Vertical drag -> Speed adjustments
                          _cumulativeVerticalDrag += dy;
                          if (_cumulativeVerticalDrag.abs() > 40) {
                            final change = (_cumulativeVerticalDrag > 0) ? -25 : 25;
                            final nextWpm = settings.wpm + change;
                            settings.setWpm(nextWpm);
                            _provider.setWpm(nextWpm);
                            _showWpmToast(nextWpm);
                            _cumulativeVerticalDrag = 0;
                          }
                        } else {
                          // Horizontal drag -> Scrubbing
                          _cumulativeHorizontalDrag += dx;
                          if (_cumulativeHorizontalDrag.abs() > 30) {
                            final steps = (_cumulativeHorizontalDrag > 0) ? -5 : 5;
                            _provider.scrub(steps);
                            _cumulativeHorizontalDrag = 0;
                          }
                        }
                      }
                    },
                    child: MouseRegion(
                      onHover: (_) => _resetAutoHideTimer(),
                      child: Consumer<ReaderProvider>(
                        builder: (context, provider, child) {
                          final state = provider.state;
                          final displayWord = state.atEnd ? 'DONE' : state.currentWord;

                          // Context words retrieval
                          String prevWordText = '';
                          String nextWordText = '';
                          final wordList = provider.words;
                          final currentIdx = state.currentIndex.toInt();

                          if (!state.atEnd && wordList.isNotEmpty && currentIdx < wordList.length) {
                            if (currentIdx > 0) {
                              prevWordText = wordList[currentIdx - 1];
                            }
                            if (currentIdx + 1 < wordList.length) {
                              nextWordText = wordList[currentIdx + 1];
                            }
                          }

                          // Top statistics calculations
                          final remainingWords = state.totalWords - state.currentIndex;
                          final minRemaining = (remainingWords.toInt() / settings.wpm).ceil();

                          return Column(
                            children: [
                              // Top Stats
                              SafeArea(
                                bottom: false,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Library Back Button
                                      IconButton(
                                        icon: Icon(
                                          Icons.arrow_back,
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                        onPressed: () {
                                          _provider.pause();
                                          Navigator.pop(context);
                                        },
                                      ),
                                      // Current Chapter Title
                                      Expanded(
                                        child: Center(
                                          child: Text(
                                            provider.currentChapterTitle,
                                            overflow: TextOverflow.ellipsis,
                                            style: getGoogleFontStyle(
                                              settings.fontPair.uiFontFamily,
                                              textStyle: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: theme.colorScheme.onSurface,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Chapters List Icon Triggering endDrawer sliding from right
                                      Builder(
                                        builder: (scaffoldContext) {
                                          return IconButton(
                                            icon: Icon(
                                              Icons.toc,
                                              color: theme.colorScheme.onSurfaceVariant,
                                            ),
                                            onPressed: () {
                                              _provider.pause();
                                              Scaffold.of(scaffoldContext).openEndDrawer();
                                            },
                                            tooltip: 'Chapters list',
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Word stats line
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Word ${state.currentIndex} / ${state.totalWords}',
                                      style: getGoogleFontStyle(
                                        settings.fontPair.uiFontFamily,
                                        textStyle: TextStyle(
                                          fontSize: 11,
                                          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '~${minRemaining}m remaining',
                                      style: getGoogleFontStyle(
                                        settings.fontPair.uiFontFamily,
                                        textStyle: TextStyle(
                                          fontSize: 11,
                                          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Display Area
                              Expanded(
                                child: Center(
                                  child: RsvpDisplay(
                                    word: displayWord,
                                    prevWord: prevWordText,
                                    nextWord: nextWordText,
                                    fontSize: settings.fontSize,
                                    orpPercent: settings.orpPercent,
                                    fontPair: settings.fontPair,
                                    showGuideLine: settings.showGuideLine,
                                    contextWordsMode: settings.contextWordsMode,
                                    orpColor: settings.orpColor,
                                  ),
                                ),
                              ),

                              // PAUSED overlay indicator
                              if (!state.isPlaying && !state.atEnd)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Text(
                                    'PAUSED',
                                    style: getGoogleFontStyle(
                                      settings.fontPair.uiFontFamily,
                                      textStyle: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ),
                                ),

                              // Bottom Navigation and Progress Bar
                              AnimatedOpacity(
                                opacity: _controlsOpacity,
                                duration: const Duration(milliseconds: 300),
                                child: Column(
                                  children: [
                                    // Progress Bar Slider Container
                                    if (state.totalWords > BigInt.zero)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 40),
                                        child: SliderTheme(
                                          data: SliderThemeData(
                                            trackHeight: 2.0,
                                            activeTrackColor: theme.colorScheme.primary,
                                            inactiveTrackColor: theme.colorScheme.outlineVariant,
                                            thumbColor: theme.colorScheme.primary,
                                            thumbShape: const RoundSliderThumbShape(
                                              enabledThumbRadius: 6,
                                            ),
                                            overlayShape: const RoundSliderOverlayShape(
                                              overlayRadius: 14,
                                            ),
                                          ),
                                          child: Slider(
                                            value: state.currentIndex.toDouble().clamp(
                                                  0.0,
                                                  state.totalWords.toDouble(),
                                                ),
                                            min: 0.0,
                                            max: state.totalWords.toDouble(),
                                            onChanged: (val) {
                                              _resetAutoHideTimer();
                                              _provider.seekTo(val.toInt());
                                            },
                                          ),
                                        ),
                                      ),

                                    // Transport controls
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 24, top: 8),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.skip_previous),
                                            iconSize: 24,
                                            color: theme.colorScheme.onSurfaceVariant,
                                            onPressed: () {
                                              _resetAutoHideTimer();
                                              _provider.rewindSentence();
                                            },
                                          ),
                                          const SizedBox(width: 32),
                                          IconButton(
                                            icon: Icon(
                                              state.isPlaying
                                                  ? Icons.pause
                                                  : Icons.play_arrow,
                                            ),
                                            iconSize: 32,
                                            color: theme.colorScheme.onSurface,
                                            onPressed: () {
                                              _resetAutoHideTimer();
                                              _provider.togglePlayPause();
                                            },
                                          ),
                                          const SizedBox(width: 32),
                                          IconButton(
                                            icon: const Icon(Icons.settings),
                                            iconSize: 24,
                                            color: theme.colorScheme.onSurfaceVariant,
                                            onPressed: () {
                                              _resetAutoHideTimer();
                                              _openSettingsPanel(settings);
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),

                // Float Overlays - large visual toasts for WPM and Font Size adjustments
                if (_wpmToastValue != null)
                  IgnorePointer(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '$_wpmToastValue WPM',
                          style: getGoogleFontStyle(
                            settings.fontPair.uiFontFamily,
                            textStyle: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                if (_fontSizeToastValue != null)
                  IgnorePointer(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'Font Size: $_fontSizeToastValue',
                          style: getGoogleFontStyle(
                            settings.fontPair.uiFontFamily,
                            textStyle: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
