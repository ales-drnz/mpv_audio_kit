// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

// An exception inside a hook of the registry, as onIdleActive (the
// player's onIdle): the reduced state is committed and the cell updated
// before the hook runs, so the exception reaches the dispatcher's catch
// (_handleEvent logs it on internalLog) with nothing of the change lost,
// and the next changes dispatch as before.

import 'package:mpv_audio_kit/src/player/player_state.dart';
import 'package:mpv_audio_kit/src/player/state/player_settings.dart';
import 'package:mpv_audio_kit/src/reactive/default_reactives.dart';
import 'package:mpv_audio_kit/src/reactive/default_specs.dart';
import 'package:mpv_audio_kit/src/reactive/property_registry.dart';
import 'package:test/test.dart';

void main() {
  test('an exception inside onIdleActive comes after the commit', () {
    final reactives = DefaultPropertyReactives();
    final calls = <bool>[];
    final registry = PropertyRegistry()
      ..registerAll(
        buildDefaultSpecs(
          reactives,
          onIdleActive: (idle) {
            calls.add(idle);
            throw StateError('onIdle failed');
          },
          onAudioOutputState: (_) {},
        ),
      );
    var state = const PlayerState(settings: PlayerSettings(volume: 50));
    PlayerState? committed;

    expect(
      () => registry.dispatch(
        'idle-active',
        1,
        state,
        commit: (next) => committed = next,
      ),
      throwsStateError,
    );
    expect(calls, [true], reason: 'the hook ran once, with the change');
    expect(committed, isNotNull, reason: 'the state was committed first');

    // The cell took the value: the same value again does not run the hook
    // a second time, a new one does.
    expect(registry.dispatch('idle-active', 1, state), isNull);
    expect(calls, [true]);
    expect(() => registry.dispatch('idle-active', 0, state), throwsStateError);
    expect(calls, [true, false]);

    // Another property dispatches as before.
    final next = registry.dispatch('volume', 80.0, state);
    expect(next?.settings.volume, 80);
    state = next!;
    expect(reactives.volume.value, 80);
  });
}
