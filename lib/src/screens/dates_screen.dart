import 'package:flutter/material.dart';

import '../format.dart';
import '../logic/planning_rules.dart';
import '../models/planning.dart';
import '../state/planning_scope.dart';
import '../theme/journey_theme.dart';
import '../widgets/chrome.dart';

class DatesScreen extends StatefulWidget {
  const DatesScreen({super.key});

  @override
  State<DatesScreen> createState() => _DatesScreenState();
}

class _DatesScreenState extends State<DatesScreen> {
  final Map<String, GlobalKey> _keys = {};
  Set<String> _painted = {};
  String? _viewer;

  @override
  Widget build(BuildContext context) {
    final controller = PlanningScope.of(context);
    final trip = controller.trip;
    if (trip == null) {
      return const NeedTrip();
    }
    if (_viewer != trip.viewerId) {
      _viewer = trip.viewerId;
      _painted = {...?trip.availability[_viewer]};
    }
    final result = bestDates(
      trip,
      viewerDraft: _painted,
      viewerId: trip.viewerId,
    );
    final window =
        result.best ?? (result.tied.isEmpty ? null : result.tied.first);
    final text = Theme.of(context).textTheme;
    final months = [
      DateTime(controller.now.year, controller.now.month),
      DateTime(controller.now.year, controller.now.month + 1),
      DateTime(controller.now.year, controller.now.month + 2),
    ];
    return ProductScaffold(
      title: 'Dates',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          const DecisionHeader(kind: DecisionKind.dates),
          const SizedBox(height: 18),
          Text('When could you go?', style: text.headlineSmall),
          const SizedBox(height: 6),
          Text(
            'Drag across days, or tap a weekend. We\'ll find the overlap.',
            style: text.bodyLarge?.copyWith(color: JourneyColors.inkSoft),
          ),
          const SizedBox(height: 8),
          Text('${trip.nights} nights (from draft)', style: text.titleSmall),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final saturday in _upcomingSaturdays(controller.now))
                ActionChip(
                  label: Text('Weekend ${monthDay(saturday)}'),
                  onPressed: () {
                    setState(() {
                      _painted.add(dayKey(saturday));
                      _painted.add(
                        dayKey(saturday.add(const Duration(days: 1))),
                      );
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_painted.isEmpty)
            Text(
              'Drag across the days you could travel.',
              style: text.bodySmall,
            ),
          GestureDetector(
            onPanUpdate: (details) =>
                _paintAt(details.globalPosition, toggle: false),
            child: Column(
              children: [
                for (final month in months)
                  _Month(
                    month: month,
                    today: controller.now,
                    painted: _painted,
                    keys: _keys,
                    windowStart: window?.start,
                    windowEnd: window?.end,
                    countFor: (key) => paintedCount(
                      trip,
                      key,
                      viewerDraft: _painted,
                      viewerId: trip.viewerId,
                    ),
                    onTap: (key) => _paintAtKey(key, toggle: true),
                    onLongPress: (key) {
                      final count = paintedCount(
                        trip,
                        key,
                        viewerDraft: _painted,
                        viewerId: trip.viewerId,
                      );
                      controller.note('$count free');
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          PaperCard(
            child: Text(
              _windowCopy(result.group, window?.people ?? 0, window),
              style: text.titleMedium,
            ),
          ),
        ],
      ),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PrimaryButton(
            key: const Key('save-dates'),
            label: 'Save my dates',
            onPressed: () {
              final saved = controller.saveDates(_painted);
              if (saved && context.mounted) {
                Navigator.of(context).maybePop();
              }
            },
          ),
          QuietButton(
            label: 'Any weekend works',
            onPressed: () {
              controller.acceptAnyWeekend();
              Navigator.of(context).maybePop();
            },
          ),
        ],
      ),
    );
  }

  String _windowCopy(int group, int people, DateWindow? window) {
    if (window == null || people == 0) {
      return 'Paint a few days. If no one objects, the suggested weekend stands.';
    }
    final label = sentenceRange(window.start, window.end);
    if (people >= group - 1) {
      return '🔥 $label works for $people of $group';
    }
    return 'No window works for everyone. Closest: $label ($people of $group).';
  }

  void _paintAt(Offset global, {required bool toggle}) {
    for (final entry in _keys.entries) {
      final box = entry.value.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.attached || !box.hasSize) {
        continue;
      }
      final local = box.globalToLocal(global);
      if (local.dx < 0 ||
          local.dy < 0 ||
          local.dx > box.size.width ||
          local.dy > box.size.height) {
        continue;
      }
      _paintAtKey(entry.key, toggle: toggle);
      return;
    }
  }

  void _paintAtKey(String key, {required bool toggle}) {
    setState(() {
      if (toggle) {
        if (!_painted.add(key)) {
          _painted.remove(key);
        }
      } else {
        _painted.add(key);
      }
    });
  }
}

class _Month extends StatelessWidget {
  const _Month({
    required this.month,
    required this.today,
    required this.painted,
    required this.keys,
    required this.countFor,
    required this.onTap,
    required this.onLongPress,
    this.windowStart,
    this.windowEnd,
  });

  final DateTime month;
  final DateTime today;
  final Set<String> painted;
  final Map<String, GlobalKey> keys;
  final DateTime? windowStart;
  final DateTime? windowEnd;
  final int Function(String key) countFor;
  final void Function(String key) onTap;
  final void Function(String key) onLongPress;

  @override
  Widget build(BuildContext context) {
    final rows = _weeks(month);
    final todayStart = DateTime(today.year, today.month, today.day);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${monthShort[month.month - 1]} ${month.year}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final label in ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
                Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
          ),
          for (final week in rows)
            Row(
              children: [
                for (final day in week)
                  Expanded(child: _cell(context, day, todayStart)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _cell(BuildContext context, DateTime? day, DateTime todayStart) {
    if (day == null) {
      return const SizedBox(height: 44);
    }
    final key = dayKey(day);
    final past = day.isBefore(todayStart);
    final mine = painted.contains(key);
    final count = past ? 0 : countFor(key);
    final inWindow =
        windowStart != null &&
        windowEnd != null &&
        !day.isBefore(windowStart!) &&
        day.isBefore(windowEnd!);
    final cellKey = keys.putIfAbsent(key, GlobalKey.new);
    final heat = count == 0 ? 0.0 : (count / 6).clamp(0.15, 0.55);
    return GestureDetector(
      key: cellKey,
      onTap: past ? null : () => onTap(key),
      onLongPress: past ? null : () => onLongPress(key),
      child: Container(
        height: 44,
        margin: const EdgeInsets.all(2),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: mine
              ? JourneyColors.terracotta
              : JourneyColors.sea.withValues(alpha: heat),
          borderRadius: BorderRadius.circular(10),
          border: inWindow
              ? Border.all(color: JourneyColors.sea, width: 1.6)
              : null,
        ),
        child: Text(
          '${day.day}',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: mine
                ? JourneyColors.onAccent
                : past
                ? JourneyColors.line
                : JourneyColors.ink,
          ),
        ),
      ),
    );
  }
}

List<DateTime> _upcomingSaturdays(DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  var day = today;
  while (day.weekday != DateTime.saturday) {
    day = day.add(const Duration(days: 1));
  }
  return [
    for (var index = 0; index < 4; index += 1)
      day.add(Duration(days: 7 * index)),
  ];
}

List<List<DateTime?>> _weeks(DateTime month) {
  final first = DateTime(month.year, month.month, 1);
  final days = DateTime(month.year, month.month + 1, 0).day;
  final cells = <DateTime?>[
    for (var index = 0; index < first.weekday - 1; index += 1) null,
    for (var day = 1; day <= days; day += 1)
      DateTime(month.year, month.month, day),
  ];
  while (cells.length % 7 != 0) {
    cells.add(null);
  }
  return [
    for (var index = 0; index < cells.length; index += 7)
      cells.sublist(index, index + 7),
  ];
}
