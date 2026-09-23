// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// Reentrancy contract for rapid back-to-back `open()` calls when the two
// URIs resolve with different latency. `open()` documents that "the last
// (pause, loadfile) pair wins", but the pair is only issued AFTER
// `resolveUri` completes — and an `asset://` URI does real I/O
// (rootBundle load + temp-file write) while a plain filesystem path
// resolves in one microtask. So `open(A: asset://…)` immediately followed
// by `open(B: /plain/path)` issues B's loadfile FIRST and A's LATER:
// A — the SUPERSEDED request — ends up as the loaded file.
//
// This needs a real Flutter asset bundle, which only the test_app
// integration suite has (the package's host suite bundles no audio
// assets) — hence this lives here and not in `test/`.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

import '_helpers/asset_fixture.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    MpvAudioKit.ensureInitialized(hotRestartCleanup: false);
  });

  group('open() ordering across mixed-latency URI resolution', () {
    late Player player;

    setUp(() async {
      player = Player(
        configuration: const PlayerConfiguration(logLevel: LogLevel.off),
      );
      await player.setRawProperty('ao', 'null');
    });

    tearDown(() async {
      await player.stop();
      await player.dispose();
    });

    testWidgets('open(asset://A) immediately followed by open(plain B) — '
        'B (the last request) must be the loaded file', (_) async {
      // A: asset:// scheme — resolveUri does rootBundle.load + temp-file
      // write before the loadfile can be issued.
      const assetUriA = 'asset://assets/fixtures/with_chapters.mka';
      // B: plain filesystem path — resolveUri is pass-through.
      final plainPathB = await materializeFixture('sine_88200hz.flac');

      // Pre-subscribe BEFORE acting (CLAUDE.md): anchor "a file is
      // loaded" on PLAYBACK_RESTART, which fires once per loadfile.
      final firstLoad = Completer<void>();
      final sub = player.stream.seekCompleted.listen((_) {
        if (!firstLoad.isCompleted) firstLoad.complete();
      });

      try {
        // Same synchronous turn — do NOT await the first open. B is the
        // caller's LAST request, so B must win regardless of how long
        // A's asset materialisation takes.
        final openA = player.open(const Media(assetUriA), play: false);
        final openB = player.open(Media(plainPathB), play: false);
        await openA;
        await openB;

        await firstLoad.future.timeout(const Duration(seconds: 10));
        // Settling window: with the bug, A's loadfile lands AFTER B's and
        // replaces it — give that late replace time to demux before
        // reading the final path.
        await Future<void>.delayed(const Duration(seconds: 2));

        expect(
          player.state.path,
          plainPathB,
          reason:
              'open(B) was issued last, so B must be the loaded file. '
              'A different path here means the earlier open(asset://A) '
              'resumed after its asset I/O and its loadfile clobbered B — '
              'the superseded request won.',
        );
      } finally {
        await sub.cancel();
      }
    }, timeout: const Timeout(Duration(seconds: 60)));
  });
}
