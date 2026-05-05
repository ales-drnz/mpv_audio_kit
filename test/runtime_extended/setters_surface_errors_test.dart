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
  // Pins the contract: typed setters MUST surface mpv rejections as
  // [MpvException], not silently swallow them. Pre-0.1.0 every typed
  // setter dropped the rc from `mpv_set_property_string`, leaving the
  // optimistic state desynced from libmpv with no signal to the caller.
  //
  // Verified via `setVolumeMax`: mpv hard-rejects values below 100
  // with an OPTION error code that the wrapper now lifts into an
  // MpvException (instead of silently dropping the rc the way
  // pre-0.1.0 setters did).
  setUpAll(() => initLibmpvOrSkip());

  late Player player;
  setUp(() async {
    player = await buildPlayer();
  });
  tearDown(() async {
    await player.dispose();
  });

  test('setVolumeMax with out-of-range value throws MpvException', () async {
    // mpv hard-rejects volume-max below 100 with a negative rc.
    await expectLater(
      player.setVolumeMax(50),
      throwsA(isA<MpvException>()
          .having((e) => e.name, 'name', 'volume-max')
          .having((e) => e.code, 'code', lessThan(0))),
      reason:
          'A typed setter that hands an out-of-range value to mpv must '
          'throw MpvException, not silently swallow the rc and leave '
          'state.volumeMax desynced from the engine.',
    );
  }, timeout: const Timeout(Duration(seconds: 10)));

  test('setAudioFormat with mpv-known value succeeds', () async {
    // Sanity: the fix must not turn legitimate setters into errors.
    await player.setAudioFormat(Format.s16);
    expect(player.state.audioFormat, Format.s16);
  });
}
