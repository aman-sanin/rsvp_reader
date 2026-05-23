import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:verse/src/rust/api/library.dart';
import 'package:verse/src/rust/storage/library_scanner.dart';
import 'package:verse/pages/reader_page.dart';

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
    _initLibrary();
  }

  Future<void> _initLibrary() async {
    // On Linux, store cache files in the user's home directory
    final home = Platform.environment['HOME'] ?? '.';
    final cachePath = '$home/.rsvp_cache.json';
    final progressPath = '$home/.rsvp_progress.json';
    await initLibrary(cacheFile: cachePath, progressFile: progressPath);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        actions: [
          if (_currentRoot != null)
            IconButton(
              icon: const Icon(Icons.folder_open),
              onPressed: _pickRootDirectory,
              tooltip: 'Change library folder',
            ),
        ],
      ),
      body: _currentRoot == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No library folder selected.'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _pickRootDirectory,
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Select Library Folder'),
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
                  Text('No books found in $_currentRoot'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loadBooks,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _books.length,
              itemBuilder: (_, i) {
                final book = _books[i];
                return ListTile(
                  leading: const Icon(Icons.book),
                  title: Text(book.title),
                  subtitle: Text(
                    '${book.author} - ${book.progressPercent ?? 0}%',
                  ),
                  trailing: book.fileType == 'epub'
                      ? IconButton(
                          icon: const Icon(Icons.get_app),
                          onPressed: () => _convertEpub(book.path),
                        )
                      : null,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReaderPage(bookPath: book.path),
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: _currentRoot != null
          ? FloatingActionButton(
              onPressed: _loadBooks,
              child: const Icon(Icons.refresh),
            )
          : null,
    );
  }
}
