// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

// The filter tap follows the playback position, not the chain's writes: a
// FLAC decodes 4608-sample frames (about 104 ms), and the tap still emits
// a new slice on each 33 ms poll while it plays, and none while paused.

@TestOn('mac-os || linux || windows')
library;

import 'dart:io';

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

import '../_helpers/setter_test_helpers.dart';

void main() {
  final fixturePath = '${Directory.current.path}/test/fixtures/sine_5s.flac';

  runtimeSuite(fixturePath: fixturePath, () {
    test('a FLAC tap emits a slice per poll while it plays', () async {
      final player = await buildPlayer();
      try {
        await player.setAudioEffects(const [EqualizerEffect()]);
        await openAndWaitForLoad(player, fixturePath);
        final stamps = <Duration>{};
        var frames = 0;
        final sub = player.stream
            .tap(AudioFilter.equalizer, side: TapSide.post)
            .listen((f) {
              frames++;
              stamps.add(f.timestamp);
            });
        try {
          await player.play();
          await waitUntil(() => frames > 0, reason: 'no tap frame');
          final from = frames;
          await Future<void>.delayed(const Duration(seconds: 2));
          final played = frames - from;
          // ignore: avoid_print
          print('tap cadence: $played frames in 2 s, ${stamps.length} stamps');
          // About 60 at 30 Hz; 20 when only the chain's writes count.
          expect(played, greaterThan(35));
          expect(stamps.length, frames, reason: 'a slice is never repeated');

          // Paused, the position stands: the slice is not emitted again.
          await player.pause();
          await Future<void>.delayed(const Duration(milliseconds: 300));
          final paused = frames;
          await Future<void>.delayed(const Duration(seconds: 1));
          expect(frames, paused, reason: 'frames while paused');
        } finally {
          await sub.cancel();
        }
      } finally {
        await player.dispose();
      }
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}
