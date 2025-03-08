import 'package:flutter/material.dart';

class MiningCanvas extends CustomPainter {
  final int drillX;
  final int drillY;
  final List<Offset> meteors; // List of meteor positions

  const MiningCanvas(this.drillX, this.drillY, this.meteors);

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()..color = Colors.blue;
    canvas.drawLine(Offset(0, 19), Offset(size.width, 19), paint); // Surface
    paint.color = Colors.grey;
    for (int z = 20; z < 80; z++) {
      canvas.drawLine(Offset(0, z.toDouble()), Offset(size.width, z.toDouble()), paint);
    }
    paint.color = Colors.red;
    canvas.drawRect(Rect.fromLTWH(drillX.toDouble(), drillY.toDouble(), 5, 5), paint); // Drill

    // Draw meteors
    paint.color = Colors.orange;
    for (var meteor in meteors) {
      canvas.drawCircle(meteor, 3, paint); // Small orange circles for meteors
    }
  }

  @override
  bool shouldRepaint(covariant MiningCanvas oldDelegate) {
    return drillX != oldDelegate.drillX ||
        drillY != oldDelegate.drillY ||
        meteors != oldDelegate.meteors;
  }
}