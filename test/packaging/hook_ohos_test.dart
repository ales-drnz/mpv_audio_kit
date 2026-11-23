// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// The build hook on OpenHarmony and HarmonyOS (OHOS) through Flutter-OH,
// which writes target_os linux with the arch of the HAP (OhosAssetTarget in
// its flutter_tools, branches oh-3.41.9 to oh-3.50.0) and passes the clang
// of the OpenHarmony SDK as the C compiler. That clang, or the ohos user
// define, makes the build OHOS: arm64 and x64 take libmpv_ohos-arm64-v8a.so
// and libmpv_ohos-x86_64.so, and 32-bit arm has none (it must not fall to
// the Tizen asset that linux on arm means otherwise).

import 'dart:convert';
import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:test/test.dart';

/// The C compiler Flutter-OH passes: `cCompilerConfigOhos` finds it at
/// `<sdk>/<version>/openharmony/native/llvm/bin/clang`.
const _ohosClang = '/opt/ohos-sdk/default/openharmony/native/llvm/bin/clang';
const _ohosAr = '/opt/ohos-sdk/default/openharmony/native/llvm/bin/llvm-ar';
const _ohosLd = '/opt/ohos-sdk/default/openharmony/native/llvm/bin/ld.lld';

/// Runs hook/build.dart for linux on [arch] with the C compiler [cc] when
/// given, the user defines [defines] and the libmpv one at [libmpvDir],
/// with target_os rewritten to [rawOS] when given; returns its exit and
/// its output.
Future<(ProcessResult, BuildOutput?)> _runHook(
  Directory tmp,
  Architecture arch, {
  String? cc,
  Directory? libmpvDir,
  Map<String, Object> defines = const {},
  String? rawOS,
}) async {
  final shared = Directory('${tmp.path}/shared')..createSync();
  final out = Directory('${tmp.path}/out')..createSync();
  final outputFile = File('${tmp.path}/output.json');
  final all = {if (libmpvDir != null) 'libmpv': libmpvDir.path, ...defines};
  final builder = BuildInputBuilder()
    ..setupShared(
      packageRoot: Directory.current.uri,
      packageName: 'mpv_audio_kit',
      outputFile: outputFile.uri,
      outputDirectoryShared: shared.uri,
      userDefines: all.isEmpty
          ? null
          : PackageUserDefines(
              workspacePubspec: PackageUserDefinesSource(
                defines: all,
                basePath: tmp.uri,
              ),
            ),
    )
    ..config.setupBuild(linkingEnabled: false);
  CodeAssetExtension(
    targetArchitecture: arch,
    targetOS: OS.linux,
    linkModePreference: LinkModePreference.dynamic,
    cCompiler: cc == null
        ? null
        : CCompilerConfig(
            compiler: Uri.file(cc),
            archiver: Uri.file(cc == _ohosClang ? _ohosAr : '/usr/bin/ar'),
            linker: Uri.file(cc == _ohosClang ? _ohosLd : '/usr/bin/ld'),
          ),
  ).setupBuildInput(builder);
  final json = builder.build().json..['out_dir'] = out.uri.toFilePath();
  if (rawOS != null) {
    final code = (json['config'] as Map)['extensions'] as Map<String, Object?>;
    (code['code_assets'] as Map<String, Object?>)['target_os'] = rawOS;
  }
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
      'libmpv_ohos-arm64-v8a.so',
      'libmpv_ohos-x86_64.so',
      'libmpv_tizen-armv7l.so',
      'libmpv_tizen-x86_64.so',
      'libmpv_linux-x86_64.so',
      'libmpv_linux-aarch64.so',
    ]) {
      File('${dir.path}/$name').writeAsStringSync(name);
    }
    return dir;
  }

  Future<Directory> temp() async {
    final tmp = await Directory.systemTemp.createTemp('mak_hook_ohos');
    addTearDown(() => tmp.delete(recursive: true));
    return tmp;
  }

  void expectBundled(ProcessResult run, BuildOutput? output, String asset) {
    expect(run.exitCode, 0, reason: '${run.stdout}${run.stderr}');
    final code = output!.assets.code.single;
    expect(code.id, 'package:mpv_audio_kit/libmpv');
    expect(code.file!.pathSegments.last, 'libmpv_audio_kit.so');
    expect(File.fromUri(code.file!).readAsStringSync(), asset);
  }

  for (final (name, arch, cc, defines, asset) in [
    (
      'the SDK clang on arm64',
      Architecture.arm64,
      _ohosClang,
      const <String, Object>{},
      'libmpv_ohos-arm64-v8a.so',
    ),
    (
      'the SDK clang on x64',
      Architecture.x64,
      _ohosClang,
      const <String, Object>{},
      'libmpv_ohos-x86_64.so',
    ),
    (
      'ohos: true without a C compiler on arm64',
      Architecture.arm64,
      null,
      const <String, Object>{'ohos': true},
      'libmpv_ohos-arm64-v8a.so',
    ),
    (
      'ohos: false over the SDK clang on arm64',
      Architecture.arm64,
      _ohosClang,
      const <String, Object>{'ohos': false},
      'libmpv_linux-aarch64.so',
    ),
    (
      'a desktop gcc on arm64',
      Architecture.arm64,
      '/usr/bin/aarch64-linux-gnu-gcc',
      const <String, Object>{},
      'libmpv_linux-aarch64.so',
    ),
    (
      'a desktop gcc on x64',
      Architecture.x64,
      '/usr/bin/gcc',
      const <String, Object>{},
      'libmpv_linux-x86_64.so',
    ),
  ]) {
    test('linux with $name bundles $asset', () async {
      final tmp = await temp();
      final (run, output) = await _runHook(
        tmp,
        arch,
        cc: cc,
        libmpvDir: assets(tmp),
        defines: defines,
      );
      expectBundled(run, output, asset);
    });
  }

  test('a target OS of ohos bundles the OHOS asset', () async {
    final tmp = await temp();
    final (run, output) = await _runHook(
      tmp,
      Architecture.arm64,
      libmpvDir: assets(tmp),
      rawOS: 'ohos',
    );
    expectBundled(run, output, 'libmpv_ohos-arm64-v8a.so');
  });

  test('OHOS on 32-bit arm is unsupported, not Tizen', () async {
    final tmp = await temp();
    final (run, _) = await _runHook(
      tmp,
      Architecture.arm,
      cc: _ohosClang,
      libmpvDir: assets(tmp),
    );
    final said = '${run.stdout}${run.stderr}';
    expect(run.exitCode, isNot(0));
    expect(said, contains('no libmpv for ohos arm'));
    expect(said, isNot(contains('tizen')));
  });

  test('ohos is true or false', () async {
    final tmp = await temp();
    final (run, _) = await _runHook(
      tmp,
      Architecture.arm64,
      libmpvDir: assets(tmp),
      defines: const {'ohos': 'yes'},
    );
    expect(run.exitCode, isNot(0));
    expect(
      '${run.stdout}${run.stderr}',
      contains('the ohos user define is true or false'),
    );
  });

  test('Tizen and OHOS at once fail', () async {
    final tmp = await temp();
    final (run, _) = await _runHook(
      tmp,
      Architecture.x64,
      cc: _ohosClang,
      libmpvDir: assets(tmp),
      defines: const {'tizen': true},
    );
    expect(run.exitCode, isNot(0));
    expect('${run.stdout}${run.stderr}', contains('not both'));
  });

  test(
    'without the libmpv user define, OHOS names its unpinned asset',
    () async {
      // Until the OHOS assets are in a published release, their checksums
      // are empty and a download is refused.
      final tmp = await temp();
      final (run, output) = await _runHook(
        tmp,
        Architecture.arm64,
        cc: _ohosClang,
      );
      final said = '${run.stdout}${run.stderr}';
      expect(output, isNull);
      expect(run.exitCode, isNot(0));
      expect(said, contains('libmpv_ohos-arm64-v8a.so'));
    },
  );
}
