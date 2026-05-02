// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'dart:io';

import 'package:test/test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import '../_helpers/setter_test_helpers.dart';

void main() {
  // Metadata reading — covers both ID3v2 (MP3) and Vorbis-comment (FLAC)
  // tag-parsing pipelines. mpv has separate parsers for each container,
  // and a regression in either can leave consumers with empty
  // `state.metadata` / `state.mediaTitle`. The fixtures embed deliberately
  // unicode strings to also catch encoding mishandling on the FFI bridge.
  final fixturesDir = '${Directory.current.path}/test/fixtures/extra';

  setUpAll(() => initLibmpvOrSkip());

  group('Metadata — ID3v2 + Vorbis comments', () {
    late Player player;

    setUpAll(() async {
      player = await buildPlayer();
    });

    tearDownAll(() async {
      await player.stop();
      await player.dispose();
    });

    test('ID3v2 tags from an MP3 surface through state.metadata', () async {
      final path = '$fixturesDir/mp3_with_id3v2.mp3';
      if (!File(path).existsSync()) {
        markTestSkipped(
            'Fixture missing: run scripts/generate_extra_fixtures.sh');
        return;
      }
      // Pre-subscribe to metadata before opening — the broadcast emit
      // for a populated tag dict can land before a late firstWhere
      // attaches.
      final mdFuture = player.stream.metadata
          .firstWhere((m) => m.isNotEmpty)
          .timeout(const Duration(seconds: 10));
      await player.open(Media(path), play: false);
      final md = await mdFuture;

      // mpv normalizes tag keys to a canonical form (e.g. ID3v2's TIT2
      // becomes "title"). Match case-insensitively to absorb any future
      // change in the wrapper's key handling, and look for the unicode
      // payload to confirm encoding round-trips through the FFI bridge.
      final lower = {
        for (final e in md.entries) e.key.toLowerCase(): e.value,
      };
      expect(lower['title'], isNotNull,
          reason: 'ID3v2 TIT2 must surface as "title"');
      expect(lower['title']!, contains('Test Title'),
          reason: 'tag value must round-trip through the FFI bridge');
      expect(lower['title']!, contains('ümlaut'),
          reason: 'unicode characters must survive the bridge');
      expect(lower['artist'], 'Test Artist');
      expect(lower['album'], 'Test Album');
    }, timeout: const Timeout(Duration(seconds: 20)));

    test('Vorbis comments from a FLAC surface through state.metadata',
        () async {
      final path = '$fixturesDir/flac_with_vorbis_comments.flac';
      if (!File(path).existsSync()) {
        markTestSkipped(
            'Fixture missing: run scripts/generate_extra_fixtures.sh');
        return;
      }
      // Open the second fixture — metadata for the new file replaces
      // the previous map, but the stream emits even when both maps are
      // non-empty (different contents, no dedup).
      final mdFuture = player.stream.metadata
          .firstWhere((m) =>
              m.isNotEmpty &&
              m.values.any((v) => v.contains('Vorbis')))
          .timeout(const Duration(seconds: 10));
      await player.open(Media(path), play: false);
      final md = await mdFuture;

      final lower = {
        for (final e in md.entries) e.key.toLowerCase(): e.value,
      };
      expect(lower['title'], 'Vorbis Comment Title');
      expect(lower['artist'], 'Vorbis Artist');
      expect(lower['album'], 'Vorbis Album');
    }, timeout: const Timeout(Duration(seconds: 20)));
  });
}
