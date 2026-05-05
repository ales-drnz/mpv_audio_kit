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
  // End-to-end wiring of `audio_output_error.dart`:
  //
  //   audio-output-state == failed
  //     → registry dispatches via spec.parseAndDispatch
  //     → onAudioOutputState callback (default_specs.dart)
  //     → buildAudioOutputError returns MpvLogError
  //     → _errorCtrl.add lands on Player.stream.error
  //
  // This test bypasses the libmpv AO layer (which is genuinely hard to
  // make fail deterministically across host platforms — `coreaudio` /
  // `null` always succeed on macOS / Linux CI) by feeding the real
  // dispatch pipeline through `Player.debugDispatchProperty`. The whole
  // chain from registry to error stream is exercised exactly as the
  // event isolate does it at runtime; only the FFI source is replaced.
  setUpAll(() => initLibmpvOrSkip());

  test('audio-output-state == failed lands on stream.error', () async {
    final player = Player(
      configuration: const PlayerConfiguration(
        autoPlay: false,
        logLevel: LogLevel.off,
      ),
    );
    try {
      // Pre-subscribe so we don't race the (synchronous) error emit.
      final errorFuture = player.stream.error
          .firstWhere((e) =>
              e is MpvLogError && e.text.toLowerCase().contains('audio output'))
          .timeout(const Duration(seconds: 5));

      // Simulate the patched libmpv emit: audio-output-state goes
      // through closed → initializing → failed.
      player.debugDispatchProperty('audio-output-state', 'initializing');
      player.debugDispatchProperty('audio-output-state', 'failed');

      final err = await errorFuture as MpvLogError;
      expect(err.prefix, 'mpv_audio_kit',
          reason:
              'AO error path must carry the library prefix so consumers can '
              'distinguish it from raw mpv log errors');
      expect(err.level, LogLevel.error);
      expect(err.text.toLowerCase(), contains('audio output'));
      expect(player.state.audioOutputState, AudioOutputState.failed,
          reason: 'state.audioOutputState must mirror the dispatched value');
    } finally {
      await player.dispose();
    }
  }, timeout: const Timeout(Duration(seconds: 10)));

  test('audio-output-state transitions to non-failed do NOT emit errors',
      () async {
    final player = Player(
      configuration: const PlayerConfiguration(
        autoPlay: false,
        logLevel: LogLevel.off,
      ),
    );
    try {
      final errors = <MpvPlayerError>[];
      final sub = player.stream.error.listen(errors.add);

      player.debugDispatchProperty('audio-output-state', 'initializing');
      player.debugDispatchProperty('audio-output-state', 'active');
      player.debugDispatchProperty('audio-output-state', 'closed');
      // Allow the dispatch microtasks to drain.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await sub.cancel();

      expect(errors, isEmpty,
          reason: 'Only audio-output-state==failed must produce an error');
    } finally {
      await player.dispose();
    }
  });
}
