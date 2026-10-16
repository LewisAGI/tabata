import 'dart:async';

import 'package:flutter/material.dart';

import '../engine/clock.dart';
import '../engine/plan.dart';
import '../models/preset.dart';
import '../models/session_log.dart';
import '../services/cues.dart';
import '../services/wake.dart';
import '../widgets/complete_sheet.dart';
import '../widgets/run_view.dart';
import 'scope.dart';

class RunScreen extends StatefulWidget {
  const RunScreen({super.key, required this.preset, this.now});

  final Preset preset;
  final DateTime Function()? now;

  @override
  State<RunScreen> createState() => _RunScreenState();
}

class _RunScreenState extends State<RunScreen> with WidgetsBindingObserver {
  late final DateTime Function() _now;
  late final IntervalClock _clock;
  late final CueSink _cues;
  late final WakeLock _wake;
  ClockSample? _sample;
  Timer? _ticker;
  Future<void> _pending = Future<void>.value();
  var _done = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final scope = TabataScope.read(context);
    _cues = scope.cues;
    _wake = scope.wake;
    _now = widget.now ?? DateTime.now;
    _clock = IntervalClock(IntervalPlan.fromPreset(widget.preset));
    _clock.start(_now());
    _sample = _clock.sample(_now());
    _enqueue(_sample!.cues);
    unawaited(_cues.begin());
    unawaited(_wake.set(running: true, foreground: true));
    _startTicker();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    unawaited(_cues.end());
    unawaited(_wake.set(running: false, foreground: false));
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final foreground = state == AppLifecycleState.resumed;
    final running = _clock.pausedAt == null && !_done;
    unawaited(_wake.set(running: running, foreground: foreground));
    if (foreground && !_done) {
      _onTick();
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) => _onTick(),
    );
  }

  void _onTick() {
    if (_done || !mounted) {
      return;
    }
    final next = _clock.sample(_now());
    setState(() => _sample = next);
    if (next.status == RunStatus.finished) {
      unawaited(_finish(completed: true, cues: next.cues));
    } else {
      _enqueue(next.cues);
    }
  }

  void _enqueue(List<Cue> cues) {
    if (cues.isEmpty) {
      return;
    }
    _pending = _pending.then((_) => playCues(_cues, cues));
  }

  Future<void> _togglePause() async {
    if (_done) {
      return;
    }
    final now = _now();
    if (_clock.pausedAt != null) {
      _clock.resume(now);
      unawaited(_cues.begin());
      unawaited(_wake.set(running: true, foreground: true));
      _startTicker();
    } else {
      _clock.pause(now);
      _ticker?.cancel();
      unawaited(_cues.end());
      unawaited(_wake.set(running: false, foreground: true));
    }
    _onTick();
  }

  Future<void> _stop() async {
    if (_done) {
      return;
    }
    _clock.pause(_now());
    await _finish(completed: false, cues: const []);
  }

  Future<void> _finish({
    required bool completed,
    required List<Cue> cues,
  }) async {
    if (_done) {
      return;
    }
    _done = true;
    _ticker?.cancel();
    _enqueue(cues);
    await _pending;
    await _cues.end();
    await _wake.set(running: false, foreground: false);
    final end = _now();
    final start = _clock.startedAt ?? end;
    final log = SessionLog.capture(
      preset: widget.preset,
      startedAt: start,
      endedAt: end,
      elapsed: _clock.elapsed(end),
      completed: completed,
    );
    if (!mounted) {
      return;
    }
    final store = TabataScope.of(context).store;
    await store.addSession(log);
    if (!mounted) {
      return;
    }
    final history = store.sessions();
    await showCompleteSheet(context, log: log, history: history);
    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sample = _sample;
    final phase = sample?.phase;
    final kind = phase?.kind ?? PhaseKind.prep;
    return Scaffold(
      backgroundColor: tintFor(kind),
      body: RunView(
        label: phase == null ? 'PREP' : phaseLabel(phase),
        seconds: sample?.displaySeconds ?? 0,
        progress: sample?.progress ?? 0,
        elapsed: sample?.elapsed ?? Duration.zero,
        paused: sample?.status == RunStatus.paused,
        tint: tintFor(kind),
        ring: ringFor(kind),
        onPause: () => unawaited(_togglePause()),
        onStop: () => unawaited(_stop()),
      ),
    );
  }
}
