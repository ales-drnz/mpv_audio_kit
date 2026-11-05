// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// A release r99 like the Build of libmpv-scripts makes it, and a copy of
// the files scripts/update_libmpv.sh reads and writes, so the packaging
// tests run the script offline.

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:mpv_audio_kit/src/internals/libmpv_release.dart';
import 'package:test/test.dart';

/// The three files of the web module.
const webFiles = ['libmpv.mjs', 'libmpv.wasm', 'mak_webaudio_processor.js'];

/// The licenses.zip of a release with a web/ target only.
const webOnlyLicenses = {
  'web/README.txt': 'libmpv r99 for web: LGPL-3.0-or-later\n',
};

String sha(List<int> bytes) => sha256.convert(bytes).toString();

/// A copy of what update_libmpv.sh reads and writes, in a new directory.
Directory packageCopy(String root) {
  final dir = Directory.systemTemp.createTempSync('mak_web_pkg');
  for (final path in [
    'scripts/update_libmpv.sh',
    'scripts/web_module.py',
    'hook/build.dart',
    'tvos/Package.swift',
    'lib/src/internals/libmpv_release.dart',
    'lib/src/internals/libmpv_licenses.dart',
    'tool/codegen/libmpv_manifest.json',
  ]) {
    final to = File('${dir.path}/$path')..parent.createSync(recursive: true);
    File('$root/$path').copySync(to.path);
  }
  return dir;
}

Future<void> _zip(String zip, Directory from) async {
  final run = await Process.run('python3', [
    '-c',
    'import os, sys, zipfile\n'
        'root = sys.argv[2]\n'
        'with zipfile.ZipFile(sys.argv[1], "w") as z:\n'
        '    for d, _, names in sorted(os.walk(root)):\n'
        '        for n in sorted(names):\n'
        '            p = os.path.join(d, n)\n'
        '            z.write(p, os.path.relpath(p, root).replace(os.sep, "/"))\n',
    zip,
    from.path,
  ]);
  expect(run.exitCode, 0, reason: '${run.stderr}');
}

/// A release r99 in a new directory: the pinned manifest of the package
/// with libmpv_web.zip (the three files and build_web.json) and
/// licenses.zip ([licenses], by path in the zip) added, as
/// write_manifest.sh lists them. [edit] changes the manifest before it is
/// written; [zipNames] renames entries of libmpv_web.zip.
Future<File> release(
  String root, {
  void Function(Map<String, dynamic> manifest)? edit,
  Map<String, String> zipNames = const {},
  Map<String, String> licenses = webOnlyLicenses,
}) async {
  final dir = Directory.systemTemp.createTempSync('mak_web_release');
  final contents = {
    for (final name in webFiles) name: utf8.encode('$name of r99\n'),
    'build_web.json': utf8.encode('{"release": "r99", "target": "web"}\n'),
  };
  final unpacked = Directory('${dir.path}/unpacked')..createSync();
  for (final MapEntry(:key, :value) in contents.entries) {
    File('${unpacked.path}/${zipNames[key] ?? key}').writeAsBytesSync(value);
  }
  await _zip('${dir.path}/libmpv_web.zip', unpacked);
  final texts = Directory('${dir.path}/licenses')..createSync();
  for (final MapEntry(:key, :value) in licenses.entries) {
    File('${texts.path}/$key')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(value);
  }
  await _zip('${dir.path}/licenses.zip', texts);
  final manifest =
      jsonDecode(
            File('$root/tool/codegen/libmpv_manifest.json').readAsStringSync(),
          )
          as Map<String, dynamic>;
  manifest['release'] = 'r99';
  (manifest['assets'] as Map<String, dynamic>)['libmpv_web.zip'] = sha(
    File('${dir.path}/libmpv_web.zip').readAsBytesSync(),
  );
  manifest['web'] = {
    'asset': 'libmpv_web.zip',
    'abi': webModuleAbi,
    'webaudioAbi': 1,
    'emscripten': '6.0.12',
    'files': {for (final name in webFiles) name: sha(contents[name]!)},
  };
  manifest['licenses'] = {
    'asset': 'licenses.zip',
    'sha256': sha(File('${dir.path}/licenses.zip').readAsBytesSync()),
  };
  edit?.call(manifest);
  return File('${dir.path}/manifest.json')
    ..writeAsStringSync(const JsonEncoder.withIndent('  ').convert(manifest));
}

/// The bash that runs the script. On Windows a bare `bash` is the WSL
/// launcher of System32, which the process search finds before PATH: the
/// one of Git for Windows is taken instead, from where git lives.
final String _bash = () {
  if (!Platform.isWindows) return 'bash';
  // The exec path is <git>/mingw64/libexec/git-core; the bash is
  // <git>/bin/bash.exe.
  final exec = Process.runSync('git', ['--exec-path']);
  final git = Directory(
    (exec.stdout as String).trim(),
  ).parent.parent.parent.path;
  final bash = File('$git/bin/bash.exe');
  if (!bash.existsSync()) {
    throw StateError('no bash of Git for Windows at ${bash.path}');
  }
  return bash.path;
}();

/// [path] as the bash of [_bash] reads it: with forward slashes on Windows.
String _bashPath(String path) =>
    Platform.isWindows ? path.replaceAll(r'\', '/') : path;

/// Runs the update_libmpv.sh of [package] on r99 from [manifest].
Future<ProcessResult> updateLibmpv(Directory package, File manifest) =>
    Process.run(_bash, [
      _bashPath('${package.path}/scripts/update_libmpv.sh'),
      'r99',
      _bashPath(manifest.path),
    ]);
