// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:io';

import 'package:test/test.dart';

import '../_helpers/update_libmpv_fixture.dart';

/// The Apple plugin exists once, in darwin/: pubspec.yaml sets
/// sharedDarwinSource on iOS and macOS, so Flutter reads the podspec and
/// the Swift package from there on both, under CocoaPods and SwiftPM.
/// flutter-tvos reads tvos/Package.swift, whose sources are copies of
/// darwin/'s. Paths are relative to the package root, the working
/// directory under `flutter test`.
void main() {
  const files = [
    'darwin/mpv_audio_kit.podspec',
    'darwin/mpv_audio_kit/Package.swift',
    'darwin/mpv_audio_kit/Sources/mpv_audio_kit/MediaSessionPlugin.swift',
    'darwin/mpv_audio_kit/Sources/mpv_audio_kit/MpvAudioKitPlugin.swift',
    'darwin/mpv_audio_kit/Sources/mpv_audio_kit/PrivacyInfo.xcprivacy',
  ];

  test('iOS and macOS read the plugin from darwin', () {
    // A Windows checkout may end the lines with CRLF (core.autocrlf).
    final pubspec = File(
      'pubspec.yaml',
    ).readAsStringSync().replaceAll('\r\n', '\n');
    for (final os in ['ios', 'macos']) {
      final entry = RegExp(
        '^      $os:\\n((?:        .*(?:\\n|\$))+)',
        multiLine: true,
      ).firstMatch(pubspec);
      expect(entry, isNotNull, reason: 'no $os entry under plugin platforms');
      expect(entry!.group(1), contains('sharedDarwinSource: true'));
    }
  });

  test('no copy of the plugin is left in ios or macos', () {
    // Flutter ignores those folders once darwin is shared: a copy there
    // would drift without anything building it.
    for (final os in ['ios', 'macos']) {
      expect(Directory(os).existsSync(), isFalse, reason: '$os/ is back');
    }
  });

  test('the manifests and the sources are real files', () {
    // dart pub publish stores a symlink as a regular file holding the link
    // path, which the app's Xcode then fails to build.
    for (final path in [...files, 'tvos/Package.swift']) {
      expect(File(path).existsSync(), isTrue, reason: '$path is missing');
    }
    for (final dir in ['darwin', 'tvos']) {
      final links = Directory(dir)
          .listSync(recursive: true, followLinks: false)
          .whereType<Link>()
          .map((l) => l.path);
      expect(links, isEmpty);
    }
  });

  test('tvOS reads the plugin from tvos', () {
    final pubspec = File(
      'pubspec.yaml',
    ).readAsStringSync().replaceAll('\r\n', '\n');
    final entry = RegExp(
      '^      tvos:\\n((?:        .*(?:\\n|\$))+)',
      multiLine: true,
    ).firstMatch(pubspec);
    expect(entry, isNotNull, reason: 'no tvos entry under plugin platforms');
    expect(entry!.group(1), contains('pluginClass: MpvAudioKitPlugin'));
  });

  test('the tvOS sources are the darwin ones', () {
    // SwiftPM takes no target outside the package root, so tvos/ holds
    // copies; a change to darwin/ goes to tvos/ too:
    //   cp darwin/mpv_audio_kit/Sources/mpv_audio_kit/* tvos/Sources/mpv_audio_kit/
    const darwin = 'darwin/mpv_audio_kit/Sources/mpv_audio_kit';
    const tvos = 'tvos/Sources/mpv_audio_kit';
    Set<String> names(String dir) => Directory(
      dir,
    ).listSync().whereType<File>().map((f) => f.uri.pathSegments.last).toSet();
    expect(names(tvos), names(darwin));
    for (final name in names(darwin)) {
      String read(String dir) =>
          File('$dir/$name').readAsStringSync().replaceAll('\r\n', '\n');
      expect(read(tvos), read(darwin), reason: '$tvos/$name differs');
    }
  });

  group('update_libmpv.sh pins the tvOS libmpv in tvos/Package.swift', () {
    final root = Directory.current.path;
    late Directory package;

    setUp(() => package = packageCopy(root));
    tearDown(() => package.deleteSync(recursive: true));

    // The two lines the script writes.
    String pins() => File('${package.path}/tvos/Package.swift')
        .readAsLinesSync()
        .where((l) => RegExp(r'^let (release|checksum) = ').hasMatch(l))
        .join('\n');

    test('with the checksum of the release', () async {
      final sum = 'ab' * 32;
      final manifest = await release(
        root,
        edit: (m) =>
            (m['assets']
                    as Map<String, dynamic>)['libmpv_tvos.xcframework.zip'] =
                sum,
      );
      final run = await updateLibmpv(package, manifest);
      expect(run.exitCode, 0, reason: '${run.stdout}${run.stderr}');
      expect(pins(), 'let release = "libmpv-r99"\nlet checksum = "$sum"');
    });

    test('with no checksum when the release has no tvOS libmpv', () async {
      final manifest = await release(
        root,
        edit: (m) => (m['assets'] as Map<String, dynamic>).remove(
          'libmpv_tvos.xcframework.zip',
        ),
      );
      final run = await updateLibmpv(package, manifest);
      expect(run.exitCode, 0, reason: '${run.stdout}${run.stderr}');
      expect(pins(), 'let release = "libmpv-r99"\nlet checksum = ""');
    });
  });

  test('darwin and tvos ship with the package', () {
    final ignored = File('.pubignore')
        .readAsLinesSync()
        .map((l) => l.trim())
        .where((l) => RegExp(r'^/?(darwin|tvos)(/.*)?$').hasMatch(l));
    expect(ignored, ['/tvos/libmpv.xcframework/']);
  });
}
