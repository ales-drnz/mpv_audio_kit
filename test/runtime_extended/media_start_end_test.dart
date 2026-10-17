// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

// Media.start: where an entry starts, as mpv's per-file `start`.

@TestOn('mac-os || linux || windows')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

import '../_helpers/setter_test_helpers.dart';

void main() {
  final a = '${Directory.current.path}/test/fixtures/sine_5s.flac';
  final b = '${Directory.current.path}/test/fixtures/sine_stereo_48k_5s.flac';

  runtimeSuite(fixturePath: a, extraFixtures: [b], () {
    late Player player;

    setUp(() async {
      player = await buildPlayer();
    });

    tearDown(() async {
      await player.dispose();
    });

    /// Waits for the next PLAYBACK_RESTART, the first stable position of
    /// a load, after [action].
    Future<void> restartAfter(Future<void> Function() action) async {
      final restarted = player.stream.seekCompleted.first.timeout(
        const Duration(seconds: 10),
      );
      await action();
      await restarted;
    }

    void expectNear(int ms, {String? reason}) => expect(
      player.state.position.inMilliseconds,
      closeTo(ms, 150),
      reason: reason,
    );

    test('open starts the file at start', () async {
      await restartAfter(
        () => player.open(
          Media(a, start: const Duration(seconds: 2)),
          play: false,
        ),
      );
      expectNear(2000);
      // The file keeps its whole length.
      await waitUntil(() => player.state.duration.inMilliseconds > 4500);
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('openAll gives each entry its own start, at every load', () async {
      await restartAfter(
        () => player.openAll([
          Media(a),
          Media(b, start: const Duration(seconds: 2)),
        ], play: false),
      );
      expectNear(0, reason: 'the first entry has no start');
      await restartAfter(() => player.next());
      expectNear(2000);
      await restartAfter(() => player.previous());
      expectNear(0);
      // Back to it: it starts at its start again.
      await restartAfter(() => player.next());
      expectNear(2000);
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('replace gives the new entry its start', () async {
      await restartAfter(() => player.open(Media(a), play: false));
      // The current entry: the replacement loads at once.
      await restartAfter(
        () => player.replace(0, Media(b, start: const Duration(seconds: 3))),
      );
      expectNear(3000);
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('Loop.file starts the file again from its beginning', () async {
      await player.setLoop(Loop.file);
      await restartAfter(
        () => player.open(
          Media(a, start: const Duration(milliseconds: 4500)),
          play: true,
        ),
      );
      expectNear(4500);
      await waitUntil(
        () => player.state.position.inMilliseconds < 1000,
        timeout: const Duration(seconds: 4),
        reason: 'mpv loops a file from its start time, 0',
      );
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('start wins over a saved resume point', () async {
      final tmp = Directory.systemTemp.createTempSync('mak_start_resume_');
      addTearDown(() {
        try {
          tmp.deleteSync(recursive: true);
        } catch (_) {}
      });
      final p = await buildPlayer(
        configuration: PlayerConfiguration(
          logLevel: LogLevel.off,
          watchLaterDir: tmp.path,
        ),
      );
      addTearDown(p.dispose);
      Future<void> saveAt600() async {
        await p.seek(const Duration(milliseconds: 600));
        await waitUntil(() => p.state.position.inMilliseconds > 500);
        await p.writeResumeConfig();
        await waitUntil(() => tmp.listSync().isNotEmpty);
      }

      Future<void> reopen(Media media) async {
        final restarted = p.stream.seekCompleted.first.timeout(
          const Duration(seconds: 10),
        );
        await p.open(media, play: false);
        await restarted;
      }

      await openAndWaitForLoad(p, a);
      await saveAt600();
      await reopen(Media(a, start: const Duration(seconds: 2)));
      expect(p.state.position.inMilliseconds, closeTo(2000, 150));
      // mpv deletes a resume point once a load used it, start or not.
      await waitUntil(
        () => tmp.listSync().isEmpty,
        reason: 'the load used up the resume point',
      );

      // Without a start the resume point applies, as before.
      await saveAt600();
      await reopen(Media(a));
      expect(p.state.position.inMilliseconds, closeTo(600, 150));
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}
