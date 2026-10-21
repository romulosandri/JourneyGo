enum Vibe { beach, city, nature, surprise }

enum Timing { thisMonth, nextMonth, flexible }

enum PartySize { few, medium, crowd }

enum DecisionKind { destination, dates, budget, activities, stay }

enum DecisionPhase { open, closing, locked }

enum MemberRole { organiser, yesPerson, reluctant, budget, planner }

enum Seat { joined, saved }

enum Vote { no, maybe, yes }

enum SwipeMode { destination, activities }

enum PreviewKind {
  basics,
  landing,
  expired,
  tie,
  belowPlan,
  plans,
  commit,
  confirmed,
  objection,
}

enum MoneyUnit { trip, day }

class Member {
  Member({
    required this.id,
    required this.name,
    required this.role,
    this.seat = Seat.joined,
    this.opened = false,
  });

  final String id;
  final String name;
  final MemberRole role;
  Seat seat;
  bool opened;

  bool get joined => seat == Seat.joined;
}

class PlaceOption {
  PlaceOption({
    required this.id,
    required this.name,
    required this.travel,
    required this.hours,
    required this.roughPp,
    required this.nightly,
    this.blurb = '',
    this.routeNote = '',
    this.extra = false,
    this.addedBy,
    this.vibe = Vibe.beach,
  });

  final String id;
  final String name;
  final String travel;
  final double hours;
  final int roughPp;
  final int nightly;
  final String blurb;
  final String routeNote;
  final bool extra;
  final String? addedBy;
  final Vibe vibe;
}

class ActivityOption {
  ActivityOption({
    required this.id,
    required this.title,
    required this.pricePp,
    required this.duration,
    this.addedBy,
    this.stretch = false,
    this.blurb = '',
  });

  final String id;
  final String title;
  final int pricePp;
  final String duration;
  final String? addedBy;
  bool stretch;
  final String blurb;
}

class StayOption {
  StayOption({
    required this.id,
    required this.name,
    required this.detail,
    required this.pricePp,
    required this.rating,
    this.stretch = false,
    this.addedBy,
    this.blurb = '',
  });

  final String id;
  final String name;
  final String detail;
  final int pricePp;
  final double rating;
  bool stretch;
  final String? addedBy;
  final String blurb;
}

class BudgetAnswer {
  const BudgetAnswer({
    required this.comfortable,
    required this.max,
    this.acceptedDefault = false,
  });

  final int comfortable;
  final int max;
  final bool acceptedDefault;
}

class ObjectionState {
  ObjectionState({
    required this.memberId,
    this.reason,
    Map<String, String>? votes,
  }) : votes = votes ?? <String, String>{};

  final String memberId;
  final String? reason;
  final Map<String, String> votes;
  bool resolved = false;
}

class CostEntry {
  CostEntry({
    required this.id,
    required this.title,
    required this.amount,
    required this.payerId,
    required this.addedById,
    required this.addedAt,
  });

  final String id;
  final String title;
  final int amount;
  final String payerId;
  final String addedById;
  final DateTime addedAt;
}

class Settlement {
  const Settlement({
    required this.fromId,
    required this.toId,
    required this.amount,
  });

  final String fromId;
  final String toId;
  final int amount;
}

class TripSession {
  TripSession({
    required this.id,
    required this.name,
    required this.code,
    required this.slug,
    required this.vibe,
    required this.timing,
    required this.party,
    required this.places,
    required this.activities,
    required this.stays,
    required this.start,
    required this.end,
    required this.draftCost,
    required this.windowHours,
    required this.createdAt,
    required this.basicsDeadline,
    required this.members,
    this.viewerId,
    this.plansDeadline,
    this.commitDeadline,
    Map<String, Map<String, Vote>>? destinationVotes,
    Map<SwipeMode, Set<String>>? finishedDecks,
    Map<String, Set<String>>? availability,
    Set<String>? flexibleDates,
    Map<String, BudgetAnswer>? budgets,
    Map<String, Map<String, Vote>>? activityVotes,
    Map<String, String>? superLikes,
    Map<String, String>? stayVotes,
    Set<String>? stayAddedBy,
    Set<String>? committed,
    Map<String, String>? optOutReasons,
    Map<String, Set<String>>? skippedActivities,
    Set<DecisionKind>? locked,
    Map<DecisionKind, DateTime>? lockedAt,
    Map<DecisionKind, ObjectionState>? objections,
    Map<DecisionKind, int>? reminders,
    List<CostEntry>? costs,
    List<Settlement>? settlements,
    this.booked = false,
    List<String>? drivers,
    this.pendingSync = false,
    this.inviteExpired = false,
    this.edited = false,
    this.arrivalNote,
    this.destinationPick,
    this.datePick,
    this.stayPick,
    this.activityPick,
  }) : destinationVotes = destinationVotes ?? <String, Map<String, Vote>>{},
       finishedDecks = finishedDecks ?? <SwipeMode, Set<String>>{},
       availability = availability ?? <String, Set<String>>{},
       flexibleDates = flexibleDates ?? <String>{},
       budgets = budgets ?? <String, BudgetAnswer>{},
       activityVotes = activityVotes ?? <String, Map<String, Vote>>{},
       superLikes = superLikes ?? <String, String>{},
       stayVotes = stayVotes ?? <String, String>{},
       stayAddedBy = stayAddedBy ?? <String>{},
       committed = committed ?? <String>{},
       optOutReasons = optOutReasons ?? <String, String>{},
       skippedActivities = skippedActivities ?? <String, Set<String>>{},
       locked = locked ?? <DecisionKind>{},
       lockedAt = lockedAt ?? <DecisionKind, DateTime>{},
       objections = objections ?? <DecisionKind, ObjectionState>{},
       reminders = reminders ?? <DecisionKind, int>{},
       costs = costs ?? <CostEntry>[],
       settlements = settlements ?? <Settlement>[],
       drivers = drivers ?? <String>[];

  final String id;
  String name;
  final String code;
  final String slug;
  final Vibe vibe;
  final Timing timing;
  final PartySize party;
  final List<PlaceOption> places;
  final List<ActivityOption> activities;
  final List<StayOption> stays;
  DateTime start;
  DateTime end;
  int draftCost;
  int windowHours;
  final DateTime createdAt;
  DateTime basicsDeadline;
  DateTime? plansDeadline;
  DateTime? commitDeadline;
  String? viewerId;
  final List<Member> members;
  final Map<String, Map<String, Vote>> destinationVotes;
  final Map<SwipeMode, Set<String>> finishedDecks;
  final Map<String, Set<String>> availability;
  final Set<String> flexibleDates;
  final Map<String, BudgetAnswer> budgets;
  final Map<String, Map<String, Vote>> activityVotes;
  final Map<String, String> superLikes;
  final Map<String, String> stayVotes;
  final Set<String> stayAddedBy;
  final Set<String> committed;
  final Map<String, String> optOutReasons;
  final Map<String, Set<String>> skippedActivities;
  final Set<DecisionKind> locked;
  final Map<DecisionKind, DateTime> lockedAt;
  final Map<DecisionKind, ObjectionState> objections;
  final Map<DecisionKind, int> reminders;
  final List<CostEntry> costs;
  final List<Settlement> settlements;
  bool booked;
  final List<String> drivers;
  bool pendingSync;
  bool inviteExpired;
  bool edited;
  String? arrivalNote;
  String? destinationPick;
  DateTime? datePick;
  String? stayPick;
  String? activityPick;

  int get nights => end.difference(start).inDays.clamp(1, 14);

  Member? member(String id) {
    for (final person in members) {
      if (person.id == id) {
        return person;
      }
    }
    return null;
  }

  Member? get viewer {
    final id = viewerId;
    if (id == null) {
      return null;
    }
    return member(id);
  }

  Member get organiser {
    for (final person in members) {
      if (person.role == MemberRole.organiser) {
        return person;
      }
    }
    return members.first;
  }

  List<Member> get joined => [
    for (final person in members)
      if (person.joined) person,
  ];

  bool get viewerIsOrganiser => viewer?.role == MemberRole.organiser;

  int get openedCount => joined.where((person) => person.opened).length;

  int get halfRequired => (joined.length / 2).ceil().clamp(1, 99);

  bool get halfOpened => openedCount >= halfRequired;
}
