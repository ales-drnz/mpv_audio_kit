// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// MpvAudioKit.ensureInitialized registers the license texts of the bundled
// libmpv with Flutter's LicenseRegistry, once, so showLicensePage lists
// them; with none (before libmpv-r20) it registers nothing.

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/src/internals/libmpv_license_registry.dart';
import 'package:mpv_audio_kit/src/internals/libmpv_licenses.dart';

Future<List<LicenseEntry>> _registered() => LicenseRegistry.licenses.toList();

void main() {
  setUp(() {
    LicenseRegistry.reset();
    resetLibmpvLicenseRegistration();
  });
  tearDown(LicenseRegistry.reset);

  test('registers each text under its packages, once', () async {
    const entries = [
      (['libmpv'], 'libmpv r99 for web: LGPL-3.0-or-later\n'),
      (['FFmpeg'], 'GNU LESSER GENERAL PUBLIC LICENSE\n\nVersion 3\n'),
      (['OpenSSL'], 'Apache License\n'),
    ];
    registerLibmpvLicenses(entries: entries);
    registerLibmpvLicenses(entries: entries);
    final registered = await _registered();
    expect(registered.map((e) => e.packages.toList()), [
      ['libmpv'],
      ['FFmpeg'],
      ['OpenSSL'],
    ]);
    expect(registered[1].paragraphs.map((p) => p.text), [
      'GNU LESSER GENERAL PUBLIC LICENSE',
      'Version 3',
    ]);
  });

  test('registers nothing without texts', () async {
    registerLibmpvLicenses(entries: const []);
    expect(await _registered(), isEmpty);
  });

  test('registers the generated texts, none before libmpv-r20', () async {
    registerLibmpvLicenses();
    final registered = await _registered();
    expect(registered, hasLength(libmpvLicenses.length));
    if (libmpvLicenses.isNotEmpty) {
      expect(registered.first.packages, ['libmpv']);
    }
  });
}
