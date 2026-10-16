import 'preset.dart';

class SessionLog {
  const SessionLog({
    required this.id,
    required this.presetId,
    required this.presetName,
    required this.prep,
    required this.work,
    required this.rest,
    required this.rounds,
    required this.sets,
    required this.setRest,
    required this.cooldown,
    required this.startedAt,
    required this.endedAt,
    required this.totalSeconds,
    required this.completed,
  });

  final String id;
  final String presetId;
  final String presetName;
  final int prep;
  final int work;
  final int rest;
  final int rounds;
  final int sets;
  final int setRest;
  final int cooldown;
  final DateTime startedAt;
  final DateTime endedAt;
  final int totalSeconds;
  final bool completed;

  String get statusLabel => completed ? 'Completed' : 'Stopped early';

  factory SessionLog.capture({
    required Preset preset,
    required DateTime startedAt,
    required DateTime endedAt,
    required Duration elapsed,
    required bool completed,
  }) {
    return SessionLog(
      id: '${startedAt.microsecondsSinceEpoch}',
      presetId: preset.id,
      presetName: preset.name,
      prep: preset.prep,
      work: preset.work,
      rest: preset.rest,
      rounds: preset.rounds,
      sets: preset.sets,
      setRest: preset.setRest,
      cooldown: preset.cooldown,
      startedAt: startedAt,
      endedAt: endedAt,
      totalSeconds: elapsed.inSeconds,
      completed: completed,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'presetId': presetId,
    'presetName': presetName,
    'prep': prep,
    'work': work,
    'rest': rest,
    'rounds': rounds,
    'sets': sets,
    'setRest': setRest,
    'cooldown': cooldown,
    'startedAt': startedAt.toIso8601String(),
    'endedAt': endedAt.toIso8601String(),
    'totalSeconds': totalSeconds,
    'completed': completed,
  };

  factory SessionLog.fromJson(Map<String, dynamic> json) {
    int asInt(Object? value) => value is num ? value.toInt() : 0;
    return SessionLog(
      id: _string(json['id']),
      presetId: _string(json['presetId']),
      presetName: _string(json['presetName'], fallback: 'Tabata'),
      prep: asInt(json['prep']),
      work: asInt(json['work']),
      rest: asInt(json['rest']),
      rounds: asInt(json['rounds']),
      sets: asInt(json['sets']),
      setRest: asInt(json['setRest']),
      cooldown: asInt(json['cooldown']),
      startedAt: _time(json['startedAt']),
      endedAt: _time(json['endedAt']),
      totalSeconds: asInt(json['totalSeconds']),
      completed: json['completed'] == true,
    );
  }
}

String _string(Object? value, {String fallback = ''}) {
  if (value == null) {
    return fallback;
  }
  if (value is String) {
    return value;
  }
  throw const FormatException('expected a string');
}

DateTime _time(Object? value) {
  if (value is! String) {
    throw const FormatException('expected a date');
  }
  return DateTime.parse(value);
}
