// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

void main() {
  group('Player() without MpvAudioKit.ensureInitialized', () {
    test('player.ready surfaces a libmpv-related failure when the bundled '
        'library is missing', () async {
      // No ensureInitialized() call: MpvAudioKit.libraryPath is null,
      // and the resolver looks for libmpv inside the Flutter app
      // bundle. In a test process those paths don't exist; the failure
      // now arrives on `player.ready` because mpv init runs in the
      // event isolate.
      final player = Player();
      await expectLater(
        player.ready,
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('libmpv'),
          ),
        ),
      );
      await player.dispose();
    });
  });
}
