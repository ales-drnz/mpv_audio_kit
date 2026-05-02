// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:mpv_audio_kit/src/internals/lifecycle_transitions.dart';

void main() {
  group('deriveLoop — loop-file transitions', () {
    test('loop-file=inf → single regardless of previous mode', () {
      expect(deriveLoop('loop-file', 'inf', Loop.off), Loop.file);
      expect(deriveLoop('loop-file', 'inf', Loop.playlist), Loop.file,
          reason: 'switching from loop-playlist to loop-file is allowed');
      expect(deriveLoop('loop-file', 'inf', Loop.file), Loop.file);
    });

    test('loop-file=no clears single', () {
      expect(deriveLoop('loop-file', 'no', Loop.file), Loop.off);
    });

    test('loop-file=no does NOT clear loop-playlist mode', () {
      // Critical: mpv emits both loop-file and loop-playlist independently.
      // If the user switched on loop-playlist, a stale loop-file=no observer
      // event must not silently downgrade the mode to none.
      expect(deriveLoop('loop-file', 'no', Loop.playlist), isNull,
          reason: 'loop-file=no with prev=loop must not modify the playlist '
              'loop — the wrapper would lose user-visible state');
    });

    test('loop-file=no with prev=none is a no-op', () {
      expect(deriveLoop('loop-file', 'no', Loop.off), isNull);
    });
  });

  group('deriveLoop — loop-playlist transitions', () {
    test('loop-playlist=inf → loop regardless of previous mode', () {
      expect(deriveLoop('loop-playlist', 'inf', Loop.off), Loop.playlist);
      expect(deriveLoop('loop-playlist', 'inf', Loop.file), Loop.playlist);
      expect(deriveLoop('loop-playlist', 'inf', Loop.playlist), Loop.playlist);
    });

    test('loop-playlist=no clears loop', () {
      expect(deriveLoop('loop-playlist', 'no', Loop.playlist), Loop.off);
    });

    test('loop-playlist=no does NOT clear loop-file (single) mode', () {
      expect(deriveLoop('loop-playlist', 'no', Loop.file), isNull);
    });
  });

  group('deriveLoop — unrelated property names', () {
    test('returns null for any name other than loop-file / loop-playlist', () {
      expect(deriveLoop('volume', '50', Loop.off), isNull);
      expect(deriveLoop('', 'inf', Loop.off), isNull);
    });
  });
}
