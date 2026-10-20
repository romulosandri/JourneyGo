enum JourneyAccent { terracotta, sea, night, gold }

enum JourneyPhase { upcoming, onTheRoad, remembered }

enum JourneyFilter { all, onTheRoad, upcoming, remembered }

DateTime dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

class Stop {
  const Stop({
    required this.id,
    required this.name,
    this.detail = '',
    this.done = false,
  });

  final String id;
  final String name;
  final String detail;
  final bool done;

  Stop copyWith({String? id, String? name, String? detail, bool? done}) {
    return Stop(
      id: id ?? this.id,
      name: name ?? this.name,
      detail: detail ?? this.detail,
      done: done ?? this.done,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'detail': detail,
    'done': done,
  };

  factory Stop.fromJson(Map<String, Object?> json) {
    final id = json['id'];
    final name = json['name'];
    if (id is! String || name is! String || id.isEmpty || name.isEmpty) {
      throw const FormatException('A stop is missing its name.');
    }
    return Stop(
      id: id,
      name: name,
      detail: json['detail'] is String ? json['detail'] as String : '',
      done: json['done'] == true,
    );
  }
}

class Journey {
  const Journey({
    required this.id,
    required this.title,
    required this.place,
    required this.start,
    required this.end,
    required this.accent,
    this.note = '',
    this.stops = const [],
  });

  final String id;
  final String title;
  final String place;
  final DateTime start;
  final DateTime end;
  final String note;
  final JourneyAccent accent;
  final List<Stop> stops;

  int get doneCount => stops.where((stop) => stop.done).length;

  double get progress => stops.isEmpty ? 0 : doneCount / stops.length;

  JourneyPhase phaseOn(DateTime day) {
    final today = dateOnly(day);
    final first = dateOnly(start);
    final last = dateOnly(end);
    if (today.isBefore(first)) {
      return JourneyPhase.upcoming;
    }
    if (today.isAfter(last)) {
      return JourneyPhase.remembered;
    }
    return JourneyPhase.onTheRoad;
  }

  Journey copyWith({
    String? id,
    String? title,
    String? place,
    DateTime? start,
    DateTime? end,
    String? note,
    JourneyAccent? accent,
    List<Stop>? stops,
  }) {
    return Journey(
      id: id ?? this.id,
      title: title ?? this.title,
      place: place ?? this.place,
      start: start ?? this.start,
      end: end ?? this.end,
      note: note ?? this.note,
      accent: accent ?? this.accent,
      stops: stops ?? this.stops,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'place': place,
    'start': _formatDate(start),
    'end': _formatDate(end),
    'note': note,
    'accent': accent.name,
    'stops': [for (final stop in stops) stop.toJson()],
  };

  factory Journey.fromJson(Map<String, Object?> json) {
    final id = json['id'];
    final title = json['title'];
    final place = json['place'];
    final start = json['start'];
    final end = json['end'];
    if (id is! String ||
        title is! String ||
        place is! String ||
        start is! String ||
        end is! String) {
      throw const FormatException('A journey is missing a required field.');
    }
    final stopsRaw = json['stops'];
    final stops = <Stop>[];
    if (stopsRaw is List) {
      for (final item in stopsRaw) {
        if (item is Map) {
          stops.add(Stop.fromJson(Map<String, Object?>.from(item)));
        }
      }
    }
    return Journey(
      id: id,
      title: title,
      place: place,
      start: _parseDate(start),
      end: _parseDate(end),
      note: json['note'] is String ? json['note'] as String : '',
      accent: _accentFromName(json['accent']),
      stops: stops,
    );
  }
}

JourneyAccent _accentFromName(Object? name) {
  for (final accent in JourneyAccent.values) {
    if (accent.name == name) {
      return accent;
    }
  }
  return JourneyAccent.terracotta;
}

String _formatDate(DateTime value) {
  final day = dateOnly(value);
  final month = day.month.toString().padLeft(2, '0');
  final date = day.day.toString().padLeft(2, '0');
  return '${day.year.toString().padLeft(4, '0')}-$month-$date';
}

DateTime _parseDate(String value) {
  final parts = value.split('-');
  if (parts.length != 3) {
    throw FormatException('Bad date: $value');
  }
  final year = int.parse(parts[0]);
  final month = int.parse(parts[1]);
  final day = int.parse(parts[2]);
  final parsed = DateTime(year, month, day);
  if (parsed.year != year || parsed.month != month || parsed.day != day) {
    throw FormatException('Bad date: $value');
  }
  return parsed;
}

int compareJourneys(Journey a, Journey b, DateTime today) {
  final phase = _phaseRank(a.phaseOn(today)) - _phaseRank(b.phaseOn(today));
  if (phase != 0) {
    return phase;
  }
  final date = switch (a.phaseOn(today)) {
    JourneyPhase.remembered => b.end.compareTo(a.end),
    JourneyPhase.upcoming ||
    JourneyPhase.onTheRoad => a.start.compareTo(b.start),
  };
  if (date != 0) {
    return date;
  }
  return a.title.toLowerCase().compareTo(b.title.toLowerCase());
}

int _phaseRank(JourneyPhase phase) {
  switch (phase) {
    case JourneyPhase.onTheRoad:
      return 0;
    case JourneyPhase.upcoming:
      return 1;
    case JourneyPhase.remembered:
      return 2;
  }
}

List<Journey> sortJourneys(List<Journey> journeys, DateTime today) {
  final sorted = [...journeys];
  sorted.sort((a, b) => compareJourneys(a, b, today));
  return sorted;
}

bool journeyMatches(
  Journey journey, {
  required JourneyFilter filter,
  required String query,
  required DateTime today,
}) {
  if (!_matchesFilter(journey, filter, today)) {
    return false;
  }
  final needle = query.trim().toLowerCase();
  if (needle.isEmpty) {
    return true;
  }
  final haystack = [
    journey.title,
    journey.place,
    journey.note,
    for (final stop in journey.stops) stop.name,
    for (final stop in journey.stops) stop.detail,
  ].join(' ').toLowerCase();
  return haystack.contains(needle);
}

bool _matchesFilter(Journey journey, JourneyFilter filter, DateTime today) {
  switch (filter) {
    case JourneyFilter.all:
      return true;
    case JourneyFilter.onTheRoad:
      return journey.phaseOn(today) == JourneyPhase.onTheRoad;
    case JourneyFilter.upcoming:
      return journey.phaseOn(today) == JourneyPhase.upcoming;
    case JourneyFilter.remembered:
      return journey.phaseOn(today) == JourneyPhase.remembered;
  }
}
