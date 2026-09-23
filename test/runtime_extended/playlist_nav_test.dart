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
    Future<int> waitIndex(Player p, int want) => p.stream.playlist
        .firstWhere((pl) => pl.index == want)
        .timeout(const Duration(seconds: 10))
        .then((pl) => pl.index);

    group('playlist navigation', () {
      test('next() / previous() move the active index', () async {
        final player = await buildPlayer();
        addTearDown(player.dispose);

        await player.openAll([
          Media(fixturePath),
          Media(fixturePath),
        ], play: false);
        await waitIndex(player, 0);

        await player.next();
        expect(await waitIndex(player, 1), 1);

        await player.previous();
        expect(await waitIndex(player, 0), 0);
      }, timeout: const Timeout(Duration(seconds: 25)));

      test(
        'nextPlaylist() / previousPlaylist() cross the playlist-path boundary',
        () async {
          final player = await buildPlayer();
          addTearDown(player.dispose);
          final tmp = Directory.systemTemp.createTempSync('mak_nav_');
          addTearDown(() {
            try {
              tmp.deleteSync(recursive: true);
            } catch (_) {}
          });
          // Two DISTINCT .m3u files (distinct playlist-path) each with one entry,
          // concatenated into a single queue. nextPlaylist must jump from the
          // first list's entry to the second list's entry.
          final a = '${tmp.path}/a.m3u';
          final b = '${tmp.path}/b.m3u';
          File(a).writeAsStringSync('$fixturePath\n');
          File(b).writeAsStringSync('$fixturePath\n');

          await player.openPlaylistFile(Media(a), play: false);
          await waitIndex(player, 0);
          // Append the second list via the raw hatch (openPlaylistFile is replace).
          await player.sendRawCommand(['loadlist', b, 'append']);
          await player.stream.playlist
              .firstWhere((pl) => pl.items.length >= 2)
              .timeout(const Duration(seconds: 10));

          await player.nextPlaylist();
          expect(
            await waitIndex(player, 1),
            1,
            reason: 'jumps to the entry from the other playlist-path',
          );

          await player.previousPlaylist();
          expect(await waitIndex(player, 0), 0);
        },
        timeout: const Timeout(Duration(seconds: 25)),
      );
    });
  });
}
