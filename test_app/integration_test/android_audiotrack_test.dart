// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// Regression guard for the Android `audiotrack` AO + JNI bootstrap.
//
// mpv's audiotrack AO calls into ffmpeg's JNI helpers, which need
// `av_jni_set_java_vm()` to have been called with the process JavaVM*
// before any AO init. The bundled libmpv.so achieves this via a
// JNI_OnLoad it ships, fired the first time the host loads the .so via
// System.loadLibrary("mpv"). Without that wiring, audiotrack reports
// `No Java virtual machine has been registered` and playback is silent.
//
// This test loads a local fixture under the default AO list (audiotrack
// first), watches the mpv log stream for the no-JVM error, and asserts
// the playback pipeline reaches a duration > 0 — i.e. an AO actually
// claimed the stream and started decoding.
//
// Skipped on non-Android targets where the AO selection is different.

import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

import '_helpers/asset_fixture.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    MpvAudioKit.ensureInitialized(hotRestartCleanup: false);
  });

  group('Android audiotrack AO + JNI bootstrap', () {
    if (!Platform.isAndroid) {
      // Hard skip outside Android: the audiotrack AO doesn't exist on
      // other platforms and `auto` resolves to a different driver.
      return;
    }

    late Player player;
    final aoErrors = <String>[];
    StreamSubscription<MpvLogEntry>? logSub;

    setUp(() async {
      aoErrors.clear();
      // Default AO (audiotrack on Android via mpv's auto-selection).
      // Surface mpv's warn-level log so the test can fail loudly if
      // audiotrack reports a missing JavaVM.
      player = Player(
        configuration: const PlayerConfiguration(
          autoPlay: false,
          logLevel: LogLevel.warn,
        ),
      );
      logSub = player.stream.log.listen((entry) {
        final lower = entry.text.toLowerCase();
        if (lower.contains('no java virtual machine') ||
            (lower.contains('audiotrack') && lower.contains('error')) ||
            (lower.contains('audio output') &&
                lower.contains('not found'))) {
          aoErrors.add('[${entry.prefix}] ${entry.text}');
        }
      });
    });

    tearDown(() async {
      await logSub?.cancel();
      await player.stop();
      await player.dispose();
    });

    testWidgets(
      'audiotrack opens against a local fixture (no JVM-registration error)',
      (_) async {
        final shortFixture = await materializeFixture('sine_440hz_1s.wav');
        await player.open(Media(shortFixture), play: false);

        // Duration > 0 means the demuxer ran AND an AO was successfully
        // initialized — mpv won't fully load a track if no AO claims it
        // when the file requires audio output.
        final d = await player.stream.duration
            .firstWhere((d) => d.inMilliseconds > 0)
            .timeout(const Duration(seconds: 10));
        expect(d.inMilliseconds, greaterThan(0));
        expect(aoErrors, isEmpty,
            reason: 'mpv reported an AO init error: $aoErrors');
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );
  });
}
