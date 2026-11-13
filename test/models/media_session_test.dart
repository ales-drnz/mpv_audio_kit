// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

void main() {
  group('toString hides the secrets of the artwork URL', () {
    final artwork = MediaSessionArtwork.uri(
      Uri.parse('https://joe:pa55@srv/rest/getCoverArt?id=al-1&t=26719a'),
    );
    const printed =
        'MediaSessionArtwork.uri('
        'https://<redacted>@srv/rest/getCoverArt?id=<redacted>&t=<redacted>)';

    test('MediaSessionArtwork.uri keeps the names of the query only', () {
      expect(artwork.toString(), printed);
      expect(
        MediaSessionArtwork.uri(Uri.parse('file:///covers/a.jpg')).toString(),
        'MediaSessionArtwork.uri(file:///covers/a.jpg)',
      );
    });

    test('MediaSession prints its artwork the same', () {
      final out = MediaSession(artwork: artwork).toString();
      expect(out, contains('artwork: $printed,'));
      for (final secret in ['joe', 'pa55', 'al-1', '26719a']) {
        expect(out, isNot(contains(secret)));
      }
    });
  });

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
