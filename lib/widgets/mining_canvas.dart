import 'package:flutter/material.dart';

class MiningCanvas extends CustomPainter {
  final double drillXNormalized;
  final double drillYNormalized;
  final List<Offset> meteors;
  final double canvasWidth;
  final double canvasHeight;
  final int numRigs;
  final bool isLosingRig;
  final double targetXNormalized;
  final double targetYNormalized;
  final double targetRadiusNormalized;
  final bool showDebugIndicator;

  MiningCanvas(
    this.drillXNormalized,
    this.drillYNormalized,
    this.meteors,
    this.canvasWidth,
    this.canvasHeight,
    this.numRigs,
    this.isLosingRig,
    this.targetXNormalized,
    this.targetYNormalized,
    this.targetRadiusNormalized, {
    this.showDebugIndicator = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw the ground (brown layer from Y=0 to Y=0.2436)
    final groundHeight = 0.2436 * canvasHeight;
    final groundPaint = Paint()..color = Colors.brown;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, canvasWidth, groundHeight),
      groundPaint,
    );

    // Draw the subsurface area (gray, below the ground)
    final subsurfacePaint = Paint()..color = Colors.grey;
    canvas.drawRect(
      Rect.fromLTWH(0, groundHeight, canvasWidth, canvasHeight - groundHeight),
      subsurfacePaint,
    );

    // Draw the remaining drill rigs in the upper left corner
    final rigPaint = Paint()..color = Colors.blue;
    const double rigSize = 10.0;
    const double rigSpacing = 5.0;
    for (int i = 0; i < numRigs; i++) {
      canvas.drawRect(
        Rect.fromLTWH(
          10.0 + i * (rigSize + rigSpacing), // X position (spaced horizontally)
          10.0, // Y position (upper left corner)
          rigSize,
          rigSize,
        ),
        rigPaint,
      );
    }

    // Draw meteors
    final meteorPaint = Paint()..color = Colors.red;
    for (var meteor in meteors) {
      canvas.drawCircle(
        Offset(meteor.dx * canvasWidth, meteor.dy * canvasHeight),
        10,
        meteorPaint,
      );
    }

    // Draw the drill rig
    final drillPaint = Paint()
      ..color = isLosingRig ? Colors.red : Colors.blue;
    final drillSize = 10.0;
    canvas.drawRect(
      Rect.fromLTWH(
        drillXNormalized * canvasWidth - drillSize / 2,
        drillYNormalized * canvasHeight - drillSize / 2,
        drillSize,
        drillSize,
      ),
      drillPaint,
    );

    // Draw the target (debug indicator) if enabled
    if (showDebugIndicator) {
      final targetPaint = Paint()
        ..color = Colors.red.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(
        Offset(targetXNormalized * canvasWidth, targetYNormalized * canvasHeight),
        targetRadiusNormalized * canvasWidth,
        targetPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}