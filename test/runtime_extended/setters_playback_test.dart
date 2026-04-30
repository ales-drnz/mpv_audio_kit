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

  // Use the 3-second chapters fixture: long enough that seek tests can
  // assert past 400ms without racing mpv's EOF on a 1-second file.
  final fixturePath =
      '${Directory.current.path}/test/fixtures/with_chapters.mka';

  setUpAll(() {
    final lib = resolveLibmpv();
    if (lib == null) {
      markTestSkipped('libmpv not found');
      return;
    }
    if (!File(fixturePath).existsSync()) {
      markTestSkipped('Fixture missing');
      return;
    }
    MpvAudioKit.ensureInitialized(libmpv: lib, hotRestartCleanup: false);
  });

  group('Playback transport (play / pause / stop / seek) end-to-end', () {
    late Player player;

    setUpAll(() async {
      player = Player(
          configuration: const PlayerConfiguration(
        autoPlay: false,
        logLevel: 'no',
      ));
      await player.setRawProperty('ao', 'null');
      await player.open(Media(fixturePath), play: false);
      await player.stream.duration
          .firstWhere((d) => d.inMilliseconds > 2500)
          .timeout(const Duration(seconds: 5));
    });

    tearDownAll(() async {
      // Stop + clear before dispose: the seek tests leave the player
      // mid-playback, and an active demuxer thread can stall the
      // dispose chain when many runtime_extended files run in parallel.
      await player.stop();
      await player.clearPlaylist();
      await player.dispose();
    });

    // Order matters: do seek tests FIRST, while the player is still
    // paused on a freshly-opened file. play / pause / stop tests
    // mutate transport state and run last; the dispose chain in
    // tearDownAll then operates on a quiesced player.

    test('seek absolute updates state.position', () async {
      await player.seek(const Duration(seconds: 1));
      await Future.delayed(const Duration(milliseconds: 500));
      expect(player.state.position.inMilliseconds, greaterThan(800),
          reason: 'mpv may settle slightly off the requested 1000ms target');
    }, timeout: const Timeout(Duration(seconds: 15)));

    test('seek relative offsets from the current position', () async {
      // Anchor at 1.0s, then seek +1.0s relative → ~2.0s.
      await player.seek(const Duration(seconds: 1));
      await Future.delayed(const Duration(milliseconds: 400));
      await player.seek(const Duration(seconds: 1), relative: true);
      await Future.delayed(const Duration(milliseconds: 400));
      expect(player.state.position.inMilliseconds, greaterThan(1700));
    }, timeout: const Timeout(Duration(seconds: 15)));

    test('play / pause flip state.playing via the core-idle observer',
        () async {
      await player.play();
      await player.stream.playing
          .firstWhere((p) => p)
          .timeout(const Duration(seconds: 3));
      expect(player.state.playing, isTrue);

      await player.pause();
      await player.stream.playing
          .firstWhere((p) => !p)
          .timeout(const Duration(seconds: 3));
      expect(player.state.playing, isFalse);
    }, timeout: const Timeout(Duration(seconds: 15)));

    test('stop returns the player to an idle lifecycle', () async {
      await player.stop();
      await Future.delayed(const Duration(milliseconds: 300));
      expect(player.state.playing, isFalse);
    }, timeout: const Timeout(Duration(seconds: 15)));
  });
}
