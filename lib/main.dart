// lib/main.dart
import 'package:flutter/material.dart';
import 'package:rsvp_reader/src/rust/frb_generated.dart';
import 'package:rsvp_reader/screens/reader_screen.dart';

Future<void> main() async {
  await RustLib.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RSVP Reader',

      // 1. Set the Dark Theme
      themeMode: ThemeMode.dark,

      // 2. Define what "Dark" looks like
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF000000), // Deep dark grey
        primaryColor: Colors.redAccent,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          elevation: 0,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.redAccent,
          foregroundColor: Colors.white,
        ),
        colorScheme: const ColorScheme.dark(
          primary: Colors.redAccent,
          secondary: Colors.redAccent,
        ),
        useMaterial3: true,
      ),

      home: const ReaderScreen(),
    );
  }
}
