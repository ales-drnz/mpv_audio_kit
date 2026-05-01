// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'package:test/test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import '../_helpers/setter_test_helpers.dart';

void main() {
  final fixturePath = defaultFixturePath();

  setUpAll(() => initLibmpvOrSkip(fixturePath: fixturePath));

  group('setReplayGain end-to-end', () {
    late Player player;

    setUpAll(() async {
      player = await buildPlayerWithFixture(fixturePath: fixturePath);
    });

    tearDownAll(() async {
      await player.dispose();
    });

    test('writes 4 backing properties atomically', () async {
      const cfg = ReplayGainConfig(
        mode: ReplayGainMode.track,
        preamp: -3.0,
        clip: true,
        fallback: 1.5,
      );
      await player.setReplayGain(cfg);
      // Optimistic update is synchronous (state is set inside the setter
      // via _updateField on the 4 granular reactives, then the aggregate
      // is reduced into state.replayGain).
      expect(player.state.replayGain.mode, ReplayGainMode.track);
      expect(player.state.replayGain.preamp, -3.0);
      expect(player.state.replayGain.clip, isTrue);
      expect(player.state.replayGain.fallback, 1.5);
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('partial update via copyWith preserves untouched fields', () async {
      // Start from a known state.
      await player.setReplayGain(const ReplayGainConfig(
        mode: ReplayGainMode.album,
        preamp: -6.0,
        clip: false,
        fallback: 0.5,
      ));
      expect(player.state.replayGain.mode, ReplayGainMode.album);

      // Tweak only preamp; the aggregate setter rewrites all 4 props,
      // but since the consumer copyWith'd from the existing state, the
      // other 3 fields are unchanged.
      await player.setReplayGain(
          player.state.replayGain.copyWith(preamp: -10.0));
      expect(player.state.replayGain.preamp, -10.0);
      expect(player.state.replayGain.mode, ReplayGainMode.album,
          reason: 'mode must survive a copyWith-only-preamp update');
      expect(player.state.replayGain.fallback, 0.5);
      expect(player.state.replayGain.clip, isFalse);
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}
