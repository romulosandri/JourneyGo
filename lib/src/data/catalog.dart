import '../models/planning.dart';

class PlaceSeed {
  const PlaceSeed({
    required this.id,
    required this.name,
    required this.vibe,
    required this.travel,
    required this.hours,
    required this.roughPp,
    required this.nightly,
    required this.blurb,
    required this.routeNote,
  });

  final String id;
  final String name;
  final Vibe vibe;
  final String travel;
  final double hours;
  final int roughPp;
  final int nightly;
  final String blurb;
  final String routeNote;

  PlaceOption build({bool extra = false, String? addedBy}) {
    return PlaceOption(
      id: id,
      name: name,
      vibe: vibe,
      travel: travel,
      hours: hours,
      roughPp: roughPp,
      nightly: nightly,
      blurb: blurb,
      routeNote: routeNote,
      extra: extra,
      addedBy: addedBy,
    );
  }
}

class ActivitySeed {
  const ActivitySeed({
    required this.id,
    required this.title,
    required this.pricePp,
    required this.duration,
    required this.blurb,
  });

  final String id;
  final String title;
  final int pricePp;
  final String duration;
  final String blurb;

  ActivityOption build({String? addedBy}) {
    return ActivityOption(
      id: id,
      title: title,
      pricePp: pricePp,
      duration: duration,
      blurb: blurb,
      addedBy: addedBy,
    );
  }
}

const placeCatalog = <PlaceSeed>[
  PlaceSeed(
    id: 'costa',
    name: 'Costa Lumen',
    vibe: Vibe.beach,
    travel: '2h drive',
    hours: 2,
    roughPp: 240,
    nightly: 90,
    blurb: 'Warm water, a Friday market, and nowhere you have to be.',
    routeNote: 'Drive · 2h 10m · ~\$22 pp (2 cars)',
  ),
  PlaceSeed(
    id: 'ilha',
    name: 'Ilha Sereno',
    vibe: Vibe.beach,
    travel: '3h drive',
    hours: 3,
    roughPp: 280,
    nightly: 110,
    blurb: 'One ferry, quiet coves, phones down by dinner.',
    routeNote: 'Ferry and a short drive · 3h · ~\$28 pp',
  ),
  PlaceSeed(
    id: 'praia',
    name: 'Praia Mansa',
    vibe: Vibe.beach,
    travel: '2h 20m drive',
    hours: 2.3,
    roughPp: 230,
    nightly: 95,
    blurb: 'A soft beach with a town that shuts early.',
    routeNote: 'Drive · 2h 20m · ~\$20 pp',
  ),
  PlaceSeed(
    id: 'vale',
    name: 'Vale Alto',
    vibe: Vibe.nature,
    travel: '2h 30m drive',
    hours: 2.5,
    roughPp: 190,
    nightly: 70,
    blurb: 'A cold river, long lunches, and hills that catch the light.',
    routeNote: 'Drive · 2h 30m · ~\$18 pp',
  ),
  PlaceSeed(
    id: 'marrow',
    name: 'Lake Marrow',
    vibe: Vibe.nature,
    travel: '4h drive',
    hours: 4,
    roughPp: 210,
    nightly: 80,
    blurb: 'Still water and a path out to the light.',
    routeNote: 'Drive · 4h · ~\$30 pp',
  ),
  PlaceSeed(
    id: 'serra',
    name: 'Serra Bruma',
    vibe: Vibe.nature,
    travel: '3h 20m drive',
    hours: 3.3,
    roughPp: 200,
    nightly: 75,
    blurb: 'Morning mist, then trails while the day is cool.',
    routeNote: 'Drive · 3h 20m · ~\$24 pp',
  ),
  PlaceSeed(
    id: 'cidade',
    name: 'Cidade Norte',
    vibe: Vibe.city,
    travel: '1h 40m drive',
    hours: 1.7,
    roughPp: 260,
    nightly: 140,
    blurb: 'A river city with late kitchens and night walks.',
    routeNote: 'Drive · 1h 40m · ~\$16 pp',
  ),
  PlaceSeed(
    id: 'cais',
    name: 'Alto Cais',
    vibe: Vibe.city,
    travel: '2h drive',
    hours: 2,
    roughPp: 250,
    nightly: 130,
    blurb: 'Warehouses, a pier, and a Sunday market.',
    routeNote: 'Drive · 2h · ~\$18 pp',
  ),
  PlaceSeed(
    id: 'rua',
    name: 'Rua Clara',
    vibe: Vibe.city,
    travel: '1h 20m drive',
    hours: 1.3,
    roughPp: 270,
    nightly: 150,
    blurb: 'Galleries, a hill, and rain-friendly plans.',
    routeNote: 'Drive · 1h 20m · ~\$14 pp',
  ),
];

const activityCatalog = <ActivitySeed>[
  ActivitySeed(
    id: 'catamaran',
    title: 'Sunset catamaran',
    pricePp: 45,
    duration: '3h',
    blurb: 'A slow loop while the light goes.',
  ),
  ActivitySeed(
    id: 'market',
    title: 'Food market',
    pricePp: 18,
    duration: '2h',
    blurb: 'Eat standing up. Nobody has to book.',
  ),
  ActivitySeed(
    id: 'lighthouse',
    title: 'Lighthouse hike',
    pricePp: 15,
    duration: '3h',
    blurb: 'A cliff path and a view you can sit in.',
  ),
  ActivitySeed(
    id: 'beach',
    title: 'Beach day',
    pricePp: 0,
    duration: '4h',
    blurb: 'Towels, a bakery run, no plan after that.',
  ),
  ActivitySeed(
    id: 'tour',
    title: 'Local food tour',
    pricePp: 32,
    duration: '3h',
    blurb: 'Four stops, all within a short walk.',
  ),
  ActivitySeed(
    id: 'picnic',
    title: 'Cliff picnic',
    pricePp: 20,
    duration: '2h',
    blurb: 'Bread, fruit, and a blanket with a view.',
  ),
];

List<StayOption> freshStays() {
  return [
    StayOption(
      id: 'brisa',
      name: 'Casa Brisa',
      detail: '3 bedrooms · sleeps 6',
      pricePp: 118,
      rating: 4.8,
      blurb: 'A courtyard, a long table, and the sea two streets away.',
    ),
    StayOption(
      id: 'mare',
      name: 'Vila Maré',
      detail: '3 bedrooms · 15 min further',
      pricePp: 96,
      rating: 4.6,
      blurb: 'Quieter, a little older, a kitchen that fits everyone.',
    ),
    StayOption(
      id: 'farol',
      name: 'Loft Farol',
      detail: '2 bedrooms · closer to the light',
      pricePp: 140,
      rating: 4.7,
      stretch: true,
      blurb: 'The view is the point. The sofas pull out.',
    ),
  ];
}

Member freshMember(String id) {
  switch (id) {
    case 'ana':
      return Member(id: 'ana', name: 'Ana', role: MemberRole.organiser);
    case 'bruno':
      return Member(id: 'bruno', name: 'Bruno', role: MemberRole.yesPerson);
    case 'caio':
      return Member(id: 'caio', name: 'Caio', role: MemberRole.yesPerson);
    case 'duda':
      return Member(id: 'duda', name: 'Duda', role: MemberRole.planner);
    case 'leo':
      return Member(id: 'leo', name: 'Leo', role: MemberRole.reluctant);
    case 'mari':
      return Member(id: 'mari', name: 'Mari', role: MemberRole.budget);
    default:
      return Member(id: id, name: id, role: MemberRole.yesPerson);
  }
}

List<Member> freshCrew() {
  return [
    freshMember('ana'),
    freshMember('bruno'),
    freshMember('caio'),
    freshMember('duda'),
    freshMember('leo'),
    freshMember('mari'),
  ];
}

PlaceSeed? placeSeed(String id) {
  for (final place in placeCatalog) {
    if (place.id == id) {
      return place;
    }
  }
  return null;
}

List<PlaceOption> suggestionsFor(Vibe vibe) {
  switch (vibe) {
    case Vibe.beach:
      return [
        placeSeed('costa')!.build(),
        placeSeed('ilha')!.build(),
        placeSeed('vale')!.build(),
      ];
    case Vibe.city:
      return [
        placeSeed('cidade')!.build(),
        placeSeed('cais')!.build(),
        placeSeed('rua')!.build(),
      ];
    case Vibe.nature:
      return [
        placeSeed('vale')!.build(),
        placeSeed('marrow')!.build(),
        placeSeed('serra')!.build(),
      ];
    case Vibe.surprise:
      return [
        placeSeed('costa')!.build(),
        placeSeed('cidade')!.build(),
        placeSeed('vale')!.build(),
      ];
  }
}

List<ActivityOption> freshActivities() {
  return [for (final seed in activityCatalog) seed.build()];
}

String vibeLabel(Vibe vibe) {
  switch (vibe) {
    case Vibe.beach:
      return 'Beach';
    case Vibe.city:
      return 'City';
    case Vibe.nature:
      return 'Nature';
    case Vibe.surprise:
      return 'Surprise me';
  }
}

String vibeEmoji(Vibe vibe) {
  switch (vibe) {
    case Vibe.beach:
      return '🏖';
    case Vibe.city:
      return '🏙';
    case Vibe.nature:
      return '🌲';
    case Vibe.surprise:
      return '🎉';
  }
}

String tripNameFor(Vibe vibe) {
  switch (vibe) {
    case Vibe.beach:
      return 'Sunny Escape';
    case Vibe.city:
      return 'North Night';
    case Vibe.nature:
      return 'High Valley';
    case Vibe.surprise:
      return 'Open Weekend';
  }
}

String timingLabel(Timing timing) {
  switch (timing) {
    case Timing.thisMonth:
      return 'This month';
    case Timing.nextMonth:
      return 'Next month';
    case Timing.flexible:
      return 'Flexible';
  }
}

String partyLabel(PartySize size) {
  switch (size) {
    case PartySize.few:
      return '2–3';
    case PartySize.medium:
      return '4–6';
    case PartySize.crowd:
      return '7+';
  }
}

DateTime nextFriday(DateTime from) {
  var day = DateTime(from.year, from.month, from.day);
  while (day.weekday != DateTime.friday) {
    day = day.add(const Duration(days: 1));
  }
  if (!day.isAfter(DateTime(from.year, from.month, from.day))) {
    day = day.add(const Duration(days: 7));
  }
  return day;
}

DateTime weekendFor(Timing timing, DateTime now) {
  switch (timing) {
    case Timing.thisMonth:
      return nextFriday(now.add(const Duration(days: 7)));
    case Timing.nextMonth:
      final anchor = DateTime(now.year, now.month + 1, 1);
      if (now.month == 10 && anchor.year == 2026) {
        return DateTime(2026, 11, 13);
      }
      return nextFriday(anchor);
    case Timing.flexible:
      return nextFriday(now.add(const Duration(days: 21)));
  }
}

DateTime thursdayEvening(DateTime now) {
  var day = DateTime(now.year, now.month, now.day, 20);
  if (!day.isAfter(now)) {
    day = day.add(const Duration(days: 1));
  }
  while (day.weekday != DateTime.thursday) {
    day = day.add(const Duration(days: 1));
  }
  return day;
}
