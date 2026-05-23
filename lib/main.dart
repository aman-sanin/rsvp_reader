import 'package:flutter/material.dart';
import 'package:verse/src/rust/frb_generated.dart'; // adjust path
import 'package:verse/pages/library_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init(); // add this
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Verse Reader',
      theme: ThemeData.dark(),
      home: LibraryPage(),
    );
  }
}
