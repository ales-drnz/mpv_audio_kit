// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'dart:io';

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

import '../_helpers/setter_test_helpers.dart';

/// A property mpv reports unavailable returns its state field to the seed,
/// so a stopped player doesn't keep the previous file's values.
void main() {
  final fixturePath = '${Directory.current.path}/test/fixtures/sine_5s.flac';

  runtimeSuite(fixturePath: fixturePath, () {
    group('Unavailable properties', () {
      late Player player;

      setUp(() async {
        player = await buildPlayerWithFixture(fixturePath: fixturePath);
        await waitUntil(
          () =>
              player.state.path.isNotEmpty &&
              player.state.duration > Duration.zero &&
              player.state.fileSize > 0,
        );
      });

      tearDown(() => player.dispose());

      test('stop() clears the per-file state', () async {
        await player.stop();
        await waitUntil(
          () => player.state.path.isEmpty,
          reason: 'path must clear once the file is unloaded',
        );
        final s = player.state;
        expect(s.filename, isEmpty);
        expect(s.mediaTitle, isEmpty);
        expect(s.fileFormat, isEmpty);
        expect(s.fileSize, 0);
        expect(s.duration, Duration.zero);
        expect(s.position, Duration.zero);
        expect(s.seekable, isFalse);
      }, timeout: const Timeout(Duration(seconds: 15)));

      test('reopening the same file restores equal values', () async {
        final duration = player.state.duration;
        await player.stop();
        await waitUntil(() => player.state.duration == Duration.zero);

        // mpv re-emits a value after it was unavailable even when it equals
        // the one before, so the cells don't stay at their seed.
        await openAndWaitForLoad(player, fixturePath);
        await waitUntil(
          () =>
              player.state.duration == duration &&
              player.state.path.isNotEmpty &&
              player.state.fileSize > 0,
          reason: 'the reloaded file must report its values again',
        );
      }, timeout: const Timeout(Duration(seconds: 15)));
    });
  });
}
