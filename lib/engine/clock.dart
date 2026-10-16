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

/// Monotonic elapsed time for foreground ticks.
///
/// [StopwatchTime] does not move when the wall clock is changed. On iOS it
/// also pauses while the device sleeps; [IntervalClock.onAppResumed] fills
/// that gap from wall time.
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

/// Countdown driven by a monotonic stopwatch, with a wall-clock catch-up.
///
/// Foreground ticks come from the stopwatch, so changing the phone's clock
/// does not move the phase. On iOS that stopwatch is `CLOCK_MONOTONIC_RAW`,
/// which pauses while the device sleeps. If the silent audio loop stops, the
/// app suspends and the stopwatch falls behind. [onAppResumed] compares wall
/// time since the last [start] or [resume] and, when wall time is more than
/// a second ahead, adds that gap.
class IntervalClock {
  IntervalClock(this.plan, {MonotonicTime? time, DateTime Function()? now})
    : time = time ?? StopwatchTime(),
      _now = now ?? DateTime.now;

  final IntervalPlan plan;
  final MonotonicTime time;
  final DateTime Function() _now;

  /// Wall time is ignored until it leads the stopwatch by more than this.
  static const catchUpThreshold = Duration(seconds: 1);

  bool _started = false;
  DateTime? _wallAnchor;
  Duration _monoAtAnchor = Duration.zero;
  Duration _slept = Duration.zero;
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
    _slept = Duration.zero;
    _announced = -1;
    _markedSecond = null;
    _finishedCue = false;
    _markAnchor();
  }

  void pause() {
    if (status != RunStatus.running) {
      return;
    }
    time.stop();
    _wallAnchor = null;
  }

  void resume() {
    if (status != RunStatus.paused) {
      return;
    }
    time.start();
    _markAnchor();
  }

  /// Call when the app returns to the foreground.
  ///
  /// Adds the time the stopwatch missed while the device was asleep.
  void onAppResumed() {
    if (status != RunStatus.running) {
      return;
    }
    final anchor = _wallAnchor;
    if (anchor == null) {
      return;
    }
    var monoDelta = time.elapsed - _monoAtAnchor;
    if (monoDelta.isNegative) {
      monoDelta = Duration.zero;
    }
    final gap = _now().difference(anchor) - monoDelta;
    if (gap > catchUpThreshold) {
      _slept += gap;
    }
    _markAnchor();
  }

  void _markAnchor() {
    _wallAnchor = _now();
    _monoAtAnchor = time.elapsed;
  }

  Duration get elapsed {
    if (!_started) {
      return Duration.zero;
    }
    var raw = time.elapsed + _slept;
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
