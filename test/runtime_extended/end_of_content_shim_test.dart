// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// The end-of-content read and the keep-open park, driven through the
// slow-core shim. With a local file mpv never stays parked with a loop on
// (it restarts the file), and `completed` is already true at the park by
// the time a test calls the transport: the shim reaches the states the
// fixes are about, a loop change with nothing else moving and a park the
// player has not seen.

@TestOn('mac-os || linux')
@Timeout(Duration(minutes: 3))
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

import '../_helpers/setter_test_helpers.dart';
import '../_helpers/slow_core_shim.dart';

void main() {
  final dir = '${Directory.current.path}/test/fixtures';
  final shortFixture = '$dir/sine_50ms.wav';
  final fixturePath = '$dir/sine_440hz_1s.wav';
  final longFixture = '$dir/sine_5s.flac';

  slowCoreShimSuite(
    fixturePath: fixturePath,
    extraFixtures: [shortFixture, longFixture],
    (shim) {
      late Player player;

      setUp(() async {
        shim().reset();
        player = await buildPlayer();
      });

      tearDown(() async {
        shim().reset();
        await player.dispose();
      });

      test('a loop change takes a fresh end-of-content read', () async {
        // Paused mid-file: no eof-reached or pause change follows a loop
        // change, so only the loop trigger can start the read.
        await openAndWaitForLoad(player, longFixture);
        await Future<void>.delayed(const Duration(milliseconds: 200));
        for (final loop in [Loop.file, Loop.off, Loop.playlist, Loop.off]) {
          shim().watchGet('eof-reached');
          await player.setLoop(loop);
          await waitUntil(
            () => shim().counter('watched_gets') > 0,
            timeout: const Duration(seconds: 2),
            reason: 'setLoop($loop) took no end-of-content read',
          );
        }
      });

      /// Plays [uris] to the keep-open park with the event isolate's
      /// `eof-reached` reads answering `no`: mpv is parked, and `completed`
      /// stays false, as when its notifications were skipped.
      Future<void> parkUnseen(List<String> uris) async {
        shim().set('hide_eof', 1);
        await player.openAll(
          uris.map(Media.new).toList(growable: false),
          play: true,
        );
        await waitUntil(
          () async =>
              await player.getRawProperty('eof-reached') == 'yes' &&
              await player.getRawProperty('pause') == 'yes' &&
              await player.getRawProperty('playlist-pos') ==
                  '${uris.length - 1}',
          timeout: const Duration(seconds: 15),
          reason: 'mpv never parked at the end',
        );
        await Future<void>.delayed(const Duration(milliseconds: 100));
        expect(
          player.state.completed,
          isFalse,
          reason: 'the shim must hide the park from completed',
        );
        shim().set('hide_eof', 0);
      }

      Future<void> expectUnpausedAfterLoad(
        Future<void> Function() call,
        String what,
      ) async {
        final loaded = player.stream.seekCompleted.first.timeout(
          const Duration(seconds: 10),
        );
        await call();
        await loaded;
        expect(
          await player.getRawProperty('pause'),
          'no',
          reason: '$what from an unseen park must not keep the pause',
        );
      }

      test('open(play: true) from an unseen park starts unpaused', () async {
        await parkUnseen([shortFixture]);
        await expectUnpausedAfterLoad(
          () => player.open(Media(fixturePath), play: true),
          'open',
        );
      });

      test('jump() from an unseen park starts unpaused', () async {
        await parkUnseen([fixturePath, shortFixture]);
        await expectUnpausedAfterLoad(() => player.jump(0), 'jump');
      });

      test('openPlaylistFile(play: true) from an unseen park starts '
          'unpaused', () async {
        final tmp = Directory.systemTemp.createTempSync('mak_eoc_shim');
        try {
          final m3u = File('${tmp.path}/list.m3u')
            ..writeAsStringSync('$fixturePath\n$shortFixture\n');
          await parkUnseen([shortFixture]);
          await expectUnpausedAfterLoad(
            () => player.openPlaylistFile(Media(m3u.path), play: true),
            'openPlaylistFile',
          );
        } finally {
          tmp.deleteSync(recursive: true);
        }
      });

      test('openAll(play: true) from an unseen park never starts the new '
          'first entry', () async {
        await parkUnseen([shortFixture]);
        // mpv logs every file it starts ("Playing: <path>").
        player.setLogLevel(LogLevel.info);
        final started = <String>[];
        final sub = player.stream.log
            .where((e) => e.text.contains('Playing:'))
            .listen((e) => started.add(e.text.trim()));
        try {
          await expectUnpausedAfterLoad(
            () => player.openAll(
              [Media(longFixture), Media(fixturePath)],
              index: 1,
              play: true,
            ),
            'openAll',
          );
          await Future<void>.delayed(const Duration(milliseconds: 200));
        } finally {
          await sub.cancel();
        }
        expect(
          started,
          isNot(anyElement(contains('sine_5s.flac'))),
          reason:
              'the parked entry must leave before the appends, or mpv '
              'advances into the new entry 0 ($started)',
        );
        expect(player.state.playlist.items.length, 2);
      });

      test('play() from an unseen park starts the track again', () async {
        await parkUnseen([longFixture]);
        await player.play();
        await waitUntil(
          () async =>
              await player.getRawProperty('pause') == 'no' &&
              player.state.playing,
          reason: 'play() at an unseen park must play',
        );
        expect(
          player.state.position,
          lessThan(const Duration(seconds: 4)),
          reason: 'the last track starts again from its beginning',
        );
      });
    },
  );
}
