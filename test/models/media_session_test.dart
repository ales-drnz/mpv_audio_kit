// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

void main() {
  group('MediaSession equality', () {
    test('actions order participates in equality', () {
      const a = MediaSession(
        actions: {MediaAction.play, MediaAction.previous, MediaAction.next},
      );
      const b = MediaSession(
        actions: {MediaAction.play, MediaAction.next, MediaAction.previous},
      );

      expect(a, isNot(b));
      expect(a.hashCode, isNot(b.hashCode));
    });

    test('matching actions order remains equal', () {
      const a = MediaSession(
        actions: {MediaAction.play, MediaAction.previous, MediaAction.next},
      );
      const b = MediaSession(
        actions: {MediaAction.play, MediaAction.previous, MediaAction.next},
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test(
      'autoApplyPlaylistNavigation participates in equality and copyWith',
      () {
        const a = MediaSession(); // default: true
        const b = MediaSession(autoApplyPlaylistNavigation: false);

        expect(a.autoApplyPlaylistNavigation, isTrue);
        expect(b.autoApplyPlaylistNavigation, isFalse);
        expect(a, isNot(b));
        expect(a.hashCode, isNot(b.hashCode));

        final copied = a.copyWith(autoApplyPlaylistNavigation: false);
        expect(copied.autoApplyPlaylistNavigation, isFalse);
        expect(copied, b);
      },
    );
  });
}
