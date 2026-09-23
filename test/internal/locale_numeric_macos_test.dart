// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

@TestOn('mac-os')
library;

import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:flutter_test/flutter_test.dart';

import '../_helpers/setter_test_helpers.dart';

void main() {
  // L1 — libmpv's API contract (mpv/client.h, player/main.c::check_locale)
  // requires LC_NUMERIC=C process-wide before any mpv_initialize call.
  // `library_loader.dart::_applyPlatformQuirks` exists solely to enforce
  // that, but the LC_* category numbers are NOT portable:
  //
  //   glibc (Linux):       LC_CTYPE=0  LC_NUMERIC=1  LC_COLLATE=3
  //   BSD libc (macOS/iOS): LC_ALL=0  LC_COLLATE=1  LC_CTYPE=2
  //                         LC_MONETARY=3  LC_NUMERIC=4
  //
  // (macOS values verified against the macOS SDK `usr/include/locale.h`.)
  // So `setlocale(1, "C")` does the right thing only on glibc; on Apple
  // platforms it silently sets LC_COLLATE and leaves LC_NUMERIC alone.
  //
  // The sibling `locale_invariant_test.dart` cannot catch this: it uses
  // category 1 for BOTH the perturbation and the read-back, so on macOS
  // it self-consistently exercises LC_COLLATE and passes regardless.
  // This file uses the platform-correct constant (4) end-to-end.
  //
  // Keep this file single-test and standalone: `ensureInitialized`
  // short-circuits on the second call within an isolate, and
  // `flutter test` gives each file its own isolate, so the quirks path
  // is guaranteed to run here. (setlocale itself is process-global —
  // tearDown restores whatever LC_NUMERIC was on entry so a shared
  // flutter_tester process is left untouched.)

  const lcNumeric = 4; // macOS/BSD LC_NUMERIC (NOT 1 — that's LC_COLLATE).

  final libc = DynamicLibrary.open('libSystem.B.dylib');

  final setlocale = libc
      .lookupFunction<
        Pointer<Utf8> Function(Int32, Pointer<Utf8>),
        Pointer<Utf8> Function(int, Pointer<Utf8>)
      >('setlocale');

  // struct lconv's first member is `char *decimal_point` (POSIX). Used
  // as a semantic sanity check that category 4 really is LC_NUMERIC on
  // this host — the exact class of mistake this file is guarding against.
  final localeconv = libc
      .lookupFunction<
        Pointer<Pointer<Utf8>> Function(),
        Pointer<Pointer<Utf8>> Function()
      >('localeconv');

  String currentNumericLocale() =>
      setlocale(lcNumeric, nullptr).cast<Utf8>().toDartString();

  String? original;

  tearDown(() {
    final o = original;
    if (o == null) return;
    using((arena) {
      setlocale(lcNumeric, o.toNativeUtf8(allocator: arena));
    });
    original = null;
  });

  test('ensureInitialized resets LC_NUMERIC (macOS category 4) to "C" '
      'from a non-C locale', () {
    original = currentNumericLocale();

    // Perturb LC_NUMERIC to a comma-decimal locale. de_DE ships on
    // stock macOS; fr_FR is the fallback.
    const candidates = ['de_DE.UTF-8', 'fr_FR.UTF-8'];
    String? perturbed;
    for (final c in candidates) {
      final r = using(
        (arena) => setlocale(lcNumeric, c.toNativeUtf8(allocator: arena)),
      );
      if (r != nullptr) {
        perturbed = r.cast<Utf8>().toDartString();
        break;
      }
    }
    if (perturbed == null) {
      markTestSkipped(
        'Neither of $candidates is installed on this host (`locale -a`) — '
        'cannot perturb LC_NUMERIC to a non-C value.',
      );
      return;
    }

    // Sanity 1: the perturbation landed.
    expect(
      currentNumericLocale(),
      equals(perturbed),
      reason:
          'precondition: LC_NUMERIC must read back as the perturbed '
          'locale before exercising the package',
    );

    // Sanity 2: category 4 is semantically LC_NUMERIC on this host —
    // a comma-decimal locale must flip lconv.decimal_point to ",".
    expect(
      localeconv()[0].toDartString(),
      equals(','),
      reason:
          'precondition: setting category 4 to $perturbed must change '
          'the numeric decimal point — otherwise 4 is not LC_NUMERIC here '
          'and this test is testing the wrong category',
    );

    // The exact code path consumers hit on init
    // (MpvAudioKit.ensureInitialized → _applyPlatformQuirks).
    final skip = libmpvSkipReason();
    if (skip != null) {
      markTestSkipped(skip);
      return;
    }
    initLibmpv();

    expect(
      currentNumericLocale(),
      equals('C'),
      reason:
          'ensureInitialized() must force LC_NUMERIC to "C" on macOS. '
          'libmpv\'s API contract (client.h, player/main.c::check_locale) '
          'requires it — a comma-decimal LC_NUMERIC breaks float parsing '
          'inside mpv/ffmpeg. setlocale(1, "C") only does this on glibc; '
          'on macOS/iOS category 1 is LC_COLLATE and LC_NUMERIC is 4.',
    );
  });
}
