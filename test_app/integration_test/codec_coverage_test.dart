// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// On-device codec coverage. Mirrors `test/runtime_extended/codec_coverage_test.dart`
// against the platform-specific libmpv binary (macOS / iOS / Android).
// Both suites read from the same `_helpers/codec.dart` matrix; the only
// platform-dependent piece is how the fixture file is reached — host uses
// an absolute filesystem path, device materializes from rootBundle.

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

import '_helpers/asset_fixture.dart';
import '_helpers/codec.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    MpvAudioKit.ensureInitialized(hotRestartCleanup: false);
  });

  group('Codec coverage — device build', () {
    late Player player;

    setUpAll(() async {
      player = await createTestPlayer();
    });

    tearDownAll(() async {
      await player.stop();
      await player.dispose();
    });

    for (final entry in codecMatrix) {
      final filename = entry.$1;
      final expected = entry.$2;
      testWidgets(expected.label, (_) async {
        final path = await materializeFixture('codec/$filename');
        final result = await verifyCodec(player, path, expected);

        expect(result.params.sampleRate, expected.sampleRate,
            reason: 'sample rate must match the fixture for ${expected.label}');
        expect(result.params.channelCount, expected.channels,
            reason: 'channel count must match the fixture for ${expected.label}');
        expect(result.duration.inMilliseconds, greaterThan(0),
            reason: 'duration must be reported by the demuxer');

        if (expected.codecHint != null) {
          final h = expected.codecHint!.toLowerCase();
          final c = (result.params.codec ?? '').toLowerCase();
          final cn = (result.params.codecName ?? '').toLowerCase();
          expect(
            c.contains(h) || cn.contains(h),
            isTrue,
            reason: 'codec id should contain "${expected.codecHint}" for '
                '${expected.label}; got codec="${result.params.codec}", '
                'codecName="${result.params.codecName}"',
          );
        }
      }, timeout: const Timeout(Duration(seconds: 30)));
    }
  });
}
