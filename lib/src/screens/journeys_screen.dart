import 'package:flutter/material.dart';

import '../app.dart';
import '../format.dart';
import '../models/journey.dart';
import '../theme/journey_theme.dart';
import '../widgets/journey_card.dart';
import '../widgets/layout.dart';
import '../widgets/route_mark.dart';
import 'journey_detail_screen.dart';
import 'journey_editor_screen.dart';

class JourneysScreen extends StatefulWidget {
  const JourneysScreen({super.key});

  @override
  State<JourneysScreen> createState() => _JourneysScreenState();
}

class _JourneysScreenState extends State<JourneysScreen> {
  final TextEditingController _search = TextEditingController();
  JourneyFilter _filter = JourneyFilter.all;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = JourneyScope.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      floatingActionButton: controller.loading || controller.error != null
          ? null
          : FloatingActionButton.extended(
              key: const Key('new-journey'),
              onPressed: () => _openEditor(context),
              icon: const Icon(Icons.add),
              label: const Text('New journey'),
            ),
      body: SafeArea(
        child: CenteredColumn(
          child: controller.loading && controller.journeys.isEmpty
              ? const _LoadingRoutes()
              : controller.error != null && controller.journeys.isEmpty
              ? _StoreError(
                  message: controller.error!,
                  onRestore: controller.restoreSamples,
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 108),
                  children: [
                    Text(
                      'JOURNEYGO',
                      style: textTheme.labelMedium?.copyWith(
                        letterSpacing: 1.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Where to next?', style: textTheme.displaySmall),
                    const SizedBox(height: 8),
                    Text(
                      journeyCountLabel(controller.journeys.length),
                      style: textTheme.bodyLarge?.copyWith(
                        color: JourneyColors.inkSoft,
                      ),
                    ),
                    if (controller.error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        controller.error!,
                        style: textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    TextField(
                      key: const Key('journey-search'),
                      controller: _search,
                      textInputAction: TextInputAction.search,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'Search places or trips',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final filter in JourneyFilter.values)
                          ChoiceChip(
                            label: Text(filterLabel(filter)),
                            selected: _filter == filter,
                            showCheckmark: false,
                            labelStyle: textTheme.labelLarge?.copyWith(
                              color: _filter == filter
                                  ? JourneyColors.paper
                                  : JourneyColors.ink,
                            ),
                            selectedColor: JourneyColors.ink,
                            backgroundColor: Colors.transparent,
                            side: BorderSide(
                              color: _filter == filter
                                  ? JourneyColors.ink
                                  : JourneyColors.line,
                            ),
                            onSelected: (_) => setState(() => _filter = filter),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _JourneyList(
                      filter: _filter,
                      query: _search.text,
                      onOpen: (journey) {
                        FocusManager.instance.primaryFocus?.unfocus();
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (context) =>
                                JourneyDetailScreen(journeyId: journey.id),
                          ),
                        );
                      },
                      onCreate: () => _openEditor(context),
                      onShowAll: _showAll,
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  void _showAll() {
    _search.clear();
    setState(() => _filter = JourneyFilter.all);
  }

  void _openEditor(BuildContext context) {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const JourneyEditorScreen(),
      ),
    );
  }
}

class _LoadingRoutes extends StatelessWidget {
  const _LoadingRoutes();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const RouteMark(size: 88),
          const SizedBox(height: 16),
          Text(
            'Opening your routes…',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

class _StoreError extends StatelessWidget {
  const _StoreError({required this.message, required this.onRestore});

  final String message;
  final Future<void> Function() onRestore;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const RouteMark(size: 88, color: JourneyColors.night),
          const SizedBox(height: 16),
          Text(
            'These journeys could not be read.',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: onRestore,
            child: const Text('Restore the sample routes'),
          ),
        ],
      ),
    );
  }
}

class _JourneyList extends StatelessWidget {
  const _JourneyList({
    required this.filter,
    required this.query,
    required this.onOpen,
    required this.onCreate,
    required this.onShowAll,
  });

  final JourneyFilter filter;
  final String query;
  final ValueChanged<Journey> onOpen;
  final VoidCallback onCreate;
  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context) {
    final controller = JourneyScope.of(context);
    final visible = [
      for (final journey in controller.journeys)
        if (journeyMatches(
          journey,
          filter: filter,
          query: query,
          today: controller.today,
        ))
          journey,
    ];
    if (controller.journeys.isEmpty) {
      return _EmptyRoutes(
        title: 'Your map is clear.',
        message: 'Add a journey when the next trip has a shape.',
        action: 'Plan a journey',
        onPressed: onCreate,
      );
    }
    if (visible.isEmpty) {
      final trimmed = query.trim();
      return _EmptyRoutes(
        title: 'Nothing in this view.',
        message: trimmed.isEmpty
            ? 'Nothing sits in this filter.'
            : 'No journeys match “$trimmed”.',
        action: 'Show every journey',
        onPressed: onShowAll,
      );
    }
    return Column(
      children: [
        for (final journey in visible) ...[
          JourneyCard(
            key: ValueKey('journey-${journey.id}'),
            journey: journey,
            today: controller.today,
            onTap: () => onOpen(journey),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _EmptyRoutes extends StatelessWidget {
  const _EmptyRoutes({
    required this.title,
    required this.message,
    required this.action,
    required this.onPressed,
  });

  final String title;
  final String message;
  final String action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          const RouteMark(size: 96, color: JourneyColors.sea),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(color: JourneyColors.inkSoft),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: onPressed, child: Text(action)),
        ],
      ),
    );
  }
}
