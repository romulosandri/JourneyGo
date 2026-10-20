import 'package:flutter/material.dart';

import '../theme/journey_theme.dart';

class RouteMark extends StatelessWidget {
  const RouteMark({
    super.key,
    this.size = 120,
    this.color = JourneyColors.terracotta,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _RouteMarkPainter(color: color)),
    );
  }
}

class _RouteMarkPainter extends CustomPainter {
  const _RouteMarkPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.045
      ..strokeCap = StrokeCap.round;
    final start = Offset(size.width * 0.22, size.height * 0.74);
    final end = Offset(size.width * 0.78, size.height * 0.28);
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(
        size.width * 0.18,
        size.height * 0.38,
        size.width * 0.48,
        size.height * 0.5,
      )
      ..quadraticBezierTo(
        size.width * 0.78,
        size.height * 0.62,
        end.dx,
        end.dy,
      );
    canvas.drawPath(path, stroke);
    _dot(canvas, start, size.width * 0.055, filled: true);
    _dot(canvas, end, size.width * 0.055, filled: false);
  }

  void _dot(
    Canvas canvas,
    Offset center,
    double radius, {
    required bool filled,
  }) {
    final paint = Paint()
      ..color = color
      ..style = filled ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = radius * 0.45;
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _RouteMarkPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
