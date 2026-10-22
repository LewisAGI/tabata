import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';

import 'cues.dart';

/// Beeps, spoken cues, and a silent loop that keeps iOS from suspending the
/// timer. The loop is digital silence so it does not hiss over other audio.
/// The session is playback mixed with whatever else is playing.
class DeviceCues implements CueSink {
  @override
  void Function()? onInterruptionEnd;

  final AudioPlayer _beep = AudioPlayer();
  final AudioPlayer _bed = AudioPlayer();
  final FlutterTts _tts = FlutterTts();
  var _ready = false;
  var _bedOn = false;
  var _listening = false;

  Future<void> _ensure() async {
    if (_ready) {
      return;
    }
    final session = await AudioSession.instance;
    await session.configure(
      const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionCategoryOptions:
            AVAudioSessionCategoryOptions.mixWithOthers,
        avAudioSessionMode: AVAudioSessionMode.defaultMode,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          usage: AndroidAudioUsage.media,
        ),
        androidAudioFocusGainType:
            AndroidAudioFocusGainType.gainTransientMayDuck,
        androidWillPauseWhenDucked: false,
      ),
    );
    await session.setActive(true);
    await _tts.setSharedInstance(true);
    await _tts.setIosAudioCategory(IosTextToSpeechAudioCategory.playback, [
      IosTextToSpeechAudioCategoryOptions.mixWithOthers,
    ]);
    await _tts.awaitSpeakCompletion(true);
    await _tts.setSpeechRate(0.48);
    await _tts.setVolume(1);
    await _beep.setAsset('assets/audio/beep.wav');
    await _beep.setVolume(1);
    await _bed.setAsset('assets/audio/bed.wav');
    await _bed.setVolume(0.35);
    await _bed.setLoopMode(LoopMode.one);
    if (!_listening) {
      _listening = true;
      session.interruptionEventStream.listen(_onInterruption);
    }
    _ready = true;
  }

  /// A phone call, Siri, or an alarm stops the silent loop. When that
  /// interruption ends, start it again so iOS does not suspend the timer.
  void _onInterruption(AudioInterruptionEvent event) {
    if (event.begin || !_bedOn) {
      return;
    }
    unawaited(_resumeBed());
    onInterruptionEnd?.call();
  }

  Future<void> _resumeBed() async {
    try {
      final session = await AudioSession.instance;
      await session.setActive(true);
      unawaited(_bed.play());
    } on Object {
      // The next foreground resume calls [begin] again.
    }
  }

  @override
  Future<void> begin() async {
    try {
      await _ensure();
      _bedOn = true;
      if (_bed.playing) {
        return;
      }
      unawaited(_bed.play());
    } on Object {
      _ready = false;
      _bedOn = false;
    }
  }

  @override
  Future<void> end() async {
    try {
      _bedOn = false;
      await _bed.stop();
      await _tts.stop();
    } on Object {
      // The player can already be released.
    }
  }

  @override
  Future<void> beep() async {
    try {
      await _ensure();
      await _beep.seek(Duration.zero);
      await _beep.play();
    } on Object {
      // A missed beep should not stop the clock.
    }
  }

  @override
  Future<void> speak(String text) async {
    try {
      await _ensure();
      await _tts.speak(text);
    } on Object {
      // Voice is best-effort if the synth is busy.
    }
  }
}
