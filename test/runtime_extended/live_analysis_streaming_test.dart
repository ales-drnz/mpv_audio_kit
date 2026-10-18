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
// Every assertion here is load-bearing. The streaming ones run on a long
// local WAV: a 5 s fixture decodes inside one publish interval (100 ms) on a
// fast host and shows no partial at all. With both analyses on, the shared
// pass over the long file lasts several intervals, so partials are always
// there to check: any SEALED bin observed mid-decode already matches the
// final value (the live partial is never wrong). The FINAL integrated
// loudness is still compared with the live ebur128 meter on the 5 s fixture,
// which has to play to its end.

@TestOn('mac-os || linux || windows')
library;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

import '../_helpers/long_wav.dart';
import '../_helpers/setter_test_helpers.dart';

/// One envelope seen while the decode was running: [filled] marks the
/// sealed bins.
typedef _Partial = ({Float32List min, Float32List max, Uint8List filled});

/// The float bins of a byte value of `waveform-data`.
Float32List _floats(Object? bytes) =>
    Uint8List.fromList(bytes! as Uint8List).buffer.asFloat32List();

void main() {
  final fixture = '${Directory.current.path}/test/fixtures/sine_5s.flac';
  late Directory tmp;
  late String longFile;

  analysisSuite(() {
    setUpAll(() async {
      tmp = await Directory.systemTemp.createTemp('mak_live_analysis_');
      longFile = '${tmp.path}/long.wav';
      await File(longFile).writeAsBytes(longWav(600));
    });

    tearDownAll(() async {
      if (tmp.existsSync()) await tmp.delete(recursive: true);
    });

    test(
      'waveform streams a partial envelope, then a correct final one',
      () async {
        final player = await buildPlayer();
        addTearDown(player.dispose);

        // Subscribing arms the analyzer; collect every emission. The loudness
        // scan rides the same pass and slows it to several publish intervals.
        final seen = <WaveformData>[];
        final sub = player.stream.waveform.listen((w) {
          if (w != null) seen.add(w);
        });
        final scan = player.stream.loudnessScan.listen((_) {});

        // The final bulk envelope: settled (not decoding) and fully covered.
        final finalF = player.stream.waveform
            .firstWhere(
              (w) => w != null && !w.decoding && w.filled.every((b) => b != 0),
            )
            .timeout(const Duration(seconds: 60));

        // Tight-poll the raw node in parallel: the 120 ms stream poll sees only
        // some of the 100 ms publishes, this one sees each of them. An awaited
        // async loop (not a periodic Timer) leaves nothing pending after.
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
        await openAndWaitForLoad(player, longFile);
        final fin = (await finalF)!;
        stopPoll = true;
        await polling;
        await sub.cancel();
        await scan.cancel();

        // ── The FINAL envelope is complete and well-formed. ──
        expect(fin.bins, greaterThan(100));
        expect(fin.min.length, fin.max.length);
        expect(fin.filled.length, fin.min.length);
        expect(
          fin.filled.every((b) => b != 0),
          isTrue,
          reason: 'a local bulk envelope is fully covered when settled',
        );
        expect(fin.decoding, isFalse);
        // The tone spans the whole axis and its level rises: proves the live
        // publish did not corrupt or reorder the final result.
        var first = -1, last = -1;
        for (var i = 0; i < fin.bins; i++) {
          if (fin.max[i].abs() > 1e-4 || fin.min[i].abs() > 1e-4) {
            if (first < 0) first = i;
            last = i;
          }
        }
        expect(first, greaterThanOrEqualTo(0));
        expect(last - first, greaterThan(fin.bins ~/ 2));
        expect(fin.max.last, greaterThan(fin.max.first * 4));

        // ── The wire surfaced "decoding" with the new keys. ──
        expect(
          rawDecoding,
          isNotEmpty,
          reason: 'the long file decodes over several publish intervals',
        );
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

        // ── Any SEALED bin seen mid-decode already holds its final value
        // (filled==1 ⇒ this bin can no longer change). This is the
        // safety/correctness guarantee of the incremental publish. The level
        // rises inside every bin, so a bin published before its decode ended
        // holds a smaller peak than the final one. ──
        final partials = <_Partial>[
          // Before the first publish the node holds no bins yet.
          for (final node in rawDecoding)
            if (node['filled'] case final Uint8List f when f.isNotEmpty)
              (min: _floats(node['min']), max: _floats(node['max']), filled: f),
          for (final w in seen.where((w) => w.decoding))
            (min: w.min, max: w.max, filled: w.filled),
        ];
        for (final w in seen.where((w) => w.decoding)) {
          final f = w.decodeFraction;
          if (f != null) expect(f, inInclusiveRange(0.0, 1.0));
        }
        expect(
          partials.any(
            (p) => p.filled.any((b) => b != 0) && p.filled.any((b) => b == 0),
          ),
          isTrue,
          reason:
              'a partial with sealed and open bins is published while the '
              'long file decodes',
        );
        var compared = 0;
        for (final p in partials) {
          expect(p.min.length, fin.min.length);
          expect(p.filled.length, fin.min.length);
          for (var i = 0; i < p.filled.length; i++) {
            if (p.filled[i] == 0) continue;
            compared++;
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
        // ignore: avoid_print
        print(
          '[live analysis] partials: ${partials.length} '
          '(streamed ${seen.where((w) => w.decoding).length}), '
          'sealed bins compared: $compared',
        );
        expect(compared, greaterThan(0));
      },
      timeout: const Timeout(Duration(seconds: 90)),
    );

    test('loudness emits scanning progress, then a terminal ready', () async {
      final player = await buildPlayer();
      addTearDown(player.dispose);

      final fracs = <double>[];
      var sawScanning = false;
      final sub = player.stream.loudnessScan.listen((s) {
        if (s?.state == LoudnessScanState.scanning) {
          sawScanning = true;
          if (s?.progress != null) fracs.add(s!.progress!);
        }
      });

      final readyF = player.stream.loudnessScan
          .firstWhere((s) => s?.state == LoudnessScanState.ready)
          .timeout(const Duration(seconds: 60));
      await openAndWaitForLoad(player, longFile);
      final offline = (await readyF)!;
      await sub.cancel();

      // ── A terminal ready with a real measurement + progress 1. ──
      expect(offline.integrated, isNotNull);
      expect(offline.progress, 1.0);

      // ── Scanning snapshots carry a monotone [0,1] fraction. ──
      expect(
        sawScanning,
        isTrue,
        reason: 'the long file is still scanning after it loads',
      );
      expect(fracs, isNotEmpty);
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
    }, timeout: const Timeout(Duration(seconds: 90)));

    test('the final integrated matches the live ebur128 meter', () async {
      final player = await buildPlayer();
      addTearDown(player.dispose);

      final readyF = player.stream.loudnessScan
          .firstWhere((s) => s?.state == LoudnessScanState.ready)
          .timeout(const Duration(seconds: 15));
      await openAndWaitForLoad(player, fixture);
      final offline = (await readyF)!;
      expect(offline.integrated, isNotNull);

      // Regression guard: the FINAL integrated still matches the
      // independent live ebur128 meter on a full pass (the streaming change
      // must not perturb the merge math).
      await player.setAudioEffects(const [Ebur128Effect(metadata: true)]);
      Loudness? live;
      final meter = player.stream.loudnessMeter.listen((l) => live = l);
      final eof = player.stream.eofReached
          .firstWhere((v) => v)
          .timeout(const Duration(seconds: 30));
      await player.seek(Duration.zero);
      await player.play();
      await eof;
      await meter.cancel();
      await player.setAudioEffects(const []);

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
  }, fixturePath: fixture);
}
