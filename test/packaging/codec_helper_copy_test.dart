// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:test/test.dart';

/// The codec coverage helper exists twice, once for the host suite and
/// once for the device app, which cannot import from test/. A fix made in
/// one copy only (the Windows path one was) leaves the device test
/// checking something else.
void main() {
  test('the test_app copy of the codec helper matches the host one', () {
    final root = Directory.current.path;
    final host = File('$root/test/_helpers/codec.dart').readAsStringSync();
    final device = File(
      '$root/test_app/integration_test/_helpers/codec.dart',
    ).readAsStringSync();
    expect(device, host);
  });
}
