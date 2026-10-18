// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:ffi';

import 'package:ffi/ffi.dart';
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

    test('a closed client reaches no libmpv call', () async {
      // A call that gets through is refused at once, so a missing guard
      // shows up in the count instead of a reply that never comes.
      var calls = 0;
      int refuse() {
        calls++;
        return MpvError.mpvErrorUninitialized;
      }

      final lib = MpvLibrary.uninitializedForTest()
        ..mpvSetPropertyAsync = ((_, _, _, _, _) => refuse())
        ..mpvCommandAsync = ((_, _, _) => refuse())
        ..mpvGetPropertyAsync = ((_, _, _, _) => refuse());
      final client = MpvClient(lib, nullptr)..close();

      final results = [
        await client.setProperty('volume', '50'),
        await client.setNodeProperty('af', (_) => nullptr),
        await client.command(['stop']),
        await client.getProperty('volume', MpvFormat.mpvFormatString),
      ];
      expect(calls, 0, reason: 'the handle is freed right after close');
      // Writes resolve as accepted, reads as failed (a null value).
      expect(results, [
        MpvError.mpvErrorSuccess,
        MpvError.mpvErrorSuccess,
        (MpvError.mpvErrorSuccess, null),
        (MpvError.mpvErrorGeneric, null),
      ]);
    });

    test(
      'a setter the drain of close resumes stops at its next write',
      () async {
        // A multi-write setter racing dispose: it waits on its first write,
        // dispose closes the client, the drain resumes it, and its next
        // write must not reach the handle mpv_terminate_destroy frees on the
        // line after close. Only the first write is accepted (with no reply),
        // so a second one would fail at once instead of hanging.
        final names = <String>[];
        final lib = MpvLibrary.uninitializedForTest()
          ..mpvSetPropertyAsync = (_, _, name, _, _) {
            names.add(name.toDartString());
            return names.length == 1
                ? MpvError.mpvErrorSuccess
                : MpvError.mpvErrorUninitialized;
          };
        final client = MpvClient(lib, nullptr);
        Future<void> setter() async {
          await client.setProperty('replaygain', 'track');
          await client.setProperty('replaygain-preamp', '0');
        }

        final running = setter();
        expect(names, ['replaygain']);
        client.close();
        await running;
        expect(names, ['replaygain']);
      },
    );
  });
}
