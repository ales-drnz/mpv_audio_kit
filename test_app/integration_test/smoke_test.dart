// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// On-device smoke test for mpv_audio_kit.
//
// Scope: verify that the bundled libmpv binary loads correctly through the
// platform's real plugin pipeline (vendored xcframework on iOS, jniLibs on
// Android, plugin Frameworks on macOS) and that an end-to-end open / play /
// observe / dispose cycle succeeds. The 246 host tests in `test/` already
// cover Dart-side logic exhaustively — this suite intentionally stays
// shallow and focuses only on what changes between platforms.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

import '_helpers/asset_fixture.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // libmpv is loaded via the platform's standard lookup on every target the
  // smoke suite runs on (xcframework symbols on iOS, jniLibs on Android,
  // plugin bundle on macOS). No explicit path argument — that's the whole
  // point of the cross-platform check.
  setUpAll(() {
    MpvAudioKit.ensureInitialized(hotRestartCleanup: false);
  });

  group('mpv_audio_kit on-device smoke', () {
    late Player player;
    late String shortFixture;

    setUp(() async {
      shortFixture = await materializeFixture('sine_440hz_1s.wav');
      player = Player(
        configuration: const PlayerConfiguration(
          autoPlay: false,
          logLevel: 'no',
        ),
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
      // Reaching this point means MpvLibrary.open() resolved every symbol —
      // the platform-specific lookup (process() on iOS, default on Android,
      // bundled framework on macOS) is wired up correctly. The default
      // PlayerState surfaces non-null reactive defaults; if any of them is
      // null the FFI bridge wasn't initialized.
      expect(player.state.volume, isNotNull);
      expect(player.state.duration, isNotNull);
    });

    testWidgets('open() on a bundled fixture settles duration', (_) async {
      await player.open(Media(shortFixture), play: false);
      final d = await player.stream.duration
          .firstWhere((d) => d.inMilliseconds > 0)
          .timeout(const Duration(seconds: 10));
      expect(d.inMilliseconds, greaterThan(0));
    });

    testWidgets('play / pause flips state via the core-idle observer',
        (_) async {
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

    testWidgets('audio-params observer reports the fixture sample rate',
        (_) async {
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

    testWidgets('embedded cover art mime is exposed by the FFI bridge',
        (_) async {
      // Cover art relies on the `embedded-cover-art-mime` property, which
      // is exposed by the patched libmpv build. macOS / Linux / Windows
      // ship the patched binary today; iOS / Android currently load an
      // unpatched libmpv release (libmpv-r5). When those device libraries
      // are rebuilt with the patch applied, this test will start passing
      // on every platform — at that point this skip can be removed.
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
      if (mime == null) {
        markTestSkipped('embedded-cover-art-mime is not exposed by the '
            'libmpv build loaded on this platform — rebuild with the '
            'cover-art patch applied to enable this assertion');
        return;
      }
      expect(mime, 'image/png',
          reason: 'fixture is muxed with a PNG cover; an empty/wrong mime '
              'would mean the FFI bridge for cover art is broken on this '
              'platform');
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
      await player.setVolume(73.0);
      expect(player.state.volume, 73.0,
          reason: 'optimistic state update should reflect the requested '
              'value synchronously, regardless of platform binary');
      // Wait for the property observer to confirm the value via the
      // stream — proves the bridge round-trips end-to-end.
      await player.stream.volume
          .firstWhere((v) => v == 73.0)
          .timeout(const Duration(seconds: 5));
      expect(player.state.volume, 73.0);
    });
  });
}
