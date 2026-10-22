import 'package:flutter/widgets.dart';

import '../data/catalog.dart';
import '../data/sample_trip.dart';
import '../format.dart';
import '../logic/planning_rules.dart';
import '../models/planning.dart';
import '../routes.dart';

class _SwipeUndo {
  _SwipeUndo({
    required this.mode,
    required this.cardId,
    required this.previous,
    required this.hadPrevious,
    required this.previousSuper,
  });

  final SwipeMode mode;
  final String cardId;
  final Vote? previous;
  final bool hadPrevious;
  final String? previousSuper;
}

class PlanningController extends ChangeNotifier {
  PlanningController({
    DateTime Function()? clock,
    this.generateDelay = const Duration(milliseconds: 700),
  }) : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
  final Duration generateDelay;

  final GlobalKey<NavigatorState> navigator = GlobalKey<NavigatorState>();

  TripSession? trip;
  Vibe? vibe;
  Timing timing = Timing.nextMonth;
  PartySize? party;
  bool generating = false;
  bool openPlaceSearch = false;
  bool offline = false;
  bool simplifyPayments = true;

  int _token = 0;
  String? _toast;
  _SwipeUndo? _undo;

  DateTime get now => _clock();

  String? takeToast() {
    final message = _toast;
    _toast = null;
    return message;
  }

  void selectVibe(Vibe value) {
    vibe = value;
    notifyListeners();
  }

  void selectTiming(Timing value) {
    timing = value;
    notifyListeners();
  }

  void selectParty(PartySize value) {
    party = party == value ? null : value;
    notifyListeners();
  }

  void requestDraft({required bool knowWhere}) {
    if (vibe == null) {
      _say('Pick a vibe and we\'ll draft the rest.');
      return;
    }
    final token = ++_token;
    generating = true;
    openPlaceSearch = false;
    trip = null;
    notifyListeners();
    Future<void>.delayed(generateDelay, () {
      if (token != _token) {
        return;
      }
      trip = buildDraft(
        vibe: vibe!,
        timing: timing,
        party: party ?? PartySize.medium,
        knowWhere: knowWhere,
        now: now,
      );
      generating = false;
      openPlaceSearch = knowWhere;
      notifyListeners();
    });
  }

  void startOver() {
    _token += 1;
    trip = null;
    generating = false;
    vibe = null;
    party = null;
    timing = Timing.nextMonth;
    openPlaceSearch = false;
    notifyListeners();
    _home(AppRoutes.spark);
  }

  bool takePlaceSearch() {
    final open = openPlaceSearch;
    openPlaceSearch = false;
    return open;
  }

  void openPreview(PreviewKind kind) {
    _token += 1;
    generating = false;
    trip = buildPreview(kind, now);
    notifyListeners();
    switch (kind) {
      case PreviewKind.landing:
      case PreviewKind.expired:
        _home(AppRoutes.landing);
      case PreviewKind.tie:
      case PreviewKind.objection:
        _home(AppRoutes.results, DecisionKind.destination);
      case PreviewKind.belowPlan:
        _home(AppRoutes.budget);
      case PreviewKind.commit:
        _home(AppRoutes.commit);
      case PreviewKind.confirmed:
        _home(AppRoutes.ticket);
      case PreviewKind.basics:
      case PreviewKind.plans:
        _home(AppRoutes.hub);
    }
  }

  void setViewer(String id) {
    final current = trip;
    final person = current?.member(id);
    if (current == null || person == null || !person.joined) {
      return;
    }
    current.viewerId = id;
    notifyListeners();
  }

  void markViewerOpened() {
    final person = trip?.viewer;
    if (person == null || person.opened) {
      return;
    }
    person.opened = true;
    notifyListeners();
  }

  void setOffline(bool value) {
    final pending = trip?.pendingSync ?? false;
    offline = value;
    if (!value && pending) {
      trip?.pendingSync = false;
      _say('All synced');
      return;
    }
    notifyListeners();
  }

  void rename(String value) {
    final current = trip;
    final next = value.trim();
    if (current == null || next.isEmpty) {
      return;
    }
    current.name = next;
    current.edited = true;
    _touch();
    notifyListeners();
  }

  void removePlace(String id) {
    final current = trip;
    if (current == null) {
      return;
    }
    if (current.places.length <= 1) {
      _say('Keep at least one place in the draft.');
      return;
    }
    current.places.removeWhere((place) => place.id == id);
    current.destinationVotes.remove(id);
    current.draftCost = current.places.first.roughPp;
    current.edited = true;
    _touch();
    notifyListeners();
  }

  void addCatalogPlace(String id, {required bool extra}) {
    final seed = placeSeed(id);
    if (seed == null) {
      return;
    }
    addPlace(seed.build(), extra: extra);
  }

  void addPlace(PlaceOption place, {required bool extra}) {
    final current = trip;
    if (current == null) {
      return;
    }
    if (current.places.any((item) => item.id == place.id)) {
      _say('That place is already in the trip.');
      return;
    }
    if (extra) {
      final extras = current.places.where((item) => item.extra).length;
      if (extras >= 2) {
        _say('Max 2 extra places, so the choice stays small.');
        return;
      }
      current.places.add(
        PlaceOption(
          id: place.id,
          name: place.name,
          travel: place.travel,
          hours: place.hours,
          roughPp: place.roughPp,
          nightly: place.nightly,
          blurb: place.blurb,
          routeNote: place.routeNote,
          vibe: place.vibe,
          extra: true,
          addedBy: current.viewerId,
        ),
      );
      current.finishedDecks[SwipeMode.destination]?.clear();
    } else {
      if (current.places.length >= 3) {
        _say('The draft holds 3 places.');
        return;
      }
      current.places.add(place);
      current.edited = true;
      current.draftCost = current.places.first.roughPp;
    }
    _touch();
    notifyListeners();
  }

  void setWeekend(DateTime start, int nights) {
    final current = trip;
    if (current == null) {
      return;
    }
    final day = DateTime(start.year, start.month, start.day);
    current.start = day;
    current.end = day.add(Duration(days: nights.clamp(2, 4)));
    current.edited = true;
    _touch();
    notifyListeners();
  }

  void setWindow(int hours) {
    final current = trip;
    if (current == null) {
      return;
    }
    current.windowHours = hours;
    current.basicsDeadline = now.add(Duration(hours: hours));
    current.edited = true;
    _say('Deadlines set to ${hours}h from now.');
  }

  void addSavedFriend(String id) {
    final current = trip;
    if (current == null || current.member(id) != null) {
      return;
    }
    final person = freshMember(id)..seat = Seat.saved;
    current.members.add(person);
    _touch();
    notifyListeners();
  }

  void addNamedSeat(String name) {
    final current = trip;
    final clean = name.trim();
    if (current == null || clean.isEmpty) {
      return;
    }
    final id =
        'seat-${clean.toLowerCase().replaceAll(RegExp(r'[^a-z]+'), '')}-${current.members.length}';
    current.members.add(
      Member(
        id: id,
        name: _title(clean),
        role: MemberRole.yesPerson,
        seat: Seat.saved,
      ),
    );
    _touch();
    notifyListeners();
  }

  String? joinWithName(String name) {
    final current = trip;
    if (current == null) {
      return 'Start a trip first.';
    }
    if (current.inviteExpired) {
      return 'This invite has expired. Ask ${current.organiser.name} for a new pass.';
    }
    final clean = name.trim();
    if (clean.isEmpty) {
      return 'Add your first name.';
    }
    Member? saved;
    for (final member in current.members) {
      if (member.seat == Seat.saved &&
          member.name.toLowerCase() == clean.toLowerCase()) {
        saved = member;
        break;
      }
    }
    if (saved != null) {
      saved.seat = Seat.joined;
      saved.opened = true;
      current.viewerId = saved.id;
    } else {
      final id =
          'guest-${clean.toLowerCase().replaceAll(RegExp(r'[^a-z]+'), '')}-${current.members.length}';
      final person = Member(
        id: id,
        name: _title(clean),
        role: MemberRole.yesPerson,
        opened: true,
      );
      current.members.add(person);
      current.viewerId = id;
    }
    _touch();
    notifyListeners();
    return null;
  }

  bool codeMatches(String digits) {
    final code = trip?.code ?? '';
    return digits.replaceAll(RegExp(r'\s'), '') == code;
  }

  bool saveDates(Set<String> days) {
    final current = trip;
    final id = current?.viewerId;
    if (current == null || id == null) {
      return false;
    }
    if (days.isEmpty) {
      _say('Paint a few days first, or tap Any weekend works.');
      return false;
    }
    current.availability[id] = {...days};
    current.flexibleDates.remove(id);
    _touch();
    if (offline) {
      _say('Saved on this phone.');
    } else {
      notifyListeners();
    }
    return true;
  }

  void acceptAnyWeekend() {
    final current = trip;
    final id = current?.viewerId;
    if (current == null || id == null) {
      return;
    }
    current.flexibleDates.add(id);
    current.availability[id] = {
      for (var offset = 0; offset < current.nights; offset += 1)
        dayKey(current.start.add(Duration(days: offset))),
    };
    _touch();
    notifyListeners();
  }

  void saveBudget(int comfortable, int max) {
    final current = trip;
    final id = current?.viewerId;
    if (current == null || id == null) {
      return;
    }
    final low = comfortable.clamp(40, 800);
    final high = (max < low ? low : max).clamp(40, 800);
    current.budgets[id] = BudgetAnswer(comfortable: low, max: high);
    _touch();
    _say('Saved. Only you can see this.');
  }

  void skipBudget() {
    final current = trip;
    final id = current?.viewerId;
    if (current == null || id == null) {
      return;
    }
    final cost = current.draftCost;
    current.budgets[id] = BudgetAnswer(
      comfortable: cost,
      max: cost,
      acceptedDefault: true,
    );
    _touch();
    _say('The draft estimate is fine for you. Only you can see this.');
  }

  void lowerPlan() {
    final current = trip;
    if (current == null || !current.viewerIsOrganiser) {
      return;
    }
    final band = budgetBand(current);
    if (band == null) {
      return;
    }
    current.draftCost = band.lowestMax;
    current.edited = true;
    _touch();
    _say('Plan adjusted to \$${current.draftCost}. No names attached.');
  }

  void castVote(SwipeMode mode, String cardId, Vote vote) {
    final current = trip;
    final id = current?.viewerId;
    if (current == null || id == null) {
      return;
    }
    final map = mode == SwipeMode.destination
        ? current.destinationVotes
        : current.activityVotes;
    final votes = map.putIfAbsent(cardId, () => <String, Vote>{});
    _undo = _SwipeUndo(
      mode: mode,
      cardId: cardId,
      previous: votes[id],
      hadPrevious: votes.containsKey(id),
      previousSuper: current.superLikes[id],
    );
    votes[id] = vote;
    if (mode == SwipeMode.activities &&
        current.superLikes[id] == cardId &&
        vote == Vote.no) {
      current.superLikes.remove(id);
    }
    _touch();
    notifyListeners();
  }

  void superLike(String cardId) {
    final current = trip;
    final id = current?.viewerId;
    if (current == null || id == null) {
      return;
    }
    if (current.superLikes.containsKey(id)) {
      _say('You\'ve used your star.');
      return;
    }
    _undo = _SwipeUndo(
      mode: SwipeMode.activities,
      cardId: cardId,
      previous: current.activityVotes[cardId]?[id],
      hadPrevious: current.activityVotes[cardId]?.containsKey(id) ?? false,
      previousSuper: null,
    );
    current.superLikes[id] = cardId;
    current.activityVotes.putIfAbsent(cardId, () => {})[id] = Vote.yes;
    _touch();
    notifyListeners();
  }

  void undoLastVote() {
    final current = trip;
    final undo = _undo;
    final id = current?.viewerId;
    if (current == null || undo == null || id == null) {
      return;
    }
    final map = undo.mode == SwipeMode.destination
        ? current.destinationVotes
        : current.activityVotes;
    final votes = map[undo.cardId];
    if (votes != null) {
      if (undo.hadPrevious && undo.previous != null) {
        votes[id] = undo.previous!;
      } else {
        votes.remove(id);
      }
    }
    current.superLikes.remove(id);
    if (undo.previousSuper != null) {
      current.superLikes[id] = undo.previousSuper!;
    }
    current.finishedDecks[undo.mode]?.remove(id);
    _undo = null;
    notifyListeners();
  }

  void finishDeck(SwipeMode mode) {
    final current = trip;
    final id = current?.viewerId;
    if (current == null || id == null) {
      return;
    }
    current.finishedDecks.putIfAbsent(mode, () => <String>{}).add(id);
    notifyListeners();
  }

  int yesCount(String activityId) {
    final votes = trip?.activityVotes[activityId];
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

  String? addActivity(String title) {
    final current = trip;
    final clean = title.trim();
    if (current == null) {
      return 'Start a trip first.';
    }
    if (clean.isEmpty) {
      return 'Couldn\'t read that link. Add a title and we\'ll save it.';
    }
    final price = 36;
    final stretch = price > activityCeiling(current);
    current.activities.add(
      ActivityOption(
        id: 'idea-${current.activities.length}',
        title: clean,
        pricePp: price,
        duration: '2h',
        addedBy: current.viewerId,
        stretch: stretch,
        blurb: 'Added by the group.',
      ),
    );
    current.finishedDecks[SwipeMode.activities]?.clear();
    _touch();
    notifyListeners();
    return null;
  }

  void voteStay(String stayId) {
    final current = trip;
    final id = current?.viewerId;
    if (current == null || id == null) {
      return;
    }
    current.stayVotes[id] = stayId;
    _touch();
    notifyListeners();
  }

  String? addStaySuggestion(String title) {
    final current = trip;
    final id = current?.viewerId;
    final clean = title.trim();
    if (current == null || id == null) {
      return 'Join the trip first.';
    }
    if (current.stayAddedBy.contains(id)) {
      return 'One suggestion each, so the list stays short.';
    }
    if (clean.isEmpty) {
      return 'Add a title and we\'ll save it.';
    }
    current.stays.add(
      StayOption(
        id: 'stay-${current.stays.length}',
        name: clean,
        detail: 'Suggested · sleeps the group',
        pricePp: 120,
        rating: 4.5,
        addedBy: id,
        blurb: 'Added from a link.',
      ),
    );
    current.stayAddedBy.add(id);
    _touch();
    notifyListeners();
    return null;
  }

  void objectTo(DecisionKind kind, String? reason) {
    final current = trip;
    final id = current?.viewerId;
    if (current == null || id == null) {
      return;
    }
    if (!current.locked.contains(kind)) {
      _say('This decision is still open.');
      return;
    }
    final lockedAt = current.lockedAt[kind];
    if (lockedAt == null ||
        now.isAfter(lockedAt.add(const Duration(hours: 12)))) {
      _say('The 12 hour objection window has closed.');
      return;
    }
    final existing = current.objections[kind];
    if (existing != null) {
      _say('This decision already had its one objection.');
      return;
    }
    current.objections[kind] = ObjectionState(
      memberId: id,
      reason: reason?.trim(),
    );
    _say('Objection noted. A 12h re-vote is open.');
  }

  void voteObjection(DecisionKind kind, String optionId) {
    final current = trip;
    final id = current?.viewerId;
    final objection = current?.objections[kind];
    if (current == null ||
        id == null ||
        objection == null ||
        objection.resolved) {
      return;
    }
    objection.votes[id] = optionId;
    _touch();
    notifyListeners();
  }

  void breakDestinationTie(String id) {
    final current = trip;
    if (current == null || !current.viewerIsOrganiser) {
      return;
    }
    final ranking = rankDestinations(current);
    if (!_allows(ranking, id)) {
      _say('You can only choose between the top options.');
      return;
    }
    current.destinationPick = id;
    _say('Tie broken.');
  }

  void breakDateTie(DateTime start) {
    final current = trip;
    if (current == null || !current.viewerIsOrganiser) {
      return;
    }
    final result = bestDates(current);
    final allowed = result.tied.any(
      (window) =>
          window.start.year == start.year &&
          window.start.month == start.month &&
          window.start.day == start.day,
    );
    if (!result.isTie || !allowed) {
      _say('You can only choose between the top options.');
      return;
    }
    current.datePick = DateTime(start.year, start.month, start.day);
    _say('Tie broken.');
  }

  void breakStayTie(String id) {
    final current = trip;
    if (current == null || !current.viewerIsOrganiser) {
      return;
    }
    final ranking = rankStays(current);
    if (!_allows(ranking, id)) {
      _say('You can only choose between the top options.');
      return;
    }
    current.stayPick = id;
    _say('Tie broken.');
  }

  void breakActivityTie(String id) {
    final current = trip;
    if (current == null || !current.viewerIsOrganiser) {
      return;
    }
    final ranking = rankActivities(current);
    if (!ranking.tie) {
      return;
    }
    final choices = ranking.options.length >= 4
        ? [ranking.options[2].id, ranking.options[3].id]
        : ranking.options.map((option) => option.id).toList();
    if (!choices.contains(id)) {
      _say('You can only choose between the top options.');
      return;
    }
    current.activityPick = id;
    _say('Tie broken.');
  }

  bool commit() {
    final current = trip;
    final person = current?.viewer;
    if (current == null || person == null) {
      return false;
    }
    final wasConfirmed = isConfirmed(current);
    current.optOutReasons.remove(person.id);
    current.committed.add(person.id);
    final nowConfirmed = isConfirmed(current);
    if (wasConfirmed) {
      current.arrivalNote =
          '${person.name} is in! ${current.committed.length} going.';
    }
    _touch();
    notifyListeners();
    return nowConfirmed && !wasConfirmed;
  }

  void cantMakeIt(String? reason) {
    final current = trip;
    final person = current?.viewer;
    if (current == null || person == null) {
      return;
    }
    current.committed.remove(person.id);
    current.optOutReasons[person.id] = (reason ?? '').trim();
    _say('Thanks for letting the group know.');
  }

  void toggleSkip(String activityId) {
    final current = trip;
    final id = current?.viewerId;
    if (current == null || id == null) {
      return;
    }
    final skipped = current.skippedActivities.putIfAbsent(id, () => <String>{});
    if (!skipped.add(activityId)) {
      skipped.remove(activityId);
    }
    notifyListeners();
  }

  void nudge() {
    final current = trip;
    if (current == null || !current.viewerIsOrganiser) {
      return;
    }
    for (final kind in DecisionKind.values) {
      if (decisionActive(current, kind)) {
        current.reminders[kind] = (current.reminders[kind] ?? 0) + 1;
      }
    }
    _say('Reminder sent by JourneyGo 👋');
  }

  void markBooked(bool value) {
    final current = trip;
    if (current == null) {
      return;
    }
    if (!current.viewerIsOrganiser) {
      _say('${current.organiser.name} is booking the stay.');
      return;
    }
    current.booked = value;
    _touch();
    notifyListeners();
  }

  void setDrivers(List<String> ids) {
    final current = trip;
    if (current == null) {
      return;
    }
    current.drivers
      ..clear()
      ..addAll(ids);
    _touch();
    notifyListeners();
  }

  void addCost({
    required String title,
    required int amount,
    required String payerId,
  }) {
    final current = trip;
    final clean = title.trim();
    if (current == null) {
      return;
    }
    if (clean.isEmpty || amount <= 0) {
      _say('Add a name and an amount.');
      return;
    }
    current.costs.add(
      CostEntry(
        id: 'cost-${current.costs.length + 1}',
        title: clean,
        amount: amount,
        payerId: payerId,
        addedById: current.viewerId ?? payerId,
        addedAt: now,
      ),
    );
    _touch();
    _say('Cost added. No money moves through JourneyGo.');
  }

  void markPaid(Transfer transfer) {
    final current = trip;
    if (current == null || transfer.amount <= 0) {
      return;
    }
    current.settlements.add(
      Settlement(
        fromId: transfer.fromId,
        toId: transfer.toId,
        amount: transfer.amount,
      ),
    );
    _touch();
    notifyListeners();
  }

  void setSimplify(bool value) {
    simplifyPayments = value;
    notifyListeners();
  }

  void advanceClock() {
    final current = trip;
    if (current == null) {
      return;
    }
    final pending = current.objections.entries.where(
      (entry) => !entry.value.resolved,
    );
    if (pending.isNotEmpty) {
      _resolveObjections(current);
      _say('Re-vote closed.');
      return;
    }
    final openKinds = [
      for (final kind in DecisionKind.values)
        if (decisionActive(current, kind)) kind,
    ];
    if (openKinds.isEmpty) {
      if (plansLocked(current) && !isConfirmed(current)) {
        _say(
          'Commitment is never assumed. Two people still need to tap I\'m in.',
        );
      }
      return;
    }
    final allClosing = openKinds.every(
      (kind) => phaseOf(current, kind, now) == DecisionPhase.closing,
    );
    if (!allClosing) {
      final soon = now.add(const Duration(minutes: 90));
      for (final kind in openKinds) {
        current.reminders[kind] = (current.reminders[kind] ?? 0) + 1;
        _setDeadline(current, kind, soon);
      }
      _say('Last call: locks in 1h 30m.');
      return;
    }
    for (final kind in openKinds) {
      final block = lockBlockReason(current, kind);
      if (block != null) {
        current.reminders[kind] = (current.reminders[kind] ?? 0) + 1;
        _say(block);
        return;
      }
      if (needsTie(current, kind)) {
        if (current.viewerIsOrganiser) {
          _say('Break the tie between the top options first.');
          _push(AppRoutes.results, kind);
        } else {
          _say('${current.organiser.name} is breaking a tie.');
        }
        return;
      }
    }
    for (final kind in openKinds) {
      current.locked.add(kind);
      current.lockedAt[kind] = now;
    }
    if (basicsLocked(current) && current.plansDeadline == null) {
      current.plansDeadline = now.add(const Duration(hours: 24));
      _say('Basics locked. Activities and stay are open.');
      return;
    }
    if (plansLocked(current) && current.commitDeadline == null) {
      current.commitDeadline = now.add(const Duration(hours: 48));
      _say('Stay and activities locked. Commitment is never assumed.');
      return;
    }
    _say('Locked. You can object for 12 hours.');
  }

  String statusUpdate() {
    final current = trip;
    if (current == null) {
      return '';
    }
    if (isConfirmed(current)) {
      return '${current.name} is confirmed. ${compactRange(current.start, current.end)}.';
    }
    final bits = <String>[];
    if (current.locked.contains(DecisionKind.destination)) {
      final name =
          rankDestinations(current).leader?.title ?? current.places.first.name;
      bits.add('$name locked');
    }
    for (final kind in DecisionKind.values) {
      if (decisionActive(current, kind)) {
        bits.add(
          '${decisionTitle(kind)} ${closesLabel(deadlineFor(current, kind), now).toLowerCase()}',
        );
        break;
      }
    }
    if (bits.isEmpty) {
      return current.name;
    }
    return '${current.name}: ${bits.join(' · ')}';
  }

  String ticketText() {
    final current = trip;
    if (current == null) {
      return '';
    }
    final place =
        rankDestinations(current).leader?.title ?? current.places.first.name;
    final stay = chosenStay(current)?.name ?? 'Stay to book';
    final anchors = [
      for (final activity in anchorActivities(current)) activity.title,
    ].join(' · ');
    return '${current.name} is ON\n$place · ${compactRange(current.start, current.end)}\n$stay\n$anchors\nAbout \$${sharedEstimate(current)} each';
  }

  String get link {
    final slug = trip?.slug ?? '';
    return 'https://journeygo.app/t/$slug';
  }

  void note(String message) => _say(message);

  void _resolveObjections(TripSession current) {
    for (final entry in current.objections.entries) {
      final objection = entry.value;
      if (objection.resolved) {
        continue;
      }
      final tally = <String, int>{};
      for (final vote in objection.votes.values) {
        tally[vote] = (tally[vote] ?? 0) + 1;
      }
      String? winner;
      var best = 0;
      for (final item in tally.entries) {
        if (item.value > best) {
          best = item.value;
          winner = item.key;
        }
      }
      if (winner != null) {
        switch (entry.key) {
          case DecisionKind.destination:
            current.destinationPick = winner;
          case DecisionKind.stay:
            current.stayPick = winner;
          case DecisionKind.activities:
            current.activityPick = winner;
          case DecisionKind.dates:
          case DecisionKind.budget:
            break;
        }
      }
      objection.resolved = true;
    }
  }

  void _setDeadline(TripSession current, DecisionKind kind, DateTime deadline) {
    switch (kind) {
      case DecisionKind.destination:
      case DecisionKind.dates:
      case DecisionKind.budget:
        current.basicsDeadline = deadline;
      case DecisionKind.activities:
      case DecisionKind.stay:
        current.plansDeadline = deadline;
    }
  }

  bool _allows(Ranking ranking, String id) {
    if (!ranking.tie || ranking.options.isEmpty) {
      return false;
    }
    final top = ranking.options.first.score;
    return ranking.options.any(
      (option) => option.id == id && option.score == top,
    );
  }

  void _touch() {
    if (offline && trip != null) {
      trip!.pendingSync = true;
    }
  }

  void _say(String message) {
    _toast = message;
    notifyListeners();
  }

  void _home(String route, [Object? arguments]) {
    navigator.currentState?.pushNamedAndRemoveUntil(
      route,
      (item) => false,
      arguments: arguments,
    );
  }

  void _push(String route, [Object? arguments]) {
    navigator.currentState?.pushNamed(route, arguments: arguments);
  }

  String _title(String value) {
    if (value.isEmpty) {
      return value;
    }
    return value[0].toUpperCase() + value.substring(1);
  }
}
