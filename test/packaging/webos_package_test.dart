// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

// webOS through flutter-webos, which runs no build hook: the package is an
// FFI plugin there, and webos/CMakeLists.txt bundles libmpv_webos-armv7l.so
// of the pinned release, at its SHA-256, as lib/libmpv_audio_kit_webos.so.

import 'dart:convert';
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

  // update_libmpv.sh writes an empty SHA-256 for a release without the
  // webOS libmpv, and every webOS build then fails: from libmpv-r24, the
  // first with it, the pinned manifest must have it, and the CMake file its
  // SHA-256.
  test('the webOS CMake file has the SHA-256 of the pinned manifest', () {
    final manifest =
        jsonDecode(File('tool/codegen/libmpv_manifest.json').readAsStringSync())
            as Map<String, dynamic>;
    final sha =
        (manifest['assets'] as Map<String, dynamic>)['libmpv_webos-armv7l.so']
            as String?;
    if (int.parse(libmpvRelease.substring(1)) >= 24) {
      expect(sha, isNotNull, reason: 'libmpv-$libmpvRelease has no webOS');
    }
    expect(
      _pins(Directory.current.path).split('\n').last,
      'set(MAK_LIBMPV_SHA256 "${sha ?? ''}")',
    );
  });

  test('webos ships with the package', () {
    final ignored = File('.pubignore')
        .readAsLinesSync()
        .map((l) => l.trim())
        .where((l) => RegExp(r'^/?webos(/.*)?$').hasMatch(l));
    expect(ignored, isEmpty);
  });

  // flutter-webos builds for arm, the TVs, and for arm64 with
  // --target-arch arm64. Only arm has a libmpv: an arm64 build bundled the
  // 32-bit library, and failed when the app loaded it.
  group('webos/CMakeLists.txt configured as flutter-webos does', () {
    late Directory tmp;

    setUp(() => tmp = Directory.systemTemp.createTempSync('mak_webos_cmake'));
    tearDown(() => tmp.deleteSync(recursive: true));

    /// Configures an app that adds the plugin, for [platform], with a
    /// libmpv of its own in the environment.
    ProcessResult? configure(String platform) {
      final root = Directory.current.path.replaceAll(r'\', '/');
      final lib = File('${tmp.path}/libmpv_webos-armv7l.so')
        ..writeAsStringSync('libmpv');
      File('${tmp.path}/CMakeLists.txt').writeAsStringSync('''
cmake_minimum_required(VERSION 3.10)
project(app LANGUAGES NONE)
add_subdirectory("$root/webos" plugin)
message(STATUS "BUNDLED=\${mpv_audio_kit_bundled_libraries}")
''');
      try {
        return Process.runSync(
          'cmake',
          [
            '-S',
            tmp.path,
            '-B',
            '${tmp.path}/build',
            '-DFLUTTER_TARGET_PLATFORM=$platform',
          ],
          environment: {'MPV_AUDIO_KIT_LIBMPV': lib.path},
        );
      } on ProcessException {
        if (Platform.environment['CI'] == 'true') rethrow;
        markTestSkipped('no cmake on this machine');
        return null;
      }
    }

    test('arm bundles libmpv_audio_kit_webos.so', () {
      final run = configure('webos-arm');
      if (run == null) return;
      expect(run.exitCode, 0, reason: '${run.stdout}${run.stderr}');
      expect(
        '${run.stdout}',
        matches(RegExp(r'BUNDLED=.*libmpv_audio_kit_webos\.so')),
      );
    });

    test('arm64 fails the build, naming the arch', () {
      final run = configure('webos-arm64');
      if (run == null) return;
      expect(run.exitCode, isNot(0), reason: '${run.stdout}${run.stderr}');
      expect('${run.stderr}', contains('no libmpv for webos-arm64'));
    });
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
