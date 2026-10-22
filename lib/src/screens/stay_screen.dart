import 'package:flutter/material.dart';

import '../format.dart';
import '../logic/planning_rules.dart';
import '../models/planning.dart';
import '../state/planning_scope.dart';
import '../theme/journey_theme.dart';
import '../widgets/chrome.dart';

class StayScreen extends StatefulWidget {
  const StayScreen({super.key});

  @override
  State<StayScreen> createState() => _StayScreenState();
}

class _StayScreenState extends State<StayScreen> {
  final PageController _pages = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = PlanningScope.of(context);
    final trip = controller.trip;
    if (trip == null) {
      return const NeedTrip();
    }
    final stays = visibleStays(trip);
    final index = stays.isEmpty || _index < stays.length
        ? _index
        : stays.length - 1;
    final viewer = trip.viewerId;
    final alreadySuggested =
        viewer != null && trip.stayAddedBy.contains(viewer);
    final locked = trip.locked.contains(DecisionKind.stay);
    final votedId = viewer == null ? null : trip.stayVotes[viewer];
    final votedName = _stayName(trip, votedId);
    final votedCount = trip.stayVotes.keys
        .where((id) => trip.joined.any((member) => member.id == id))
        .length;
    final text = Theme.of(context).textTheme;
    return ProductScaffold(
      title: 'Stay',
      body: stays.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const DecisionHeader(kind: DecisionKind.stay),
                  const SizedBox(height: 20),
                  Text(_emptyHeadline(trip), style: text.headlineSmall),
                  const SizedBox(height: 8),
                  Text(_emptyBody(trip)),
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: DecisionHeader(kind: DecisionKind.stay),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Pick a place to stay',
                          style: text.headlineSmall,
                        ),
                      ),
                      if (locked) ...[
                        const SizedBox(width: 8),
                        const LockedStamp(),
                      ],
                    ],
                  ),
                ),
                if (locked)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Text(
                      'Stay locked: ${chosenStay(trip)?.name ?? 'the shortlist'}. Booking happens on the host site.',
                    ),
                  ),
                const SizedBox(height: 12),
                Expanded(
                  child: PageView.builder(
                    controller: _pages,
                    itemCount: stays.length,
                    onPageChanged: (value) => setState(() => _index = value),
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _StayCard(
                          stay: stays[index],
                          isDefault: stays[index].id == _defaultId(stays),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: _Estimate(
                    stay: stays[index],
                    routeNote: _routeNote(trip),
                  ),
                ),
                if (votedName != null || votedCount > 0)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Text(
                      votedName == null
                          ? '$votedCount of ${trip.joined.length} voted'
                          : 'You voted $votedName · $votedCount of ${trip.joined.length} voted',
                      style: text.titleSmall,
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var dot = 0; dot < stays.length; dot += 1)
                      Container(
                        width: 7,
                        height: 7,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: dot == index
                              ? JourneyColors.ink
                              : JourneyColors.line,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (stays.isNotEmpty)
            PrimaryButton(
              key: Key('stay-vote-${stays[index].id}'),
              label: trip.stayVotes[viewer] == stays[index].id
                  ? 'Your pick'
                  : 'Vote for ${stays[index].name}',
              onPressed: locked
                  ? null
                  : () => controller.voteStay(stays[index].id),
            ),
          QuietButton(
            label: alreadySuggested ? 'You\'ve added yours' : 'Suggest a stay',
            onPressed: alreadySuggested ? null : () => _suggest(context),
          ),
        ],
      ),
    );
  }

  String _emptyHeadline(TripSession trip) {
    final band = _revealedBand(trip);
    if (trip.viewerIsOrganiser && band != null) {
      return 'Nothing sleeps ${trip.joined.length} within ${money(band.high)} each.';
    }
    return 'Nothing in the comfortable range yet.';
  }

  String _emptyBody(TripSession trip) {
    final band = _revealedBand(trip);
    if (trip.viewerIsOrganiser && band != null) {
      return '${trip.organiser.name}, try 2 smaller places or a cheaper area.';
    }
    return 'Suggest one the group can actually book. One suggestion each, so the list stays short.';
  }

  BudgetBand? _revealedBand(TripSession trip) {
    final viewer = trip.viewerId;
    if (viewer == null ||
        !trip.budgets.containsKey(viewer) ||
        trip.budgets.length < trip.halfRequired) {
      return null;
    }
    return budgetBand(trip);
  }

  String? _stayName(TripSession trip, String? id) {
    if (id == null) {
      return null;
    }
    for (final stay in trip.stays) {
      if (stay.id == id) {
        return stay.name;
      }
    }
    return null;
  }

  String? _defaultId(List<StayOption> stays) {
    StayOption? best;
    for (final stay in stays) {
      if (best == null || stay.rating > best.rating) {
        best = stay;
      }
    }
    return best?.id;
  }

  String? _routeNote(TripSession trip) {
    final leader = rankDestinations(trip).leaderId;
    for (final place in trip.places) {
      if (place.id == leader) {
        return place.routeNote;
      }
    }
    return trip.places.isEmpty ? null : trip.places.first.routeNote;
  }

  Future<void> _suggest(BuildContext context) async {
    final title = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _SuggestSheet(),
    );
    if (title == null || !context.mounted) {
      return;
    }
    final error = PlanningScope.read(context).addStaySuggestion(title);
    if (error != null && context.mounted) {
      PlanningScope.read(context).note(error);
    }
  }
}

class _StayCard extends StatelessWidget {
  const _StayCard({required this.stay, required this.isDefault});

  final StayOption stay;
  final bool isDefault;

  @override
  Widget build(BuildContext context) {
    final trip = PlanningScope.of(context).trip;
    final text = Theme.of(context).textTheme;
    return PaperCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (isDefault) const _Badge('Default', JourneyColors.sea),
              if (stay.stretch) const _Badge('Stretch', JourneyColors.amber),
            ],
          ),
          const SizedBox(height: 10),
          Text(stay.name, style: text.headlineSmall),
          const SizedBox(height: 4),
          Text('${stay.detail} · ★ ${stay.rating.toStringAsFixed(1)}'),
          const SizedBox(height: 8),
          Text(money(stay.pricePp), style: text.displaySmall),
          Text('per person, before activities', style: text.bodySmall),
          const SizedBox(height: 10),
          Text(stay.blurb, style: text.bodyLarge),
          const SizedBox(height: 8),
          Text(addedByLabel(stay.addedBy, trip), style: text.bodySmall),
          TextButton(
            onPressed: () => _listing(context),
            child: const Text('Open the listing'),
          ),
        ],
      ),
    );
  }

  void _listing(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(stay.name, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(stay.blurb),
            const SizedBox(height: 8),
            const Text(
              'This playground keeps the listing here. A later version can open the real page.',
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.label, this.color);

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color),
      ),
    );
  }
}

class _Estimate extends StatelessWidget {
  const _Estimate({required this.stay, required this.routeNote});

  final StayOption stay;
  final String? routeNote;

  @override
  Widget build(BuildContext context) {
    final trip = PlanningScope.of(context).trip!;
    final total = stayTripTotal(trip, stay);
    final viewer = trip.viewerId;
    final revealed =
        viewer != null &&
        trip.budgets.containsKey(viewer) &&
        trip.budgets.length >= trip.halfRequired;
    final band = revealed ? budgetBand(trip) : null;
    final cap = band?.high ?? trip.draftCost;
    final fraction = cap <= 0 ? 1.0 : (total / cap).clamp(0, 1).toDouble();
    final over = band != null && total > band.high;
    final text = Theme.of(context).textTheme;
    final summary = band == null
        ? 'Trip so far: ${money(total)} each'
        : over
        ? 'Trip so far: ${money(total)} each · above the comfortable range'
        : 'Trip so far: ${money(total)} each · inside your band (${money(band.low)}–${money(band.high)})';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(summary, style: text.titleSmall),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: fraction,
            backgroundColor: JourneyColors.dune,
            color: over ? JourneyColors.amber : JourneyColors.sea,
          ),
        ),
        if (routeNote != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(routeNote!, style: text.bodySmall),
          ),
      ],
    );
  }
}

class _SuggestSheet extends StatefulWidget {
  const _SuggestSheet();

  @override
  State<_SuggestSheet> createState() => _SuggestSheetState();
}

class _SuggestSheetState extends State<_SuggestSheet> {
  final _title = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
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
          Text('Suggest a stay', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text(
            'Paste a name. One each, so the shortlist stays a shortlist.',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _title,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Stay name'),
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            label: 'Add to the shortlist',
            onPressed: () => Navigator.pop(context, _title.text),
          ),
        ],
      ),
    );
  }
}
