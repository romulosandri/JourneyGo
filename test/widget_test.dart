import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journeygo/src/app.dart';
import 'package:journeygo/src/widgets/chrome.dart';

void main() {
  final now = DateTime(2026, 10, 21, 14);

  Future<void> launch(WidgetTester tester) async {
    tester.view.physicalSize = const Size(393, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      JourneyApp(clock: () => now, generateDelay: Duration.zero),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the draft stays closed until a vibe is chosen', (tester) async {
    await launch(tester);
    expect(
      tester
          .widget<PrimaryButton>(find.byKey(const Key('spark-continue')))
          .onPressed,
      isNull,
    );
    await tester.tap(find.byKey(const Key('vibe-beach')));
    await tester.pump();
    expect(
      tester
          .widget<PrimaryButton>(find.byKey(const Key('spark-continue')))
          .onPressed,
      isNotNull,
    );
    await tester.tap(find.byKey(const Key('spark-continue')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Costa Lumen'), findsWidgets);
  });

  testWidgets('the hub waits without naming anyone', (tester) async {
    await launch(tester);
    await tester.tap(find.byIcon(Icons.layers_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('preview-basics')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('hub-screen')), findsOneWidget);
    expect(find.text('Waiting on 1 person'), findsWidgets);
    expect(find.text('Waiting on 2 people'), findsWidgets);
    for (final name in ['Bruno', 'Caio', 'Duda', 'Leo', 'Mari']) {
      expect(find.textContaining(name), findsNothing);
    }
  });

  testWidgets('Mari never sees anyone else\'s budget numbers', (tester) async {
    await launch(tester);
    await tester.tap(find.byIcon(Icons.layers_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('preview-basics')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('View as someone else'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('viewer-mari')));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const Key('hub-screen')),
      const Offset(0, -360),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('decision-budget')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Only you see these'), findsOneWidget);
    for (final private in ['340', '400', '230', '300']) {
      expect(find.textContaining(private), findsNothing);
    }
  });

  testWidgets('a yes moves the destination deck along', (tester) async {
    await launch(tester);
    await tester.tap(find.byIcon(Icons.layers_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('preview-basics')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('decision-destination')));
    await tester.tap(find.byKey(const Key('decision-destination')));
    await tester.pumpAndSettle();
    expect(find.text('Costa Lumen'), findsWidgets);
    await tester.tap(find.byKey(const Key('swipe-yes')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Ilha Sereno'), findsWidgets);
  });

  testWidgets('organiser plus one reaches the ticket', (tester) async {
    await launch(tester);
    await tester.tap(find.byIcon(Icons.layers_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('preview-commit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('commit-in')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.textContaining('Organiser + 1 needed'),
      120,
    );
    expect(find.textContaining('Organiser + 1 needed'), findsOneWidget);

    await tester.tap(find.byTooltip('View as someone else'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('viewer-bruno')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('commit-in')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('ticket-screen')), findsOneWidget);
    expect(find.textContaining('Sunny Escape is ON'), findsOneWidget);
    expect(find.textContaining('23 days to go'), findsOneWidget);
  });
}
