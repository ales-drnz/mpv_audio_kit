// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'dart:io';

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

import '../_helpers/setter_test_helpers.dart';

void main() {
  // End-to-end wiring of `audio_output_error.dart`:
  //
  //   audio-output-state == failed
  //     → registry dispatches via spec.parseAndDispatch
  //     → onAudioOutputState callback (default_specs.dart)
  //     → buildAudioOutputError returns LogError
  //     → _errorCtrl.add lands on Player.stream.error
  //
  // This test bypasses the libmpv AO layer (which is genuinely hard to
  // make fail deterministically across host platforms — `coreaudio` /
  // `null` always succeed on macOS / Linux CI) by feeding the real
  // dispatch pipeline through `Player.debugDispatchProperty`. The whole
  // chain from registry to error stream is exercised exactly as the
  // event isolate does it at runtime; only the FFI source is replaced.
  runtimeSuite(() {
    test('audio-output-state == failed lands on stream.error', () async {
      final player = Player(
        configuration: const PlayerConfiguration(logLevel: LogLevel.off),
      );
      try {
        // Pre-subscribe so we don't race the (synchronous) error emit.
        final errorFuture = player.stream.error
            .firstWhere(
              (e) =>
                  e is LogError &&
                  e.text.toLowerCase().contains('audio output'),
            )
            .timeout(const Duration(seconds: 5));

        // Simulate the `audio-output-state` mpv property transitioning
        // closed → initializing → failed.
        player.debugDispatchProperty('audio-output-state', 'initializing');
        player.debugDispatchProperty('audio-output-state', 'failed');

        final err = await errorFuture as LogError;
        expect(
          err.prefix,
          'mpv_audio_kit',
          reason:
              'AO error path must carry the library prefix so consumers can '
              'distinguish it from raw mpv log errors',
        );
        expect(err.level, LogLevel.error);
        expect(err.text.toLowerCase(), contains('audio output'));
        expect(
          player.state.audioOutputState,
          AudioOutputState.failed,
          reason: 'state.audioOutputState must mirror the dispatched value',
        );
      } finally {
        await player.dispose();
      }
    }, timeout: const Timeout(Duration(seconds: 10)));

    test(
      'audio-output-state transitions to non-failed do NOT emit errors',
      () async {
        final player = Player(
          configuration: const PlayerConfiguration(logLevel: LogLevel.off),
        );
        try {
          final errors = <PlayerError>[];
          final sub = player.stream.error.listen(errors.add);

          player.debugDispatchProperty('audio-output-state', 'initializing');
          player.debugDispatchProperty('audio-output-state', 'active');
          player.debugDispatchProperty('audio-output-state', 'closed');
          // Let the dispatch microtasks drain.
          await pumpEventQueue();
          await sub.cancel();

          expect(
            errors,
            isEmpty,
            reason: 'Only audio-output-state==failed must produce an error',
          );
        } finally {
          await player.dispose();
        }
      },
    );

    // mpv falls back to the null output when the device cannot be opened
    // (audio-fallback-to-null): the state goes active and the position
    // runs, but nothing is heard.
    test(
      'a fallback to the null output lands on stream.error once',
      () async {
        final player = await buildPlayer();
        addTearDown(player.dispose);
        // ALSA on a card that does not exist: the open fails.
        await player.setRawProperty('ao', 'alsa');
        await player.setRawProperty('audio-device', 'alsa/hw:99,99');
        final errors = <PlayerError>[];
        final sub = player.stream.error.listen(errors.add);
        addTearDown(sub.cancel);
        await openAndWaitForLoad(player, defaultFixturePath());
        await waitUntil(
          () => player.state.currentAo == 'null',
          reason: 'precondition: mpv fell back to the null output',
        );
        await waitUntil(
          () => errors.whereType<LogError>().any(
            (e) => e.prefix == 'mpv_audio_kit' && e.text.contains('null'),
          ),
          reason: 'the silent fallback is reported',
        );
        // A seek restarts the audio without opening the output again.
        await player.seek(const Duration(milliseconds: 300));
        await Future<void>.delayed(const Duration(milliseconds: 300));
        expect(
          errors.whereType<LogError>().where(
            (e) => e.prefix == 'mpv_audio_kit',
          ),
          hasLength(1),
        );
      },
      skip: Platform.isLinux ? false : 'needs ALSA',
      timeout: const Timeout(Duration(seconds: 20)),
    );

    test('the null output chosen by the app is no error', () async {
      // buildPlayer sets ao=null, as the runtime suites do.
      final player = await buildPlayer();
      addTearDown(player.dispose);
      final errors = <PlayerError>[];
      final sub = player.stream.error.listen(errors.add);
      addTearDown(sub.cancel);
      await openAndWaitForLoad(player, defaultFixturePath());
      await waitUntil(() => player.state.currentAo == 'null');
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(errors, isEmpty);
    }, timeout: const Timeout(Duration(seconds: 20)));
  });
}
