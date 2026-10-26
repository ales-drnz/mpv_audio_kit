// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

// kit-core-1: `mpv_hook_continue` locks the core. For `on_load` and the
// other hooks mpv waits for the continue in its hook loop, so the lock
// comes at once; `on_prefetch` of libmpv-r20 keeps the playloop running,
// and its continue waits for whatever the core is doing. On the main
// isolate a continue that came while the audio output opened (a Bluetooth
// or AirPlay device waking up) froze the UI for the whole open: 1.95 s
// here, with an output that waits 2 s for the reader of its FIFO.

@TestOn('mac-os || linux')
library;

import 'dart:async';
import 'dart:io';

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

import '../_helpers/long_wav.dart';
import '../_helpers/setter_test_helpers.dart';

/// Main-isolate heartbeat gaps above this fail the test, as in
/// main_isolate_stall_test: the output below takes 2 s to open.
const int _maxGapMs = 350;

/// A 1 ms heartbeat on the main isolate: the largest gap between two
/// ticks. A synchronous wait shows up as a gap about as long.
class _Beat {
  final _sw = Stopwatch()..start();
  int _last = 0;
  int maxGap = 0;
  Timer? _timer;

  void start() {
    _last = _sw.elapsedMilliseconds;
    _timer = Timer.periodic(const Duration(milliseconds: 1), (_) {
      final now = _sw.elapsedMilliseconds;
      if (now - _last > maxGap) maxGap = now - _last;
      _last = now;
    });
  }

  /// Stops the beat: the largest gap, the one still open included.
  int stop() {
    _timer?.cancel();
    final now = _sw.elapsedMilliseconds;
    if (now - _last > maxGap) maxGap = now - _last;
    return maxGap;
  }
}

void main() {
  runtimeSuite(() {
    libmpvReleaseGroup(20, 'The continue of on_prefetch', () {
      late Directory dir;
      late String a;
      late String b;
      late String fifo;
      late Process reader;
      late Player player;

      // A reader of the FIFO, after [delay].
      Future<Process> readFifo([Duration delay = Duration.zero]) =>
          Process.start('sh', [
            '-c',
            'sleep ${delay.inMilliseconds / 1000}; exec cat "$fifo" >/dev/null',
          ]);

      setUp(() async {
        dir = await Directory.systemTemp.createTemp('mak_prefetch_continue');
        a = '${dir.path}/a.wav';
        b = '${dir.path}/b.wav';
        fifo = '${dir.path}/out.fifo';
        await File(a).writeAsBytes(longWav(60));
        await File(b).writeAsBytes(longWav(60));
        await Process.run('mkfifo', [fifo]);
        reader = await readFifo();
        player = await buildPlayer();
        // ao=pcm writes into the FIFO, and its open waits for a reader.
        await player.setRawProperty('ao', 'pcm');
        await player.setRawProperty('ao-pcm-file', fifo);
        // A local file reads ahead to its end only with the cache on.
        await player.setRawProperty('cache', 'yes');
        await player.setPrefetchPlaylist(true);
        await player.registerHook(Hook.prefetch);
      });

      tearDown(() async {
        await player.dispose();
        reader.kill();
        await dir.delete(recursive: true);
      });

      // Opens [a, b] paused and returns the on_prefetch event of b, held.
      Future<MpvHookEvent> heldPrefetch() async {
        final event = player.stream.hook
            .firstWhere((e) => e.hook == Hook.prefetch)
            .timeout(const Duration(seconds: 15));
        await player.openAll([Media(a), Media(b)], play: false);
        final held = await event;
        await Future<void>.delayed(const Duration(milliseconds: 200));
        return held;
      }

      // Reopens the output, which now waits 2 s for its reader: the core
      // thread is busy for that long.
      Future<void> slowOutputOpen() async {
        reader.kill();
        await reader.exitCode;
        reader = await readFifo(const Duration(seconds: 2));
        unawaited(player.sendRawCommand(['ao-reload']));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }

      test('a continue while the core is busy leaves the main isolate '
          'free', () async {
        final held = await heldPrefetch();
        final states = <PrefetchState>[];
        final sub = player.stream.prefetchState.listen(states.add);
        final beat = _Beat()..start();
        await slowOutputOpen();
        await player.continueHook(held.id);
        // Past the open, and the continue reached mpv: b opens ahead.
        await waitUntil(
          () => states.any((s) => s != PrefetchState.idle),
          timeout: const Duration(seconds: 6),
          reason: 'the continue never reached mpv: $states',
        );
        await sub.cancel();
        expect(beat.stop(), lessThan(_maxGapMs));
      }, timeout: const Timeout(Duration(seconds: 40)));

      test('a dispose with on_prefetch held while the core is busy leaves '
          'the main isolate free', () async {
        await heldPrefetch();
        final beat = _Beat()..start();
        await slowOutputOpen();
        final sw = Stopwatch()..start();
        final disposed = player.dispose();
        // The synchronous part of dispose ran here: the continue of every
        // held hook comes before its first await.
        final sync = sw.elapsedMilliseconds;
        await disposed.timeout(const Duration(seconds: 10));
        expect(sync, lessThan(_maxGapMs));
        expect(beat.stop(), lessThan(_maxGapMs));
      }, timeout: const Timeout(Duration(seconds: 40)));
    });
  });
}
