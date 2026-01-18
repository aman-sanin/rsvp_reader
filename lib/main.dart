// lib/main.dart
import 'package:flutter/material.dart';
import 'package:rsvp_reader/src/rust/frb_generated.dart';
import 'package:rsvp_reader/screens/reader_screen.dart';

Future<void> main() async {
  await RustLib.init();
  runApp(const MaterialApp(home: ReaderScreen()));
}
