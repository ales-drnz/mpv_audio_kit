// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

import '../_helpers/setter_test_helpers.dart';

/// `completed` for the last entry rises when mpv parks (keep-open pauses
/// the core once the audio output has played everything), not when
/// `eof-reached` turns true. With gapless audio mpv reports EOF as soon as
/// the decoder is done, while a whole output buffer is still to be heard.
void main() {
  final fixturePath = '${Directory.current.path}/test/fixtures/sine_5s.flac';

  runtimeSuite(fixturePath: fixturePath, () {
    test('completed waits for the output buffer to play out', () async {
      final player = await buildPlayer();
      addTearDown(player.dispose);
      // A one second output buffer: eof-reached comes about a second
      // before the end is heard.
      await player.setRawProperty('ao-null-buffer', '1');

      DateTime? eofAt;
      final eofSub = player.stream.eofReached.listen((e) {
        if (e) eofAt ??= DateTime.now();
      });
      addTearDown(eofSub.cancel);
      final completed = player.stream.completed
          .firstWhere((c) => c)
          .timeout(const Duration(seconds: 15));

      await player.open(Media(fixturePath), play: true);
      await completed;
      final completedAt = DateTime.now();
      final pause = await player.getRawProperty('pause');

      expect(eofAt, isNotNull);
      expect(
        completedAt.difference(eofAt!),
        greaterThan(const Duration(milliseconds: 600)),
        reason: 'completed rose with eof-reached, before the buffer played',
      );
      expect(pause, 'yes', reason: 'completed before the keep-open park');
      expect(
        player.state.position,
        greaterThan(player.state.duration - const Duration(milliseconds: 300)),
      );
      await waitUntil(() => !player.state.playing);
      expect(player.state.playWhenReady, isFalse);
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}
