import 'package:flutter/material.dart';

class ThemeSystem {
  static ThemeData getDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0F0F0F),
      colorScheme: const ColorScheme.dark(
        surface: Color(0xFF0F0F0F),
        surfaceContainerLow: Color(0xFF1A1A1A),
        onSurface: Color(0xFFE8E4DE),
        onSurfaceVariant: Color(0xFF6B6560),
        primary: Color(0xFFE8A849),
        primaryContainer: Color(0x14E8A849), // 8% opacity
        surfaceContainerHighest: Color(0xFF161616),
        outlineVariant: Color(0xFF2A2725),
      ),
    );
  }

  static ThemeData getLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF5F0E8),
      colorScheme: const ColorScheme.light(
        surface: Color(0xFFF5F0E8),
        surfaceContainerLow: Color(0xFFEBE5D9),
        onSurface: Color(0xFF1A1714),
        onSurfaceVariant: Color(0xFF8A837A),
        primary: Color(0xFFC47D1A),
        primaryContainer: Color(0x14C47D1A), // 8% opacity
        surfaceContainerHighest: Color(0xFFFFFFFF),
        outlineVariant: Color(0xFFD9D2C7),
      ),
    );
  }

  static ThemeData getSepiaTheme() {
    // Custom theme acting as a darker warm sepia as specified: `#2c2418` background
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF2C2418),
      colorScheme: const ColorScheme.dark(
        surface: Color(0xFF2C2418),
        surfaceContainerLow: Color(0xFF352B1F),
        onSurface: Color(0xFFD4C4A8),
        onSurfaceVariant: Color(0xFF7A6E5A),
        primary: Color(0xFFC4956A),
        primaryContainer: Color(0x14C4956A), // 8% opacity
        surfaceContainerHighest: Color(0xFF332820),
        outlineVariant: Color(0xFF4A3E30),
      ),
    );
  }
}
