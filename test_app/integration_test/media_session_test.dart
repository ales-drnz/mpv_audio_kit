// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// End-to-end media-session test on the REAL OS. Runs the full path —
// Dart `Player` → `MediaSessionController` → method channel → native
// plugin → the OS media session — then reads the OS-facing state back
// through a native debug probe. A green run means the running app
// publishes exactly this state to the OS — there is no "different world"
// between the tests and the app.
//
// Two platform-gated groups share this file:
//  - Apple (iOS / macOS): `MediaSessionPlugin` → `MPNowPlayingInfoCenter`,
//    read back via `debugNowPlayingInfo`.
//  - Android: `MediaSessionManager` → Media3 `MediaSession` /
//    `SimpleBasePlayer`, read back via `debugMediaSessionState`.
//
// Cover art is intentionally NOT asserted — title / artist / album /
// duration / state come from standard mpv properties and work everywhere,
// while embedded cover art depends on the platform's libmpv build.

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

import '_helpers/asset_fixture.dart';

const _probe = MethodChannel('mpv_audio_kit/media_session');

/// Reads the OS-visible Now Playing snapshot back from the plugin (the
/// real `MPNowPlayingInfoCenter.default()`). Apple only.
Future<Map<String, Object?>> readNowPlaying() async {
  final raw = await _probe.invokeMethod<Map<Object?, Object?>>(
    'debugNowPlayingInfo',
  );
  return Map<String, Object?>.from(raw ?? const {});
}

/// Reads back the real published Media3 session State from the Android
/// plugin (what the OS notification / lock-screen renders from). Android only.
Future<Map<String, Object?>> readMediaSession() async {
  final raw = await _probe.invokeMethod<Map<Object?, Object?>>(
    'debugMediaSessionState',
  );
  return Map<String, Object?>.from(raw ?? const {});
}

/// Polls [reader] until [predicate] holds or the timeout fires. Returns
/// the last snapshot so the caller can assert on it (and get a useful
/// failure message). Method-channel pushes are async, so a settled
/// assertion needs a poll, not a fixed delay. [reader] defaults to the
/// Apple Now Playing probe; the Android tests pass [readMediaSession].
Future<Map<String, Object?>> pumpUntil(
  bool Function(Map<String, Object?>) predicate, {
  Duration timeout = const Duration(seconds: 5),
  Future<Map<String, Object?>> Function() reader = readNowPlaying,
}) async {
  final deadline = DateTime.now().add(timeout);
  var snapshot = await reader();
  while (!predicate(snapshot)) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Media session never satisfied the predicate. Last: $snapshot');
    }
    await Future<void>.delayed(const Duration(milliseconds: 50));
    snapshot = await reader();
  }
  return snapshot;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    MpvAudioKit.ensureInitialized(hotRestartCleanup: false);
  });

  // The probe (`debugNowPlayingInfo`) and MPNowPlayingInfoCenter only
  // exist in the Apple plugin; `debugMediaSessionState` + the Media3
  // session live in the Android plugin.
  final isApple = Platform.isIOS || Platform.isMacOS;
  // Android (Media3), Windows (SMTC), and Linux (MPRIS2) expose an identical
  // `debugMediaSessionState` probe and assert the same way, so they share one
  // group below.
  final isProbePlatform =
      Platform.isAndroid || Platform.isWindows || Platform.isLinux;

  group('media session — real OS Now Playing', () {
    late Player player;
    late String fixture;

    setUp(() async {
      // ~3s, seekable — long enough for a real seek that doesn't race EOF.
      fixture = await materializeFixture('with_chapters.mka');
      player = Player(
        configuration: const PlayerConfiguration(logLevel: LogLevel.off),
      );
      // Null audio output — simulators expose no real device.
      await player.setRawProperty('ao', 'null');
    });

    tearDown(() async {
      await player.setMediaSession(null);
      await player.stop();
      await player.dispose();
    });

    testWidgets('enable publishes overridden metadata to the OS', (_) async {
      await player.open(Media(fixture), play: false);
      await player.stream.duration
          .firstWhere((d) => d.inMilliseconds > 2500)
          .timeout(const Duration(seconds: 10));

      await player.setMediaSession(
        const MediaSession(
          title: 'E2E Title',
          artist: 'E2E Artist',
          album: 'E2E Album',
        ),
      );

      final np = await pumpUntil((s) => s['title'] == 'E2E Title');
      expect(np['artist'], 'E2E Artist');
      expect(np['album'], 'E2E Album');
      expect(
        (np['duration'] as num?)?.toDouble(),
        greaterThan(2.5),
        reason: 'duration must reach the OS, got ${np['duration']}',
      );
      // autoPlay:false + opened paused → core-idle true → paused.
      expect(np['playbackState'], 'paused');
    }, skip: !isApple);

    testWidgets('example flow: setMediaSession BEFORE play, derive from file', (
      _,
    ) async {
      // Mirrors the example app EXACTLY: enable the session at startup
      // (no media yet), THEN open + autoplay a real tagged m4a
      // (title/artist/album tags + embedded cover + 2s).
      final tagged = await materializeFixture('tagged.m4a');
      await player.setMediaSession(const MediaSession()); // enable FIRST
      await player.open(Media(tagged), play: true); // then autoplay
      await player.stream.playing
          .firstWhere((p) => p)
          .timeout(const Duration(seconds: 10));
      // Let the incremental metadata pushes (title / duration / cover)
      // settle through the channel.
      await Future<void>.delayed(const Duration(seconds: 1));

      final np = await readNowPlaying();
      expect(np['title'], 'Tagged Title', reason: 'snapshot=$np');
      expect(
        (np['duration'] as num?)?.toDouble() ?? 0,
        greaterThan(1.5),
        reason: 'snapshot=$np',
      );
      expect(np['playbackState'], 'playing', reason: 'snapshot=$np');
      // Embedded cover art reaches the OS now-playing info on every
      // shipped platform; this suite asserts it on macOS only.
      if (Platform.isMacOS) {
        expect(np['hasArtwork'], true, reason: 'snapshot=$np');
      }
    }, skip: !isApple);

    testWidgets('play / pause round-trips to the OS playbackState + rate', (
      _,
    ) async {
      await player.open(Media(fixture), play: false);
      await player.stream.duration
          .firstWhere((d) => d.inMilliseconds > 2500)
          .timeout(const Duration(seconds: 10));
      await player.setMediaSession(const MediaSession(title: 'E2E'));
      await pumpUntil((s) => s['title'] == 'E2E');

      await player.play();
      await player.stream.playing
          .firstWhere((p) => p)
          .timeout(const Duration(seconds: 5));
      var np = await pumpUntil((s) => s['playbackState'] == 'playing');
      expect(
        (np['rate'] as num?)?.toDouble(),
        1.0,
        reason: 'playing must publish rate 1, got ${np['rate']}',
      );

      await player.pause();
      await player.stream.playing
          .firstWhere((p) => !p)
          .timeout(const Duration(seconds: 5));
      np = await pumpUntil((s) => s['playbackState'] == 'paused');
      expect(
        (np['rate'] as num?)?.toDouble(),
        0.0,
        reason: 'paused must publish rate 0, got ${np['rate']}',
      );
    }, skip: !isApple);

    testWidgets('seek moves the OS elapsed and keeps the play state', (
      _,
    ) async {
      await player.open(Media(fixture), play: false);
      await player.stream.duration
          .firstWhere((d) => d.inMilliseconds > 2500)
          .timeout(const Duration(seconds: 10));
      await player.setMediaSession(const MediaSession(title: 'E2E'));
      await pumpUntil((s) => s['title'] == 'E2E');

      await player.play();
      await player.stream.playing
          .firstWhere((p) => p)
          .timeout(const Duration(seconds: 5));
      await pumpUntil((s) => s['playbackState'] == 'playing');

      await player.seek(const Duration(milliseconds: 1500));
      await player.stream.position
          .firstWhere((p) => p.inMilliseconds >= 1400)
          .timeout(const Duration(seconds: 5));

      // The settled OS state: elapsed moved to ~1.5s, and the play
      // state stayed playing — i.e. mpv's transient pause during the
      // seek did NOT leak to the OS — the published play state binds to
      // the playWhenReady intent axis, stable across seeks. The frame-level
      // proof of no-flicker is the Dart controller unit test; here we
      // assert the real settled end-to-end state.
      final np = await pumpUntil(
        (s) => ((s['elapsed'] as num?)?.toDouble() ?? 0) >= 1.4,
      );
      expect(
        np['playbackState'],
        'playing',
        reason: 'seek must not leave the OS paused, got ${np['playbackState']}',
      );
    }, skip: !isApple);

    testWidgets('disable clears the OS Now Playing entry', (_) async {
      await player.open(Media(fixture), play: false);
      await player.stream.duration
          .firstWhere((d) => d.inMilliseconds > 2500)
          .timeout(const Duration(seconds: 10));
      await player.setMediaSession(const MediaSession(title: 'E2E'));
      await pumpUntil((s) => s['title'] == 'E2E');

      await player.setMediaSession(null);
      final np = await pumpUntil((s) => s['playbackState'] == 'stopped');
      expect(
        np['title'],
        isNull,
        reason: 'disable must clear the title, got ${np['title']}',
      );
    }, skip: !isApple);
  });

  // Android (Media3 SimpleBasePlayer) + Windows (SMTC) + Linux (MPRIS2) share
  // this group: all read the real published state via `debugMediaSessionState`.
  // A green run proves the Dart Player → controller → channel → native session
  // path publishes exactly this. The Apple group above is separate (rate-0 on
  // pause, artwork specifics differ).
  group('media session — real OS session (Android / Windows / Linux)', () {
    late Player player;
    late String fixture;

    setUp(() async {
      fixture = await materializeFixture('with_chapters.mka');
      player = Player(
        configuration: const PlayerConfiguration(logLevel: LogLevel.off),
      );
      await player.setRawProperty('ao', 'null');
    });

    tearDown(() async {
      await player.setMediaSession(null);
      await player.stop();
      await player.dispose();
    });

    testWidgets('enable publishes overridden metadata to the session', (
      _,
    ) async {
      await player.open(Media(fixture), play: false);
      await player.stream.duration
          .firstWhere((d) => d.inMilliseconds > 2500)
          .timeout(const Duration(seconds: 10));

      await player.setMediaSession(
        const MediaSession(
          title: 'E2E Title',
          artist: 'E2E Artist',
          album: 'E2E Album',
        ),
      );

      final np = await pumpUntil(
        (s) => s['title'] == 'E2E Title',
        reader: readMediaSession,
      );
      expect(np['artist'], 'E2E Artist');
      expect(np['album'], 'E2E Album');
      expect(
        (np['durationMs'] as num?)?.toDouble(),
        greaterThan(2500),
        reason: 'duration must reach the session, got ${np['durationMs']}',
      );
      // open(play:false) → playWhenReady false → paused.
      expect(np['playbackState'], 'paused');
    }, skip: !isProbePlatform);

    testWidgets('example flow: setMediaSession BEFORE play, derive from file', (
      _,
    ) async {
      final tagged = await materializeFixture('tagged.m4a');
      await player.setMediaSession(const MediaSession()); // enable FIRST
      await player.open(Media(tagged), play: true); // then autoplay
      await player.stream.playing
          .firstWhere((p) => p)
          .timeout(const Duration(seconds: 10));

      final np = await pumpUntil(
        (s) => s['title'] == 'Tagged Title',
        reader: readMediaSession,
      );
      expect(
        (np['durationMs'] as num?)?.toDouble() ?? 0,
        greaterThan(1500),
        reason: 'snapshot=$np',
      );
      expect(np['playbackState'], 'playing', reason: 'snapshot=$np');
    }, skip: !isProbePlatform);

    testWidgets('play / pause round-trips to the session playbackState', (
      _,
    ) async {
      await player.open(Media(fixture), play: false);
      await player.stream.duration
          .firstWhere((d) => d.inMilliseconds > 2500)
          .timeout(const Duration(seconds: 10));
      await player.setMediaSession(const MediaSession(title: 'E2E'));
      await pumpUntil((s) => s['title'] == 'E2E', reader: readMediaSession);

      await player.play();
      await player.stream.playing
          .firstWhere((p) => p)
          .timeout(const Duration(seconds: 5));
      final np = await pumpUntil(
        (s) => s['playbackState'] == 'playing',
        reader: readMediaSession,
      );
      expect(
        (np['rate'] as num?)?.toDouble(),
        1.0,
        reason: 'playing must publish rate 1, got ${np['rate']}',
      );

      await player.pause();
      await player.stream.playing
          .firstWhere((p) => !p)
          .timeout(const Duration(seconds: 5));
      // Android binds the OS button to the INTENT axis (playWhenReady);
      // playbackState flips to paused while the configured speed stays 1.
      await pumpUntil(
        (s) => s['playbackState'] == 'paused',
        reader: readMediaSession,
      );
    }, skip: !isProbePlatform);

    testWidgets('seek moves the session position and keeps the play state', (
      _,
    ) async {
      await player.open(Media(fixture), play: false);
      await player.stream.duration
          .firstWhere((d) => d.inMilliseconds > 2500)
          .timeout(const Duration(seconds: 10));
      await player.setMediaSession(const MediaSession(title: 'E2E'));
      await pumpUntil((s) => s['title'] == 'E2E', reader: readMediaSession);

      await player.play();
      await player.stream.playing
          .firstWhere((p) => p)
          .timeout(const Duration(seconds: 5));
      await pumpUntil(
        (s) => s['playbackState'] == 'playing',
        reader: readMediaSession,
      );

      await player.seek(const Duration(milliseconds: 1500));
      await player.stream.position
          .firstWhere((p) => p.inMilliseconds >= 1400)
          .timeout(const Duration(seconds: 5));

      // The settled session: position moved to ~1.5s and the play state
      // stayed playing — mpv's transient seek-pause did NOT leak (intent axis).
      final np = await pumpUntil(
        (s) => ((s['positionMs'] as num?)?.toDouble() ?? 0) >= 1400,
        reader: readMediaSession,
      );
      expect(
        np['playbackState'],
        'playing',
        reason:
            'seek must not leave the session paused, '
            'got ${np['playbackState']}',
      );
    }, skip: !isProbePlatform);

    testWidgets('disable clears the session entry', (_) async {
      await player.open(Media(fixture), play: false);
      await player.stream.duration
          .firstWhere((d) => d.inMilliseconds > 2500)
          .timeout(const Duration(seconds: 10));
      await player.setMediaSession(const MediaSession(title: 'E2E'));
      await pumpUntil((s) => s['title'] == 'E2E', reader: readMediaSession);

      await player.setMediaSession(null);
      final np = await pumpUntil(
        (s) => s['playbackState'] == 'stopped',
        reader: readMediaSession,
      );
      expect(
        np['title'],
        isNull,
        reason: 'disable must clear the title, got ${np['title']}',
      );
    }, skip: !isProbePlatform);
  });
}
