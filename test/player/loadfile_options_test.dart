// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/src/internals/pcm_native.dart';
import 'package:mpv_audio_kit/src/player/player.dart';

import '../pcm/fake_pcm_native.dart';

/// The per-entry `loadfile` options a [Media] gives, without a player.
void main() {
  group('start', () {
    test('null adds nothing', () {
      expect(loadfileOptions(const Media('a.flac')), '');
    });

    test('goes out in seconds with fixed decimals', () {
      String opts(Duration d) => loadfileOptions(Media('a.flac', start: d));
      expect(opts(Duration.zero), 'start=0.000');
      expect(opts(const Duration(seconds: 2)), 'start=2.000');
      expect(opts(const Duration(milliseconds: 1250)), 'start=1.250');
      // Every microsecond is kept.
      expect(opts(const Duration(microseconds: 1500500)), 'start=1.500500');
      // Never an exponent, at either end.
      expect(opts(const Duration(microseconds: 5)), 'start=0.000005');
      expect(opts(const Duration(days: 365 * 1000)), 'start=31536000000.000');
    });

    test('rides along with the other options', () {
      final opts = loadfileOptions(
        const Media(
          'https://example.com/a.mp3',
          httpHeaders: {'X-Token': 'abc'},
          start: Duration(minutes: 1),
        ),
      );
      expect(opts.split(','), contains('start=60.000'));
      expect(opts, contains('http-header-fields='));
    });

    test('a negative start is refused before any load', () {
      const media = Media('a.flac', start: Duration(milliseconds: -1));
      expect(
        () => validateLoadOptions(media),
        throwsA(isA<ArgumentError>().having((e) => e.name, 'name', 'start')),
      );
      expect(() => loadfileOptions(media), throwsArgumentError);
    });

    test('a live PCM entry refuses a start', () {
      debugPcmNativeOverride = FakePcmNative();
      addTearDown(() {
        debugPcmNativeOverride = null;
        PcmSource.debugReset();
      });
      final source = PcmSource.create(
        const PcmFormat(sampleRate: 1000, channels: 1),
      );
      final media = source.toMedia().copyWith(
        start: const Duration(seconds: 1),
      );
      expect(
        () => validateLoadOptions(media),
        throwsA(isA<ArgumentError>().having((e) => e.name, 'name', 'start')),
      );
      // Without a start it loads as before.
      validateLoadOptions(source.toMedia());
    });
  });

  group('end', () {
    test('goes out like start, after it', () {
      expect(
        loadfileOptions(const Media('a.flac', end: Duration(seconds: 30))),
        'end=30.000',
      );
      expect(
        loadfileOptions(
          const Media(
            'a.flac',
            start: Duration(minutes: 1),
            end: Duration(minutes: 1, seconds: 30, microseconds: 5),
          ),
        ),
        'start=60.000,end=90.000005',
      );
    });

    test('must be later than start, or than zero', () {
      Matcher refused() =>
          throwsA(isA<ArgumentError>().having((e) => e.name, 'name', 'end'));
      expect(
        () => validateLoadOptions(const Media('a.flac', end: Duration.zero)),
        refused(),
      );
      expect(
        () => validateLoadOptions(
          const Media('a.flac', end: Duration(milliseconds: -5)),
        ),
        refused(),
      );
      expect(
        () => validateLoadOptions(
          const Media(
            'a.flac',
            start: Duration(seconds: 2),
            end: Duration(seconds: 2),
          ),
        ),
        refused(),
      );
      expect(
        () => loadfileOptions(
          const Media(
            'a.flac',
            start: Duration(seconds: 3),
            end: Duration(seconds: 2),
          ),
        ),
        refused(),
      );
      // Just after start is fine.
      validateLoadOptions(
        const Media(
          'a.flac',
          start: Duration(seconds: 2),
          end: Duration(seconds: 2, microseconds: 1),
        ),
      );
    });

    test('a live PCM entry refuses an end', () {
      debugPcmNativeOverride = FakePcmNative();
      addTearDown(() {
        debugPcmNativeOverride = null;
        PcmSource.debugReset();
      });
      final media = PcmSource.create(
        const PcmFormat(sampleRate: 1000, channels: 1),
      ).toMedia().copyWith(end: const Duration(seconds: 1));
      expect(
        () => validateLoadOptions(media),
        throwsA(isA<ArgumentError>().having((e) => e.name, 'name', 'end')),
      );
    });
  });
}
