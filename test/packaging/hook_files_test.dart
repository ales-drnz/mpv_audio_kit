// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

// pub.dev takes hooks as experimental: an upload with any file of hook/
// other than the hook scripts is refused ("Hook files are experimental and
// `hook/src/hook_download.dart` is not allowed yet"), which no check of
// `dart pub publish --dry-run` shows. The code the hook shares lives in lib.

@TestOn('vm')
library;

import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('hook holds only the hook scripts pub.dev takes', () {
    final files = [
      for (final entity in Directory('hook').listSync(recursive: true))
        if (entity is File) entity.path.replaceAll(r'\', '/'),
    ]..sort();
    expect(
      files.where((f) => f != 'hook/build.dart' && f != 'hook/link.dart'),
      isEmpty,
      reason: 'hook/ has $files',
    );
  });
}
