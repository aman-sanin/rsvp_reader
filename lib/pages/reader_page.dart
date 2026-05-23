import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:verse/providers/reader_provider.dart';

class ReaderPage extends StatefulWidget {
  final String? bookPath;
  const ReaderPage({Key? key, this.bookPath}) : super(key: key);

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  late ReaderProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = ReaderProvider();
    _provider.loadBook(widget.bookPath);
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Reading'),
          actions: [
            IconButton(
              icon: const Icon(Icons.speed),
              onPressed: () => _showSpeedDialog(),
            ),
          ],
        ),
        body: GestureDetector(
          onTap: () => _provider.togglePlayPause(),
          onVerticalDragUpdate: (details) {
            if (details.delta.dy < -5) {
              _provider.adjustWpm(1);
            } else if (details.delta.dy > 5) {
              _provider.adjustWpm(-1);
            }
          },
          onHorizontalDragUpdate: (details) {
            if (details.delta.dx < -5) {
              _provider.scrub(-1);
            } else if (details.delta.dx > 5) {
              _provider.scrub(1);
            }
          },
          child: Consumer<ReaderProvider>(
            builder: (ctx, provider, child) {
              final state = provider.state;
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Current word
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        state.currentWord,
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 40),
                    // WPM and progress
                    Text('${state.wpm} WPM'),
                    Text('${state.progressPercent}%'),
                    const SizedBox(height: 20),
                    // Play/pause indicator
                    if (!state.isPlaying)
                      const Icon(Icons.pause_circle_outline, size: 48),
                    // Simple scrub bar (optional)
                    Slider(
                      min: 0,
                      max: state.totalWords.toDouble(),
                      value: state.currentIndex.toDouble(),
                      onChanged: (value) => provider.seekTo(value.toInt()),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showSpeedDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set WPM'),
        content: StatefulBuilder(
          builder: (ctx, setStateDialog) {
            final wpm = _provider.state.wpm;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$wpm WPM'),
                Slider(
                  min: 100,
                  max: 800,
                  value: wpm.toDouble(),
                  onChanged: (value) {
                    setStateDialog(() {});
                    _provider.setWpm(value.toInt());
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
