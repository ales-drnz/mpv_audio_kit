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
  // Pre-0.1.0, `_eventIsolate` was a `late final` field assigned inside
  // a fire-and-forget `_startEventIsolate()` future. Calling `dispose()`
  // synchronously between `Player()` and the next microtask threw
  // `LateInitializationError: Field '_eventIsolate' has not been
  // initialized`. The fix made the field eager and stored the start
  // future as `_eventIsolateReady`, which dispose awaits before stop.
  setUpAll(() => initLibmpvOrSkip());

  test('Player() then dispose() synchronously must not throw', () async {
    final player = Player(
      configuration: const PlayerConfiguration(
        autoPlay: false,
        logLevel: LogLevel.off,
      ),
    );
    // Deliberately NO awaitable work between construction and dispose.
    // This is the hostile path that triggered the LateInitError.
    await player.dispose();
  }, timeout: const Timeout(Duration(seconds: 5)));

  test('Player() then dispose() in the same microtask must not throw',
      () async {
    final player = Player(
      configuration: const PlayerConfiguration(
        autoPlay: false,
        logLevel: LogLevel.off,
      ),
    );
    final disposed = player.dispose();
    await disposed;
  }, timeout: const Timeout(Duration(seconds: 5)));
}
