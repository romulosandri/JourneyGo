import 'models/planning.dart';

const monthShort = <String>[
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

const weekdayShort = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

String money(int value) => '\$$value';

String weekdayOf(DateTime day) => weekdayShort[day.weekday - 1];

String monthDay(DateTime day) => '${monthShort[day.month - 1]} ${day.day}';

String weekdayMonthDay(DateTime day) => '${weekdayOf(day)} ${monthDay(day)}';

String rangeLabel(DateTime start, DateTime end) {
  if (start.year == end.year && start.month == end.month) {
    return '${weekdayMonthDay(start)} – ${weekdayOf(end)} ${end.day}';
  }
  if (start.year == end.year) {
    return '${weekdayMonthDay(start)} – ${weekdayMonthDay(end)}';
  }
  return '${weekdayMonthDay(start)} ${start.year} – ${weekdayMonthDay(end)} ${end.year}';
}

String compactRange(DateTime start, DateTime end) {
  final startMonth = monthShort[start.month - 1].toUpperCase();
  final endMonth = monthShort[end.month - 1].toUpperCase();
  if (start.month == end.month) {
    return '$startMonth ${start.day}–${end.day}';
  }
  return '$startMonth ${start.day} – $endMonth ${end.day}';
}

String sentenceRange(DateTime start, DateTime end) {
  if (start.month == end.month) {
    return '${monthShort[start.month - 1]} ${start.day}–${end.day}';
  }
  return '${monthShort[start.month - 1]} ${start.day} – ${monthShort[end.month - 1]} ${end.day}';
}

String hourLabel(DateTime time) {
  final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
  final suffix = time.hour >= 12 ? 'pm' : 'am';
  return '$hour$suffix';
}

String deadlineClock(DateTime deadline) =>
    '${weekdayOf(deadline)} ${hourLabel(deadline)}';

String closesLabel(DateTime deadline, DateTime now) {
  final left = deadline.difference(now);
  if (left.inMinutes <= 0) {
    return 'Closing now';
  }
  if (left.inMinutes < 120) {
    final hours = left.inHours;
    final minutes = left.inMinutes.remainder(60);
    if (hours == 0) {
      return 'Closes in ${minutes}m';
    }
    return 'Closes in ${hours}h ${minutes}m';
  }
  if (left.inHours < 48) {
    return 'Closes in ${left.inHours}h';
  }
  return 'Closes ${deadlineClock(deadline)}';
}

String ringLabel(DateTime deadline, DateTime now) {
  final left = deadline.difference(now);
  if (left.inMinutes <= 0) {
    return 'now';
  }
  if (left.inHours >= 48) {
    return '${left.inDays}d';
  }
  if (left.inMinutes >= 60) {
    return '${left.inHours}h';
  }
  return '${left.inMinutes}m';
}

String decisionTitle(DecisionKind kind) {
  switch (kind) {
    case DecisionKind.destination:
      return 'Destination';
    case DecisionKind.dates:
      return 'Dates';
    case DecisionKind.budget:
      return 'Budget';
    case DecisionKind.activities:
      return 'Activities';
    case DecisionKind.stay:
      return 'Stay';
  }
}

String codeLabel(String code) {
  if (code.length != 6) {
    return code;
  }
  return '${code.substring(0, 3)} ${code.substring(3)}';
}

String agoLabel(DateTime then, DateTime now) {
  final left = now.difference(then);
  if (left.inMinutes < 1) {
    return 'just now';
  }
  if (left.inMinutes < 60) {
    return '${left.inMinutes}m ago';
  }
  if (left.inHours < 24) {
    return '${left.inHours}h ago';
  }
  return '${left.inDays}d ago';
}

int daysUntil(DateTime now, DateTime start) {
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(start.year, start.month, start.day);
  return target.difference(today).inDays;
}
