// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

import '../_helpers/setter_test_helpers.dart';

/// Regression pin (behavioural patch — runs against the REAL bundled libmpv):
/// enabling the offline loudness scan mid-playback must NOT reset a
/// PROGRESSIVE waveform that is being grown from playback.
///
/// The bug: `loudness-scan-enabled = yes` used to call `mak_waveform_start`
/// unconditionally, which always bumps the generation and frees the bin
/// arrays before re-arming. For a network adaptive / non-seekable source
/// (Jellyfin/Plex transcode) the waveform is grown live by the af-tap, so the
/// restart wiped every already-accumulated bin — the envelope visibly
/// collapsed the moment the user opened the Now-Playing sheet (which
/// subscribes to `stream.loudness`). For such a source an integrated loudness
/// is impossible anyway (a live transcode cannot be rewound and scanned in
/// full), so the restart was pure loss.
///
/// The fix gates that kick: when a playback-grown PROGRESSIVE/ROLLING envelope
/// is already live the start is skipped (envelope preserved) and the scan is
/// reported `unavailable` directly.
///
/// Reproduced hermetically: a localhost HTTP server serves the 5 s sine FLAC
/// but REFUSES range requests, so the host mpv classifies it as a non-seekable
/// network stream and grows the waveform from playback — exactly the
/// transcode shape, with no external network. If the host mpv nonetheless
/// treats the source as seekable (bulk-decoded), the precondition is not met
/// and the test self-skips rather than asserting against the wrong path.
void main() {
  final fixture = '${Directory.current.path}/test/fixtures/sine_5s.flac';

  HttpServer? server;
  late String url;

  runtimeSuite(fixturePath: fixture, () {
    setUpAll(() async {
      final bytes = await File(fixture).readAsBytes();
      // Range-refusing server: always 200 with the full body and
      // `Accept-Ranges: none`, so ffmpeg's HTTP protocol reports the stream
      // non-seekable → mpv grows the waveform progressively.
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      unawaited(
        server!.forEach((HttpRequest req) async {
          final res = req.response;
          res.headers
            ..set(HttpHeaders.acceptRangesHeader, 'none')
            ..contentType = ContentType('audio', 'flac')
            ..contentLength = bytes.length;
          if (req.method != 'HEAD') res.add(bytes);
          await res.close();
        }),
      );
      url = 'http://${server!.address.address}:${server!.port}/sine_5s.flac';
    });

    tearDownAll(() async {
      await server?.close(force: true);
    });

    test('enabling loudness-scan mid-progressive does not wipe the waveform', () async {
      final player = await buildPlayer();
      final probe = await player.getRawProperty('waveform-data');
      if (probe == null) {
        markTestSkipped('libmpv has no waveform-data property.');
        await player.dispose();
        return;
      }

      final waves = <WaveformData>[];
      final waveSub = player.stream.waveform.listen(
        (w) => w == null ? null : waves.add(w),
      );

      try {
        // Arm the waveform FIRST (the bug only bites when an envelope is already
        // growing), then play so the af-tap folds pre-DSP frames into it.
        await player.open(Media(url), play: true);

        // Wait for a PROGRESSIVE envelope that is partially filled and growing —
        // the signature of "grown from playback" (a bulk decode lands fully
        // filled at once; a live/rolling one reports live==true).
        WaveformData? grown;
        var prevFilled = -1;
        final deadline = DateTime.now().add(const Duration(seconds: 20));
        while (DateTime.now().isBefore(deadline)) {
          await Future<void>.delayed(const Duration(milliseconds: 200));
          if (waves.isEmpty) continue;
          final w = waves.last;
          if (w.live) continue; // rolling axis slides — handled by its own test
          final filledCount = _filledCount(w);
          final partial = filledCount > 0 && filledCount < w.bins;
          if (partial && prevFilled >= 0 && filledCount > prevFilled) {
            grown = w;
            break;
          }
          prevFilled = filledCount;
        }

        if (grown == null) {
          markTestSkipped(
            'host mpv did not grow a PROGRESSIVE envelope for the non-range '
            'HTTP source (it may have decoded it as seekable) — the mid-'
            'progressive reset path is not exercised on this host.',
          );
          return;
        }

        // Snapshot the bins accumulated so far. A bin behind the playhead is
        // stable (folding only ever widens a bin, and playback never revisits
        // it), so these values must persist verbatim across the loudness enable.
        final snapMin = Float32List.fromList(grown.min);
        final snapMax = Float32List.fromList(grown.max);
        final snapIdx = <int>[
          for (var i = 0; i < grown.bins; i++)
            if (grown.filled[i] != 0) i,
        ];
        expect(
          snapIdx.length,
          greaterThan(5),
          reason: 'precondition: a run of bins must already be accumulated',
        );

        // THE TRIGGER: subscribe to the loudness scan → writes
        // `loudness-scan-enabled = yes`. Pre-fix this restarted the analyzer and
        // wiped the envelope above.
        final loudTerminal = player.stream.loudness
            .firstWhere(
              (s) =>
                  s != null &&
                  s.state != LoudnessScanState.scanning &&
                  s.state != LoudnessScanState.idle,
            )
            .timeout(const Duration(seconds: 12));

        // Give a (hypothetical) reset time to wipe + only-partially-refill.
        await Future<void>.delayed(const Duration(milliseconds: 700));

        final after = waves.last;
        var wiped = 0;
        var regressedValue = 0;
        for (final i in snapIdx) {
          final stillFilled = i < after.bins && after.filled[i] != 0;
          if (!stillFilled) {
            wiped++;
            continue;
          }
          // Folding may only widen a bin; it must never shrink or zero it.
          final preserved =
              after.min[i] <= snapMin[i] + 1e-6 &&
              after.max[i] >= snapMax[i] - 1e-6;
          if (!preserved) regressedValue++;
        }

        expect(
          wiped,
          0,
          reason:
              'enabling loudness-scan zeroed $wiped/${snapIdx.length} '
              'already-accumulated waveform bins — the destructive reset '
              'regressed (the envelope was wiped and only refilled ahead of '
              'the playhead)',
        );
        expect(
          regressedValue,
          0,
          reason:
              'enabling loudness-scan changed $regressedValue '
              'already-accumulated bins to non-widened values',
        );

        // Loudness must be reported honestly: a playback-grown source cannot be
        // scanned offline, so the terminal state is "unavailable" — NOT a stale
        // "scanning", and certainly not at the cost of the waveform.
        final loud = await loudTerminal;
        expect(
          loud!.state,
          LoudnessScanState.unavailable,
          reason:
              'an integrated scan is impossible for a non-rewindable '
              'progressive source; it must report unavailable',
        );
      } finally {
        await waveSub.cancel();
        await player.stop();
        await player.dispose();
      }
    }, timeout: const Timeout(Duration(seconds: 40)));
  });
}

int _filledCount(WaveformData w) {
  var n = 0;
  for (var i = 0; i < w.filled.length; i++) {
    if (w.filled[i] != 0) n++;
  }
  return n;
}
