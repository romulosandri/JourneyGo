import '../models/planning.dart';

const int travelPerPerson = 22;
const int bufferPerPerson = 18;

class BudgetBand {
  const BudgetBand({
    required this.low,
    required this.high,
    required this.draftFits,
    required this.hasOverlap,
    required this.lowestMax,
  });

  final int low;
  final int high;
  final bool draftFits;
  final bool hasOverlap;
  final int lowestMax;
}

class RankedOption {
  const RankedOption({
    required this.id,
    required this.title,
    required this.score,
    required this.yes,
    this.meta = '',
  });

  final String id;
  final String title;
  final int score;
  final int yes;
  final String meta;
}

class Ranking {
  const Ranking({
    required this.options,
    required this.tie,
    required this.leaderId,
  });

  final List<RankedOption> options;
  final bool tie;
  final String? leaderId;

  RankedOption? get leader {
    final id = leaderId;
    if (id == null) {
      return null;
    }
    for (final option in options) {
      if (option.id == id) {
        return option;
      }
    }
    return null;
  }
}

class DateWindow {
  const DateWindow({
    required this.start,
    required this.end,
    required this.people,
  });

  final DateTime start;
  final DateTime end;
  final int people;
}

class DateResult {
  const DateResult({
    required this.best,
    required this.tied,
    required this.group,
  });

  final DateWindow? best;
  final List<DateWindow> tied;
  final int group;

  bool get isTie => tied.length > 1;
}

class Transfer {
  const Transfer({
    required this.fromId,
    required this.toId,
    required this.amount,
  });

  final String fromId;
  final String toId;
  final int amount;

  String get key => '$fromId>$toId:$amount';
}

BudgetBand? budgetBand(TripSession trip) {
  if (trip.budgets.isEmpty) {
    return null;
  }
  final answers = trip.budgets.values.toList();
  var low = answers.first.comfortable;
  var highComfort = answers.first.comfortable;
  var lowestMax = answers.first.max;
  for (final answer in answers.skip(1)) {
    if (answer.comfortable < low) {
      low = answer.comfortable;
    }
    if (answer.comfortable > highComfort) {
      highComfort = answer.comfortable;
    }
    if (answer.max < lowestMax) {
      lowestMax = answer.max;
    }
  }
  final high = highComfort < lowestMax ? highComfort : lowestMax;
  final overlap = lowestMax >= low;
  return BudgetBand(
    low: low,
    high: overlap ? high : lowestMax,
    draftFits: trip.draftCost <= lowestMax && overlap,
    hasOverlap: overlap,
    lowestMax: lowestMax,
  );
}

int matchThreshold(int joined) {
  if (joined <= 3) {
    return joined.clamp(1, 3);
  }
  return (joined * 2 / 3).ceil();
}

Ranking rankDestinations(TripSession trip) {
  final options = <RankedOption>[
    for (final place in trip.places)
      RankedOption(
        id: place.id,
        title: place.name,
        score: _destinationScore(trip.destinationVotes[place.id]),
        yes: _yesCount(trip.destinationVotes[place.id]),
        meta: '${place.travel} · \$${place.roughPp} pp',
      ),
  ];
  options.sort((a, b) {
    final score = b.score.compareTo(a.score);
    if (score != 0) {
      return score;
    }
    return a.title.compareTo(b.title);
  });
  final anyVote = options.any((option) => option.score > 0);
  if (!anyVote && options.isNotEmpty) {
    return Ranking(
      options: options,
      tie: false,
      leaderId: trip.places.first.id,
    );
  }
  return _withLeader(
    options,
    override: trip.destinationPick,
    tieWhenEqual: true,
  );
}

int _destinationScore(Map<String, Vote>? votes) {
  if (votes == null) {
    return 0;
  }
  var score = 0;
  for (final vote in votes.values) {
    switch (vote) {
      case Vote.yes:
        score += 2;
      case Vote.maybe:
        score += 1;
      case Vote.no:
        score += 0;
    }
  }
  return score;
}

int _yesCount(Map<String, Vote>? votes) {
  if (votes == null) {
    return 0;
  }
  var count = 0;
  for (final vote in votes.values) {
    if (vote == Vote.yes) {
      count += 1;
    }
  }
  return count;
}

Ranking rankActivities(TripSession trip) {
  final options = <RankedOption>[
    for (final activity in trip.activities)
      RankedOption(
        id: activity.id,
        title: activity.title,
        score: _activityScore(trip, activity.id),
        yes: _activityYes(trip, activity.id),
        meta: activity.pricePp == 0
            ? 'Free · ${activity.duration}'
            : '\$${activity.pricePp} pp · ${activity.duration}',
      ),
  ];
  options.sort((a, b) => b.score.compareTo(a.score));
  final any = options.any((option) => option.score > 0);
  if (!any) {
    final seeded = trip.activities.take(3).map((item) => item.id).toSet();
    final ordered = [...options]
      ..sort((a, b) {
        final aSeed = seeded.contains(a.id) ? 0 : 1;
        final bSeed = seeded.contains(b.id) ? 0 : 1;
        return aSeed.compareTo(bSeed);
      });
    return Ranking(
      options: ordered,
      tie: false,
      leaderId: ordered.isEmpty ? null : ordered.first.id,
    );
  }
  if (options.length < 4) {
    return _withLeader(
      options,
      override: trip.activityPick,
      tieWhenEqual: false,
    );
  }
  final third = options[2].score;
  final fourth = options[3].score;
  final tiedForLast = third > 0 && third == fourth;
  if (tiedForLast && trip.activityPick == null) {
    return Ranking(options: options, tie: true, leaderId: null);
  }
  if (tiedForLast && trip.activityPick != null) {
    final picked = trip.activityPick!;
    final next = [...options];
    final index = next.indexWhere((option) => option.id == picked);
    if (index > 2) {
      final swap = next.removeAt(index);
      next.insert(2, swap);
    }
    return Ranking(options: next, tie: false, leaderId: next.first.id);
  }
  return Ranking(options: options, tie: false, leaderId: options.first.id);
}

int _activityScore(TripSession trip, String activityId) {
  final votes = trip.activityVotes[activityId] ?? const {};
  var score = 0;
  for (final entry in votes.entries) {
    if (trip.superLikes[entry.key] == activityId) {
      score += 3;
      continue;
    }
    if (entry.value == Vote.yes) {
      score += 1;
    }
  }
  return score;
}

int _activityYes(TripSession trip, String activityId) {
  final votes = trip.activityVotes[activityId] ?? const {};
  var count = 0;
  for (final entry in votes.entries) {
    if (entry.value == Vote.yes || trip.superLikes[entry.key] == activityId) {
      count += 1;
    }
  }
  return count;
}

List<ActivityOption> anchorActivities(TripSession trip) {
  final ranking = rankActivities(trip);
  if (ranking.tie) {
    return const [];
  }
  final ids = ranking.options.take(3).map((option) => option.id).toList();
  return [
    for (final id in ids)
      for (final activity in trip.activities)
        if (activity.id == id) activity,
  ];
}

List<ActivityOption> maybeActivities(TripSession trip) {
  final anchors = anchorActivities(trip).map((item) => item.id).toSet();
  return [
    for (final activity in trip.activities)
      if (!anchors.contains(activity.id)) activity,
  ];
}

Ranking rankStays(TripSession trip) {
  final band = budgetBand(trip);
  final visible = [
    for (final stay in trip.stays)
      if (_stayInBand(trip, stay, band)) stay,
  ];
  final options = <RankedOption>[
    for (final stay in visible)
      RankedOption(
        id: stay.id,
        title: stay.name,
        score: _stayScore(trip, stay),
        yes: _stayYes(trip, stay.id),
        meta: '\$${stay.pricePp} pp · ★ ${stay.rating.toStringAsFixed(1)}',
      ),
  ];
  options.sort((a, b) {
    final score = b.score.compareTo(a.score);
    if (score != 0) {
      return score;
    }
    final aStay = _stay(trip, a.id);
    final bStay = _stay(trip, b.id);
    return (bStay?.rating ?? 0).compareTo(aStay?.rating ?? 0);
  });
  final any = options.any((option) => option.yes > 0);
  if (!any && options.isNotEmpty) {
    return Ranking(options: options, tie: false, leaderId: options.first.id);
  }
  return _withLeader(options, override: trip.stayPick, tieWhenEqual: true);
}

bool _stayInBand(TripSession trip, StayOption stay, BudgetBand? band) {
  if (band == null || !band.hasOverlap) {
    return !stay.stretch;
  }
  return stayTripTotal(trip, stay) <= band.high || stay.addedBy != null;
}

int _stayScore(TripSession trip, StayOption stay) {
  final yes = _stayYes(trip, stay.id);
  return yes * 10 + (stay.rating * 10).round();
}

int _stayYes(TripSession trip, String stayId) {
  var count = 0;
  for (final vote in trip.stayVotes.entries) {
    if (vote.value == stayId) {
      count += 1;
    }
  }
  return count;
}

StayOption? _stay(TripSession trip, String id) {
  for (final stay in trip.stays) {
    if (stay.id == id) {
      return stay;
    }
  }
  return null;
}

Ranking _withLeader(
  List<RankedOption> options, {
  required String? override,
  required bool tieWhenEqual,
}) {
  if (options.isEmpty) {
    return const Ranking(options: [], tie: false, leaderId: null);
  }
  final top = options.first.score;
  final tied = [
    for (final option in options)
      if (option.score == top) option,
  ];
  final isTie = tieWhenEqual && tied.length > 1 && top > 0;
  if (isTie) {
    if (override != null && tied.any((option) => option.id == override)) {
      return Ranking(options: options, tie: false, leaderId: override);
    }
    return Ranking(options: options, tie: true, leaderId: null);
  }
  return Ranking(options: options, tie: false, leaderId: options.first.id);
}

DateResult bestDates(
  TripSession trip, {
  Set<String>? viewerDraft,
  String? viewerId,
}) {
  final group = trip.joined.length;
  final nights = trip.nights;
  final startRange = DateTime(
    trip.createdAt.year,
    trip.createdAt.month,
    trip.createdAt.day,
  );
  final endRange = DateTime(startRange.year, startRange.month + 3, 0);
  final windows = <DateWindow>[];
  for (
    var day = startRange;
    !day.isAfter(endRange.subtract(Duration(days: nights)));
    day = day.add(const Duration(days: 1))
  ) {
    final people = _peopleForWindow(
      trip,
      day,
      nights,
      viewerDraft: viewerDraft,
      viewerId: viewerId,
    );
    windows.add(
      DateWindow(
        start: day,
        end: day.add(Duration(days: nights)),
        people: people,
      ),
    );
  }
  if (windows.isEmpty) {
    return DateResult(
      best: DateWindow(start: trip.start, end: trip.end, people: 0),
      tied: const [],
      group: group,
    );
  }
  var maxPeople = 0;
  for (final window in windows) {
    if (window.people > maxPeople) {
      maxPeople = window.people;
    }
  }
  if (maxPeople == 0) {
    final fallback = DateWindow(start: trip.start, end: trip.end, people: 0);
    return DateResult(best: fallback, tied: const [], group: group);
  }
  var leaders = [
    for (final window in windows)
      if (window.people == maxPeople) window,
  ];
  // Sliding windows tie with themselves. Prefer Friday departures when a
  // Friday is already among the best overlaps.
  final fridays = [
    for (final window in leaders)
      if (window.start.weekday == DateTime.friday) window,
  ];
  if (fridays.isNotEmpty) {
    leaders = fridays;
  }
  if (trip.datePick != null) {
    for (final window in leaders) {
      if (_sameDay(window.start, trip.datePick!)) {
        return DateResult(best: window, tied: const [], group: group);
      }
    }
  }
  if (leaders.length > 1) {
    return DateResult(best: null, tied: leaders.take(2).toList(), group: group);
  }
  return DateResult(best: leaders.first, tied: const [], group: group);
}

int _peopleForWindow(
  TripSession trip,
  DateTime start,
  int nights, {
  Set<String>? viewerDraft,
  String? viewerId,
}) {
  var people = 0;
  for (final member in trip.joined) {
    final days = member.id == viewerId && viewerDraft != null
        ? viewerDraft
        : (trip.availability[member.id] ?? const <String>{});
    final flexible = trip.flexibleDates.contains(member.id);
    if (flexible &&
        start.weekday == DateTime.friday &&
        _sameDay(start, trip.start)) {
      people += 1;
      continue;
    }
    var covered = true;
    for (var offset = 0; offset < nights; offset += 1) {
      final day = start.add(Duration(days: offset));
      if (!days.contains(dayKey(day))) {
        covered = false;
        break;
      }
    }
    if (covered) {
      people += 1;
    }
  }
  return people;
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String dayKey(DateTime day) {
  final month = day.month.toString().padLeft(2, '0');
  final date = day.day.toString().padLeft(2, '0');
  return '${day.year}-$month-$date';
}

DateTime? parseDayKey(String key) {
  final parts = key.split('-');
  if (parts.length != 3) {
    return null;
  }
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) {
    return null;
  }
  return DateTime(year, month, day);
}

int paintedCount(
  TripSession trip,
  String key, {
  Set<String>? viewerDraft,
  String? viewerId,
}) {
  var count = 0;
  for (final member in trip.joined) {
    final days = member.id == viewerId && viewerDraft != null
        ? viewerDraft
        : (trip.availability[member.id] ?? const <String>{});
    if (days.contains(key)) {
      count += 1;
    }
  }
  return count;
}

int activityCeiling(TripSession trip) {
  final band = budgetBand(trip);
  if (band == null || !band.hasOverlap) {
    return trip.draftCost;
  }
  var cheapest = trip.stays.first.pricePp;
  for (final stay in trip.stays) {
    if (stay.addedBy != null) {
      continue;
    }
    if (stay.pricePp < cheapest) {
      cheapest = stay.pricePp;
    }
  }
  final ceiling = band.high - cheapest - travelPerPerson - bufferPerPerson;
  return ceiling < 0 ? 0 : ceiling;
}

int stayTripTotal(TripSession trip, StayOption stay) {
  return stay.pricePp +
      _activityBundle(trip) +
      travelPerPerson +
      bufferPerPerson;
}

int _activityBundle(TripSession trip) {
  final anchors = anchorActivities(trip);
  if (anchors.length >= 2 && !rankActivities(trip).tie) {
    var sum = 0;
    for (final activity in anchors) {
      sum += activity.pricePp;
    }
    return sum;
  }
  var sum = 0;
  var count = 0;
  for (final activity in trip.activities) {
    if (activity.addedBy != null) {
      continue;
    }
    sum += activity.pricePp;
    count += 1;
    if (count == 3) {
      break;
    }
  }
  return sum;
}

int sharedEstimate(TripSession trip) {
  final stay = chosenStay(trip);
  final stayPrice = stay?.pricePp ?? trip.stays.first.pricePp;
  return stayPrice + _activityBundle(trip) + travelPerPerson + bufferPerPerson;
}

int personalEstimate(TripSession trip, String memberId) {
  final stay = chosenStay(trip);
  final stayPrice = stay?.pricePp ?? trip.stays.first.pricePp;
  final skipped = trip.skippedActivities[memberId] ?? const <String>{};
  final anchors = anchorActivities(trip);
  var activities = 0;
  if (anchors.length >= 2 && !rankActivities(trip).tie) {
    for (final activity in anchors) {
      if (!skipped.contains(activity.id)) {
        activities += activity.pricePp;
      }
    }
  } else {
    activities = _activityBundle(trip);
  }
  return stayPrice + activities + travelPerPerson + bufferPerPerson;
}

List<StayOption> visibleStays(TripSession trip) {
  final band = budgetBand(trip);
  return [
    for (final stay in trip.stays)
      if (_stayInBand(trip, stay, band)) stay,
  ];
}

StayOption? chosenStay(TripSession trip) {
  final ranking = rankStays(trip);
  final id = ranking.leaderId;
  if (id == null) {
    return null;
  }
  return _stay(trip, id);
}

bool viewerFinished(TripSession trip, DecisionKind kind) {
  final viewer = trip.viewerId;
  if (viewer == null) {
    return false;
  }
  return memberFinished(trip, viewer, kind);
}

bool memberFinished(TripSession trip, String memberId, DecisionKind kind) {
  switch (kind) {
    case DecisionKind.destination:
      return trip.finishedDecks[SwipeMode.destination]?.contains(memberId) ??
          false;
    case DecisionKind.dates:
      return trip.flexibleDates.contains(memberId) ||
          (trip.availability[memberId]?.isNotEmpty ?? false);
    case DecisionKind.budget:
      return trip.budgets.containsKey(memberId);
    case DecisionKind.activities:
      return trip.finishedDecks[SwipeMode.activities]?.contains(memberId) ??
          false;
    case DecisionKind.stay:
      return trip.stayVotes.containsKey(memberId);
  }
}

int waitingCount(TripSession trip, DecisionKind kind) {
  var waiting = 0;
  for (final member in trip.joined) {
    final done = memberFinished(trip, member.id, kind);
    if (!done && !trip.optOutReasons.containsKey(member.id)) {
      waiting += 1;
    }
  }
  return waiting;
}

List<ActivityOption> activityDeck(TripSession trip) {
  final ceiling = activityCeiling(trip);
  final affordable = <ActivityOption>[];
  final stretch = <ActivityOption>[];
  for (final activity in trip.activities) {
    final over = activity.pricePp > ceiling && activity.pricePp > 0;
    if (over && activity.addedBy == null) {
      continue;
    }
    if (over || activity.stretch) {
      stretch.add(activity);
    } else {
      affordable.add(activity);
    }
  }
  if (affordable.isEmpty) {
    final starters = [
      for (final activity in trip.activities)
        if (activity.addedBy == null && activity.pricePp <= 20) activity,
    ];
    if (starters.isNotEmpty) {
      return starters.take(3).toList();
    }
  }
  return [...affordable, ...stretch];
}

String waitingLabel(int count) {
  if (count <= 0) {
    return 'Everyone has weighed in';
  }
  if (count == 1) {
    return 'Waiting on 1 person';
  }
  return 'Waiting on $count people';
}

bool decisionActive(TripSession trip, DecisionKind kind) {
  if (trip.locked.contains(kind)) {
    return false;
  }
  switch (kind) {
    case DecisionKind.destination:
    case DecisionKind.dates:
    case DecisionKind.budget:
      return true;
    case DecisionKind.activities:
    case DecisionKind.stay:
      return basicsLocked(trip);
  }
}

bool basicsLocked(TripSession trip) {
  return trip.locked.contains(DecisionKind.destination) &&
      trip.locked.contains(DecisionKind.dates) &&
      trip.locked.contains(DecisionKind.budget);
}

bool plansLocked(TripSession trip) {
  return basicsLocked(trip) &&
      trip.locked.contains(DecisionKind.activities) &&
      trip.locked.contains(DecisionKind.stay);
}

bool commitOpen(TripSession trip) => plansLocked(trip);

bool isConfirmed(TripSession trip) {
  if (!plansLocked(trip)) {
    return false;
  }
  if (anchorActivities(trip).length < 2) {
    return false;
  }
  if (chosenStay(trip) == null) {
    return false;
  }
  final organiserIn = trip.committed.contains(trip.organiser.id);
  final others = trip.committed.where((id) => id != trip.organiser.id).length;
  return organiserIn && others >= 1;
}

int lockedCount(TripSession trip) => trip.locked.length;

DecisionPhase phaseOf(TripSession trip, DecisionKind kind, DateTime now) {
  if (trip.locked.contains(kind)) {
    return DecisionPhase.locked;
  }
  final deadline = deadlineFor(trip, kind);
  if (!deadline.isAfter(now.add(const Duration(hours: 2)))) {
    return DecisionPhase.closing;
  }
  return DecisionPhase.open;
}

DateTime deadlineFor(TripSession trip, DecisionKind kind) {
  switch (kind) {
    case DecisionKind.destination:
    case DecisionKind.dates:
    case DecisionKind.budget:
      return trip.basicsDeadline;
    case DecisionKind.activities:
    case DecisionKind.stay:
      return trip.plansDeadline ?? trip.basicsDeadline;
  }
}

String? lockBlockReason(TripSession trip, DecisionKind kind) {
  if ((trip.reminders[kind] ?? 0) < 1) {
    return 'A reminder goes out before this can lock.';
  }
  if (!trip.halfOpened) {
    return 'Waiting for at least ${trip.halfRequired} people to open the trip before locking';
  }
  return null;
}

bool needsTie(TripSession trip, DecisionKind kind) {
  switch (kind) {
    case DecisionKind.destination:
      return rankDestinations(trip).tie;
    case DecisionKind.dates:
      return bestDates(trip).isTie;
    case DecisionKind.budget:
      return false;
    case DecisionKind.activities:
      return rankActivities(trip).tie;
    case DecisionKind.stay:
      return rankStays(trip).tie;
  }
}

List<Transfer> transfersFor(TripSession trip, {required bool simplified}) {
  final members = [
    for (final member in trip.joined)
      if (!trip.optOutReasons.containsKey(member.id)) member.id,
  ];
  if (members.isEmpty) {
    return const [];
  }
  final net = <String, int>{for (final id in members) id: 0};
  for (final cost in trip.costs) {
    final shares = _shares(cost.amount, members.length);
    for (var index = 0; index < members.length; index += 1) {
      final id = members[index];
      net[id] = (net[id] ?? 0) - shares[index];
      if (id == cost.payerId) {
        net[id] = (net[id] ?? 0) + cost.amount;
      }
    }
  }
  for (final settlement in trip.settlements) {
    net[settlement.fromId] = (net[settlement.fromId] ?? 0) + settlement.amount;
    net[settlement.toId] = (net[settlement.toId] ?? 0) - settlement.amount;
  }
  if (!simplified) {
    return _pairwise(trip, members);
  }
  return _simplify(net);
}

List<int> _shares(int amount, int count) {
  if (count <= 0) {
    return const [];
  }
  final base = amount ~/ count;
  final extra = amount % count;
  return [
    for (var index = 0; index < count; index += 1)
      base + (index < extra ? 1 : 0),
  ];
}

List<Transfer> _pairwise(TripSession trip, List<String> members) {
  final transfers = <Transfer>[];
  for (final cost in trip.costs) {
    final shares = _shares(cost.amount, members.length);
    for (var index = 0; index < members.length; index += 1) {
      final id = members[index];
      if (id == cost.payerId || shares[index] == 0) {
        continue;
      }
      transfers.add(
        Transfer(fromId: id, toId: cost.payerId, amount: shares[index]),
      );
    }
  }
  return transfers;
}

List<Transfer> _simplify(Map<String, int> net) {
  final debtors = <String, int>{};
  final creditors = <String, int>{};
  for (final entry in net.entries) {
    if (entry.value < 0) {
      debtors[entry.key] = -entry.value;
    } else if (entry.value > 0) {
      creditors[entry.key] = entry.value;
    }
  }
  final debtorIds = debtors.keys.toList()
    ..sort((a, b) => debtors[b]!.compareTo(debtors[a]!));
  final creditorIds = creditors.keys.toList()
    ..sort((a, b) => creditors[b]!.compareTo(creditors[a]!));
  final result = <Transfer>[];
  var debtorIndex = 0;
  var creditorIndex = 0;
  while (debtorIndex < debtorIds.length && creditorIndex < creditorIds.length) {
    final debtor = debtorIds[debtorIndex];
    final creditor = creditorIds[creditorIndex];
    final pay = debtors[debtor]! < creditors[creditor]!
        ? debtors[debtor]!
        : creditors[creditor]!;
    if (pay > 0) {
      result.add(Transfer(fromId: debtor, toId: creditor, amount: pay));
    }
    debtors[debtor] = debtors[debtor]! - pay;
    creditors[creditor] = creditors[creditor]! - pay;
    if (debtors[debtor] == 0) {
      debtorIndex += 1;
    }
    if (creditors[creditor] == 0) {
      creditorIndex += 1;
    }
  }
  return result;
}

int loggedTotal(TripSession trip) {
  var sum = 0;
  for (final cost in trip.costs) {
    sum += cost.amount;
  }
  return sum;
}

String defaultLine(TripSession trip, DecisionKind kind) {
  switch (kind) {
    case DecisionKind.destination:
      final leader = rankDestinations(trip).leader;
      final name = leader?.title ?? trip.places.first.name;
      return 'If no one objects, we\'ll go with $name.';
    case DecisionKind.dates:
      final dates = bestDates(trip);
      final window = dates.best;
      if (window == null) {
        return 'If no one objects, Ana picks between the closest windows.';
      }
      return 'If no one objects: ${_shortRange(window.start, window.end)}.';
    case DecisionKind.budget:
      return 'Default: ~\$${trip.draftCost} if it fits everyone.';
    case DecisionKind.activities:
      return 'Default: top 3 by score.';
    case DecisionKind.stay:
      final stay = chosenStay(trip);
      return 'Default: ${stay?.name ?? 'the highest rated stay in your budget'}.';
  }
}

String _shortRange(DateTime start, DateTime end) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  if (start.month == end.month) {
    return '${months[start.month - 1]} ${start.day}–${end.day}';
  }
  return '${months[start.month - 1]} ${start.day} – ${months[end.month - 1]} ${end.day}';
}

String leadingLabel(TripSession trip, DecisionKind kind) {
  switch (kind) {
    case DecisionKind.destination:
      final ranking = rankDestinations(trip);
      if (ranking.tie) {
        return 'Tie between the top 2';
      }
      return 'Leading: ${ranking.leader?.title ?? trip.places.first.name}';
    case DecisionKind.dates:
      final dates = bestDates(trip);
      if (dates.isTie) {
        return 'Two windows are level';
      }
      final window = dates.best;
      if (window == null) {
        return 'Default: best overlap';
      }
      return 'Leading: ${_shortRange(window.start, window.end)}';
    case DecisionKind.budget:
      final band = budgetBand(trip);
      if (band == null) {
        return 'Default: ~\$${trip.draftCost}';
      }
      return 'Comfortable: \$${band.low}–\$${band.high}';
    case DecisionKind.activities:
      final anchors = anchorActivities(trip);
      if (anchors.isEmpty) {
        return 'Default: top 3 by score';
      }
      return 'Leading: ${anchors.first.title}';
    case DecisionKind.stay:
      final ranking = rankStays(trip);
      if (ranking.tie) {
        return 'Tie between the top 2';
      }
      return 'Leading: ${ranking.leader?.title ?? 'a shortlisted stay'}';
  }
}
