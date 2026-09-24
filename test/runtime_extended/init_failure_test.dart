// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

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
}
