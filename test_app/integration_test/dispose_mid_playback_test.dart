// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

@TestOn('mac-os')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

import '_helpers/asset_fixture.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    MpvAudioKit.ensureInitialized(hotRestartCleanup: false);
  });

  group('dispose mid-playback (real AO)', () {
    testWidgets(
      'dispose() while audio is playing through coreaudio settles cleanly',
      (_) async {
        // Real AO (coreaudio default), file actually playing — dispose
        // must teardown the AO render thread without hanging.
        final fixturePath = await materializeFixture('sine_440hz_1s.wav');
        final player = Player(
          configuration: const PlayerConfiguration(logLevel: LogLevel.off),
        );

        await player.open(Media(fixturePath), play: true);
        await player.stream.playing
            .firstWhere((p) => p)
            .timeout(const Duration(seconds: 5));
        // Hold for 500 ms so coreaudio is genuinely consuming frames.
        await Future<void>.delayed(const Duration(milliseconds: 500));

        await player.dispose().timeout(const Duration(seconds: 3));
      },
      timeout: const Timeout(Duration(seconds: 30)),
    );
  });
}
