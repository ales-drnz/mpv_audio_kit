// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:mpv_audio_kit/src/internals/duration_seconds.dart';

void main() {
  group('secondsToDuration', () {
    test('zero seconds → Duration.zero', () {
      expect(secondsToDuration(0.0), Duration.zero);
    });

    test('integer seconds round-trip exactly', () {
      expect(secondsToDuration(1.0), const Duration(seconds: 1));
      expect(secondsToDuration(30.0), const Duration(seconds: 30));
    });

    test('millisecond precision', () {
      expect(secondsToDuration(0.001), const Duration(milliseconds: 1));
      expect(secondsToDuration(0.5), const Duration(milliseconds: 500));
    });

    test('microsecond precision', () {
      expect(secondsToDuration(0.000001), const Duration(microseconds: 1));
    });

    test('negative values (e.g. negative audio-delay) work', () {
      expect(secondsToDuration(-1.5), const Duration(milliseconds: -1500));
    });

    test('large values for network-timeout-style use', () {
      expect(secondsToDuration(3600.0), const Duration(hours: 1));
    });

    test('sub-microsecond precision is rounded', () {
      // Anything below 1µs gets rounded to 0 — documented behaviour.
      expect(secondsToDuration(0.0000001), Duration.zero);
    });
  });

  group('durationToSeconds', () {
    test('Duration.zero → 0.0', () {
      expect(durationToSeconds(Duration.zero), 0.0);
    });

    test('integer seconds round-trip', () {
      expect(durationToSeconds(const Duration(seconds: 30)), 30.0);
    });

    test('millisecond precision', () {
      expect(durationToSeconds(const Duration(milliseconds: 200)), 0.2);
      expect(durationToSeconds(const Duration(milliseconds: 1500)), 1.5);
    });

    test('negative durations stay negative', () {
      expect(durationToSeconds(const Duration(milliseconds: -50)), -0.05);
    });

    test('large durations don\'t lose precision in IEEE-754 double range', () {
      // Even at 24h (86400s), microsecond precision still fits in a
      // double (~15-17 sig figs).
      expect(durationToSeconds(const Duration(hours: 24, microseconds: 1)),
          closeTo(86400.000001, 1e-9));
    });
  });

  group('round-trip identity', () {
    test('seconds → Duration → seconds preserves common values', () {
      const samples = [0.0, 0.001, 0.05, 0.5, 1.0, 30.0, 3600.0, -1.5];
      for (final s in samples) {
        final round = durationToSeconds(secondsToDuration(s));
        expect(round, closeTo(s, 1e-9), reason: 'sample = $s');
      }
    });
  });
}
