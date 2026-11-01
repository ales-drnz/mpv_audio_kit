// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// The manifest of the release (tool/codegen/libmpv_manifest.json, copied
// by scripts/update_libmpv.sh) names its license and the filters it
// compiled. A GPL build, or one with rubberband, is not the libmpv the
// README's Licenses section describes, so an update to such a release fails
// here. The pin is still libmpv-r19, the GPL build with Rubber Band, whose
// manifest names no license: the tests are skipped until libmpv-r20 is
// pinned.

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

void main() {
  final manifest =
      jsonDecode(File('tool/codegen/libmpv_manifest.json').readAsStringSync())
          as Map<String, dynamic>;

  test('the pinned libmpv is LGPL, version 3 or later', () {
    expect(manifest['license'], 'LGPL-3.0-or-later');
  }, skip: 'libmpv-r20 not pinned yet');

  test('the pinned libmpv has no rubberband filter', () {
    final filters = (manifest['audioFilters'] as List).cast<String>();
    expect(filters, isNotEmpty);
    expect(filters, isNot(contains('rubberband')));
  }, skip: 'libmpv-r20 not pinned yet');
}
