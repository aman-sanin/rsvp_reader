import 'package:flutter/material.dart';
import 'package:verse/providers/settings_store.dart';

/// A premium RSVP display widget that implements fixed-point ORP alignment,
/// flanking context words, guide lines, and horizontal framing lines.
class RsvpDisplay extends StatelessWidget {
  final String word;
  final String prevWord;
  final String nextWord;
  final double fontSize;
  final double orpPercent;
  final FontPair fontPair;
  final bool showGuideLine;
  final ContextWordsMode contextWordsMode;
  final String orpColor;

  const RsvpDisplay({
    Key? key,
    required this.word,
    this.prevWord = '',
    this.nextWord = '',
    required this.fontSize,
    required this.orpPercent,
    required this.fontPair,
    required this.showGuideLine,
    required this.contextWordsMode,
    required this.orpColor,
  }) : super(key: key);

  /// Computes the ORP index based on model.md Section 8.1
  static int getOrpIndex(String word, double orpPercent) {
    if (word.isEmpty) return 0;
    final cleanWord = word.trim();
    if (cleanWord.length <= 1) return 0;
    if (cleanWord.length <= 3) return 1;
    if (cleanWord.length <= 5) return 2;
    if (cleanWord.length <= 9) return 3;
    if (cleanWord.length <= 13) return 4;
    return (cleanWord.length * orpPercent).floor().clamp(0, cleanWord.length - 1);
  }

  Color _resolveOrpColor() {
    switch (orpColor) {
      case 'green':
        return Colors.greenAccent;
      case 'amber':
        return Colors.amberAccent;
      case 'blue':
        return Colors.blueAccent;
      case 'red':
      default:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final primaryContainer = theme.colorScheme.primaryContainer;
    final resolvedOrpColor = _resolveOrpColor();

    // Set up the typography style
    final baseStyle = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      height: 1.2,
    );

    final currentWordStyle = getGoogleFontStyle(
      fontPair.readingFontFamily,
      textStyle: baseStyle.copyWith(color: onSurface),
    );

    final contextWordStyle = getGoogleFontStyle(
      fontPair.readingFontFamily,
      textStyle: baseStyle.copyWith(color: onSurface.withOpacity(0.2)),
    );

    // Split current word around ORP
    final effectiveOrpIndex = getOrpIndex(word, orpPercent);
    final String preOrp;
    final String orpChar;
    final String postOrp;

    if (word.isNotEmpty && effectiveOrpIndex < word.length) {
      preOrp = word.substring(0, effectiveOrpIndex);
      orpChar = word.substring(effectiveOrpIndex, effectiveOrpIndex + 1);
      postOrp = word.substring(effectiveOrpIndex + 1);
    } else {
      preOrp = '';
      orpChar = word;
      postOrp = '';
    }

    // Measure pre-ORP width
    final preOrpPainter = TextPainter(
      text: TextSpan(text: preOrp, style: currentWordStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    final preOrpWidth = preOrpPainter.width;

    // Measure current word width
    final currentWordPainter = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(text: preOrp, style: currentWordStyle),
          TextSpan(text: orpChar, style: currentWordStyle),
          TextSpan(text: postOrp, style: currentWordStyle),
        ],
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final currentWordWidth = currentWordPainter.width;

    // Measure previous/next words if context mode is enabled
    final showContext = contextWordsMode != ContextWordsMode.hidden;

    return LayoutBuilder(
      builder: (context, constraints) {
        final centerX = constraints.maxWidth / 2;
        final currentWordLeft = centerX - preOrpWidth;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Framing line above the word display
            Container(
              width: 320,
              height: 1.5,
              color: theme.colorScheme.outlineVariant.withOpacity(0.3),
            ),
            const SizedBox(height: 16),

            // Word display area
            SizedBox(
              height: fontSize * 1.5,
              width: constraints.maxWidth,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // 1. Fixation Guide Line (vertical line centered on ORP, never moves)
                  if (showGuideLine)
                    Positioned(
                      left: centerX,
                      top: -40,
                      bottom: -40,
                      child: Container(
                        width: 1.5,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              resolvedOrpColor.withOpacity(0.05),
                              resolvedOrpColor.withOpacity(
                                contextWordsMode == ContextWordsMode.greyedLine ? 0.25 : 0.15,
                              ),
                              resolvedOrpColor.withOpacity(0.05),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // 2. Previous Word (Context)
                  if (showContext && prevWord.isNotEmpty)
                    Positioned(
                      right: constraints.maxWidth - currentWordLeft + 24,
                      top: 0,
                      child: Text(
                        prevWord,
                        style: contextWordStyle,
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                      ),
                    ),

                  // 3. Current Word with ORP Highlight
                  Positioned(
                    left: currentWordLeft,
                    top: 0,
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: preOrp,
                            style: currentWordStyle, // NOT greyed out - matches onSurface color
                          ),
                          TextSpan(
                            text: orpChar,
                            style: currentWordStyle.copyWith(
                              color: resolvedOrpColor,
                              backgroundColor: primaryContainer,
                            ),
                          ),
                          TextSpan(
                            text: postOrp,
                            style: currentWordStyle,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 4. Next Word (Context)
                  if (showContext && nextWord.isNotEmpty)
                    Positioned(
                      left: currentWordLeft + currentWordWidth + 24,
                      top: 0,
                      child: Text(
                        nextWord,
                        style: contextWordStyle,
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Framing line below the word display
            Container(
              width: 320,
              height: 1.5,
              color: theme.colorScheme.outlineVariant.withOpacity(0.3),
            ),
          ],
        );
      },
    );
  }
}
