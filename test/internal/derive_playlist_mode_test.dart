// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:mpv_audio_kit/src/playback/lifecycle_transitions.dart';

void main() {
  group('deriveLoopMode — loop-file transitions', () {
    test('loop-file=inf → single regardless of previous mode', () {
      expect(deriveLoopMode('loop-file', 'inf', LoopMode.off),
          LoopMode.file);
      expect(deriveLoopMode('loop-file', 'inf', LoopMode.playlist),
          LoopMode.file,
          reason: 'switching from loop-playlist to loop-file is allowed');
      expect(deriveLoopMode('loop-file', 'inf', LoopMode.file),
          LoopMode.file);
    });

    test('loop-file=no clears single', () {
      expect(deriveLoopMode('loop-file', 'no', LoopMode.file),
          LoopMode.off);
    });

    test('loop-file=no does NOT clear loop-playlist mode', () {
      // Critical: mpv emits both loop-file and loop-playlist independently.
      // If the user switched on loop-playlist, a stale loop-file=no observer
      // event must not silently downgrade the mode to none.
      expect(deriveLoopMode('loop-file', 'no', LoopMode.playlist), isNull,
          reason:
              'loop-file=no with prev=loop must not modify the playlist '
              'loop — the wrapper would lose user-visible state');
    });

    test('loop-file=no with prev=none is a no-op', () {
      expect(deriveLoopMode('loop-file', 'no', LoopMode.off), isNull);
    });
  });

  group('deriveLoopMode — loop-playlist transitions', () {
    test('loop-playlist=inf → loop regardless of previous mode', () {
      expect(deriveLoopMode('loop-playlist', 'inf', LoopMode.off),
          LoopMode.playlist);
      expect(deriveLoopMode('loop-playlist', 'inf', LoopMode.file),
          LoopMode.playlist);
      expect(deriveLoopMode('loop-playlist', 'inf', LoopMode.playlist),
          LoopMode.playlist);
    });

    test('loop-playlist=no clears loop', () {
      expect(deriveLoopMode('loop-playlist', 'no', LoopMode.playlist),
          LoopMode.off);
    });

    test('loop-playlist=no does NOT clear loop-file (single) mode', () {
      expect(
          deriveLoopMode('loop-playlist', 'no', LoopMode.file),
          isNull);
    });
  });

  group('deriveLoopMode — unrelated property names', () {
    test('returns null for any name other than loop-file / loop-playlist',
        () {
      expect(deriveLoopMode('volume', '50', LoopMode.off), isNull);
      expect(deriveLoopMode('', 'inf', LoopMode.off), isNull);
    });
  });
}
