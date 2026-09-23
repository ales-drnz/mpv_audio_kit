// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'dart:ffi';
import 'dart:io';

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

/// The loader's last resort is the system search path (`libmpv.so` or
/// `libmpv.dll`), so a host with mpv installed never sees the failure this
/// test expects.
String? _systemLibmpvSkipReason() {
  if (Platform.isMacOS) return null;
  try {
    DynamicLibrary.open(Platform.isWindows ? 'libmpv.dll' : 'libmpv.so');
    return 'a system libmpv is on the search path';
  } on ArgumentError {
    return null;
  }
}

void main() {
  group(
    'Player() without MpvAudioKit.ensureInitialized',
    skip: _systemLibmpvSkipReason(),
    () {
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
    },
  );
}
