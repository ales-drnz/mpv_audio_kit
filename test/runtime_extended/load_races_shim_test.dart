// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// Loads that a later call overtakes or that mpv refuses, driven through
// the slow-core shim: a reply held back keeps a load in flight for as long
// as the test needs to call something else meanwhile, and a refused
// loadfile stands in for a full reply queue. A test resolver stands in for
// a source that holds a platform resource, as an Android `content://`
// descriptor does, and counts its releases.

@TestOn('mac-os || linux')
@Timeout(Duration(minutes: 3))
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:mpv_audio_kit/src/internals/uri_resolver.dart';

import '../_helpers/setter_test_helpers.dart';
import '../_helpers/slow_core_shim.dart';

void main() {
  final dir = '${Directory.current.path}/test/fixtures';
  final fixturePath = '$dir/sine_440hz_1s.wav';
  final longFixture = '$dir/sine_5s.flac';

  slowCoreShimSuite(fixturePath: fixturePath, extraFixtures: [longFixture], (
    shim,
  ) {
    late Player player;

    setUp(() async {
      shim().reset();
      player = await buildPlayer();
    });

    tearDown(() async {
      shim().reset();
      debugResolveUriOverride = null;
      await player.dispose();
    });

    /// Plays [fixturePath] to the keep-open park at the end of the queue.
    Future<void> park() async {
      final completed = player.stream.completed
          .firstWhere((c) => c)
          .timeout(const Duration(seconds: 10));
      await player.open(Media(fixturePath), play: true);
      await completed;
    }

    /// Runs [load] with the reply to its [command] held back, and calls
    /// pause() while that reply waits: after mpv ran the command, before
    /// the load sees it.
    Future<void> pauseDuring(
      String command,
      Future<void> Function() load,
    ) async {
      shim().holdReply(command, const Duration(milliseconds: 400));
      final loading = load();
      await waitUntil(
        () => shim().counter('replies_held') > 0,
        reason: 'the $command reply was never held',
      );
      final pausing = player.pause();
      await loading;
      await pausing;
    }

    // At the park a load writes the unpause again once mpv replaced the
    // file, since keep-open undoes the first one. A pause() called while
    // the load waited for that reply has the last word.
    group('a pause() during a load at the end has the last word', () {
      test('open', () async {
        await park();
        await pauseDuring(
          'loadfile',
          () => player.open(Media(longFixture), play: true),
        );
        await Future<void>.delayed(const Duration(milliseconds: 300));
        expect(await player.getRawProperty('pause'), 'yes');
        expect(player.state.playWhenReady, isFalse);
      });

      test('openPlaylistFile', () async {
        final tmp = Directory.systemTemp.createTempSync('mak_m3u_');
        addTearDown(() => tmp.deleteSync(recursive: true));
        final list = File('${tmp.path}/list.m3u')
          ..writeAsStringSync('$longFixture\n');
        await park();
        await pauseDuring(
          'loadlist',
          () => player.openPlaylistFile(Media(list.path), play: true),
        );
        await Future<void>.delayed(const Duration(milliseconds: 300));
        expect(await player.getRawProperty('pause'), 'yes');
        expect(player.state.playWhenReady, isFalse);
      });
    });

    // mpv keeps what it had when it refuses a load: the track there goes
    // on as it did, with the intent it had.
    test('an open that mpv refuses leaves a paused track paused', () async {
      await openAndWaitForLoad(player, longFixture);
      shim().refuseLoadfile('mak-refused');
      await expectLater(
        player.open(Media('$dir/mak-refused.wav'), play: true),
        throwsA(isA<MpvCommandException>()),
      );
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(await player.getRawProperty('pause'), 'yes');
      expect(player.state.playWhenReady, isFalse);
      expect(player.state.playing, isFalse);
    });

    // openAll at the end of the queue steps through idle, and the intent
    // reset that idle makes waits for the load. Overtaken by a
    // clearPlaylist, the load ends with nothing to play: the reset lands
    // then.
    test('an openAll at the end overtaken by clearPlaylist leaves the '
        'intent off', () async {
      await park();
      shim().holdReply('loadfile', const Duration(milliseconds: 300));
      final opening = player.openAll([
        Media(fixturePath),
        Media(fixturePath),
      ], play: true);
      await waitUntil(
        () => shim().counter('replies_held') > 0,
        reason: 'the loadfile reply was never held',
      );
      await player.clearPlaylist();
      await opening;
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(await player.getRawProperty('idle-active'), 'yes');
      expect(player.state.playlist.items, isEmpty);
      expect(player.state.playWhenReady, isFalse);
    });

    // Each append holds one of the 1000 reply slots mpv keeps per client
    // until the player reads its reply, and mpv refuses a request once they
    // are all taken. With the replies held back, as on a busy device, an
    // album sent all at once runs out of them.
    test('an openAll of 3000 entries fits the reply queue', () async {
      const n = 3000;
      shim().holdReply('loadfile', const Duration(milliseconds: 300));
      await player.openAll([
        for (var i = 0; i < n; i++) Media(fixturePath),
      ], play: false);
      await waitUntil(() => player.state.playlist.items.length == n);
      expect(shim().counter('replies_held'), 1);
    });

    // A `test://` URI resolves to its own link to the long fixture, with a
    // release that is counted, as the player holds a `content://`
    // descriptor; `test://broken` fails to resolve.
    group('sources', () {
      late Directory tmp;
      late List<String> released;

      setUp(() {
        tmp = Directory.systemTemp.createTempSync('mak_src_');
        released = [];
        debugResolveUriOverride = (uri) async {
          if (!uri.startsWith('test://')) return ResolvedUri(uri);
          final name = uri.substring('test://'.length);
          if (name == 'broken') throw SourceException(uri, 'no descriptor');
          final link = Link('${tmp.path}/$name.flac');
          if (!link.existsSync()) link.createSync(longFixture);
          return ResolvedUri(link.path, () async => released.add(uri));
        };
      });

      tearDown(() async {
        await player.dispose();
        tmp.deleteSync(recursive: true);
      });

      List<Media> album(String name, int n) => [
        for (var i = 0; i < n; i++) Media('test://$name$i'),
      ];

      /// The test entries the playlist lists.
      Set<String> listed() => {
        for (final m in player.state.playlist.items)
          if (m.uri.startsWith('test://')) m.uri,
      };

      /// Runs [load] with the reply to its [command] held back, and while
      /// it waits overtakes it with an open() that fails to resolve, so
      /// nothing replaces what mpv took from [load].
      Future<void> overtake(
        String command,
        Future<void> Function() load,
      ) async {
        shim().holdReply(command, const Duration(milliseconds: 400));
        final loading = load();
        await waitUntil(
          () => shim().counter('replies_held') > 0,
          reason: 'the $command reply was never held',
        );
        await expectLater(
          player.open(const Media('test://broken')),
          throwsA(isA<SourceException>()),
        );
        await loading;
      }

      // mpv reads an fd:// entry again on every open of it (a previous, a
      // loop, a prefetch): closed while listed, the number goes to the next
      // descriptor the app opens.
      test('an openAll overtaken after its appends keeps them', () async {
        await overtake(
          'loadfile',
          () => player.openAll(album('a', 3), play: false),
        );
        await waitUntil(
          () => listed().length == 3,
          reason: 'mpv never listed the entries',
        );
        await Future<void>.delayed(const Duration(milliseconds: 200));
        expect(released, isEmpty, reason: 'released while mpv lists them');
      });

      test('an openAll overtaken after its jump keeps them', () async {
        await player.open(Media(longFixture), play: true);
        await waitUntil(() => player.state.playing);
        await overtake(
          'playlist-play-index',
          () => player.openAll(album('b', 3), play: true),
        );
        await waitUntil(
          () => listed().length == 3,
          reason: 'mpv never listed the entries',
        );
        await Future<void>.delayed(const Duration(milliseconds: 200));
        expect(await player.getRawProperty('path'), endsWith('b0.flac'));
        expect(released, isEmpty, reason: 'released while mpv plays one');
      });

      // mpv refuses an append only when its reply queue is full. The call
      // fails as a whole: the entries that went in come out again, the
      // track that played goes on with its intent, and the refused
      // entry's source is released.
      group('an openAll with a refused append', () {
        test('while a track plays', () async {
          await player.open(Media(longFixture), play: true);
          await waitUntil(() => player.state.playing);
          shim().refuseLoadfile('refused');
          await expectLater(
            player.openAll([
              const Media('test://c0'),
              const Media('test://refused-c1'),
              const Media('test://c2'),
            ], play: false),
            throwsA(isA<MpvCommandException>()),
          );
          await Future<void>.delayed(const Duration(milliseconds: 300));
          expect(player.state.playlist.items.map((m) => m.uri), [longFixture]);
          expect(player.state.playWhenReady, isTrue);
          expect(player.state.playing, isTrue);
          expect(released, contains('test://refused-c1'));
        });

        test('at the end of the queue', () async {
          await park();
          shim().refuseLoadfile('refused');
          await expectLater(
            player.openAll([
              const Media('test://d0'),
              const Media('test://refused-d1'),
            ], play: true),
            throwsA(isA<MpvCommandException>()),
          );
          await Future<void>.delayed(const Duration(milliseconds: 300));
          expect(player.state.playlist.items, isEmpty);
          expect(player.state.playWhenReady, isFalse);
          expect(await player.getRawProperty('idle-active'), 'yes');
          expect(released, contains('test://refused-d1'));
        });
      });

      // A source mpv never took is released at once, not at dispose.
      group('released when mpv never took the entry', () {
        Future<void> queueOfFour() async {
          await player.openAll([
            for (var i = 0; i < 4; i++) Media(longFixture),
          ], play: false);
          await waitUntil(() => player.state.playlist.items.length == 4);
        }

        test('a replace whose index a remove took first', () async {
          await queueOfFour();
          final replacing = player.replace(3, const Media('test://r0'));
          await player.remove(3);
          await expectLater(replacing, throwsA(isA<MpvCommandException>()));
          expect(released, ['test://r0']);
        });

        test('a replace overtaken by an open', () async {
          await queueOfFour();
          shim().holdReply('playlist-pos', const Duration(milliseconds: 400));
          final replacing = player.replace(1, const Media('test://r1'));
          await waitUntil(
            () => shim().counter('replies_held') > 0,
            reason: 'the playlist-pos reply was never held',
          );
          final opening = player.open(Media(fixturePath));
          await replacing;
          await opening;
          expect(released, ['test://r1']);
        });

        test('an add that mpv refuses', () async {
          await queueOfFour();
          shim().refuseLoadfile('refused');
          await expectLater(
            player.add(const Media('test://refused-add')),
            throwsA(isA<MpvCommandException>()),
          );
          expect(released, ['test://refused-add']);
        });

        test('an open that mpv refuses', () async {
          await queueOfFour();
          shim().refuseLoadfile('refused');
          await expectLater(
            player.open(const Media('test://refused-open')),
            throwsA(isA<MpvCommandException>()),
          );
          expect(released, ['test://refused-open']);
        });
      });
    });

    group('test seams', () {
      test('a refused loadfile fails like a full reply queue', () async {
        shim().refuseLoadfile('mak-refused');
        await expectLater(
          player.open(Media('$dir/mak-refused.wav')),
          throwsA(
            isA<MpvCommandException>().having(
              (e) => e.code,
              'code',
              MpvError.mpvErrorEventQueueFull,
            ),
          ),
        );
        expect(shim().counter('loadfiles_refused'), 1);
        // Other loads go through.
        await openAndWaitForLoad(player, fixturePath);
      });

      test('the test resolver stands in for every load', () async {
        final released = <String>[];
        debugResolveUriOverride = (uri) async =>
            ResolvedUri(fixturePath, () async => released.add(uri));
        await player.open(const Media('test://one'), play: false);
        await waitUntil(
          () async => await player.getRawProperty('path') == fixturePath,
        );
        expect(released, isEmpty, reason: 'mpv still lists the entry');
        await player.dispose();
        expect(released, ['test://one']);
      });
    });
  });
}
