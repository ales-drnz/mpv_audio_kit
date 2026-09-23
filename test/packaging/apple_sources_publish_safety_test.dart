// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:io';

import 'package:test/test.dart';

/// Guards the shape of the Apple Swift sources as they ship to pub.dev.
///
/// The iOS and macOS plugins share their Swift through
/// `darwin/Sources/mpv_audio_kit/`, mirrored into each platform's
/// `Sources/mpv_audio_kit/`. Those mirrors MUST be real files, never
/// symlinks: `dart pub publish` does not preserve symlinks — it writes them
/// into the tarball as regular files whose body is the link-target path, so
/// the consumer's Xcode tries to compile `../../../../darwin/...` as Swift
/// and fails with "Expressions are not allowed at the top level". The host
/// build never sees this because git keeps the symlinks intact locally.
///
/// `scripts/sync_apple_sources.sh` keeps the copies in sync; this test is the
/// invariant that catches a stale copy or an accidentally re-added symlink
/// before publish. Paths are relative to the package root, which is the
/// working directory under `flutter test`.
void main() {
  const sharedDir = 'darwin/Sources/mpv_audio_kit';
  const sharedFiles = ['MediaSessionPlugin.swift', 'MpvAudioKitPlugin.swift'];
  const platformDirs = [
    'ios/mpv_audio_kit/Sources/mpv_audio_kit',
    'macos/mpv_audio_kit/Sources/mpv_audio_kit',
  ];

  group('Apple Swift sources are publish-safe', () {
    for (final platformDir in platformDirs) {
      for (final file in sharedFiles) {
        final path = '$platformDir/$file';

        test('$path is a real file, not a symlink', () {
          expect(
            FileSystemEntity.isLinkSync(path),
            isFalse,
            reason:
                '$path must be a real file — pub publish flattens '
                'symlinks to broken regular files. '
                'Run scripts/sync_apple_sources.sh.',
          );
          expect(File(path).existsSync(), isTrue, reason: '$path is missing');
        });

        test('$path is byte-identical to $sharedDir/$file', () {
          final shared = File('$sharedDir/$file');
          final copy = File(path);
          expect(
            copy.readAsBytesSync(),
            equals(shared.readAsBytesSync()),
            reason:
                '$path has drifted from the shared source. '
                'Run scripts/sync_apple_sources.sh.',
          );
        });
      }
    }

    test('ios and macos PrivacyInfo.xcprivacy stay in sync', () {
      final ios = File(
        'ios/mpv_audio_kit/Sources/mpv_audio_kit/PrivacyInfo.xcprivacy',
      );
      final macos = File(
        'macos/mpv_audio_kit/Sources/mpv_audio_kit/PrivacyInfo.xcprivacy',
      );
      expect(ios.existsSync() && macos.existsSync(), isTrue);
      expect(
        ios.readAsBytesSync(),
        equals(macos.readAsBytesSync()),
        reason:
            'iOS and macOS privacy manifests must match — '
            'they are maintained as per-platform copies.',
      );
    });
  });
}
