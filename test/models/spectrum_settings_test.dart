// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

/// The `dart` executable of the Flutter SDK running the tests.
String _dart() {
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root != null) {
    final exe = Platform.isWindows ? 'dart.exe' : 'dart';
    final path = [
      root,
      'bin',
      'cache',
      'dart-sdk',
      'bin',
      exe,
    ].join(Platform.pathSeparator);
    if (File(path).existsSync()) return path;
  }
  return 'dart';
}

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

  // A release build skips the constructor asserts, so out of range settings
  // reach setSpectrum: an overlapFactor of 0 then threw from every poll of
  // the FFT stream. setSpectrum validates them first. `flutter test` always
  // runs asserts, so a `dart` process, which runs none, builds them.
  group(
    'validate, in a build without asserts',
    testOn: 'mac-os || linux || windows',
    () {
      test('refuses what the asserts refuse and passes the rest', () async {
        final result = await Process.run(_dart(), [
          'test/_helpers/probes/spectrum_settings_probe.dart',
        ], stdoutEncoding: utf8);
        expect(result.exitCode, 0, reason: '${result.stderr}');
        final report =
            jsonDecode((result.stdout as String).trim().split('\n').last)
                as Map<String, dynamic>;
        expect(report['asserts'], isFalse);
        final cases = report['cases'] as Map<String, dynamic>;
        expect(cases['defaults'], isNull);
        expect(cases['edges'], isNull);
        for (final MapEntry(:key, :value) in cases.entries) {
          if (key == 'defaults' || key == 'edges') continue;
          expect(value, anyOf('ArgumentError', 'RangeError'), reason: key);
        }
      }, timeout: const Timeout(Duration(minutes: 2)));
    },
  );

  group('validate and the asserts share their limits', () {
    // validate is what holds in a release build.
    SpectrumSettings fft(int v) => SpectrumSettings(fftSize: v);
    SpectrumSettings overlap(int v) => SpectrumSettings(overlapFactor: v);
    SpectrumSettings attack(double v) => SpectrumSettings(attackSmoothing: v);
    SpectrumSettings release(double v) => SpectrumSettings(releaseSmoothing: v);

    test('a value at a limit passes both', () {
      for (final build in [
        () => fft(256),
        () => fft(4096),
        () => overlap(1),
        () => overlap(16),
        () => attack(0),
        () => attack(1),
        () => release(0),
        () => release(1),
      ]) {
        build().validate();
      }
    });

    test('a value past a limit fails the assert', () {
      // validate cannot be reached with such a value while the asserts
      // run: test/_helpers/probes/spectrum_settings_probe.dart runs it
      // without them.
      for (final build in [
        () => fft(128),
        () => fft(8192),
        () => overlap(32),
        () => attack(1.5),
        () => attack(-0.5),
        () => release(1.5),
      ]) {
        expect(build, throwsA(isA<AssertionError>()));
      }
    });
  });
}
