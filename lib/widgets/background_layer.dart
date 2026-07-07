import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:verse/providers/settings_store.dart';

class BackgroundLayer extends StatefulWidget {
  final ThemeModeOption themeMode;

  const BackgroundLayer({Key? key, required this.themeMode}) : super(key: key);

  @override
  State<BackgroundLayer> createState() => _BackgroundLayerState();
}

class _BackgroundLayerState extends State<BackgroundLayer>
    with SingleTickerProviderStateMixin {
  late AnimationController _orbController;

  @override
  void initState() {
    super.initState();
    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 45),
    )..repeat();
  }

  @override
  void dispose() {
    _orbController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = widget.themeMode != ThemeModeOption.light;
    final primaryColor = theme.colorScheme.primary;

    return Stack(
      children: [
        // Base Color
        Positioned.fill(
          child: Container(
            color: theme.colorScheme.surface,
          ),
        ),

        // Layer 1 - Radial Glow centered slightly above the middle
        Positioned(
          left: -150,
          right: -150,
          top: -200,
          height: 600,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.8,
                  colors: [
                    primaryColor.withOpacity(isDark ? 0.05 : 0.025),
                    primaryColor.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Layer 3 - Floating Orbs (Disabled in light theme)
        if (isDark)
          AnimatedBuilder(
            animation: _orbController,
            builder: (context, child) {
              final val = _orbController.value * 2 * pi;
              // Smooth drifting paths using sin/cos
              final orb1x = sin(val) * 80;
              final orb1y = cos(val) * 50;

              final orb2x = cos(val + pi / 2) * 90;
              final orb2y = sin(val + pi / 2) * 60;

              final orb3x = sin(val + pi) * 60;
              final orb3y = cos(val + pi) * 80;

              return Stack(
                children: [
                  // Orb 1
                  Positioned(
                    left: 40 + orb1x,
                    top: 150 + orb1y,
                    width: 250,
                    height: 250,
                    child: _OrbWidget(
                      color: primaryColor.withOpacity(0.04),
                      blur: 90,
                    ),
                  ),
                  // Orb 2
                  Positioned(
                    right: 20 + orb2x,
                    bottom: 120 + orb2y,
                    width: 300,
                    height: 300,
                    child: _OrbWidget(
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.03),
                      blur: 100,
                    ),
                  ),
                  // Orb 3
                  Positioned(
                    left: 100 + orb3x,
                    bottom: 200 + orb3y,
                    width: 220,
                    height: 220,
                    child: _OrbWidget(
                      color: primaryColor.withOpacity(0.035),
                      blur: 85,
                    ),
                  ),
                ],
              );
            },
          ),

        // Layer 2 - Static procedural paper/grain noise texture
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _NoisePainter(
                opacity: isDark ? 0.025 : 0.04,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _OrbWidget extends StatelessWidget {
  final Color color;
  final double blur;

  const _OrbWidget({required this.color, required this.blur});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: blur,
            spreadRadius: blur / 2,
          ),
        ],
      ),
    );
  }
}

/// Custom painter to draw static seeded background noise grain
class _NoisePainter extends CustomPainter {
  final double opacity;

  _NoisePainter({required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(opacity)
      ..strokeWidth = 1.0;

    // Use a fixed seed Random so the noise is static (paper texture style)
    // rather than shifting on every frame repainting.
    final rand = Random(42);
    final count = (size.width * size.height / 1200).floor().clamp(1000, 15000);

    for (int i = 0; i < count; i++) {
      final x = rand.nextDouble() * size.width;
      final y = rand.nextDouble() * size.height;
      canvas.drawPoints(
        PointMode.points,
        [Offset(x, y)],
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _NoisePainter oldDelegate) =>
      oldDelegate.opacity != opacity;
}
