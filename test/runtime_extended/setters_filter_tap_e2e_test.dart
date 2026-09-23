// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'dart:async';

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

  setUpAll(() => initLibmpvOrSkip(fixturePath: fixturePath));

  group('Filter tap end-to-end', () {
    test(
      'post-filter tap captures non-silent PCM after a filter is enabled',
      () async {
        final player = await buildPlayer();
        try {
          // Probe the patched property first.
          final probe = await player.getRawProperty('audio-tap-frames');
          if (probe == null) {
            markTestSkipped(
              'libmpv has no audio-tap-frames property '
              '(patch_filter_label_tap.py not applied to this binary).',
            );
            return;
          }

          // Enable a real filter. `equalizer` is in the audio-only build
          // and forwards every frame untouched at gain 0 — perfect for
          // a "is the tap actually wired" probe.
          await player.setAudioEffects(
            const AudioEffects(equalizer: EqualizerSettings(enabled: true)),
          );

          await openAndWaitForLoad(player, fixturePath);

          // Speed up the FFT pipeline cadence so PCM flows promptly. The
          // tap pipeline polls on its own timer (33 ms), so this only
          // affects neighbouring streams.
          await player.setSpectrum(
            const SpectrumSettings(emitInterval: Duration(milliseconds: 16)),
          );

          final completer = Completer<PcmFrame>();
          final sub = player.stream
              .tap(AudioEffect.equalizer, side: TapSide.post)
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

    test('refcount: cancelling all subscribers clears analyzer-taps', () async {
      final player = await buildPlayer();
      try {
        final probe = await player.getRawProperty('audio-tap-frames');
        if (probe == null) {
          markTestSkipped('libmpv has no audio-tap-frames property.');
          return;
        }

        // Initial state: no taps active.
        var active = await player.getRawProperty('analyzer-taps');
        expect(active ?? '', isEmpty);

        // First subscriber arms the tap.
        final s1 = player.stream
            .tap(AudioEffect.equalizer, side: TapSide.pre)
            .listen((_) {});
        // Give the pipeline a microtask tick to write the property.
        await Future<void>.delayed(const Duration(milliseconds: 50));
        active = await player.getRawProperty('analyzer-taps');
        // Pipeline prepends the `lavfi-` prefix so the C-side hook —
        // which sees `u->name = "lavfi-equalizer"` for any libavfilter
        // user filter — finds the slot.
        expect(active, contains('lavfi-equalizer'));

        // Second subscriber on the same filter: refcount, not a
        // duplicate write.
        final s2 = player.stream
            .tap(AudioEffect.equalizer, side: TapSide.post)
            .listen((_) {});
        await Future<void>.delayed(const Duration(milliseconds: 50));
        active = await player.getRawProperty('analyzer-taps');
        expect(active, 'lavfi-equalizer');

        // Cancel one — analyzer-taps stays the same (other still up).
        await s1.cancel();
        await Future<void>.delayed(const Duration(milliseconds: 50));
        active = await player.getRawProperty('analyzer-taps');
        expect(active, 'lavfi-equalizer');

        // Cancel the last — analyzer-taps must be cleared.
        await s2.cancel();
        await Future<void>.delayed(const Duration(milliseconds: 50));
        active = await player.getRawProperty('analyzer-taps');
        expect(active ?? '', isEmpty);
      } finally {
        await player.dispose();
      }
    }, timeout: const Timeout(Duration(seconds: 10)));
  });
}
