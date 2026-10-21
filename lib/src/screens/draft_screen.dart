import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../format.dart';
import '../logic/planning_rules.dart';
import '../models/planning.dart';
import '../routes.dart';
import '../state/planning_scope.dart';
import '../theme/journey_theme.dart';
import '../widgets/chrome.dart';

class DraftScreen extends StatefulWidget {
  const DraftScreen({super.key});

  @override
  State<DraftScreen> createState() => _DraftScreenState();
}

class _DraftScreenState extends State<DraftScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeSearch());
  }

  void _maybeSearch() {
    if (!mounted) {
      return;
    }
    final controller = PlanningScope.read(context);
    if (controller.takePlaceSearch()) {
      _openSearch(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = PlanningScope.of(context);
    final trip = controller.trip;
    if (controller.generating || trip == null) {
      return const _Generating();
    }
    final text = Theme.of(context).textTheme;
    return ProductScaffold(
      title: 'Your draft',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          const SetupStepper(index: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(child: Eyebrow(text: 'Your draft')),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: JourneyColors.dune,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  trip.edited ? 'Edited' : 'Suggestion: edit anything',
                  style: text.bodySmall?.copyWith(color: JourneyColors.ink),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          PaperCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () => _rename(context, trip.name),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(trip.name, style: text.headlineSmall),
                      ),
                      const Icon(Icons.edit_outlined, size: 18),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final place in trip.places)
                      InputChip(
                        label: Text('${place.name} · ${place.travel}'),
                        onDeleted: () => controller.removePlace(place.id),
                        onPressed: () {},
                      ),
                    if (trip.places.length < 3)
                      ActionChip(
                        label: const Text('+ Add'),
                        onPressed: () => _openSearch(context),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        rangeLabel(trip.start, trip.end),
                        style: text.titleMedium,
                      ),
                    ),
                    TextButton(
                      onPressed: () => _editWeekend(context, trip),
                      child: const Text('Edit'),
                    ),
                  ],
                ),
                Text(
                  'About \$${trip.draftCost} each, rough, incl. travel',
                  style: text.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text('How we\'ll decide', style: text.titleMedium),
          const SizedBox(height: 8),
          for (final kind in [
            DecisionKind.destination,
            DecisionKind.dates,
            DecisionKind.budget,
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: PaperCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(decisionTitle(kind), style: text.titleSmall),
                    const SizedBox(height: 2),
                    Text(defaultLine(trip, kind), style: text.bodyMedium),
                    Text(
                      closesLabel(trip.basicsDeadline, controller.now),
                      style: text.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          Text(
            '${trip.organiser.name} (tie-breaks only)',
            style: text.bodyMedium,
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => _deadlines(context),
              child: const Text('Change deadlines'),
            ),
          ),
        ],
      ),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PrimaryButton(
            key: const Key('draft-invite'),
            label: 'Looks good, invite friends',
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.invite),
          ),
          QuietButton(label: 'Start over', onPressed: controller.startOver),
        ],
      ),
    );
  }

  Future<void> _rename(BuildContext context, String current) async {
    final next = await _ask(context, title: 'Trip name', initial: current);
    if (next != null && context.mounted) {
      PlanningScope.read(context).rename(next);
    }
  }

  Future<void> _openSearch(BuildContext context) async {
    final controller = PlanningScope.read(context);
    final trip = controller.trip;
    if (trip == null) {
      return;
    }
    final chosen = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _PlaceSearch(),
    );
    if (chosen != null && context.mounted) {
      PlanningScope.read(context).addCatalogPlace(chosen, extra: false);
    }
  }

  Future<void> _editWeekend(BuildContext context, TripSession trip) async {
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      builder: (context) => _WeekendSheet(now: PlanningScope.read(context).now),
    );
    if (picked != null && context.mounted) {
      PlanningScope.read(context).setWeekend(picked, trip.nights);
    }
  }

  Future<void> _deadlines(BuildContext context) async {
    final hours = await showModalBottomSheet<int>(
      context: context,
      builder: (context) => const _DeadlineSheet(),
    );
    if (hours != null && context.mounted) {
      PlanningScope.read(context).setWindow(hours);
    }
  }
}

class _Generating extends StatelessWidget {
  const _Generating();

  @override
  Widget build(BuildContext context) {
    return ProductScaffold(
      title: 'Your draft',
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Drafting something you can say yes to…',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            const _Block(width: 180),
            const SizedBox(height: 12),
            const _Block(width: double.infinity, height: 140),
          ],
        ),
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({required this.width, this.height = 18});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: JourneyColors.dune,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

class _PlaceSearch extends StatefulWidget {
  const _PlaceSearch();

  @override
  State<_PlaceSearch> createState() => _PlaceSearchState();
}

class _PlaceSearchState extends State<_PlaceSearch> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final trip = PlanningScope.of(context).trip;
    final used = trip?.places.map((place) => place.id).toSet() ?? {};
    final matches = [
      for (final place in placeCatalog)
        if (!used.contains(place.id) &&
            (_query.isEmpty ||
                place.name.toLowerCase().contains(_query.toLowerCase())))
          place,
    ];
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Search a town, region or coast',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          TextField(
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Costa, vale, city…'),
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 12),
          if (matches.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Nothing matches. Try a coast, town or region.'),
            )
          else
            for (final place in matches.take(6))
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(place.name),
                subtitle: Text('${place.travel} · ~\$${place.roughPp} pp'),
                onTap: () => Navigator.pop(context, place.id),
              ),
        ],
      ),
    );
  }
}

class _WeekendSheet extends StatelessWidget {
  const _WeekendSheet({required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final fridays = <DateTime>[];
    var day = nextFriday(now);
    for (var index = 0; index < 6; index += 1) {
      fridays.add(day);
      day = day.add(const Duration(days: 7));
    }
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Suggested weekend',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            for (final friday in fridays)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  rangeLabel(friday, friday.add(const Duration(days: 3))),
                ),
                onTap: () => Navigator.pop(context, friday),
              ),
          ],
        ),
      ),
    );
  }
}

class _DeadlineSheet extends StatelessWidget {
  const _DeadlineSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How long is the window?',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            for (final hours in [24, 48, 72])
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('$hours hours'),
                subtitle: Text(
                  hours == 24
                      ? 'The spontaneous default'
                      : 'A little more room',
                ),
                onTap: () => Navigator.pop(context, hours),
              ),
          ],
        ),
      ),
    );
  }
}

Future<String?> _ask(
  BuildContext context, {
  required String title,
  required String initial,
}) {
  final field = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(controller: field, autofocus: true),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, field.text),
          child: const Text('Save'),
        ),
      ],
    ),
  ).whenComplete(field.dispose);
}
