import 'package:flutter_test/flutter_test.dart';
import 'package:journeygo/src/data/sample_trip.dart';
import 'package:journeygo/src/logic/planning_rules.dart';
import 'package:journeygo/src/models/planning.dart';
import 'package:journeygo/src/state/planning_controller.dart';

void main() {
  final now = DateTime(2026, 10, 21, 14);

  test('comfortable band is the overlap, capped by the lowest max', () {
    final trip = buildPreview(PreviewKind.basics, now);
    final band = budgetBand(trip)!;
    expect(band.low, 200);
    expect(band.high, 260);
    expect(band.draftFits, isTrue);

    final below = buildPreview(PreviewKind.belowPlan, now);
    final tight = budgetBand(below)!;
    expect(tight.lowestMax, 180);
    expect(tight.draftFits, isFalse);
  });

  test('the best window is the Friday five people painted', () {
    final trip = buildPreview(PreviewKind.basics, now);
    final dates = bestDates(trip);
    expect(dates.group, 6);
    expect(dates.isTie, isFalse);
    expect(dates.best!.people, 5);
    expect(dates.best!.start, DateTime(2026, 11, 13));
  });

  test('advancing the deadline closes, then locks, and never commits', () {
    final controller = PlanningController(
      clock: () => now,
      generateDelay: Duration.zero,
    );
    controller.trip = buildPreview(PreviewKind.basics, now);
    final trip = controller.trip!;

    controller.advanceClock();
    expect(phaseOf(trip, DecisionKind.destination, now), DecisionPhase.closing);
    expect(controller.takeToast(), 'Last call: locks in 1h 30m.');

    controller.advanceClock();
    expect(basicsLocked(trip), isTrue);
    expect(trip.plansDeadline, isNotNull);
    expect(trip.locked.contains(DecisionKind.activities), isFalse);
    expect(trip.committed, isEmpty);

    controller.trip = buildPreview(PreviewKind.commit, now);
    controller.advanceClock();
    expect(controller.trip!.committed, isEmpty);
    expect(isConfirmed(controller.trip!), isFalse);
    expect(controller.takeToast(), contains('Commitment is never assumed'));
  });

  test('silence is not a commitment', () {
    final trip = buildPreview(PreviewKind.commit, now);
    expect(plansLocked(trip), isTrue);
    expect(trip.committed, isEmpty);
    expect(isConfirmed(trip), isFalse);
  });

  test('fewest payments is a shorter settlement than every share', () {
    final trip = buildPreview(PreviewKind.confirmed, now);
    final raw = transfersFor(trip, simplified: false);
    final simple = transfersFor(trip, simplified: true);
    expect(raw, hasLength(10));
    expect(simple.length, lessThan(raw.length));
    final settled = simple.fold<int>(0, (sum, item) => sum + item.amount);
    expect(settled, 192);
  });
}
