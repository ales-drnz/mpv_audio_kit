// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// The build hook's check of the iOS version, which it reads from the input
// as Flutter writes it: deployment_version (code_assets 2.2), or
// target_version before. An iOS below 15 stops the build with the Flutter
// it needs.

import 'dart:convert';
import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:test/test.dart';

void main() {
  /// Runs the hook on an iOS input whose `ios` block is [ios], written by
  /// hand: IOSCodeConfig has no form that both the code_assets 1.x of
  /// Flutter 3.41 and 2.2 take without a deprecation. Its libmpv user
  /// define names a file that is not there, which stops the hook right
  /// after the check, before any download.
  Future<ProcessResult> runHook(Map<String, Object?> ios) async {
    final tmp = await Directory.systemTemp.createTemp('mak_hook_ios');
    addTearDown(() => tmp.delete(recursive: true));
    final shared = Directory('${tmp.path}/shared')..createSync();
    final builder = BuildInputBuilder()
      ..setupShared(
        packageRoot: Directory.current.uri,
        packageName: 'mpv_audio_kit',
        outputFile: File('${tmp.path}/output.json').uri,
        outputDirectoryShared: shared.uri,
        userDefines: PackageUserDefines(
          workspacePubspec: PackageUserDefinesSource(
            defines: {'libmpv': '${tmp.path}/missing/libmpv.so'},
            basePath: tmp.uri,
          ),
        ),
      )
      ..config.setupBuild(linkingEnabled: false);
    CodeAssetExtension(
      targetArchitecture: Architecture.arm64,
      targetOS: OS.linux,
      linkModePreference: LinkModePreference.dynamic,
    ).setupBuildInput(builder);
    final json = builder.build().json;
    final config = json['config'] as Map;
    ((config['extensions'] as Map)['code_assets'] as Map)
      ..['target_os'] = 'ios'
      ..['ios'] = {'target_sdk': 'iphonesimulator', ...ios};
    final input = File('${tmp.path}/input.json')
      ..writeAsStringSync(jsonEncode(json));
    return Process.run('dart', [
      'run',
      'hook/build.dart',
      '--config=${input.path}',
    ]);
  }

  String said(ProcessResult run) => '${run.stdout}${run.stderr}';

  test('iOS 13 by target_version stops the build', () async {
    final run = await runHook({'target_version': 13});
    expect(run.exitCode, isNot(0));
    expect(said(run), contains('needs Flutter 3.47.4'));
    expect(said(run), contains('targets iOS 13'));
  });

  test('deployment_version wins over target_version', () async {
    final run = await runHook({
      'deployment_version': {'major': 13, 'minor': 0, 'patch': 0},
      'target_version': 15,
    });
    expect(run.exitCode, isNot(0));
    expect(said(run), contains('targets iOS 13'));
  });

  test('iOS 15 passes the check', () async {
    final run = await runHook({'target_version': 15});
    expect(run.exitCode, isNot(0));
    expect(said(run), isNot(contains('needs Flutter')));
    expect(said(run), contains('the libmpv user define points at'));
  });
}
