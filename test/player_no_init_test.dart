// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'package:test/test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

void main() {
  group('Player() without MpvAudioKit.ensureInitialized', () {
    test('throws MpvLibraryException pointing at the missing bundled libmpv',
        () {
      // No ensureInitialized() call: MpvAudioKit.libraryPath is null,
      // and MpvLibrary._resolvePath() looks for libmpv inside the
      // Flutter app bundle (../Frameworks/...). In a `dart test` /
      // `flutter test` process, those paths don't exist and the
      // wrapper must surface a typed MpvLibraryException — never a
      // raw FFI failure.
      expect(
        () => Player(),
        throwsA(
          isA<MpvLibraryException>().having(
            (e) => e.message,
            'message',
            contains('libmpv'),
          ),
        ),
      );
    });
  });
}
