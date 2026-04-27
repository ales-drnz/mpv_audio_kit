// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
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

  group('Media equality (0.1.0 full-field semantics)', () {
    test('same uri, same extras, same headers → equal', () {
      // Regression test for the 0.1.0 breaking change: `Media` now uses
      // Freezed-generated structural equality on ALL fields, not just
      // `uri`. Two identical-shape instances must be equal.
      final a = Media('a', extras: const {'k': 'v'}, httpHeaders: const {'h': 'x'});
      final b = Media('a', extras: const {'k': 'v'}, httpHeaders: const {'h': 'x'});
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('same uri, different extras → not equal', () {
      // This is the documented breaking change vs 0.0.x: previously two
      // Media with same uri but different extras compared equal.
      const a = Media('a');
      final b = Media('a', extras: const {'cover': 'data'});
      expect(a, isNot(b));
    });

    test('same uri, different httpHeaders → not equal', () {
      const a = Media('a');
      final b = Media('a', httpHeaders: const {'X-Token': 'foo'});
      expect(a, isNot(b));
    });

    test('different uri → not equal', () {
      const a = Media('a');
      const b = Media('b');
      expect(a, isNot(b));
    });

    test('two empty-extras null vs explicit null → equal (Freezed default)',
        () {
      const a = Media('a');
      const b = Media('a', extras: null, httpHeaders: null);
      expect(a, b);
    });
  });

  group('Media copyWith', () {
    test('copyWith preserves uri and overrides extras', () {
      final a = Media('a', extras: const {'k': 'v'});
      final b = a.copyWith(extras: const {'k2': 'v2'});
      expect(b.uri, 'a');
      expect(b.extras, {'k2': 'v2'});
    });

    test('copyWith with no args is structurally equal', () {
      final a = Media('a', extras: const {'k': 'v'});
      final b = a.copyWith();
      expect(b, a);
    });
  });
}
