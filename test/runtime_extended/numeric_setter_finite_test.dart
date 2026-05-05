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
  // Numeric setters must reject non-finite doubles BEFORE they reach
  // `toStringAsFixed`. Without the guard the wrapper sent the literal
  // `'NaN'` / `'Infinity'` to mpv, which produced an opaque rejection.
  // The new contract is: ArgumentError with the offending parameter
  // name, no FFI write, no state mutation.
  setUpAll(() => initLibmpvOrSkip());

  late Player player;
  setUp(() async {
    player = await buildPlayer();
  });
  tearDown(() async {
    await player.dispose();
  });

  test('setVolume rejects NaN / Infinity / -Infinity', () async {
    final priorVolume = player.state.volume;
    for (final bad in [
      double.nan,
      double.infinity,
      double.negativeInfinity,
    ]) {
      expect(() => player.setVolume(bad), throwsArgumentError,
          reason: 'volume=$bad must be rejected at the wrapper boundary');
    }
    expect(player.state.volume, priorVolume,
        reason: 'state must not advance past a rejected non-finite write');
  });

  test('setRate rejects NaN / Infinity', () async {
    expect(() => player.setRate(double.nan), throwsArgumentError);
    expect(() => player.setRate(double.infinity), throwsArgumentError);
  });

  test('setPitch rejects NaN', () async {
    expect(() => player.setPitch(double.nan), throwsArgumentError);
  });

  test('setVolumeGain rejects NaN', () async {
    expect(() => player.setVolumeGain(double.nan), throwsArgumentError);
  });

  test('setVolumeMax rejects Infinity', () async {
    expect(() => player.setVolumeMax(double.infinity), throwsArgumentError);
  });

  test('finite values still pass (regression sanity)', () async {
    await player.setVolume(50);
    expect(player.state.volume, 50);
    await player.setRate(1.5);
    expect(player.state.rate, 1.5);
  });
}
