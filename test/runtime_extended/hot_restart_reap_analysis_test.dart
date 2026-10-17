// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/src/internals/library_loader.dart';
import 'package:mpv_audio_kit/src/mpv_bindings.dart';

import '../_helpers/setter_test_helpers.dart';

void main() {
  // The waveform, the loudness scan and the analyzer taps are switched on
  // and off process-wide in libmpv. A Hot Restart skips the old VM's
  // dispose, so whatever its listeners armed stayed on for the new VM,
  // whose players then decoded every file they opened for nobody (F158).
  // The cores here stand for the old VM's leaked player and the new one.
  analysisSuite(() {
    late MpvLibrary lib;
    setUpAll(() => lib = MpvLibrary.open());

    Pointer<MpvHandle> core() {
      final h = lib.mpvCreate();
      using((arena) {
        for (final (name, value) in [('ao', 'null'), ('idle', 'yes')]) {
          lib.mpvSetOptionString(
            h,
            name.toNativeUtf8(allocator: arena),
            value.toNativeUtf8(allocator: arena),
          );
        }
      });
      expect(lib.mpvInitialize(h), greaterThanOrEqualTo(0));
      return h;
    }

    void set(Pointer<MpvHandle> h, String name, String value) => using(
      (arena) => expect(
        lib.mpvSetPropertyString(
          h,
          name.toNativeUtf8(allocator: arena),
          value.toNativeUtf8(allocator: arena),
        ),
        0,
        reason: 'set $name',
      ),
    );

    String? get(Pointer<MpvHandle> h, String name) => using((arena) {
      final p = lib.mpvGetPropertyString(
        h,
        name.toNativeUtf8(allocator: arena),
      );
      if (p == nullptr) return null;
      final s = p.cast<Utf8>().toDartString();
      lib.mpvFree(p.cast());
      return s;
    });

    test('the reap turns off the analysis the old VM left on', () async {
      final old = core();
      set(old, 'waveform-enabled', 'yes');
      set(old, 'loudness-scan-enabled', 'yes');
      set(old, 'analyzer-taps', 'eq');
      expect(get(old, 'analyzer-taps'), 'eq');

      // The new VM's first player comes up while the reap waits to destroy.
      final reaping = reapOrphanedHandles(lib, [
        old,
      ], delay: const Duration(milliseconds: 200));
      final fresh = core();
      try {
        expect(get(fresh, 'waveform-enabled'), 'no');
        expect(get(fresh, 'loudness-scan-enabled'), 'no');
        expect(get(fresh, 'analyzer-taps'), anyOf(isNull, isEmpty));
      } finally {
        await reaping;
        // Process-wide: leave them off for the next test of this process.
        set(fresh, 'loudness-scan-enabled', 'no');
        set(fresh, 'waveform-enabled', 'no');
        set(fresh, 'analyzer-taps', '');
        lib.mpvTerminateDestroy(fresh);
      }
    });
  });
}
