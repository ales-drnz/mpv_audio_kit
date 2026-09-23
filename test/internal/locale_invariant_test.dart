// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

@TestOn('mac-os || linux')
library;

import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter_test/flutter_test.dart';

import '../_helpers/setter_test_helpers.dart';

void main() {
  // L1 — libmpv's API contract (mpv/client.h, player/main.c::check_locale)
  // requires LC_NUMERIC=C process-wide before any mpv_initialize call.
  // This is documented in `library_loader.dart::_applyPlatformQuirks`
  // alongside the rationale for why thread-local `uselocale` is NOT a
  // valid substitute (mpv spawns its own pthreads which inherit
  // LC_GLOBAL_LOCALE, not the caller's uselocale state).
  //
  // The naive test "is LC_NUMERIC == C after ensureInitialized?" is
  // weak: a Dart VM process starts with LC_NUMERIC=C by default, so
  // the test would pass even if `_applyPlatformQuirks` did nothing.
  // To make the test meaningful, we force LC_NUMERIC to a non-C
  // locale BEFORE calling ensureInitialized, then verify that
  // ensureInitialized has reset it back to "C". A future change that
  // drops the setlocale (or moves to an ineffective thread-local
  // variant) breaks this assertion.
  //
  // Keep this file single-test: `ensureInitialized` short-circuits on
  // the second call, which would skip `_applyPlatformQuirks`.

  final libc = Platform.isLinux
      ? DynamicLibrary.open('libc.so.6')
      : DynamicLibrary.open('libSystem.B.dylib');

  final setlocale = libc
      .lookupFunction<
        Pointer<Utf8> Function(Int32, Pointer<Utf8>),
        Pointer<Utf8> Function(int, Pointer<Utf8>)
      >('setlocale');

  // libc-specific constant: 1 on Linux glibc, 4 on macOS/iOS (BSD
  // layout, where 1 is LC_COLLATE). Using the wrong one here would make
  // this test perturb and read back a different category than the one
  // `_applyPlatformQuirks` enforces, passing regardless of the fix.
  final lcNumeric = Platform.isLinux ? 1 : 4;

  test(
    'ensureInitialized resets LC_NUMERIC to "C" even from a non-C locale',
    () {
      // Try a few likely-installed locales. macOS test runners usually
      // ship `en_US.UTF-8`; CI Linux images often have it too. If none
      // succeed, skip — we'd be testing nothing.
      final candidates = ['en_US.UTF-8', 'C.UTF-8', 'de_DE.UTF-8'];
      String? installed;
      for (final c in candidates) {
        final r = using(
          (arena) => setlocale(lcNumeric, c.toNativeUtf8(allocator: arena)),
        );
        if (r != nullptr) {
          installed = r.cast<Utf8>().toDartString();
          if (installed != 'C') break;
        }
      }
      if (installed == null || installed == 'C') {
        markTestSkipped(
          'No non-C locale available on this host — cannot test the '
          'reset path. Install one of $candidates and re-run.',
        );
        return;
      }

      // Sanity: precondition met.
      final pre = setlocale(lcNumeric, nullptr).cast<Utf8>().toDartString();
      expect(
        pre,
        isNot('C'),
        reason: 'precondition: must enter the test in a non-C locale',
      );

      initLibmpvOrSkip();

      final post = setlocale(lcNumeric, nullptr).cast<Utf8>().toDartString();
      expect(
        post,
        equals('C'),
        reason:
            'ensureInitialized() must reset LC_NUMERIC to "C" '
            'process-wide. libmpv requires this; if you switched to '
            'thread-local uselocale, libmpv\'s own threads will fail '
            'to parse floats correctly. See client.h:147-149 and '
            'player/main.c::check_locale in mpv 0.41.0.',
      );
    },
  );
}
