import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// A faint Star of Bethlehem, painted behind the prayer.
class StarWatermark extends CustomPainter {
  StarWatermark(this.color);

  final Color color;

  // ray lengths clockwise from the top; the long one points down
  static const _rays = [0.6, 0.28, 0.6, 0.28, 1.15, 0.28, 0.6, 0.28];
  static const _inner = 0.07;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.shortestSide / 2;
    final center = Offset(size.width / 2, size.height / 2 - 0.2 * unit);
    final path = Path();
    for (var k = 0; k < _rays.length; k++) {
      final angle = -math.pi / 2 + k * math.pi / 4;
      final tip = center + Offset.fromDirection(angle, _rays[k] * unit);
      final notch =
          center + Offset.fromDirection(angle + math.pi / 8, _inner * unit);
      k == 0 ? path.moveTo(tip.dx, tip.dy) : path.lineTo(tip.dx, tip.dy);
      path.lineTo(notch.dx, notch.dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.05));
  }

  @override
  bool shouldRepaint(StarWatermark oldDelegate) => oldDelegate.color != color;
}
