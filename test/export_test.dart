import 'package:flutter_test/flutter_test.dart';
import 'package:tabata/export/format.dart';
import 'package:tabata/models/preset.dart';
import 'package:tabata/models/session_log.dart';

void main() {
  final morning = DateTime(2026, 10, 16, 8, 41);
  final evening = DateTime(2026, 10, 16, 18, 2);
  final monday = DateTime(2026, 10, 12, 7, 5);

  SessionLog log({
    required DateTime start,
    required String name,
    required int totalSeconds,
    required bool completed,
    bool interrupted = false,
    int prep = 10,
    int setRest = 0,
    int cooldown = 0,
  }) {
    return SessionLog.capture(
      preset: Preset.classic.copyWith(
        name: name,
        prep: prep,
        setRest: setRest,
        cooldown: cooldown,
      ),
      startedAt: start,
      endedAt: start.add(Duration(seconds: totalSeconds)),
      elapsed: Duration(seconds: totalSeconds),
      completed: completed,
      interrupted: interrupted,
    );
  }

  final classic = log(
    start: morning,
    name: 'Classic',
    totalSeconds: 240,
    completed: true,
  );
  final stopped = log(
    start: evening,
    name: 'Short',
    totalSeconds: 65,
    completed: false,
    prep: 0,
    setRest: 60,
    cooldown: 30,
  );

  test('session export matches the golden text', () {
    expect(exportSession(classic), '''
# Tabata
Session · Fri 16 Oct 2026

## 08:41 · Classic
Preset: Classic
Prep: 10s
Work: 20s
Rest: 10s
Rounds: 8
Sets: 1
Rest between sets: 0s
Cooldown: 0s
Total time: 4:00
Completed
''');
  });

  test('day export matches the golden text', () {
    expect(exportDay(morning, [stopped, classic]), '''
# Tabata
Day · Fri 16 Oct 2026

## 08:41 · Classic
Preset: Classic
Prep: 10s
Work: 20s
Rest: 10s
Rounds: 8
Sets: 1
Rest between sets: 0s
Cooldown: 0s
Total time: 4:00
Completed

## 18:02 · Short
Preset: Short
Prep: 0s
Work: 20s
Rest: 10s
Rounds: 8
Sets: 1
Rest between sets: 60s
Cooldown: 30s
Total time: 1:05
Stopped early
''');
  });

  test('week export matches the golden text', () {
    final earlier = log(
      start: monday,
      name: 'Classic',
      totalSeconds: 240,
      completed: true,
    );
    expect(exportWeek(morning, [classic, earlier, stopped]), '''
# Tabata
Week · 12–18 Oct 2026

## Mon 12 Oct 2026
### 07:05 · Classic
Preset: Classic
Prep: 10s
Work: 20s
Rest: 10s
Rounds: 8
Sets: 1
Rest between sets: 0s
Cooldown: 0s
Total time: 4:00
Completed

## Fri 16 Oct 2026
### 08:41 · Classic
Preset: Classic
Prep: 10s
Work: 20s
Rest: 10s
Rounds: 8
Sets: 1
Rest between sets: 0s
Cooldown: 0s
Total time: 4:00
Completed

### 18:02 · Short
Preset: Short
Prep: 0s
Work: 20s
Rest: 10s
Rounds: 8
Sets: 1
Rest between sets: 60s
Cooldown: 30s
Total time: 1:05
Stopped early
''');
  });

  test('an interrupted session exports its own status', () {
    final session = log(
      start: morning,
      name: 'Classic',
      totalSeconds: 200,
      completed: false,
      interrupted: true,
    );
    expect(session.statusLabel, 'Interrupted');
    for (final text in [
      exportSession(session),
      exportDay(morning, [session]),
      exportWeek(morning, [session]),
    ]) {
      expect(text, contains('Interrupted'));
      expect(text, isNot(contains('Stopped early')));
      expect(text, isNot(contains('Completed')));
    }
  });

  test('a week that crosses months uses both month names', () {
    final anchor = DateTime(2026, 4, 1);
    expect(
      fmtRange(
        weekStart(anchor),
        weekStart(anchor).add(const Duration(days: 6)),
      ),
      '30 Mar – 5 Apr 2026',
    );
  });
}
