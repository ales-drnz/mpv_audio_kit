// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'dart:io';

import 'package:test/test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import '../_helpers/setter_test_helpers.dart';

void main() {
  setUpAll(() => initLibmpvOrSkip());

  group('Edge cases — exotic fixtures and boundary inputs', () {
    late Player player;

    setUpAll(() async {
      player = await buildPlayer();
    });

    tearDownAll(() async {
      await player.stop();
      await player.clearPlaylist();
      await player.dispose();
    });

    test('50 ms fixture loads without crashing the demuxer', () async {
      final tinyPath = '${Directory.current.path}/test/fixtures/sine_50ms.wav';
      if (!File(tinyPath).existsSync()) {
        markTestSkipped('Tiny fixture missing');
        return;
      }
      await player.open(Media(tinyPath), play: false);
      // Wait for the duration observer to settle on the demuxed value
      // rather than gambling on a fixed delay. Some containers report 0
      // for a 50 ms fixture (precision floor), some report exactly 50 ms;
      // either is fine — what matters is the wrapper isn't stuck. We
      // bound on the file-loaded signal rather than duration to handle
      // the 0-duration case.
      await player.stream.fileFormat
          .firstWhere((fmt) => fmt.isNotEmpty)
          .timeout(const Duration(seconds: 5));
      expect(player.state.duration.inMilliseconds, lessThan(200));
    }, timeout: const Timeout(Duration(seconds: 15)));

    test('88.2 kHz sample rate fixture decodes with correct audio-params',
        () async {
      final exoticPath =
          '${Directory.current.path}/test/fixtures/sine_88200hz.flac';
      if (!File(exoticPath).existsSync()) {
        markTestSkipped('88.2kHz fixture missing');
        return;
      }
      await player.open(Media(exoticPath), play: false);
      // Wait for the 88.2 kHz value specifically — the previous test
      // may have left a cached sampleRate from a different fixture,
      // so `!= null` would match the stale value before the new
      // file's audio-params observer fires.
      final params = await player.stream.audioParams
          .firstWhere((p) => p.sampleRate == 88200)
          .timeout(const Duration(seconds: 5));
      expect(params.sampleRate, 88200,
          reason: 'fixture is encoded at 88.2 kHz; '
              'NODE_MAP int64 must preserve the value');
    }, timeout: const Timeout(Duration(seconds: 15)));

    test('openAll([]) is a no-op (does not throw)', () async {
      // Empty playlist passed to openAll: documented as a no-op (returns
      // without issuing loadfile). State must not change.
      final initialPlaylist = player.state.playlist;
      await player.openAll(const <Media>[], play: false);
      expect(player.state.playlist, initialPlaylist,
          reason: 'empty list must not mutate the playlist');
    }, timeout: const Timeout(Duration(seconds: 5)));

    test('openAll(index out-of-range) clamps to last entry', () async {
      final fixturePath =
          '${Directory.current.path}/test/fixtures/sine_440hz_1s.wav';
      if (!File(fixturePath).existsSync()) {
        markTestSkipped('Fixture missing');
        return;
      }
      // 2 items, request index 99 — wrapper documents that this clamps
      // to medias.length - 1 (= 1) rather than no-op like raw mpv.
      await player.openAll(
        [Media(fixturePath), Media(fixturePath)],
        play: false,
        index: 99,
      );
      // Wait for the clamped state (length=2, index=1) in a single
      // firstWhere — the openAll path may emit the clamped index in
      // the same observer event as the playlist length change, so
      // chaining two waits would race.
      await player.stream.playlist
          .firstWhere((p) => p.items.length == 2 && p.index == 1)
          .timeout(const Duration(seconds: 5));
      expect(player.state.playlist.index, 1);
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('rapid sequential setVolume calls converge to the last value',
        () async {
      // Stress: 50 sequential setters fired without await between each.
      // The optimistic state update is synchronous, so the last call
      // wins on state.volume; libmpv's observer dedups intermediate
      // values and emits only the final settled volume.
      final futures = <Future<void>>[];
      for (var i = 0; i < 50; i++) {
        futures.add(player.setVolume(20.0 + i.toDouble()));
      }
      await Future.wait(futures);
      expect(player.state.volume, 69.0,
          reason: 'last setVolume(20 + 49 = 69) wins');
    }, timeout: const Timeout(Duration(seconds: 15)));

    test(
        'concurrent open() calls — last one wins (replace aborts the '
        'in-flight load)', () async {
      // Two open() calls fired without await between them. mpv processes
      // commands in arrival order on a single thread and each open()
      // issues a (set pause, loadfile replace) pair atomically; the
      // *last* pair wins because `replace` aborts any in-flight load.
      // We use two fixtures with distinct sample rates so the
      // audio-params observer emits an unambiguous "B has settled" value.
      final fixA = '${Directory.current.path}/test/fixtures/sine_440hz_1s.wav';
      final fixB = '${Directory.current.path}/test/fixtures/sine_88200hz.flac';
      if (!File(fixA).existsSync() || !File(fixB).existsSync()) {
        markTestSkipped('Fixtures missing');
        return;
      }

      final futureA = player.open(Media(fixA), play: false);
      final futureB = player.open(Media(fixB), play: false);
      await Future.wait([futureA, futureB]);

      final params = await player.stream.audioParams
          .firstWhere((p) => p.sampleRate == 88200)
          .timeout(const Duration(seconds: 5));
      expect(params.sampleRate, 88200,
          reason: 'open(B) was issued after open(A) without await between '
              "them; replace must abort A's in-flight load and the "
              "audio-params observer must settle on B's 88.2 kHz value");
    }, timeout: const Timeout(Duration(seconds: 30)));

    // ── Numeric boundary contracts ─────────────────────────────────────
    //
    // mpv applies its own M_RANGE clamp on the way in; the wrapper
    // optimistically writes the *requested* value to PlayerState before
    // the observer event arrives. The observer then emits the clamped
    // value, and state catches up. These tests document that contract:
    // the optimistic value is what the consumer last set, and the
    // observed value is what mpv accepted. Both surfaces are valid; UI
    // widgets bound to the stream always converge on the clamped value.
    test(
        'setVolume above 100 retains the optimistic value (mpv clamps to '
        'volume-max in its own time)', () async {
      await player.setVolume(150.0);
      expect(player.state.volume, 150.0,
          reason: 'wrapper writes the requested value optimistically; mpv '
              'clamps to volume-max (130 by default) on its side');
    }, timeout: const Timeout(Duration(seconds: 5)));

    test('setRate at the M_RANGE boundaries passes through', () async {
      // mpv's M_RANGE for speed is (0.01, 100.0). Values inside the
      // range pass through unchanged.
      await player.setRate(0.01);
      expect(player.state.rate, 0.01);

      await player.setRate(100.0);
      expect(player.state.rate, 100.0);

      // Restore a normal rate so subsequent tests aren't disturbed.
      await player.setRate(1.0);
    }, timeout: const Timeout(Duration(seconds: 5)));

    test(
        'setRate above 100.0 throws MpvException (mpv hard-rejects the '
        'out-of-range write; state stays at the prior value)', () async {
      // 0.1.0 contract: typed setters surface mpv rejections via
      // MpvException instead of swallowing the rc and leaving the
      // optimistic state desynced. The wrapper writes nothing to state
      // when mpv rejects, so the prior `1.0` from the previous test
      // survives.
      final priorRate = player.state.rate;
      await expectLater(
        player.setRate(150.0),
        throwsA(isA<MpvException>().having((e) => e.name, 'name', 'speed')),
      );
      expect(player.state.rate, priorRate,
          reason: 'optimistic state must not advance past a rejected write');
    }, timeout: const Timeout(Duration(seconds: 5)));

    test(
        'setRate below 0.01 throws MpvException (mpv hard-rejects sub-0.01 '
        'speeds; state stays at the prior value)', () async {
      final priorRate = player.state.rate;
      await expectLater(
        player.setRate(-1.0),
        throwsA(isA<MpvException>().having((e) => e.name, 'name', 'speed')),
      );
      expect(player.state.rate, priorRate,
          reason: 'optimistic state must not advance past a rejected write');
    }, timeout: const Timeout(Duration(seconds: 5)));

    test('setDemuxerMaxBytes preserves sub-MiB precision (no MiB rounding)',
        () async {
      // 100 MiB + 1 byte. Pre-fix the wrapper truncated to 100 MiB and
      // state diverged from mpv's actual cap. The byte-precise contract
      // forwards the exact int.
      const bytes = 100 * 1024 * 1024 + 1;
      await player.setDemuxerMaxBytes(bytes);
      expect(player.state.demuxerMaxBytes, bytes);

      // Restore to default so subsequent tests aren't disturbed.
      await player.setDemuxerMaxBytes(150 * 1024 * 1024);
    }, timeout: const Timeout(Duration(seconds: 5)));

    test('setAbLoopCount rejects negative ints', () {
      // null / non-negative int are valid; negative values are an error
      // because mpv's `--ab-loop-count` accepts only `inf` (encoded as
      // null) or `M_RANGE(0, INT_MAX)`.
      expect(() => player.setAbLoopCount(-1), throwsArgumentError);
    });
  });
}
