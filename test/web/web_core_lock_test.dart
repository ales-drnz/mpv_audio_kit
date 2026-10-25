// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// The calls that lock the core run on the browser's main thread, where
// Emscripten waits for the lock with a busy loop (web_session.dart). This
// measures them against a core that plays through a heavy chain, with hooks
// registered and continued meanwhile, and checks that none takes a frame
// (16 ms): the measure behind not moving them to a service thread. The
// numbers go to the console (read them over CDP, see AUDIT/w4a).

@TestOn('browser')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:mpv_audio_kit/src/backend/web/mpv_module.dart';

import '../_helpers/parity_scenario.dart';
import 'web_module_helper.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadTestModule();
    MpvAudioKit.ensureInitialized(hotRestartCleanup: false);
  });

  test('the core-locking calls stay under a frame', () async {
    webCallMaxMicros.clear();
    final long = await blobFixture('fixtures/sine_5s.flac');
    final short = await blobFixture('fixtures/sine_stereo_1s.flac');
    final player = Player();
    addTearDown(player.dispose);
    await player.ready;
    await player.setRawProperty('ao', 'null');
    await player.setAudioEffects(const [
      LoudnormEffect(),
      AfftdnEffect(),
      EqualizerEffect(frequency: 1000, gain: 3),
    ]);
    await player.open(Media(long), play: true);
    await waitUntil(() => player.state.playing, what: 'playing');
    // Registered while the chain plays, then continued at each load.
    await player.registerHook(Hook.unload, timeout: const Duration(seconds: 1));
    final hooks = player.stream.hook.listen((e) => player.continueHook(e.id));
    addTearDown(hooks.cancel);
    await player.setSourceResolver((r) => null);
    for (var i = 0; i < 3; i++) {
      await player.add(Media(short));
      await player.next();
      await waitUntil(
        () => player.state.playlist.index == i + 1,
        what: 'entry ${i + 1}',
      );
    }
    await player.dispose();
    // ignore: avoid_print
    print('core-locking calls, longest run in us: $webCallMaxMicros');
    expect(
      webCallMaxMicros.keys,
      containsAll(['mpv_hook_add', 'mpv_hook_continue']),
    );
    for (final MapEntry(:key, :value) in webCallMaxMicros.entries) {
      expect(value, lessThan(16000), reason: '$key took $value us');
    }
  }, timeout: const Timeout(Duration(seconds: 60)));
}
