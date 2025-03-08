import 'package:flutter/material.dart';

class MiningCanvas extends CustomPainter {
  final int drillX;
  final int drillY;
  final List<Offset> meteors;
  final double canvasWidth;
  final double canvasHeight;

  const MiningCanvas(this.drillX, this.drillY, this.meteors, this.canvasWidth, this.canvasHeight);

  @override
  void paint(Canvas canvas, Size size) {
    // Use Atari-like colors
    var paint = Paint()..color = const Color(0xFF000000); // Black background
    canvas.drawRect(Rect.fromLTWH(0, 0, canvasWidth, canvasHeight), paint);

    paint.color = const Color(0xFF00FF00); // Green subsurface
    canvas.drawRect(Rect.fromLTWH(0, 0, canvasWidth, canvasHeight * 0.9), paint); // 90% for subsurface

    paint.color = const Color(0xFF008000); // Dark green surface/status bar
    canvas.drawRect(Rect.fromLTWH(0, canvasHeight * 0.9, canvasWidth, canvasHeight * 0.1), paint);

    // Drill (pink, like Atari screenshot)
    paint.color = const Color(0xFFFF00FF); // Pink
    canvas.drawRect(
      Rect.fromLTWH(
        drillX.toDouble() * (canvasWidth / 150), // Scale x to canvas width
        drillY.toDouble() * (canvasHeight / 78), // Scale y to canvas height
        5 * (canvasWidth / 150), // Scale drill size
        5 * (canvasHeight / 78),
      ),
      paint,
    );

    // Meteors (orange)
    paint.color = const Color(0xFFFFA500); // Orange
    for (var meteor in meteors) {
      canvas.drawCircle(
        Offset(meteor.dx * (canvasWidth / 150), meteor.dy * (canvasHeight / 78)),
        3 * (canvasWidth / 150), // Scale meteor size
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant MiningCanvas oldDelegate) {
    return drillX != oldDelegate.drillX ||
        drillY != oldDelegate.drillY ||
        meteors != oldDelegate.meteors;
  }
}