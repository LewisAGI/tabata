import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tabata/data/store.dart';
import 'package:tabata/models/preset.dart';
import 'package:tabata/models/session_log.dart';

void main() {
  test('preset crud survives a new store on the same box', () async {
    final box = MemoryBox();
    final store = TabataStore(box);
    await store.ensureSeed();
    expect(store.presets().map((preset) => preset.name), ['Classic']);

    await store.ensureSeed();
    expect(store.presets(), hasLength(1));

    final extra = Preset.draft().copyWith(
      name: '  Short  ',
      work: 10,
      rest: 5,
      rounds: 4,
    );
    await store.savePreset(extra);
    expect(store.presets().map((preset) => preset.name), ['Classic', 'Short']);

    await store.savePreset(extra.copyWith(name: 'Tiny', rest: 0));
    final updated = store.presets()[1];
    expect(updated.name, 'Tiny');
    expect(updated.work, 10);
    expect(updated.rest, 0);
    expect(updated.id, extra.id);

    await store.deletePreset('classic');
    expect(store.presets().map((preset) => preset.id), [extra.id]);

    final reloaded = TabataStore(box);
    expect(reloaded.presets().single.name, 'Tiny');
    expect(reloaded.presets().single.cardLine, '10/0 × 4');
  });

  test('presets are not capped', () async {
    final store = TabataStore(MemoryBox());
    for (var i = 0; i < 40; i++) {
      await store.savePreset(
        Preset(
          id: 'p$i',
          name: 'P$i',
          prep: 0,
          work: 20,
          rest: 10,
          rounds: 8,
          sets: 1,
          setRest: 0,
          cooldown: 0,
        ),
      );
    }
    expect(store.presets(), hasLength(40));
    expect(store.presets().last.name, 'P39');
  });

  test('session log appends and reloads', () async {
    final box = MemoryBox();
    final store = TabataStore(box);
    final started = DateTime(2026, 10, 16, 8, 41);
    await store.addSession(
      SessionLog.capture(
        preset: Preset.classic,
        startedAt: started,
        endedAt: started.add(const Duration(minutes: 4)),
        elapsed: const Duration(minutes: 4),
        completed: true,
      ),
    );
    await store.addSession(
      SessionLog.capture(
        preset: Preset.classic.copyWith(name: 'Short'),
        startedAt: started.add(const Duration(hours: 2)),
        endedAt: started.add(const Duration(hours: 2, seconds: 65)),
        elapsed: const Duration(seconds: 65),
        completed: false,
      ),
    );
    final again = TabataStore(box).sessions();
    expect(again, hasLength(2));
    expect(again.first.completed, isTrue);
    expect(again.first.totalSeconds, 240);
    expect(again.last.statusLabel, 'Stopped early');
    expect(again.last.presetName, 'Short');
  });

  test('broken json reads as an empty list', () {
    final box = MemoryBox()..data[TabataStore.presetsKey] = '{';
    expect(TabataStore(box).presets(), isEmpty);
  });

  test('bad preset and session entries are skipped', () {
    final started = DateTime(2026, 10, 16, 8, 41);
    final session = SessionLog.capture(
      preset: Preset.classic,
      startedAt: started,
      endedAt: started.add(const Duration(minutes: 4)),
      elapsed: const Duration(minutes: 4),
      completed: true,
    );
    final box = MemoryBox()
      ..data[TabataStore.presetsKey] = jsonEncode([
        {'id': 7, 'name': 'Broken'},
        Preset.classic.toJson(),
        {'id': 'x', 'name': 3},
        'nope',
      ])
      ..data[TabataStore.sessionsKey] = jsonEncode([
        {...session.toJson(), 'startedAt': 12},
        session.toJson(),
        {
          'id': 'bad',
          'presetId': 'p',
          'presetName': 'P',
          'startedAt': 'nope',
          'endedAt': 'also-nope',
        },
        {'id': 1, 'startedAt': started.toIso8601String()},
      ]);
    final store = TabataStore(box);
    expect(store.presets().map((preset) => preset.name), ['Classic']);
    expect(store.sessions(), hasLength(1));
    expect(store.sessions().single.presetName, 'Classic');
    expect(store.sessions().single.totalSeconds, 240);
  });
}
