// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'dart:io';

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

import '../_helpers/setter_test_helpers.dart';

void main() {
  final fx = defaultFixturePath();
  runtimeSuite(fixturePath: fx, () {
    test('writeResumeConfig + reopen restores the saved position', () async {
      final tmp = Directory.systemTemp.createTempSync('mak_resume_');
      addTearDown(() {
        try {
          tmp.deleteSync(recursive: true);
        } catch (_) {}
      });
      final cfg = PlayerConfiguration(
        logLevel: LogLevel.off,
        watchLaterDir: tmp.path,
      );

      // Session 1: play in, seek to 0.6s, save the resume point.
      final p1 = await buildPlayer(configuration: cfg);
      await openAndWaitForLoad(p1, fx);
      await p1.seek(const Duration(milliseconds: 600));
      await Future<void>.delayed(const Duration(milliseconds: 400));
      await p1.writeResumeConfig();
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(
        tmp.listSync(),
        isNotEmpty,
        reason: 'a watch-later config file is written into watchLaterDir',
      );
      await p1.dispose();

      // Session 2: reopen the SAME file → mpv restores ~0.6s during load.
      final p2 = await buildPlayer(configuration: cfg);
      addTearDown(p2.dispose);
      final resumed = p2.stream.position
          .firstWhere((x) => x.inMilliseconds > 400)
          .timeout(const Duration(seconds: 8));
      await p2.open(Media(fx), play: false);
      final pos = await resumed;
      expect(
        pos.inMilliseconds,
        greaterThan(400),
        reason: 'resume-playback restored the position from the saved config',
      );
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('deleteResumeConfig clears the saved resume point', () async {
      final tmp = Directory.systemTemp.createTempSync('mak_delresume_');
      addTearDown(() {
        try {
          tmp.deleteSync(recursive: true);
        } catch (_) {}
      });
      final cfg = PlayerConfiguration(
        logLevel: LogLevel.off,
        watchLaterDir: tmp.path,
      );

      final p = await buildPlayer(configuration: cfg);
      addTearDown(p.dispose);
      await openAndWaitForLoad(p, fx);
      await p.seek(const Duration(milliseconds: 600));
      await Future<void>.delayed(const Duration(milliseconds: 400));

      // Write a resume point, confirm it lands...
      await p.writeResumeConfig();
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(
        tmp.listSync(),
        isNotEmpty,
        reason: 'precondition: a watch-later config exists to delete',
      );

      // ...then delete it for the current file and confirm it is gone.
      await p.deleteResumeConfig();
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(
        tmp.listSync(),
        isEmpty,
        reason: 'deleteResumeConfig removed the current file\'s resume config',
      );
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('resumePlayback=false does NOT restore position', () async {
      final tmp = Directory.systemTemp.createTempSync('mak_noresume_');
      addTearDown(() {
        try {
          tmp.deleteSync(recursive: true);
        } catch (_) {}
      });

      // Write a resume point with resume ON...
      final p1 = await buildPlayer(
        configuration: PlayerConfiguration(
          logLevel: LogLevel.off,
          watchLaterDir: tmp.path,
        ),
      );
      await openAndWaitForLoad(p1, fx);
      await p1.seek(const Duration(milliseconds: 600));
      await Future<void>.delayed(const Duration(milliseconds: 400));
      await p1.writeResumeConfig();
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await p1.dispose();

      // ...but reopen with resume OFF → starts at 0.
      final p2 = await buildPlayer(
        configuration: PlayerConfiguration(
          logLevel: LogLevel.off,
          watchLaterDir: tmp.path,
          resumePlayback: false,
        ),
      );
      addTearDown(p2.dispose);
      await openAndWaitForLoad(p2, fx);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(
        p2.state.position.inMilliseconds,
        lessThan(300),
        reason: 'with resumePlayback:false playback starts from the beginning',
      );
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}
