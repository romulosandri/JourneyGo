import 'package:flutter_test/flutter_test.dart';
import 'package:journeygo/src/data/journey_repository.dart';
import 'package:journeygo/src/data/sample_journeys.dart';
import 'package:journeygo/src/format.dart';
import 'package:journeygo/src/models/journey.dart';
import 'package:journeygo/src/state/journey_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final today = DateTime(2026, 10, 20);

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('phase follows the first and last day, inclusive', () {
    final journey = sampleJourneys(today).first;
    expect(
      journey.phaseOn(today.subtract(const Duration(days: 2))),
      JourneyPhase.upcoming,
    );
    expect(journey.phaseOn(journey.start), JourneyPhase.onTheRoad);
    expect(journey.phaseOn(today), JourneyPhase.onTheRoad);
    expect(journey.phaseOn(journey.end), JourneyPhase.onTheRoad);
    expect(
      journey.phaseOn(journey.end.add(const Duration(days: 1))),
      JourneyPhase.remembered,
    );
  });

  test('places label counts visited stops', () {
    final lisbon = sampleJourneys(today).first;
    expect(lisbon.doneCount, 2);
    expect(placesLabel(lisbon), '2 of 5 places');
    expect(placesLabel(lisbon.copyWith(stops: const [])), 'No places yet');
  });

  test('date ranges stay compact', () {
    expect(
      formatRange(DateTime(2026, 10, 14), DateTime(2026, 10, 17)),
      '14–17 Oct 2026',
    );
    expect(
      formatRange(DateTime(2026, 10, 28), DateTime(2026, 11, 2)),
      '28 Oct – 2 Nov 2026',
    );
    expect(
      formatRange(DateTime(2026, 12, 30), DateTime(2027, 1, 2)),
      '30 Dec 2026 – 2 Jan 2027',
    );
  });

  test('journeys sort active, then upcoming, then remembered', () {
    final sorted = sortJourneys(sampleJourneys(today).reversed.toList(), today);
    expect(sorted.map((journey) => journey.place), [
      'Lisbon',
      'Oaxaca',
      'Kyoto',
    ]);
  });

  test('search matches stop names and filters by phase', () {
    final journeys = sampleJourneys(today);
    final kyoto = journeys.last;
    expect(
      journeyMatches(
        kyoto,
        filter: JourneyFilter.all,
        query: 'inari',
        today: today,
      ),
      isTrue,
    );
    expect(
      journeyMatches(
        kyoto,
        filter: JourneyFilter.upcoming,
        query: '',
        today: today,
      ),
      isFalse,
    );
  });

  test('json keeps dates, accent, and stops', () {
    final journey = sampleJourneys(today).first;
    final restored = Journey.fromJson(journey.toJson());
    expect(restored.toJson(), journey.toJson());
  });

  test(
    'first launch seeds examples and a later empty list stays empty',
    () async {
      final preferences = await SharedPreferences.getInstance();
      final repository = JourneyRepository(preferences);
      final controller = JourneyController(repository, clock: () => today);

      expect(await repository.read(), isNull);
      await controller.load();
      expect(controller.journeys.map((journey) => journey.id), [
        'sample-lisbon',
        'sample-oaxaca',
        'sample-kyoto',
      ]);

      await controller.deleteJourney('sample-lisbon');
      await controller.deleteJourney('sample-oaxaca');
      await controller.deleteJourney('sample-kyoto');
      expect(controller.journeys, isEmpty);

      final reloaded = JourneyController(repository, clock: () => today);
      await reloaded.load();
      expect(reloaded.journeys, isEmpty);
    },
  );

  test(
    'corrupt storage surfaces an error and restore writes examples',
    () async {
      SharedPreferences.setMockInitialValues({
        JourneyRepository.storageKey: '{not-json',
      });
      final preferences = await SharedPreferences.getInstance();
      final controller = JourneyController(
        JourneyRepository(preferences),
        clock: () => today,
      );

      await controller.load();
      expect(controller.error, 'Could not read your journeys.');
      expect(controller.journeys, isEmpty);

      await controller.restoreSamples();
      expect(controller.error, isNull);
      expect(controller.journeys, hasLength(3));
    },
  );

  test('stops can be toggled and moved', () async {
    final preferences = await SharedPreferences.getInstance();
    final controller = JourneyController(
      JourneyRepository(preferences),
      clock: () => today,
    );
    await controller.load();

    await controller.toggleStop('sample-lisbon', 'lx-factory');
    final visited = controller.find('sample-lisbon')!;
    expect(visited.stops[2].done, isTrue);

    await controller.moveStop('sample-lisbon', 'lx-factory', -1);
    expect(controller.find('sample-lisbon')!.stops.map((stop) => stop.id), [
      'lx-market',
      'lx-factory',
      'lx-alfama',
      'lx-belem',
      'lx-monte',
    ]);
  });
}
