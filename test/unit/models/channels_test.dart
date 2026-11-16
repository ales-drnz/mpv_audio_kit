// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

void main() {
  group('Channels equality is by mpvValue', () {
    test('a custom layout with a named string equals the named one', () {
      // The state comes from fromMpv, which gives the named value: a
      // comparison with what the app wrote must not depend on the form.
      for (final (custom, named) in [
        (const Channels.custom('stereo'), Channels.stereo),
        (const Channels.custom('5.1'), Channels.fiveOne),
        (const Channels.custom('auto-safe'), Channels.autoSafe),
      ]) {
        expect(custom, named);
        expect(named, custom);
        expect(custom.hashCode, named.hashCode);
        expect(Channels.fromMpv(custom.mpvValue), custom);
        expect({custom, named}, hasLength(1));
      }
    });

    test('different strings stay different', () {
      expect(Channels.stereo, isNot(Channels.twoZero));
      expect(const Channels.custom('fl-fr'), isNot(Channels.stereo));
      expect(
        const Channels.custom('fl-fr'),
        isNot(const Channels.custom('fl-fr-lfe')),
      );
      expect(const Channels.custom('fl-fr'), const Channels.custom('fl-fr'));
      expect(Channels.fromMpv('stereo'), Channels.stereo);
    });

    test('AudioParams compares its channels the same way', () {
      expect(
        const AudioParams(channels: Channels.custom('stereo')),
        const AudioParams(channels: Channels.stereo),
      );
    });
  });
}
