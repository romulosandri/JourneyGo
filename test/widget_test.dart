import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journeygo/src/app.dart';
import 'package:journeygo/src/data/journey_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final today = DateTime(2026, 10, 20);

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('shows the sample routes and filters them', (tester) async {
    await _pumpApp(tester, today);

    expect(find.text('Lisbon'), findsOneWidget);
    expect(find.text('Oaxaca'), findsOneWidget);
    expect(find.text('Kyoto'), findsOneWidget);
    expect(find.text('3 journeys on this phone.'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Upcoming'));
    await tester.pump();

    expect(find.text('Oaxaca'), findsOneWidget);
    expect(find.text('Lisbon'), findsNothing);
    expect(find.text('Kyoto'), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, 'All'));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('journey-search')), 'inari');
    await tester.pump();

    expect(find.text('Kyoto'), findsOneWidget);
    expect(find.text('Lisbon'), findsNothing);
  });

  testWidgets('marks a stop visited from the route', (tester) async {
    await _pumpApp(tester, today);
    await tester.tap(find.text('Lisbon'));
    await tester.pumpAndSettle();

    expect(find.text('2 of 5 places'), findsOneWidget);
    final stop = find.text('LX Factory');
    await tester.ensureVisible(stop);
    final visitedBefore = tester.widgetList(find.text('Visited')).length;
    await tester.tap(stop);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.widgetList(find.text('Visited')).length, visitedBefore + 1);
    await tester.drag(find.byType(ListView).hitTestable(), const Offset(0, 800));
    await tester.pump();
    expect(find.text('3 of 5 places'), findsOneWidget);
  });

  testWidgets('adds a journey and a stop, then removes the journey', (
    tester,
  ) async {
    await _pumpApp(tester, today);

    await tester.tap(find.byKey(const Key('new-journey')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('journey-title')),
      'Coast road',
    );
    await tester.enterText(find.byKey(const Key('journey-place')), 'Big Sur');
    await tester.ensureVisible(find.byKey(const Key('save-journey')));
    await tester.tap(find.byKey(const Key('save-journey')));
    await tester.pumpAndSettle();

    final bigSur = find.text('Big Sur');
    expect(bigSur, findsOneWidget);
    await tester.ensureVisible(bigSur);
    await tester.tap(bigSur);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-stop')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('stop-name')),
      'Bixby Creek Bridge',
    );
    await tester.enterText(
      find.byKey(const Key('stop-detail')),
      'Pull over before the fog',
    );
    await tester.ensureVisible(find.byKey(const Key('save-stop')));
    await tester.tap(find.byKey(const Key('save-stop')));
    await tester.pumpAndSettle();

    expect(find.text('Bixby Creek Bridge'), findsOneWidget);
    expect(find.text('0 of 1 place'), findsOneWidget);

    await tester.tap(find.byTooltip('Remove journey'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();

    expect(find.text('Big Sur'), findsNothing);
    expect(find.text('Lisbon'), findsOneWidget);
  });
}

Future<void> _pumpApp(WidgetTester tester, DateTime today) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final preferences = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    JourneyApp(repository: JourneyRepository(preferences), clock: () => today),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 20));
}
