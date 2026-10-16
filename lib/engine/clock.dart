import 'plan.dart';

enum CueKind { beep, voice }

class Cue {
  const Cue.beep() : kind = CueKind.beep, text = null;

  const Cue.voice(this.text) : kind = CueKind.voice;

  final CueKind kind;
  final String? text;
}

enum RunStatus { ready, running, paused, finished }

class PhaseLocation {
  const PhaseLocation({
    required this.index,
    required this.phase,
    required this.into,
    required this.remaining,
  });

  final int index;
  final Phase phase;
  final Duration into;
  final Duration remaining;
}

class ClockSample {
  const ClockSample({
    required this.status,
    required this.phase,
    required this.phaseIndex,
    required this.remaining,
    required this.elapsed,
    required this.progress,
    required this.displaySeconds,
    required this.cues,
  });

  final RunStatus status;
  final Phase? phase;
  final int phaseIndex;
  final Duration remaining;
  final Duration elapsed;
  final double progress;
  final int displaySeconds;
  final List<Cue> cues;

  bool get finished => status == RunStatus.finished;
}

/// Monotonic elapsed time.
///
/// [StopwatchTime] keeps advancing while the app is backgrounded, and it does
/// not move when the wall clock is changed.
abstract class MonotonicTime {
  void start();
  void stop();
  void reset();
  Duration get elapsed;
  bool get isRunning;
}

class StopwatchTime implements MonotonicTime {
  StopwatchTime([Stopwatch? watch]) : _watch = watch ?? Stopwatch();

  final Stopwatch _watch;

  @override
  void start() => _watch.start();

  @override
  void stop() => _watch.stop();

  @override
  void reset() => _watch.reset();

  @override
  Duration get elapsed => _watch.elapsed;

  @override
  bool get isRunning => _watch.isRunning;
}

/// A clock tests can move without waiting.
class ManualTime implements MonotonicTime {
  Duration _elapsed = Duration.zero;
  bool _running = false;

  void advance(Duration by) {
    if (_running) {
      _elapsed += by;
    }
  }

  @override
  void start() => _running = true;

  @override
  void stop() => _running = false;

  @override
  void reset() => _elapsed = Duration.zero;

  @override
  Duration get elapsed => _elapsed;

  @override
  bool get isRunning => _running;
}

/// Countdown driven by a monotonic stopwatch.
///
/// Elapsed time is read from the stopwatch, so a locked screen still moves
/// the phase forward and a wall-clock change does not. Pause stops the
/// stopwatch. Resume continues it.
class IntervalClock {
  IntervalClock(this.plan, {MonotonicTime? time})
    : time = time ?? StopwatchTime();

  final IntervalPlan plan;
  final MonotonicTime time;
  bool _started = false;
  int _announced = -1;
  int? _markedSecond;
  bool _finishedCue = false;

  RunStatus get status {
    if (!_started) {
      return RunStatus.ready;
    }
    if (plan.total == Duration.zero || elapsed >= plan.total) {
      return RunStatus.finished;
    }
    if (!time.isRunning) {
      return RunStatus.paused;
    }
    return RunStatus.running;
  }

  void start() {
    time
      ..reset()
      ..start();
    _started = true;
    _announced = -1;
    _markedSecond = null;
    _finishedCue = false;
  }

  void pause() {
    if (status != RunStatus.running) {
      return;
    }
    time.stop();
  }

  void resume() {
    if (status != RunStatus.paused) {
      return;
    }
    time.start();
  }

  Duration get elapsed {
    if (!_started) {
      return Duration.zero;
    }
    var raw = time.elapsed;
    if (raw.isNegative) {
      raw = Duration.zero;
    }
    if (raw > plan.total) {
      return plan.total;
    }
    return raw;
  }

  ClockSample sample() {
    final status = this.status;
    final elapsed = this.elapsed;
    if (plan.phases.isEmpty) {
      return const ClockSample(
        status: RunStatus.finished,
        phase: null,
        phaseIndex: 0,
        remaining: Duration.zero,
        elapsed: Duration.zero,
        progress: 1,
        displaySeconds: 0,
        cues: [],
      );
    }
    final location = locate(plan, elapsed);
    final shown = displaySeconds(location.remaining);
    final cues = <Cue>[];
    if (status == RunStatus.running) {
      if (location.index != _announced) {
        _announced = location.index;
        _markedSecond = null;
        cues.add(const Cue.beep());
        for (final line in voiceLines(location.phase)) {
          cues.add(Cue.voice(line));
        }
      }
      if (shown >= 1 && shown <= 3 && shown != _markedSecond) {
        final opening =
            _markedSecond == null &&
            shown == displaySeconds(location.phase.duration);
        _markedSecond = shown;
        if (!opening) {
          cues.add(const Cue.beep());
        }
      }
    } else if (status == RunStatus.finished && !_finishedCue) {
      _finishedCue = true;
      cues.add(const Cue.beep());
    }
    final durationMs = location.phase.duration.inMilliseconds;
    final progress = durationMs == 0
        ? 1.0
        : (location.into.inMilliseconds / durationMs).clamp(0.0, 1.0);
    return ClockSample(
      status: status,
      phase: location.phase,
      phaseIndex: location.index,
      remaining: location.remaining,
      elapsed: elapsed,
      progress: progress,
      displaySeconds: shown,
      cues: cues,
    );
  }
}

PhaseLocation locate(IntervalPlan plan, Duration elapsed) {
  var cursor = Duration.zero;
  for (var i = 0; i < plan.phases.length; i++) {
    final phase = plan.phases[i];
    final end = cursor + phase.duration;
    final last = i == plan.phases.length - 1;
    if (elapsed < end || last) {
      var into = elapsed - cursor;
      if (into.isNegative) {
        into = Duration.zero;
      }
      if (into > phase.duration) {
        into = phase.duration;
      }
      return PhaseLocation(
        index: i,
        phase: phase,
        into: into,
        remaining: phase.duration - into,
      );
    }
    cursor = end;
  }
  throw StateError('Interval plan has no phases');
}
