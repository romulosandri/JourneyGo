import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../format.dart';
import '../logic/planning_rules.dart';
import '../models/planning.dart';
import '../routes.dart';
import '../state/planning_scope.dart';
import '../theme/journey_theme.dart';
import '../widgets/chrome.dart';
import '../widgets/scenery.dart';

class HubScreen extends StatelessWidget {
  const HubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = PlanningScope.of(context);
    final trip = controller.trip;
    if (trip == null) {
      return const NeedTrip();
    }
    final text = Theme.of(context).textTheme;
    final place =
        rankDestinations(trip).leader?.title ?? trip.places.first.name;
    final open =
        [
          for (final kind in DecisionKind.values)
            if (decisionActive(trip, kind)) kind,
        ]..sort((a, b) {
          final aRank =
              phaseOf(trip, a, controller.now) == DecisionPhase.closing ? 0 : 1;
          final bRank =
              phaseOf(trip, b, controller.now) == DecisionPhase.closing ? 0 : 1;
          return aRank.compareTo(bRank);
        });
    final confirmed = isConfirmed(trip);
    final committing = commitOpen(trip) && !confirmed;
    return ProductScaffold(
      showBack: false,
      body: ListView(
        key: const Key('hub-screen'),
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const OpenedMarker(),
          Stack(
            children: [
              Scenery(vibe: trip.vibe, height: 196),
              Positioned(
                left: 20,
                right: 20,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(trip.name, style: text.headlineMedium),
                    const SizedBox(height: 6),
                    _Chip('$place · ${compactRange(trip.start, trip.end)}'),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AvatarStack(
                  members: trip.members,
                  onAdd: trip.viewerIsOrganiser
                      ? () => Navigator.of(context).pushNamed(AppRoutes.invite)
                      : null,
                ),
                if (trip.optOutReasons.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    trip.optOutReasons.length == 1
                        ? '1 can\'t make it'
                        : '${trip.optOutReasons.length} can\'t make it',
                    style: text.bodyMedium,
                  ),
                ],
                if (trip.pendingSync) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Saved on this phone',
                    style: text.bodySmall?.copyWith(color: JourneyColors.ink),
                  ),
                ],
                const SizedBox(height: 16),
                const ProgressMeter(),
                const SizedBox(height: 16),
                for (final kind in open)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _DecisionCard(kind: kind),
                  ),
                if (committing) const _CommitBanner(),
                if (confirmed) const _TicketBanner(),
                if (!committing && !confirmed && open.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 8),
                    child: Text(
                      basicsLocked(trip)
                          ? 'Commit opens when activities and the stay lock.'
                          : 'Activities and stay open when the basics lock.',
                      style: text.bodyMedium,
                    ),
                  ),
                if (trip.viewerIsOrganiser && open.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextButton(
                        key: const Key('nudge'),
                        onPressed: controller.nudge,
                        child: const Text('Nudge the stragglers'),
                      ),
                      Text(
                        'JourneyGo sends a friendly reminder. It won\'t come from you.',
                        style: text.bodySmall,
                      ),
                    ],
                  ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: controller.statusUpdate()),
                    );
                    controller.note(
                      'Update copied. Drop it in the group chat.',
                    );
                  },
                  child: const Text('Share an update to the group chat'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: JourneyColors.card.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(label, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}

class _DecisionCard extends StatelessWidget {
  const _DecisionCard({required this.kind});

  final DecisionKind kind;

  @override
  Widget build(BuildContext context) {
    final controller = PlanningScope.of(context);
    final trip = controller.trip!;
    final phase = phaseOf(trip, kind, controller.now);
    final done = viewerFinished(trip, kind);
    final closing = phase == DecisionPhase.closing;
    return Material(
      color: JourneyColors.card,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        key: Key('decision-${kind.name}'),
        borderRadius: BorderRadius.circular(20),
        onTap: () => _open(context, kind, trip),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: closing ? JourneyColors.amber : JourneyColors.line,
              width: closing ? 1.6 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      decisionTitle(kind),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(leadingLabel(trip, kind)),
                    const SizedBox(height: 4),
                    Text(
                      defaultLine(trip, kind),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      done ? 'You: done ✓' : 'Your turn: 10 sec',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(waitingLabel(waitingCount(trip, kind))),
                  ],
                ),
              ),
              CountdownRing(
                deadline: deadlineFor(trip, kind),
                now: controller.now,
                windowHours: trip.windowHours,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _open(BuildContext context, DecisionKind kind, TripSession trip) {
    if (trip.locked.contains(kind) || trip.objections.containsKey(kind)) {
      Navigator.of(context).pushNamed(AppRoutes.results, arguments: kind);
      return;
    }
    switch (kind) {
      case DecisionKind.destination:
        Navigator.of(context)
            .pushNamed(AppRoutes.swipe, arguments: SwipeMode.destination);
      case DecisionKind.dates:
        Navigator.of(context).pushNamed(AppRoutes.dates);
      case DecisionKind.budget:
        Navigator.of(context).pushNamed(AppRoutes.budget);
      case DecisionKind.activities:
        Navigator.of(context)
            .pushNamed(AppRoutes.swipe, arguments: SwipeMode.activities);
      case DecisionKind.stay:
        Navigator.of(context).pushNamed(AppRoutes.stay);
    }
  }
}

class _CommitBanner extends StatelessWidget {
  const _CommitBanner();

  @override
  Widget build(BuildContext context) {
    final trip = PlanningScope.of(context).trip!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PaperCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Everything\'s decided. Are you in?',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text('About \$${sharedEstimate(trip)} each'),
            const SizedBox(height: 12),
            PrimaryButton(
              label: 'Review and commit',
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRoutes.commit),
            ),
          ],
        ),
      ),
    );
  }
}

class _TicketBanner extends StatelessWidget {
  const _TicketBanner();

  @override
  Widget build(BuildContext context) {
    final trip = PlanningScope.of(context).trip!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PaperCard(
        color: JourneyColors.ink,
        child: InkWell(
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.ticket),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${trip.name} is ON',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(color: JourneyColors.onAccent),
              ),
              const SizedBox(height: 4),
              Text(
                '${trip.committed.length} in so far',
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: JourneyColors.dune),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
