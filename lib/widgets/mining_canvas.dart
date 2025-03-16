import 'package:flutter/material.dart';

class MiningCanvas extends CustomPainter {
  final double drillXNormalized;
  final double drillYNormalized;
  final List<Offset> meteors;
  final double canvasWidth;
  final double canvasHeight;
  final int drillRigs;
  final bool isLosingRig;
  final double targetXNormalized; // Add target position
  final double targetYNormalized;
  final double targetRadiusNormalized; // Add target radius
  final bool showDebugIndicator; // Debug flag
  static const double animationDuration = 0.3;

  const MiningCanvas(
    this.drillXNormalized,
    this.drillYNormalized,
    this.meteors,
    this.canvasWidth,
    this.canvasHeight,
    this.drillRigs,
    this.isLosingRig,
    this.targetXNormalized,
    this.targetYNormalized,
    this.targetRadiusNormalized,
    {this.showDebugIndicator = false} // Default to false
  );

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()..color = const Color(0xFF000000); // Black background
    canvas.drawRect(Rect.fromLTWH(0, 0, canvasWidth, canvasHeight), paint);

    paint.color = const Color(0xFF00FF00); // Green subsurface
    canvas.drawRect(Rect.fromLTWH(0, 0, canvasWidth, canvasHeight * 0.9), paint);

    paint.color = const Color(0xFF008000); // Dark green surface/status bar
    canvas.drawRect(Rect.fromLTWH(0, canvasHeight * 0.9, canvasWidth, canvasHeight * 0.1), paint);

    // Debug: Draw Dilithium target area
    if (showDebugIndicator) {
      paint.color = const Color(0xFFFF0000).withAlpha(50); // Semi-transparent red
      canvas.drawCircle(
        Offset(targetXNormalized * canvasWidth, targetYNormalized * canvasHeight),
        targetRadiusNormalized * canvasWidth, // Scale radius to canvas width
        paint,
      );
      // Draw center point for precision
      paint.color = const Color(0xFFFF0000);
      canvas.drawCircle(
        Offset(targetXNormalized * canvasWidth, targetYNormalized * canvasHeight),
        2, // Small dot
        paint,
      );
    }

    // Draw active drill with glow (pink with outer shadow)
    paint.color = const Color(0xFFFF00FF);
    canvas.drawRect(
      Rect.fromLTWH(
        drillXNormalized * canvasWidth,
        drillYNormalized * canvasHeight,
        5 * (canvasWidth / 150),
        5 * (canvasHeight / 78),
      ),
      paint,
    );
    for (double offset = 1; offset <= 3; offset += 1) {
      paint.color = const Color(0xFFFF00FF).withAlpha((255 * (0.3 / offset)).round());
      canvas.drawRect(
        Rect.fromLTWH(
          (drillXNormalized * canvasWidth) - offset,
          (drillYNormalized * canvasHeight) - offset,
          (5 + 2 * offset) * (canvasWidth / 150),
          (5 + 2 * offset) * (canvasHeight / 78),
        ),
        paint,
      );
    }

    // Draw stack of drill rigs with animation for loss
    paint.color = const Color(0xFFFF00FF);
    for (int i = 0; i < drillRigs; i++) {
      double yOffsetNormalized = 0.05 + i * 0.06;
      if (isLosingRig && i == drillRigs - 1) {
        yOffsetNormalized += 0.1 * (1 - (animationDuration * 1000 / 300));
        paint.color = const Color(0xFFFF00FF).withAlpha((255 * (1 - (animationDuration * 1000 / 300))).round());
      }
      canvas.drawRect(
        Rect.fromLTWH(
          0.05 * canvasWidth,
          yOffsetNormalized * canvasHeight,
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
        Offset(meteor.dx * canvasWidth, meteor.dy * canvasHeight),
        3 * (canvasWidth / 150),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant MiningCanvas oldDelegate) {
    return drillXNormalized != oldDelegate.drillXNormalized ||
        drillYNormalized != oldDelegate.drillYNormalized ||
        meteors != oldDelegate.meteors ||
        drillRigs != oldDelegate.drillRigs ||
        isLosingRig != oldDelegate.isLosingRig ||
        showDebugIndicator != oldDelegate.showDebugIndicator;
  }
}