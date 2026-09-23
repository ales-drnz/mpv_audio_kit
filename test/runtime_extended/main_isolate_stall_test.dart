// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

@TestOn('mac-os || linux')
@Timeout(Duration(minutes: 3))
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart' show TestWidgetsFlutterBinding;
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

import '../_helpers/libmpv_resolver.dart';
import '../_helpers/slow_core_shim.dart';

/// Stall injected in front of every synchronous `mpv_get_property*` call.
/// Models the real-world window where the mpv playloop is busy (CoreAudio
/// waking a Bluetooth/AirPlay/HDMI device during AO init takes seconds)
/// and every synchronous client call queues behind it.
const int _getDelayUs = 500 * 1000;

/// Main-isolate heartbeat gaps above this fail the test. One leftover
/// synchronous read in the file-load window costs ≥ [_getDelayUs] (500ms),
/// comfortably above this bound; scheduler noise stays well below it.
const int _maxGapMs = 350;

void main() {
  var ready = false;

  setUpAll(() async {
    // rootBundle must work for the TLS CA bundle extraction in bring-up.
    TestWidgetsFlutterBinding.ensureInitialized();
    final real = resolveLibmpv();
    if (real == null) {
      markTestSkipped('libmpv not found');
      return;
    }
    final shim = await SlowCoreShim.build();
    if (shim == null) {
      markTestSkipped('no host C compiler — cannot build the slow-core shim');
      return;
    }
    shim.configure(realLibmpvPath: real, getDelayUs: _getDelayUs);
    MpvAudioKit.ensureInitialized(libmpv: shim.path, hotRestartCleanup: false);
    ready = true;
  });

  test('a busy mpv core cannot stall the main isolate through the '
      'file-load window', () async {
    if (!ready) return;
    final coverPath =
        '${Directory.current.path}/test/fixtures/sine_with_cover.flac';
    if (!File(coverPath).existsSync()) {
      markTestSkipped('Cover fixture missing: $coverPath');
      return;
    }

    final player = Player(
      configuration: const PlayerConfiguration(logLevel: LogLevel.off),
    );
    try {
      await player.setRawProperty('ao', 'null');

      // Pre-subscribe BEFORE open (optimistic emits land synchronously).
      // Cover arrival + PLAYBACK_RESTART together bracket every read the
      // file-load window performs (position, chapters, cover, path).
      final coverFuture = player.stream.coverArt
          .firstWhere((c) => c != null && c.bytes.isNotEmpty)
          .timeout(const Duration(seconds: 30));
      final restartFuture = player.stream.seekCompleted.first.timeout(
        const Duration(seconds: 30),
      );

      // 1ms heartbeat: any synchronous FFI wait on the main isolate shows
      // up as an inter-tick gap roughly the length of the wait. Missed
      // ticks coalesce, so the first tick after a stall carries the full
      // gap.
      final sw = Stopwatch()..start();
      var lastMs = 0;
      var maxGapMs = 0;
      final timer = Timer.periodic(const Duration(milliseconds: 1), (_) {
        final now = sw.elapsedMilliseconds;
        final gap = now - lastMs;
        lastMs = now;
        if (gap > maxGapMs) maxGapMs = gap;
      });

      CoverArt? cover;
      try {
        await player.open(Media(coverPath), play: false);
        cover = await coverFuture;
        await restartFuture;
        // One extra breath so the tail of the last event-handler turn is
        // still inside the measured window.
        await Future<void>.delayed(const Duration(milliseconds: 100));
      } finally {
        timer.cancel();
      }

      // ignore: avoid_print
      print(
        '[stall] max main-isolate heartbeat gap: ${maxGapMs}ms '
        '(injected core stall per read: ${_getDelayUs ~/ 1000}ms)',
      );

      expect(
        maxGapMs,
        lessThan(_maxGapMs),
        reason:
            'The main isolate froze for ${maxGapMs}ms while the core '
            'was busy — a synchronous mpv read is still running on the '
            'main isolate inside the file-load window. With a real '
            'CoreAudio device waking up, this is the beachball.',
      );

      // The slow path must still deliver correct data, just off-main.
      expect(cover!.bytes.isNotEmpty, isTrue);
      expect(cover.mimeType, 'image/png');
    } finally {
      await player.dispose();
    }
  });

  test('a busy mpv core cannot stall the main isolate while a DSP visualizer '
      'is polling', () async {
    if (!ready) return;
    final fixture = '${Directory.current.path}/test/fixtures/sine_440hz_1s.wav';
    if (!File(fixture).existsSync()) {
      markTestSkipped('Fixture missing: $fixture');
      return;
    }

    final player = Player(
      configuration: const PlayerConfiguration(logLevel: LogLevel.off),
    );
    try {
      await player.setRawProperty('ao', 'null');

      // Arm the spectrum pipeline: subscribing to `fft` starts its
      // `pcm-tap-frame` poll loop. Each poll is an mpv property read; on the
      // main isolate, under a busy core, every one of those reads would
      // freeze the UI — exactly the visualizer beachball.
      final fftSub = player.stream.fft.listen((_) {});
      // Loop playback so frames keep flowing for the whole measurement.
      await player.setLoop(Loop.file);
      await player.open(Media(fixture), play: true);

      // Let the poll loop run against the busy core for a steady window.
      final sw = Stopwatch()..start();
      var lastMs = 0;
      var maxGapMs = 0;
      final timer = Timer.periodic(const Duration(milliseconds: 1), (_) {
        final now = sw.elapsedMilliseconds;
        final gap = now - lastMs;
        lastMs = now;
        if (gap > maxGapMs) maxGapMs = gap;
      });
      await Future<void>.delayed(const Duration(seconds: 2));
      timer.cancel();
      await fftSub.cancel();

      // ignore: avoid_print
      print(
        '[stall-dsp] max main-isolate heartbeat gap: ${maxGapMs}ms '
        '(injected core stall per read: ${_getDelayUs ~/ 1000}ms)',
      );

      expect(
        maxGapMs,
        lessThan(_maxGapMs),
        reason:
            'The main isolate froze for ${maxGapMs}ms while a DSP '
            'visualizer was polling and the core was busy — a synchronous '
            'mpv read still runs on the main isolate in the poll loop.',
      );
    } finally {
      await player.dispose();
    }
  });
}
