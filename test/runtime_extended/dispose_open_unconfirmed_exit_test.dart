// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@TestOn('mac-os || linux')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

import '../_helpers/setter_test_helpers.dart';
import '../_helpers/slow_core_shim.dart';

void main() {
  slowCoreShimSuite(fixturePath: defaultFixturePath(), (shim) {
    setUp(() => shim().reset());
    tearDown(() => shim().reset());

    // When the event isolate does not confirm its exit, dispose closes the
    // session and the streams back to back. An openAll() whose pause
    // write was waiting for its reply resumes in between, past its last
    // check of the dispose, and cleared the state of the old file: an
    // event on streams one turn from closed, where an add throws.
    test('an openAll() in flight at a dispose that could not confirm the '
        'isolate exit emits nothing after the dispose', () async {
      final player = await buildPlayer();
      await player.ready;
      shim().holdReply('pause', const Duration(seconds: 4));
      final opened = player.openAll([
        Media(defaultFixturePath()),
        Media(defaultFixturePath()),
      ], play: false);
      await waitUntil(
        () => shim().counter('replies_held') > 0,
        reason: 'the reply to the pause write was never held',
      );
      final late = <CoverArt?>[];
      final disposed = player.dispose();
      final sub = player.stream.coverArt.listen(late.add);
      await expectLater(opened, completes);
      await disposed.timeout(const Duration(seconds: 10));
      // The held isolate leaves, and the late destroy runs, before the
      // shim is reset.
      await Future<void>.delayed(const Duration(seconds: 4));
      await sub.cancel();
      // The replay of the value at the listen, and nothing after it.
      expect(late, [null], reason: 'the state changed after dispose');
    }, timeout: const Timeout(Duration(seconds: 60)));
  });
}
