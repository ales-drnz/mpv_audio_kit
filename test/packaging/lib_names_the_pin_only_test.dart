// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

// Each version of the package runs on the libmpv of its pin only, so lib
// keeps no code or note for another release: no `libmpv-rN`, no `+rN` and
// no version of libmpv-scripts other than the pin.

@TestOn('vm')
library;

import 'dart:io';

import 'package:mpv_audio_kit/src/internals/libmpv_release.dart';
import 'package:test/test.dart';

void main() {
  test('lib names no libmpv release but the pin', () {
    final release = RegExp(r'(?:libmpv-|\+)(r\d+)\b');
    final scripts = RegExp(r'libmpv-scripts \d+\.\d+');
    final found = <String>[];
    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        final other = release
            .allMatches(line)
            .any((m) => m.group(1) != libmpvRelease);
        if (other || scripts.hasMatch(line)) {
          found.add('${file.path}:${i + 1}: ${line.trim()}');
        }
      }
    }
    expect(found, isEmpty, reason: found.join('\n'));
  });
}
