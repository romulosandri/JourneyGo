import 'package:flutter/material.dart';

import '../models/planning.dart';
import '../state/planning_scope.dart';
import '../theme/journey_theme.dart';
import 'chrome.dart';

class PlaygroundBar extends StatelessWidget {
  const PlaygroundBar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = PlanningScope.of(context);
    final trip = controller.trip;
    final viewer = trip?.viewer;
    return Material(
      color: const Color(0xFFE7E0D4),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 48,
          child: Row(
            children: [
              const SizedBox(width: 12),
              Text('Playground', style: Theme.of(context).textTheme.titleSmall),
              const Spacer(),
              PopupMenuButton<String>(
                tooltip: 'View as someone else',
                enabled: trip != null && trip.joined.isNotEmpty,
                onSelected: controller.setViewer,
                itemBuilder: (context) => [
                  for (final member in trip?.joined ?? const <Member>[])
                    PopupMenuItem(
                      value: member.id,
                      child: Text(
                        '${member.name} · ${roleLabel(member.role)}',
                        key: Key('viewer-${member.id}'),
                      ),
                    ),
                ],
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    viewer == null ? 'Guest' : viewer.name,
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(color: JourneyColors.ink),
                  ),
                ),
              ),
              PopupMenuButton<PreviewKind>(
                tooltip: 'Preview a screen',
                onSelected: controller.openPreview,
                itemBuilder: (context) => [
                  for (final kind in PreviewKind.values)
                    PopupMenuItem(
                      value: kind,
                      child: Text(
                        _previewLabel(kind),
                        key: Key('preview-${kind.name}'),
                      ),
                    ),
                ],
                icon: const Icon(Icons.layers_outlined),
              ),
              IconButton(
                tooltip: 'Advance the deadline',
                onPressed: trip == null ? null : controller.advanceClock,
                icon: const Icon(Icons.fast_forward),
              ),
              IconButton(
                tooltip: controller.offline ? 'Back online' : 'Go offline',
                onPressed: () => controller.setOffline(!controller.offline),
                icon: Icon(
                  controller.offline
                      ? Icons.cloud_off
                      : Icons.cloud_queue_outlined,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _previewLabel(PreviewKind kind) {
  switch (kind) {
    case PreviewKind.basics:
      return 'Sunny Escape · basics open';
    case PreviewKind.landing:
      return 'Invite link';
    case PreviewKind.expired:
      return 'Expired invite';
    case PreviewKind.tie:
      return 'Tie to break';
    case PreviewKind.belowPlan:
      return 'Budget below the plan';
    case PreviewKind.plans:
      return 'Activities and stay';
    case PreviewKind.commit:
      return 'Ready to commit';
    case PreviewKind.confirmed:
      return 'Confirmed ticket';
    case PreviewKind.objection:
      return 'Objection window';
  }
}
