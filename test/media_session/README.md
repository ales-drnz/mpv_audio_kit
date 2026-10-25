# Media session tests

The OS media session has three layers of tests:

1. The Dart side (`MediaSessionController`, `MediaSessionChannel`, the
   artwork fetcher), in the `*_test.dart` files of this directory.
2. The native plugins on their own: the Swift suite in `darwin/` and the
   plugin's JVM tests in `android/src/test`.
3. The whole path through a running app, from `Player` to what the OS
   holds, in `test_app/integration_test/`.

## Layout

```
test/media_session/
├── README.md                  this file
├── run.sh                     runs the native suites this host can run
├── *_test.dart                the Dart side, under flutter test
└── darwin/                    macOS and iOS (Swift)
    ├── main.swift             the scenarios
    └── run.sh                 compiles and runs them (macOS host only)

test_app/integration_test/
├── media_session_test.dart    every platform, through the plugin's probe
├── linux_mpris_test.dart      Linux, read from the session bus with gdbus
├── windows_smtc_test.dart     Windows, read back from the SMTC
└── windows_gsmtc_spike_test.dart
                               Windows, through the API of the media
                               flyout (a spike that does not gate)
```

## What runs where

| Platform | Dart side | Native suite | Through the app |
|----------|-----------|--------------|-----------------|
| Linux | Test (Linux) | none | Build Linux: media_session_test and linux_mpris_test, under xvfb-run and dbus-run-session |
| Windows | Windows per file (check) | none | Build Windows: media_session_test and windows_smtc_test |
| macOS | Test (macOS) | Build macOS (SwiftPM): `darwin/run.sh` | none |
| iOS | | the Swift of `darwin/` is shared | the simulator job of the check |
| Android | | Build Android: the JVM tests | the emulator jobs of the check |

The Test and Build jobs are in `.github/workflows/ci.yml`. The check is
`check-mpv-audio-kit.yml` in libmpv-scripts.

## The Dart side

Most files build a `MediaSessionController` against a fake channel and
fake input streams, and run on any host. They pin what lives in Dart.
The published play state follows the `playWhenReady` intent, so a seek
never shows a pause. `playing` only drives `actualPlaying`, which tells
the native side when to advance the position. A seek landing syncs the
position. A cover URL is downloaded or read in Dart and sent as bytes:
no URL reaches a plugin.

`media_session_root_isolate_test` and `set_media_session_race_test`
create real players, so they need the bundled libmpv.

```
flutter test test/media_session/
```

## The Swift suite (darwin)

`darwin/main.swift` is a `swiftc` executable, not an XCTest bundle. It
links against the `FlutterMacOS.framework` of test_app's macOS build,
creates a real `MediaSessionPlugin`, drives it through the method channel
and the scrub entry point, and asserts against
`MPNowPlayingInfoCenter.default()` and `MPRemoteCommandCenter.shared()`,
the objects the OS reads. The plugin publishes each call synchronously.

It needs test_app's macOS build first:

```
(cd test_app && flutter build macos --debug)
bash test/media_session/darwin/run.sh
```

## Through the app

The integration tests open a real file in a real `Player`, publish it,
and read back what the platform holds.

- `media_session_test` reads the plugin's probe: `debugNowPlayingInfo` on
  Apple, `debugMediaSessionState` on Android, Windows and Linux.
- `linux_mpris_test` reads `org.mpris.MediaPlayer2.<app>.instance<pid>`
  with gdbus, as a desktop shell does, and sends Play, Pause, Seek and
  SetPosition back through the bus to the player.
- `windows_smtc_test` reads the values back from the
  SystemMediaTransportControls of the process.

On Linux they need a session bus and gdbus:

```
cd test_app
dbus-run-session -- flutter test -d linux integration_test/linux_mpris_test.dart
```

## Adding a native suite

A suite for another platform goes in `test/media_session/<os>/`, with the
scenarios of `darwin/main.swift` and a `run.sh` that builds and runs
them. That `run.sh` exits 2 with a message on the wrong host. The
top-level `run.sh` already calls `linux/run.sh` and `windows/run.sh` when
they exist.
