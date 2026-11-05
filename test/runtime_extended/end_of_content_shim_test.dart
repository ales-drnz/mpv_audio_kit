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
import 'package:mpv_audio_kit/src/internals/uri_resolver.dart';
import 'package:mpv_audio_kit/src/mpv_constants.dart';

import '../_helpers/long_wav.dart';
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

      /// Parks on an entry with no audio frames, the last one of [before]
      /// and it, with play: true, and returns its path. A seek back to 0
      /// there finds the end at once.
      Future<String> parkOnEmpty({List<String> before = const []}) async {
        final tmp = Directory.systemTemp.createTempSync('mak_eoc_shim');
        addTearDown(() => tmp.deleteSync(recursive: true));
        final empty = File('${tmp.path}/empty.wav')
          ..writeAsBytesSync(longWav(0));
        await player.setAudioNullUntimed(true);
        final uris = [...before, empty.path];
        await player.openAll(uris.map(Media.new).toList(), play: true);
        await waitUntil(
          () async =>
              player.state.completed &&
              await player.getRawProperty('playlist-pos') ==
                  '${uris.length - 1}',
          timeout: const Duration(seconds: 10),
          reason: 'never parked on the empty entry',
        );
        // The reads the park itself started are done by then.
        await Future<void>.delayed(const Duration(milliseconds: 300));
        expect(player.state.playWhenReady, isFalse);
        expect(await player.getRawProperty('seekable'), 'yes');
        return empty.path;
      }

      /// Records the changes of `completed` from now on.
      List<bool> recordCompletions() {
        final completions = <bool>[];
        final sub = player.stream.completed.skip(1).listen(completions.add);
        addTearDown(sub.cancel);
        return completions;
      }

      /// Expects the player parked again at the end, with the intent spent.
      Future<void> expectParkedOff(String why) async {
        await waitUntil(
          () async =>
              await player.getRawProperty('eof-reached') == 'yes' &&
              await player.getRawProperty('pause') == 'yes',
          reason: 'mpv never parked again',
        );
        // The reads keep-open's pause can still start.
        await Future<void>.delayed(const Duration(milliseconds: 300));
        expect(player.state.completed, isTrue);
        expect(player.state.playWhenReady, isFalse, reason: why);
        expect(player.state.playing, isFalse);
      }

      // play() at the park of an entry with no audio frames: its seek back
      // to 0 finds the end at once and the core parks again before the
      // unpause. The restart of that seek clears completed and the
      // end-of-content read after it raises it again, in a new park, ahead
      // of the reply of play()'s `pause no`: the shim sends that write only
      // once the pump has sent the reads of the restart. keep-open undoes
      // the unpause too fast for a notification: the intent of play() must
      // end with the new park, whatever comes last.
      test(
        'play() at a park its seek lands on again ends its intent',
        () async {
          await parkOnEmpty();
          final completions = recordCompletions();
          shim().deferRequest(
            'pause',
            afterEvent: MpvEventId.mpvEventPlaybackRestart,
          );
          await player.play();
          expect(
            shim().counter('deferred_sent'),
            1,
            reason: 'the unpause must go after the restart',
          );
          expect(
            completions,
            containsAllInOrder([false, true]),
            reason:
                'the seek left the park and landed on the end again, read '
                'before the reply of the unpause',
          );
          await expectParkedOff(
            'parked at the end again: the intent of play() is spent',
          );
        },
      );

      // The same with nothing held back: the reply of the unpause and the
      // read of the new park come in the order the core gives.
      test('play() at a park its seek lands on again ends its intent, nothing '
          'held', () async {
        await parkOnEmpty();
        await player.play();
        await expectParkedOff(
          'parked at the end again: the intent of play() is spent',
        );
      });

      // jump() at the park to an entry that parks as soon as it loads: the
      // read of the restart that starts it finds the end, ahead of the
      // reply of the corrective `pause no` the jump writes after
      // `playlist-play-index`. Not the read of its FILE_LOADED: the entry
      // has not decoded to its end yet then.
      test('jump() to an entry that parks at once ends its intent', () async {
        await parkOnEmpty(before: [shortFixture]);
        final completions = recordCompletions();
        // The first `pause` is the one before the jump.
        shim().deferRequest(
          'pause',
          afterEvent: MpvEventId.mpvEventPlaybackRestart,
          skip: 1,
        );
        await player.jump(1);
        expect(
          shim().counter('deferred_sent'),
          1,
          reason: 'the corrective unpause must go after the restart',
        );
        expect(completions, containsAllInOrder([false, true]));
        await expectParkedOff(
          'the entry the jump started parked: the intent of jump() is spent',
        );
      });

      // play() called while the read of the park is on its way: the read
      // lands after play() claimed the intent and before the seek leaves
      // the park. It belongs to the park play() leaves, and must not end
      // the playback that follows.
      test('play() at a park with a stale read of it keeps playing', () async {
        final completions = recordCompletions();
        shim().set('stall_park_read_us', 600000);
        await openAndWaitForLoad(player, longFixture);
        await player.seek(const Duration(milliseconds: 4700));
        await player.play();
        await waitUntil(
          () => shim().counter('park_reads_stalled') > 0,
          timeout: const Duration(seconds: 10),
          reason: 'mpv never parked',
        );
        await player.play();
        expect(completions, contains(true), reason: 'the park read landed');
        await waitUntil(
          () async =>
              await player.getRawProperty('pause') == 'no' &&
              player.state.playing,
          reason: 'play() at the park must play',
        );
        expect(player.state.playWhenReady, isTrue);
        expect(player.state.position, lessThan(const Duration(seconds: 4)));
      });

      // play() at a park while a seek to the end, called just before it, is
      // still on its way: play() reads the park and takes it, then the
      // earlier seek lands on the end again, and the read of its restart
      // spends the intent, all before the seek of play() leaves for 0. The
      // shim holds the earlier seek until play() sends its own, and that
      // one until the restart of the earlier seek has been read. The
      // player then plays from the start, and the intent must say so.
      test('play() at a park with a seek to the end in flight plays from '
          'the start', () async {
        await openAndWaitForLoad(player, longFixture);
        await player.seek(const Duration(milliseconds: 4700));
        await player.play();
        await waitUntil(
          () async =>
              player.state.completed &&
              await player.getRawProperty('eof-reached') == 'yes' &&
              await player.getRawProperty('pause') == 'yes',
          timeout: const Duration(seconds: 10),
          reason: 'mpv never parked',
        );
        // The reads the park itself started are done by then.
        await Future<void>.delayed(const Duration(milliseconds: 300));
        expect(player.state.playWhenReady, isFalse);
        final completions = recordCompletions();
        shim()
          ..holdRequest('seek')
          ..deferRequest(
            'seek',
            afterEvent: MpvEventId.mpvEventPlaybackRestart,
          );
        // To the end itself: a seek short of it leaves audio to play, which
        // keep-open-parked does not take for a park (libmpv-r22).
        final toEnd = player.seek(const Duration(seconds: 5));
        await player.play();
        await toEnd;
        expect(
          shim().counter('held_requests_sent'),
          1,
          reason:
              'the seek to the end must reach mpv after the reads of play()',
        );
        expect(
          shim().counter('deferred_sent'),
          1,
          reason: 'the seek of play() must go after the restart of the first',
        );
        // The reads of the two restarts reach the stream after the reply of
        // play(), so they are waited for.
        await waitUntil(
          () =>
              containsAllInOrder([false, true, false]).matches(completions, {}),
          reason:
              'the seek to the end landed on the end, read before the seek '
              'of play() left it',
        );
        await waitUntil(
          () async =>
              await player.getRawProperty('pause') == 'no' &&
              player.state.playing,
          reason: 'play() at the park must play',
        );
        // The reads of the restart of play()'s seek.
        await Future<void>.delayed(const Duration(milliseconds: 300));
        expect(player.state.playing, isTrue);
        expect(
          player.state.playWhenReady,
          isTrue,
          reason: 'playing from the start: the intent of play() stands',
        );
        expect(player.state.position, lessThan(const Duration(seconds: 2)));
      });

      group('a park reached while a load runs', () {
        setUp(() {
          // A `slow://` URI resolves to the long fixture after its delay
          // in milliseconds.
          debugResolveUriOverride = (uri) async {
            if (!uri.startsWith('slow://')) return ResolvedUri(uri);
            await Future<void>.delayed(
              Duration(milliseconds: int.parse(uri.substring(7))),
            );
            return ResolvedUri(longFixture);
          };
        });

        tearDown(() => debugResolveUriOverride = null);

        // The 1 s track parks while the load resolves its source: the load
        // replaces it, and plays.
        test('keeps the intent of the load', () async {
          await player.open(Media(fixturePath), play: true);
          await waitUntil(() => player.state.playing);
          final completions = recordCompletions();
          await player.open(const Media('slow://1500'), play: true);
          expect(completions, contains(true), reason: 'no park in the load');
          await waitUntil(
            () async =>
                await player.getRawProperty('pause') == 'no' &&
                player.state.playing,
            reason: 'the load must play',
          );
          expect(player.state.playWhenReady, isTrue);
        });

        // A clearPlaylist() that keeps the parked entry supersedes the load
        // before it sends anything: the core stays in the park, which spends
        // the intent once the load is over.
        test('spends the intent when the load is superseded', () async {
          await player.open(Media(fixturePath), play: true);
          await waitUntil(() => player.state.playing);
          final load = player.open(const Media('slow://2500'), play: true);
          await waitUntil(
            () => player.state.completed,
            reason: 'the 1 s track never parked',
          );
          expect(
            player.state.playWhenReady,
            isTrue,
            reason: 'the park waits for the load',
          );
          await player.clearPlaylist(keepCurrent: true);
          await load;
          expect(player.state.completed, isTrue);
          expect(player.state.playWhenReady, isFalse);
        });
      });

      // play() at the park of an entry with no audio frames while an open()
      // that mpv refuses runs: the seek of play() lands on the end again,
      // and the load that failed leaves nothing to play.
      test('play() at a park with a refused load in flight ends its '
          'intent', () async {
        final empty = await parkOnEmpty();
        shim().refuseLoadfile('mak-refused');
        final load = player.open(
          Media('${File(empty).parent.path}/mak-refused.wav'),
          play: true,
        );
        final play = player.play();
        await expectLater(load, throwsA(isA<MpvCommandException>()));
        await play;
        expect(shim().counter('loadfiles_refused'), 1);
        await expectParkedOff('nothing plays: the intent is spent');
      });

      // A park the player sees while mpv plays on (freeze_park), whose
      // intent a play() sets again: the loop changes after it read the same
      // park, and spend nothing more. Each park spends the intent once.
      test(
        'a loop toggled at a park does not spend its intent again',
        () async {
          await player.open(Media(longFixture), play: true);
          await waitUntil(() => player.state.playing);
          shim().set('freeze_park', 1);
          await player.setLoop(Loop.file);
          await player.setLoop(Loop.off);
          await waitUntil(
            () => player.state.completed,
            timeout: const Duration(seconds: 2),
            reason: 'the read must find the park',
          );
          expect(player.state.playWhenReady, isFalse);
          await player.play();
          expect(player.state.playWhenReady, isTrue);
          final completions = recordCompletions();
          await player.setLoop(Loop.file);
          await waitUntil(() => !player.state.completed);
          await player.setLoop(Loop.off);
          await waitUntil(
            () => player.state.completed,
            timeout: const Duration(seconds: 2),
            reason: 'the read must find the park again',
          );
          await Future<void>.delayed(const Duration(milliseconds: 200));
          expect(completions, [false, true]);
          expect(player.state.playWhenReady, isTrue);
          expect(await player.getRawProperty('pause'), 'no');
        },
      );

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
          // kit-core-4: the new value comes with completed, as at any end.
          final completions = <bool>[];
          final sub = player.stream.completed.listen(completions.add);
          addTearDown(sub.cancel);
          await Future<void>.delayed(Duration.zero);
          completions.clear();
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
          expect(completions, [
            false,
            true,
          ], reason: 'completed turns false and true again with the new read');
        });
      });
    },
  );
}
