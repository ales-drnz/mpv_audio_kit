// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// The build hook on Tizen through flutter-tizen, which writes target_os
// linux with the arch of the Tizen build. arm, the TVs, is an arch Flutter's
// own Linux desktop never builds, so it takes libmpv_tizen-armv7l.so by
// itself. x64, the TV emulator, is the desktop's arch too: the app says
// Tizen with the user define tizen: true. Each Tizen asset is bundled as
// libmpv_audio_kit.so like the Linux one.

import 'dart:convert';
import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:crypto/crypto.dart';
import 'package:hooks/hooks.dart';
import 'package:test/test.dart';

/// Runs hook/build.dart for linux on [arch], with the libmpv user define
/// at [libmpvDir] when given and the tizen one when [tizen] is not false,
/// and returns its exit and its output.
Future<(ProcessResult, BuildOutput?)> _runHook(
  Directory tmp,
  Architecture arch, {
  Directory? libmpvDir,
  Object tizen = false,
}) async {
  final shared = Directory('${tmp.path}/shared')..createSync();
  final out = Directory('${tmp.path}/out')..createSync();
  final outputFile = File('${tmp.path}/output.json');
  final builder = BuildInputBuilder()
    ..setupShared(
      packageRoot: Directory.current.uri,
      packageName: 'mpv_audio_kit',
      outputFile: outputFile.uri,
      outputDirectoryShared: shared.uri,
      userDefines: libmpvDir == null && tizen == false
          ? null
          : PackageUserDefines(
              workspacePubspec: PackageUserDefinesSource(
                defines: {
                  if (libmpvDir != null) 'libmpv': libmpvDir.path,
                  if (tizen != false) 'tizen': tizen,
                },
                basePath: tmp.uri,
              ),
            ),
    )
    ..config.setupBuild(linkingEnabled: false);
  // What flutter-tizen writes: OS.linux, no C compiler.
  CodeAssetExtension(
    targetArchitecture: arch,
    targetOS: OS.linux,
    linkModePreference: LinkModePreference.dynamic,
  ).setupBuildInput(builder);
  final json = builder.build().json..['out_dir'] = out.uri.toFilePath();
  final input = File('${tmp.path}/input.json')
    ..writeAsStringSync(jsonEncode(json));
  final run = await Process.run('dart', [
    'run',
    'hook/build.dart',
    '--config=${input.path}',
  ]);
  if (run.exitCode != 0 || !outputFile.existsSync()) return (run, null);
  return (
    run,
    BuildOutput(
      jsonDecode(outputFile.readAsStringSync()) as Map<String, Object?>,
    ),
  );
}

void main() {
  // A directory of release assets, each file naming itself.
  Directory assets(Directory tmp) {
    final dir = Directory('${tmp.path}/release')..createSync();
    for (final name in [
      'libmpv_tizen-armv7l.so',
      'libmpv_tizen-x86_64.so',
      'libmpv_linux-x86_64.so',
      'libmpv_linux-aarch64.so',
    ]) {
      File('${dir.path}/$name').writeAsStringSync(name);
    }
    return dir;
  }

  for (final (arch, tizen, asset) in [
    (Architecture.arm, false, 'libmpv_tizen-armv7l.so'),
    (Architecture.arm, true, 'libmpv_tizen-armv7l.so'),
    (Architecture.x64, true, 'libmpv_tizen-x86_64.so'),
    (Architecture.x64, false, 'libmpv_linux-x86_64.so'),
    (Architecture.arm64, false, 'libmpv_linux-aarch64.so'),
  ]) {
    test('linux on ${arch.name}${tizen ? ' with tizen: true' : ''} '
        'bundles $asset', () async {
      final tmp = await Directory.systemTemp.createTemp('mak_hook_tizen');
      addTearDown(() => tmp.delete(recursive: true));
      final (run, output) = await _runHook(
        tmp,
        arch,
        libmpvDir: assets(tmp),
        tizen: tizen,
      );
      expect(run.exitCode, 0, reason: '${run.stdout}${run.stderr}');
      final code = output!.assets.code.single;
      expect(code.id, 'package:mpv_audio_kit/libmpv');
      expect(code.file!.pathSegments.last, 'libmpv_audio_kit.so');
      expect(File.fromUri(code.file!).readAsStringSync(), asset);
    });
  }

  for (final arch in [Architecture.ia32, Architecture.arm64]) {
    test('Tizen on ${arch.name} is unsupported', () async {
      final tmp = await Directory.systemTemp.createTemp('mak_hook_tizen');
      addTearDown(() => tmp.delete(recursive: true));
      final (run, _) = await _runHook(
        tmp,
        arch,
        libmpvDir: assets(tmp),
        tizen: arch == Architecture.arm64,
      );
      expect(run.exitCode, isNot(0));
      expect('${run.stdout}${run.stderr}', contains('no libmpv for'));
    });
  }

  test(
    'a Tizen build without the user define downloads its own asset',
    () async {
      final tmp = await Directory.systemTemp.createTemp('mak_hook_tizen');
      addTearDown(() => tmp.delete(recursive: true));
      final (run, output) = await _runHook(tmp, Architecture.arm);
      final said = '${run.stdout}${run.stderr}';
      if (output == null) {
        // The pinned release is not published yet, or the network is
        // down: the failure names the asset, never the arch as
        // unsupported.
        expect(run.exitCode, isNot(0));
        expect(said, contains('libmpv_tizen-armv7l.so'));
        expect(said, isNot(contains('no libmpv for')));
        return;
      }
      // Published: what it bundled is the Tizen asset the hook pins.
      final code = output.assets.code.single;
      expect(code.file!.pathSegments.last, 'libmpv_audio_kit.so');
      final pinned = RegExp(
        r"'libmpv_tizen-armv7l\.so':\s*'([0-9a-f]{64})'",
      ).firstMatch(File('hook/build.dart').readAsStringSync())!.group(1);
      expect(
        sha256.convert(File.fromUri(code.file!).readAsBytesSync()).toString(),
        pinned,
      );
    },
  );

  // A string or a yes from YAML is not the bool the hook reads: an emulator
  // build would bundle the desktop library and fail only when it loads.
  for (final value in ['true', 'yes', 1]) {
    test(
      'tizen: ${jsonEncode(value)} fails the build, naming the define',
      () async {
        final tmp = await Directory.systemTemp.createTemp('mak_hook_tizen');
        addTearDown(() => tmp.delete(recursive: true));
        final (run, _) = await _runHook(
          tmp,
          Architecture.x64,
          libmpvDir: assets(tmp),
          tizen: value,
        );
        expect(run.exitCode, isNot(0), reason: '${run.stdout}');
        expect('${run.stdout}${run.stderr}', contains('tizen user define'));
      },
    );
  }

  // update_libmpv.sh rewrites only the names already in _sha256: a name the
  // hook can pick but the table lacks never gets its SHA at a pin, and
  // every build for it fails.
  test('every asset the hook can pick has a row in _sha256', () {
    final hook = File('hook/build.dart').readAsStringSync();
    final table = RegExp(
      r'const _sha256 = <String, String>\{\n(.*?)\n\};',
      dotAll: true,
    ).firstMatch(hook)!;
    final rows = RegExp(r"'([^']+)':").allMatches(table[1]!).map((m) => m[1]);
    final picked = RegExp(r"'(libmpv_[A-Za-z0-9_.-]+\.(?:so|dll|zip))'")
        .allMatches(hook.substring(table.end))
        .map((m) => m[1]!)
        // The name an asset is bundled as, not one of the release.
        .where((name) => !name.startsWith('libmpv_audio_kit.'))
        .toSet();
    expect(
      picked,
      containsAll(['libmpv_tizen-armv7l.so', 'libmpv_tizen-x86_64.so']),
    );
    expect(rows, containsAll(picked));
  });
}
