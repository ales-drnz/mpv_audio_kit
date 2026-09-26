// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'dart:io';

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

import '../_helpers/setter_test_helpers.dart';

void main() {
  // 5-second fixture lets sustained-playback observers (audioBitrate,
  // bufferDuration, audioPts, position) emit several values before EOF.
  final fixturePath = '${Directory.current.path}/test/fixtures/sine_5s.flac';

  runtimeSuite(fixturePath: fixturePath, () {
    group('Runtime state — sustained-playback observers populate', () {
      late Player player;

      setUpAll(() async {
        player = await buildPlayerWithFixture(fixturePath: fixturePath);
      });

      tearDownAll(() async {
        await player.stop();
        await player.clearPlaylist();
        await player.dispose();
      });

      test('mediaTitle / fileFormat / fileSize / seekable / partiallySeekable '
          'populate from a real file', () async {
        // Some properties land at file-load time; some at first
        // play / first audio frame.
        await waitUntil(
          () =>
              player.state.mediaTitle.isNotEmpty &&
              player.state.fileFormat.isNotEmpty &&
              player.state.fileSize > 0 &&
              player.state.seekable,
        );

        // mediaTitle falls back to the filename (no `title` tag in the
        // fixture).
        expect(player.state.mediaTitle, isNotEmpty);

        // fileFormat populated by the demuxer.
        expect(
          player.state.fileFormat,
          isNotEmpty,
          reason: 'demuxer must report the container format',
        );

        // fileSize is non-zero for a finite file.
        expect(
          player.state.fileSize,
          greaterThan(0),
          reason: 'sine_5s.flac is a finite local file',
        );

        // Local files are fully seekable.
        expect(player.state.seekable, isTrue);
        expect(
          player.state.partiallySeekable,
          isFalse,
          reason: 'partial seek is for HLS / DASH only',
        );
      }, timeout: const Timeout(Duration(seconds: 15)));

      test('audioBitrate holds a value during playback', () async {
        // The state streams replay the current value, and the file is
        // already loaded: check the value while audio is playing.
        await player.play();
        try {
          await waitUntil(
            () => player.state.playing && (player.state.audioBitrate ?? 0) > 0,
            reason:
                'mpv reports audio-bitrate about once per second during '
                'playback; FLAC at 44.1 kHz mono yields >50 kbps',
          );
        } finally {
          await player.pause();
        }
      }, timeout: const Timeout(Duration(seconds: 15)));

      test(
        'bufferDuration populates during playback (demuxer-cache-duration)',
        () async {
          final restarted = player.stream.seekCompleted.first.timeout(
            const Duration(seconds: 5),
          );
          await player.seek(Duration.zero);
          await restarted;

          await player.play();
          try {
            await waitUntil(
              () =>
                  player.state.playing &&
                  player.state.bufferDuration > Duration.zero,
              reason:
                  'demuxer-cache-duration must show some lookahead '
                  'while audio is producing samples',
            );
          } finally {
            await player.pause();
          }
        },
        timeout: const Timeout(Duration(seconds: 15)),
      );

      test('audioPts advances during playback', () async {
        final restarted = player.stream.seekCompleted.first.timeout(
          const Duration(seconds: 5),
        );
        await player.seek(const Duration(seconds: 1));
        await restarted;

        // The value after the seek may already be non-zero; what shows
        // audio-pts is live is that it advances while playing.
        final before = player.state.audioPts;
        await player.play();
        try {
          await waitUntil(
            () =>
                player.state.audioPts >
                before + const Duration(milliseconds: 200),
            reason: 'audio-pts must advance during playback',
          );
        } finally {
          await player.pause();
        }
      }, timeout: const Timeout(Duration(seconds: 15)));

      test('eofReached flips to true when the file ends naturally', () async {
        // Switch to the 1-second fixture so the wait is bounded and we
        // don't need to seek-then-play the 5s file (seek-near-EOF with
        // keep-open=yes can race the observer).
        final shortPath =
            '${Directory.current.path}/test/fixtures/sine_440hz_1s.wav';
        if (!File(shortPath).existsSync()) {
          markTestSkipped('1s fixture missing');
          return;
        }
        await openAndWaitForLoad(player, shortPath);

        await player.play();
        // The 1s file plus AO and observer latency.
        await waitUntil(
          () => player.state.eofReached,
          timeout: const Duration(seconds: 8),
        );
        expect(
          player.state.eofReached,
          isTrue,
          reason:
              'with keep-open=yes mpv pauses at EOF and emits '
              'eof-reached=true; assert via state to dodge the broadcast '
              'firstWhere subscribe-after-emit window',
        );
        await player.pause();
      }, timeout: const Timeout(Duration(seconds: 15)));
    });
  });
}
