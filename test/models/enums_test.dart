// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/src/models/enums.dart';

void main() {
  group('GaplessMode', () {
    test('round-trip fromMpv ↔ mpvValue is identity', () {
      for (final mode in GaplessMode.values) {
        expect(GaplessMode.fromMpv(mode.mpvValue), mode);
      }
    });

    test('unknown values fall back to weak (mpv default)', () {
      expect(GaplessMode.fromMpv('totally-bogus'), GaplessMode.weak);
      expect(GaplessMode.fromMpv(''), GaplessMode.weak);
    });
  });

  group('ReplayGainMode', () {
    test('round-trip fromMpv ↔ mpvValue is identity', () {
      for (final mode in ReplayGainMode.values) {
        expect(ReplayGainMode.fromMpv(mode.mpvValue), mode);
      }
    });

    test('unknown values fall back to no', () {
      expect(ReplayGainMode.fromMpv('totally-bogus'), ReplayGainMode.no);
    });
  });

  group('AudioDisplayMode', () {
    test('round-trip fromMpv ↔ mpvValue is identity', () {
      for (final mode in AudioDisplayMode.values) {
        expect(AudioDisplayMode.fromMpv(mode.mpvValue), mode);
      }
    });

    test('unknown values fall back to embeddedFirst (mpv default)', () {
      expect(AudioDisplayMode.fromMpv('garbage'), AudioDisplayMode.embeddedFirst);
    });

    test('mpvValue uses kebab-case for multi-word variants', () {
      expect(AudioDisplayMode.embeddedFirst.mpvValue, 'embedded-first');
      expect(AudioDisplayMode.externalFirst.mpvValue, 'external-first');
    });
  });

  group('CoverArtAutoMode', () {
    test('round-trip fromMpv ↔ mpvValue is identity', () {
      for (final mode in CoverArtAutoMode.values) {
        expect(CoverArtAutoMode.fromMpv(mode.mpvValue), mode);
      }
    });

    test('unknown values fall back to no (library default)', () {
      expect(CoverArtAutoMode.fromMpv('garbage'), CoverArtAutoMode.no);
    });
  });

  group('CacheMode', () {
    test('round-trip fromMpv ↔ mpvValue is identity', () {
      for (final mode in CacheMode.values) {
        expect(CacheMode.fromMpv(mode.mpvValue), mode);
      }
    });

    test('unknown values fall back to auto', () {
      expect(CacheMode.fromMpv('maybe'), CacheMode.auto);
    });
  });
}
