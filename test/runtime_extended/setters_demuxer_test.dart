// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

import '../_helpers/setter_test_helpers.dart';

void main() {
  final fixturePath = defaultFixturePath();

  runtimeSuite(fixturePath: fixturePath, () {
    group('setDemuxer end-to-end', () {
      late Player player;

      setUpAll(() async {
        player = await buildPlayerWithFixture(fixturePath: fixturePath);
      });

      tearDownAll(() async {
        await player.dispose();
      });

      test('writes 3 backing properties atomically', () async {
        const cfg = DemuxerSettings(
          maxBytes: 100 * 1024 * 1024,
          maxBackBytes: 25 * 1024 * 1024,
          readahead: Duration(seconds: 10),
        );
        await player.setDemuxer(cfg);
        expect(player.state.demuxer.maxBytes, 100 * 1024 * 1024);
        expect(player.state.demuxer.maxBackBytes, 25 * 1024 * 1024);
        expect(player.state.demuxer.readahead, const Duration(seconds: 10));
      }, timeout: const Timeout(Duration(seconds: 30)));

      test('byte caps preserve sub-MiB precision', () async {
        // 100 MiB + 1 byte. The byte-precise contract forwards the exact int
        // rather than flooring to whole MiB.
        const bytes = 100 * 1024 * 1024 + 1;
        await player.setDemuxer(player.state.demuxer.copyWith(maxBytes: bytes));
        expect(player.state.demuxer.maxBytes, bytes);
      }, timeout: const Timeout(Duration(seconds: 15)));

      test('readahead preserves sub-second precision', () async {
        // Regression for the old int model, which truncated fractional readahead
        // to whole seconds (mpv's demuxer-readahead-secs is a fractional-seconds
        // Double).
        await player.setDemuxer(
          player.state.demuxer.copyWith(
            readahead: const Duration(milliseconds: 1500),
          ),
        );
        expect(
          player.state.demuxer.readahead,
          const Duration(milliseconds: 1500),
        );
      }, timeout: const Timeout(Duration(seconds: 15)));

      test('a single field can be tweaked via copyWith', () async {
        // Seekback pool set to zero (radio / live use case) leaves the other
        // two fields untouched.
        final before = player.state.demuxer;
        await player.setDemuxer(before.copyWith(maxBackBytes: 0));
        expect(player.state.demuxer.maxBackBytes, 0);
        expect(player.state.demuxer.maxBytes, before.maxBytes);
        expect(player.state.demuxer.readahead, before.readahead);
      }, timeout: const Timeout(Duration(seconds: 15)));
    });
  });
}
