// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

@TestOn('mac-os')
library;

import 'dart:io' show ProcessInfo;

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

import '_helpers/asset_fixture.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    MpvAudioKit.ensureInitialized(hotRestartCleanup: false);
  });

  group('dispose mid-playback stress', () {
    testWidgets(
      '30 create→play→dispose cycles with real AO stay bounded in RSS',
      (_) async {
        final fixturePath = await materializeFixture('sine_440hz_1s.wav');

        Future<void> oneCycle() async {
          final player = Player(
            configuration: const PlayerConfiguration(logLevel: LogLevel.off),
          );
          await player.open(Media(fixturePath), play: true);
          await player.stream.playing
              .firstWhere((p) => p)
              .timeout(const Duration(seconds: 5));
          await Future<void>.delayed(const Duration(milliseconds: 100));
          await player.dispose().timeout(const Duration(seconds: 3));
        }

        // Warm-up: dyld cache, libmpv first-init, allocator slab
        // expansion all distort the first few cycles.
        const warmup = 5;
        const cycles = 30;
        for (var i = 0; i < warmup; i++) {
          await oneCycle();
        }

        final rssBefore = ProcessInfo.currentRss;
        for (var i = 0; i < cycles; i++) {
          await oneCycle();
        }
        final rssAfter = ProcessInfo.currentRss;

        final delta = rssAfter - rssBefore;
        // ignore: avoid_print
        print(
          '[stress] RSS ${rssBefore ~/ 1024} → ${rssAfter ~/ 1024} KB '
          '(Δ ${delta ~/ 1024} KB across $cycles cycles)',
        );
        // A real per-cycle leak (orphan thread, retained mpv handle) is
        // ~1+ MB per cycle; 15 MB across 30 cycles is generous noise
        // headroom while still catching real growth.
        expect(
          delta,
          lessThan(15 * 1024 * 1024),
          reason:
              'RSS grew by ${delta ~/ 1024} KB across $cycles cycles '
              '(${rssBefore ~/ 1024} → ${rssAfter ~/ 1024} KB).',
        );
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );
  });
}
