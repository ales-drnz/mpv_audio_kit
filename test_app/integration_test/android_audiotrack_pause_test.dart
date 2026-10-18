// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// The audiotrack output of libmpv-r18 at rest and across pauses, on an
// Android device or emulator (CI: diag/android_emulator.sh, API 24, 29 and
// 34). Up to r17 the output thread spun on a full core while there was
// nothing to play: paused, or with the source dry (F277). A pause flushed
// the audio the track held, so each resume skipped it and the position
// jumped ahead (F276).
//
// Skipped off Android, and on a libmpv older than r18.

import 'dart:io' show Platform;
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

import '_helpers/device_probes.dart';

/// Above this, over [_window], the output thread is busy, not waiting:
/// a spinning thread uses the whole window.
const _restingCpu = Duration(milliseconds: 300);
const _window = Duration(seconds: 2);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    MpvAudioKit.ensureInitialized(hotRestartCleanup: false);
  });

  group('Android audiotrack at rest and across pauses', () {
    if (!Platform.isAndroid) return;

    late Player player;
    late String tone;

    setUp(() async {
      player = Player();
      await player.setVolume(0);
      tone = await writeToneWav('tone_10s.wav', 10);
    });

    tearDown(() async {
      await player.stop();
      await player.dispose();
    });

    /// Plays [media] until audiotrack has taken it and the position moves.
    Future<void> playOnAudiotrack(Media media) async {
      await player.open(media, play: true);
      await player.stream.currentAo
          .firstWhere((ao) => ao == 'audiotrack')
          .timeout(const Duration(seconds: 10));
      await player.stream.position
          .firstWhere((p) => p > const Duration(milliseconds: 300))
          .timeout(const Duration(seconds: 10));
      expect(threadExists(audiotrackThread), isTrue);
    }

    Future<double> timePos() async =>
        double.parse(await player.getRawProperty('time-pos') ?? 'nan');

    testWidgets('the output thread rests while paused (F277)', (_) async {
      if (await skipBeforeRelease(player, 18)) return;
      await playOnAudiotrack(Media(tone));
      await player.pause();
      await Future<void>.delayed(const Duration(milliseconds: 300));
      final cpu = await threadCpuOver(audiotrackThread, _window);
      expect(cpu, lessThan(_restingCpu), reason: 'paused, it used $cpu');
    }, timeout: const Timeout(Duration(seconds: 60)));

    testWidgets('the output thread rests while paused with stream silence '
        '(F277)', (_) async {
      if (await skipBeforeRelease(player, 18)) return;
      await player.setAudioStreamSilence(true);
      await playOnAudiotrack(Media(tone));
      await player.pause();
      await Future<void>.delayed(const Duration(milliseconds: 300));
      final cpu = await threadCpuOver(audiotrackThread, _window);
      expect(cpu, lessThan(_restingCpu), reason: 'paused, it used $cpu');
    }, timeout: const Timeout(Duration(seconds: 60)));

    testWidgets('the output thread rests while the source runs dry (F277)', (
      _,
    ) async {
      if (await skipBeforeRelease(player, 18)) return;
      // 0.5 s of audio, then nothing: the output underruns while playing.
      const format = PcmFormat(sampleRate: 24000, channels: 1);
      final chunk = ByteData(12000 * format.bytesPerFrame);
      for (var i = 0; i < 12000; i++) {
        final v = 0.1 * math.sin(2 * math.pi * 440 * i / 24000);
        chunk.setInt16(i * 2, (v * 32767).round(), Endian.little);
      }
      final source = await player.openPcmStream(format);
      source.add(chunk.buffer.asUint8List());
      await player.stream.currentAo
          .firstWhere((ao) => ao == 'audiotrack')
          .timeout(const Duration(seconds: 10));
      await Future<void>.delayed(const Duration(seconds: 1));
      expect(player.state.playWhenReady, isTrue);
      final cpu = await threadCpuOver(audiotrackThread, _window);
      expect(cpu, lessThan(_restingCpu), reason: 'dry, it used $cpu');
      await source.close();
    }, timeout: const Timeout(Duration(seconds: 60)));

    testWidgets('ten pauses keep the audio the track held (F276)', (_) async {
      if (await skipBeforeRelease(player, 18)) return;
      await playOnAudiotrack(Media(tone));
      // Paused, the position stands still: what it gained while playing is
      // what was played, plus what a flush threw away at the pause.
      var played = Duration.zero;
      var advanced = 0.0;
      for (var i = 0; i < 10; i++) {
        final from = await timePos();
        final sw = Stopwatch()..start();
        await player.play();
        await Future<void>.delayed(const Duration(milliseconds: 400));
        await player.pause();
        played += sw.elapsed;
        await Future<void>.delayed(const Duration(milliseconds: 250));
        advanced += await timePos() - from;
      }
      final drift = advanced - played.inMicroseconds / 1e6;
      expect(
        drift.abs(),
        lessThan(0.5),
        reason:
            'the position moved ${advanced.toStringAsFixed(2)} s in '
            '${played.inMilliseconds} ms of playback',
      );
    }, timeout: const Timeout(Duration(seconds: 60)));

    testWidgets('a seek while paused resumes at the target (F276)', (_) async {
      if (await skipBeforeRelease(player, 18)) return;
      await playOnAudiotrack(Media(tone));
      await player.pause();
      final landed = player.stream.seekCompleted.first.timeout(
        const Duration(seconds: 5),
      );
      await player.seek(const Duration(seconds: 6));
      await landed;
      await player.play();
      await Future<void>.delayed(const Duration(milliseconds: 500));
      await player.pause();
      await Future<void>.delayed(const Duration(milliseconds: 250));
      expect(await timePos(), inInclusiveRange(6.2, 6.9));
    }, timeout: const Timeout(Duration(seconds: 60)));
  });
}
