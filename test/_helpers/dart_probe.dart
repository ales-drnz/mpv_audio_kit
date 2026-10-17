// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// Runs a Flutter-free Dart program of the test tree in a `dart` process of
// its own. A test reaches what `flutter test` cannot give it this way: a
// build compiled with other defines (`dart.vm.profile`), a fresh process,
// a process that may crash.

import 'dart:convert';
import 'dart:io';

/// The `dart` executable of the Flutter SDK running the tests.
String dartExecutable() {
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root != null) {
    final exe = Platform.isWindows ? 'dart.exe' : 'dart';
    final sep = Platform.pathSeparator;
    final path = [root, 'bin', 'cache', 'dart-sdk', 'bin', exe].join(sep);
    if (File(path).existsSync()) return path;
  }
  return 'dart';
}

/// Runs [script] (a path relative to the package root) with [args], in a
/// `dart` process compiled with [defines] (`name=value`). [tempDir] becomes
/// the system temp directory of the process.
Future<ProcessResult> runDartProbe(
  String script, {
  List<String> args = const [],
  List<String> defines = const [],
  Directory? tempDir,
}) {
  final tmp = tempDir?.path;
  return Process.run(
    dartExecutable(),
    [for (final d in defines) '-D$d', script, ...args],
    workingDirectory: Directory.current.path,
    environment: {
      if (tmp != null) ...{'TMPDIR': tmp, 'TMP': tmp, 'TEMP': tmp},
    },
    stdoutEncoding: utf8,
    stderrEncoding: utf8,
  );
}

/// The last line of [result]'s stdout, decoded as a JSON object. Fails
/// with the process output when there is none.
Map<String, dynamic> probeReport(ProcessResult result) {
  final lines = (result.stdout as String)
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.startsWith('{'))
      .toList();
  if (result.exitCode != 0 || lines.isEmpty) {
    throw StateError(
      'probe exited ${result.exitCode} without a report\n'
      'stdout: ${result.stdout}\nstderr: ${result.stderr}',
    );
  }
  return jsonDecode(lines.last) as Map<String, dynamic>;
}
