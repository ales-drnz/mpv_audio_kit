// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

// Pins the decision behind `MediaSession.autoApplyPlaylistNavigation` (PR #11):
// the gate `_handleSessionCommand` consults before driving mpv's playlist on an
// OS next/previous. The full Dart→native command path is covered elsewhere; the
// only branching LOGIC of the feature is this predicate, so it is pinned here so
// an inverted condition, a dropped flag check, or a dropped length guard fails
// loudly instead of shipping green.

import 'package:mpv_audio_kit/src/player/playlist_nav_gate.dart';
import 'package:test/test.dart';

void main() {
  group('shouldAutoApplyPlaylistNav', () {
    test(
      'opted out (false) suppresses navigation even with a real playlist',
      () {
        expect(
          shouldAutoApplyPlaylistNav(
            autoApplyPlaylistNavigation: false,
            playlistLength: 2,
          ),
          isFalse,
        );
      },
    );

    test('opted in (true) navigates when the playlist has >1 entry', () {
      expect(
        shouldAutoApplyPlaylistNav(
          autoApplyPlaylistNavigation: true,
          playlistLength: 2,
        ),
        isTrue,
      );
    });

    test('null config defaults to true (auto-apply)', () {
      expect(
        shouldAutoApplyPlaylistNav(
          autoApplyPlaylistNavigation: null,
          playlistLength: 2,
        ),
        isTrue,
      );
    });

    test('a lone entry is emit-only regardless of the flag', () {
      for (final flag in <bool?>[null, true, false]) {
        expect(
          shouldAutoApplyPlaylistNav(
            autoApplyPlaylistNavigation: flag,
            playlistLength: 1,
          ),
          isFalse,
          reason: 'length 1 has nowhere to navigate (flag=$flag)',
        );
      }
    });

    test('an empty playlist is emit-only regardless of the flag', () {
      for (final flag in <bool?>[null, true, false]) {
        expect(
          shouldAutoApplyPlaylistNav(
            autoApplyPlaylistNavigation: flag,
            playlistLength: 0,
          ),
          isFalse,
        );
      }
    });
  });
}
