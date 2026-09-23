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
    group('openPlaylistFile (loadlist)', () {
      late Player player;
      late Directory tmp;
      late String m3uPath;

      setUpAll(() async {
        player = await buildPlayer();
        tmp = Directory.systemTemp.createTempSync('mak_m3u_');
        // A plain .m3u with two entries (the fixture twice). If openPlaylistFile
        // wrongly used loadfile, the playlist would hold ONE entry (the .m3u
        // file itself); loadlist expands it into two — the discriminator.
        m3uPath = '${tmp.path}/list.m3u';
        File(m3uPath).writeAsStringSync('$fixturePath\n$fixturePath\n');
      });

      tearDownAll(() async {
        await player.dispose();
        try {
          tmp.deleteSync(recursive: true);
        } catch (_) {}
      });

      test('expands a .m3u into multiple playlist entries', () async {
        // Pre-subscribe before the load: the playlist + playlist-path each emit
        // once when the first entry loads, so a late firstWhere would miss them
        // (see CLAUDE.md). Gate on seekCompleted, then read the state snapshot.
        final loaded = player.stream.seekCompleted.first.timeout(
          const Duration(seconds: 10),
        );
        await player.openPlaylistFile(Media(m3uPath), play: false);
        await loaded;

        expect(
          player.state.playlist.items,
          hasLength(2),
          reason: 'loadlist must parse the .m3u into its 2 entries',
        );
        expect(
          player.state.playlist.items.first.uri,
          contains('sine_440hz'),
          reason: 'entries resolve to the fixture referenced by the playlist',
        );
        // playlist-path (#D1 part C) reports the source .m3u for the entry.
        expect(
          player.state.playlistPath,
          contains('list.m3u'),
          reason: 'playlist-path reports the source .m3u',
        );
        // play:false must leave the intent axis down.
        expect(player.state.playWhenReady, isFalse);
      }, timeout: const Timeout(Duration(seconds: 20)));
    });
  });
}
