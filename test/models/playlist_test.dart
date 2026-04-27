// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

void main() {
  group('Playlist construction', () {
    test('default constructor stores medias and index', () {
      const a = Media('a');
      const b = Media('b');
      const playlist = Playlist([a, b], index: 1);
      expect(playlist.medias, [a, b]);
      expect(playlist.index, 1);
    });

    test('default constructor uses index=0 when omitted', () {
      const playlist = Playlist([Media('a')]);
      expect(playlist.index, 0);
    });

    test('Playlist.empty() has zero medias and index=0', () {
      const playlist = Playlist.empty();
      expect(playlist.medias, isEmpty);
      expect(playlist.index, 0);
    });
  });

  group('Playlist equality', () {
    test('two empties are equal', () {
      // Important regression test: 0.1.0 keeps Playlist with manual `==`
      // (NOT migrated to Freezed) precisely so deep-list equality keeps
      // working — `Playlist.empty()` must therefore be `==` to itself
      // across instances.
      expect(const Playlist.empty(), const Playlist.empty());
      expect(
          const Playlist.empty().hashCode, const Playlist.empty().hashCode);
    });

    test('same medias same index = equal', () {
      const a = Playlist([Media('x'), Media('y')], index: 1);
      const b = Playlist([Media('x'), Media('y')], index: 1);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('different index = not equal', () {
      const a = Playlist([Media('x'), Media('y')], index: 0);
      const b = Playlist([Media('x'), Media('y')], index: 1);
      expect(a, isNot(b));
    });

    test('different medias = not equal (deep comparison)', () {
      const a = Playlist([Media('x'), Media('y')]);
      const b = Playlist([Media('x'), Media('z')]);
      expect(a, isNot(b));
    });

    test('different lengths = not equal', () {
      const a = Playlist([Media('x')]);
      const b = Playlist([Media('x'), Media('y')]);
      expect(a, isNot(b));
    });

    test('media extras change → playlist not equal (0.1.0 semantics)', () {
      // Critical: 0.1.0 made Media use full-field equality. So two playlists
      // containing the same URI but different extras (e.g. cover art added
      // to one of them after load) must compare NOT equal — otherwise
      // `playlistCtrl.add(updated)` would silently dedup at the
      // ReactiveProperty level and consumers would never see the cover.
      const before = Playlist([Media('track://1')]);
      final after = Playlist([
        Media('track://1', extras: const {'artBytes': 'something'}),
      ]);
      expect(before, isNot(after));
    });

    test('identity equality short-circuits', () {
      const playlist = Playlist([Media('a'), Media('b')]);
      expect(identical(playlist, playlist), isTrue);
      expect(playlist == playlist, isTrue);
    });
  });

  group('PlaylistMode enum', () {
    test('three variants present', () {
      expect(PlaylistMode.values.length, 3);
      expect(PlaylistMode.values, containsAll([
        PlaylistMode.none,
        PlaylistMode.single,
        PlaylistMode.loop,
      ]));
    });
  });
}
