// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// The checks a web module passes before any other call into it (ABI
// version and struct layout), on the VM: the rules are plain Dart. The
// tables are those of libmpv-scripts' mak_web_layout() with and without
// the read_error patch.

import 'package:mpv_audio_kit/src/backend/web/web_layout.dart';
import 'package:mpv_audio_kit/src/internals/libmpv_release.dart';
import 'package:test/test.dart';

/// mak_web_layout() of libmpv-r20: END_FILE of 40 bytes, the read error at
/// 28 and the skipped segments at 32.
const _r20 = [
  16, 8, 12, 4, 8, 8, 4, 24, 4, 8, 16, 12, 4, 8, 16, 8, 12, //
  40, 4, 8, 16, 24, 28, 32, 16, 8,
];

/// The same module built without the read_error patch.
const _noReadError = [
  16, 8, 12, 4, 8, 8, 4, 24, 4, 8, 16, 12, 4, 8, 16, 8, 12, //
  32, 4, 8, 16, 24, 0, 0, 16, 8,
];

/// The 24 entries of the modules before the ABI (W1 to W3).
const _beforeAbi = [
  16, 8, 12, 4, 8, 8, 4, 24, 4, 8, 16, 12, 4, 8, 16, 8, 12, //
  32, 4, 8, 16, 24, 16, 8,
];

void main() {
  group('checkWebModuleAbi', () {
    test('takes the ABI of the package', () {
      expect(webModuleAbi, 1);
      checkWebModuleAbi(webModuleAbi);
    });

    test('refuses another ABI, naming both', () {
      expect(
        () => checkWebModuleAbi(2),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            allOf(contains('has ABI 2'), contains('needs ABI 1')),
          ),
        ),
      );
    });

    test('refuses a module without an ABI version', () {
      expect(
        () => checkWebModuleAbi(null),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('states no ABI version'),
          ),
        ),
      );
    });
  });

  group('checkWebLayout', () {
    test(
      'a module with the read_error patch keeps its fields at 28 and 32',
      () {
        expect(checkWebLayout(_r20), (readError: 28, skippedSegments: 32));
      },
    );

    test('a module without it has a 32-byte END_FILE and no fields', () {
      expect(checkWebLayout(_noReadError), (readError: 0, skippedSegments: 0));
    });

    test('the 24 entries of a module before the ABI are refused', () {
      expect(() => checkWebLayout(_beforeAbi), throwsStateError);
    });

    test('any other size or offset is refused', () {
      for (var i = 0; i < _r20.length; i++) {
        final table = [..._r20]..[i] += 4;
        expect(() => checkWebLayout(table), throwsStateError, reason: '$i');
      }
      // The read error fields without the 40-byte END_FILE, and the other
      // way round.
      expect(
        () => checkWebLayout([..._noReadError]..[22] = 28),
        throwsStateError,
      );
      expect(
        () => checkWebLayout([..._noReadError]..[17] = 40),
        throwsStateError,
      );
      expect(() => checkWebLayout([..._r20, 0]), throwsStateError);
    });
  });
}
