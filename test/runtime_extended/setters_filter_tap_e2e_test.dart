// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'dart:async';
import 'dart:io';

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

import '../_helpers/setter_test_helpers.dart';

/// End-to-end coverage for [PlayerStream.tap], backed by the
/// `analyzer-taps` and `audio-tap-frames` mpv properties added by
/// `patch_filter_label_tap.py`.
///
/// On a libmpv binary without the patch the properties don't exist;
/// the test set is marked skipped instead of failing the suite.
void main() {
  final fixturePath = defaultFixturePath();

  runtimeSuite(fixturePath: fixturePath, () {
    group('Filter tap end-to-end', () {
      test(
        'post-filter tap captures non-silent PCM after a filter is enabled',
        () async {
          final player = await buildPlayer();
          try {
            // Probe the patched property first.
            final probe = await player.getRawProperty('audio-tap-frames');
            if (probe == null) {
              skipMissing(
                'libmpv has no audio-tap-frames property '
                '(patch_filter_label_tap.py not applied to this binary).',
              );
              return;
            }

            // Enable a real filter. `equalizer` is in the audio-only build
            // and forwards every frame untouched at gain 0 — perfect for
            // a "is the tap actually wired" probe.
            await player.setAudioEffects(const [EqualizerEffect()]);

            await openAndWaitForLoad(player, fixturePath);

            // Speed up the FFT pipeline cadence so PCM flows promptly. The
            // tap pipeline polls on its own timer (33 ms), so this only
            // affects neighbouring streams.
            player.setSpectrum(
              const SpectrumSettings(emitInterval: Duration(milliseconds: 16)),
            );

            final completer = Completer<PcmFrame>();
            final sub = player.stream
                .tap(AudioFilter.equalizer, side: TapSide.post)
                .listen((f) {
                  if (!completer.isCompleted) completer.complete(f);
                });
            try {
              await player.play();
              final frame = await completer.future.timeout(
                const Duration(seconds: 3),
              );
              expect(frame.samples.length, greaterThan(0));
              expect(frame.sampleRate, greaterThan(0));
              expect(frame.channels, greaterThanOrEqualTo(1));
              // Sine-440 fixture: at least one sample must carry signal.
              final hasSignal = frame.samples.any((s) => s.abs() > 1e-4);
              expect(
                hasSignal,
                isTrue,
                reason: 'Post-tap should expose the actual filtered PCM',
              );
            } finally {
              await sub.cancel();
              await player.pause();
            }
          } finally {
            await player.dispose();
          }
        },
        timeout: const Timeout(Duration(seconds: 10)),
      );

      test(
        'refcount: cancelling all subscribers clears analyzer-taps',
        () async {
          final player = await buildPlayer();
          try {
            final probe = await player.getRawProperty('audio-tap-frames');
            if (probe == null) {
              skipMissing('libmpv has no audio-tap-frames property.');
              return;
            }

            // Initial state: no taps active.
            var active = await player.getRawProperty('analyzer-taps');
            expect(active ?? '', isEmpty);

            // First subscriber arms the tap.
            final s1 = player.stream
                .tap(AudioFilter.equalizer, side: TapSide.pre)
                .listen((_) {});
            // The native hook matches the stage's chain label, which the
            // first equalizer in the list carries as `aek_equalizer_0`.
            await waitUntil(
              () async => (await player.getRawProperty('analyzer-taps') ?? '')
                  .contains('aek_equalizer_0'),
            );

            // Second subscriber on the same filter: refcount, not a
            // duplicate write.
            final s2 = player.stream
                .tap(AudioFilter.equalizer, side: TapSide.post)
                .listen((_) {});
            // A window, not a wait: a duplicate write would land in it.
            await Future<void>.delayed(const Duration(milliseconds: 50));
            active = await player.getRawProperty('analyzer-taps');
            expect(active, 'aek_equalizer_0');

            // Cancel one — analyzer-taps stays the same (other still up).
            await s1.cancel();
            await Future<void>.delayed(const Duration(milliseconds: 50));
            active = await player.getRawProperty('analyzer-taps');
            expect(active, 'aek_equalizer_0');

            // Cancel the last — analyzer-taps must be cleared.
            await s2.cancel();
            await waitUntil(
              () async =>
                  (await player.getRawProperty('analyzer-taps') ?? '').isEmpty,
            );
          } finally {
            await player.dispose();
          }
        },
        timeout: const Timeout(Duration(seconds: 10)),
      );

      test(
        'a second player taps a stage and goes, the first keeps its tap',
        () async {
          // analyzer-taps is one list per process, replaced by each write.
          final a = await buildPlayer();
          final b = await buildPlayer();
          var bGone = false;
          try {
            final probe = await a.getRawProperty('audio-tap-frames');
            if (probe == null) {
              skipMissing('libmpv has no audio-tap-frames property.');
              return;
            }
            final flac = '${Directory.current.path}/test/fixtures/sine_5s.flac';
            await a.setAudioEffects(const [EqualizerEffect()]);
            await b.setAudioEffects(const [BassEffect()]);
            await a.setRawProperty('loop-file', 'inf');
            await openAndWaitForLoad(a, flac);
            var frames = 0;
            final eq = a.stream
                .tap(AudioFilter.equalizer, side: TapSide.pre)
                .listen((_) => frames++);
            try {
              await a.play();
              Future<void> flowing(String reason) {
                final from = frames;
                return waitUntil(() => frames > from + 2, reason: reason);
              }

              Future<void> listed(String csv) => waitUntil(
                () async => await a.getRawProperty('analyzer-taps') == csv,
                reason: 'analyzer-taps is not $csv',
              );

              await flowing('the first player taps nothing');
              final bass = b.stream
                  .tap(AudioFilter.bass, side: TapSide.post)
                  .listen((_) {});
              await Future<void>.delayed(const Duration(milliseconds: 100));
              await flowing('the tap stopped when the second player tapped');
              await listed('aek_equalizer_0,aek_bass_0');

              // The second player goes with its listener attached.
              await b.dispose();
              bGone = true;
              await bass.cancel();
              await Future<void>.delayed(const Duration(milliseconds: 100));
              await flowing('the tap stopped when the second player went');
              await listed('aek_equalizer_0');
            } finally {
              await eq.cancel();
            }
            await waitUntil(
              () async =>
                  (await a.getRawProperty('analyzer-taps') ?? '').isEmpty,
            );
          } finally {
            if (!bGone) await b.dispose();
            await a.dispose();
          }
        },
        timeout: const Timeout(Duration(seconds: 20)),
      );
    });
  });
}
