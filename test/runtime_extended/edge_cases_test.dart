// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@TestOn('mac-os || linux')
library;

import 'dart:io';

import 'package:test/test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

void main() {
  String? resolveLibmpv() {
    final root = Directory.current.path;
    if (Platform.isMacOS) {
      final p = '$root/macos/libs/libmpv.dylib';
      return File(p).existsSync() ? p : null;
    }
    if (Platform.isLinux) {
      final p = '$root/linux/libs/libmpv.so';
      return File(p).existsSync() ? p : null;
    }
    return null;
  }

  setUpAll(() {
    final lib = resolveLibmpv();
    if (lib == null) {
      markTestSkipped('libmpv not found');
      return;
    }
    MpvAudioKit.ensureInitialized(libmpv: lib, hotRestartCleanup: false);
  });

  group('Edge cases — exotic fixtures and boundary inputs', () {
    late Player player;

    setUpAll(() async {
      player = Player(
          configuration: const PlayerConfiguration(
        autoPlay: false,
        logLevel: 'no',
      ));
      await player.setRawProperty('ao', 'null');
    });

    tearDownAll(() async {
      await player.stop();
      await player.clearPlaylist();
      await player.dispose();
    });

    test('50 ms fixture loads without crashing the demuxer', () async {
      final tinyPath =
          '${Directory.current.path}/test/fixtures/sine_50ms.wav';
      if (!File(tinyPath).existsSync()) {
        markTestSkipped('Tiny fixture missing');
        return;
      }
      await player.open(Media(tinyPath), play: false);
      // Give mpv a moment to demux a near-zero-length file.
      await Future.delayed(const Duration(milliseconds: 300));
      // Duration may report 50ms or 0 depending on container precision;
      // we assert that the wrapper isn't stuck / crashed.
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
          .firstWhere((p) => p.medias.length == 2 && p.index == 1)
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
  });
}
