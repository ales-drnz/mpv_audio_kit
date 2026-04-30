// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

void main() {
  group('AudioFilter.custom', () {
    test('passes the raw string through unchanged', () {
      const f = AudioFilter.custom('lavfi-aresample=48000');
      expect(f.value, 'lavfi-aresample=48000');
    });

    test('toString includes the filter value', () {
      const f = AudioFilter.custom('foo');
      expect(f.toString(), contains('foo'));
    });
  });

  group('AudioFilter.equalizer', () {
    test('produces 10 comma-separated lavfi-equalizer entries', () {
      final f = AudioFilter.equalizer(
          [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]);
      // 10 bands → 10 entries → 9 commas.
      expect(f.value.split(',').length, 10);
      expect(f.value, contains('lavfi-equalizer='));
    });

    test('uses ISO standard center frequencies', () {
      final f = AudioFilter.equalizer(
          [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]);
      const centers = ['31.25', '62.5', '125.0', '250.0', '500.0',
                       '1000.0', '2000.0', '4000.0', '8000.0', '16000.0'];
      for (final c in centers) {
        expect(f.value, contains('f=$c'));
      }
    });

    test('encodes per-band gains with two decimals', () {
      final f = AudioFilter.equalizer(
          [3.0, -3.5, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]);
      // Gains are emitted as `g=<value>` with 2 decimals.
      expect(f.value, contains('g=3.00'));
      expect(f.value, contains('g=-3.50'));
    });

    test('throws ArgumentError on length != 10', () {
      expect(() => AudioFilter.equalizer([1.0, 2.0]),
          throwsA(isA<ArgumentError>()));
      expect(
          () => AudioFilter.equalizer([0.0, 0.0, 0.0, 0.0, 0.0,
              0.0, 0.0, 0.0, 0.0, 0.0, 0.0]),
          throwsA(isA<ArgumentError>()));
    });
  });

  group('AudioFilter.compressor', () {
    test('emits lavfi-acompressor with default values', () {
      final f = AudioFilter.compressor();
      expect(f.value, contains('lavfi-acompressor='));
      expect(f.value, contains('threshold=-20.0dB'));
      expect(f.value, contains('ratio=4'));
    });

    test('respects custom parameters', () {
      final f = AudioFilter.compressor(
          threshold: -10, ratio: 8, attack: 5, release: 100);
      expect(f.value, contains('threshold=-10.0dB'));
      expect(f.value, contains('ratio=8'));
      expect(f.value, contains('attack=5'));
      expect(f.value, contains('release=100'));
    });
  });

  group('AudioFilter.loudnorm', () {
    test('default values match EBU R128 broadcast targets', () {
      final f = AudioFilter.loudnorm();
      expect(f.value, contains('I=-16.0'));
      expect(f.value, contains('TP=-1.5'));
      expect(f.value, contains('LRA=11.0'));
    });
  });

  group('AudioFilter.scaleTempo + echo + extraStereo + crystalizer + crossfeed',
      () {
    test('scaleTempo emits rubberband filter', () {
      final f = AudioFilter.scaleTempo(pitch: 1.2, tempo: 0.9);
      expect(f.value, 'rubberband=pitch=1.2:tempo=0.9');
    });

    test('echo emits aecho with delay and falloff', () {
      final f = AudioFilter.echo(delay: 100, falloff: 0.6);
      expect(f.value, contains('lavfi-aecho='));
      expect(f.value, contains(':100:0.6'));
    });

    test('extraStereo emits with custom factor', () {
      final f = AudioFilter.extraStereo(m: 1.5);
      expect(f.value, 'lavfi-extrastereo=m=1.5');
    });

    test('crystalizer emits with custom intensity', () {
      final f = AudioFilter.crystalizer(intensity: 3.0);
      expect(f.value, 'lavfi-crystalizer=i=3.0');
    });

    test('crossfeed emits canonical name', () {
      final f = AudioFilter.crossfeed();
      expect(f.value, 'lavfi-crossfeed');
    });
  });
}
