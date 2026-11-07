// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// The build hook on Tizen through flutter-tizen, which writes target_os
// linux with the arch of the Tizen build: arm for the TVs, ia32 for the
// emulator (its x86 build), arches Flutter's own Linux desktop never builds.
// Each takes its libmpv_tizen asset, bundled as libmpv_audio_kit.so like
// the Linux one; the desktop arches keep the Linux assets.

import 'dart:convert';
import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:test/test.dart';

/// Runs hook/build.dart for linux on [arch], with the libmpv user define
/// at [libmpvDir] when given, and returns its exit and its output.
Future<(ProcessResult, BuildOutput?)> _runHook(
  Directory tmp,
  Architecture arch, {
  Directory? libmpvDir,
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
      userDefines: libmpvDir == null
          ? null
          : PackageUserDefines(
              workspacePubspec: PackageUserDefinesSource(
                defines: {'libmpv': libmpvDir.path},
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
      'libmpv_tizen-i686.so',
      'libmpv_linux-x86_64.so',
      'libmpv_linux-aarch64.so',
    ]) {
      File('${dir.path}/$name').writeAsStringSync(name);
    }
    return dir;
  }

  for (final (arch, asset) in [
    (Architecture.arm, 'libmpv_tizen-armv7l.so'),
    (Architecture.ia32, 'libmpv_tizen-i686.so'),
    (Architecture.x64, 'libmpv_linux-x86_64.so'),
    (Architecture.arm64, 'libmpv_linux-aarch64.so'),
  ]) {
    test('linux on ${arch.name} bundles $asset', () async {
      final tmp = await Directory.systemTemp.createTemp('mak_hook_tizen');
      addTearDown(() => tmp.delete(recursive: true));
      final (run, output) = await _runHook(tmp, arch, libmpvDir: assets(tmp));
      expect(run.exitCode, 0, reason: '${run.stdout}${run.stderr}');
      final code = output!.assets.code.single;
      expect(code.id, 'package:mpv_audio_kit/libmpv');
      expect(code.file!.pathSegments.last, 'libmpv_audio_kit.so');
      expect(File.fromUri(code.file!).readAsStringSync(), asset);
    });
  }

  test(
    'a Tizen build without the user define downloads its own asset',
    () async {
      final tmp = await Directory.systemTemp.createTemp('mak_hook_tizen');
      addTearDown(() => tmp.delete(recursive: true));
      final (run, _) = await _runHook(tmp, Architecture.arm);
      // Until a release has the asset, it is not pinned: the failure names it,
      // never the arch as unsupported.
      final said = '${run.stdout}${run.stderr}';
      if (run.exitCode != 0) {
        expect(said, contains('libmpv_tizen-armv7l.so'));
        expect(said, isNot(contains('no libmpv for')));
      }
    },
  );
}
