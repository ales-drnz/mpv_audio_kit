// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

// Regression test (red phase): `updateAudioEffects` lost-update race.
// The copyWith mapper runs synchronously on `state.audioEffects` at
// call time, BEFORE `setAudioEffects` suspends on `await _ready` and
// commits the new bundle. Two rapid un-awaited calls therefore both
// read the same pre-mutation bundle and the first mutation is silently
// dropped — classic read-modify-write race.

@TestOn('mac-os || linux || windows')
library;

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

import '../_helpers/setter_test_helpers.dart';

void main() {
  setUpAll(() => initLibmpvOrSkip(fixturePath: defaultFixturePath()));

  test('two back-to-back un-awaited updateAudioEffects calls must both '
      'land — no lost update', () async {
    final player = await buildPlayer();
    await openAndWaitForLoad(player, defaultFixturePath());
    addTearDown(player.dispose);

    // Fire both in the SAME synchronous turn — neither awaited before
    // the other starts. This is the documented UI-slider pattern
    // (`updateAudioEffects` exists precisely for rapid incremental
    // mutation) so concurrent in-flight calls are a supported shape.
    final f1 = player.updateAudioEffects(
      (e) => e.copyWith(bass: const BassSettings(enabled: true, gain: 6.0)),
    );
    final f2 = player.updateAudioEffects(
      (e) => e.copyWith(treble: const TrebleSettings(enabled: true, gain: 6.0)),
    );
    await Future.wait([f1, f2]);

    final effects = player.state.audioEffects;
    expect(
      effects.bass!.enabled,
      isTrue,
      reason:
          'First update (bass) was silently dropped: the second '
          "call's mapper ran on the pre-mutation bundle before the "
          'first commit landed (lost-update race in updateAudioEffects).',
    );
    expect(
      effects.treble!.enabled,
      isTrue,
      reason: 'Second update (treble) must land as well.',
    );
  }, timeout: const Timeout(Duration(seconds: 30)));
}
