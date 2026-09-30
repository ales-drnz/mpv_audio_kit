// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:ffi';

import 'package:mpv_audio_kit/src/internals/mpv_client.dart';
import 'package:mpv_audio_kit/src/mpv_bindings.dart';
import 'package:test/test.dart';

void main() {
  group('MpvClient', () {
    test('an enqueue that throws settles its slot', () async {
      final lib = MpvLibrary.uninitializedForTest()
        ..mpvCommandAsync = (_, _, _) => throw StateError('enqueue failed');
      final client = MpvClient(lib, nullptr);

      expect(() => client.command(['stop']), throwsStateError);
      // The failed request must not stay open: settleWrites waits for
      // every write on the wire, and would never complete.
      await expectLater(
        client.settleWrites().timeout(const Duration(seconds: 1)),
        completes,
      );
    });

    test('a request mpv refuses client-side resolves with its rc', () async {
      final lib = MpvLibrary.uninitializedForTest()
        ..mpvCommandAsync = (_, _, _) => MpvError.mpvErrorInvalidParameter;
      final client = MpvClient(lib, nullptr);

      final (rc, _) = await client.command(['stop']);
      expect(rc, MpvError.mpvErrorInvalidParameter);
      await expectLater(client.settleWrites(), completes);
    });
  });
}
