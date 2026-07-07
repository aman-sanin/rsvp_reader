import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:verse/providers/settings_store.dart';

class SettingsPanel extends StatefulWidget {
  final Function(String path)? onPastedTextChanged;

  const SettingsPanel({Key? key, this.onPastedTextChanged})
      : super(key: key);

  @override
  State<SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends State<SettingsPanel> {
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    final settings = Provider.of<SettingsStore>(context, listen: false);
    _textController = TextEditingController(text: settings.pastedText);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _updatePastedTextFile(SettingsStore settings, String val) async {
    settings.setPastedText(val);

    // Get correct writable directory
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

    final lines = val.split('\n');
    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) {
        buffer.writeln('@para');
      } else {
        buffer.writeln(trimmedLine);
      }
    }

    await file.writeAsString(buffer.toString());

    if (widget.onPastedTextChanged != null) {
      widget.onPastedTextChanged!(rsvpPath);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsStore>(context);
    final theme = Theme.of(context);
    final labelStyle = getGoogleFontStyle(
      settings.fontPair.uiFontFamily,
      textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
    );
    final sectionTitleStyle = getGoogleFontStyle(
      settings.fontPair.uiFontFamily,
      textStyle: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 14,
        color: theme.colorScheme.primary,
        letterSpacing: 1.1,
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          // Drag Handle
          Positioned(
            top: 10,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'READER SETTINGS',
                        style: sectionTitleStyle.copyWith(fontSize: 15),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // --- SPEED (WPM) ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('SPEED', style: labelStyle),
                      Text(
                        '${settings.wpm} WPM',
                        style: labelStyle.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: settings.wpm.toDouble(),
                    min: 100,
                    max: 1000,
                    divisions: 36,
                    onChanged: (val) => settings.setWpm(val.toInt()),
                  ),
                  const SizedBox(height: 12),

                  // --- FONT SIZE ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('FONT SIZE', style: labelStyle),
                      Text(
                        '${settings.fontSize.round()} px',
                        style: labelStyle.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: settings.fontSize,
                    min: 18,
                    max: 72,
                    divisions: 54,
                    onChanged: (val) => settings.setFontSize(val),
                  ),
                  const SizedBox(height: 12),

                  // --- ORP POSITION ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('ORP POSITION', style: labelStyle),
                      Text(
                        '${(settings.orpPercent * 100).round()}%',
                        style: labelStyle.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: settings.orpPercent,
                    min: 0.0,
                    max: 0.50,
                    divisions: 50,
                    onChanged: (val) => settings.setOrpPercent(val),
                  ),
                  const Divider(height: 32),

                  // --- APPEARANCE ---
                  Text('APPEARANCE', style: sectionTitleStyle),
                  const SizedBox(height: 16),

                  // Theme Select
                  Text('Theme', style: labelStyle),
                  const SizedBox(height: 8),
                  Row(
                    children: ThemeModeOption.values.map((opt) {
                      final isSelected = settings.themeMode == opt;
                      final String name = opt.name[0].toUpperCase() + opt.name.substring(1);
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

                  // Font Pair Select
                  Text('Font Pair', style: labelStyle),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: fontPairs.map((pair) {
                      final isSelected = settings.fontPairId == pair.id;
                      return ChoiceChip(
                        label: Text(pair.label),
                        selected: isSelected,
                        onSelected: (_) => settings.setFontPairId(pair.id),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),

                  // Font Preview Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withOpacity(
                          0.3,
                        ),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'The quick brown fox jumps over the lazy dog',
                        style: getGoogleFontStyle(
                          settings.fontPair.readingFontFamily,
                          textStyle: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ORP Color Select
                  Text('ORP Color', style: labelStyle),
                  const SizedBox(height: 8),
                  Row(
                    children: ['red', 'green', 'amber', 'blue'].map((colorName) {
                      final isSelected = settings.orpColor == colorName;
                      final Color chipColor;
                      switch (colorName) {
                        case 'green':
                          chipColor = Colors.greenAccent;
                          break;
                        case 'amber':
                          chipColor = Colors.amberAccent;
                          break;
                        case 'blue':
                          chipColor = Colors.blueAccent;
                          break;
                        case 'red':
                        default:
                          chipColor = Colors.redAccent;
                          break;
                      }

                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          avatar: CircleAvatar(
                            backgroundColor: chipColor,
                            radius: 6,
                          ),
                          label: Text(
                            colorName[0].toUpperCase() + colorName.substring(1),
                          ),
                          selected: isSelected,
                          onSelected: (_) => settings.setOrpColor(colorName),
                        ),
                      );
                    }).toList(),
                  ),
                  const Divider(height: 32),

                  // --- READING AIDS ---
                  Text('READING AIDS', style: sectionTitleStyle),
                  const SizedBox(height: 12),

                  SwitchListTile(
                    title: Text('Show guide line', style: labelStyle),
                    value: settings.showGuideLine,
                    onChanged: (val) => settings.setShowGuideLine(val),
                    contentPadding: EdgeInsets.zero,
                  ),

                  Text('Context words', style: labelStyle),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<ContextWordsMode>(
                    value: settings.contextWordsMode,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerLow,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: ContextWordsMode.hidden,
                        child: Text('Hidden'),
                      ),
                      DropdownMenuItem(
                        value: ContextWordsMode.greyed,
                        child: Text('Greyed out'),
                      ),
                      DropdownMenuItem(
                        value: ContextWordsMode.greyedLine,
                        child: Text('Greyed + line extension'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        settings.setContextWordsMode(val);
                      }
                    },
                  ),
                  const Divider(height: 32),

                  // --- BEHAVIOR & PACING ---
                  Text('BEHAVIOR & PACING', style: sectionTitleStyle),
                  const SizedBox(height: 12),

                  SwitchListTile(
                    title: Text('Pause at punctuation', style: labelStyle),
                    value: settings.pauseAtPunctuation,
                    onChanged: (val) => settings.setPauseAtPunctuation(val),
                    contentPadding: EdgeInsets.zero,
                  ),

                  if (settings.pauseAtPunctuation) ...[
                    Text(
                      'Punctuation Delay: ${settings.punctuationDelayMs} ms',
                      style: labelStyle,
                    ),
                    Slider(
                      value: settings.punctuationDelayMs.toDouble(),
                      min: 0,
                      max: 600,
                      divisions: 12,
                      onChanged: (val) =>
                          settings.setPunctuationDelayMs(val.toInt()),
                    ),
                    Text(
                      'Punctuation Scale: ${settings.punctuationScalePercent}%',
                      style: labelStyle,
                    ),
                    Slider(
                      value: settings.punctuationScalePercent.toDouble(),
                      min: 25,
                      max: 200,
                      divisions: 7,
                      onChanged: (val) =>
                          settings.setPunctuationScalePercent(val.toInt()),
                    ),
                  ],

                  SwitchListTile(
                    title: Text('Pause at sentence end', style: labelStyle),
                    value: settings.pauseAtSentenceEnd,
                    onChanged: (val) => settings.setPauseAtSentenceEnd(val),
                    contentPadding: EdgeInsets.zero,
                  ),

                  // Advanced Pacing Delays
                  const SizedBox(height: 8),
                  Text('Advanced word pacing weight:', style: labelStyle),
                  const SizedBox(height: 8),

                  Text(
                    'Long word scale: ${settings.longWordScalePercent}%',
                    style: labelStyle.copyWith(fontSize: 12, color: Colors.grey),
                  ),
                  Slider(
                    value: settings.longWordScalePercent.toDouble(),
                    min: 25,
                    max: 200,
                    divisions: 7,
                    onChanged: (val) =>
                        settings.setLongWordScalePercent(val.toInt()),
                  ),

                  Text(
                    'Complex word scale: ${settings.complexWordScalePercent}%',
                    style: labelStyle.copyWith(fontSize: 12, color: Colors.grey),
                  ),
                  Slider(
                    value: settings.complexWordScalePercent.toDouble(),
                    min: 25,
                    max: 200,
                    divisions: 7,
                    onChanged: (val) =>
                        settings.setComplexWordScalePercent(val.toInt()),
                  ),

                  SwitchListTile(
                    title: Text('Auto-hide controls', style: labelStyle),
                    value: settings.autoHideControls,
                    onChanged: (val) => settings.setAutoHideControls(val),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const Divider(height: 32),

                  // --- TEXT INPUT ---
                  Text('TEXT INPUT', style: sectionTitleStyle),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _textController,
                    maxLines: 6,
                    minLines: 3,
                    onChanged: (val) => _updatePastedTextFile(settings, val),
                    style: getGoogleFontStyle(
                      settings.fontPair.uiFontFamily,
                      textStyle: const TextStyle(fontSize: 14),
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerLow,
                      hintText: 'Paste or type text here to begin reading...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- RESET TO DEFAULTS ---
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        settings.resetToDefaults();
                        _textController.text = settings.pastedText;
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: theme.colorScheme.outlineVariant),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      icon: const Icon(Icons.restore),
                      label: Text(
                        'Reset to Defaults',
                        style: getGoogleFontStyle(
                          settings.fontPair.uiFontFamily,
                          textStyle: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
