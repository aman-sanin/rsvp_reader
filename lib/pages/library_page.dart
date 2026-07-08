import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:verse/src/rust/api/library.dart';
import 'package:verse/src/rust/storage/library_scanner.dart';
import 'package:verse/pages/reader_page.dart';
import 'package:verse/providers/settings_store.dart';
import 'package:verse/widgets/background_layer.dart';

class LibraryPage extends StatefulWidget {
  @override
  _LibraryPageState createState() => _LibraryPageState();
}

enum BookFilter { all, epub, rsvp }

class _LibraryPageState extends State<LibraryPage> {
  List<BookInfo> _books = [];
  bool _loading = false;
  String? _currentRoot;
  BookFilter _filter = BookFilter.all;

  @override
  void initState() {
    super.initState();
    _initLibrary().then((_) {
      _requestPermissions();
    });
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      await Permission.storage.request();
      await Permission.manageExternalStorage.request();
    }
  }

  Future<void> _initLibrary() async {
    try {
      String cacheDir;
      if (Platform.isAndroid || Platform.isIOS) {
        final dir = await getApplicationSupportDirectory();
        cacheDir = dir.path;
      } else {
        cacheDir = Platform.environment['HOME'] ?? '.';
      }
      final cachePath = '$cacheDir/.rsvp_cache.json';
      final progressPath = '$cacheDir/.rsvp_progress.json';
      await initLibrary(cacheFile: cachePath, progressFile: progressPath);

      final prefs = await SharedPreferences.getInstance();
      final savedRoot = prefs.getString('rsvp_library_root');
      if (savedRoot != null) {
        setState(() {
          _currentRoot = savedRoot;
        });
        await _loadBooks();
      }
    } catch (e) {
      debugPrint("Failed to initialize library: $e");
    }
  }

  Future<void> _pickRootDirectory() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) {
      setState(() {
        _currentRoot = selectedDirectory;
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('rsvp_library_root', selectedDirectory);
      await _loadBooks();
    }
  }

  Future<void> _loadBooks() async {
    if (_currentRoot == null) return;
    setState(() => _loading = true);
    if (!await Directory(_currentRoot!).exists()) {
      setState(() {
        _books = [];
        _loading = false;
      });
      return;
    }
    final books = await getLibrary(rootDir: _currentRoot!);
    setState(() {
      _books = books;
      _loading = false;
    });
  }

  Future<void> _convertEpub(String path) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Converting EPUB'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LinearProgressIndicator(),
              SizedBox(height: 8),
              Text('Please wait...'),
            ],
          ),
        ),
      );
      await convertEpub(epubPath: path, maxWords: BigInt.zero);
      Navigator.pop(context);
      await _loadBooks();
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Conversion complete')),
      );
    } catch (e) {
      Navigator.pop(context);
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Conversion failed: $e')),
      );
    }
  }

  Future<void> _deleteBook(String path) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      await deleteBook(bookPath: path);
      await _loadBooks();
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Book deleted successfully')),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  void _showDeleteConfirmDialog(String path, String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Book'),
        content: Text('Are you sure you want to delete "$title"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteBook(path);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsStore>(context);
    final theme = Theme.of(context);

    final filteredBooks = _books.where((book) {
      if (_filter == BookFilter.all) return true;
      if (_filter == BookFilter.epub) return book.fileType == 'epub';
      if (_filter == BookFilter.rsvp) return book.fileType == 'rsvp';
      return true;
    }).toList();

    final fontPair = settings.fontPair;
    final titleStyle = getGoogleFontStyle(
      fontPair.uiFontFamily,
      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
    );
    final subtitleStyle = getGoogleFontStyle(
      fontPair.uiFontFamily,
      textStyle: TextStyle(
        fontSize: 12,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );

    return Scaffold(
      backgroundColor: Colors.transparent, // BackgroundLayer paints background
      appBar: AppBar(
        title: Text(
          'Library',
          style: getGoogleFontStyle(
            fontPair.uiFontFamily,
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettingsDialog(context, settings),
            tooltip: 'Settings & Help',
          ),
          if (_currentRoot != null) ...[
            PopupMenuButton<BookFilter>(
              icon: const Icon(Icons.filter_list),
              tooltip: 'Filter books',
              initialValue: _filter,
              onSelected: (BookFilter value) {
                setState(() {
                  _filter = value;
                });
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<BookFilter>>[
                const PopupMenuItem<BookFilter>(
                  value: BookFilter.all,
                  child: Row(
                    children: [
                      Icon(Icons.all_inclusive, size: 20),
                      SizedBox(width: 8),
                      Text('Show All'),
                    ],
                  ),
                ),
                const PopupMenuItem<BookFilter>(
                  value: BookFilter.rsvp,
                  child: Row(
                    children: [
                      Icon(Icons.text_snippet_outlined, size: 20),
                      SizedBox(width: 8),
                      Text('RSVP Only'),
                    ],
                  ),
                ),
                const PopupMenuItem<BookFilter>(
                  value: BookFilter.epub,
                  child: Row(
                    children: [
                      Icon(Icons.book_outlined, size: 20),
                      SizedBox(width: 8),
                      Text('EPUB Only'),
                    ],
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.folder_open),
              onPressed: _pickRootDirectory,
              tooltip: 'Change library folder',
            ),
          ],
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: BackgroundLayer(themeMode: settings.themeMode),
          ),
          SafeArea(
            child: _currentRoot == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'No library folder selected.',
                          style: getGoogleFontStyle(
                            fontPair.uiFontFamily,
                            textStyle: const TextStyle(fontSize: 16),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _pickRootDirectory,
                          icon: const Icon(Icons.folder_open),
                          label: Text(
                            'Select Library Folder',
                            style: getGoogleFontStyle(fontPair.uiFontFamily),
                          ),
                        ),
                      ],
                    ),
                  )
                : _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _books.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'No books found in $_currentRoot',
                                  style: getGoogleFontStyle(
                                    fontPair.uiFontFamily,
                                    textStyle: const TextStyle(fontSize: 15),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: _loadBooks,
                                  icon: const Icon(Icons.refresh),
                                  label: Text(
                                    'Refresh',
                                    style: getGoogleFontStyle(
                                      fontPair.uiFontFamily,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            itemCount: filteredBooks.length + 1,
                            itemBuilder: (_, i) {
                              if (i == 0) {
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.15),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(
                                      color: theme.colorScheme.primary.withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    leading: CircleAvatar(
                                      backgroundColor: theme.colorScheme.primary,
                                      child: const Icon(
                                        Icons.paste_outlined,
                                        color: Colors.white,
                                      ),
                                    ),
                                    title: Text(
                                      'Pasted Text Reader',
                                      style: titleStyle.copyWith(
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'Read text from your clipboard or type custom text.',
                                      style: subtitleStyle,
                                    ),
                                    onTap: () async {
                                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                                      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
                                      final text = clipboardData?.text;
                                      if (text == null || text.trim().isEmpty) {
                                        scaffoldMessenger.showSnackBar(
                                          const SnackBar(content: Text('Clipboard is empty')),
                                        );
                                        return;
                                      }

                                      String cacheDir;
                                      if (Platform.isAndroid || Platform.isIOS) {
                                        final dir = await getApplicationSupportDirectory();
                                        cacheDir = dir.path;
                                      } else {
                                        cacheDir = Platform.environment['HOME'] ?? '.';
                                      }
                                      final rsvpPath = '$cacheDir/.rsvp_pasted.rsvp';
                                      final file = File(rsvpPath);
                                      
                                      final buffer = StringBuffer();
                                      buffer.writeln('@rsvp 1');
                                      buffer.writeln('@title Pasted Text');
                                      buffer.writeln('@author Guest');
                                      buffer.writeln();

                                      final lines = text.split('\n');
                                      for (final line in lines) {
                                        final trimmedLine = line.trim();
                                        if (trimmedLine.isEmpty) {
                                          buffer.writeln('@para');
                                        } else {
                                          buffer.writeln(trimmedLine);
                                        }
                                      }
                                      await file.writeAsString(buffer.toString());

                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              ReaderPage(bookPath: rsvpPath),
                                        ),
                                      );

                                      try {
                                        if (await file.exists()) {
                                          await file.delete();
                                        }
                                      } catch (e) {
                                        debugPrint("Failed to delete temp file: $e");
                                      }

                                      await _loadBooks();
                                    },
                                  ),
                                );
                              }

                              final book = filteredBooks[i - 1];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                color: theme.colorScheme.surfaceContainerLow
                                    .withValues(alpha: 0.8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: theme.colorScheme.outlineVariant
                                        .withValues(alpha: 0.3),
                                  ),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        theme.colorScheme.primaryContainer,
                                    child: Icon(
                                      Icons.book_outlined,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  title: Text(
                                    book.title,
                                    style: titleStyle,
                                  ),
                                  subtitle: Text(
                                    '${book.author.isNotEmpty ? book.author : "Unknown Author"} • ${book.progressPercent ?? 0}% read',
                                    style: subtitleStyle,
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (book.fileType == 'epub')
                                        IconButton(
                                          icon: const Icon(Icons.get_app),
                                          onPressed: () => _convertEpub(book.path),
                                          tooltip: 'Convert to RSVP',
                                        ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.redAccent,
                                        ),
                                        onPressed: () =>
                                            _showDeleteConfirmDialog(
                                          book.path,
                                          book.title,
                                        ),
                                        tooltip: 'Delete Book',
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            ReaderPage(bookPath: book.path),
                                      ),
                                    ).then((_) => _loadBooks());
                                  },
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
      floatingActionButton: _currentRoot != null
          ? FloatingActionButton(
              onPressed: _loadBooks,
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              child: const Icon(Icons.refresh),
            )
          : null,
    );
  }

  void _showSettingsDialog(BuildContext context, SettingsStore settings) {
    final theme = Theme.of(context);
    final fontPair = settings.fontPair;
    final titleStyle = getGoogleFontStyle(
      fontPair.uiFontFamily,
      textStyle: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 18,
        color: theme.colorScheme.primary,
      ),
    );
    final sectionHeaderStyle = getGoogleFontStyle(
      fontPair.uiFontFamily,
      textStyle: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 14,
        color: theme.colorScheme.primary,
        letterSpacing: 1.1,
      ),
    );
    final bodyStyle = getGoogleFontStyle(
      fontPair.uiFontFamily,
      textStyle: TextStyle(
        fontSize: 14,
        color: theme.colorScheme.onSurface,
        height: 1.5,
      ),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Settings & Help', style: titleStyle),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // RSVP EXPLANATION
                  Text('WHAT IS RSVP?', style: sectionHeaderStyle),
                  const SizedBox(height: 8),
                  Text(
                    'Rapid Serial Visual Presentation (RSVP) is a reading technique where words are displayed sequentially at a single focal point. By eliminating eye movement (saccades), RSVP reduces cognitive load and allows you to read at much higher speeds. You can customize the pacing, fonts, themes, and ORP alignment from the settings panel during reading.',
                    style: bodyStyle,
                  ),
                  const SizedBox(height: 24),

                  // TUTORIAL / HOW TO USE
                  Text('TUTORIAL & GESTURES', style: sectionHeaderStyle),
                  const SizedBox(height: 12),
                  _buildTutorialItem(
                    Icons.play_arrow_outlined,
                    'Play / Pause',
                    'Single-tap anywhere on the reader screen to pause or resume reading.',
                    bodyStyle,
                    theme,
                  ),
                  _buildTutorialItem(
                    Icons.swap_vert,
                    'Adjust WPM Speed',
                    'Swipe UP or DOWN on the reader screen to increase or decrease words-per-minute (WPM) reading speed.',
                    bodyStyle,
                    theme,
                  ),
                  _buildTutorialItem(
                    Icons.zoom_in,
                    'Adjust Font Size',
                    'Use a pinch gesture (pinch to zoom) with two fingers on the reader screen to scale text size on the fly.',
                    bodyStyle,
                    theme,
                  ),
                  _buildTutorialItem(
                    Icons.toc,
                    'Chapter Drawer',
                    'Tap the list icon in the top header to slide open the Table of Contents drawer and jump to any chapter.',
                    bodyStyle,
                    theme,
                  ),
                  _buildTutorialItem(
                    Icons.skip_previous,
                    'Skip Paragraphs',
                    'Use the left skip button next to the play controls to instantly rewind to the start of the paragraph.',
                    bodyStyle,
                    theme,
                  ),
                  _buildTutorialItem(
                    Icons.settings_outlined,
                    'Double-Tap for Settings',
                    'Double-tap or long-press on the reader screen to slide up the advanced pacing, guide lines, font pairs, and ORP color config panel.',
                    bodyStyle,
                    theme,
                  ),
                  const Divider(height: 32),

                  // GLOBAL APP SETTINGS
                  Text('GLOBAL SETTINGS', style: sectionHeaderStyle),
                  const SizedBox(height: 16),

                  // Theme Selection
                  Text('Theme Mode', style: bodyStyle.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: ThemeModeOption.values.map((opt) {
                      final isSelected = settings.themeMode == opt;
                      final name = opt == ThemeModeOption.dark
                          ? 'Dark'
                          : opt == ThemeModeOption.light
                              ? 'Light'
                              : 'Sepia';
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: ChoiceChip(
                            label: Text(name),
                            selected: isSelected,
                            onSelected: (_) => settings.setThemeMode(opt),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Reset Defaults Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        settings.resetToDefaults();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Settings reset to defaults')),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: theme.colorScheme.outlineVariant),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      icon: const Icon(Icons.restore),
                      label: Text(
                        'Reset All Settings to Defaults',
                        style: bodyStyle.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTutorialItem(
    IconData icon,
    String title,
    String description,
    TextStyle bodyStyle,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Icon(icon, size: 18, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: bodyStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: bodyStyle.copyWith(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
