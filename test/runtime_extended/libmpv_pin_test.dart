// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

// Each version of the package runs on the libmpv of its pin, and on no
// other: a libmpv of another release, or a build of upstream mpv, fails
// bring-up with a PlayerInitException. Up to 0.6.1 such a libmpv played,
// with a warning on internalLog. The shim answers the version of another
// release in place of the real one.

@TestOn('mac-os || linux')
@Timeout(Duration(minutes: 1))
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:mpv_audio_kit/src/internals/libmpv_release.dart';

import '../_helpers/setter_test_helpers.dart';
import '../_helpers/slow_core_shim.dart';

void main() {
  slowCoreShimSuite((shim) {
    tearDown(() => shim().reset());

    Future<void> expectRefused(String version, String shown) async {
      shim().fakeVersion(version);
      final player = Player(
        configuration: const PlayerConfiguration(logLevel: LogLevel.off),
      );
      addTearDown(player.dispose);
      await expectLater(
        player.ready,
        throwsA(
          isA<PlayerInitException>().having(
            (e) => e.message,
            'message',
            allOf(contains(shown), contains('libmpv-$libmpvRelease')),
          ),
        ),
      );
    }

    test('a libmpv of another release fails bring-up', () async {
      await expectRefused('mpv v0.41.0+r20', 'mpv v0.41.0+r20');
    });

    test('a build of upstream mpv fails bring-up', () async {
      await expectRefused('mpv v0.41.0', 'mpv v0.41.0');
    });

    test('the libmpv of the pin brings up and plays', () async {
      final player = Player(
        configuration: const PlayerConfiguration(logLevel: LogLevel.off),
      );
      addTearDown(player.dispose);
      await player.ready;
      await player.setRawProperty('ao', 'null');
      await openAndWaitForLoad(player, defaultFixturePath());
    });
  });
}
