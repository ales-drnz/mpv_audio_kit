// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

@TestOn('mac-os || linux')
library;

import 'dart:io';

import 'package:test/test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import '../_helpers/libmpv_resolver.dart';

void main() {
  // Cover-art-raw stream contract — verifies the public typed surface
  // for embedded artwork. The runtime tests in `runtime/` already assert
  // the underlying mpv property `embedded-cover-art-mime`; this file
  // covers the **stream** wiring on top of that property:
  //   - file with attached cover  → emit a CoverArtRaw with non-empty
  //     bytes and the right mime
  //   - file without artwork      → emit `null` so consumers can clear
  //     stale UI on track change
  //
  // The two emissions are observed in succession on the same Player.
  final fixturesDir = '${Directory.current.path}/test/fixtures';

  setUpAll(() {
    final lib = resolveLibmpv();
    if (lib == null) {
      markTestSkipped('libmpv not found');
      return;
    }
    MpvAudioKit.ensureInitialized(libmpv: lib, hotRestartCleanup: false);
  });

  test('coverArtRaw stream emits bytes for cover, null for non-cover',
      () async {
    final player = Player(
      configuration: const PlayerConfiguration(
        autoPlay: false,
        logLevel: 'no',
      ),
    );
    await player.setRawProperty('ao', 'null');

    try {
      // Pre-subscribe BEFORE open: `_extractEmbeddedCover` fires on
      // FILE_LOADED inside the event isolate, and a late firstWhere
      // would race the broadcast emit.
      final coverFuture = player.stream.coverArtRaw
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
      expect(cover!.bytes.isNotEmpty, isTrue,
          reason: 'fixture has a 64×64 PNG attached_pic; bytes must arrive');
      expect(cover.mimeType, 'image/png',
          reason: 'fixture is muxed with a PNG cover');

      // Now load a fixture WITHOUT attached art. The stream contract says
      // we should observe a `null` emit so consumers can clear the
      // previous track's artwork.
      final clearedFuture = player.stream.coverArtRaw
          .firstWhere((c) => c == null)
          .timeout(const Duration(seconds: 10));

      final plainPath = '$fixturesDir/sine_440hz_1s.wav';
      if (!File(plainPath).existsSync()) {
        markTestSkipped('Plain fixture missing: $plainPath');
        return;
      }
      await player.open(Media(plainPath), play: false);

      final cleared = await clearedFuture;
      expect(cleared, isNull,
          reason: 'opening a file without attached art must emit `null` so '
              'UIs can clear stale artwork on track change');
    } finally {
      await player.stop();
      await player.dispose();
    }
  }, timeout: const Timeout(Duration(seconds: 30)));
}
