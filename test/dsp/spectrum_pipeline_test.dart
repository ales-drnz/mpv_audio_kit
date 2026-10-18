// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

// The spectrum poll against a fake mpv, with no libmpv loaded.

import 'dart:async';
import 'dart:typed_data';

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:mpv_audio_kit/src/dsp/spectrum_pipeline.dart';
import 'package:test/test.dart';

void main() {
  group('spectrum', () {
    test('an emit interval under 8 ms is polled every 8 ms', () async {
      var gets = 0;
      final p = SpectrumPipeline(
        asyncGet: (name, format) async {
          gets++;
          return (-10, null);
        },
      )..setSettings(const SpectrumSettings(emitInterval: Duration.zero));
      final sub = p.fftStream.listen((_) {});
      await Future<void>.delayed(const Duration(milliseconds: 160));
      expect(gets, lessThanOrEqualTo(22), reason: '$gets reads in 160 ms');
      await sub.cancel();
      await p.dispose();
    });
  });

  group('paused', () {
    // Paused, the output writes nothing: every poll reads the same frame.
    SpectrumPipeline paused() =>
        SpectrumPipeline(
          asyncGet: (name, format) async => (
            0,
            {
              'sample_rate': 48000,
              'channels': 2,
              'pts_ns': 5000000000,
              'samples': Uint8List(4096 * 2 * 4),
            },
          ),
        )..setSettings(
          const SpectrumSettings(emitInterval: Duration(milliseconds: 10)),
        );
    Future<void> polls() =>
        Future<void>.delayed(const Duration(milliseconds: 60));

    test('a listener that comes back gets the current frame', () async {
      final p = paused();
      var frames = 0;
      var sub = p.fftStream.listen((_) => frames++);
      await polls();
      expect(frames, 1);
      await sub.cancel();
      sub = p.fftStream.listen((_) => frames++);
      await polls();
      expect(frames, 2);
      await sub.cancel();
      await p.dispose();
    });

    test('an fft listener after a pcm one gets the current frame', () async {
      final p = paused();
      var pcm = 0;
      var fft = 0;
      final pcmSub = p.pcmStream.listen((_) => pcm++);
      await polls();
      expect(pcm, 1);
      final fftSub = p.fftStream.listen((_) => fft++);
      await polls();
      expect(fft, 1);
      expect(pcm, 1, reason: 'the pcm listener has this frame already');
      await fftSub.cancel();
      await pcmSub.cancel();
      await p.dispose();
    });
  });
  group('core idle', () {
    // F41: paused or stopped, the output writes nothing, so the poll reads
    // nothing new. It stops while the core is idle and starts again after.
    test('no read while the core is idle, the poll comes back after', () async {
      var gets = 0;
      final p =
          SpectrumPipeline(
            asyncGet: (name, format) async {
              gets++;
              return (-10, null);
            },
          )..setSettings(
            const SpectrumSettings(emitInterval: Duration(milliseconds: 10)),
          );
      final sub = p.fftStream.listen((_) {});
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(gets, greaterThan(2), reason: 'it polls while playing');
      p.setIdle(true);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      gets = 0;
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(gets, 0, reason: 'idle, it read $gets times');
      p.setIdle(false);
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(gets, greaterThan(2), reason: 'it polls again');
      await sub.cancel();
      await p.dispose();
    });

    test(
      'a listener that comes while idle gets the current frame once',
      () async {
        var gets = 0;
        final p =
            SpectrumPipeline(
              asyncGet: (name, format) async {
                gets++;
                return (
                  0,
                  {
                    'sample_rate': 48000,
                    'channels': 2,
                    'pts_ns': 5000000000,
                    'samples': Uint8List(4096 * 2 * 4),
                  },
                );
              },
            )..setSettings(
              const SpectrumSettings(emitInterval: Duration(milliseconds: 10)),
            );
        p.setIdle(true);
        var frames = 0;
        final sub = p.fftStream.listen((_) => frames++);
        await Future<void>.delayed(const Duration(milliseconds: 100));
        expect(frames, 1);
        expect(gets, 1, reason: 'one read for the new listener, then none');
        await sub.cancel();
        await p.dispose();
      },
    );
  });
}
