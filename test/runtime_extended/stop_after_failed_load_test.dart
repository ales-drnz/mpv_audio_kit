// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'dart:async';
import 'dart:io';

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

import '../_helpers/setter_test_helpers.dart';

void main() {
  // After a load that fails mpv is idle with the failed entry still in
  // its playlist. A stop() then clears the playlist, but mpv does not
  // always report the change, so the state kept the old entry.
  final fixturePath = '${Directory.current.path}/test/fixtures/sine_5s.flac';

  runtimeSuite(fixturePath: fixturePath, () {
    group('stop() after a failed load', () {
      late Player player;

      setUpAll(() async {
        player = await buildPlayer();
      });

      tearDownAll(() async {
        await player.dispose();
      });

      Future<void> failLoad() async {
        final failed = player.stream.endFile.firstWhere(
          (e) => e.reason == MpvEndFileReason.error,
        );
        await player.open(
          const Media('/tmp/mak-stop-after-failed-load-missing.flac'),
          play: false,
        );
        await failed.timeout(const Duration(seconds: 5));
        // Let the idle state settle, past any notification of the load.
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }

      test('empties the playlist in the state', () async {
        await failLoad();
        expect(player.state.playlist.items, hasLength(1));

        await player.stop();
        final deadline = DateTime.now().add(const Duration(seconds: 2));
        while (player.state.playlist.items.isNotEmpty &&
            DateTime.now().isBefore(deadline)) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }
        expect(player.state.playlist.items, isEmpty);
      }, timeout: const Timeout(Duration(seconds: 30)));

      test('ends a live source added to the failed entry', () async {
        await failLoad();
        // A live source queued behind the failed entry, so it is held
        // but never read; the stop comes after the 300 ms check.
        final source = PcmSource.create(
          const PcmFormat(sampleRate: 48000, channels: 2),
        );
        await player.add(source.toMedia());
        await Future<void>.delayed(const Duration(milliseconds: 600));
        expect(source.state, isNot(PcmSourceState.stopped));

        await player.stop();
        await source.done.timeout(const Duration(seconds: 2));
        expect(source.state, PcmSourceState.stopped);
      }, timeout: const Timeout(Duration(seconds: 30)));
    });
  });
}
