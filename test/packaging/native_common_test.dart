// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:io';

import 'package:test/test.dart';

/// The Windows and Linux plugins share one header for the multi engine
/// rule of the media session, native_common/engine_ownership.h: each
/// CMakeLists adds the folder beside it, so the rule exists once. Paths are
/// relative to the package root, the working directory under
/// `flutter test`.
void main() {
  const header = 'native_common/engine_ownership.h';
  const include = r'"${CMAKE_CURRENT_SOURCE_DIR}/../native_common"';
  const users = {
    'windows': 'windows/media_session_channel_win.cpp',
    'linux': 'linux/mpv_audio_kit_plugin.cc',
  };

  test('the header is a real file in native_common', () {
    // dart pub publish stores a symlink as a file holding the link path.
    expect(File(header).existsSync(), isTrue);
    expect(FileSystemEntity.isLinkSync(header), isFalse);
  });

  test('both plugins include it from native_common, with no copy', () {
    for (final MapEntry(key: os, value: source) in users.entries) {
      expect(
        File('$os/CMakeLists.txt').readAsStringSync(),
        contains(include),
        reason: '$os/CMakeLists.txt does not add native_common',
      );
      expect(
        File(source).readAsStringSync(),
        contains('#include "engine_ownership.h"'),
      );
      final copies = Directory(os)
          .listSync(recursive: true)
          .where((e) => e.path.endsWith('engine_ownership.h'));
      expect(copies, isEmpty, reason: 'a copy of the header in $os/');
    }
  });

  test('native_common ships with the package', () {
    final ignored = File('.pubignore')
        .readAsLinesSync()
        .map((l) => l.trim())
        .where((l) => RegExp(r'^/?native_common(/.*)?$').hasMatch(l));
    expect(ignored, isEmpty);
  });
}
