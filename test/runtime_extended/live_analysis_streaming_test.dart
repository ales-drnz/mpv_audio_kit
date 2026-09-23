// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

// Live streaming of the bulk analysis pass. The waveform analyzer and the
// loudness scan ride ONE decode pass; both now surface progress WHILE it runs
// instead of only at the end:
//   - waveform-data carries state "decoding" with a partial envelope plus
//     coverage_bins / total_bins / progress;
//   - loudness-scan-data carries state "scanning" with a progress fraction.
//
// Two kinds of assertion live here. The TIMING-INDEPENDENT, load-bearing ones
// guard against regressions regardless of how fast the host decodes: the FINAL
// waveform envelope is complete, any sealed bin observed mid-decode already
// matches the final value (so the live partial is never wrong), and the FINAL
// integrated loudness still matches the live ebur128 meter within 0.5 LU. The
// partial-OBSERVATION assertions are soft (a short fixture can decode inside a
// single publish interval): they `markTestSkipped` rather than fail when the
// host outran them.

@TestOn('mac-os || linux || windows')
library;

import 'dart:async';
import 'dart:io';

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

import '../_helpers/setter_test_helpers.dart';

void main() {
  late Player player;
  final fixture = '${Directory.current.path}/test/fixtures/sine_5s.flac';

  runtimeSuite(() {
    setUpAll(() async {
      player = await buildPlayer();
    });

    tearDownAll(() => player.dispose());

    test('waveform streams a partial envelope, then a correct final one', () async {
      final probe = await player.getRawPropertyNode('waveform-data');
      if (probe == null) {
        markTestSkipped('libmpv has no waveform-data property.');
        return;
      }

      // Subscribing arms the analyzer; collect every emission.
      final seen = <WaveformData>[];
      final sub = player.stream.waveform.listen((w) {
        if (w != null) seen.add(w);
      });

      // The final bulk envelope: settled (not decoding) and fully covered.
      final finalF = player.stream.waveform
          .firstWhere(
            (w) => w != null && !w.decoding && w.filled.every((b) => b != 0),
          )
          .timeout(const Duration(seconds: 15));

      // Tight-poll the raw node in parallel — the 120 ms stream poll can miss a
      // fast decode, so this catches the "decoding" wire contract directly. An
      // awaited async loop (not a periodic Timer) leaves nothing pending after.
      final rawDecoding = <Map<Object?, Object?>>[];
      var stopPoll = false;
      Future<void> pollRaw() async {
        while (!stopPoll) {
          final node = await player.getRawPropertyNode('waveform-data');
          if (node is Map) {
            final state = node['state'];
            if (state == 'decoding') {
              rawDecoding.add(Map<Object?, Object?>.from(node));
            } else if (state == 'ready') {
              break;
            }
          }
          await Future<void>.delayed(const Duration(milliseconds: 8));
        }
      }

      final polling = pollRaw();
      await openAndWaitForLoad(player, fixture);
      final fin = (await finalF)!;
      stopPoll = true;
      await polling;
      await sub.cancel();

      // ── Load-bearing: the FINAL envelope is complete and well-formed. ──
      expect(fin.bins, greaterThan(100));
      expect(fin.min.length, fin.max.length);
      expect(fin.filled.length, fin.min.length);
      expect(
        fin.filled.every((b) => b != 0),
        isTrue,
        reason: 'a local bulk envelope is fully covered when settled',
      );
      expect(fin.decoding, isFalse);
      // The sine must span more than half the axis (final correctness, as in the
      // bulk test) — proves the live publish did not corrupt the final result.
      var first = -1, last = -1;
      for (var i = 0; i < fin.bins; i++) {
        if (fin.max[i].abs() > 1e-4 || fin.min[i].abs() > 1e-4) {
          if (first < 0) first = i;
          last = i;
        }
      }
      expect(first, greaterThanOrEqualTo(0));
      expect(last - first, greaterThan(fin.bins ~/ 2));

      // ── Soft: the wire surfaced "decoding" with the new keys. ──
      if (rawDecoding.isEmpty) {
        markTestSkipped('host decoded faster than the raw poll could observe.');
      } else {
        var lastCoverage = -1;
        for (final node in rawDecoding) {
          final cov = node['coverage_bins'];
          final tot = node['total_bins'];
          final prog = node['progress'];
          expect(cov, isA<int>());
          expect(tot, isA<int>());
          expect(prog, isA<double>());
          final c = cov as int, p = prog as double;
          expect(p, inInclusiveRange(0.0, 1.0));
          if (tot is int && tot > 0) expect(c, lessThanOrEqualTo(tot));
          // coverage is monotone non-decreasing across the decode.
          expect(c, greaterThanOrEqualTo(lastCoverage));
          lastCoverage = c;
        }
      }

      // ── Soft but high-value: any SEALED bin seen mid-decode already holds its
      // final value (filled==1 ⇒ this bin can no longer change). This is the
      // safety/correctness guarantee of the incremental publish. ──
      final partials = seen.where((w) => w.decoding).toList();
      if (partials.isEmpty) {
        markTestSkipped(
          'no streamed partial observed on this host (fast decode)',
        );
      } else {
        for (final p in partials) {
          final n = p.min.length < fin.min.length
              ? p.min.length
              : fin.min.length;
          for (var i = 0; i < n; i++) {
            if (p.filled[i] != 0) {
              expect(
                p.min[i],
                fin.min[i],
                reason: 'sealed bin $i min must equal the final value',
              );
              expect(
                p.max[i],
                fin.max[i],
                reason: 'sealed bin $i max must equal the final value',
              );
            }
          }
          final f = p.decodeFraction;
          if (f != null) expect(f, inInclusiveRange(0.0, 1.0));
        }
      }
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('loudness emits scanning progress, then an exact integrated', () async {
      final probe = await player.getRawPropertyNode('loudness-scan-data');
      if (probe == null) {
        markTestSkipped('libmpv has no loudness-scan-data property.');
        return;
      }

      final fracs = <double>[];
      var sawScanning = false;
      final sub = player.stream.loudness.listen((s) {
        if (s?.state == LoudnessScanState.scanning) {
          sawScanning = true;
          if (s?.progress != null) fracs.add(s!.progress!);
        }
      });

      final readyF = player.stream.loudness
          .firstWhere((s) => s?.state == LoudnessScanState.ready)
          .timeout(const Duration(seconds: 15));
      await openAndWaitForLoad(player, fixture);
      final offline = (await readyF)!;
      await sub.cancel();

      // ── Load-bearing: a terminal ready with a real measurement + progress 1. ──
      expect(offline.integrated, isNotNull);
      expect(offline.progress, 1.0);

      // ── Soft: scanning snapshots, if observed, carry a monotone [0,1] fraction.
      if (!sawScanning && fracs.isEmpty) {
        markTestSkipped('host scanned faster than the poll could observe.');
      } else {
        for (final f in fracs) {
          expect(f, inInclusiveRange(0.0, 1.0));
        }
        for (var i = 1; i < fracs.length; i++) {
          expect(
            fracs[i],
            greaterThanOrEqualTo(fracs[i - 1]),
            reason: 'scan progress must be monotone non-decreasing',
          );
        }
      }

      // ── Load-bearing regression guard: the FINAL integrated still matches the
      // independent live ebur128 meter on a full pass (the streaming change must
      // not perturb the merge math). ──
      await player.setAudioEffects(
        const AudioEffects(
          ebur128: Ebur128Settings(enabled: true, metadata: true),
        ),
      );
      Loudness? live;
      final meter = player.stream.loudnessMeter.listen((l) => live = l);
      final eof = player.stream.eofReached
          .firstWhere((v) => v)
          .timeout(const Duration(seconds: 30));
      await player.seek(Duration.zero);
      await player.play();
      await eof;
      await meter.cancel();
      await player.setAudioEffects(const AudioEffects());

      expect(live?.integrated, isNotNull);
      expect(
        offline.integrated!,
        closeTo(live!.integrated!, 0.5),
        reason:
            'offline scan and live ebur128 implement the same BS.1770 '
            'definition — drift beyond tolerance means the live-streaming '
            'change perturbed the final merge',
      );
    }, timeout: const Timeout(Duration(seconds: 60)));
  });
}
