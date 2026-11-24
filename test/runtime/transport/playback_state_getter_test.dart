// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

import '../../_helpers/setter_test_helpers.dart';

/// `state.playbackState` reads what `stream.playbackState` last emitted.
void main() {
  final fixturePath = defaultFixturePath();

  runtimeSuite(fixturePath: fixturePath, () {
    test('follows the stream through open, pause and stop', () async {
      final player = await buildPlayer();
      addTearDown(player.dispose);
      MpvPlaybackState? last;
      final sub = player.stream.playbackState.listen((s) => last = s);
      addTearDown(sub.cancel);

      expect(player.state.playbackState, MpvPlaybackState.idle);

      await player.open(Media(fixturePath), play: true);
      await waitUntil(() => last == MpvPlaybackState.playing);
      expect(player.state.playbackState, MpvPlaybackState.playing);

      await player.pause();
      await waitUntil(() => last == MpvPlaybackState.paused);
      expect(player.state.playbackState, MpvPlaybackState.paused);

      await player.stop();
      await waitUntil(() => last == MpvPlaybackState.idle);
      expect(player.state.playbackState, MpvPlaybackState.idle);
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}
