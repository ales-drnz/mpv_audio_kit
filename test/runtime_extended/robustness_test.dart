// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'dart:async';
import 'dart:io';

import 'package:test/test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import '../_helpers/setter_test_helpers.dart';

void main() {
  // File robustness — covers what happens when consumers feed garbage
  // into open(). Two scenarios distinct from error_paths_test (which
  // covers non-existent paths and malformed URLs):
  //   1. **Truncated**: a valid MP3 header followed by half-cut payload.
  //      The demuxer accepts the file at open() time, then errors mid-
  //      decode when it hits the cut.
  //   2. **Corrupted**: plain text wearing a .mp3 extension. Header
  //      validation must reject this immediately.
  // Both must surface as `endFile.error` rather than crashing the
  // process — a serious-library invariant for any app that lets the
  // user pick arbitrary files.
  final fixturesDir = '${Directory.current.path}/test/fixtures/extra';

  setUpAll(() => initLibmpvOrSkip());

  group('Robustness — broken / corrupted files', () {
    late Player player;

    setUpAll(() async {
      player = await buildPlayer();
    });

    tearDownAll(() async {
      await player.stop();
      await player.clearPlaylist();
      await player.dispose();
    });

    test('truncated MP3 reaches endFile via the public stream', () async {
      final path = '$fixturesDir/truncated.mp3';
      if (!File(path).existsSync()) {
        markTestSkipped(
            'Fixture missing: run scripts/generate_extra_fixtures.sh');
        return;
      }
      // mpv is tolerant of truncated MPEG audio: a file with valid frames
      // followed by a clean cut typically replays the available frames and
      // emits endFile with reason `eof` rather than `error` (vs the
      // corrupted-header case below, where reject is immediate).
      // What we actually test here is the **robustness invariant**: the
      // library surfaces an endFile event through the public stream
      // rather than hanging or crashing — the reason itself is mpv's call,
      // either eof or error is acceptable.
      final completer = Completer<MpvFileEndedEvent>();
      final sub = player.stream.endFile.listen((event) {
        if (!completer.isCompleted) completer.complete(event);
      });

      try {
        await player.open(Media(path), play: true);
        final event =
            await completer.future.timeout(const Duration(seconds: 10));
        expect(
          event.reason,
          anyOf(MpvEndFileReason.eof, MpvEndFileReason.error),
          reason: 'truncated file must surface an endFile event with a '
              'natural-end-or-error reason; the wrapper must not hang',
        );
      } finally {
        await sub.cancel();
      }
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('corrupted file (text masquerading as .mp3) is rejected', () async {
      final path = '$fixturesDir/corrupted.mp3';
      if (!File(path).existsSync()) {
        markTestSkipped(
            'Fixture missing: run scripts/generate_extra_fixtures.sh');
        return;
      }
      final completer = Completer<MpvFileEndedEvent>();
      final sub = player.stream.endFile.listen((event) {
        if (event.reason == MpvEndFileReason.error && !completer.isCompleted) {
          completer.complete(event);
        }
      });

      try {
        await player.open(Media(path), play: false);
        final event =
            await completer.future.timeout(const Duration(seconds: 5));
        expect(event.reason, MpvEndFileReason.error);
        expect(event.error, lessThan(0),
            reason: 'demuxer-rejection carries a negative mpv error code');
      } finally {
        await sub.cancel();
      }
    }, timeout: const Timeout(Duration(seconds: 15)));
  });
}
