// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'dart:async';

import 'package:test/test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import '../_helpers/setter_test_helpers.dart';

/// End-to-end assertions that need a libmpv binary built with
/// `patch_pcm_tap.py`. Plays a fixture through the null AO, subscribes
/// to the spectrum / PCM streams, and verifies real frames arrive.
///
/// The null AO is a push driver — `ao_post_process_data` runs on every
/// chunk it consumes, so the patched tap fires regardless of whether
/// the host has speakers. If the binary is unpatched the
/// `pcm-tap-frame` property returns `M_PROPERTY_UNAVAILABLE`, no frames
/// flow, and these tests fail with a timeout — which is the expected
/// hard signal that a fresh binary build is needed.
void main() {
  final fixturePath = defaultFixturePath();

  setUpAll(() => initLibmpvOrSkip(fixturePath: fixturePath));

  group('Spectrum / PCM end-to-end', () {
    late Player player;

    setUpAll(() async {
      player = await buildPlayerWithFixture(fixturePath: fixturePath);
    });

    tearDownAll(() async {
      await player.dispose();
    });

    test('PcmFrame arrives within 1s of play() — non-zero samples', () async {
      // Speed up the emit cadence so the test doesn't wait a full
      // 33 ms per tick.
      await player.setSpectrum(
        const SpectrumSettings(emitInterval: Duration(milliseconds: 16)),
      );
      final completer = Completer<PcmFrame>();
      final sub = player.stream.pcm.listen((f) {
        if (!completer.isCompleted) completer.complete(f);
      });
      try {
        await player.play();
        final frame = await completer.future
            .timeout(const Duration(seconds: 2));
        expect(frame.samples.length, greaterThan(0));
        expect(frame.sampleRate, greaterThan(0));
        expect(frame.channels, greaterThanOrEqualTo(1));
        expect(frame.timestamp, isA<Duration>());
        // Sine-440 fixture: at least some samples must be non-zero
        // (the wrapper / mpv silence-pad anything before play() lands,
        // so non-zero proves the post-DSP signal made it through).
        final hasSignal = frame.samples.any((s) => s.abs() > 1e-4);
        expect(hasSignal, isTrue,
            reason: 'PCM frame should contain non-silent audio');
      } finally {
        await sub.cancel();
        await player.pause();
      }
    }, timeout: const Timeout(Duration(seconds: 5)));

    test('FftFrame bands respond to the sine — at least one band > 0',
        () async {
      await player.setSpectrum(
        const SpectrumSettings(
          fftSize: 1024,
          bandCount: 64,
          emitInterval: Duration(milliseconds: 16),
        ),
      );
      final completer = Completer<FftFrame>();
      final sub = player.stream.spectrum.listen((f) {
        // Wait for a frame that has signal (the very first frame can
        // arrive before audio has flowed through the AO).
        final hasEnergy = f.bands.any((b) => b > 0.01);
        if (hasEnergy && !completer.isCompleted) completer.complete(f);
      });
      try {
        await player.play();
        final frame = await completer.future
            .timeout(const Duration(seconds: 3));
        expect(frame.bands.length, 64);
        expect(frame.bins.length, 512); // fftSize / 2
        expect(frame.sampleRate, greaterThan(0));
        // The 440 Hz sine fixture should peak in a low band.
        final maxBand =
            frame.bands.reduce((a, b) => a > b ? a : b);
        expect(maxBand, greaterThan(0.01));
      } finally {
        await sub.cancel();
        await player.pause();
      }
    }, timeout: const Timeout(Duration(seconds: 5)));
  });
}
