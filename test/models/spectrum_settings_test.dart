// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

void main() {
  group('SpectrumSettings construction asserts', () {
    test('default constructor produces a valid bundle', () {
      expect(() => const SpectrumSettings(), returnsNormally);
    });

    test('fftSize must be a power of two', () {
      expect(
        () => SpectrumSettings(fftSize: 1000),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => const SpectrumSettings(fftSize: 1024),
        returnsNormally,
      ); // power of 2
    });

    test('fftSize is rejected below 256', () {
      expect(
        () => SpectrumSettings(fftSize: 128),
        throwsA(isA<AssertionError>()),
      );
      expect(() => const SpectrumSettings(fftSize: 256), returnsNormally);
    });

    test('fftSize is rejected above 4096', () {
      expect(
        () => SpectrumSettings(fftSize: 8192),
        throwsA(isA<AssertionError>()),
      );
      expect(() => const SpectrumSettings(fftSize: 4096), returnsNormally);
    });

    test('bandCount must be positive', () {
      expect(
        () => SpectrumSettings(bandCount: 0),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => SpectrumSettings(bandCount: -1),
        throwsA(isA<AssertionError>()),
      );
      expect(() => const SpectrumSettings(bandCount: 1), returnsNormally);
    });

    test('bandLowHz must be positive', () {
      expect(
        () => SpectrumSettings(bandLowHz: 0),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => SpectrumSettings(bandLowHz: -10),
        throwsA(isA<AssertionError>()),
      );
    });

    test('bandHighHz must be greater than bandLowHz', () {
      expect(
        () => SpectrumSettings(bandLowHz: 100, bandHighHz: 100),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => SpectrumSettings(bandLowHz: 100, bandHighHz: 50),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => const SpectrumSettings(bandLowHz: 100, bandHighHz: 200),
        returnsNormally,
      );
    });

    test('attackSmoothing is constrained to [0, 1]', () {
      expect(
        () => SpectrumSettings(attackSmoothing: -0.01),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => SpectrumSettings(attackSmoothing: 1.01),
        throwsA(isA<AssertionError>()),
      );
      expect(() => const SpectrumSettings(attackSmoothing: 0), returnsNormally);
      expect(() => const SpectrumSettings(attackSmoothing: 1), returnsNormally);
    });

    test('releaseSmoothing is constrained to [0, 1]', () {
      expect(
        () => SpectrumSettings(releaseSmoothing: -0.01),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => SpectrumSettings(releaseSmoothing: 1.01),
        throwsA(isA<AssertionError>()),
      );
    });

    test('maxDb must be greater than minDb', () {
      expect(
        () => SpectrumSettings(minDb: -10, maxDb: -10),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => SpectrumSettings(minDb: -10, maxDb: -20),
        throwsA(isA<AssertionError>()),
      );
    });

    test('copyWith result is itself validated', () {
      const seed = SpectrumSettings();
      expect(
        () => seed.copyWith(fftSize: 1000),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => seed.copyWith(attackSmoothing: 2),
        throwsA(isA<AssertionError>()),
      );
      expect(() => seed.copyWith(fftSize: 4096), returnsNormally);
    });
  });
}
