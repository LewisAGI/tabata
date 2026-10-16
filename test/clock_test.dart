import 'package:flutter_test/flutter_test.dart';
import 'package:tabata/engine/clock.dart';
import 'package:tabata/engine/plan.dart';
import 'package:tabata/models/preset.dart';

void main() {
  const preset = Preset(
    id: 't',
    name: 'T',
    prep: 0,
    work: 20,
    rest: 10,
    rounds: 2,
    sets: 1,
    setRest: 0,
    cooldown: 0,
  );

  final t0 = DateTime(2026, 10, 16, 8);

  IntervalPlan plan() => IntervalPlan.fromPreset(preset);

  test('pause freezes the clock and resume follows wall time', () {
    final clock = IntervalClock(plan());
    clock.start(t0);

    final opened = clock.sample(t0);
    expect(opened.displaySeconds, 20);
    expect(opened.cues.map((cue) => cue.text), [null, 'round 1 of 2', 'work']);

    final atThree = clock.sample(t0.add(const Duration(seconds: 17)));
    expect(atThree.displaySeconds, 3);
    expect(atThree.remaining, const Duration(seconds: 3));
    expect(atThree.cues, hasLength(1));
    expect(atThree.cues.single.kind, CueKind.beep);

    final stillThree = clock.sample(
      t0.add(const Duration(milliseconds: 17500)),
    );
    expect(stillThree.displaySeconds, 3);
    expect(stillThree.cues, isEmpty);

    final atTwo = clock.sample(t0.add(const Duration(seconds: 18)));
    expect(atTwo.displaySeconds, 2);
    expect(atTwo.cues.single.kind, CueKind.beep);

    clock.pause(t0.add(const Duration(seconds: 18)));
    final held = clock.sample(t0.add(const Duration(seconds: 100)));
    expect(held.status, RunStatus.paused);
    expect(held.elapsed, const Duration(seconds: 18));
    expect(held.displaySeconds, 2);
    expect(held.phaseIndex, 0);
    expect(held.cues, isEmpty);

    clock.resume(t0.add(const Duration(seconds: 100)));
    final after = clock.sample(t0.add(const Duration(seconds: 101)));
    expect(after.status, RunStatus.running);
    expect(after.elapsed, const Duration(seconds: 19));
    expect(after.displaySeconds, 1);
    expect(after.cues.single.kind, CueKind.beep);
  });

  test('a background jump lands on the phase for that wall clock', () {
    final clock = IntervalClock(plan());
    clock.start(t0);

    final landed = clock.sample(t0.add(const Duration(seconds: 25)));
    expect(landed.status, RunStatus.running);
    expect(landed.phaseIndex, 1);
    expect(landed.phase!.kind, PhaseKind.rest);
    expect(landed.remaining, const Duration(seconds: 5));
    expect(landed.cues.map((cue) => cue.text), [null, 'rest']);

    final next = clock.sample(t0.add(const Duration(seconds: 32)));
    expect(next.phaseIndex, 2);
    expect(next.phase!.round, 2);
    expect(next.displaySeconds, 18);
    expect(next.cues.map((cue) => cue.text), [null, 'round 2 of 2', 'work']);
  });

  test('jumping past the end finishes once', () {
    final clock = IntervalClock(plan());
    clock.start(t0);
    final done = clock.sample(t0.add(const Duration(seconds: 50)));
    expect(done.status, RunStatus.finished);
    expect(done.elapsed, plan().total);
    expect(done.cues, hasLength(1));
    expect(done.cues.single.kind, CueKind.beep);

    final again = clock.sample(t0.add(const Duration(seconds: 80)));
    expect(again.status, RunStatus.finished);
    expect(again.cues, isEmpty);
    expect(again.elapsed, const Duration(seconds: 50));
  });
}
