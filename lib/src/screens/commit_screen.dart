import 'package:flutter/material.dart';

import '../format.dart';
import '../logic/planning_rules.dart';
import '../routes.dart';
import '../state/planning_scope.dart';
import '../widgets/chrome.dart';

class CommitScreen extends StatelessWidget {
  const CommitScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = PlanningScope.of(context);
    final trip = controller.trip;
    final viewer = trip?.viewer;
    if (trip == null || viewer == null) {
      return const NeedTrip();
    }
    if (!commitOpen(trip)) {
      return ProductScaffold(
        title: 'Commit',
        body: const Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Activities and the stay lock before anyone commits. Silence never counts as a yes.',
          ),
        ),
        footer: PrimaryButton(
          label: 'Back to trip',
          onPressed: () => _leave(context),
        ),
      );
    }
    final personal = personalEstimate(trip, viewer.id);
    final shared = sharedEstimate(trip);
    final place =
        rankDestinations(trip).leader?.title ?? trip.places.first.name;
    final stay = chosenStay(trip)?.name ?? 'Stay still open';
    final anchors = anchorActivities(trip);
    final skipped = trip.skippedActivities[viewer.id] ?? const <String>{};
    final confirmed = isConfirmed(trip);
    final already = trip.committed.contains(viewer.id);
    final text = Theme.of(context).textTheme;
    final status = confirmed
        ? '${trip.committed.length} of ${trip.joined.length} in'
        : '${trip.committed.length} of ${trip.joined.length} in · Organiser + 1 needed';
    return ProductScaffold(
      title: 'Commit',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Text(trip.name, style: text.headlineSmall),
          const SizedBox(height: 6),
          Text('$place · ${sentenceRange(trip.start, trip.end)}'),
          Text(stay),
          const SizedBox(height: 16),
          Text('Keep the anchors you want', style: text.titleMedium),
          const SizedBox(height: 4),
          if (anchors.isEmpty)
            const Text(
              'The activity list is tied, so the estimate uses the starter three.',
            )
          else
            for (final activity in anchors)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: !skipped.contains(activity.id),
                title: Text(activity.title),
                subtitle: Text(
                  activity.pricePp == 0 ? 'Free' : money(activity.pricePp),
                ),
                onChanged: (_) => controller.toggleSkip(activity.id),
              ),
          const SizedBox(height: 12),
          Text('Your share', style: text.bodyMedium),
          RollingNumber(value: personal, style: text.displaySmall),
          if (personal != shared)
            Text(
              'The group plan is about ${money(shared)} if everyone keeps the anchors.',
              style: text.bodySmall,
            ),
          const SizedBox(height: 12),
          Text(status, style: text.titleSmall),
          const SizedBox(height: 8),
          Text(
            'This isn\'t a payment. Tapping I\'m in tells the group you\'re coming.',
            style: text.bodyMedium,
          ),
        ],
      ),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PrimaryButton(
            key: const Key('commit-in'),
            label: already ? 'You\'re in' : 'I\'m in, about ${money(personal)}',
            onPressed: already
                ? null
                : () {
                    final fresh = controller.commit();
                    final current = controller.trip;
                    if (current == null || !context.mounted) {
                      return;
                    }
                    final going =
                        isConfirmed(current) &&
                        current.committed.contains(viewer.id);
                    if (fresh || going) {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        AppRoutes.ticket,
                        (route) => false,
                      );
                    }
                  },
          ),
          QuietButton(
            key: const Key('cant-make-it'),
            label: 'Can\'t make it',
            onPressed: () => _decline(context),
          ),
        ],
      ),
    );
  }

  Future<void> _decline(BuildContext context) async {
    final reason = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _ReasonSheet(),
    );
    if (reason == null || !context.mounted) {
      return;
    }
    PlanningScope.read(context).cantMakeIt(reason);
    if (context.mounted) {
      _leave(context);
    }
  }

  void _leave(BuildContext context) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    navigator.pushNamedAndRemoveUntil(AppRoutes.hub, (route) => false);
  }
}

class _ReasonSheet extends StatefulWidget {
  const _ReasonSheet();

  @override
  State<_ReasonSheet> createState() => _ReasonSheetState();
}

class _ReasonSheetState extends State<_ReasonSheet> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + inset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Can\'t make it', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text('This stays off the group thread. A reason is optional.'),
          const SizedBox(height: 12),
          TextField(
            controller: _reason,
            decoration: const InputDecoration(hintText: 'Optional, private'),
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            label: 'Tell the organiser',
            onPressed: () => Navigator.pop(context, _reason.text),
          ),
        ],
      ),
    );
  }
}
