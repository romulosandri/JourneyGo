import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../format.dart';
import '../logic/planning_rules.dart';
import '../models/planning.dart';
import '../state/planning_scope.dart';
import '../theme/journey_theme.dart';
import '../widgets/chrome.dart';
import '../widgets/scenery.dart';

class SwipeScreen extends StatefulWidget {
  const SwipeScreen({super.key, required this.mode});

  final SwipeMode mode;

  @override
  State<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen> {
  final List<_DeckCard> _cards = [];
  int _index = 0;
  Offset _drag = Offset.zero;
  String? _matchTitle;
  bool _loaded = false;

  @override
  Widget build(BuildContext context) {
    final controller = PlanningScope.of(context);
    final trip = controller.trip;
    if (trip == null) {
      return const NeedTrip();
    }
    _ensureCards(trip);
    final kind = widget.mode == SwipeMode.destination
        ? DecisionKind.destination
        : DecisionKind.activities;
    final done = _index >= _cards.length;
    final extras = trip.places.where((place) => place.extra).length;
    return ProductScaffold(
      title: decisionTitle(kind),
      trailing: IconButton(
        tooltip: 'Add',
        onPressed: widget.mode == SwipeMode.destination && extras >= 2
            ? () => controller.note(
                'Max 2 extra places, so the choice stays small.',
              )
            : () => _add(context),
        icon: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecisionHeader(kind: kind),
            const SizedBox(height: 12),
            Expanded(child: done ? _done(context, trip) : _stack(context)),
          ],
        ),
      ),
      footer: done
          ? PrimaryButton(
              label: 'Back to trip',
              onPressed: () => Navigator.of(context).maybePop(),
            )
          : _actions(context),
    );
  }

  void _ensureCards(TripSession trip) {
    final fresh = _read(trip);
    if (!_loaded) {
      _cards.addAll(fresh);
      _loaded = true;
      return;
    }
    final known = _cards.map((card) => card.id).toSet();
    for (final card in fresh) {
      if (!known.contains(card.id)) {
        _cards.add(card);
      }
    }
  }

  List<_DeckCard> _read(TripSession trip) {
    if (widget.mode == SwipeMode.destination) {
      return [
        for (final place in trip.places)
          _DeckCard(
            id: place.id,
            title: place.name,
            meta: '${place.travel} · ~\$${place.roughPp} pp',
            blurb: place.blurb,
            byline: addedByLabel(place.addedBy, trip),
            stretch: false,
            vibe: place.vibe,
          ),
      ];
    }
    return [
      for (final activity in activityDeck(trip))
        _DeckCard(
          id: activity.id,
          title: activity.title,
          meta: activity.pricePp == 0
              ? 'Free · ${activity.duration}'
              : '\$${activity.pricePp} pp · ${activity.duration}',
          blurb: activity.blurb,
          byline: addedByLabel(activity.addedBy, trip),
          stretch: activity.stretch || activity.pricePp > activityCeiling(trip),
          vibe: trip.vibe,
        ),
    ];
  }

  Widget _stack(BuildContext context) {
    final card = _cards[_index];
    final width = MediaQuery.sizeOf(context).width;
    final angle = (_drag.dx / width).clamp(-1.0, 1.0) * 0.21;
    return Stack(
      alignment: Alignment.center,
      children: [
        if (_index + 1 < _cards.length)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
            child: _CardFace(card: _cards[_index + 1]),
          ),
        GestureDetector(
          onPanUpdate: (details) => setState(() => _drag += details.delta),
          onPanEnd: _release,
          child: Transform.translate(
            offset: _drag,
            child: Transform.rotate(
              angle: angle,
              child: Stack(
                children: [
                  _CardFace(card: card),
                  if (_matchTitle != null)
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: JourneyColors.sea,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              _matchTitle!,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(color: JourneyColors.onAccent),
                            ),
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 24,
                    left: 20,
                    child: _Stamp(
                      label: 'NO',
                      color: JourneyColors.terracotta,
                      opacity: (-_drag.dx / 120).clamp(0, 1),
                    ),
                  ),
                  Positioned(
                    top: 24,
                    right: 20,
                    child: _Stamp(
                      label: 'YES',
                      color: JourneyColors.sea,
                      opacity: (_drag.dx / 120).clamp(0, 1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _actions(BuildContext context) {
    final controller = PlanningScope.of(context);
    final used =
        controller.trip?.superLikes.containsKey(controller.trip?.viewerId) ??
        false;
    return Row(
      children: [
        _RoundAction(
          key: const Key('swipe-no'),
          tooltip: 'No',
          icon: Icons.close,
          onPressed: () => _commit(Vote.no),
        ),
        if (widget.mode == SwipeMode.destination) ...[
          const SizedBox(width: 12),
          _RoundAction(
            tooltip: 'Maybe',
            icon: Icons.question_mark,
            onPressed: () => _commit(Vote.maybe),
          ),
        ],
        const Spacer(),
        if (widget.mode == SwipeMode.activities)
          _RoundAction(
            tooltip: used ? 'You\'ve used your star.' : 'Super-like',
            icon: Icons.star,
            onPressed: used
                ? () => controller.note('You\'ve used your star.')
                : () => _super(),
          ),
        const SizedBox(width: 12),
        _RoundAction(
          key: const Key('swipe-yes'),
          tooltip: 'Yes',
          icon: Icons.favorite,
          onPressed: () => _commit(Vote.yes),
        ),
      ],
    );
  }

  Widget _done(BuildContext context, TripSession trip) {
    final id = trip.viewerId;
    var yeses = 0;
    final votes = widget.mode == SwipeMode.destination
        ? trip.destinationVotes
        : trip.activityVotes;
    for (final card in _cards) {
      final vote = votes[card.id]?[id];
      if (vote == Vote.yes) {
        yeses += 1;
      }
    }
    return Center(
      child: Text(
        'That\'s everything! You said yes to $yeses.',
        style: Theme.of(context).textTheme.headlineSmall,
        textAlign: TextAlign.center,
      ),
    );
  }

  void _release(DragEndDetails details) {
    if (_drag.dx > 110) {
      _commit(Vote.yes);
      return;
    }
    if (_drag.dx < -110) {
      _commit(Vote.no);
      return;
    }
    setState(() => _drag = Offset.zero);
  }

  Future<void> _commit(Vote vote, {bool alreadyCast = false}) async {
    if (_index >= _cards.length) {
      return;
    }
    final card = _cards[_index];
    final controller = PlanningScope.read(context);
    final trip = controller.trip;
    if (trip == null) {
      return;
    }
    if (!alreadyCast) {
      controller.castVote(widget.mode, card.id, vote);
    }
    final threshold = matchThreshold(trip.joined.length);
    final matched =
        widget.mode == SwipeMode.activities &&
        controller.yesCount(card.id) >= threshold &&
        threshold > 0;
    if (!mounted) {
      return;
    }
    if (matched && !MediaQuery.disableAnimationsOf(context)) {
      setState(() {
        _drag = Offset.zero;
        _matchTitle =
            '${controller.yesCount(card.id)} of ${trip.joined.length} liked this!';
      });
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (!mounted) {
        return;
      }
    }
    setState(() {
      _matchTitle = null;
      _drag = Offset.zero;
      _index += 1;
    });
    if (_index >= _cards.length) {
      controller.finishDeck(widget.mode);
    }
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Vote saved'),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(label: 'Undo', onPressed: _undo),
      ),
    );
  }

  void _undo() {
    final controller = PlanningScope.read(context);
    controller.undoLastVote();
    setState(() {
      _index = math.max(0, _index - 1);
      _matchTitle = null;
    });
  }

  Future<void> _super() async {
    if (_index >= _cards.length) {
      return;
    }
    final card = _cards[_index];
    final controller = PlanningScope.read(context);
    controller.superLike(card.id);
    await _commit(Vote.yes, alreadyCast: true);
  }

  Future<void> _add(BuildContext context) async {
    final controller = PlanningScope.read(context);
    final trip = controller.trip;
    if (trip == null) {
      return;
    }
    if (widget.mode == SwipeMode.destination) {
      final id = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        builder: (context) => const _PlaceAdd(),
      );
      if (id != null && context.mounted) {
        PlanningScope.read(context).addCatalogPlace(id, extra: true);
      }
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _IdeaSheet(),
    );
  }
}

class _DeckCard {
  const _DeckCard({
    required this.id,
    required this.title,
    required this.meta,
    required this.blurb,
    required this.byline,
    required this.stretch,
    required this.vibe,
  });

  final String id;
  final String title;
  final String meta;
  final String blurb;
  final String byline;
  final bool stretch;
  final Vibe vibe;
}

class _CardFace extends StatelessWidget {
  const _CardFace({required this.card});

  final _DeckCard card;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: JourneyColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: JourneyColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Scenery(vibe: card.vibe, height: 150),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(card.title, style: text.headlineSmall),
                const SizedBox(height: 6),
                Text(card.meta, style: text.titleSmall),
                const SizedBox(height: 6),
                Text(card.blurb, style: text.bodyMedium),
                const SizedBox(height: 8),
                Text(card.byline, style: text.bodySmall),
                if (card.stretch)
                  Text(
                    'Stretch',
                    style: text.titleSmall?.copyWith(
                      color: JourneyColors.amber,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stamp extends StatelessWidget {
  const _Stamp({
    required this.label,
    required this.color,
    required this.opacity,
  });

  final String label;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity.toDouble(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium
              ?.copyWith(color: color),
        ),
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        minimumSize: const Size(56, 56),
        backgroundColor: JourneyColors.ink,
        foregroundColor: JourneyColors.onAccent,
      ),
      icon: Icon(icon),
    );
  }
}

class _PlaceAdd extends StatelessWidget {
  const _PlaceAdd();

  @override
  Widget build(BuildContext context) {
    final trip = PlanningScope.of(context).trip;
    final used = trip?.places.map((place) => place.id).toSet() ?? {};
    final choices = [
      for (final place in placeCatalog)
        if (!used.contains(place.id)) place,
    ];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add a place', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              '2 extra places at most.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            for (final place in choices.take(5))
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(place.name),
                subtitle: Text(place.travel),
                onTap: () => Navigator.pop(context, place.id),
              ),
          ],
        ),
      ),
    );
  }
}

class _IdeaSheet extends StatefulWidget {
  const _IdeaSheet();

  @override
  State<_IdeaSheet> createState() => _IdeaSheetState();
}

class _IdeaSheetState extends State<_IdeaSheet> {
  final _title = TextEditingController();
  final _link = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    _link.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trip = PlanningScope.of(context).trip;
    final ceiling = trip == null ? 0 : activityCeiling(trip);
    final stretch = _title.text.trim().isNotEmpty && 36 > ceiling;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add an idea', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          TextField(
            controller: _link,
            decoration: const InputDecoration(hintText: 'Paste a link'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _title,
            decoration: const InputDecoration(
              hintText: 'e.g. Sunset catamaran',
            ),
            onChanged: (_) => setState(() {}),
          ),
          if (stretch) ...[
            const SizedBox(height: 8),
            Text(
              'Over the group budget. It\'ll be shown as stretch.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: 12),
          PrimaryButton(
            label: 'Add to the deck',
            onPressed: () {
              final error = PlanningScope.read(context)
                  .addActivity(_title.text);
              if (error != null) {
                PlanningScope.read(context).note(error);
                return;
              }
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
