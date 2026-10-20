import 'models/journey.dart';

const _months = [
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

String formatDay(DateTime date) {
  final day = dateOnly(date);
  return '${day.day} ${_months[day.month - 1]} ${day.year}';
}

String formatRange(DateTime start, DateTime end) {
  final first = dateOnly(start);
  final last = dateOnly(end);
  if (first == last) {
    return formatDay(first);
  }
  if (first.year == last.year && first.month == last.month) {
    return '${first.day}–${last.day} ${_months[first.month - 1]} ${first.year}';
  }
  if (first.year == last.year) {
    return '${first.day} ${_months[first.month - 1]} – ${last.day} ${_months[last.month - 1]} ${first.year}';
  }
  return '${formatDay(first)} – ${formatDay(last)}';
}

String phaseLabel(JourneyPhase phase) {
  switch (phase) {
    case JourneyPhase.upcoming:
      return 'Upcoming';
    case JourneyPhase.onTheRoad:
      return 'On the road';
    case JourneyPhase.remembered:
      return 'Remembered';
  }
}

String filterLabel(JourneyFilter filter) {
  switch (filter) {
    case JourneyFilter.all:
      return 'All';
    case JourneyFilter.onTheRoad:
      return 'On the road';
    case JourneyFilter.upcoming:
      return 'Upcoming';
    case JourneyFilter.remembered:
      return 'Remembered';
  }
}

String placesLabel(Journey journey) {
  final total = journey.stops.length;
  if (total == 0) {
    return 'No places yet';
  }
  final noun = total == 1 ? 'place' : 'places';
  return '${journey.doneCount} of $total $noun';
}

String journeyCountLabel(int count) {
  switch (count) {
    case 0:
      return 'Nothing planned yet.';
    case 1:
      return '1 journey on this phone.';
    default:
      return '$count journeys on this phone.';
  }
}
