// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// Cost of the Dart spectrum on a device. A measurement, not a check: it
// only fails when the spectrum stops producing frames. Run it in profile
// mode, where Dart is compiled ahead of time as in a release build:
//
//   flutter drive --profile -d <device> \
//     --driver=test_driver/integration_test.dart \
//     --target=integration_test/fft_cost_test.dart
//
// The numbers go to the console (lines starting with [fft_cost]) and to
// build/integration_response_data.json. On a Ryzen 7 5800X under Linux a
// 33 ms poll costs about 150 us at every FFT size.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

import '_helpers/asset_fixture.dart';

/// One poll of the spectrum pipeline at its default 33 ms interval:
/// 48 kHz stereo, a 440 Hz tone with some noise.
PcmFrame _pollFrame(int index) {
  const sampleRate = 48000;
  const perChannel = sampleRate * 33 ~/ 1000;
  final rnd = math.Random(index);
  final samples = Float32List(perChannel * 2);
  for (var i = 0; i < perChannel; i++) {
    final t = (index * perChannel + i) / sampleRate;
    final v = 0.5 * math.sin(2 * math.pi * 440 * t) + 0.05 * rnd.nextDouble();
    samples[2 * i] = v;
    samples[2 * i + 1] = v;
  }
  return PcmFrame(
    samples: samples,
    timestamp: Duration(milliseconds: index * 33),
    sampleRate: sampleRate,
    channels: 2,
  );
}

Map<String, num> _stats(List<int> us) {
  final sorted = [...us]..sort();
  int at(double q) => sorted[((sorted.length - 1) * q).round()];
  return {
    'p50_us': at(0.5),
    'p95_us': at(0.95),
    'max_us': sorted.last,
    'mean_us': us.reduce((a, b) => a + b) / us.length,
  };
}

/// How late a 16 ms periodic timer fires on the main isolate over [span].
Future<Map<String, num>> _timerLateness(Duration span) async {
  final lateUs = <int>[];
  final sw = Stopwatch()..start();
  var last = 0;
  final timer = Timer.periodic(const Duration(milliseconds: 16), (_) {
    final now = sw.elapsedMicroseconds;
    lateUs.add(math.max(0, now - last - 16000));
    last = now;
  });
  await Future<void>.delayed(span);
  timer.cancel();
  return _stats(lateUs);
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final report = <String, Object>{};

  setUpAll(() {
    MpvAudioKit.ensureInitialized(hotRestartCleanup: false);
  });

  tearDownAll(() {
    binding.reportData = {'fft_cost': report};
  });

  testWidgets('BandProcessor cost per 33 ms poll', (_) async {
    const polls = 600;
    final frames = [for (var i = 0; i < polls + 100; i++) _pollFrame(i)];
    for (final fftSize in [1024, 2048, 4096]) {
      final processor = BandProcessor(SpectrumSettings(fftSize: fftSize));
      // Warm-up, outside the measure.
      for (var i = 0; i < 100; i++) {
        processor.process(frames[i]);
      }
      final us = <int>[];
      final sw = Stopwatch();
      for (var i = 100; i < polls + 100; i++) {
        sw
          ..reset()
          ..start();
        processor.process(frames[i]);
        sw.stop();
        us.add(sw.elapsedMicroseconds);
      }
      final stats = _stats(us);
      final budget = (stats['mean_us']! / 33000 * 100).toStringAsFixed(2);
      report['dsp_fft$fftSize'] = {...stats, 'budget_percent': budget};
      debugPrint('[fft_cost] dsp fftSize=$fftSize $stats, $budget% of 33 ms');
    }
  }, timeout: const Timeout(Duration(minutes: 2)));

  testWidgets('spectrum during playback', (_) async {
    final fixture = await materializeFixture('sine_440hz_1s.wav');
    final player = Player(
      configuration: const PlayerConfiguration(logLevel: LogLevel.off),
    );
    try {
      await player.setLoop(Loop.file);
      await player.open(Media(fixture), play: true);
      await player.stream.playing.firstWhere((p) => p);

      const span = Duration(seconds: 10);
      final idle = await _timerLateness(span);
      report['timer_late_spectrum_off'] = idle;
      debugPrint('[fft_cost] 16 ms timer lateness, spectrum off: $idle');

      var frames = 0;
      final sub = player.stream.fft.listen((_) => frames++);
      final busy = await _timerLateness(span);
      await sub.cancel();
      final perSecond = frames / span.inSeconds;
      report['timer_late_spectrum_on'] = busy;
      report['fft_frames_per_second'] = perSecond;
      debugPrint('[fft_cost] 16 ms timer lateness, spectrum on: $busy');
      debugPrint('[fft_cost] fft frames per second: $perSecond');
      expect(frames, greaterThan(0), reason: 'the spectrum emitted nothing');
    } finally {
      await player.dispose();
    }
  }, timeout: const Timeout(Duration(minutes: 2)));
}
