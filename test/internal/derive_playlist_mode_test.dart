// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:mpv_audio_kit/src/internal/lifecycle_transitions.dart';

void main() {
  group('derivePlaylistMode — loop-file transitions', () {
    test('loop-file=inf → single regardless of previous mode', () {
      expect(derivePlaylistMode('loop-file', 'inf', PlaylistMode.none),
          PlaylistMode.single);
      expect(derivePlaylistMode('loop-file', 'inf', PlaylistMode.loop),
          PlaylistMode.single,
          reason: 'switching from loop-playlist to loop-file is allowed');
      expect(derivePlaylistMode('loop-file', 'inf', PlaylistMode.single),
          PlaylistMode.single);
    });

    test('loop-file=no clears single', () {
      expect(derivePlaylistMode('loop-file', 'no', PlaylistMode.single),
          PlaylistMode.none);
    });

    test('loop-file=no does NOT clear loop-playlist mode', () {
      // Critical: mpv emits both loop-file and loop-playlist independently.
      // If the user switched on loop-playlist, a stale loop-file=no observer
      // event must not silently downgrade the mode to none.
      expect(derivePlaylistMode('loop-file', 'no', PlaylistMode.loop), isNull,
          reason:
              'loop-file=no with prev=loop must not modify the playlist '
              'loop — the wrapper would lose user-visible state');
    });

    test('loop-file=no with prev=none is a no-op', () {
      expect(derivePlaylistMode('loop-file', 'no', PlaylistMode.none), isNull);
    });
  });

  group('derivePlaylistMode — loop-playlist transitions', () {
    test('loop-playlist=inf → loop regardless of previous mode', () {
      expect(derivePlaylistMode('loop-playlist', 'inf', PlaylistMode.none),
          PlaylistMode.loop);
      expect(derivePlaylistMode('loop-playlist', 'inf', PlaylistMode.single),
          PlaylistMode.loop);
      expect(derivePlaylistMode('loop-playlist', 'inf', PlaylistMode.loop),
          PlaylistMode.loop);
    });

    test('loop-playlist=no clears loop', () {
      expect(derivePlaylistMode('loop-playlist', 'no', PlaylistMode.loop),
          PlaylistMode.none);
    });

    test('loop-playlist=no does NOT clear loop-file (single) mode', () {
      expect(
          derivePlaylistMode('loop-playlist', 'no', PlaylistMode.single),
          isNull);
    });
  });

  group('derivePlaylistMode — unrelated property names', () {
    test('returns null for any name other than loop-file / loop-playlist',
        () {
      expect(derivePlaylistMode('volume', '50', PlaylistMode.none), isNull);
      expect(derivePlaylistMode('', 'inf', PlaylistMode.none), isNull);
    });
  });
}
