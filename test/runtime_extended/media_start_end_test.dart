// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

// Media.start and Media.end: where an entry starts and stops, as mpv's
// per-file `start` and `end`.

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
        // Wait for the landing, not the position: after a start of 2 s the
        // position is already past 500, and a restart still in flight
        // would end the next reopen's wait with the old file's event.
        final landed = p.stream.seekCompleted.first.timeout(
          const Duration(seconds: 10),
        );
        await p.seek(const Duration(milliseconds: 600));
        await landed;
        expect(p.state.position.inMilliseconds, closeTo(600, 150));
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

    test('end finishes the last entry there, as its end', () async {
      final completed = player.stream.completed
          .firstWhere((c) => c)
          .timeout(const Duration(seconds: 10));
      await player.open(Media(a, end: const Duration(seconds: 2)), play: true);
      await completed;
      expect(
        player.state.position.inMilliseconds,
        inInclusiveRange(1800, 2300),
      );
      expect(player.state.duration.inMilliseconds, greaterThan(4500));
      expect(await player.getRawProperty('pause'), 'yes');
      expect(player.state.playWhenReady, isFalse);
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('end moves the playlist on there', () async {
      final started = DateTime.now();
      await player.openAll([
        Media(a, end: const Duration(seconds: 1)),
        Media(b),
      ], play: true);
      await waitUntil(
        () => player.state.playlist.index == 1,
        timeout: const Duration(seconds: 4),
        reason: 'the first entry ends at 1 s, not at 5 s',
      );
      expect(DateTime.now().difference(started).inMilliseconds, lessThan(3000));
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('start and end play the section between them', () async {
      final completed = player.stream.completed
          .firstWhere((c) => c)
          .timeout(const Duration(seconds: 10));
      await restartAfter(
        () => player.open(
          Media(
            a,
            start: const Duration(seconds: 1),
            end: const Duration(seconds: 2),
          ),
          play: true,
        ),
      );
      expect(player.state.position.inMilliseconds, greaterThanOrEqualTo(900));
      await completed;
      expect(
        player.state.position.inMilliseconds,
        inInclusiveRange(1800, 2300),
      );
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('an end not after start is refused before mpv', () async {
      await restartAfter(
        () => player.openAll([Media(a), Media(b)], play: false),
      );
      final items = player.state.playlist.items;
      final intent = player.state.playWhenReady;
      const bad = [Duration.zero, Duration(milliseconds: -1)];
      for (final end in bad) {
        final m = Media(b, end: end);
        await expectLater(player.open(m), throwsArgumentError);
        await expectLater(player.openAll([Media(a), m]), throwsArgumentError);
        await expectLater(player.add(m), throwsArgumentError);
        await expectLater(player.replace(1, m), throwsArgumentError);
      }
      final late = Media(
        b,
        start: const Duration(seconds: 2),
        end: const Duration(seconds: 1),
      );
      await expectLater(player.open(late, play: true), throwsArgumentError);
      expect(player.state.playlist.items, items);
      expect(player.state.playWhenReady, intent);
      expect(await player.getRawProperty('playlist-count'), '2');
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}
