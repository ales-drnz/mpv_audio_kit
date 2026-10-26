// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:io';

import 'package:test/test.dart';

/// The Apple plugin exists once, in darwin/: pubspec.yaml sets
/// sharedDarwinSource on iOS and macOS, so Flutter reads the podspec and
/// the Swift package from there on both, under CocoaPods and SwiftPM.
/// Paths are relative to the package root, the working directory under
/// `flutter test`.
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
    for (final path in files) {
      expect(File(path).existsSync(), isTrue, reason: '$path is missing');
    }
    final links = Directory('darwin')
        .listSync(recursive: true, followLinks: false)
        .whereType<Link>()
        .map((l) => l.path);
    expect(links, isEmpty);
  });

  test('darwin ships with the package', () {
    final ignored = File('.pubignore')
        .readAsLinesSync()
        .map((l) => l.trim())
        .where((l) => RegExp(r'^/?darwin(/.*)?$').hasMatch(l));
    expect(ignored, isEmpty);
  });
}
