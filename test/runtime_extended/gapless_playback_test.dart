// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'package:test/test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import '../_helpers/setter_test_helpers.dart';

void main() {
  // Gapless playback transition — verifies that mpv's playlist advances
  // to the next track when the current one reaches EOF naturally, with
  // gapless=yes set. We don't measure the gap duration itself (that
  // would require sample-accurate output capture), only the lifecycle:
  // file 1 ends → playlist index advances to 1 → file 2's audio-params
  // settle. The wrapper's `state.playlist.index` and `audioParams`
  // observers are the load-bearing surface for any consumer wanting to
  // build a "now-playing" UI off a continuous playlist.
  //
  // Uses sine_440hz_1s.wav (1-second fixture) twice in a playlist; with
  // `ao=null` mpv's decoder runs ahead of realtime so the test
  // completes in well under the wall-clock 1s + 1s.
  final fixturePath = defaultFixturePath();

  setUpAll(() => initLibmpvOrSkip(fixturePath: fixturePath));

  group('Gapless playback — playlist transition', () {
    late Player player;

    setUpAll(() async {
      player = await buildPlayer();
    });

    tearDownAll(() async {
      await player.stop();
      await player.clearPlaylist();
      await player.dispose();
    });

    test('playlist advances to next track when current ends with gapless=yes',
        () async {
      // Strict gapless requires identical format / sample-rate /
      // channels between tracks. Loading the same fixture twice is the
      // simplest way to satisfy that contract — the encoder boundary is
      // identical by construction.
      await player.setGapless(Gapless.yes);

      // Pre-subscribe to the playlist index transition before issuing
      // openAll — broadcast emits during the load phase shouldn't be
      // missed by a late firstWhere.
      final advanced = player.stream.playlist
          .firstWhere((p) => p.medias.length == 2 && p.index == 1)
          .timeout(const Duration(seconds: 30));

      await player.openAll([
        Media(fixturePath),
        Media(fixturePath),
      ], play: true);

      await advanced;
      expect(player.state.playlist.index, 1,
          reason: 'mpv must advance to the second track when the first '
              'reaches EOF naturally');
      expect(player.state.playlist.medias.length, 2);
    }, timeout: const Timeout(Duration(seconds: 60)));
  });
}
