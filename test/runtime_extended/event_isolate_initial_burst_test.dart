// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'package:test/test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

import '../_helpers/setter_test_helpers.dart';

void main() {
  // Pins the event-isolate startup contract:
  //
  //   For every observed mpv property (~70 of them), the property's
  //   first emit MUST land on `state` and on `Player.stream.<x>`. Prior
  //   to 0.1.0 the controller was a broadcast `StreamController` and
  //   the listener was registered AFTER `start()` returned — the
  //   initial PROPERTY_CHANGE burst issued by libmpv between
  //   `mpv_observe_property` and the late `listen` was dropped on the
  //   floor (broadcast controllers never buffer).
  //
  //   `volume` is the canary here: it's seeded by `_applyPostInitOptions`
  //   with `configuration.initialVolume` (default 100.0) and libmpv
  //   immediately fires a PROPERTY_CHANGE for it. With the broadcast
  //   race, the first emit was lost and `state.volume` stayed at the
  //   PlayerState default (100.0 by coincidence) until the next
  //   user-driven setVolume.
  //
  //   The observable contract is "the first volume value the consumer
  //   reads from `stream.volume` is the seed mpv reports, not the
  //   PlayerState default" — proven below by configuring a non-default
  //   `initialVolume` and asserting it propagates.
  setUpAll(() => initLibmpvOrSkip());

  test('initial property burst from libmpv reaches the main isolate',
      () async {
    final player = Player(
      configuration: const PlayerConfiguration(
        autoPlay: false,
        logLevel: LogLevel.off,
        initialVolume: 42.5,
      ),
    );
    await player.setRawProperty('ao', 'null');

    try {
      // Subscribe to the volume stream and grab the first emit. With the
      // broadcast race, this firstWhere would time out because the seed
      // emit was lost between observe and listen.
      final firstVolume = await player.stream.volume
          .firstWhere((v) => v == 42.5)
          .timeout(const Duration(seconds: 5),
              onTimeout: () => double.nan);

      expect(firstVolume, 42.5,
          reason: 'The initial PROPERTY_CHANGE burst from libmpv must '
              'reach the main isolate. If this times out, the event '
              'isolate dropped the seed events between `start()` and '
              'the main-side listen.');
      expect(player.state.volume, 42.5,
          reason: 'state.volume must mirror the observed volume '
              'synchronously after the first emit propagates.');
    } finally {
      await player.dispose();
    }
  }, timeout: const Timeout(Duration(seconds: 10)));
}
