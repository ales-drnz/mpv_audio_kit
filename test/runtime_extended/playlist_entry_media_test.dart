// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

import '../_helpers/setter_test_helpers.dart';

/// Each playlist entry keeps the [Media] it was loaded with, even when
/// another entry has the same URI: the player maps mpv's entry ids, not
/// URIs, back to [Media].
void main() {
  final fx = defaultFixturePath();

  runtimeSuite(fixturePath: fx, () {
    test('entries with the same URI keep their own extras', () async {
      final player = await buildPlayer();
      addTearDown(player.dispose);

      List<Object?> extras() =>
          player.state.playlist.items.map((m) => m.extras?['n']).toList();

      await player.openAll([
        Media(fx, extras: {'n': 1}),
        Media(fx, extras: {'n': 2}),
      ], play: false);
      await waitUntil(() => extras().length == 2);
      expect(extras(), [1, 2]);

      await player.add(Media(fx, extras: {'n': 3}));
      await waitUntil(() => extras().length == 3);
      expect(extras(), [1, 2, 3]);

      await player.remove(0);
      await waitUntil(() => extras().length == 2);
      expect(extras(), [2, 3]);

      await player.replace(1, Media(fx, extras: {'n': 4}));
      await waitUntil(() => extras().contains(4));
      expect(extras(), [2, 4]);
    }, timeout: const Timeout(Duration(seconds: 20)));
  });
}
