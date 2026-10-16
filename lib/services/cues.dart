import '../engine/clock.dart';

abstract class CueSink {
  /// Fired when an audio interruption ends and the silent loop should resume.
  void Function()? onInterruptionEnd;

  Future<void> begin();
  Future<void> end();
  Future<void> beep();
  Future<void> speak(String text);
}

class SilentCues implements CueSink {
  @override
  void Function()? onInterruptionEnd;

  int beeps = 0;
  final List<String> spoken = [];
  bool bed = false;

  @override
  Future<void> begin() async {
    bed = true;
  }

  @override
  Future<void> end() async {
    bed = false;
  }

  @override
  Future<void> beep() async {
    beeps += 1;
  }

  @override
  Future<void> speak(String text) async {
    spoken.add(text);
  }
}

Future<void> playCues(CueSink sink, List<Cue> cues) async {
  final voices = <String>[];
  Future<void> flush() async {
    if (voices.isEmpty) {
      return;
    }
    final line = voices.join(', ');
    voices.clear();
    await sink.speak(line);
  }

  for (final cue in cues) {
    if (cue.kind == CueKind.beep) {
      await flush();
      await sink.beep();
    } else if (cue.text != null) {
      voices.add(cue.text!);
    }
  }
  await flush();
}
