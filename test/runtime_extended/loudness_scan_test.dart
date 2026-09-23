// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

// Offline loudness scan (`stream.loudness`): the bundled libmpv
// decodes the whole file off the playback path on load and reports the
// EBU R128 measurement. The cross-check test pins the offline integrated
// loudness against the live `ebur128` meter (an independent
// implementation of the same BS.1770 definition) playing the same file
// to the end — guarding both the native merge math and the patch across
// mpv/ffmpeg bumps.

import 'dart:io';

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

import '../_helpers/setter_test_helpers.dart';

void main() {
  late Player player;
  final fixture = '${Directory.current.path}/test/fixtures/sine_5s.flac';
  final fixtureShort =
      '${Directory.current.path}/test/fixtures/sine_440hz_1s.wav';

  setUpAll(() async {
    initLibmpvOrSkip();
    player = await buildPlayer();
  });

  tearDownAll(() => player.dispose());

  test(
    'scan delivers a ready result moments after load, without playback',
    () async {
      // The scan streams `scanning` snapshots before the terminal result, so
      // wait for the ready state specifically (not merely the first non-null).
      final scan = player.stream.loudness
          .firstWhere((s) => s?.state == LoudnessScanState.ready)
          .timeout(const Duration(seconds: 15));
      await openAndWaitForLoad(player, fixture);
      final result = (await scan)!;

      expect(
        result.state,
        LoudnessScanState.ready,
        reason: 'a local seekable file must bulk-scan',
      );
      expect(result.integrated, isNotNull);
      expect(
        result.integrated!,
        lessThan(0),
        reason: 'a sine below full scale measures negative LUFS',
      );
      expect(
        result.integrated!,
        greaterThan(-70),
        reason: 'the fixture is not silence',
      );
      expect(result.gatedBlockCount, greaterThan(0));
      expect(result.samplePeak!, greaterThan(0));
      expect(result.samplePeak!, lessThanOrEqualTo(1.0));
      // A steady sine has no inter-sample overshoot to speak of, but the
      // oversampled reading must never sit BELOW the sample peak by more
      // than interpolation error.
      expect(result.truePeak!, greaterThan(result.samplePeak! * 0.95));
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );

  test(
    'offline integrated matches the live ebur128 meter on a full pass',
    () async {
      // Offline measurement for the loaded fixture (already scanned in the
      // previous test — re-listen; the pipeline replays the cached result).
      final offline = (await player.stream.loudness
          .firstWhere((s) => s?.state == LoudnessScanState.ready)
          .timeout(const Duration(seconds: 15)))!;

      // Live measurement: ebur128 in the chain, play the file to the end.
      await player.setAudioEffects(
        const AudioEffects(
          ebur128: Ebur128Settings(enabled: true, metadata: true),
        ),
      );
      Loudness? last;
      final sub = player.stream.loudnessMeter.listen((l) => last = l);
      final done = player.stream.eofReached
          .firstWhere((v) => v)
          .timeout(const Duration(seconds: 30));
      await player.seek(Duration.zero);
      await player.play();
      await done;
      await sub.cancel();
      await player.setAudioEffects(const AudioEffects());

      expect(
        last?.integrated,
        isNotNull,
        reason: 'the live meter must have produced an integrated reading',
      );
      expect(
        offline.integrated!,
        closeTo(last!.integrated!, 0.5),
        reason:
            'offline scan and live ebur128 implement the same BS.1770 '
            'definition — a drift beyond tolerance means the native merge '
            'math (or a patched-binary regression) is wrong',
      );
    },
    timeout: const Timeout(Duration(seconds: 60)),
  );

  test('track change clears the result and rescans the new source', () async {
    final events = <LoudnessScan?>[];
    final sub = player.stream.loudness.listen(events.add);
    final fresh = player.stream.loudness
        .firstWhere((s) => s?.state == LoudnessScanState.ready)
        .timeout(const Duration(seconds: 15));
    await openAndWaitForLoad(player, fixtureShort);
    final result = await fresh;
    await sub.cancel();

    expect(
      events,
      contains(null),
      reason: 'the track-change boundary must clear the stale result',
    );
    expect(result!.integrated, isNotNull);
  }, timeout: const Timeout(Duration(seconds: 30)));
}
