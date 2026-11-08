// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'dart:io';

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

import '../_helpers/setter_test_helpers.dart';

/// Removing a stage that holds the end of the file must not lose it:
/// libmpv-scripts' chain_eof patch re-seeks, where plain mpv 0.41 stays at
/// the end for good. dynaudnorm's look-ahead takes all of a 5 s file, its
/// end included; with it in the chain, time-pos moves on to the loop's
/// start or the next entry about 0.7 s before the end, so the change comes
/// in the last second.
void main() {
  final fixture = '${Directory.current.path}/test/fixtures/sine_5s.flac';

  runtimeSuite(fixturePath: fixture, () {
    Future<double> timePos(Player p) async =>
        double.tryParse(await p.getRawProperty('time-pos') ?? '') ?? -1;

    for (final (name, loop) in [('loop', Loop.file), ('playlist', Loop.off)]) {
      test('removing dynaudnorm at the end keeps the $name going', () async {
        final player = await buildPlayer();
        addTearDown(player.dispose);
        await player.setLoop(loop);
        await player.setAudioEffects(const [DynaudnormEffect()]);
        await player.openAll([Media(fixture), Media(fixture)], play: true);
        await waitUntil(
          () async => await timePos(player) > 4,
          timeout: const Duration(seconds: 10),
          reason: 'playback reaches the last second',
        );
        final entry = player.state.playback.playlist.index;
        await player.setAudioEffects(const []);

        await waitUntil(
          () async =>
              await timePos(player) < 3 ||
              player.state.playback.playlist.index != entry,
          timeout: const Duration(seconds: 3),
          reason: 'playback went past the end of the file',
        );
      }, timeout: const Timeout(Duration(seconds: 30)));
    }
  });
}
