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

void main() {
  // Cover-art stream contract — verifies the public typed surface
  // for embedded artwork. The runtime tests in `runtime/` already assert
  // the underlying mpv property `embedded-cover-art-mime`; this file
  // covers the **stream** wiring on top of that property:
  //   - file with attached cover  → emit a CoverArt with non-empty
  //     bytes and the right mime
  //   - file without artwork      → emit `null` so consumers can clear
  //     stale UI on track change
  //
  // The two emissions are observed in succession on the same Player.
  final fixturesDir = '${Directory.current.path}/test/fixtures';

  setUpAll(() => initLibmpvOrSkip());

  test('coverArt stream emits bytes for cover, null for non-cover', () async {
    final player = await buildPlayer();

    try {
      // Pre-subscribe BEFORE open: the embedded cover is read in the event
      // isolate on FILE_LOADED and shipped on the payload, so the emit lands
      // as soon as the file loads — a late firstWhere would race it.
      final coverFuture = player.stream.coverArt
          .firstWhere((c) => c != null && c.bytes.isNotEmpty)
          .timeout(const Duration(seconds: 10));

      final coverPath = '$fixturesDir/sine_with_cover.flac';
      if (!File(coverPath).existsSync()) {
        markTestSkipped('Cover fixture missing: $coverPath');
        return;
      }
      await player.open(Media(coverPath), play: false);

      final cover = await coverFuture;
      expect(cover, isNotNull);
      expect(
        cover!.bytes.isNotEmpty,
        isTrue,
        reason: 'fixture has a 64×64 PNG attached_pic; bytes must arrive',
      );
      expect(
        cover.mimeType,
        'image/png',
        reason: 'fixture is muxed with a PNG cover',
      );

      // README contract: state.coverArt mirrors the latest stream emit
      // synchronously. Pin it.
      expect(
        player.state.coverArt,
        isNotNull,
        reason: 'state.coverArt must mirror the latest stream emit',
      );
      expect(player.state.coverArt!.bytes, equals(cover.bytes));
      expect(player.state.coverArt!.mimeType, equals(cover.mimeType));

      // Now load a fixture WITHOUT attached art. The stream contract says
      // we should observe a `null` emit so consumers can clear the
      // previous track's artwork.
      final clearedFuture = player.stream.coverArt
          .firstWhere((c) => c == null)
          .timeout(const Duration(seconds: 10));

      final plainPath = '$fixturesDir/sine_440hz_1s.wav';
      if (!File(plainPath).existsSync()) {
        markTestSkipped('Plain fixture missing: $plainPath');
        return;
      }
      await player.open(Media(plainPath), play: false);

      final cleared = await clearedFuture;
      expect(
        cleared,
        isNull,
        reason:
            'opening a file without attached art must emit `null` so '
            'UIs can clear stale artwork on track change',
      );
      expect(
        player.state.coverArt,
        isNull,
        reason: 'state.coverArt must mirror the cleared stream emit',
      );
    } finally {
      await player.stop();
      await player.dispose();
    }
  }, timeout: const Timeout(Duration(seconds: 30)));
}
