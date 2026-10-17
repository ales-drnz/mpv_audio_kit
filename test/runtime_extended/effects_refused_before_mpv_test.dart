// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// A stage lavfi would accept and then read or write out of its buffers
// with is refused before anything reaches mpv: both effects setters throw
// ArgumentError, and the state and mpv's chain stay on the last list.
// No file is loaded, so a list that got through would only be stored by
// mpv, never run.

@TestOn('mac-os || linux || windows')
library;

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

import '../_helpers/setter_test_helpers.dart';

void main() {
  runtimeSuite(() {
    late Player player;
    setUp(() async {
      player = await buildPlayer();
    });
    tearDown(() async {
      await player.dispose();
    });

    // chorus reads decays[1] from a buffer that holds one float.
    const unsafe = ChorusEffect(
      delays: '40|50',
      decays: '0.4',
      speeds: '0.25|0.4',
      depths: '2|1.3',
    );
    const accepted = [EqualizerEffect(frequency: 1000, gain: 3)];

    test('setAudioEffects throws and keeps the last list', () async {
      await player.setAudioEffects(accepted);
      final af = await player.getRawProperty('af');
      await expectLater(
        player.setAudioEffects([...accepted, unsafe]),
        throwsArgumentError,
      );
      expect(player.state.audioEffects, accepted);
      expect(await player.getRawProperty('af'), af);
    });

    test('updateAudioEffects throws and keeps the last list', () async {
      await player.setAudioEffects(accepted);
      final af = await player.getRawProperty('af');
      await expectLater(
        player.updateAudioEffects((fx) => [...fx, unsafe]),
        throwsArgumentError,
      );
      expect(player.state.audioEffects, accepted);
      expect(await player.getRawProperty('af'), af);
    });
  });
}
