// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'dart:async';

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

import '../_helpers/setter_test_helpers.dart';

void main() {
  final fixturePath = defaultFixturePath();

  Player? player;

  setUpAll(() async {
    if (!initLibmpvOrSkip(fixturePath: fixturePath)) return;
    player = await buildPlayerWithFixture(fixturePath: fixturePath);
  });

  tearDownAll(() async {
    await player?.dispose();
  });

  test('setLogLevel changes the mpv log threshold at runtime', () async {
    final p = player;
    if (p == null) {
      markTestSkipped('libmpv not found');
      return;
    }

    final errors = <MpvLogEntry>[];
    final sub = p.stream.log
        .where((e) => e.level == LogLevel.error || e.level == LogLevel.fatal)
        .listen(errors.add);

    try {
      await _trySetBogusFilter(p, 'lavfi-log-level-off-probe');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(
        errors,
        isEmpty,
        reason:
            'The player starts with LogLevel.off in the test helper, '
            'so mpv error logs should be suppressed before the setter.',
      );

      await p.setLogLevel(LogLevel.error);
      await _trySetBogusFilter(p, 'lavfi-log-level-error-probe');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(
        errors,
        isNotEmpty,
        reason:
            'After setLogLevel(LogLevel.error), mpv error diagnostics '
            'must reach Player.stream.log without recreating the Player.',
      );
    } finally {
      await sub.cancel();
      try {
        await p.setAudioEffects(const AudioEffects());
      } catch (_) {}
    }
  }, timeout: const Timeout(Duration(seconds: 10)));
}

Future<void> _trySetBogusFilter(Player player, String name) async {
  try {
    await player.setAudioEffects(AudioEffects(custom: [name]));
  } on MpvException {
    // mpv may reject the live `af` assignment synchronously while also
    // emitting the diagnostic on the log stream; this test only cares about
    // whether the log threshold lets that diagnostic through.
  }
}
