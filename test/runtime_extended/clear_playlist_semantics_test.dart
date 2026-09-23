// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

import '../_helpers/setter_test_helpers.dart';

void main() {
  // L2 — `clearPlaylist()` issues both `playlist-clear` AND
  // `playlist-remove current`. mpv's `playlist-clear` on its own
  // preserves the active entry; the second command is what makes the
  // wrapper's contract match the method name ("clear ALL tracks,
  // including the playing one"). The combined behaviour is
  // observable: after the call playback stops and the playlist is
  // empty.
  //
  // This test pins that contract. A future change that drops the
  // `playlist-remove current` (e.g. to keep playback running) would
  // be a breaking semantic change visible to consumers; the test
  // forces it to be intentional.
  final fixturePath = defaultFixturePath();

  setUpAll(() => initLibmpvOrSkip(fixturePath: fixturePath));

  group('clearPlaylist semantics (L2)', () {
    test('clearPlaylist() during playback stops the active track and '
        'empties the playlist', () async {
      final player = await buildPlayer();
      try {
        // Open + start playing — gets us a non-empty playlist with a
        // currently-playing entry.
        await player.open(Media(fixturePath), play: true);
        await player.stream.seekCompleted.first.timeout(
          const Duration(seconds: 5),
        );
        expect(
          player.state.playlist.items,
          isNotEmpty,
          reason: 'precondition: playlist must be populated',
        );

        await player.clearPlaylist();

        // Settle: the `playlist-remove current` command makes mpv
        // emit a file-ended event; allow the observers to land.
        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(
          player.state.playlist.items,
          isEmpty,
          reason:
              'clearPlaylist() must empty the playlist completely '
              '(both queued and currently-playing entries)',
        );
        expect(
          player.state.playing,
          isFalse,
          reason:
              'clearPlaylist() also removes the currently-playing '
              'entry, which stops playback. This is documented; the '
              'test pins the contract so a future change must be '
              'intentional.',
        );
      } finally {
        await player.dispose();
      }
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}
