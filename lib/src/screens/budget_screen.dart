import 'package:flutter/material.dart';

import '../logic/planning_rules.dart';
import '../models/planning.dart';
import '../state/planning_scope.dart';
import '../theme/journey_theme.dart';
import '../widgets/chrome.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  String? _viewer;
  int _comfortable = 240;
  int _max = 240;
  bool _perDay = false;

  void _load(TripSession trip) {
    if (_viewer == trip.viewerId) {
      return;
    }
    _viewer = trip.viewerId;
    final saved = trip.budgets[_viewer];
    _comfortable = saved?.comfortable ?? trip.draftCost;
    _max = saved?.max ?? trip.draftCost;
    if (_max < _comfortable) {
      _max = _comfortable;
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = PlanningScope.of(context);
    final trip = controller.trip;
    if (trip == null) {
      return const NeedTrip();
    }
    _load(trip);
    final saved = trip.budgets[trip.viewerId];
    final band = budgetBand(trip);
    final reveal = saved != null && trip.budgets.length >= trip.halfRequired;
    final text = Theme.of(context).textTheme;
    final nights = trip.nights;
    return ProductScaffold(
      title: 'Budget',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          const DecisionHeader(kind: DecisionKind.budget),
          const SizedBox(height: 18),
          Text('What works for you?', style: text.headlineSmall),
          const SizedBox(height: 6),
          Text(
            '🔒 Only you see these. The group sees one comfortable range, never who said what.',
            style: text.bodyLarge?.copyWith(color: JourneyColors.inkSoft),
          ),
          const SizedBox(height: 16),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Whole trip')),
              ButtonSegment(value: true, label: Text('Per day')),
            ],
            selected: {_perDay},
            onSelectionChanged: (value) =>
                setState(() => _perDay = value.first),
          ),
          const SizedBox(height: 18),
          Text('Comfortable per person', style: text.titleSmall),
          RollingNumber(
            value: _shown(_comfortable, nights),
            style: text.displaySmall,
          ),
          if (_perDay)
            Text('Whole trip \$$_comfortable', style: text.bodySmall),
          Slider(
            value: _comfortable.toDouble(),
            min: 40,
            max: 760,
            activeColor: JourneyColors.sea,
            onChanged: (value) {
              setState(() {
                _comfortable = value.round();
                if (_max < _comfortable) {
                  _max = _comfortable;
                }
              });
            },
          ),
          Text('My absolute max', style: text.titleSmall),
          RollingNumber(
            value: _shown(_max, nights),
            style: text.headlineMedium,
          ),
          Slider(
            value: _max.toDouble().clamp(_comfortable.toDouble(), 800),
            min: _comfortable.toDouble(),
            max: 800,
            activeColor: JourneyColors.ink,
            onChanged: (value) => setState(() => _max = value.round()),
          ),
          if (saved != null) ...[
            const SizedBox(height: 8),
            Text(
              'Saved. Only you can see this.',
              style: text.titleSmall?.copyWith(color: JourneyColors.sea),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            waitingLabel(waitingCount(trip, DecisionKind.budget)),
            style: text.bodyMedium,
          ),
          if (reveal && band != null) ...[
            const SizedBox(height: 14),
            PaperCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    band.hasOverlap
                        ? 'Comfortable for everyone: \$${band.low}–\$${band.high} each'
                        : 'No shared range yet.',
                    style: text.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    band.draftFits
                        ? 'Draft estimate ~\$${trip.draftCost} ✓ fits'
                        : 'The draft estimate doesn\'t fit the range.',
                    style: text.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
          if (trip.viewerIsOrganiser && band != null && !band.draftFits) ...[
            const SizedBox(height: 12),
            PaperCard(
              color: const Color(0xFFFFF4E8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Heads up: one person\'s max is below the plan. Try a cheaper stay or fewer paid activities.',
                    style: text.bodyLarge?.copyWith(color: JourneyColors.ink),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: controller.lowerPlan,
                    child: const Text('Lower the plan'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PrimaryButton(
            key: const Key('budget-save'),
            label: 'Save privately',
            onPressed: () => controller.saveBudget(_comfortable, _max),
          ),
          QuietButton(
            label: 'Skip, the draft estimate is fine for me',
            onPressed: controller.skipBudget,
          ),
        ],
      ),
    );
  }

  int _shown(int whole, int nights) {
    if (!_perDay || nights <= 0) {
      return whole;
    }
    return (whole / nights).round();
  }
}
