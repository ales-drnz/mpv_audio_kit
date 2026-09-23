// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

@TestOn('mac-os')
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    MpvAudioKit.ensureInitialized(hotRestartCleanup: false);
  });

  group('cold start: main thread stays free', () {
    testWidgets(
      'Flutter renders frames continuously while a Player is being initialized',
      (tester) async {
        int frameCount = 0;
        WidgetsBinding.instance.addPersistentFrameCallback((_) => frameCount++);

        await tester.pumpWidget(const MaterialApp(home: SizedBox.expand()));
        await tester.pump();
        final before = frameCount;

        final sw = Stopwatch()..start();
        final player = Player();
        // Pump frames for ~800 ms in 16 ms steps. If `Player()` blocked
        // the main isolate, pump() would not advance and frameCount
        // would stay close to the baseline.
        for (var i = 0; i < 50; i++) {
          await tester.pump(const Duration(milliseconds: 16));
        }
        sw.stop();

        final delta = frameCount - before;
        await player.ready;
        await player.dispose();

        // Tolerance: 50 ideal − 50% headroom = ≥25.
        expect(
          delta,
          greaterThan(25),
          reason:
              'Only $delta frames rendered in ${sw.elapsedMilliseconds} '
              'ms while Player() was being initialized — main thread '
              'was likely blocked by synchronous FFI',
        );
      },
      timeout: const Timeout(Duration(seconds: 30)),
    );
  });
}
