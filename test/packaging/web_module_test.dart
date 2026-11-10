// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// The delivery of the web module: web/ is a web asset folder of the
// package, its three files stay out of git and go into the published
// package, and scripts/update_libmpv.sh installs them from the release's
// libmpv_web.zip only once the zip, the ABI and every file match the
// manifest. The script runs offline on a copy of the files it touches,
// against a release made here. From libmpv-r20 on the pinned manifest
// names the module, which CI's browser tests take.

import 'dart:convert';
import 'dart:io';

import 'package:mpv_audio_kit/src/internals/libmpv_release.dart';
import 'package:test/test.dart';

import '../_helpers/release_gate.dart' show releaseNumber;
import '../_helpers/update_libmpv_fixture.dart';

void main() {
  final root = Directory.current.path;

  test(
    'pubspec ships web/ as a web asset folder, Flutter 3.38.10 or later',
    () {
      // A Windows checkout may end the lines with CRLF (core.autocrlf).
      final pubspec = File(
        '$root/pubspec.yaml',
      ).readAsStringSync().replaceAll('\r\n', '\n');
      expect(pubspec, contains("flutter: '>=3.38.10'"));
      expect(
        pubspec,
        matches(RegExp(r'assets:\n\s+- path: web/\n\s+platforms: \[web\]\n')),
      );
      expect(Directory('$root/web').existsSync(), isTrue);
    },
  );

  test('git ignores the web module, the published package keeps it', () {
    final ignored = Process.runSync('git', [
      'check-ignore',
      ...[for (final name in webFiles) 'web/$name'],
    ], workingDirectory: root);
    expect(LineSplitter.split(ignored.stdout as String), [
      for (final name in webFiles) 'web/$name',
    ]);
    // A .pubignore replaces the .gitignore of its folder for pub: the root
    // one has no rule for the three files, and web/ has neither file.
    final pubignore = File('$root/.pubignore').readAsLinesSync();
    expect(
      pubignore.where((l) => l.startsWith('/web') || l.startsWith('web')),
      ['/web/.gitkeep'],
    );
    expect(File('$root/web/.gitignore').existsSync(), isFalse);
    expect(File('$root/web/.pubignore').existsSync(), isFalse);
  });

  // CI skips the browser tests only on a libmpv before the first release
  // with a web module (scripts/ci/web_module.sh), so a pin from that
  // release on must come with its module.
  test('the pinned manifest is the one of libmpvRelease, with the web '
      'module from libmpv-r20 on', () {
    final manifest =
        jsonDecode(
              File(
                '$root/tool/codegen/libmpv_manifest.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    expect(manifest['release'], libmpvRelease);
    final script = File('$root/scripts/ci/web_module.sh').readAsStringSync();
    final first = RegExp(
      r'^first_web_release=(\d+)$',
      multiLine: true,
    ).firstMatch(script)?.group(1);
    expect(first, '20');
    if (releaseNumber(libmpvRelease)! >= int.parse(first!)) {
      expect(
        manifest['web'],
        isNotNull,
        reason:
            'libmpv-$libmpvRelease is pinned without its web module, and '
            'CI would not run the browser tests',
      );
    }
  });

  test('the web files in web/, when there, are those of the pinned '
      'manifest', () {
    final manifest =
        jsonDecode(
              File(
                '$root/tool/codegen/libmpv_manifest.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final web = manifest['web'] as Map<String, dynamic>?;
    if (web == null) {
      markTestSkipped('libmpv-$libmpvRelease has no web module');
      return;
    }
    expect(web['abi'], webModuleAbi);
    for (final MapEntry(:key, :value)
        in (web['files'] as Map<String, dynamic>).entries) {
      final file = File('$root/web/$key');
      if (!file.existsSync()) continue;
      expect(sha(file.readAsBytesSync()), value, reason: key);
    }
  });

  group('update_libmpv.sh', () {
    late Directory package;

    setUp(() => package = packageCopy(root));
    tearDown(() => package.deleteSync(recursive: true));

    String read(String path) =>
        File('${package.path}/$path').readAsStringSync();

    test('installs the web module of the release with the pins', () async {
      final manifest = await release(root);
      final run = await updateLibmpv(package, manifest);
      expect(run.exitCode, 0, reason: '${run.stdout}${run.stderr}');
      for (final name in webFiles) {
        expect(read('web/$name'), '$name of r99\n');
      }
      expect(File('${package.path}/web/build_web.json').existsSync(), isFalse);
      expect(
        read('lib/src/internals/libmpv_release.dart'),
        contains("const String libmpvRelease = 'r99';"),
      );
      expect(read('tool/codegen/libmpv_manifest.json'), contains('"web"'));
    });

    Map<String, dynamic> web(Map<String, dynamic> m) =>
        m['web'] as Map<String, dynamic>;
    Map<String, dynamic> files(Map<String, dynamic> m) =>
        web(m)['files'] as Map<String, dynamic>;

    // Each release, and what the refusal says about it.
    final refusals = <String, (Future<File> Function(), String)>{
      'a release without a web module': (
        () => release(root, edit: (m) => m.remove('web')),
        'libmpv-r99 has no web module',
      ),
      'a web module of another ABI': (
        () => release(root, edit: (m) => web(m)['abi'] = webModuleAbi + 1),
        'has ABI ${webModuleAbi + 1}, and the package drives ABI $webModuleAbi',
      ),
      'a zip that is not the one of the manifest': (
        () => release(
          root,
          edit: (m) => (m['assets'] as Map<String, dynamic>)['libmpv_web.zip'] =
              '0' * 64,
        ),
        'is not the ${'0' * 64} of the manifest',
      ),
      'a file that is not the one of the manifest': (
        () => release(root, edit: (m) => files(m)['libmpv.wasm'] = '0' * 64),
        'libmpv.wasm has SHA-256',
      ),
      'a zip without a listed file': (
        () => release(
          root,
          zipNames: {'mak_webaudio_processor.js': 'processor.js'},
        ),
        'libmpv_web.zip has no mak_webaudio_processor.js',
      ),
      'a listed name outside web/': (
        () => release(root, edit: (m) => files(m)['../libmpv.mjs'] = '0' * 64),
        "'../libmpv.mjs' is not a plain file name",
      ),
    };
    for (final MapEntry(key: what, value: (release, reason))
        in refusals.entries) {
      test('refuses $what and writes nothing', () async {
        final before = {
          for (final path in [
            'hook/build.dart',
            'tvos/Package.swift',
            'lib/src/internals/libmpv_release.dart',
          ])
            path: read(path),
        };
        final run = await updateLibmpv(package, await release());
        expect(run.exitCode, isNot(0), reason: '${run.stdout}');
        expect(run.stderr, contains(reason));
        for (final MapEntry(:key, :value) in before.entries) {
          expect(read(key), value, reason: key);
        }
        expect(Directory('${package.path}/web').existsSync(), isFalse);
      });
    }
  });
}
