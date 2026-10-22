import 'package:flutter/material.dart';

import '../format.dart';
import '../logic/planning_rules.dart';
import '../models/planning.dart';
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
    final stayOption = chosenStay(trip);
    final stay = stayOption?.name ?? 'Stay still open';
    final stayPrice =
        stayOption?.pricePp ??
        (trip.stays.isEmpty ? 0 : trip.stays.first.pricePp);
    final activityCost =
        personal - stayPrice - travelPerPerson - bufferPerPerson;
    final anchors = anchorActivities(trip);
    final skipped = trip.skippedActivities[viewer.id] ?? const <String>{};
    final confirmed = isConfirmed(trip);
    final already = trip.committed.contains(viewer.id);
    final text = Theme.of(context).textTheme;
    final status = confirmed
        ? '${trip.committed.length} of ${trip.joined.length} in'
        : '${trip.committed.length} of ${trip.joined.length} in · Organiser + 1 needed to confirm';
    final stillWaiting = [
      for (final member in trip.joined)
        if (!trip.committed.contains(member.id) &&
            !trip.optOutReasons.containsKey(member.id))
          member,
    ];
    final othersWaiting = stillWaiting
        .where((member) => member.id != viewer.id)
        .length;
    final band = _visibleBand(trip, viewer.id);
    final out = trip.optOutReasons.length;
    return ProductScaffold(
      title: 'Commit',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Text('${trip.name} is ready. Are you in?', style: text.headlineSmall),
          const SizedBox(height: 12),
          PaperCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(place, style: text.titleMedium),
                const SizedBox(height: 4),
                Text(
                  '${weekdayMonthDay(trip.start)} – ${weekdayMonthDay(trip.end)}',
                ),
                const SizedBox(height: 4),
                Text(stay),
                if (anchors.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Anchors: ${anchors.map((item) => item.title).join(' · ')}',
                    style: text.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('About ${money(personal)} each', style: text.bodyMedium),
          RollingNumber(value: personal, style: text.displaySmall),
          if (band != null)
            Text(
              personal <= band.high
                  ? 'Inside your band ✓'
                  : 'Above the comfortable range.',
              style: text.titleSmall,
            ),
          if (personal != shared)
            Text(
              'The group plan is about ${money(shared)} if everyone keeps the anchors.',
              style: text.bodySmall,
            ),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 8),
              title: Text('See the breakdown', style: text.titleSmall),
              children: [
                _MoneyLine(label: 'Stay', amount: stayPrice),
                _MoneyLine(label: 'Activities', amount: activityCost),
                _MoneyLine(label: 'Travel', amount: travelPerPerson),
                _MoneyLine(label: 'Buffer', amount: bufferPerPerson),
              ],
            ),
          ),
          Text('Skipping something? Untick it.', style: text.titleMedium),
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
          Text(status, style: text.titleSmall),
          if (trip.commitDeadline != null) ...[
            const SizedBox(height: 4),
            Text(_commitCloses(trip.commitDeadline!, controller.now)),
          ],
          if (stillWaiting.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(_waiting(stillWaiting.length)),
          ],
          if (trip.viewerIsOrganiser && othersWaiting > 0) ...[
            TextButton(
              key: const Key('commit-nudge'),
              onPressed: controller.nudge,
              child: const Text('Nudge them'),
            ),
            Text(
              'JourneyGo sends a friendly reminder. It won\'t come from you.',
              style: text.bodySmall,
            ),
          ],
          if (out > 0) ...[
            const SizedBox(height: 8),
            Text(out == 1 ? '1 can\'t make it' : '$out can\'t make it'),
          ],
          const SizedBox(height: 8),
          Text(
            'This isn\'t a payment. It\'s a promise to your friends. Booking and paying happen outside JourneyGo.',
            style: text.bodyMedium,
          ),
        ],
      ),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PrimaryButton(
            key: const Key('commit-in'),
            label: already
                ? 'You\'re in ✓'
                : 'I\'m in, about ${money(personal)}',
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
            label: 'I can\'t make it',
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

BudgetBand? _visibleBand(TripSession trip, String viewerId) {
  if (!trip.budgets.containsKey(viewerId) ||
      trip.budgets.length < trip.halfRequired) {
    return null;
  }
  return budgetBand(trip);
}

String _commitCloses(DateTime deadline, DateTime now) {
  final label = closesLabel(deadline, now);
  if (label == 'Closing now') {
    return 'Commit is closing now';
  }
  const prefix = 'Closes ';
  if (label.startsWith(prefix)) {
    return 'Commit closes ${label.substring(prefix.length)}';
  }
  return 'Commit $label';
}

String _waiting(int count) {
  if (count == 1) {
    return 'Waiting on 1 person';
  }
  return 'Waiting on $count people';
}

class _MoneyLine extends StatelessWidget {
  const _MoneyLine({required this.label, required this.amount});

  final String label;
  final int amount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(money(amount < 0 ? 0 : amount)),
        ],
      ),
    );
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
