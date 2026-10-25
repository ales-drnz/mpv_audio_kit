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

import 'package:crypto/crypto.dart';
import 'package:mpv_audio_kit/src/internals/libmpv_release.dart';
import 'package:test/test.dart';

import '../_helpers/release_gate.dart' show releaseNumber;

const _webFiles = ['libmpv.mjs', 'libmpv.wasm', 'mak_webaudio_processor.js'];

String _sha(List<int> bytes) => sha256.convert(bytes).toString();

/// A copy of what update_libmpv.sh reads and writes, in a new directory.
Directory _packageCopy(String root) {
  final dir = Directory.systemTemp.createTempSync('mak_web_pkg');
  for (final path in [
    'scripts/update_libmpv.sh',
    'scripts/web_module.py',
    'hook/build.dart',
    'lib/src/internals/libmpv_release.dart',
    'tool/codegen/libmpv_manifest.json',
  ]) {
    final to = File('${dir.path}/$path')..parent.createSync(recursive: true);
    File('$root/$path').copySync(to.path);
  }
  return dir;
}

/// A release r99 like the Build makes it, in a new directory: the pinned
/// manifest of the package with libmpv_web.zip (the three files and
/// build_web.json) added, as write_manifest.sh lists it. [edit] changes
/// the manifest before it is written; [zipNames] renames entries of the
/// zip.
Future<File> _release(
  String root, {
  void Function(Map<String, dynamic> manifest)? edit,
  Map<String, String> zipNames = const {},
}) async {
  final dir = Directory.systemTemp.createTempSync('mak_web_release');
  final contents = {
    for (final name in _webFiles) name: utf8.encode('$name of r99\n'),
    'build_web.json': utf8.encode('{"release": "r99", "target": "web"}\n'),
  };
  final unpacked = Directory('${dir.path}/unpacked')..createSync();
  for (final MapEntry(:key, :value) in contents.entries) {
    File('${unpacked.path}/${zipNames[key] ?? key}').writeAsBytesSync(value);
  }
  final zip = await Process.run('python3', [
    '-c',
    'import os, sys, zipfile\n'
        'with zipfile.ZipFile(sys.argv[1], "w") as z:\n'
        '    for n in sorted(os.listdir(sys.argv[2])):\n'
        '        z.write(os.path.join(sys.argv[2], n), n)\n',
    '${dir.path}/libmpv_web.zip',
    unpacked.path,
  ]);
  expect(zip.exitCode, 0, reason: '${zip.stderr}');
  final manifest =
      jsonDecode(
            File('$root/tool/codegen/libmpv_manifest.json').readAsStringSync(),
          )
          as Map<String, dynamic>;
  manifest['release'] = 'r99';
  (manifest['assets'] as Map<String, dynamic>)['libmpv_web.zip'] = _sha(
    File('${dir.path}/libmpv_web.zip').readAsBytesSync(),
  );
  manifest['web'] = {
    'asset': 'libmpv_web.zip',
    'abi': webModuleAbi,
    'webaudioAbi': 1,
    'emscripten': '6.0.12',
    'files': {for (final name in _webFiles) name: _sha(contents[name]!)},
  };
  edit?.call(manifest);
  return File('${dir.path}/manifest.json')
    ..writeAsStringSync(const JsonEncoder.withIndent('  ').convert(manifest));
}

Future<ProcessResult> _update(Directory package, File manifest) => Process.run(
  'bash',
  ['${package.path}/scripts/update_libmpv.sh', 'r99', manifest.path],
);

void main() {
  final root = Directory.current.path;

  test('pubspec ships web/ as a web asset folder, Flutter 3.41 or later', () {
    final pubspec = File('$root/pubspec.yaml').readAsStringSync();
    expect(pubspec, contains("flutter: '>=3.41.0'"));
    expect(
      pubspec,
      matches(RegExp(r'assets:\n\s+- path: web/\n\s+platforms: \[web\]\n')),
    );
    expect(Directory('$root/web').existsSync(), isTrue);
  });

  test('git ignores the web module, the published package keeps it', () {
    final ignored = Process.runSync('git', [
      'check-ignore',
      ...[for (final name in _webFiles) 'web/$name'],
    ], workingDirectory: root);
    expect(LineSplitter.split(ignored.stdout as String), [
      for (final name in _webFiles) 'web/$name',
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
      expect(_sha(file.readAsBytesSync()), value, reason: key);
    }
  });

  group('update_libmpv.sh', () {
    late Directory package;

    setUp(() => package = _packageCopy(root));
    tearDown(() => package.deleteSync(recursive: true));

    String read(String path) =>
        File('${package.path}/$path').readAsStringSync();

    test('installs the web module of the release with the pins', () async {
      final manifest = await _release(root);
      final run = await _update(package, manifest);
      expect(run.exitCode, 0, reason: '${run.stdout}${run.stderr}');
      for (final name in _webFiles) {
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
        () => _release(root, edit: (m) => m.remove('web')),
        'libmpv-r99 has no web module',
      ),
      'a web module of another ABI': (
        () => _release(root, edit: (m) => web(m)['abi'] = webModuleAbi + 1),
        'has ABI ${webModuleAbi + 1}, and the package drives ABI $webModuleAbi',
      ),
      'a zip that is not the one of the manifest': (
        () => _release(
          root,
          edit: (m) => (m['assets'] as Map<String, dynamic>)['libmpv_web.zip'] =
              '0' * 64,
        ),
        'is not the ${'0' * 64} of the manifest',
      ),
      'a file that is not the one of the manifest': (
        () => _release(root, edit: (m) => files(m)['libmpv.wasm'] = '0' * 64),
        'libmpv.wasm has SHA-256',
      ),
      'a zip without a listed file': (
        () => _release(
          root,
          zipNames: {'mak_webaudio_processor.js': 'processor.js'},
        ),
        'libmpv_web.zip has no mak_webaudio_processor.js',
      ),
      'a listed name outside web/': (
        () => _release(root, edit: (m) => files(m)['../libmpv.mjs'] = '0' * 64),
        "'../libmpv.mjs' is not a plain file name",
      ),
    };
    for (final MapEntry(key: what, value: (release, reason))
        in refusals.entries) {
      test('refuses $what and writes nothing', () async {
        final before = {
          for (final path in [
            'hook/build.dart',
            'lib/src/internals/libmpv_release.dart',
          ])
            path: read(path),
        };
        final run = await _update(package, await release());
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
