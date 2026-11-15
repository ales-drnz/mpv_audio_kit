// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

import '../_helpers/setter_test_helpers.dart';

void main() {
  runtimeSuite(() {
    // A core that shuts down without dispose leaves nobody to answer the
    // asynchronous calls: the event isolate exits on MPV_EVENT_SHUTDOWN.
    test('sendRawCommand refuses quit and quit-watch-later', () async {
      final player = await buildPlayer();
      addTearDown(player.dispose);
      for (final args in const [
        ['quit'],
        ['quit', '3'],
        ['quit-watch-later'],
        ['quit_watch_later'],
        ['no-osd', 'quit'],
      ]) {
        await expectLater(
          () => player.sendRawCommand(args),
          throwsArgumentError,
          reason: '$args',
        );
      }
      // The core still answers.
      expect(await player.getRawProperty('idle-active'), 'yes');
    }, timeout: const Timeout(Duration(seconds: 20)));

    test(
      'the calls made after the core shut down by itself complete',
      () async {
        final player = await buildPlayer();
        addTearDown(player.dispose);
        await player.ready;
        final warned = player.stream.internalLog.firstWhere(
          (e) => e.level == LogLevel.warn && e.text.contains('shut down'),
        );
        // Without `idle` mpv quits once nothing is left to play: a
        // shutdown that no command of this player asked for.
        await player.setRawProperty('idle', 'no');
        await warned.timeout(const Duration(seconds: 5));

        await player.setVolume(50).timeout(const Duration(seconds: 3));
        expect(
          await player
              .getRawProperty('volume')
              .timeout(const Duration(seconds: 3)),
          isNull,
        );
        await player.dispose().timeout(const Duration(seconds: 10));
      },
      timeout: const Timeout(Duration(seconds: 30)),
    );
  });
}
