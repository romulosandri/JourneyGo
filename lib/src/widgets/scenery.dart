import 'package:flutter/material.dart';

import '../models/planning.dart';
import '../theme/journey_theme.dart';
import 'chrome.dart';

class Scenery extends StatelessWidget {
  const Scenery({super.key, required this.vibe, this.height = 168});

  final Vibe vibe;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _SceneryPainter(vibe)),
    );
  }
}

class _SceneryPainter extends CustomPainter {
  _SceneryPainter(this.vibe);

  final Vibe vibe;

  @override
  void paint(Canvas canvas, Size size) {
    final sky = Paint()..color = vibeWash(vibe);
    canvas.drawRect(Offset.zero & size, sky);
    final accent = vibeInk(vibe);
    final sun = Paint()..color = accent.withValues(alpha: 0.85);
    switch (vibe) {
      case Vibe.beach:
        canvas.drawCircle(
          Offset(size.width * 0.78, size.height * 0.32),
          28,
          sun,
        );
        final sea = Paint()..color = JourneyColors.sea.withValues(alpha: 0.35);
        final dune = Path()
          ..moveTo(0, size.height * 0.62)
          ..quadraticBezierTo(
            size.width * 0.5,
            size.height * 0.42,
            size.width,
            size.height * 0.66,
          )
          ..lineTo(size.width, size.height)
          ..lineTo(0, size.height)
          ..close();
        canvas.drawPath(dune, sea);
        final sand = Paint()..color = const Color(0xFFF0D7B4);
        final shore = Path()
          ..moveTo(0, size.height * 0.78)
          ..quadraticBezierTo(
            size.width * 0.4,
            size.height * 0.7,
            size.width,
            size.height * 0.8,
          )
          ..lineTo(size.width, size.height)
          ..lineTo(0, size.height)
          ..close();
        canvas.drawPath(shore, sand);
      case Vibe.city:
        canvas.drawCircle(Offset(size.width * 0.18, 36), 16, sun);
        final building = Paint()
          ..color = JourneyColors.night.withValues(alpha: 0.85);
        final windows = Paint()..color = const Color(0xFFF3E2B3);
        final blocks = [0.08, 0.28, 0.46, 0.66, 0.82];
        final heights = [0.42, 0.62, 0.5, 0.7, 0.46];
        for (var index = 0; index < blocks.length; index += 1) {
          final rect = Rect.fromLTWH(
            size.width * blocks[index],
            size.height * (1 - heights[index]),
            size.width * 0.14,
            size.height * heights[index],
          );
          canvas.drawRect(rect, building);
          for (var row = 0; row < 3; row += 1) {
            canvas.drawRect(
              Rect.fromLTWH(rect.left + 8, rect.top + 12 + row * 16, 8, 6),
              windows,
            );
          }
        }
      case Vibe.nature:
        canvas.drawCircle(
          Offset(size.width * 0.72, size.height * 0.28),
          22,
          sun,
        );
        final far = Paint()..color = JourneyColors.moss.withValues(alpha: 0.35);
        final near = Paint()..color = JourneyColors.moss.withValues(alpha: 0.8);
        final farHill = Path()
          ..moveTo(0, size.height * 0.7)
          ..quadraticBezierTo(
            size.width * 0.35,
            size.height * 0.28,
            size.width * 0.7,
            size.height * 0.62,
          )
          ..lineTo(size.width, size.height * 0.5)
          ..lineTo(size.width, size.height)
          ..lineTo(0, size.height)
          ..close();
        canvas.drawPath(farHill, far);
        final nearHill = Path()
          ..moveTo(0, size.height * 0.82)
          ..quadraticBezierTo(
            size.width * 0.55,
            size.height * 0.48,
            size.width,
            size.height * 0.78,
          )
          ..lineTo(size.width, size.height)
          ..lineTo(0, size.height)
          ..close();
        canvas.drawPath(nearHill, near);
      case Vibe.surprise:
        canvas.drawCircle(
          Offset(size.width * 0.5, size.height * 0.42),
          26,
          sun,
        );
        final chip = Paint()..color = JourneyColors.gold.withValues(alpha: 0.8);
        const spots = [
          Offset(40, 30),
          Offset(90, 70),
          Offset(280, 40),
          Offset(240, 90),
          Offset(160, 36),
        ];
        for (final spot in spots) {
          canvas.drawCircle(
            Offset(spot.dx.clamp(0, size.width), spot.dy),
            5,
            chip,
          );
        }
    }
  }

  @override
  bool shouldRepaint(_SceneryPainter oldDelegate) => oldDelegate.vibe != vibe;
}
