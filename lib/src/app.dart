import 'package:flutter/material.dart';

import 'routes.dart';
import 'screens/budget_screen.dart';
import 'screens/commit_screen.dart';
import 'screens/cost_log_screen.dart';
import 'screens/dates_screen.dart';
import 'screens/draft_screen.dart';
import 'screens/hub_screen.dart';
import 'screens/invite_screen.dart';
import 'screens/landing_screen.dart';
import 'screens/results_screen.dart';
import 'screens/spark_screen.dart';
import 'screens/stay_screen.dart';
import 'screens/swipe_screen.dart';
import 'screens/ticket_screen.dart';
import 'state/planning_controller.dart';
import 'state/planning_scope.dart';
import 'theme/journey_theme.dart';
import 'widgets/playground_bar.dart';
import 'models/planning.dart';

class JourneyApp extends StatefulWidget {
  const JourneyApp({super.key, this.clock, this.generateDelay});

  final DateTime Function()? clock;
  final Duration? generateDelay;

  @override
  State<JourneyApp> createState() => _JourneyAppState();
}

class _JourneyAppState extends State<JourneyApp> {
  late final PlanningController _controller;
  final GlobalKey<ScaffoldMessengerState> _messenger =
      GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    _controller = PlanningController(
      clock: widget.clock,
      generateDelay: widget.generateDelay ?? const Duration(milliseconds: 700),
    );
    _controller.addListener(_onToast);
  }

  @override
  void dispose() {
    _controller.removeListener(_onToast);
    _controller.dispose();
    super.dispose();
  }

  void _onToast() {
    final message = _controller.takeToast();
    if (message == null || message.isEmpty) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final messenger = _messenger.currentState;
      if (messenger == null) {
        return;
      }
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    });
  }

  @override
  Widget build(BuildContext context) {
    return PlanningScope(
      controller: _controller,
      child: MaterialApp(
        title: 'JourneyGo',
        debugShowCheckedModeBanner: false,
        theme: buildJourneyTheme(),
        themeMode: ThemeMode.light,
        scaffoldMessengerKey: _messenger,
        home: PlaygroundShell(navigatorKey: _controller.navigator),
      ),
    );
  }
}

class PlaygroundShell extends StatelessWidget {
  const PlaygroundShell({super.key, required this.navigatorKey});

  final GlobalKey<NavigatorState> navigatorKey;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFE7E0D4),
      child: Column(
        children: [
          const PlaygroundBar(),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Navigator(
                  key: navigatorKey,
                  initialRoute: AppRoutes.spark,
                  onGenerateRoute: _route,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Route<void> _route(RouteSettings settings) {
  return MaterialPageRoute<void>(
    settings: settings,
    builder: (context) => _screen(settings),
  );
}

Widget _screen(RouteSettings settings) {
  switch (settings.name) {
    case AppRoutes.spark:
      return const SparkScreen();
    case AppRoutes.draft:
      return const DraftScreen();
    case AppRoutes.invite:
      return const InviteScreen();
    case AppRoutes.landing:
      return const LandingScreen();
    case AppRoutes.hub:
      return const HubScreen();
    case AppRoutes.dates:
      return const DatesScreen();
    case AppRoutes.budget:
      return const BudgetScreen();
    case AppRoutes.swipe:
      return SwipeScreen(mode: _swipeMode(settings.arguments));
    case AppRoutes.results:
      return ResultsScreen(kind: _decisionKind(settings.arguments));
    case AppRoutes.stay:
      return const StayScreen();
    case AppRoutes.commit:
      return const CommitScreen();
    case AppRoutes.ticket:
      return const TicketScreen();
    case AppRoutes.costs:
      return const CostLogScreen();
    default:
      return const SparkScreen();
  }
}

SwipeMode _swipeMode(Object? arguments) {
  if (arguments is SwipeMode) {
    return arguments;
  }
  return SwipeMode.destination;
}

DecisionKind _decisionKind(Object? arguments) {
  if (arguments is DecisionKind) {
    return arguments;
  }
  return DecisionKind.destination;
}
