// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'dart:async';

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

import '../_helpers/setter_test_helpers.dart';

/// End-to-end coverage for [PlayerStream.waveform], backed by the
/// `waveform-data` / `waveform-enabled` mpv properties.
///
/// On a libmpv binary without those properties every test in this
/// group is marked skipped instead of failing the suite — the wrapper
/// has no fallback path, so the absence of the analyzer is a build
/// issue, not a Dart-side regression.
void main() {
  final fixturePath = defaultFixturePath();

  setUpAll(() => initLibmpvOrSkip(fixturePath: fixturePath));

  group('Waveform', () {
    test(
      'envelope materialises within 5s of loadfile (without playing)',
      () async {
        final player = await buildPlayer();
        try {
          // Probe the analyzer property — if mpv rejects it, the binary
          // lacks the waveform support and we skip rather than fail.
          final probe = await player.getRawProperty('waveform-data');
          if (probe == null) {
            markTestSkipped('libmpv has no waveform-data property.');
            return;
          }

          final completer = Completer<WaveformData>();
          final sub = player.stream.waveform.listen((w) {
            // The analyzer now streams partial (decoding) envelopes first, which
            // legitimately carry no signal yet — wait for the settled one.
            if (w != null && !w.decoding && !completer.isCompleted) {
              completer.complete(w);
            }
          });
          try {
            await openAndWaitForLoad(player, fixturePath);
            final wave = await completer.future.timeout(
              const Duration(seconds: 5),
            );

            expect(wave.duration.inMilliseconds, greaterThan(0));
            expect(wave.bins, greaterThan(0));
            expect(wave.min.length, wave.max.length);

            // Sine fixture: the envelope must carry the signal across
            // more than half the bin axis.
            var firstSignalBin = -1;
            var lastSignalBin = -1;
            for (var i = 0; i < wave.bins; i++) {
              if (wave.max[i].abs() > 1e-4 || wave.min[i].abs() > 1e-4) {
                if (firstSignalBin < 0) firstSignalBin = i;
                lastSignalBin = i;
              }
            }
            expect(
              firstSignalBin,
              greaterThanOrEqualTo(0),
              reason: 'Envelope must carry the sine signal',
            );
            expect(
              lastSignalBin - firstSignalBin,
              greaterThan(wave.bins ~/ 2),
              reason: 'Signal must span more than half the bin axis',
            );
          } finally {
            await sub.cancel();
          }
        } finally {
          await player.dispose();
        }
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );

    test('emits null on every track change', () async {
      final player = await buildPlayer();
      try {
        final probe = await player.getRawProperty('waveform-data');
        if (probe == null) {
          markTestSkipped('libmpv has no waveform-data property.');
          return;
        }

        final events = <WaveformData?>[];
        final sub = player.stream.waveform.listen(events.add);
        try {
          await openAndWaitForLoad(player, fixturePath);
          await Future<void>.delayed(const Duration(milliseconds: 300));
          await openAndWaitForLoad(player, fixturePath);
          await Future<void>.delayed(const Duration(milliseconds: 300));
        } finally {
          await sub.cancel();
        }

        // The pipeline emits null on every track-change so a renderer
        // can clear stale data between tracks.
        expect(
          events.contains(null),
          isTrue,
          reason: 'Expected at least one null reset on track change',
        );
        // And it must eventually reach a real envelope on at least
        // one of the loads.
        expect(
          events.any((w) => w != null),
          isTrue,
          reason: 'Expected at least one settled envelope after a load',
        );
      } finally {
        await player.dispose();
      }
    }, timeout: const Timeout(Duration(seconds: 15)));

    test('listener-gated — no envelope emitted while unsubscribed', () async {
      final player = await buildPlayer();
      try {
        final probe = await player.getRawProperty('waveform-data');
        if (probe == null) {
          markTestSkipped('libmpv has no waveform-data property.');
          return;
        }

        // No subscriber → analyzer stays disabled.
        await openAndWaitForLoad(player, fixturePath);
        await Future<void>.delayed(const Duration(seconds: 1));
        final flag = await player.getRawProperty('waveform-enabled');
        expect(
          flag == 'yes',
          isFalse,
          reason: 'Analyzer must stay disabled with no listener',
        );

        // Subscribing arms the analyzer and eventually settles an
        // envelope for the already-loaded track.
        final completer = Completer<WaveformData>();
        final sub = player.stream.waveform.listen((w) {
          // The analyzer now streams partial (decoding) envelopes first, which
          // legitimately carry no signal yet — wait for the settled one.
          if (w != null && !w.decoding && !completer.isCompleted) {
            completer.complete(w);
          }
        });
        try {
          final wave = await completer.future.timeout(
            const Duration(seconds: 5),
          );
          expect(wave.bins, greaterThan(0));
        } finally {
          await sub.cancel();
        }
      } finally {
        await player.dispose();
      }
    }, timeout: const Timeout(Duration(seconds: 15)));
  });
}
