import 'package:flutter/material.dart';

import '../app.dart';
import '../format.dart';
import '../models/journey.dart';
import '../theme/journey_theme.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/layout.dart';
import '../widgets/phase_chip.dart';
import 'journey_editor_screen.dart';
import 'stop_editor_screen.dart';

enum _StopMenu { earlier, later, edit, remove }

class JourneyDetailScreen extends StatelessWidget {
  const JourneyDetailScreen({super.key, required this.journeyId});

  final String journeyId;

  @override
  Widget build(BuildContext context) {
    final controller = JourneyScope.of(context);
    final journey = controller.find(journeyId);
    if (journey == null) {
      return const Scaffold(body: SizedBox.shrink());
    }
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(journey.place),
        actions: [
          IconButton(
            tooltip: 'Edit journey',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => JourneyEditorScreen(journey: journey),
                ),
              );
            },
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Remove journey',
            onPressed: () => _deleteJourney(context, journey),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add-stop'),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) => StopEditorScreen(journeyId: journey.id),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add a stop'),
      ),
      body: CenteredColumn(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 112),
          children: [
            Text(journey.title, style: textTheme.headlineMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                PhaseChip(
                  phase: journey.phaseOn(controller.today),
                  accent: journey.accent,
                ),
                Text(
                  formatRange(journey.start, journey.end),
                  style: textTheme.bodyLarge,
                ),
              ],
            ),
            if (journey.note.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(journey.note, style: textTheme.bodyLarge),
            ],
            const SizedBox(height: 20),
            Text(placesLabel(journey), style: textTheme.titleSmall),
            if (journey.stops.isNotEmpty) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: journey.progress,
                  minHeight: 8,
                  backgroundColor: JourneyColors.line,
                  color: journey.accent.color,
                ),
              ),
            ],
            if (controller.error != null) ...[
              const SizedBox(height: 12),
              Text(
                controller.error!,
                style: textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 24),
            Text('The route', style: textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              journey.stops.isEmpty
                  ? 'Add the places in the order you want to meet them.'
                  : 'Tap a place when you have been. Hold the menu to reorder.',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            if (journey.stops.isEmpty)
              const _EmptyRoute()
            else
              for (var i = 0; i < journey.stops.length; i++)
                _StopTile(
                  journey: journey,
                  stop: journey.stops[i],
                  last: i == journey.stops.length - 1,
                  index: i,
                ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteJourney(BuildContext context, Journey journey) async {
    final shouldDelete = await confirm(
      context,
      title: 'Remove ${journey.place}?',
      message: 'The stops go with it. This stays on this phone only.',
      confirmLabel: 'Remove',
    );
    if (!shouldDelete || !context.mounted) {
      return;
    }
    await JourneyScope.read(context).deleteJourney(journey.id);
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }
}

class _EmptyRoute extends StatelessWidget {
  const _EmptyRoute();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: JourneyColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: JourneyColors.line),
      ),
      child: Text(
        'No places yet. The first stop becomes the start of the route.',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}

class _StopTile extends StatelessWidget {
  const _StopTile({
    required this.journey,
    required this.stop,
    required this.last,
    required this.index,
  });

  final Journey journey;
  final Stop stop;
  final bool last;
  final int index;

  @override
  Widget build(BuildContext context) {
    final accent = journey.accent.color;
    final textTheme = Theme.of(context).textTheme;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 18,
                  height: 18,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: stop.done ? accent : Colors.transparent,
                    border: Border.all(color: accent, width: 2),
                  ),
                  child: stop.done
                      ? const Icon(
                          Icons.check,
                          size: 12,
                          color: JourneyColors.onAccent,
                        )
                      : null,
                ),
                if (!last)
                  Expanded(
                    child: Container(width: 2, color: JourneyColors.line),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : 8),
              child: Material(
                color: JourneyColors.card,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  key: ValueKey('stop-${stop.id}'),
                  onTap: () =>
                      JourneyScope.read(context)
                          .toggleStop(journey.id, stop.id),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                stop.name,
                                style: textTheme.titleMedium?.copyWith(
                                  color: stop.done
                                      ? JourneyColors.inkSoft
                                      : JourneyColors.ink,
                                ),
                              ),
                              if (stop.detail.isNotEmpty)
                                Text(stop.detail, style: textTheme.bodyMedium),
                              Text(
                                stop.done ? 'Visited' : 'Not yet',
                                style: textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton<_StopMenu>(
                          tooltip: 'Stop actions',
                          onSelected: (action) => _onMenu(context, action),
                          itemBuilder: (context) => [
                            if (index > 0)
                              const PopupMenuItem(
                                value: _StopMenu.earlier,
                                child: Text('Move earlier'),
                              ),
                            if (index < journey.stops.length - 1)
                              const PopupMenuItem(
                                value: _StopMenu.later,
                                child: Text('Move later'),
                              ),
                            const PopupMenuItem(
                              value: _StopMenu.edit,
                              child: Text('Edit stop'),
                            ),
                            const PopupMenuItem(
                              value: _StopMenu.remove,
                              child: Text('Remove stop'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onMenu(BuildContext context, _StopMenu action) async {
    final controller = JourneyScope.read(context);
    switch (action) {
      case _StopMenu.earlier:
        await controller.moveStop(journey.id, stop.id, -1);
      case _StopMenu.later:
        await controller.moveStop(journey.id, stop.id, 1);
      case _StopMenu.edit:
        if (!context.mounted) {
          return;
        }
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (context) =>
                StopEditorScreen(journeyId: journey.id, stop: stop),
          ),
        );
      case _StopMenu.remove:
        if (!context.mounted) {
          return;
        }
        final shouldDelete = await confirm(
          context,
          title: 'Remove ${stop.name}?',
          message: 'It leaves the route. The rest of the journey stays.',
          confirmLabel: 'Remove',
        );
        if (shouldDelete) {
          await controller.deleteStop(journey.id, stop.id);
        }
    }
  }
}
