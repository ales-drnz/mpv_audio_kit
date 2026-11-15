// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:mpv_audio_kit/src/internals/duration_seconds.dart';
import 'package:mpv_audio_kit/src/reactive/node_parsers.dart';
import 'package:test/test.dart';

void main() {
  group('secondsToDuration is total', () {
    test('a value that is not finite gives Duration.zero', () {
      // double.round() throws on these.
      expect(secondsToDuration(double.nan), Duration.zero);
      expect(secondsToDuration(double.infinity), Duration.zero);
      expect(secondsToDuration(double.negativeInfinity), Duration.zero);
    });

    test('a range bound that is not finite keeps the cache state', () {
      final state = parseDemuxerCacheStateFull({
        'seekable-ranges': [
          {'start': 0.0, 'end': double.infinity},
          {'start': double.nan, 'end': 12.0},
        ],
        'eof-cached': true,
      });
      expect(state.eofCached, isTrue);
      expect(state.seekableRanges, hasLength(2));
      expect(state.seekableRanges[1].end, const Duration(seconds: 12));
    });
  });
}
