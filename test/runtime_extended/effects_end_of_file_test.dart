// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'dart:io';

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

import '../_helpers/setter_test_helpers.dart';

/// Removing a stage that holds the end of the file (rubberband keeps a few
/// hundred milliseconds) must not lose it: libmpv-scripts' chain_eof patch
/// re-seeks, where plain mpv 0.41 stays at the end for good.
void main() {
  final fixture = '${Directory.current.path}/test/fixtures/sine_5s.flac';

  runtimeSuite(fixturePath: fixture, () {
    Future<double> timePos(Player p) async =>
        double.tryParse(await p.getRawProperty('time-pos') ?? '') ?? -1;

    for (final (name, loop) in [('loop', Loop.file), ('playlist', Loop.off)]) {
      test('removing rubberband at the end keeps the $name going', () async {
        final player = await buildPlayer();
        addTearDown(player.dispose);
        await player.setLoop(loop);
        await player.setAudioEffects(const [RubberbandEffect()]);
        await player.openAll([Media(fixture), Media(fixture)], play: true);
        await waitUntil(
          () async => await timePos(player) > 4.55,
          timeout: const Duration(seconds: 10),
          reason: 'playback reaches the last half second',
        );
        final entry = player.state.playlist.index;
        await player.setAudioEffects(const []);

        await waitUntil(
          () async =>
              await timePos(player) < 3 || player.state.playlist.index != entry,
          timeout: const Duration(seconds: 3),
          reason: 'playback went past the end of the file',
        );
      }, timeout: const Timeout(Duration(seconds: 30)));
    }
  });
}
