// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// TEMPORARY probe of front C4, removed before integration: what mpv says
// while the default audio output of iOS should open. It only prints and
// always passes.

import 'dart:io' show Platform;

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

import '_helpers/asset_fixture.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    MpvAudioKit.ensureInitialized(hotRestartCleanup: false);
  });

  testWidgets('C4 probe: the default output on iOS', (_) async {
    if (!Platform.isIOS) return;
    final clock = Stopwatch()..start();
    final lines = <String>[];
    void note(String s) => lines.add('${clock.elapsedMilliseconds} ms $s');
    final player = Player(
      configuration: const PlayerConfiguration(logLevel: LogLevel.v),
    );
    final subs = [
      player.stream.log.listen(
        (e) => note('log ${e.level.name} [${e.prefix}] ${e.text.trim()}'),
      ),
      player.stream.internalLog.listen((e) => note('internal $e')),
      player.stream.error.listen((e) => note('error $e')),
      player.stream.endFile.listen((e) => note('end ${e.reason} ${e.error}')),
      player.stream.playing.listen((p) => note('playing $p')),
      player.stream.currentAo.listen((a) => note('currentAo $a')),
    ];
    final fixture = await materializeFixture('sine_440hz_1s.wav');
    await player.setVolume(0);
    note('ao=${await player.getRawProperty('ao')}');
    await player.open(Media(fixture), play: true);
    await Future<void>.delayed(const Duration(seconds: 8));
    note(
      'after 8 s: playing ${player.state.playing} position '
      '${player.state.position} currentAo ${player.state.currentAo} '
      'audio-output-state ${await player.getRawProperty('audio-output-state')} '
      'pause ${await player.getRawProperty('pause')} '
      'core-idle ${await player.getRawProperty('core-idle')}',
    );
    for (final s in subs) {
      await s.cancel();
    }
    await player.dispose();
    for (final l in lines) {
      // ignore: avoid_print
      print('C4PROBE $l');
    }
  }, timeout: const Timeout(Duration(seconds: 60)));
}
