// lib/widgets/rsvp_display.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rsvp_reader/src/rust/api/processor.dart'; // Ensure import path matches generated code

class RsvpDisplay extends StatelessWidget {
  final RsvpWord word;

  const RsvpDisplay({super.key, required this.word});

  @override
  Widget build(BuildContext context) {
    // Monospace is essential for consistent jitter-free rendering
    final style = GoogleFonts.robotoMono(
      fontSize: 40,
      fontWeight: FontWeight.bold,
      color: Colors.black,
    );
    final pivotStyle = style.copyWith(color: Colors.red);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Top Guideline
        Container(width: 200, height: 2, color: Colors.grey.shade300),
        const SizedBox(height: 15),

        // The Alignment Row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            // Left Side: Pushes text to the RIGHT
            Expanded(
              child: Text(
                word.left,
                textAlign: TextAlign.right,
                style: style,
                softWrap: false,
                overflow: TextOverflow.visible,
              ),
            ),
            // Pivot: The fixed center
            Text(word.center, style: pivotStyle),
            // Right Side: Pushes text to the LEFT
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

        const SizedBox(height: 15),
        // Bottom Guideline with Marker
        Stack(
          alignment: Alignment.center,
          children: [
            Container(width: 200, height: 2, color: Colors.grey.shade300),
            Container(width: 2, height: 10, color: Colors.black54),
          ],
        ),
      ],
    );
  }
}
