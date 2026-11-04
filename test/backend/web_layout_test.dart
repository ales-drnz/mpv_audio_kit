// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// The checks a web module passes before any other call into it (ABI
// version and struct layout), on the VM: the rules are plain Dart. The
// module of the pin passes, any other is refused.

import 'package:mpv_audio_kit/src/backend/web/web_layout.dart';
import 'package:mpv_audio_kit/src/internals/libmpv_release.dart';
import 'package:test/test.dart';

/// mak_web_layout() of libmpv-r21 (ABI 2): END_FILE of 56 bytes, the read
/// error at 28, the skipped segments at 32, the duration at 40 and the
/// position at 48.
const _r21 = [
  16, 8, 12, 4, 8, 8, 4, 24, 4, 8, 16, 12, 4, 8, 16, 8, 12, //
  56, 4, 8, 16, 24, 28, 32, 40, 48, 16, 8,
];

/// The same module built without the read_error patch.
const _noReadError = [
  16, 8, 12, 4, 8, 8, 4, 24, 4, 8, 16, 12, 4, 8, 16, 8, 12, //
  32, 4, 8, 16, 24, 0, 0, 0, 0, 16, 8,
];

/// mak_web_layout() of libmpv-r20 (ABI 1): END_FILE of 40 bytes, two
/// fields.
const _r20 = [
  16, 8, 12, 4, 8, 8, 4, 24, 4, 8, 16, 12, 4, 8, 16, 8, 12, //
  40, 4, 8, 16, 24, 28, 32, 16, 8,
];

/// The 24 entries of the modules before the ABI (W1 to W3).
const _beforeAbi = [
  16, 8, 12, 4, 8, 8, 4, 24, 4, 8, 16, 12, 4, 8, 16, 8, 12, //
  32, 4, 8, 16, 24, 16, 8,
];

void main() {
  group('checkWebModuleAbi', () {
    test('takes the ABI of the package', () {
      expect(webModuleAbi, 2);
      checkWebModuleAbi(webModuleAbi);
    });

    test('refuses another ABI, naming both', () {
      expect(
        () => checkWebModuleAbi(1),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            allOf(contains('has ABI 1'), contains('needs ABI 2')),
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
    test('takes the layout of the pinned release', () {
      checkWebLayout(_r21);
      expect(kEndFileFields, (
        readError: 28,
        skippedSegments: 32,
        duration: 40,
        position: 48,
      ));
    });

    test('a module without the read_error patch is refused', () {
      expect(() => checkWebLayout(_noReadError), throwsStateError);
    });

    test('the 26 entries of libmpv-r20 and the 24 of a module before the '
        'ABI are refused', () {
      expect(() => checkWebLayout(_r20), throwsStateError);
      expect(() => checkWebLayout(_beforeAbi), throwsStateError);
    });

    test('any other size or offset is refused', () {
      for (var i = 0; i < _r21.length; i++) {
        final table = [..._r21]..[i] += 4;
        expect(() => checkWebLayout(table), throwsStateError, reason: '$i');
      }
      expect(() => checkWebLayout([..._r21, 0]), throwsStateError);
    });
  });
}
