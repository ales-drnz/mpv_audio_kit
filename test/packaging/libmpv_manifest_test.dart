// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// The libmpv the package pins is the LGPL build of libmpv-scripts. The
// manifest of the release (tool/codegen/libmpv_manifest.json, which
// scripts/update_libmpv.sh copies from it) names its license and the
// filters it compiled; a GPL build, or one with rubberband, would make the
// package's apps GPL without a word, so an update to such a release fails
// here.

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

void main() {
  final manifest =
      jsonDecode(File('tool/codegen/libmpv_manifest.json').readAsStringSync())
          as Map<String, dynamic>;

  test('the pinned libmpv is LGPL, version 3 or later', () {
    expect(manifest['license'], 'LGPL-3.0-or-later');
  });

  test('the pinned libmpv has no rubberband filter', () {
    final filters = (manifest['audioFilters'] as List).cast<String>();
    expect(filters, isNotEmpty);
    expect(filters, isNot(contains('rubberband')));
  });
}
