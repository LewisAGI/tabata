import '../models/session_log.dart';

const monthLabels = [
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

const weekdayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

DateTime dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

DateTime weekStart(DateTime value) {
  final day = dateOnly(value);
  return day.subtract(Duration(days: day.weekday - DateTime.monday));
}

String fmtDay(DateTime value) => '${value.day} ${monthLabels[value.month - 1]}';

String fmtDayYear(DateTime value) =>
    '${value.day} ${monthLabels[value.month - 1]} ${value.year}';

String fmtWeekdayDate(DateTime value) =>
    '${weekdayLabels[value.weekday - 1]} ${value.day} ${monthLabels[value.month - 1]} ${value.year}';

String fmtHm(int hour, int minute) =>
    '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

String fmtRange(DateTime start, DateTime end) {
  if (start.year == end.year && start.month == end.month) {
    return '${start.day}–${end.day} ${monthLabels[start.month - 1]} ${start.year}';
  }
  if (start.year == end.year) {
    return '${fmtDay(start)} – ${fmtDay(end)} ${start.year}';
  }
  return '${fmtDayYear(start)} – ${fmtDayYear(end)}';
}

String fmtClock(int seconds) {
  final safe = seconds < 0 ? 0 : seconds;
  final hours = safe ~/ 3600;
  final minutes = (safe % 3600) ~/ 60;
  final secs = safe % 60;
  final mm = minutes.toString().padLeft(2, '0');
  final ss = secs.toString().padLeft(2, '0');
  if (hours > 0) {
    return '$hours:$mm:$ss';
  }
  return '$minutes:$ss';
}

String fmtElapsed(Duration duration) {
  final totalMs = duration.inMilliseconds < 0 ? 0 : duration.inMilliseconds;
  final minutes = totalMs ~/ 60000;
  final seconds = (totalMs % 60000) ~/ 1000;
  final tenths = (totalMs % 1000) ~/ 100;
  final mm = minutes.toString().padLeft(2, '0');
  final ss = seconds.toString().padLeft(2, '0');
  return '$mm:$ss.$tenths';
}

String exportSession(SessionLog session) {
  return _document('Session · ${fmtWeekdayDate(session.startedAt)}', [
    _sessionBlock(session, 2),
  ]);
}

String exportDay(DateTime day, List<SessionLog> sessions) {
  final matches =
      sessions.where((session) => sameDay(session.startedAt, day)).toList()
        ..sort((a, b) => a.startedAt.compareTo(b.startedAt));
  return _document('Day · ${fmtWeekdayDate(day)}', [
    for (final session in matches) _sessionBlock(session, 2),
  ]);
}

String exportWeek(DateTime anchor, List<SessionLog> sessions) {
  final start = weekStart(anchor);
  final end = start.add(const Duration(days: 6));
  final matches = sessions.where((session) {
    final day = dateOnly(session.startedAt);
    return !day.isBefore(start) && !day.isAfter(end);
  }).toList()..sort((a, b) => a.startedAt.compareTo(b.startedAt));
  final blocks = <String>[];
  DateTime? current;
  final buffer = <String>[];
  void flush() {
    final day = current;
    if (day == null) {
      return;
    }
    blocks.add('## ${fmtWeekdayDate(day)}\n${buffer.join('\n\n')}');
    buffer.clear();
  }

  for (final session in matches) {
    final day = dateOnly(session.startedAt);
    if (current == null || !sameDay(current, day)) {
      flush();
      current = day;
    }
    buffer.add(_sessionBlock(session, 3));
  }
  flush();
  return _document('Week · ${fmtRange(start, end)}', blocks);
}

String _document(String scope, List<String> blocks) {
  if (blocks.isEmpty) {
    return '# Tabata\n$scope\n';
  }
  return '# Tabata\n$scope\n\n${blocks.join('\n\n')}\n';
}

String _sessionBlock(SessionLog session, int level) {
  final marks = '#' * level;
  final when = fmtHm(session.startedAt.hour, session.startedAt.minute);
  return [
    '$marks $when · ${session.presetName}',
    'Preset: ${session.presetName}',
    'Prep: ${session.prep}s',
    'Work: ${session.work}s',
    'Rest: ${session.rest}s',
    'Rounds: ${session.rounds}',
    'Sets: ${session.sets}',
    'Rest between sets: ${session.setRest}s',
    'Cooldown: ${session.cooldown}s',
    'Total time: ${fmtClock(session.totalSeconds)}',
    session.statusLabel,
  ].join('\n');
}
