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

import '../_helpers/range_http_server.dart';
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

      // A seek at the park that lands on the end again at once. The read
      // that sees the end finds pause 0 (shim), as when it lands while an
      // unpause of play() is in effect that keep-open undoes before mpv
      // samples pause: mpv then sends no change of pause, nor of
      // eof-reached, and nothing else reads the core again.
      test(
        'a park read while an unpause was in effect is read again',
        () async {
          final flac = File(longFixture).readAsBytesSync();
          final server = await RangeHttpServer.start({'a.flac': flac});
          addTearDown(server.close);
          server
            ..dropAfterBytes = flac.length ~/ 2
            ..outageAfterDrop = true;
          await player.setAudioNullUntimed(true);
          final parked = player.stream.completed
              .firstWhere((c) => c)
              .timeout(const Duration(seconds: 30));
          await player.open(
            Media(
              server.url('a.flac'),
              streamLavfOptions: const {
                'reconnect': '0',
                'reconnect_on_network_error': '0',
              },
            ),
            play: true,
          );
          await parked;
          // The reads the park itself started are done by then.
          await Future<void>.delayed(const Duration(milliseconds: 300));
          final completions = <bool>[];
          final sub = player.stream.completed.listen(completions.add);
          addTearDown(sub.cancel);
          shim().set('pause_zero_once', 1);
          // Past the cut, while the server is down: the end again at once.
          await player.seek(const Duration(seconds: 3));
          await waitUntil(
            () async =>
                shim().counter('pause_zero_reads') > 0 &&
                await player.getRawProperty('eof-reached') == 'yes' &&
                await player.getRawProperty('pause') == 'yes',
            reason: 'mpv never parked again, or no read found it there',
          );
          expect(completions, contains(false), reason: 'the read saw no park');
          await waitUntil(
            () => player.state.completed,
            timeout: const Duration(seconds: 2),
            reason: 'the park must be read again',
          );
        },
      );

      // A seek and a play() at the park whose leave no read of the event
      // isolate sees: with freeze_park its eof-reached and pause reads
      // answer 1, as when the core leaves and parks again between two of
      // its reads (a slow pump on a loaded runner). The seek's restart
      // still leaves the park: the new park is an edge of completed, and
      // the intent of play() ends with it.
      test('a park the player never sees left is a new end', () async {
        await player.setAudioNullUntimed(true);
        final parked = player.stream.completed
            .firstWhere((c) => c)
            .timeout(const Duration(seconds: 30));
        await player.open(Media(longFixture), play: true);
        await parked;
        await Future<void>.delayed(const Duration(milliseconds: 300));
        expect(player.state.playWhenReady, isFalse);
        final completions = <bool>[];
        final sub = player.stream.completed.skip(1).listen(completions.add);
        addTearDown(sub.cancel);
        shim().set('freeze_park', 1);
        await player.seek(const Duration(seconds: 3));
        await player.play();
        await waitUntil(
          () async =>
              await player.getRawProperty('eof-reached') == 'yes' &&
              await player.getRawProperty('pause') == 'yes' &&
              player.state.position > const Duration(seconds: 4),
          timeout: const Duration(seconds: 10),
          reason: 'mpv never parked at the end again',
        );
        await Future<void>.delayed(const Duration(milliseconds: 300));
        expect(player.state.completed, isTrue);
        expect(
          completions,
          containsAllInOrder([false, true]),
          reason: 'the seek left the park and the play parked again',
        );
        expect(
          player.state.playWhenReady,
          isFalse,
          reason: 'the intent of play() ends at the new park',
        );
      });

      libmpvReleaseGroup(20, 'A park the player never sees left', () {
        // A seek at the park and the play to the end can both go by
        // between two reads, as with an output that does not wait: the
        // new park must still say how the entry ended this time.
        test('reads how the entry ended again', () async {
          final flac = File(longFixture).readAsBytesSync();
          final server = await RangeHttpServer.start({'a.flac': flac});
          addTearDown(server.close);
          server
            ..dropAfterBytes = flac.length ~/ 2
            ..outageAfterDrop = true;
          await player.setAudioNullUntimed(true);
          final parked = player.stream.completed
              .firstWhere((c) => c)
              .timeout(const Duration(seconds: 30));
          await player.open(
            Media(
              server.url('a.flac'),
              streamLavfOptions: const {'reconnect': '0'},
            ),
            play: true,
          );
          await parked;
          expect(player.state.readError, isTrue, reason: server.describe());
          shim().set('freeze_park', 1);
          server.comeBack();
          await player.seek(const Duration(seconds: 3));
          await player.play();
          await waitUntil(
            () async =>
                await player.getRawProperty('demuxer-read-error') == 'no' &&
                await player.getRawProperty('eof-reached') == 'yes' &&
                await player.getRawProperty('pause') == 'yes',
            timeout: const Duration(seconds: 15),
            reason: 'mpv never parked at the real end (${server.describe()})',
          );
          expect(
            player.state.completed,
            isTrue,
            reason: 'parked at the real end',
          );
          await waitUntil(
            () => player.state.readError == false,
            reason: 'the park at the real end reads how it ended again',
          );
        });
      });
    },
  );
}
