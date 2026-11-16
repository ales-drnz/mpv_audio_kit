// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

void main() {
  group('Spdif', () {
    // mpv's `audio-spdif` option accepts EXACTLY this set (DOCS/man/options.rst,
    // verified against the shipped libmpv). The enum must mirror it 1:1 — any
    // extra value would let a consumer pass a token mpv rejects, making the
    // public setter throw. This guard fails if someone re-adds e.g. aac/mp3.
    const accepted = {'ac3', 'dts', 'dts-hd', 'eac3', 'truehd'};

    test('enum mirrors mpv\'s accepted codec set exactly', () {
      expect(Spdif.values.map((s) => s.mpvValue).toSet(), accepted);
    });

    test('fromMpv round-trips every accepted token', () {
      const cases = {
        'ac3': Spdif.ac3,
        'dts': Spdif.dts,
        'dts-hd': Spdif.dtsHd,
        'eac3': Spdif.eac3,
        'truehd': Spdif.trueHd,
      };
      for (final e in cases.entries) {
        expect(
          Spdif.fromMpv(e.key),
          e.value,
          reason: 'fromMpv("${e.key}") should be ${e.value}',
        );
      }
    });

    test('fromMpv returns null for tokens mpv does NOT accept', () {
      // aac and mp3 are af_fmt passthrough labels, NOT audio-spdif codecs —
      // mpv rejects them on the option, so the enum must not surface them.
      for (final bogus in ['aac', 'mp3', 'opus', 'flac', '', 'AC3']) {
        expect(
          Spdif.fromMpv(bogus),
          isNull,
          reason: 'fromMpv("$bogus") → null',
        );
      }
    });

    test('parseMpvList parses CSV and silently drops unknown tokens', () {
      expect(Spdif.parseMpvList('ac3,dts,truehd'), {
        Spdif.ac3,
        Spdif.dts,
        Spdif.trueHd,
      });
      // Mixed valid + rejected: only the valid ones survive.
      expect(Spdif.parseMpvList('aac,ac3,mp3,eac3'), {Spdif.ac3, Spdif.eac3});
      expect(Spdif.parseMpvList('  '), isEmpty);
      expect(Spdif.parseMpvList(''), isEmpty);
    });

    test('formatMpvList round-trips through parseMpvList', () {
      const set = {Spdif.ac3, Spdif.eac3, Spdif.trueHd};
      expect(Spdif.parseMpvList(Spdif.formatMpvList(set)), set);
      expect(Spdif.formatMpvList(const <Spdif>{}), '');
    });
  });
}
