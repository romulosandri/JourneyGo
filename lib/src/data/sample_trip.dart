import '../logic/planning_rules.dart';
import '../models/planning.dart';
import 'catalog.dart';

TripSession buildDraft({
  required Vibe vibe,
  required Timing timing,
  required PartySize party,
  required bool knowWhere,
  required DateTime now,
}) {
  final places = suggestionsFor(vibe);
  final chosen = knowWhere ? places.take(1).toList() : places;
  final start = weekendFor(timing, now);
  final ana = freshMember('ana')..opened = true;
  return TripSession(
    id: 'draft-${now.millisecondsSinceEpoch}',
    name: tripNameFor(vibe),
    code: _digits(now),
    slug: _slug(tripNameFor(vibe), now),
    vibe: vibe,
    timing: timing,
    party: party,
    places: chosen,
    activities: freshActivities(),
    stays: freshStays(),
    start: start,
    end: start.add(const Duration(days: 3)),
    draftCost: chosen.first.roughPp,
    windowHours: 24,
    createdAt: now,
    basicsDeadline: now.add(const Duration(hours: 24)),
    members: [ana],
    viewerId: ana.id,
  );
}

TripSession buildPreview(PreviewKind kind, DateTime now) {
  final trip = _sunny(now);
  switch (kind) {
    case PreviewKind.basics:
      return trip;
    case PreviewKind.landing:
      trip.viewerId = null;
      final leo = trip.member('leo');
      if (leo != null) {
        leo.seat = Seat.saved;
        leo.opened = false;
      }
      return trip;
    case PreviewKind.expired:
      trip.viewerId = null;
      trip.inviteExpired = true;
      return trip;
    case PreviewKind.tie:
      _applyTie(trip);
      return trip;
    case PreviewKind.belowPlan:
      trip.budgets['mari'] = const BudgetAnswer(comfortable: 160, max: 180);
      return trip;
    case PreviewKind.plans:
      _lockBasics(trip, now);
      _seedPlans(trip, now);
      return trip;
    case PreviewKind.commit:
      _lockBasics(trip, now);
      _seedPlans(trip, now);
      _lockPlans(trip, now);
      return trip;
    case PreviewKind.confirmed:
      _lockBasics(trip, now);
      _seedPlans(trip, now);
      _lockPlans(trip, now);
      trip.committed.addAll(['ana', 'bruno', 'caio', 'duda']);
      trip.costs.add(
        CostEntry(
          id: 'deposit',
          title: 'Casa Brisa deposit',
          amount: 200,
          payerId: 'bruno',
          addedById: 'bruno',
          addedAt: now.subtract(const Duration(hours: 2)),
        ),
      );
      trip.costs.add(
        CostEntry(
          id: 'tickets',
          title: 'Catamaran tickets',
          amount: 90,
          payerId: 'ana',
          addedById: 'ana',
          addedAt: now.subtract(const Duration(hours: 1)),
        ),
      );
      return trip;
    case PreviewKind.objection:
      trip.locked.add(DecisionKind.destination);
      trip.lockedAt[DecisionKind.destination] = now;
      trip.objections[DecisionKind.destination] = ObjectionState(
        memberId: 'duda',
        reason: 'Ilha Sereno fits the weekend better.',
      );
      return trip;
  }
}

TripSession _sunny(DateTime now) {
  final start = _sampleWeekend(now);
  final nights = [
    for (var offset = 0; offset < 3; offset += 1)
      dayKey(start.add(Duration(days: offset))),
  ];
  final later = [
    for (var offset = 0; offset < 3; offset += 1)
      dayKey(start.add(Duration(days: 7 + offset))),
  ];
  final members = freshCrew();
  for (final member in members) {
    member.opened = member.id != 'leo';
  }
  final trip = TripSession(
    id: 'sunny',
    name: 'Sunny Escape',
    code: '482913',
    slug: 'sunny-42',
    vibe: Vibe.beach,
    timing: Timing.nextMonth,
    party: PartySize.medium,
    places: [
      placeSeed('costa')!.build(),
      placeSeed('ilha')!.build(),
      placeSeed('vale')!.build(),
    ],
    activities: freshActivities(),
    stays: freshStays(),
    start: start,
    end: start.add(const Duration(days: 3)),
    draftCost: 240,
    windowHours: 24,
    createdAt: now,
    basicsDeadline: thursdayEvening(now),
    members: members,
    viewerId: 'ana',
    reminders: {for (final kind in DecisionKind.values) kind: 1},
  );
  _dest(trip, 'bruno', 'costa', Vote.yes);
  _dest(trip, 'bruno', 'ilha', Vote.maybe);
  _dest(trip, 'bruno', 'vale', Vote.no);
  _dest(trip, 'caio', 'costa', Vote.yes);
  _dest(trip, 'caio', 'ilha', Vote.yes);
  _dest(trip, 'caio', 'vale', Vote.maybe);
  _dest(trip, 'duda', 'costa', Vote.yes);
  _dest(trip, 'duda', 'ilha', Vote.no);
  _dest(trip, 'duda', 'vale', Vote.yes);
  trip.finishedDecks[SwipeMode.destination] = {'bruno', 'caio', 'duda'};
  for (final id in ['ana', 'bruno', 'caio', 'duda', 'mari']) {
    trip.availability[id] = {...nights};
  }
  for (final id in ['bruno', 'caio', 'duda', 'mari']) {
    trip.availability[id] = {...trip.availability[id]!, ...later};
  }
  trip.budgets['ana'] = const BudgetAnswer(comfortable: 240, max: 340);
  trip.budgets['bruno'] = const BudgetAnswer(comfortable: 260, max: 400);
  trip.budgets['caio'] = const BudgetAnswer(comfortable: 200, max: 300);
  trip.budgets['duda'] = const BudgetAnswer(comfortable: 230, max: 320);
  return trip;
}

void _seedPlans(TripSession trip, DateTime now) {
  trip.plansDeadline = now.add(const Duration(hours: 24));
  void yes(String member, String activity) {
    trip.activityVotes.putIfAbsent(activity, () => {})[member] = Vote.yes;
  }

  for (final member in ['bruno', 'caio', 'duda', 'mari']) {
    yes(member, 'market');
  }
  for (final member in ['bruno', 'caio', 'duda']) {
    yes(member, 'lighthouse');
    yes(member, 'catamaran');
  }
  yes('bruno', 'beach');
  yes('duda', 'tour');
  trip.finishedDecks[SwipeMode.activities] = {'bruno', 'caio', 'duda', 'mari'};
  for (final member in ['bruno', 'caio', 'duda']) {
    trip.stayVotes[member] = 'brisa';
  }
}

void _lockBasics(TripSession trip, DateTime now) {
  for (final kind in [
    DecisionKind.destination,
    DecisionKind.dates,
    DecisionKind.budget,
  ]) {
    trip.locked.add(kind);
    trip.lockedAt[kind] = now;
  }
}

void _lockPlans(TripSession trip, DateTime now) {
  for (final kind in [DecisionKind.activities, DecisionKind.stay]) {
    trip.locked.add(kind);
    trip.lockedAt[kind] = now;
  }
  trip.commitDeadline = now.add(const Duration(hours: 48));
}

void _applyTie(TripSession trip) {
  trip.destinationVotes.clear();
  trip.finishedDecks[SwipeMode.destination] = {'bruno', 'caio', 'duda', 'mari'};
  _dest(trip, 'bruno', 'costa', Vote.yes);
  _dest(trip, 'caio', 'costa', Vote.yes);
  _dest(trip, 'duda', 'ilha', Vote.yes);
  _dest(trip, 'mari', 'ilha', Vote.yes);
}

void _dest(TripSession trip, String member, String place, Vote vote) {
  trip.destinationVotes.putIfAbsent(place, () => {})[member] = vote;
}

DateTime _sampleWeekend(DateTime now) {
  final target = DateTime(now.year, 11, 13);
  if (target.isAfter(now) && target.weekday == DateTime.friday) {
    return target;
  }
  return weekendFor(Timing.flexible, now);
}

String _digits(DateTime now) {
  final value = (now.millisecondsSinceEpoch % 900000) + 100000;
  return value.toString();
}

String _slug(String name, DateTime now) {
  final base = name
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  final suffix = (now.second % 90) + 10;
  return '$base-$suffix';
}
