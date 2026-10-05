// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

import '../_helpers/mpv_error_capture.dart';
import '../_helpers/setter_test_helpers.dart';

/// Effects swapped on a short paused file: now and then a filter that held
/// the end goes away, chain_eof re-seeks, and the next filter is created
/// while the chain restarts, with the end of the stream as its first input.
/// hdcd takes no float, so a graph built on mpv's dummy float format failed
/// and the filter was disabled. libmpv-scripts' lavfi_eof_passthrough patch
/// passes that EOF on and builds the graph on the next real frame.
void main() {
  final fixture = '${Directory.current.path}/test/fixtures/sine_stereo_1s.flac';

  setUpAll(() => initLibmpvOrSkip(fixturePath: fixture));

  test('an effect created while the chain restarts at the end stays on',
      () async {
    final player = await buildPlayer(
      configuration: const PlayerConfiguration(logLevel: LogLevel.error),
    );
    addTearDown(player.dispose);
    await openAndWaitForLoad(player, fixture);

    const effects = {
      'hdcd': AudioEffects(hdcd: HdcdSettings(enabled: true)),
      'haas': AudioEffects(haas: HaasSettings(enabled: true)),
      'highpass': AudioEffects(highpass: HighpassSettings(enabled: true)),
    };
    // With libmpv-r15 the first failure came at the 26th round on Linux.
    for (var round = 0; round < 60; round++) {
      for (final MapEntry(key: name, value: fx) in effects.entries) {
        final errors = await captureMpvErrors(
          player,
          () => player.setAudioEffects(fx),
        );
        expect(errors.map((e) => e.text.trim()), isEmpty,
            reason: 'round $round, $name',);
        await player.setAudioEffects(const AudioEffects());
      }
    }
  }, timeout: const Timeout(Duration(minutes: 2)),);
}
