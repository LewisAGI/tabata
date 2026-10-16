# Tabata

An offline interval timer for the phone. Presets, the countdown, beeps, spoken cues, and the session log stay on the device.

There is no account, no cloud, and no network call.

## Install on an iPhone

A Mac, Flutter 3.47 stable, and Xcode. Plug the iPhone in, unlock it, and tap Trust.

Clone onto a normal local disk. Do not put the project in iCloud Drive, in Documents if that folder is synced, or in a Grok folder. Flutter's build tools fail on those paths.

```bash
git clone https://github.com/LewisAGI/tabata.git
cd tabata
flutter pub get
flutter run --release
```

`flutter run --release` builds and installs Tabata on the plugged-in iPhone. The bundle id is `com.lewisagi.tabata`.

### Signing team

If the build stops on a signing error, open `ios/Runner.xcworkspace` in Xcode, select the Runner target, and set Signing & Capabilities → Team to your Apple ID. Then run `flutter run --release` again.

A free Apple ID can install the app on your own phone. That install lasts about seven days, then you run the same command again.

## What you get

Saved presets: name, prep, work, rest, rounds, sets, rest between sets, and cooldown. There is no cap.

The running screen is a large countdown. The background tints for work and rest. A beep sounds on each phase change and on the last three seconds. Voice cues say "round 3 of 8" and "work", or "rest".

The countdown stores a wall-clock end time, so locking the phone does not drift it. iOS `UIBackgroundModes` includes `audio`, and the audio session is playback mixed with whatever else is playing. A quiet loop keeps the process awake so the beeps and the voice still fire with the screen locked. `wakelock_plus` holds the screen on only while the timer is running in the foreground.

Finished and stopped sessions are logged on the phone. Copy, Grok, and Share hand over one plain-text block for a session, a day, or a week: heading, date, preset, work, rest, rounds, sets, total time, and completed or stopped early. Paste that block into any AI. Share uses the system sheet, and on iPad the popover is anchored to the button.

## Tests

```bash
flutter analyze
flutter test
```

Screenshots in `docs/screenshots` are rendered with Roboto, which ships in the app (Apache-2.0, see `assets/fonts/LICENSE-roboto.txt`).
