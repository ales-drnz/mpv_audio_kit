// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

import '../_helpers/setter_test_helpers.dart';

void main() {
  // The `af` mpv property is owned by the effects chain.
  // Both write paths must reject — `setRawProperty('af', ...)` AND
  // `sendRawCommand(['af', ...])` (incremental mutator) AND
  // `sendRawCommand(['af-command', ...])` (per-filter command).
  //
  // Pre-0.1.0 only `setRawProperty` was guarded; `sendRawCommand` left
  // a backdoor that silently desynced `state.audioEffects` from mpv.
  runtimeSuite(() {
    late Player player;
    setUp(() async {
      player = await buildPlayer();
    });
    tearDown(() async {
      await player.dispose();
    });

    test('setRawProperty through an option prefix is rejected', () {
      for (final name in ['options/af', 'file-local-options/pause']) {
        expect(
          () => player.setRawProperty(name, 'yes'),
          throwsA(isA<ArgumentError>()),
          reason: name,
        );
      }
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

    test(
      'sendRawCommand([af-command, ...]) is rejected (per-filter command)',
      () {
        expect(
          () => player.sendRawCommand(['af-command', 'loudnorm', 'enable']),
          throwsA(isA<ArgumentError>()),
        );
      },
    );

    test('property commands cannot write af or pause', () {
      for (final args in [
        ['set', 'af', 'lavfi-loudnorm'],
        ['change-list', 'af', 'append', 'lavfi-loudnorm'],
        ['no-osd', 'set', 'af', ''],
        ['cycle', 'pause'],
        ['set', 'pause', 'yes'],
        ['no-osd', 'af', 'add', 'lavfi-loudnorm'],
        ['set', 'options/af', 'lavfi-loudnorm'],
        ['set', 'file-local-options/pause', 'yes'],
        ['cycle-values', '!reverse', 'pause', 'yes', 'no'],
        ['loadfile', '/tmp/x.flac', 'replace', '-1', 'start=5,pause=yes'],
        ['loadfile', '/tmp/x.flac', 'append', '-1', 'af=lavfi-loudnorm'],
        // mpv reads `_` in a command name as `-`.
        ['change_list', 'af', 'append', 'lavfi-loudnorm'],
        ['af_command', 'loudnorm', 'enable'],
        ['cycle_values', 'pause', 'yes', 'no'],
        // Per-file options take list actions, `no-`, and quoted keys.
        ['loadfile', '/tmp/x.flac', 'append', '-1', 'af-add=lavfi-loudnorm'],
        ['loadfile', '/tmp/x.flac', 'append', '-1', 'no-pause'],
        ['loadfile', '/tmp/x.flac', 'append', '-1', '"af"=lavfi-loudnorm'],
        ['loadfile', '/tmp/x.flac', 'append', '-1', '[pause]=yes'],
        ['loadfile', '/tmp/x.flac', 'append', '-1', '%5%pause=yes'],
      ]) {
        expect(
          () => player.sendRawCommand(args),
          throwsA(isA<ArgumentError>()),
          reason: '$args',
        );
      }
    });

    test('property commands on other properties are allowed', () async {
      await player.sendRawCommand(['set', 'volume', '40']);
      await player.sendRawCommand(['no-osd', 'add', 'volume', '5']);
      // A property that only starts like an owned one reaches mpv, which
      // refuses the write because af-metadata is read-only.
      await expectLater(
        player.sendRawCommand(['set', 'af-metadata', '']),
        throwsA(isA<MpvCommandException>()),
      );
      expect(await player.getRawProperty('volume'), startsWith('45'));
    });

    test('sendRawCommand([screenshot, ...]) is allowed (sanity)', () async {
      // Confirm the guard is targeted, not a blanket sendRawCommand block.
      // `screenshot` is meaningless on the audio-only build but mpv accepts
      // the command (it returns -9 because no video is loaded). The point
      // is the wrapper LET the call through to the FFI boundary instead of
      // rejecting it pre-emptively.
      try {
        await player.sendRawCommand(['screenshot']);
      } on MpvCommandException {
        // Expected: mpv rejects on this build. Reaching the catch confirms
        // the guard didn't fire.
      } on ArgumentError {
        fail('sendRawCommand([screenshot]) must not be ArgumentError-blocked');
      }
    });
  });
}
