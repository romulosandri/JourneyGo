import 'package:flutter/material.dart';

import '../format.dart';
import '../models/journey.dart';
import '../theme/journey_theme.dart';

class PhaseChip extends StatelessWidget {
  const PhaseChip({super.key, required this.phase, required this.accent});

  final JourneyPhase phase;
  final JourneyAccent accent;

  @override
  Widget build(BuildContext context) {
    final color = accent.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        phaseLabel(phase),
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(color: color, letterSpacing: 0.2),
      ),
    );
  }
}
