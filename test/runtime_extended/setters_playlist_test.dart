// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'dart:io';

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

import '../_helpers/setter_test_helpers.dart';

void main() {
  final fixturePath = defaultFixturePath();

  runtimeSuite(fixturePath: fixturePath, () {
    group('Playlist mutation / navigation setters end-to-end', () {
      late Player player;

      setUpAll(() async {
        player = await buildPlayer();
      });

      tearDownAll(() async {
        // Stop + clear before dispose to avoid demuxer threads stalling
        // the dispose chain on multi-item playlists (see
        // setters_open_prefetch_test.dart for the same mitigation).
        await player.stop();
        await player.clearPlaylist();
        await player.dispose();
      });

      test('add appends a track and updates state.playlist length', () async {
        await player.openAll([Media(fixturePath)], play: false);
        await player.stream.playlist
            .firstWhere((p) => p.items.length == 1)
            .timeout(const Duration(seconds: 5));
        expect(player.state.playlist.items.length, 1);

        await player.add(Media(fixturePath));
        await player.stream.playlist
            .firstWhere((p) => p.items.length == 2)
            .timeout(const Duration(seconds: 5));
        expect(player.state.playlist.items.length, 2);
      }, timeout: const Timeout(Duration(seconds: 30)));

      test('jump moves to the requested index', () async {
        // Playlist now has 2 entries from the previous test.
        await player.jump(1);
        await player.stream.playlist
            .firstWhere((p) => p.index == 1)
            .timeout(const Duration(seconds: 5));
        expect(player.state.playlist.index, 1);
      }, timeout: const Timeout(Duration(seconds: 15)));

      test('move reorders entries (1 → 0)', () async {
        // 2-item playlist; move the second entry to position 0. The
        // current entry (index 1) moves with it, so the index follows.
        await player.move(1, 0);
        await waitUntil(() => player.state.playlist.index == 0);
        expect(player.state.playlist.items.length, 2);
      }, timeout: const Timeout(Duration(seconds: 15)));

      test('remove drops an entry', () async {
        // Drop position 1.
        await player.remove(1);
        await player.stream.playlist
            .firstWhere((p) => p.items.length == 1)
            .timeout(const Duration(seconds: 5));
        expect(player.state.playlist.items.length, 1);
      }, timeout: const Timeout(Duration(seconds: 15)));

      test('clearPlaylist empties the queue', () async {
        await player.clearPlaylist();
        // mpv's `playlist-clear` + `playlist-remove current` collapses
        // the queue. The observer eventually emits an empty playlist.
        await player.stream.playlist
            .firstWhere((p) => p.items.isEmpty)
            .timeout(const Duration(seconds: 5));
        expect(player.state.playlist.items, isEmpty);
      }, timeout: const Timeout(Duration(seconds: 15)));

      test('setShuffle / setLoop round-trip', () async {
        await player.openAll([
          Media(fixturePath),
          Media(fixturePath),
        ], play: false);
        await player.stream.playlist
            .firstWhere((p) => p.items.length == 2)
            .timeout(const Duration(seconds: 5));

        await player.setShuffle(true);
        expect(player.state.shuffle, isTrue);
        await player.setShuffle(false);
        expect(player.state.shuffle, isFalse);

        await player.setLoop(Loop.file);
        expect(player.state.loop, Loop.file);
        await player.setLoop(Loop.playlist);
        expect(player.state.loop, Loop.playlist);
        await player.setLoop(Loop.off);
        expect(player.state.loop, Loop.off);
      }, timeout: const Timeout(Duration(seconds: 30)));

      test('setLoop between two modes never passes through off', () async {
        await player.setLoop(Loop.file);
        addTearDown(() => player.setLoop(Loop.off));
        final seen = <Loop>[];
        final sub = player.stream.loop.skip(1).listen(seen.add);
        await player.setLoop(Loop.playlist);
        await player.setLoop(Loop.file);
        // Let mpv's echoes of both writes land.
        await Future<void>.delayed(const Duration(milliseconds: 300));
        await sub.cancel();
        expect(seen, [Loop.playlist, Loop.file]);
      }, timeout: const Timeout(Duration(seconds: 15)));

      test('a negative index throws RangeError even racing dispose', () async {
        // Checked before the playlist-count read: after a dispose that read
        // lets any index through, so only the early check still catches it.
        final other = await buildPlayer();
        final calls = [
          other.jump(-1),
          other.remove(-1),
          other.move(-1, 0),
          other.move(0, -1),
          other.replace(-1, Media(fixturePath)),
        ];
        final disposed = other.dispose();
        for (final call in calls) {
          await expectLater(call, throwsRangeError);
        }
        await disposed;
      });

      test('next() / previous() advance the playlist index', () async {
        // 3-item playlist so next/previous have a clear before/after to
        // anchor on. jump(0) is the documented entry point; next/prev
        // are the convenience wrappers tested here.
        await player.openAll([
          Media(fixturePath),
          Media(fixturePath),
          Media(fixturePath),
        ], play: false);
        await player.stream.playlist
            .firstWhere((p) => p.items.length == 3)
            .timeout(const Duration(seconds: 5));

        // Subscribed before each command: the replay only gives a late
        // subscriber the current index, not a transition already past.
        Future<void> waitFor(int idx) => player.stream.playlist
            .firstWhere((p) => p.index == idx)
            .timeout(const Duration(seconds: 5));

        final advancedTo1 = waitFor(1);
        await player.next();
        await advancedTo1;
        expect(player.state.playlist.index, 1);

        final advancedTo2 = waitFor(2);
        await player.next();
        await advancedTo2;
        expect(player.state.playlist.index, 2);

        final backTo1 = waitFor(1);
        await player.previous();
        await backTo1;
        expect(player.state.playlist.index, 1);
      }, timeout: const Timeout(Duration(seconds: 30)));

      test(
        'replace(index, media) swaps the entry without changing the length',
        () async {
          // Use two distinct fixture URIs so the replaced entry is
          // observably different. The primary fixture above is
          // sine_440hz_1s.wav; with_chapters.mka serves as the alt.
          final altPath =
              '${Directory.current.path}/test/fixtures/with_chapters.mka';
          if (!File(altPath).existsSync()) {
            skipMissing('Alt fixture missing for replace()');
            return;
          }

          // Reset to a known 2-item playlist of the primary fixture.
          await player.openAll([
            Media(fixturePath),
            Media(fixturePath),
          ], play: false);
          await player.stream.playlist
              .firstWhere((p) => p.items.length == 2)
              .timeout(const Duration(seconds: 5));

          // After replace(1, alt), the playlist must still have length 2
          // and entry 1 must point at the alt URI. The wrapper implements
          // this as `playlist-remove 1` + `loadfile insert-at 1`, so we
          // wait for the entry's URI to flip while length stays 2.
          final swapped = player.stream.playlist
              .firstWhere(
                (p) =>
                    p.items.length == 2 &&
                    p.items[1].uri.endsWith('with_chapters.mka'),
              )
              .timeout(const Duration(seconds: 10));
          await player.replace(1, Media(altPath));
          await swapped;
          expect(player.state.playlist.items.length, 2);
          expect(
            player.state.playlist.items[1].uri.endsWith('with_chapters.mka'),
            isTrue,
          );
          expect(
            player.state.playlist.items[0].uri.endsWith('sine_440hz_1s.wav'),
            isTrue,
            reason: 'replace(1) must not touch entry 0',
          );
        },
        timeout: const Timeout(Duration(seconds: 30)),
      );
    });

    group('insert', () {
      final a = '${Directory.current.path}/test/fixtures/sine_5s.flac';
      final b =
          '${Directory.current.path}/test/fixtures/sine_stereo_48k_5s.flac';
      final c = '${Directory.current.path}/test/fixtures/with_chapters.mka';
      final d = fixturePath;
      late Player player;
      late List<MpvFileEndedEvent> ends;

      setUp(() async {
        player = await buildPlayer();
        ends = [];
        final sub = player.stream.endFile.listen(ends.add);
        addTearDown(sub.cancel);
      });

      tearDown(() async {
        await player.dispose();
      });

      Future<void> openThree({int index = 0}) async {
        final restarted = player.stream.seekCompleted.first.timeout(
          const Duration(seconds: 10),
        );
        await player.openAll(
          [Media(a), Media(b), Media(c)],
          play: true,
          index: index,
        );
        await restarted;
        await waitUntil(() => player.state.playlist.items.length == 3);
        ends.clear();
      }

      List<String> uris() =>
          player.state.playlist.items.map((m) => m.uri).toList();

      test('puts an entry before the one at index, the current one playing '
          'on', () async {
        await openThree();
        final path = player.state.path;
        await player.insert(1, Media(d, extras: const {'tag': 'inserted'}));
        await waitUntil(() => player.state.playlist.items.length == 4);
        expect(uris(), [a, d, b, c]);
        expect(player.state.playlist.items[1].extras, {'tag': 'inserted'});
        expect(player.state.playlist.index, 0);
        expect(player.state.path, path);
        expect(player.state.playing, isTrue);
        expect(ends, isEmpty, reason: 'the current entry was not reloaded');
      }, timeout: const Timeout(Duration(seconds: 30)));

      test('before the current entry, the index follows it', () async {
        await openThree(index: 1);
        await player.insert(0, Media(d));
        await waitUntil(() => player.state.playlist.index == 2);
        expect(uris(), [d, a, b, c]);
        expect(ends, isEmpty);
      }, timeout: const Timeout(Duration(seconds: 30)));

      test('at the length it appends, and its options ride along', () async {
        await openThree();
        await player.insert(
          3,
          Media(d, httpHeaders: const {'X-Inserted': 'yes'}),
        );
        await waitUntil(() => player.state.playlist.items.length == 4);
        expect(uris(), [a, b, c, d]);
        final loaded = player.stream.seekCompleted.first.timeout(
          const Duration(seconds: 10),
        );
        await player.jump(3);
        await loaded;
        expect(
          await player.getRawProperty('http-header-fields'),
          contains('X-Inserted: yes'),
        );
      }, timeout: const Timeout(Duration(seconds: 30)));

      test('outside 0..length it throws RangeError', () async {
        await openThree();
        await expectLater(player.insert(4, Media(d)), throwsRangeError);
        await expectLater(player.insert(-1, Media(d)), throwsRangeError);
        await Future<void>.delayed(const Duration(milliseconds: 200));
        expect(uris(), [a, b, c]);
      }, timeout: const Timeout(Duration(seconds: 30)));

      test('entries with the same URI keep their own Media', () async {
        await openThree();
        await player.insert(1, Media(d, extras: const {'n': 1}));
        await player.insert(2, Media(d, extras: const {'n': 2}));
        await waitUntil(() => player.state.playlist.items.length == 5);
        expect(player.state.playlist.items[1].extras, {'n': 1});
        expect(player.state.playlist.items[2].extras, {'n': 2});
      }, timeout: const Timeout(Duration(seconds: 30)));
    });
  });
}
