// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

// webOS through flutter-webos, which runs no build hook: the package is an
// FFI plugin there, and webos/CMakeLists.txt bundles libmpv_webos-armv7l.so
// of the pinned release, at its SHA-256, as lib/libmpv_audio_kit.so.

import 'dart:io';

import 'package:mpv_audio_kit/src/internals/libmpv_release.dart';
import 'package:test/test.dart';

import '../_helpers/update_libmpv_fixture.dart';

/// The release and SHA-256 lines of the webOS CMake file at [root].
String _pins(String root) => File('$root/webos/CMakeLists.txt')
    .readAsLinesSync()
    .where((l) => RegExp(r'^set\(MAK_LIBMPV_(RELEASE|SHA256) ').hasMatch(l))
    .join('\n');

void main() {
  test('webOS is an FFI plugin of the package', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('      webos:\n        ffiPlugin: true\n'));
  });

  test('the webOS CMake file pins the release of the package', () {
    expect(
      _pins(Directory.current.path).split('\n').first,
      'set(MAK_LIBMPV_RELEASE "libmpv-$libmpvRelease")',
    );
  });

  test('webos ships with the package', () {
    final ignored = File('.pubignore')
        .readAsLinesSync()
        .map((l) => l.trim())
        .where((l) => RegExp(r'^/?webos(/.*)?$').hasMatch(l));
    expect(ignored, isEmpty);
  });

  group('update_libmpv.sh pins the webOS libmpv in webos/CMakeLists.txt', () {
    final root = Directory.current.path;
    late Directory package;

    setUp(() => package = packageCopy(root));
    tearDown(() => package.deleteSync(recursive: true));

    test('with the SHA-256 of the release', () async {
      final sum = 'cd' * 32;
      final manifest = await release(
        root,
        edit: (m) =>
            (m['assets'] as Map<String, dynamic>)['libmpv_webos-armv7l.so'] =
                sum,
      );
      final run = await updateLibmpv(package, manifest);
      expect(run.exitCode, 0, reason: '${run.stdout}${run.stderr}');
      expect(
        _pins(package.path),
        'set(MAK_LIBMPV_RELEASE "libmpv-r99")\n'
        'set(MAK_LIBMPV_SHA256 "$sum")',
      );
    });

    test('with none when the release has no webOS libmpv', () async {
      final manifest = await release(
        root,
        edit: (m) => (m['assets'] as Map<String, dynamic>).remove(
          'libmpv_webos-armv7l.so',
        ),
      );
      final run = await updateLibmpv(package, manifest);
      expect(run.exitCode, 0, reason: '${run.stdout}${run.stderr}');
      expect(
        _pins(package.path),
        'set(MAK_LIBMPV_RELEASE "libmpv-r99")\n'
        'set(MAK_LIBMPV_SHA256 "")',
      );
    });
  });
}
