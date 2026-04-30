// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

void main() {
  group('Media construction', () {
    test('positional uri only', () {
      const media = Media('https://example.com/a.mp3');
      expect(media.uri, 'https://example.com/a.mp3');
      expect(media.extras, isNull);
      expect(media.httpHeaders, isNull);
    });

    test('full constructor with extras + headers', () {
      final media = Media(
        'https://example.com/a.mp3',
        extras: const {'title': 'Song', 'artist': 'Artist'},
        httpHeaders: const {'X-Token': 'abc'},
      );
      expect(media.extras, {'title': 'Song', 'artist': 'Artist'});
      expect(media.httpHeaders, {'X-Token': 'abc'});
    });
  });

  group('Media equality — 0.1.0 full-field semantics', () {
    // Regression tests for the 0.1.0 breaking change: `Media` equality
    // now considers `extras` and `httpHeaders`, not just `uri`. The
    // previous behaviour silently broke playlist deduplication when a
    // consumer attached cover art to an existing entry.

    test('extras participate in equality', () {
      const a = Media('a');
      final b = Media('a', extras: const {'cover': 'data'});
      expect(a, isNot(b));
    });

    test('httpHeaders participate in equality', () {
      const a = Media('a');
      final b = Media('a', httpHeaders: const {'X-Token': 'foo'});
      expect(a, isNot(b));
    });
  });
}
