// lib/widgets/rsvp_display.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rsvp_reader/src/rust/api/processor.dart';

class RsvpDisplay extends StatelessWidget {
  final RsvpWord word;
  final double fontSize;

  const RsvpDisplay({super.key, required this.word, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    // 1. Define styling based on dynamic font size
    final style = GoogleFonts.robotoMono(
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
      // Adaptive color for dark/light mode
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.white
          : Colors.black,
      height: 1.0, // Force standard line height
    );

    final pivotStyle = style.copyWith(color: Colors.red);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // TOP GUIDELINE
        Container(
          width: 200,
          height: 2,
          color: Colors.grey.withValues(alpha: 0.3),
        ),

        // TEXT CONTAINER (Fixed Height to prevent Jitter)
        SizedBox(
          height: fontSize * 1.6, // Reserve space for ascenders/descenders
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment:
                CrossAxisAlignment.center, // Center vertically in the box
            children: [
              // LEFT LANE
              Expanded(
                child: Text(
                  word.left,
                  textAlign: TextAlign.right,
                  style: style,
                  softWrap: false,
                  overflow: TextOverflow.visible,
                ),
              ),
              // PIVOT
              Text(word.center, style: pivotStyle),
              // RIGHT LANE
              Expanded(
                child: Text(
                  word.right,
                  textAlign: TextAlign.left,
                  style: style,
                  softWrap: false,
                  overflow: TextOverflow.visible,
                ),
              ),
            ],
          ),
        ),

        // BOTTOM GUIDELINE
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 200,
              height: 2,
              color: Colors.grey.withValues(alpha: 0.3),
            ),
            Container(width: 2, height: 10, color: Colors.redAccent), // Notch
          ],
        ),
      ],
    );
  }
}
