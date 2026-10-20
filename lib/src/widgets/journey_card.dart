import 'package:flutter/material.dart';

import '../format.dart';
import '../models/journey.dart';
import '../theme/journey_theme.dart';
import 'phase_chip.dart';

class JourneyCard extends StatelessWidget {
  const JourneyCard({
    super.key,
    required this.journey,
    required this.today,
    required this.onTap,
  });

  final Journey journey;
  final DateTime today;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = journey.accent.color;
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: JourneyColors.card,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ColoredBox(color: accent, child: const SizedBox(width: 8)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          PhaseChip(
                            phase: journey.phaseOn(today),
                            accent: journey.accent,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              placesLabel(journey),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
                              style: textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        journey.place,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        journey.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        formatRange(journey.start, journey.end),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyMedium,
                      ),
                      if (journey.stops.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _StopRail(journey: journey),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StopRail extends StatelessWidget {
  const _StopRail({required this.journey});

  final Journey journey;

  @override
  Widget build(BuildContext context) {
    const maxDots = 6;
    final shown = journey.stops.length > maxDots
        ? maxDots
        : journey.stops.length;
    final extra = journey.stops.length - shown;
    final accent = journey.accent.color;
    return Row(
      children: [
        for (var i = 0; i < shown; i++) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: 2,
                color: journey.stops[i].done && journey.stops[i - 1].done
                    ? accent
                    : JourneyColors.line,
              ),
            ),
          _RailDot(done: journey.stops[i].done, color: accent),
        ],
        if (extra > 0) ...[
          const SizedBox(width: 8),
          Text('+$extra', style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
    );
  }
}

class _RailDot extends StatelessWidget {
  const _RailDot({required this.done, required this.color});

  final bool done;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? color : Colors.transparent,
        border: Border.all(color: color, width: 2),
      ),
    );
  }
}
