import 'dart:ui';

import 'package:flutter/material.dart';

import '../format.dart';
import '../logic/planning_rules.dart';
import '../models/planning.dart';
import '../routes.dart';
import '../state/planning_scope.dart';
import '../theme/journey_theme.dart';
import '../widgets/chrome.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key, required this.kind});

  final DecisionKind kind;

  @override
  Widget build(BuildContext context) {
    final controller = PlanningScope.of(context);
    final trip = controller.trip;
    if (trip == null) {
      return const NeedTrip();
    }
    final locked = trip.locked.contains(kind);
    final phase = phaseOf(trip, kind, controller.now);
    final finished = viewerFinished(trip, kind);
    final revealBudget =
        kind != DecisionKind.budget ||
        (trip.budgets.containsKey(trip.viewerId) &&
            trip.budgets.length >= trip.halfRequired);
    final hideScores = !revealBudget || (!locked && !finished);
    final text = Theme.of(context).textTheme;
    return ProductScaffold(
      title: decisionTitle(kind),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          DecisionHeader(kind: kind),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: Text(_headline(trip), style: text.headlineSmall)),
              if (locked) ...[const SizedBox(width: 8), const LockedStamp()],
            ],
          ),
          if (phase == DecisionPhase.closing && !locked) ...[
            const SizedBox(height: 8),
            Text(
              'Last call',
              style: text.titleMedium?.copyWith(color: JourneyColors.amber),
            ),
          ],
          const SizedBox(height: 8),
          Text(waitingLabel(waitingCount(trip, kind))),
          const SizedBox(height: 16),
          if (trip.objections[kind] case final objection?)
            if (!objection.resolved)
              _Objection(kind: kind, objection: objection),
          if (!locked && needsTie(trip, kind)) _TieBreak(kind: kind),
          if (hideScores)
            _HiddenScores(budget: kind == DecisionKind.budget && !revealBudget)
          else
            _ScoreList(kind: kind),
          if (_canObject(trip, controller.now)) ...[
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => _object(context),
              child: const Text('I object'),
            ),
            Text(
              'One objection, for 12 hours after the lock.',
              style: text.bodySmall,
            ),
          ],
        ],
      ),
      footer: _footer(context, trip, locked, finished),
    );
  }

  Widget _footer(
    BuildContext context,
    TripSession trip,
    bool locked,
    bool finished,
  ) {
    if (!locked && !finished) {
      return PrimaryButton(
        label: 'Weigh in',
        onPressed: () => _weighIn(context),
      );
    }
    return PrimaryButton(
      label: locked ? 'Looks good' : 'Back to trip',
      onPressed: () => _leave(context),
    );
  }

  bool _canObject(TripSession trip, DateTime now) {
    if (!trip.locked.contains(kind) || trip.objections.containsKey(kind)) {
      return false;
    }
    final lockedAt = trip.lockedAt[kind];
    if (lockedAt == null) {
      return false;
    }
    return !now.isAfter(lockedAt.add(const Duration(hours: 12)));
  }

  String _headline(TripSession trip) {
    switch (kind) {
      case DecisionKind.destination:
        final ranking = rankDestinations(trip);
        if (ranking.tie) {
          return 'Two places are level';
        }
        return ranking.leader?.title ?? trip.places.first.name;
      case DecisionKind.dates:
        final dates = bestDates(trip);
        if (dates.isTie) {
          return 'Two weekends are level';
        }
        final window = dates.best;
        if (window == null) {
          return sentenceRange(trip.start, trip.end);
        }
        return sentenceRange(window.start, window.end);
      case DecisionKind.budget:
        final band = budgetBand(trip);
        if (band == null) {
          return 'Waiting for a few private answers';
        }
        return 'Comfortable ${money(band.low)}–${money(band.high)}';
      case DecisionKind.activities:
        final anchors = anchorActivities(trip);
        if (anchors.isEmpty) {
          return 'The top three are tied';
        }
        return anchors.map((item) => item.title).join(' · ');
      case DecisionKind.stay:
        final ranking = rankStays(trip);
        if (ranking.tie) {
          return 'Two stays are level';
        }
        return ranking.leader?.title ?? 'A shortlisted stay';
    }
  }

  void _weighIn(BuildContext context) {
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

  Future<void> _object(BuildContext context) async {
    final reason = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _ObjectSheet(),
    );
    if (reason == null || !context.mounted) {
      return;
    }
    PlanningScope.read(context).objectTo(kind, reason);
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

class _HiddenScores extends StatelessWidget {
  const _HiddenScores({required this.budget});

  final bool budget;

  @override
  Widget build(BuildContext context) {
    final message = budget
        ? 'The range stays hidden until you\'ve answered and at least half the group has.'
        : 'Weigh in to see how the group is leaning.';
    return Stack(
      alignment: Alignment.center,
      children: [
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
          child: const IgnorePointer(
            child: Column(
              children: [
                _GhostBar(),
                SizedBox(height: 10),
                _GhostBar(width: 0.62),
                SizedBox(height: 10),
                _GhostBar(width: 0.4),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 8),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ],
    );
  }
}

class _GhostBar extends StatelessWidget {
  const _GhostBar({this.width = 1});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: width,
        child: Container(
          height: 36,
          decoration: BoxDecoration(
            color: JourneyColors.dune,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}

class _ScoreList extends StatelessWidget {
  const _ScoreList({required this.kind});

  final DecisionKind kind;

  @override
  Widget build(BuildContext context) {
    final trip = PlanningScope.of(context).trip!;
    final rows = _rows(trip);
    if (rows.isEmpty) {
      return const Text('Nothing to compare yet.');
    }
    var maxScore = 1;
    for (final row in rows) {
      if (row.score > maxScore) {
        maxScore = row.score;
      }
    }
    return Column(
      children: [
        for (final row in rows) ...[
          _ScoreBar(row: row, maxScore: maxScore),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  List<_ScoreRow> _rows(TripSession trip) {
    switch (kind) {
      case DecisionKind.destination:
        return [
          for (final option in rankDestinations(trip).options)
            _ScoreRow(
              id: option.id,
              title: option.title,
              meta: '${option.yes} yes',
              score: option.score,
            ),
        ];
      case DecisionKind.activities:
        return [
          for (final option in rankActivities(trip).options)
            _ScoreRow(
              id: option.id,
              title: option.title,
              meta: option.meta,
              score: option.score,
            ),
        ];
      case DecisionKind.stay:
        return [
          for (final option in rankStays(trip).options)
            _ScoreRow(
              id: option.id,
              title: option.title,
              meta: '${option.yes} votes',
              score: option.score,
            ),
        ];
      case DecisionKind.dates:
        final dates = bestDates(trip);
        final windows = dates.isTie
            ? dates.tied
            : [if (dates.best != null) dates.best!];
        return [
          for (final window in windows)
            _ScoreRow(
              id: dayKey(window.start),
              title: sentenceRange(window.start, window.end),
              meta: '${window.people} of ${dates.group}',
              score: window.people,
            ),
        ];
      case DecisionKind.budget:
        final band = budgetBand(trip);
        if (band == null) {
          return const [];
        }
        return [
          _ScoreRow(
            id: 'low',
            title: 'Low end',
            meta: 'Lowest comfortable',
            score: band.low,
          ),
          _ScoreRow(
            id: 'high',
            title: 'High end',
            meta: band.draftFits
                ? 'The draft fits'
                : 'The draft is above the cap',
            score: band.high,
          ),
        ];
    }
  }
}

class _ScoreRow {
  const _ScoreRow({
    required this.id,
    required this.title,
    required this.meta,
    required this.score,
  });

  final String id;
  final String title;
  final String meta;
  final int score;
}

class _ScoreBar extends StatelessWidget {
  const _ScoreBar({required this.row, required this.maxScore});

  final _ScoreRow row;
  final int maxScore;

  @override
  Widget build(BuildContext context) {
    final fraction = maxScore == 0 ? 0.0 : row.score / maxScore;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(row.title, style: text.titleSmall)),
            Text(row.meta, style: text.bodySmall),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: fraction.clamp(0, 1),
            backgroundColor: JourneyColors.dune,
            color: JourneyColors.sea,
          ),
        ),
      ],
    );
  }
}

class _TieBreak extends StatelessWidget {
  const _TieBreak({required this.kind});

  final DecisionKind kind;

  @override
  Widget build(BuildContext context) {
    final controller = PlanningScope.of(context);
    final trip = controller.trip!;
    final text = Theme.of(context).textTheme;
    if (!trip.viewerIsOrganiser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Text(
          '${trip.organiser.name} is breaking a tie.',
          style: text.titleMedium,
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: PaperCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Break the tie', style: text.titleLarge),
            const SizedBox(height: 6),
            const Text('You can only choose between the top options.'),
            const SizedBox(height: 12),
            ..._choices(context, trip),
          ],
        ),
      ),
    );
  }

  List<Widget> _choices(BuildContext context, TripSession trip) {
    final controller = PlanningScope.read(context);
    switch (kind) {
      case DecisionKind.destination:
        return [
          for (final option in _top(rankDestinations(trip)))
            _ChoiceButton(
              label: option.title,
              onPressed: () => controller.breakDestinationTie(option.id),
            ),
        ];
      case DecisionKind.stay:
        return [
          for (final option in _top(rankStays(trip)))
            _ChoiceButton(
              label: option.title,
              onPressed: () => controller.breakStayTie(option.id),
            ),
        ];
      case DecisionKind.activities:
        final ranking = rankActivities(trip);
        final options = ranking.options.length >= 4
            ? [ranking.options[2], ranking.options[3]]
            : ranking.options;
        return [
          for (final option in options)
            _ChoiceButton(
              label: option.title,
              onPressed: () => controller.breakActivityTie(option.id),
            ),
        ];
      case DecisionKind.dates:
        final dates = bestDates(trip);
        return [
          for (final window in dates.tied)
            _ChoiceButton(
              label: sentenceRange(window.start, window.end),
              onPressed: () => controller.breakDateTie(window.start),
            ),
        ];
      case DecisionKind.budget:
        return const [];
    }
  }

  List<RankedOption> _top(Ranking ranking) {
    if (ranking.options.isEmpty) {
      return const [];
    }
    final top = ranking.options.first.score;
    return [
      for (final option in ranking.options)
        if (option.score == top) option,
    ];
  }
}

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(onPressed: onPressed, child: Text(label)),
      ),
    );
  }
}

class _Objection extends StatelessWidget {
  const _Objection({required this.kind, required this.objection});

  final DecisionKind kind;
  final ObjectionState objection;

  @override
  Widget build(BuildContext context) {
    final controller = PlanningScope.of(context);
    final trip = controller.trip!;
    final name = trip.member(objection.memberId)?.name ?? 'Someone';
    final reason = objection.reason;
    final text = Theme.of(context).textTheme;
    final options = _options(trip);
    final mine = objection.votes[trip.viewerId];
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: PaperCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$name objected. Quick 12h re-vote.', style: text.titleMedium),
            if (reason != null && reason.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(reason),
            ],
            const SizedBox(height: 12),
            for (final option in options)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    key: Key('objection-${option.id}'),
                    onPressed: mine == null
                        ? () => controller.voteObjection(kind, option.id)
                        : null,
                    child: Text(
                      mine == option.id
                          ? '${option.title} · your vote'
                          : option.title,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<_ScoreRow> _options(TripSession trip) {
    switch (kind) {
      case DecisionKind.destination:
        return _take(rankDestinations(trip).options);
      case DecisionKind.activities:
        return _take(rankActivities(trip).options);
      case DecisionKind.stay:
        return _take(rankStays(trip).options);
      case DecisionKind.dates:
        final dates = bestDates(trip);
        final windows = dates.tied.isNotEmpty
            ? dates.tied
            : [if (dates.best != null) dates.best!];
        return [
          for (final window in windows.take(2))
            _ScoreRow(
              id: dayKey(window.start),
              title: sentenceRange(window.start, window.end),
              meta: '',
              score: window.people,
            ),
        ];
      case DecisionKind.budget:
        return const [
          _ScoreRow(id: 'keep', title: 'Keep the range', meta: '', score: 1),
          _ScoreRow(id: 'lower', title: 'Lower the plan', meta: '', score: 1),
        ];
    }
  }

  List<_ScoreRow> _take(List<RankedOption> options) {
    return [
      for (final option in options.take(2))
        _ScoreRow(
          id: option.id,
          title: option.title,
          meta: '',
          score: option.score,
        ),
    ];
  }
}

class _ObjectSheet extends StatefulWidget {
  const _ObjectSheet();

  @override
  State<_ObjectSheet> createState() => _ObjectSheetState();
}

class _ObjectSheetState extends State<_ObjectSheet> {
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
          Text(
            'What should we reopen?',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'One sentence is enough. The group gets a single 12 hour re-vote.',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reason,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Optional reason'),
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            label: 'Send the objection',
            onPressed: () => Navigator.pop(context, _reason.text),
          ),
        ],
      ),
    );
  }
}
