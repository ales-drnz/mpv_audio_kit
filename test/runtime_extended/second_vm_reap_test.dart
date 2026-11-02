// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

// A second VM of the process calls ensureInitialized with the default
// hotRestartCleanup: a second Flutter engine of an add-to-app host, a
// background task, here an isolate. It finds the buffer of the Hot Restart
// tracker that the first VM published in the process environment. The
// first VM is alive, so its cores are not orphans: the reap sent them
// `quit` and destroyed them while the first VM still used them.

@TestOn('mac-os || linux')
@Timeout(Duration(minutes: 2))
library;

import 'dart:io';
import 'dart:isolate';

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

import '../_helpers/setter_test_helpers.dart';

/// Past the 500 ms after which the reap destroys the cores it found.
const _secondVmLifeMs = 800;

Future<void> _secondVm() async {
  MpvAudioKit.ensureInitialized();
  await Future<void>.delayed(const Duration(milliseconds: _secondVmLifeMs));
}

void main() {
  final fixturePath = '${Directory.current.path}/test/fixtures/sine_5s.flac';

  // The tracker runs once per process, in a debug build only, and each test
  // file of `flutter test` has a process of its own.
  runtimeSuite(fixturePath: fixturePath, initialize: false, () {
    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      MpvAudioKit.ensureInitialized();
    });

    test('a second VM leaves the playing cores of the first alone', () async {
      final player = await buildPlayer();
      addTearDown(() => player.dispose().timeout(const Duration(seconds: 5)));
      await openAndWaitForLoad(player, fixturePath);
      await player.play();
      await waitUntil(
        () => player.state.position > const Duration(milliseconds: 300),
        reason: 'the first player never advanced',
      );

      final before = player.state.position;
      await Isolate.run(_secondVm);
      await Future<void>.delayed(const Duration(milliseconds: 600));

      expect(player.state.playing, isTrue, reason: 'the core got a quit');
      expect(
        player.state.position - before,
        greaterThan(const Duration(milliseconds: 800)),
        reason: 'the first player stopped after the second VM init',
      );
      expect(
        await player
            .getRawProperty('time-pos')
            .timeout(const Duration(seconds: 3)),
        isNotNull,
        reason: 'the core answers',
      );
    });
  });
}
