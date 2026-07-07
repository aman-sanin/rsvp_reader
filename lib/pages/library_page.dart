import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:verse/src/rust/api/library.dart';
import 'package:verse/src/rust/storage/library_scanner.dart';
import 'package:verse/pages/reader_page.dart';
import 'package:verse/providers/settings_store.dart';
import 'package:verse/widgets/background_layer.dart';

class LibraryPage extends StatefulWidget {
  @override
  _LibraryPageState createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  List<BookInfo> _books = [];
  bool _loading = false;
  String? _currentRoot;

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
          if (_currentRoot != null)
            IconButton(
              icon: const Icon(Icons.folder_open),
              onPressed: _pickRootDirectory,
              tooltip: 'Change library folder',
            ),
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
                            itemCount: _books.length + 1,
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
                                      String cacheDir;
                                      if (Platform.isAndroid || Platform.isIOS) {
                                        final dir = await getApplicationSupportDirectory();
                                        cacheDir = dir.path;
                                      } else {
                                        cacheDir = Platform.environment['HOME'] ?? '.';
                                      }
                                      final rsvpPath = '$cacheDir/.rsvp_pasted.rsvp';
                                      final file = File(rsvpPath);
                                      if (!await file.exists()) {
                                        final buffer = StringBuffer();
                                        buffer.writeln('@rsvp 1');
                                        buffer.writeln('@title Pasted Text');
                                        buffer.writeln('@author Guest');
                                        buffer.writeln();
                                        buffer.writeln(settings.pastedText);
                                        await file.writeAsString(buffer.toString());
                                      }

                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              ReaderPage(bookPath: rsvpPath),
                                        ),
                                      ).then((_) => _loadBooks());
                                    },
                                  ),
                                );
                              }

                              final book = _books[i - 1];
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
}
