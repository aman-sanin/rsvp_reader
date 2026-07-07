import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:verse/src/rust/core/pacing.dart'; // import PacingConfig

class FontPair {
  final String id;
  final String label;
  final String readingFontFamily;
  final String uiFontFamily;

  const FontPair({
    required this.id,
    required this.label,
    required this.readingFontFamily,
    required this.uiFontFamily,
  });
}

const List<FontPair> fontPairs = [
  FontPair(
    id: 'Geometric',
    label: 'Geometric',
    readingFontFamily: 'SpaceMono',
    uiFontFamily: 'SpaceGrotesk',
  ),
  FontPair(
    id: 'Warm',
    label: 'Warm',
    readingFontFamily: 'SourceCodePro',
    uiFontFamily: 'SourceSans3',
  ),
  FontPair(
    id: 'Crisp',
    label: 'Crisp',
    readingFontFamily: 'JetBrainsMono',
    uiFontFamily: 'Inter',
  ),
  FontPair(
    id: 'Editorial',
    label: 'Editorial',
    readingFontFamily: 'IBMPlexMono',
    uiFontFamily: 'IBMPlexSans',
  ),
  FontPair(
    id: 'Friendly',
    label: 'Friendly',
    readingFontFamily: 'FiraCode',
    uiFontFamily: 'FiraSans',
  ),
];

TextStyle getGoogleFontStyle(String fontFamily, {TextStyle? textStyle}) {
  switch (fontFamily) {
    case 'SpaceMono':
      return GoogleFonts.spaceMono(textStyle: textStyle);
    case 'SpaceGrotesk':
      return GoogleFonts.spaceGrotesk(textStyle: textStyle);
    case 'SourceCodePro':
      return GoogleFonts.sourceCodePro(textStyle: textStyle);
    case 'SourceSans3':
      return GoogleFonts.sourceSans3(textStyle: textStyle);
    case 'JetBrainsMono':
      return GoogleFonts.jetBrainsMono(textStyle: textStyle);
    case 'Inter':
      return GoogleFonts.inter(textStyle: textStyle);
    case 'IBMPlexMono':
      return GoogleFonts.ibmPlexMono(textStyle: textStyle);
    case 'IBMPlexSans':
      return GoogleFonts.ibmPlexSans(textStyle: textStyle);
    case 'FiraCode':
      return GoogleFonts.firaMono(
        textStyle: textStyle,
      ); // Google Fonts has firaMono, which is excellent
    case 'FiraSans':
      return GoogleFonts.firaSans(textStyle: textStyle);
    default:
      return GoogleFonts.spaceMono(textStyle: textStyle);
  }
}

enum ThemeModeOption { dark, light, sepia }

enum ContextWordsMode { hidden, greyed, greyedLine }

class SettingsStore extends ChangeNotifier {
  SharedPreferences? _prefs;

  ThemeModeOption _themeMode = ThemeModeOption.dark;
  String _fontPairId = 'Geometric';
  int _wpm = 350;
  double _fontSize = 36.0;
  double _orpPercent = 0.33;
  bool _showGuideLine = true;
  ContextWordsMode _contextWordsMode = ContextWordsMode.hidden;

  // Behavior & Pacing
  bool _pauseAtPunctuation = true;
  bool _pauseAtSentenceEnd = true;
  int _punctuationDelayMs = 200;
  int _longWordDelayMs = 200;
  int _complexWordDelayMs = 200;
  int _punctuationScalePercent = 100;
  int _longWordScalePercent = 100;
  int _complexWordScalePercent = 100;
  bool _autoHideControls = true;
  String _orpColor = 'red';

  // Last pasted text
  String _pastedText =
      "Rapid Serial Visual Presentation (RSVP) is a reading technique where words are displayed sequentially at a single focal point. By eliminating eye movement (saccades), RSVP reduces cognitive load and allows you to read at much higher speeds. You can customize the pacing, fonts, themes, and ORP alignment from the settings panel below.";

  SettingsStore() {
    _loadPrefs();
  }

  // Getters
  ThemeModeOption get themeMode => _themeMode;
  String get fontPairId => _fontPairId;
  FontPair get fontPair =>
      fontPairs.firstWhere((p) => p.id == _fontPairId, orElse: () => fontPairs[0]);
  int get wpm => _wpm;
  double get fontSize => _fontSize;
  double get orpPercent => _orpPercent;
  bool get showGuideLine => _showGuideLine;
  ContextWordsMode get contextWordsMode => _contextWordsMode;
  bool get pauseAtPunctuation => _pauseAtPunctuation;
  bool get pauseAtSentenceEnd => _pauseAtSentenceEnd;
  int get punctuationDelayMs => _punctuationDelayMs;
  int get longWordDelayMs => _longWordDelayMs;
  int get complexWordDelayMs => _complexWordDelayMs;
  int get punctuationScalePercent => _punctuationScalePercent;
  int get longWordScalePercent => _longWordScalePercent;
  int get complexWordScalePercent => _complexWordScalePercent;
  bool get autoHideControls => _autoHideControls;
  String get pastedText => _pastedText;
  String get orpColor => _orpColor;

  PacingConfig get pacingConfig => PacingConfig(
    longWordDelayMs: _longWordDelayMs,
    complexWordDelayMs: _complexWordDelayMs,
    punctuationDelayMs: _pauseAtPunctuation ? _punctuationDelayMs : 0,
    longWordScalePercent: _longWordScalePercent,
    complexWordScalePercent: _complexWordScalePercent,
    punctuationScalePercent:
        _pauseAtPunctuation ? _punctuationScalePercent : 0,
  );

  Future<void> _loadPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    _themeMode = ThemeModeOption.values[(_prefs?.getInt('rsvp_themeMode') ??
        ThemeModeOption.dark.index)];
    _fontPairId = _prefs?.getString('rsvp_fontPairId') ?? 'Geometric';
    _wpm = _prefs?.getInt('rsvp_wpm') ?? 350;
    _fontSize = _prefs?.getDouble('rsvp_fontSize') ?? 36.0;
    _orpPercent = _prefs?.getDouble('rsvp_orpPercent') ?? 0.33;
    _showGuideLine = _prefs?.getBool('rsvp_showGuideLine') ?? true;
    _contextWordsMode = ContextWordsMode.values[(_prefs?.getInt(
            'rsvp_contextWordsMode') ??
        ContextWordsMode.hidden.index)];
    _pauseAtPunctuation = _prefs?.getBool('rsvp_pauseAtPunctuation') ?? true;
    _pauseAtSentenceEnd = _prefs?.getBool('rsvp_pauseAtSentenceEnd') ?? true;
    _punctuationDelayMs = _prefs?.getInt('rsvp_punctuationDelayMs') ?? 200;
    _longWordDelayMs = _prefs?.getInt('rsvp_longWordDelayMs') ?? 200;
    _complexWordDelayMs = _prefs?.getInt('rsvp_complexWordDelayMs') ?? 200;
    _punctuationScalePercent =
        _prefs?.getInt('rsvp_punctuationScalePercent') ?? 100;
    _longWordScalePercent = _prefs?.getInt('rsvp_longWordScalePercent') ?? 100;
    _complexWordScalePercent =
        _prefs?.getInt('rsvp_complexWordScalePercent') ?? 100;
    _autoHideControls = _prefs?.getBool('rsvp_autoHideControls') ?? true;
    _pastedText = _prefs?.getString('rsvp_pastedText') ?? _pastedText;
    _orpColor = _prefs?.getString('rsvp_orpColor') ?? 'red';
    notifyListeners();
  }

  // Setters with persistence
  void setThemeMode(ThemeModeOption val) {
    _themeMode = val;
    _prefs?.setInt('rsvp_themeMode', val.index);
    notifyListeners();
  }

  void setFontPairId(String val) {
    _fontPairId = val;
    _prefs?.setString('rsvp_fontPairId', val);
    notifyListeners();
  }

  void setWpm(int val) {
    _wpm = val.clamp(10, 1000);
    _prefs?.setInt('rsvp_wpm', _wpm);
    notifyListeners();
  }

  void setFontSize(double val) {
    _fontSize = val.clamp(18.0, 72.0);
    _prefs?.setDouble('rsvp_fontSize', _fontSize);
    notifyListeners();
  }

  void setOrpPercent(double val) {
    _orpPercent = val.clamp(0.0, 0.50);
    _prefs?.setDouble('rsvp_orpPercent', _orpPercent);
    notifyListeners();
  }

  void setShowGuideLine(bool val) {
    _showGuideLine = val;
    _prefs?.setBool('rsvp_showGuideLine', val);
    notifyListeners();
  }

  void setContextWordsMode(ContextWordsMode val) {
    _contextWordsMode = val;
    _prefs?.setInt('rsvp_contextWordsMode', val.index);
    notifyListeners();
  }

  void setPauseAtPunctuation(bool val) {
    _pauseAtPunctuation = val;
    _prefs?.setBool('rsvp_pauseAtPunctuation', val);
    notifyListeners();
  }

  void setPauseAtSentenceEnd(bool val) {
    _pauseAtSentenceEnd = val;
    _prefs?.setBool('rsvp_pauseAtSentenceEnd', val);
    notifyListeners();
  }

  void setPunctuationDelayMs(int val) {
    _punctuationDelayMs = val.clamp(0, 600);
    _prefs?.setInt('rsvp_punctuationDelayMs', _punctuationDelayMs);
    notifyListeners();
  }

  void setLongWordDelayMs(int val) {
    _longWordDelayMs = val.clamp(0, 600);
    _prefs?.setInt('rsvp_longWordDelayMs', _longWordDelayMs);
    notifyListeners();
  }

  void setComplexWordDelayMs(int val) {
    _complexWordDelayMs = val.clamp(0, 600);
    _prefs?.setInt('rsvp_complexWordDelayMs', _complexWordDelayMs);
    notifyListeners();
  }

  void setPunctuationScalePercent(int val) {
    _punctuationScalePercent = val.clamp(25, 200);
    _prefs?.setInt('rsvp_punctuationScalePercent', _punctuationScalePercent);
    notifyListeners();
  }

  void setLongWordScalePercent(int val) {
    _longWordScalePercent = val.clamp(25, 200);
    _prefs?.setInt('rsvp_longWordScalePercent', _longWordScalePercent);
    notifyListeners();
  }

  void setComplexWordScalePercent(int val) {
    _complexWordScalePercent = val.clamp(25, 200);
    _prefs?.setInt('rsvp_complexWordScalePercent', _complexWordScalePercent);
    notifyListeners();
  }

  void setAutoHideControls(bool val) {
    _autoHideControls = val;
    _prefs?.setBool('rsvp_autoHideControls', val);
    notifyListeners();
  }

  void setPastedText(String val) {
    _pastedText = val;
    _prefs?.setString('rsvp_pastedText', val);
    notifyListeners();
  }

  void setOrpColor(String val) {
    _orpColor = val;
    _prefs?.setString('rsvp_orpColor', val);
    notifyListeners();
  }

  void resetToDefaults() {
    _themeMode = ThemeModeOption.dark;
    _fontPairId = 'Geometric';
    _wpm = 350;
    _fontSize = 36.0;
    _orpPercent = 0.33;
    _showGuideLine = true;
    _contextWordsMode = ContextWordsMode.hidden;
    _pauseAtPunctuation = true;
    _pauseAtSentenceEnd = true;
    _punctuationDelayMs = 200;
    _longWordDelayMs = 200;
    _complexWordDelayMs = 200;
    _punctuationScalePercent = 100;
    _longWordScalePercent = 100;
    _complexWordScalePercent = 100;
    _autoHideControls = true;
    _orpColor = 'red';

    _prefs?.setInt('rsvp_themeMode', _themeMode.index);
    _prefs?.setString('rsvp_fontPairId', _fontPairId);
    _prefs?.setInt('rsvp_wpm', _wpm);
    _prefs?.setDouble('rsvp_fontSize', _fontSize);
    _prefs?.setDouble('rsvp_orpPercent', _orpPercent);
    _prefs?.setBool('rsvp_showGuideLine', _showGuideLine);
    _prefs?.setInt('rsvp_contextWordsMode', _contextWordsMode.index);
    _prefs?.setBool('rsvp_pauseAtPunctuation', _pauseAtPunctuation);
    _prefs?.setBool('rsvp_pauseAtSentenceEnd', _pauseAtSentenceEnd);
    _prefs?.setInt('rsvp_punctuationDelayMs', _punctuationDelayMs);
    _prefs?.setInt('rsvp_longWordDelayMs', _longWordDelayMs);
    _prefs?.setInt('rsvp_complexWordDelayMs', _complexWordDelayMs);
    _prefs?.setInt('rsvp_punctuationScalePercent', _punctuationScalePercent);
    _prefs?.setInt('rsvp_longWordScalePercent', _longWordScalePercent);
    _prefs?.setInt('rsvp_complexWordScalePercent', _complexWordScalePercent);
    _prefs?.setBool('rsvp_autoHideControls', _autoHideControls);
    _prefs?.setString('rsvp_orpColor', _orpColor);

    notifyListeners();
  }
}
