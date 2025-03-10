import 'package:flutter/material.dart';

class MiningCanvas extends CustomPainter {
  final int drillX;
  final int drillY;
  final List<Offset> meteors;
  final double canvasWidth;
  final double canvasHeight;
  final int drillRigs; // Add total drill rigs to display

  const MiningCanvas(
    this.drillX,
    this.drillY,
    this.meteors,
    this.canvasWidth,
    this.canvasHeight,
    this.drillRigs,
  );

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()..color = const Color(0xFF000000); // Black background
    canvas.drawRect(Rect.fromLTWH(0, 0, canvasWidth, canvasHeight), paint);

    paint.color = const Color(0xFF00FF00); // Green subsurface
    canvas.drawRect(Rect.fromLTWH(0, 0, canvasWidth, canvasHeight * 0.9), paint);

    paint.color = const Color(0xFF008000); // Dark green surface/status bar
    canvas.drawRect(Rect.fromLTWH(0, canvasHeight * 0.9, canvasWidth, canvasHeight * 0.1), paint);

    // Draw active drill (pink)
    paint.color = const Color(0xFFFF00FF);
    canvas.drawRect(
      Rect.fromLTWH(
        drillX.toDouble() * (canvasWidth / 150),
        drillY.toDouble() * (canvasHeight / 78),
        5 * (canvasWidth / 150),
        5 * (canvasHeight / 78),
      ),
      paint,
    );

    // Draw stack of drill rigs in top-left corner
    paint.color = const Color(0xFFFF00FF); // Same pink as active drill
    for (int i = 0; i < drillRigs; i++) {
      canvas.drawRect(
        Rect.fromLTWH(
          5 * (canvasWidth / 150), // Small offset from left
          (5 + i * 6) * (canvasHeight / 78), // Stack vertically
          5 * (canvasWidth / 150), // Small size
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
        drillRigs != oldDelegate.drillRigs;
  }
}