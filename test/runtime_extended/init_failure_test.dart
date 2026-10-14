// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

/// A player whose libmpv cannot load reports it on every call as
/// [PlayerInitException].
void main() {
  test('a libmpv that cannot load throws PlayerInitException', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    MpvAudioKit.ensureInitialized(
      libmpv: '/nonexistent/libmpv_audio_kit.so',
      hotRestartCleanup: false,
    );
    final player = Player();
    await expectLater(
      player.setVolume(10),
      throwsA(isA<PlayerInitException>()),
    );
    await player.dispose();
  });

  test('a failed init nobody awaits is no unhandled error', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    MpvAudioKit.ensureInitialized(
      libmpv: '/nonexistent/libmpv_audio_kit.so',
      hotRestartCleanup: false,
    );
    final errors = <Object>[];
    final unhandledAfterWait = <Object>[];
    Object? readyError;
    final done = Completer<void>();
    // Everything in the zone: an error does not cross into another error
    // zone, so `ready` is awaited from inside it too.
    unawaited(
      runZonedGuarded(() async {
        // Created at startup, first used later: nothing awaits the init.
        final player = Player();
        await Future<void>.delayed(const Duration(milliseconds: 500));
        unhandledAfterWait.addAll(errors);
        try {
          await player.ready;
        } catch (e) {
          readyError = e;
        }
        await player.dispose();
        done.complete();
      }, (e, _) => errors.add(e)),
    );
    await done.future;
    expect(unhandledAfterWait, isEmpty);
    expect(errors, isEmpty);
    expect(readyError, isA<PlayerInitException>());
  });
}
