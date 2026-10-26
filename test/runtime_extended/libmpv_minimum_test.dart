// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

// A libmpv the app passes by path can be any build. The player relies on
// the patches of libmpv-scripts 0.3.0 (libmpv-r20), plays without them,
// and says on internalLog what an older build loses. Up to 0.5.3 the check
// ran for the bundled libmpv only.

@TestOn('mac-os || linux || windows')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:mpv_audio_kit/src/internals/libmpv_requirements.dart';

import '../_helpers/libmpv_resolver.dart';
import '../_helpers/setter_test_helpers.dart';

void main() {
  runtimeSuite(initialize: false, () {
    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      MpvAudioKit.ensureInitialized(
        libmpv: resolveLibmpv(),
        hotRestartCleanup: false,
      );
    });

    test('a libmpv passed by path is checked against the minimum '
        'release', () async {
      final release = libmpvReleaseOf(resolveLibmpv()!);
      final player = Player(
        configuration: const PlayerConfiguration(logLevel: LogLevel.off),
      );
      final warnings = <String>[];
      final sub = player.stream.internalLog.listen((e) => warnings.add(e.text));
      addTearDown(() async {
        await sub.cancel();
        await player.dispose();
      });
      await player.setRawProperty('ao', 'null');
      // The check reads the version and one property per patch, each a
      // round trip queued after the previous one.
      for (var i = 0; i <= libmpvRequiredPatches.length + 1; i++) {
        await player.getRawProperty('mpv-version');
      }
      await pumpEventQueue();
      final told = warnings.where((w) => w.contains('libmpv-scripts 0.3.0'));
      if ((release ?? 0) >= libmpvMinimumRelease) {
        expect(told, isEmpty, reason: 'libmpv r$release: $warnings');
      } else {
        expect(told, hasLength(1), reason: 'libmpv r$release: $warnings');
        for (final (_, loss) in libmpvRequiredPatches) {
          expect(told.single, contains(loss));
        }
      }
      // And it plays.
      await openAndWaitForLoad(player, defaultFixturePath());
    }, timeout: const Timeout(Duration(seconds: 20)));
  });
}
