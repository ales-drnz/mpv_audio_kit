// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// On-device smoke test for mpv_audio_kit.
//
// Scope: verify that the libmpv the package's build hook bundles loads on
// the device (libmpv_audio_kit.so on Android, libmpv_audio_kit.framework on
// iOS and macOS) and that an end-to-end open / play / observe / dispose
// cycle succeeds. The 246 host tests in `test/` already
// cover Dart-side logic exhaustively — this suite intentionally stays
// shallow and focuses only on what changes between platforms.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

import '_helpers/asset_fixture.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // libmpv is the code asset the build hook bundles, bound with @Native.
  // No explicit path argument: that's the whole point of the check.
  setUpAll(() {
    MpvAudioKit.ensureInitialized(hotRestartCleanup: false);
  });

  group('mpv_audio_kit on-device smoke', () {
    late Player player;
    late String shortFixture;

    setUp(() async {
      shortFixture = await materializeFixture('sine_440hz_1s.wav');
      player = Player(
        configuration: const PlayerConfiguration(logLevel: LogLevel.off),
      );
      // Force the null audio output so the test harness never holds a real
      // audio device — important on simulators that don't expose one and on
      // CI machines where audio focus would be flaky.
      await player.setRawProperty('ao', 'null');
    });

    tearDown(() async {
      await player.stop();
      await player.dispose();
    });

    testWidgets('libmpv loads and a Player can be constructed', (_) async {
      // A reply from mpv means the bundled library loaded, its symbols
      // resolved and the core started. The version carries the release
      // the package pins.
      final version = await player.getRawProperty('mpv-version');
      expect(version, isNotNull);
      expect(version, contains('+r'));
    });

    testWidgets('open() on a bundled fixture settles duration', (_) async {
      await player.open(Media(shortFixture), play: false);
      final d = await player.stream.duration
          .firstWhere((d) => d.inMilliseconds > 0)
          .timeout(const Duration(seconds: 10));
      expect(d.inMilliseconds, greaterThan(0));
    });

    testWidgets('play / pause flips state via the core-idle observer', (
      _,
    ) async {
      await player.open(Media(shortFixture), play: false);
      await player.stream.duration
          .firstWhere((d) => d.inMilliseconds > 0)
          .timeout(const Duration(seconds: 10));

      await player.play();
      await player.stream.playing
          .firstWhere((p) => p)
          .timeout(const Duration(seconds: 5));
      expect(player.state.playing, isTrue);

      await player.pause();
      await player.stream.playing
          .firstWhere((p) => !p)
          .timeout(const Duration(seconds: 5));
      expect(player.state.playing, isFalse);
    });

    testWidgets('seek absolute moves position', (_) async {
      // Use the 3-second chapters fixture — long enough that a 500 ms seek
      // doesn't race the EOF on a 1-second sine wave.
      final longFixture = await materializeFixture('with_chapters.mka');
      await player.open(Media(longFixture), play: false);
      await player.stream.duration
          .firstWhere((d) => d.inMilliseconds > 2500)
          .timeout(const Duration(seconds: 10));

      final waitFor400 = player.stream.position
          .firstWhere((p) => p.inMilliseconds >= 400)
          .timeout(const Duration(seconds: 5));
      await player.seek(const Duration(milliseconds: 500));
      await waitFor400;
      expect(player.state.position.inMilliseconds, greaterThan(400));
    });

    testWidgets('audio-params observer reports the fixture sample rate', (
      _,
    ) async {
      // 88.2 kHz is unusual enough that a buggy NODE_MAP int64 parser would
      // produce a different number — the assertion catches a regression in
      // the FFI bridge, not just "any value is fine".
      final exoticFixture = await materializeFixture('sine_88200hz.flac');
      await player.open(Media(exoticFixture), play: false);
      final params = await player.stream.audioParams
          .firstWhere((p) => p.sampleRate == 88200)
          .timeout(const Duration(seconds: 10));
      expect(params.sampleRate, 88200);
    });

    testWidgets('embedded cover art mime is exposed by the FFI bridge', (
      _,
    ) async {
      // Cover art relies on the `embedded-cover-art-mime` property, which
      // the patched libmpv exposes on every platform.
      final coverFixture = await materializeFixture('sine_with_cover.flac');
      final restartCompleter = Completer<void>();
      final sub = player.stream.seekCompleted.listen((_) {
        if (!restartCompleter.isCompleted) restartCompleter.complete();
      });
      try {
        await player.open(Media(coverFixture), play: false);
        await restartCompleter.future.timeout(const Duration(seconds: 10));
      } finally {
        await sub.cancel();
      }
      final mime = await player.getRawProperty('embedded-cover-art-mime');
      expect(
        mime,
        'image/png',
        reason:
            'fixture is muxed with a PNG cover; an empty/wrong mime '
            'would mean the FFI bridge for cover art is broken on this '
            'platform',
      );
    });

    testWidgets('typed setter (setVolume) round-trips through the platform '
        'binary', (_) async {
      // The host suite already covers setVolume exhaustively against the
      // patched desktop build. On iOS / Android the libmpv binary is
      // separately compiled and downloaded from GitHub Releases; if its
      // FFI symbol table or property dispatch differs in any way, a
      // typed setter is the cheapest way to catch the regression. Volume
      // is a good probe because it has an optimistic state update + a
      // property observer round-trip — exercising both directions of the
      // bridge at once.
      // The stream replays the current value (100), so only the set can
      // satisfy the wait.
      final waitFor = player.stream.volume
          .firstWhere((v) => v == 73.0)
          .timeout(const Duration(seconds: 5));
      await player.setVolume(73.0);
      expect(
        player.state.volume,
        73.0,
        reason:
            'optimistic state update should reflect the requested '
            'value synchronously, regardless of platform binary',
      );
      await waitFor;
      expect(player.state.volume, 73.0);
    });
  });
}
