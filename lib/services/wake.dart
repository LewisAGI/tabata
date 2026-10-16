import 'package:wakelock_plus/wakelock_plus.dart';

abstract class WakeLock {
  Future<void> set({required bool running, required bool foreground});
}

class NoWake implements WakeLock {
  bool enabled = false;

  @override
  Future<void> set({required bool running, required bool foreground}) async {
    enabled = running && foreground;
  }
}

class PlusWake implements WakeLock {
  @override
  Future<void> set({required bool running, required bool foreground}) async {
    try {
      if (running && foreground) {
        await WakelockPlus.enable();
      } else {
        await WakelockPlus.disable();
      }
    } on Object {
      // The screen lock is optional. The clock still uses wall time.
    }
  }
}
