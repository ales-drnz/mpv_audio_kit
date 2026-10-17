// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

import '../_helpers/setter_test_helpers.dart';

void main() {
  // L2 — `clearPlaylist()` issues both `playlist-clear` AND
  // `playlist-remove current`. mpv's `playlist-clear` on its own
  // preserves the active entry; the second command is what makes the
  // wrapper's contract match the method name ("clear ALL tracks,
  // including the playing one"). The combined behaviour is
  // observable: after the call playback stops and the playlist is
  // empty.
  //
  // This test pins that contract. A future change that drops the
  // `playlist-remove current` (e.g. to keep playback running) would
  // be a breaking semantic change visible to consumers; the test
  // forces it to be intentional.
  final fixturePath = defaultFixturePath();

  runtimeSuite(fixturePath: fixturePath, () {
    group('clearPlaylist semantics (L2)', () {
      test('clearPlaylist() during playback stops the active track and '
          'empties the playlist', () async {
        final player = await buildPlayer();
        try {
          // Open + start playing — gets us a non-empty playlist with a
          // currently-playing entry.
          await player.open(Media(fixturePath), play: true);
          await player.stream.seekCompleted.first.timeout(
            const Duration(seconds: 5),
          );
          expect(
            player.state.playlist.items,
            isNotEmpty,
            reason: 'precondition: playlist must be populated',
          );

          await player.clearPlaylist();

          // The `playlist-remove current` command makes mpv emit a
          // file-ended event; wait for the observers to land.
          await waitUntil(() => player.state.playlist.items.isEmpty);

          expect(
            player.state.playlist.items,
            isEmpty,
            reason:
                'clearPlaylist() must empty the playlist completely '
                '(both queued and currently-playing entries)',
          );
          expect(
            player.state.playing,
            isFalse,
            reason:
                'clearPlaylist() also removes the currently-playing '
                'entry, which stops playback. This is documented; the '
                'test pins the contract so a future change must be '
                'intentional.',
          );
        } finally {
          await player.dispose();
        }
      }, timeout: const Timeout(Duration(seconds: 30)));
    });

    group('clearPlaylist(keepCurrent: true)', () {
      final a = '${Directory.current.path}/test/fixtures/sine_5s.flac';
      final b =
          '${Directory.current.path}/test/fixtures/sine_stereo_48k_5s.flac';
      late Player player;

      setUp(() async {
        player = await buildPlayer();
      });

      tearDown(() async {
        await player.dispose();
      });

      test('keeps the current entry playing as the only one', () async {
        final restarted = player.stream.seekCompleted.first.timeout(
          const Duration(seconds: 10),
        );
        await player.openAll(
          [Media(a), Media(b), Media(fixturePath)],
          index: 1,
          play: true,
        );
        await restarted;
        await waitUntil(() => player.state.playlist.items.length == 3);
        final ends = <MpvFileEndedEvent>[];
        final sub = player.stream.endFile.listen(ends.add);
        addTearDown(sub.cancel);

        await player.clearPlaylist(keepCurrent: true);
        await waitUntil(() => player.state.playlist.items.length == 1);
        expect(player.state.playlist.items.single.uri, b);
        expect(player.state.playlist.index, 0);
        final from = player.state.position;
        await Future<void>.delayed(const Duration(milliseconds: 400));
        expect(player.state.playing, isTrue);
        expect(player.state.position, greaterThan(from));
        expect(ends, isEmpty, reason: 'the current entry was not reloaded');
        expect(await player.next(), isFalse);
      }, timeout: const Timeout(Duration(seconds: 30)));

      test('with nothing loaded it empties the playlist', () async {
        await player.clearPlaylist(keepCurrent: true);
        expect(player.state.playlist.items, isEmpty);
        expect(await player.getRawProperty('playlist-count'), '0');
      }, timeout: const Timeout(Duration(seconds: 30)));

      test('the kept entry keeps its Media for the source resolver', () async {
        final requests = <SourceResolveRequest>[];
        await player.setSourceResolver((r) {
          requests.add(r);
          return null;
        });
        final restarted = player.stream.seekCompleted.first.timeout(
          const Duration(seconds: 10),
        );
        await player.openAll(
          [
            Media(a),
            Media(fixturePath, extras: const {'id': 'kept'}),
          ],
          index: 1,
          play: true,
        );
        await restarted;
        await player.clearPlaylist(keepCurrent: true);
        await waitUntil(() => player.state.playlist.items.length == 1);
        requests.clear();
        // The 1 s entry loops alone: each round loads it again.
        await player.setLoop(Loop.playlist);
        await waitUntil(
          () => requests.isNotEmpty,
          reason: 'the next round asks the resolver',
        );
        expect(requests.first.media.extras, {'id': 'kept'});
      }, timeout: const Timeout(Duration(seconds: 30)));
    });
  });
}
