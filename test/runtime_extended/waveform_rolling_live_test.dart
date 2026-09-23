// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

@TestOn('mac-os || linux || windows')
@Tags(['network'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

import '../_helpers/setter_test_helpers.dart';

/// Live ROLLING waveform — proves the "initial gap" fix end-to-end against a
/// real unknown-duration stream (the only source that drives the analyzer
/// into ROLLING state; the offline sine fixture exercises only the BULK path).
///
/// The radiomast.io "ref-*" endpoints are maintained explicitly for testing
/// and are the same streams used in `streaming_test.dart`. The group probes
/// connectivity in `setUpAll` and skips when air-gapped, so `flutter test`
/// still passes on a CI machine without internet.
///
/// What the fix guarantees, asserted below:
///   * the surfaced window is anchored at the FIRST filled bin, so
///     `filled.first != 0` — before the fix the leading bins were `0`
///     (the empty gap that rendered as a faint baseline left of 0:00);
///   * the axis is an exact integer grid: `duration == bins * 40 ms`, i.e.
///     one bin == 0.04 s with no float drift;
///   * the three per-bin arrays share one length.
void main() {
  const mp3Stream = 'https://streams.radiomast.io/ref-128k-mp3-stereo';
  const aacStream = 'https://streams.radiomast.io/ref-128k-aaclc-stereo';

  // 40 ms per ROLLING bin (MAK_WAVE_ROLL_BIN_US on the native side).
  const rollBinUs = 40000;

  bool networkAvailable = false;

  runtimeSuite(() {
    setUpAll(() async {
      // Short HEAD probe — skip the whole group if radiomast is unreachable
      // rather than burning a full timeout per test.
      try {
        final client = HttpClient()
          ..connectionTimeout = const Duration(seconds: 4);
        final req = await client.headUrl(Uri.parse(mp3Stream));
        final resp = await req.close().timeout(const Duration(seconds: 4));
        await resp.drain<void>();
        client.close();
        networkAvailable = true;
      } catch (_) {
        networkAvailable = false;
      }
    });

    /// Plays [url], arms the analyzer by subscribing, and returns the first
    /// settled ROLLING envelope carrying at least [minBins] bins.
    Future<WaveformData> firstRollingEnvelope(
      String url, {
      int minBins = 3,
      Duration timeout = const Duration(seconds: 25),
    }) async {
      final player = await buildPlayer();
      // Pre-subscribe: the listener both arms the analyzer (listener-gated
      // `waveform-enabled`) and captures the first emit without a race.
      final settled = player.stream.waveform
          .firstWhere((w) => w != null && w.live && w.bins >= minBins)
          .timeout(timeout);
      try {
        // play:true so the af-tap folds pre-DSP frames into the rolling window
        // (the envelope grows from playback, not a one-shot decode).
        await player.open(Media(url), play: true);
        return (await settled)!;
      } finally {
        await player.stop();
        await player.dispose();
      }
    }

    /// Shared assertions for the gap-trim contract.
    void expectGapTrimmed(WaveformData wave, {required String label}) {
      expect(
        wave.live,
        isTrue,
        reason: '$label: must be a ROLLING (live) window',
      );
      expect(
        wave.bins,
        greaterThan(0),
        reason: '$label: window must hold bins',
      );
      expect(
        wave.min.length,
        wave.max.length,
        reason: '$label: min/max length mismatch',
      );
      expect(
        wave.filled.length,
        wave.bins,
        reason: '$label: filled length must equal bin count',
      );

      // The headline fix: the window starts at the first FILLED bin, so the
      // leading bin is real signal, never the old empty-gap placeholder.
      expect(
        wave.filled.first,
        isNot(0),
        reason:
            '$label: leading bin must be filled — the initial gap is '
            'trimmed, not surfaced as an empty bin',
      );

      // Exact integer axis: duration == bins * 40 ms (binSecs == 0.04 s).
      expect(
        wave.duration.inMicroseconds,
        wave.bins * rollBinUs,
        reason:
            '$label: duration must equal bins * 40 ms exactly '
            '(no float drift in the rolling axis)',
      );
    }

    group('ROLLING live waveform — initial-gap trim', () {
      test('MP3 ICY stream: window anchored at first filled bin', () async {
        if (!networkAvailable) {
          markTestSkipped('Network unreachable');
          return;
        }
        final wave = await firstRollingEnvelope(mp3Stream);
        expectGapTrimmed(wave, label: 'MP3');
      }, timeout: const Timeout(Duration(seconds: 35)));

      test('AAC-LC stream: window anchored at first filled bin', () async {
        if (!networkAvailable) {
          markTestSkipped('Network unreachable');
          return;
        }
        final wave = await firstRollingEnvelope(aacStream);
        expectGapTrimmed(wave, label: 'AAC');
      }, timeout: const Timeout(Duration(seconds: 35)));
    });
  });
}
