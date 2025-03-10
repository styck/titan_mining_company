import 'package:flutter/material.dart';

class MiningCanvas extends CustomPainter {
  final int drillX;
  final int drillY;
  final List<Offset> meteors;
  final double canvasWidth;
  final double canvasHeight;
  final int drillRigs;
  final bool isLosingRig; // Flag to trigger animation
  static const double animationDuration = 0.3; // Seconds for animation

  const MiningCanvas(
    this.drillX,
    this.drillY,
    this.meteors,
    this.canvasWidth,
    this.canvasHeight,
    this.drillRigs,
    this.isLosingRig,
  );

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()..color = const Color(0xFF000000); // Black background
    canvas.drawRect(Rect.fromLTWH(0, 0, canvasWidth, canvasHeight), paint);

    paint.color = const Color(0xFF00FF00); // Green subsurface
    canvas.drawRect(Rect.fromLTWH(0, 0, canvasWidth, canvasHeight * 0.9), paint);

    paint.color = const Color(0xFF008000); // Dark green surface/status bar
    canvas.drawRect(Rect.fromLTWH(0, canvasHeight * 0.9, canvasWidth, canvasHeight * 0.1), paint);

    // Draw active drill with glow (pink with outer shadow)
    paint.color = const Color(0xFFFF00FF); // Pink
    canvas.drawRect(
      Rect.fromLTWH(
        drillX.toDouble() * (canvasWidth / 150),
        drillY.toDouble() * (canvasHeight / 78),
        5 * (canvasWidth / 150),
        5 * (canvasHeight / 78),
      ),
      paint,
    );
    // Glow effect (simple shadow simulation)
    for (double offset = 1; offset <= 3; offset += 1) {
      paint.color = const Color(0xFFFF00FF).withAlpha((255 * (0.3 / offset)).round()); // Fading pink with alpha
      canvas.drawRect(
        Rect.fromLTWH(
          (drillX.toDouble() - offset) * (canvasWidth / 150),
          (drillY.toDouble() - offset) * (canvasHeight / 78),
          (5 + 2 * offset) * (canvasWidth / 150),
          (5 + 2 * offset) * (canvasHeight / 78),
        ),
        paint,
      );
    }

    // Draw stack of drill rigs with animation for loss
    paint.color = const Color(0xFFFF00FF);
    for (int i = 0; i < drillRigs; i++) {
      double yOffset = 5 + i * 6;
      if (isLosingRig && i == drillRigs - 1) { // Animate the top rig being lost
        yOffset += 10 * (1 - (animationDuration * 1000 / 300)); // Move up and fade
        paint.color = const Color(0xFFFF00FF).withAlpha((255 * (1 - (animationDuration * 1000 / 300))).round());
      }
      canvas.drawRect(
        Rect.fromLTWH(
          5.0 * (canvasWidth / 150), // Ensure double
          yOffset.toDouble() * (canvasHeight / 78), // Ensure double
          5 * (canvasWidth / 150),
          5 * (canvasHeight / 78),
        ),
        paint,
      );
    }

    // Meteors (orange)
    paint.color = const Color(0xFFFFA500);
    for (var meteor in meteors) {
      canvas.drawCircle(
        Offset(meteor.dx * (canvasWidth / 150), meteor.dy * (canvasHeight / 78)),
        3 * (canvasWidth / 150),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant MiningCanvas oldDelegate) {
    return drillX != oldDelegate.drillX ||
        drillY != oldDelegate.drillY ||
        meteors != oldDelegate.meteors ||
        drillRigs != oldDelegate.drillRigs ||
        isLosingRig != oldDelegate.isLosingRig;
  }
}