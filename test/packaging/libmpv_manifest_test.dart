// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// The manifest of the release (tool/codegen/libmpv_manifest.json, copied
// by scripts/update_libmpv.sh) names its license and the filters it
// compiled. A GPL build, or one with rubberband, is not the libmpv the
// README's Licenses section describes, so an update to such a release fails
// here. Up to libmpv-r19, the GPL build with Rubber Band, the manifest
// names no license: the tests skip those, and libmpv-r20 turns them on.

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

void main() {
  final manifest =
      jsonDecode(File('tool/codegen/libmpv_manifest.json').readAsStringSync())
          as Map<String, dynamic>;
  final gplPin = manifest['license'] == null
      ? 'libmpv-${manifest['release']} predates the LGPL builds'
      : null;

  test('the pinned libmpv is LGPL, version 3 or later', () {
    expect(manifest['license'], 'LGPL-3.0-or-later');
  }, skip: gplPin);

  test('the pinned libmpv has no rubberband filter', () {
    final filters = (manifest['audioFilters'] as List).cast<String>();
    expect(filters, isNotEmpty);
    expect(filters, isNot(contains('rubberband')));
  }, skip: gplPin);
}
