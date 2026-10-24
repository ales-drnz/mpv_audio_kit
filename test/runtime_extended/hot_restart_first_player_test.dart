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

/// Stall injected in front of `mpv_terminate_destroy`: the orphaned core
/// closes its audio output slowly, as a busy device does.
const int _destroyDelayUs = 300 * 1000;

void main() {
  // The tracker and ensureInitialized run once per process, and each test
  // file of `flutter test` has a process of its own: this file stands for
  // one Hot Restart.
  slowCoreShimSuite(initialize: false, (shim) {
    // F220: the reap destroyed the cores of the replaced VM 500 ms after
    // ensureInitialized, and nothing held the new VM's players meanwhile.
    // A player opened right away initialized its audio output while the
    // orphan still held the device: an exclusive output failed.
    test('after a Hot Restart the first player creates its core once the '
        'orphaned ones are destroyed', () async {
      // The VM the Hot Restart replaced: a core it never disposed, listed
      // in the buffer its tracker published in the process environment.
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
      final previousVm = OrphanHandleTracker.forTesting(
        ProcessEnvironment.native(),
      )..ensureInitialized((_) {});
      previousVm.add(orphan);
      // add() writes the slot once the tracker's init future resolves.
      await Future<void>.delayed(Duration.zero);
      shim().set('destroy_delay_us', _destroyDelayUs);

      // The new VM: ensureInitialized finds the orphan, and the app
      // creates its first player right away.
      MpvAudioKit.ensureInitialized(libmpv: shim().path);
      final player = await buildPlayer();
      try {
        await player.ready;
        expect(shim().counter('destroys'), 1, reason: 'the orphan is reaped');
        expect(
          shim().counter('destroys_done_at_create'),
          1,
          reason:
              'the new core was created while the orphan still held its '
              'audio output',
        );
      } finally {
        await player.dispose();
      }
    });
  });
}
