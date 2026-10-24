// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'dart:async';

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

import '../_helpers/setter_test_helpers.dart';

/// API-surface tests for the spectrum / PCM streams. The end-to-end FFT
/// and PCM data assertions are in setters_spectrum_e2e_test, which
/// plays a fixture through the `pcm-tap-frame` mpv property. This file
/// covers:
///
///   1. SpectrumSettings round-trip via setSpectrum / updateSpectrum.
///   2. spectrumSettings getter reflects the latest call.
///   3. Pipeline laziness — subscribing to spectrum / pcm doesn't
///      throw even when the property is unavailable, and is safe to
///      cancel back to zero listeners.
///   4. The two streams exist on PlayerStream.
///   5. dispose() tears the pipeline down without hangs.
void main() {
  final fixturePath = defaultFixturePath();

  runtimeSuite(fixturePath: fixturePath, () {
    group('Spectrum / PCM setters', () {
      late Player player;

      setUpAll(() async {
        player = await buildPlayerWithFixture(fixturePath: fixturePath);
      });

      tearDownAll(() async {
        await player.dispose();
      });

      test('default SpectrumSettings in state.spectrum', () {
        // Before any setSpectrum, the state holds the defaults.
        final s = player.state.spectrum;
        expect(s.fftSize, 2048);
        expect(s.bandCount, 64);
        expect(s.window, WindowFunction.hann);
        expect(s.emitInterval, const Duration(milliseconds: 33));
      });

      test('setSpectrum / updateSpectrum apply synchronously', () {
        player.setSpectrum(
          const SpectrumSettings(
            fftSize: 1024,
            bandCount: 32,
            window: WindowFunction.blackmanHarris,
            emitInterval: Duration(milliseconds: 16),
            attackSmoothing: 0.7,
            releaseSmoothing: 0.05,
            minDb: -80,
            maxDb: -5,
          ),
        );
        var s = player.state.spectrum;
        expect(s.fftSize, 1024);
        expect(s.bandCount, 32);
        expect(s.window, WindowFunction.blackmanHarris);
        expect(s.emitInterval, const Duration(milliseconds: 16));
        expect(s.attackSmoothing, 0.7);
        expect(s.releaseSmoothing, 0.05);
        expect(s.minDb, -80);
        expect(s.maxDb, -5);

        // updateSpectrum mapper sees the current settings.
        player.updateSpectrum((c) => c.copyWith(bandCount: 128));
        s = player.state.spectrum;
        expect(s.bandCount, 128);
        expect(s.fftSize, 1024); // other fields preserved
      });

      test(
        'subscribe to spectrum + pcm without crash; cancel back to zero',
        () async {
          // The host libmpv binaries may be unpatched; the property may
          // return M_PROPERTY_UNAVAILABLE on every poll. We're only
          // asserting the wrapper-side plumbing doesn't blow up.
          final spectrumSub = player.stream.fft.listen((_) {});
          final pcmSub = player.stream.pcm.listen((_) {});
          // Give the timer a few ticks.
          await Future<void>.delayed(const Duration(milliseconds: 120));
          await spectrumSub.cancel();
          await pcmSub.cancel();
          // Re-subscribe — pipeline should re-arm.
          final reSub = player.stream.fft.listen((_) {});
          await Future<void>.delayed(const Duration(milliseconds: 60));
          await reSub.cancel();
        },
        timeout: const Timeout(Duration(seconds: 5)),
      );

      test('setSpectrum mid-stream (mutability) does not throw', () async {
        final sub = player.stream.fft.listen((_) {});
        try {
          player.updateSpectrum(
            (c) => c.copyWith(
              fftSize: 4096,
              emitInterval: const Duration(milliseconds: 20),
            ),
          );
          await Future<void>.delayed(const Duration(milliseconds: 80));
          player.updateSpectrum(
            (c) => c.copyWith(fftSize: 512, window: WindowFunction.hann),
          );
          await Future<void>.delayed(const Duration(milliseconds: 80));
        } finally {
          await sub.cancel();
        }
      }, timeout: const Timeout(Duration(seconds: 5)));

      test('an emit interval under 8 ms is rejected', () {
        final before = player.state.spectrum;
        expect(
          () => player.setSpectrum(
            const SpectrumSettings(emitInterval: Duration.zero),
          ),
          throwsA(isA<AssertionError>()),
        );
        expect(player.state.spectrum, before);
      });
    });
  });
}
