import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:verse/src/rust/frb_generated.dart';
import 'package:verse/pages/library_page.dart';
import 'package:verse/providers/settings_store.dart';
import 'package:verse/src/theme_system.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsStore()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsStore>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Verse Reader',
      theme: settings.themeMode == ThemeModeOption.dark
          ? ThemeSystem.getDarkTheme()
          : settings.themeMode == ThemeModeOption.light
              ? ThemeSystem.getLightTheme()
              : ThemeSystem.getSepiaTheme(),
      home: LibraryPage(),
    );
  }
}
