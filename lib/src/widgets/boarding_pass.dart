import 'package:flutter/material.dart';

import '../format.dart';
import '../models/planning.dart';
import '../theme/journey_theme.dart';

class BoardingPass extends StatelessWidget {
  const BoardingPass({super.key, required this.trip});

  final TripSession trip;

  @override
  Widget build(BuildContext context) {
    final place = trip.places.isEmpty ? 'Somewhere' : trip.places.first.name;
    final text = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: JourneyColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: JourneyColors.ink, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(trip.name.toUpperCase(), style: text.labelMedium),
            const SizedBox(height: 6),
            Text(
              place.toUpperCase(),
              style: text.headlineSmall?.copyWith(letterSpacing: 0.4),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  compactRange(trip.start, trip.end),
                  style: text.titleMedium,
                ),
                const Spacer(),
                Text('~\$${trip.draftCost} pp', style: text.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            Text('From: ${trip.organiser.name}', style: text.bodyMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _Barcode(seed: trip.code)),
                const SizedBox(width: 12),
                Text(
                  codeLabel(trip.code),
                  style: text.titleMedium?.copyWith(letterSpacing: 1.2),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Barcode extends StatelessWidget {
  const _Barcode({required this.seed});

  final String seed;

  @override
  Widget build(BuildContext context) {
    final widths = [for (final unit in seed.codeUnits) 1 + (unit % 3)];
    return SizedBox(
      height: 36,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final width in widths) ...[
            SizedBox(
              width: width.toDouble(),
              child: const ColoredBox(color: JourneyColors.ink),
            ),
            const SizedBox(width: 2),
          ],
        ],
      ),
    );
  }
}
