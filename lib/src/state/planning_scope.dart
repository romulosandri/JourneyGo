import 'package:flutter/widgets.dart';

import 'planning_controller.dart';

class PlanningScope extends InheritedNotifier<PlanningController> {
  const PlanningScope({
    super.key,
    required PlanningController controller,
    required super.child,
  }) : super(notifier: controller);

  static PlanningController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<PlanningScope>();
    assert(scope != null, 'PlanningScope is missing above this widget.');
    return scope!.notifier!;
  }

  static PlanningController read(BuildContext context) {
    final element = context
        .getElementForInheritedWidgetOfExactType<PlanningScope>();
    final scope = element?.widget as PlanningScope?;
    assert(scope != null, 'PlanningScope is missing above this widget.');
    return scope!.notifier!;
  }
}
