# Media-session tests

This directory holds **native, per-platform** tests for the OS
media-session bridge implementations. The Dart-side wrapper logic
(`MediaSessionController` + `MediaSessionChannel`) is exercised by
`*_test.dart` files **at this level** that run under `flutter test`
like any other Dart unit test; the native subdirectories below
build and run the platform-native plugin code directly so we can
assert on what `MPNowPlayingInfoCenter` / `SMTC` / `MPRIS` / Android
`MediaSession` actually publish under specific event sequences.

## Layout

```
test/media_session/
├── README.md                    — this file
├── run.sh                       — OS-aware orchestrator, runs every
│                                  native suite available on the host
├── controller_test.dart         — Dart unit tests for
│                                  MediaSessionController (any host)
├── darwin/                      — macOS + iOS (Swift)
│   ├── main.swift               — test scenarios
│   └── run.sh                   — compiles + executes the Swift suite
│                                  (macOS host only)
└── (future)
    ├── linux/                   — MPRIS (likely C++/GLib)
    ├── windows/                 — SMTC (likely C++/WinRT)
    └── android/                 — MediaSession (likely Kotlin via Gradle)
```

## What runs where

| Host    | Suite                                  |
|---------|----------------------------------------|
| macOS   | `flutter test` + `darwin/run.sh`       |
| Linux   | `flutter test` + (future) `linux/`     |
| Windows | `flutter test` + (future) `windows/`   |
| Android | Cannot run native suites from a host — covered by `test_app/integration_test/` on an emulator/device. |

The Dart `*_test.dart` files run on every host because they only
exercise the Dart-side controller. They do **not** depend on a real
mpv or platform channel — they stub `MediaSessionChannel` and drive
the controller's input streams directly.

## How the Swift (darwin) suite works

`darwin/main.swift` is a `swiftc`-compiled executable, not an
XCTest bundle. It links against the `FlutterMacOS.framework` shipped
inside test_app's macOS build output, instantiates a real
`MediaSessionPlugin`, drives it through the method channel
(`enable` / `updatePlayback` / `disable`) plus the scrub entry point
(`handleScrub`), and asserts against the real
`MPNowPlayingInfoCenter.default()` and `MPRemoteCommandCenter.shared()`
— the same process singletons the OS reads. The plugin is a stateless
renderer, so each call publishes synchronously; there is no timer or
seek state machine to spin the run loop for.

CI runs it in the macOS (SwiftPM) build job of `.github/workflows/ci.yml`,
right after that job's `flutter build macos --debug`.

The suite expects test_app's macOS build artifacts to exist:

```
(cd test_app && flutter build macos --debug)
```

Then:

```
bash test/media_session/darwin/run.sh
# or
bash test/media_session/run.sh   # auto-detects host OS
```

## How the Dart controller tests work

The Dart tests in `test/media_session/*_test.dart` construct a
`MediaSessionController` against a fake channel and fake input
streams, then assert the one behaviour that lives purely in Dart:
suppressing the transient `playing=false` that mpv emits while
seeking (core-idle flips), so the OS never shows a spurious pause
frame mid-scrub. The forced `seekCompleted` push republishes the
held play intent rather than that transient.

Run with the rest of the package tests:

```
flutter test test/media_session/
```

## Adding a new platform suite

When a new OS gains a media-session implementation:

1. Add a new subdir `test/media_session/<os>/`.
2. Add an `<os>/main.<ext>` source that mirrors the scenarios in
   `darwin/main.swift`.
3. Add `<os>/run.sh` that compiles + runs the suite. It must
   guard `uname -s` (or equivalent) and exit `2` with a clear
   message when invoked on the wrong host.
4. The top-level `run.sh` already routes `uname -s` to the right
   subdir — extend the `case` if you need additional mapping.
5. Update this README's "What runs where" table.

Keep the scenarios in lockstep across platforms: each new
scenario added to `darwin/main.swift` should be added to its
counterparts in every other native suite, so the OS bridges stay
behaviorally identical.
