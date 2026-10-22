import 'package:flutter_test/flutter_test.dart';
import 'package:tabata/services/device_cues.dart';

void main() {
  test('an interruption end calls onInterruptionEnd', () {
    var resumed = 0;
    var ended = 0;

    handleAudioInterruption(
      begin: true,
      bedOn: true,
      resumeBed: () => resumed += 1,
      onInterruptionEnd: () => ended += 1,
    );
    expect(resumed, 0);
    expect(ended, 0);

    handleAudioInterruption(
      begin: false,
      bedOn: false,
      resumeBed: () => resumed += 1,
      onInterruptionEnd: () => ended += 1,
    );
    expect(resumed, 0);
    expect(ended, 0);

    handleAudioInterruption(
      begin: false,
      bedOn: true,
      resumeBed: () => resumed += 1,
      onInterruptionEnd: () => ended += 1,
    );
    expect(resumed, 1);
    expect(ended, 1);

    handleAudioInterruption(
      begin: false,
      bedOn: true,
      resumeBed: () => resumed += 1,
      onInterruptionEnd: null,
    );
    expect(resumed, 2);
    expect(ended, 1);
  });
}
