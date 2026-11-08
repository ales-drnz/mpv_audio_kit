// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// The build hook on tvOS, where tvos/Package.swift links libmpv: an input
// whose target_os is tvos, which code_assets before 2.0.0 cannot parse,
// gets no asset and no download.

import 'dart:convert';
import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:test/test.dart';

void main() {
  test('the hook bundles nothing for a tvos target', () async {
    final tmp = await Directory.systemTemp.createTemp('mak_hook_tvos');
    addTearDown(() => tmp.delete(recursive: true));
    final shared = Directory('${tmp.path}/shared')..createSync();
    final outputFile = File('${tmp.path}/output.json');
    final builder = BuildInputBuilder()
      ..setupShared(
        packageRoot: Directory.current.uri,
        packageName: 'mpv_audio_kit',
        outputFile: outputFile.uri,
        outputDirectoryShared: shared.uri,
      )
      ..config.setupBuild(linkingEnabled: false);
    CodeAssetExtension(
      targetArchitecture: Architecture.arm64,
      targetOS: OS.linux,
      linkModePreference: LinkModePreference.dynamic,
    ).setupBuildInput(builder);
    final json = builder.build().json;
    // What flutter-tvos writes: the protocol's name of the OS, on an iOS
    // input. Written by hand: IOSCodeConfig has no form that both the
    // code_assets 1.x of Flutter 3.41 and 2.2 take without a deprecation.
    final config = json['config'] as Map;
    ((config['extensions'] as Map)['code_assets'] as Map)
      ..['target_os'] = 'tvos'
      ..['ios'] = {'target_sdk': 'iphonesimulator', 'target_version': 15};
    final input = File('${tmp.path}/input.json')
      ..writeAsStringSync(jsonEncode(json));

    // In a process of its own: the hook's main returns before it writes.
    final run = await Process.run('dart', [
      'run',
      'hook/build.dart',
      '--config=${input.path}',
    ]);
    expect(run.exitCode, 0, reason: '${run.stdout}${run.stderr}');

    final output = BuildOutput(
      jsonDecode(outputFile.readAsStringSync()) as Map<String, Object?>,
    );
    expect(output.assets.encodedAssets, isEmpty);
    // The download goes to the shared output directory: nothing there.
    expect(shared.listSync(recursive: true).whereType<File>(), isEmpty);
  });
}
