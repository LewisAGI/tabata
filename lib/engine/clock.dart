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

/// Countdown driven by wall-clock timestamps.
///
/// Pause stores the remaining slice. A jump in [DateTime] (the app was
/// suspended) lands on the phase that contains that instant.
class IntervalClock {
  IntervalClock(this.plan);

  final IntervalPlan plan;
  DateTime? startedAt;
  Duration pausedAccumulated = Duration.zero;
  DateTime? pausedAt;
  int _announced = -1;
  int? _markedSecond;
  bool _finishedCue = false;

  RunStatus statusAt(DateTime now) {
    if (startedAt == null) {
      return RunStatus.ready;
    }
    if (pausedAt != null) {
      return RunStatus.paused;
    }
    if (plan.total == Duration.zero || elapsed(now) >= plan.total) {
      return RunStatus.finished;
    }
    return RunStatus.running;
  }

  void start(DateTime now) {
    startedAt = now;
    pausedAccumulated = Duration.zero;
    pausedAt = null;
    _announced = -1;
    _markedSecond = null;
    _finishedCue = false;
  }

  void pause(DateTime now) {
    if (statusAt(now) != RunStatus.running) {
      return;
    }
    pausedAt = now;
  }

  void resume(DateTime now) {
    final paused = pausedAt;
    if (paused == null) {
      return;
    }
    pausedAccumulated += now.difference(paused);
    pausedAt = null;
  }

  Duration elapsed(DateTime now) {
    final start = startedAt;
    if (start == null) {
      return Duration.zero;
    }
    final end = pausedAt ?? now;
    var raw = end.difference(start) - pausedAccumulated;
    if (raw.isNegative) {
      raw = Duration.zero;
    }
    if (raw > plan.total) {
      return plan.total;
    }
    return raw;
  }

  ClockSample sample(DateTime now) {
    final status = statusAt(now);
    final elapsed = this.elapsed(now);
    if (plan.phases.isEmpty) {
      return ClockSample(
        status: RunStatus.finished,
        phase: null,
        phaseIndex: 0,
        remaining: Duration.zero,
        elapsed: Duration.zero,
        progress: 1,
        displaySeconds: 0,
        cues: const [],
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
