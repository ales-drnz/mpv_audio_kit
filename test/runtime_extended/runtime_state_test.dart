// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@TestOn('mac-os || linux')
library;

import 'dart:io';

import 'package:test/test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import '../_helpers/libmpv_resolver.dart';

void main() {
// 5-second fixture lets sustained-playback observers (audioBitrate,
  // bufferDuration, audioPts, position) emit several values before EOF.
  final fixturePath =
      '${Directory.current.path}/test/fixtures/sine_5s.flac';

  setUpAll(() {
    final lib = resolveLibmpv();
    if (lib == null) {
      markTestSkipped('libmpv not found');
      return;
    }
    if (!File(fixturePath).existsSync()) {
      markTestSkipped('5s fixture missing');
      return;
    }
    MpvAudioKit.ensureInitialized(libmpv: lib, hotRestartCleanup: false);
  });

  group('Runtime state — sustained-playback observers populate', () {
    late Player player;

    setUpAll(() async {
      player = Player(
          configuration: const PlayerConfiguration(
        autoPlay: false,
        logLevel: 'no',
      ));
      await player.setRawProperty('ao', 'null');
      await player.open(Media(fixturePath), play: false);
      await player.stream.duration
          .firstWhere((d) => d.inMilliseconds > 4500)
          .timeout(const Duration(seconds: 5));
    });

    tearDownAll(() async {
      await player.stop();
      await player.clearPlaylist();
      await player.dispose();
    });

    test('mediaTitle / fileFormat / fileSize / seekable / partiallySeekable '
        'populate from a real file', () async {
      // Some properties land at file-load time; some at first
      // play / first audio frame. Wait briefly to give them a chance.
      await Future.delayed(const Duration(milliseconds: 500));

      // mediaTitle falls back to the filename (no `title` tag in the
      // fixture).
      expect(player.state.mediaTitle, isNotEmpty);

      // fileFormat populated by the demuxer.
      expect(player.state.fileFormat, isNotEmpty,
          reason: 'demuxer must report the container format');

      // fileSize is non-zero for a finite file.
      expect(player.state.fileSize, greaterThan(0),
          reason: 'sine_5s.flac is a finite local file');

      // Local files are fully seekable.
      expect(player.state.seekable, isTrue);
      expect(player.state.partiallySeekable, isFalse,
          reason: 'partial seek is for HLS / DASH only');
    }, timeout: const Timeout(Duration(seconds: 15)));

    test('audioBitrate emits a non-null value during playback', () async {
      // Subscribe BEFORE play so the first observer event isn't missed.
      final bitrateCompleter = player.stream.audioBitrate
          .firstWhere((b) => b != null && b > 0)
          .timeout(const Duration(seconds: 5));
      await player.play();
      try {
        final br = await bitrateCompleter;
        expect(br, isNotNull);
        expect(br!, greaterThan(0),
            reason: 'mpv emits audio-bitrate ~once per second during '
                'playback; FLAC at 44.1 kHz mono yields >50 kbps');
      } finally {
        await player.pause();
      }
    }, timeout: const Timeout(Duration(seconds: 15)));

    test('bufferDuration populates during playback (demuxer-cache-duration)',
        () async {
      await player.seek(Duration.zero);
      await Future.delayed(const Duration(milliseconds: 200));

      final bufferCompleter = player.stream.bufferDuration
          .firstWhere((d) => d > Duration.zero)
          .timeout(const Duration(seconds: 5));
      await player.play();
      try {
        final buf = await bufferCompleter;
        expect(buf.inMilliseconds, greaterThan(0),
            reason: 'demuxer-cache-duration must show some lookahead '
                'while audio is producing samples');
      } finally {
        await player.pause();
      }
    }, timeout: const Timeout(Duration(seconds: 15)));

    test('audioPts emits a Duration distinct from time-pos baseline',
        () async {
      // audio-pts may or may not differ from time-pos depending on
      // driver latency; assert only that it emits a non-zero value
      // during playback.
      await player.seek(const Duration(seconds: 1));
      await Future.delayed(const Duration(milliseconds: 200));

      final ptsCompleter = player.stream.audioPts
          .firstWhere((d) => d > Duration.zero)
          .timeout(const Duration(seconds: 5));
      await player.play();
      try {
        final pts = await ptsCompleter;
        expect(pts.inMilliseconds, greaterThan(0));
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
      await player.open(Media(shortPath), play: false);
      await player.stream.duration
          .firstWhere((d) => d.inMilliseconds > 500 &&
              d.inMilliseconds < 1500)
          .timeout(const Duration(seconds: 5));

      await player.play();
      // 1s file + a comfortable margin for AO + observer roundtrip.
      await Future.delayed(const Duration(milliseconds: 1800));
      expect(player.state.eofReached, isTrue,
          reason: 'with keep-open=yes mpv pauses at EOF and emits '
              'eof-reached=true; assert via state to dodge the broadcast '
              'firstWhere subscribe-after-emit window');
      await player.pause();
    }, timeout: const Timeout(Duration(seconds: 15)));
  });
}
