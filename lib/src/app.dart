import 'package:flutter/material.dart';

import 'data/journey_repository.dart';
import 'screens/journeys_screen.dart';
import 'state/journey_controller.dart';
import 'theme/journey_theme.dart';

class JourneyScope extends InheritedNotifier<JourneyController> {
  const JourneyScope({
    super.key,
    required JourneyController controller,
    required super.child,
  }) : super(notifier: controller);

  static JourneyController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<JourneyScope>();
    assert(scope != null, 'JourneyScope is missing above this widget.');
    return scope!.notifier!;
  }

  static JourneyController read(BuildContext context) {
    final element = context
        .getElementForInheritedWidgetOfExactType<JourneyScope>();
    final scope = element?.widget as JourneyScope?;
    assert(scope != null, 'JourneyScope is missing above this widget.');
    return scope!.notifier!;
  }
}

class JourneyApp extends StatefulWidget {
  const JourneyApp({super.key, required this.repository, this.clock});

  final JourneyRepository repository;
  final DateTime Function()? clock;

  @override
  State<JourneyApp> createState() => _JourneyAppState();
}

class _JourneyAppState extends State<JourneyApp> {
  late final JourneyController _controller;

  @override
  void initState() {
    super.initState();
    _controller = JourneyController(widget.repository, clock: widget.clock);
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return JourneyScope(
      controller: _controller,
      child: MaterialApp(
        title: 'JourneyGo',
        debugShowCheckedModeBanner: false,
        theme: buildJourneyTheme(),
        themeMode: ThemeMode.light,
        home: const JourneysScreen(),
      ),
    );
  }
}
