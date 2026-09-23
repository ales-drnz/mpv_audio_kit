// Diagnostic — not part of the suite. Subscribes to a post-side tap
// and logs timing + sample fingerprint to see exactly what flows.
// The `print`s are the point of this diagnostic test, so avoid_print
// is suppressed file-wide rather than dropping the output.
// ignore_for_file: avoid_print
@TestOn('mac-os || linux || windows')
library;

import 'dart:async';
import 'dart:io';

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

import '../_helpers/setter_test_helpers.dart';

void main() {
  final fixture = '${Directory.current.path}/test/fixtures/sine_5s.flac';
  runtimeSuite(fixturePath: fixture, () {
    test('diag: trace post-side tap frames', () async {
      final player = await buildPlayer();
      try {
        await player.setAudioEffects(
          const AudioEffects(equalizer: EqualizerSettings(enabled: true)),
        );
        await openAndWaitForLoad(player, fixture);

        // Wait for the global pcm-tap to start flowing — proves audio
        // is actually streaming.
        final pcmReady = Completer<void>();
        final pcmSub = player.stream.pcm.listen((_) {
          if (!pcmReady.isCompleted) pcmReady.complete();
        });
        await player.play();
        await pcmReady.future.timeout(const Duration(seconds: 3));
        await pcmSub.cancel();
        print('[diag] global pcm tap flowing');

        // Now subscribe to the post-side tap and log every frame.
        final t0 = DateTime.now().millisecondsSinceEpoch;
        var prevTs = 0;
        var count = 0;
        var prevFirst = 0.0;
        final sub = player.stream
            .tap(AudioEffect.equalizer, side: TapSide.post)
            .listen((frame) {
              final tWall = DateTime.now().millisecondsSinceEpoch - t0;
              final ts = frame.timestamp.inMilliseconds;
              final dTs = ts - prevTs;
              final first = frame.samples.first;
              final last = frame.samples.last;
              final dFirst = (first - prevFirst).abs();
              print(
                '[diag] #${count.toString().padLeft(3)} '
                'tWall=${tWall.toString().padLeft(5)}ms  '
                'ts=${ts.toString().padLeft(7)}ms (Δ${dTs.toString().padLeft(5)}ms)  '
                'first=${first.toStringAsFixed(6).padLeft(10)} '
                '(Δ${dFirst.toStringAsFixed(6).padLeft(10)})  '
                'last=${last.toStringAsFixed(6).padLeft(10)}',
              );
              prevTs = ts;
              prevFirst = first;
              count++;
            });

        await Future<void>.delayed(const Duration(milliseconds: 1500));
        await sub.cancel();
        print('[diag] received $count frames in ~1.5s');
      } finally {
        await player.pause();
        await player.dispose();
      }
    }, timeout: const Timeout(Duration(seconds: 15)));
  });
}
