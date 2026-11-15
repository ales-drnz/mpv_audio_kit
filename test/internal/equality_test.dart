// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

// The values are built anew on each call, not const: equal collections
// that are not identical are what == must compare.
// ignore_for_file: prefer_const_constructors

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:mpv_audio_kit/src/internals/equality.dart';
import 'package:test/test.dart';

void main() {
  group('iterableEq', () {
    test('compares the elements in order', () {
      expect(iterableEq([1, 2, 3], [1, 2, 3]), isTrue);
      expect(iterableEq([1, 2, 3], [1, 3, 2]), isFalse);
      expect(iterableEq([1, 2], [1, 2, 3]), isFalse);
      expect(iterableEq(<int>[], <int>[]), isTrue);
    });

    test('a set compares in its order of insertion', () {
      expect(iterableEq({1, 2}, {1, 2}), isTrue);
      expect(iterableEq({1, 2}, {2, 1}), isFalse);
    });

    test('null equals null only', () {
      expect(iterableEq<int>(null, null), isTrue);
      expect(iterableEq<int>(null, []), isFalse);
      expect(iterableEq<int>([], null), isFalse);
    });
  });

  group('mapEq and mapHash', () {
    test('the order of the entries does not count', () {
      final a = {'x': 1, 'y': 2};
      final b = {'y': 2, 'x': 1};
      expect(mapEq(a, b), isTrue);
      expect(mapHash(a), mapHash(b));
    });

    test('a missing key is not a null value', () {
      expect(mapEq<String, int?>({'x': null}, {'y': null}), isFalse);
      expect(mapEq<String, int?>({'x': null}, {'x': null}), isTrue);
      expect(mapEq({'x': 1}, {'x': 2}), isFalse);
      expect(mapEq({'x': 1}, {'x': 1, 'y': 2}), isFalse);
    });

    test('null equals null only, and hashes to null', () {
      expect(mapEq<String, int>(null, null), isTrue);
      expect(mapEq<String, int>(null, {}), isFalse);
      expect(mapEq<String, int>({}, null), isFalse);
      expect(mapHash<String, int>(null), isNull);
    });
  });

  group('the models compare their collections by content', () {
    test('Media', () {
      Media build() => Media(
        'a.mp3',
        extras: {'n': 1, 'none': null},
        httpHeaders: {'A': 'b'},
        streamLavfOptions: {'reconnect_streamed': '1'},
        demuxerLavfOptions: {'k': 'v'},
      );
      expect(build(), build());
      expect(build().hashCode, build().hashCode);
      expect(build(), isNot(build().copyWith(extras: {'n': 1})));
      expect(build(), isNot(build().copyWith(httpHeaders: {'A': 'c'})));
      expect(build(), isNot(build().copyWith(httpHeaders: null)));
    });

    test('Playlist', () {
      Playlist build() => Playlist([const Media('a'), const Media('b')]);
      expect(build(), build());
      expect(build().hashCode, build().hashCode);
      expect(build(), isNot(Playlist([const Media('b'), const Media('a')])));
    });

    test('MediaSession', () {
      MediaSession build(List<double> rates) => MediaSession(
        actions: {MediaAction.play, MediaAction.next},
        supportedPlaybackRates: rates,
      );
      expect(build([1, 2]), build([1, 2]));
      expect(build([1, 2]).hashCode, build([1, 2]).hashCode);
      expect(build([1, 2]), isNot(build([2, 1])));
      expect(build([1, 2]), isNot(build([1])));
      expect(
        build([1]),
        isNot(
          MediaSession(
            actions: {MediaAction.next, MediaAction.play},
            supportedPlaybackRates: [1],
          ),
        ),
      );
    });

    test('DemuxerCacheState', () {
      DemuxerCacheState build(int end) => DemuxerCacheState(
        seekableRanges: [CacheRange(Duration.zero, Duration(seconds: end))],
        eofCached: true,
      );
      expect(build(5), build(5));
      expect(build(5).hashCode, build(5).hashCode);
      expect(build(5), isNot(build(6)));
      expect(build(5), isNot(const DemuxerCacheState(eofCached: true)));
    });
  });
}
