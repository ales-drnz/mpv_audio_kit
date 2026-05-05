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
  // The `af` mpv property is owned by the typed AudioEffects bundle.
  // Both write paths must reject — `setRawProperty('af', ...)` AND
  // `sendRawCommand(['af', ...])` (incremental mutator) AND
  // `sendRawCommand(['af-command', ...])` (per-filter command).
  //
  // Pre-0.1.0 only `setRawProperty` was guarded; `sendRawCommand` left
  // a backdoor that silently desynced `state.audioEffects` from mpv.
  setUpAll(() => initLibmpvOrSkip());

  late Player player;
  setUp(() async {
    player = await buildPlayer();
  });
  tearDown(() async {
    await player.dispose();
  });

  test('setRawProperty(af, ...) is rejected', () {
    expect(
      () => player.setRawProperty('af', 'lavfi-loudnorm'),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('sendRawCommand([af, ...]) is rejected (incremental mutator)', () {
    expect(
      () => player.sendRawCommand(['af', 'add', 'lavfi-loudnorm']),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('sendRawCommand([af-command, ...]) is rejected (per-filter command)',
      () {
    expect(
      () => player.sendRawCommand(['af-command', 'loudnorm', 'enable']),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('sendRawCommand([screenshot, ...]) is allowed (sanity)', () async {
    // Confirm the guard is targeted, not a blanket sendRawCommand block.
    // `screenshot` is meaningless on the audio-only build but mpv accepts
    // the command (it returns -9 because no video is loaded). The point
    // is the wrapper LET the call through to the FFI boundary instead of
    // rejecting it pre-emptively.
    try {
      await player.sendRawCommand(['screenshot']);
    } on MpvException {
      // Expected: mpv rejects on this build. Reaching the catch confirms
      // the guard didn't fire.
    } on ArgumentError {
      fail('sendRawCommand([screenshot]) must not be ArgumentError-blocked');
    }
  });
}
