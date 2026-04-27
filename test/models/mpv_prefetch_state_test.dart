// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

void main() {
  group('MpvPrefetchState.parse', () {
    test('round-trips every known value', () {
      // Pair each enum variant with its expected mpv wire string. If a
      // future maintenance breaks the parse map, this test fails before
      // production silently swallows a transition.
      const cases = {
        'idle': MpvPrefetchState.idle,
        'loading': MpvPrefetchState.loading,
        'ready': MpvPrefetchState.ready,
        'used': MpvPrefetchState.used,
      };
      for (final entry in cases.entries) {
        expect(MpvPrefetchState.parse(entry.key), entry.value,
            reason: 'parse("${entry.key}") should be ${entry.value}');
      }
    });

    test('unknown values fall back to idle (forward-compat)', () {
      // The parse function is documented to fall back to `idle` for
      // future mpv values rather than throwing — this is a
      // forward-compatibility guarantee for hosts running mismatched
      // wrapper / mpv versions.
      expect(MpvPrefetchState.parse('totally-bogus'), MpvPrefetchState.idle);
      expect(MpvPrefetchState.parse(''), MpvPrefetchState.idle);
      expect(MpvPrefetchState.parse('IDLE'), MpvPrefetchState.idle,
          reason: 'parse is case-sensitive (mpv emits lowercase)');
    });

    test('all four variants are reachable via parse', () {
      final reachable = MpvPrefetchState.values
          .map((v) => MpvPrefetchState.parse(v.name))
          .toSet();
      expect(reachable.length, MpvPrefetchState.values.length);
    });
  });
}
