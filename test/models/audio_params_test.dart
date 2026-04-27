// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

void main() {
  group('AudioParams', () {
    test('default constructor: all fields null', () {
      const p = AudioParams();
      expect(p.format, isNull);
      expect(p.sampleRate, isNull);
      expect(p.channels, isNull);
      expect(p.channelCount, isNull);
      expect(p.hrChannels, isNull);
      expect(p.codec, isNull);
      expect(p.codecName, isNull);
    });

    test('full-field equality', () {
      const a = AudioParams(
        format: 'floatp',
        sampleRate: 48000,
        channels: 'stereo',
        channelCount: 2,
        hrChannels: 'L+R',
        codec: 'flac',
        codecName: 'FLAC',
      );
      const b = AudioParams(
        format: 'floatp',
        sampleRate: 48000,
        channels: 'stereo',
        channelCount: 2,
        hrChannels: 'L+R',
        codec: 'flac',
        codecName: 'FLAC',
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('different field → not equal', () {
      const a = AudioParams(format: 's16');
      const b = AudioParams(format: 's32');
      expect(a, isNot(b));
    });

    test('copyWith updates only the requested field', () {
      const a = AudioParams(format: 's16', sampleRate: 44100);
      final b = a.copyWith(sampleRate: 48000);
      expect(b.format, 's16');
      expect(b.sampleRate, 48000);
    });

    test('copyWith with no args returns structurally-equal value', () {
      const a = AudioParams(format: 's16', codec: 'flac');
      final b = a.copyWith();
      expect(b, a);
    });

    test('copyWith chained doesn\'t leak null over previously-set fields', () {
      // Freezed chain semantic: copyWith(format: 'x').copyWith(sampleRate: 1)
      // should keep format='x', not reset to null.
      const a = AudioParams();
      final b = a.copyWith(format: 'x').copyWith(sampleRate: 1);
      expect(b.format, 'x');
      expect(b.sampleRate, 1);
    });
  });
}
