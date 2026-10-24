// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

@TestOn('mac-os || linux')
@Timeout(Duration(minutes: 2))
library;

import 'package:ffi/ffi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:mpv_audio_kit/src/internals/orphan_handle_tracker.dart';
import 'package:mpv_audio_kit/src/mpv_bindings.dart';

import '../_helpers/setter_test_helpers.dart';
import '../_helpers/slow_core_shim.dart';

/// A destroy of the orphan that takes far longer than the bring-up waits.
const int _destroyDelayUs = 6000 * 1000;

void main() {
  // One Hot Restart per process, as in hot_restart_first_player_test.
  slowCoreShimSuite(initialize: false, (shim) {
    // The first player waits for the reap of F220 only so long: a destroy
    // that hangs must not hold the app's player with it.
    test(
      'a reap that hangs does not hold the first player past the bound',
      () async {
        final lib = MpvLibrary.open(shim().path);
        final orphan = lib.mpvCreate();
        using((arena) {
          for (final (name, value) in [('ao', 'null'), ('idle', 'yes')]) {
            lib.mpvSetOptionString(
              orphan,
              name.toNativeUtf8(allocator: arena),
              value.toNativeUtf8(allocator: arena),
            );
          }
        });
        expect(lib.mpvInitialize(orphan), greaterThanOrEqualTo(0));
        OrphanHandleTracker.forTesting(ProcessEnvironment.native())
          ..ensureInitialized((_) {})
          ..add(orphan);
        await Future<void>.delayed(Duration.zero);
        shim().set('destroy_delay_us', _destroyDelayUs);

        final sw = Stopwatch()..start();
        MpvAudioKit.ensureInitialized(libmpv: shim().path);
        final player = await buildPlayer();
        try {
          await player.ready;
          final took = sw.elapsedMilliseconds;
          // ignore: avoid_print
          print('[bound] first player ready after ${took}ms');
          expect(shim().counter('destroys'), 1, reason: 'the reap destroys');
          expect(
            shim().counter('destroys_done_at_create'),
            0,
            reason: 'the destroy still runs: the player did not wait for it',
          );
          expect(took, lessThan(_destroyDelayUs ~/ 1000));
        } finally {
          // The orphan's destroy already sleeps its stall; the player's own
          // destroy needs none.
          shim().set('destroy_delay_us', 0);
          await player.dispose();
        }
      },
    );
  });
}
