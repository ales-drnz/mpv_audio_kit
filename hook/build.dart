// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

// Build hook: fetches the libmpv binary for the target from the
// libmpv-<release> GitHub release, checks its SHA-256 and bundles it as the
// code asset `package:mpv_audio_kit/libmpv`, which lib/src/mpv_bindings.dart
// binds with @Native. One script for every platform, in place of a Gradle
// task, two podspecs, two SwiftPM manifests and two CMake files.
//
// Offline builds and custom binaries: point the app at a local copy with
//
//   hooks:
//     user_defines:
//       mpv_audio_kit:
//         libmpv: path/to/libmpv
//
// in the app's pubspec. A directory holds files named like the release
// assets (libmpv_android-arm64-v8a.so, libmpv_ios.xcframework.zip, ...),
// and each target takes its own. A single file is bundled for every
// target, so it only suits a build for one target and architecture. Local
// files are bundled as they are, without a checksum.
//
// tvOS is the exception: the plugin's tvos/Package.swift links libmpv
// there, and this hook bundles nothing.

import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:crypto/crypto.dart';
import 'package:hooks/hooks.dart';

import 'package:mpv_audio_kit/src/internals/hook_download.dart';
import 'package:mpv_audio_kit/src/internals/libmpv_release.dart';

const _release = 'libmpv-$libmpvRelease';
const _baseUrl =
    'https://github.com/ales-drnz/mpv_audio_kit/releases/download/$_release';

/// SHA-256 of every release asset, from the release's manifest.json.
const _sha256 = <String, String>{
  'libmpv_android-arm64-v8a.so':
      'cc2b328fd2b3ae6ece527c9acda048ac3d8ecd8854e4ef6184db3cb62b11553a',
  'libmpv_android-armeabi-v7a.so':
      '0415456779015ad2d62ce7b1549c0adb54821986e88c2b0ac82053e3af31cccb',
  'libmpv_android-x86_64.so':
      '0f0bbc952feed353e5bfd4bc0c1af2d4944631574caf953883cfde7755e0a219',
  'libmpv_ios.xcframework.zip':
      'cd5c8700c19b12c7e802410a07e4fd93fb906a245a391330a985d34abdf73cea',
  'libmpv_linux-aarch64.so':
      '3bc9b3277705686e00303f2a2cebeef6dc9ad22a5b1f71f41de78557d5904789',
  'libmpv_linux-x86_64.so':
      '13d59f9026d831d8c69fc897b7f120e1d96ed67a8fb0e10e206b1adc44786239',
  'libmpv_macos.xcframework.zip':
      '55c720db17eaaa20f8928cc53587a06dfcb92c154db8a0a5fe20f2552730898e',
  'libmpv_windows-arm64.dll':
      'd72b331061cdbfc61f85595a2879aac06fbea9c4ab966be819ebf870ff94c42a',
  'libmpv_windows-x86_64.dll':
      '36928dcaf795385f476c0484077757c91b946436fc0c4954c0f344d093bdd7b1',
};

void main(List<String> args) async {
  await build(args, (input, output) async {
    if (!input.config.buildCodeAssets) return;
    // flutter-tvos (https://fluttertv.dev) runs the hook but installs no
    // code asset, so tvos/Package.swift links libmpv into the app and
    // @Native finds its symbols in the process. Read before
    // input.config.code, which code_assets before 2.0.0 cannot parse for
    // an OS it does not know.
    if (_targetOSName(input) == 'tvos') return;
    final code = input.config.code;
    final target = _Target.of(code, iOSVersion: _iOSVersion(input));
    final out = File.fromUri(input.outputDirectory.resolve(target.fileName));

    final local = input.userDefines.path('libmpv');
    if (local != null &&
        await FileSystemEntity.type(local.toFilePath()) ==
            FileSystemEntityType.notFound) {
      throw StateError(
        'mpv_audio_kit: the libmpv user define points at '
        '${local.toFilePath()}, which does not exist',
      );
    }
    if (local != null &&
        !await FileSystemEntity.isDirectory(local.toFilePath())) {
      // A single file is the finished library, bundled for every target.
      output.dependencies.add(local);
      await File.fromUri(local).copy(out.path);
    } else {
      final asset = local == null
          ? await _fetch(target.asset, input.outputDirectoryShared)
          : await _localAsset(local, target.asset);
      if (local != null) output.dependencies.add(asset.uri);
      if (target.appleSlice == null) {
        await asset.copy(out.path);
      } else {
        // A pinned download never changes, so its unpacked copy is kept
        // beside it; a local zip may, so it is unpacked again each build.
        final unpacked = local == null
            ? Directory('${asset.parent.path}/unzipped')
            : Directory.fromUri(input.outputDirectory.resolve('unzipped'));
        if (local != null && await unpacked.exists()) {
          await unpacked.delete(recursive: true);
        }
        await _extractAppleSlice(
          asset,
          unpacked,
          target,
          code.targetArchitecture,
          out,
        );
      }
    }

    output.assets.code.add(
      CodeAsset(
        package: input.packageName,
        name: 'libmpv',
        linkMode: DynamicLoadingBundled(),
        file: out.uri,
      ),
    );
  });
}

/// The target OS as the hook protocol writes it, read off the JSON input.
String? _targetOSName(BuildInput input) {
  final extensions = input.config.json['extensions'];
  final code = extensions is Map ? extensions['code_assets'] : null;
  final os = code is Map ? code['target_os'] : null;
  return os is String ? os : null;
}

/// The iOS version the build targets, as Flutter writes it in the input:
/// `deployment_version` (code_assets 2.2) or `target_version` before.
/// Read raw, as [_targetOSName]: code_assets 2.2 deprecates
/// `IOSCodeConfig.targetVersion` for `deploymentVersion`, which the
/// code_assets 1.x of Flutter 3.41 lacks. `null` when the input has none.
int? _iOSVersion(BuildInput input) {
  final extensions = input.config.json['extensions'];
  final code = extensions is Map ? extensions['code_assets'] : null;
  final ios = code is Map ? code['ios'] : null;
  if (ios is! Map) return null;
  final deployment = ios['deployment_version'];
  final major = deployment is Map ? deployment['major'] : ios['target_version'];
  return major is int ? major : null;
}

/// Which release asset a target needs, and the file name it is bundled
/// under. The name is the package's own, never `libmpv`, so it cannot
/// collide with another plugin's copy on disk or in the loader (bionic
/// matches a dlopen by name against the SONAMEs already loaded; the SONAME
/// inside is the same). On Apple the file becomes
/// `libmpv_audio_kit.framework/libmpv_audio_kit`: not `mpv_audio_kit`,
/// which is the framework CocoaPods builds for the plugin itself under
/// `use_frameworks!`, and both land in the app's Frameworks directory.
class _Target {
  const _Target(this.asset, this.fileName, {this.appleSlice});

  final String asset;
  final String fileName;

  /// The xcframework directory holding the slice, on Apple.
  final String? appleSlice;

  static _Target of(CodeConfig code, {int? iOSVersion}) {
    final arch = code.targetArchitecture;
    Never unsupported() => throw UnsupportedError(
      'mpv_audio_kit: no libmpv for ${code.targetOS} '
      '$arch in $_release',
    );
    // The iOS binary is built for iOS 15, and Flutter writes this version
    // into the framework's MinimumOSVersion: a lower one does not match the
    // binary. Flutter before 3.47.4 passes 12 or 13.
    if (code.targetOS == OS.iOS && iOSVersion != null && iOSVersion < 15) {
      throw UnsupportedError(
        'mpv_audio_kit: building for iOS needs Flutter 3.47.4 or later, '
        'which targets iOS 15 like the bundled libmpv '
        '(this Flutter targets iOS $iOSVersion).',
      );
    }
    return switch (code.targetOS) {
      OS.linux => _Target(
        'libmpv_linux-${switch (arch) {
          Architecture.x64 => 'x86_64',
          Architecture.arm64 => 'aarch64',
          _ => unsupported(),
        }}.so',
        'libmpv_audio_kit.so',
      ),
      OS.android => _Target(
        'libmpv_android-${switch (arch) {
          Architecture.arm64 => 'arm64-v8a',
          Architecture.arm => 'armeabi-v7a',
          Architecture.x64 => 'x86_64',
          _ => unsupported(),
        }}.so',
        'libmpv_audio_kit.so',
      ),
      OS.windows => _Target(
        'libmpv_windows-${switch (arch) {
          Architecture.x64 => 'x86_64',
          Architecture.arm64 => 'arm64',
          _ => unsupported(),
        }}.dll',
        'mpv_audio_kit.dll',
      ),
      OS.macOS => const _Target(
        'libmpv_macos.xcframework.zip',
        'libmpv_audio_kit',
        appleSlice: 'macos-arm64_x86_64',
      ),
      OS.iOS => _Target(
        'libmpv_ios.xcframework.zip',
        'libmpv_audio_kit',
        appleSlice: code.iOS.targetSdk == IOSSdk.iPhoneSimulator
            ? 'ios-arm64_x86_64-simulator'
            : 'ios-arm64',
      ),
      _ => unsupported(),
    };
  }
}

/// The release [asset] in the user-defined directory [dir].
Future<File> _localAsset(Uri dir, String asset) async {
  // Resolve inside the directory even when the path has no trailing slash.
  final base = dir.path.endsWith('/') ? dir : dir.replace(path: '${dir.path}/');
  final file = File.fromUri(base.resolve(asset));
  if (!await file.exists()) {
    throw StateError(
      'mpv_audio_kit: the libmpv user define points at ${dir.toFilePath()}, '
      'which has no $asset',
    );
  }
  return file;
}

/// The release [asset], downloaded once into [cacheDir] and reused by every
/// build that asks for the same checksum.
Future<File> _fetch(String asset, Uri cacheDir) async {
  final expected = _sha256[asset];
  if (expected == null || expected.isEmpty) {
    throw StateError('mpv_audio_kit: no SHA-256 pinned for $asset');
  }
  final cached = File.fromUri(cacheDir.resolve('$expected/$asset'));
  if (await _matches(cached, expected)) return cached;

  await cached.parent.create(recursive: true);
  // One partial file per build: Flutter can run the hook for two
  // architectures at once, and both would download the same asset.
  final partial = File('${cached.path}.$pid.part');
  try {
    await download('$_baseUrl/$asset', partial);
    if (!await _matches(partial, expected)) {
      throw StateError(
        'mpv_audio_kit: SHA-256 mismatch for $asset from $_baseUrl',
      );
    }
    return await partial.rename(cached.path);
  } finally {
    if (await partial.exists()) await partial.delete();
  }
}

/// Copies the libmpv binary of the xcframework slice, unpacked from [zip]
/// into [dir], into [out], thinned to [arch] when the slice is universal:
/// Flutter runs the hook once per architecture and merges the results
/// itself.
Future<void> _extractAppleSlice(
  File zip,
  Directory dir,
  _Target target,
  Architecture arch,
  File out,
) async {
  final framework =
      '${dir.path}/libmpv.xcframework/${target.appleSlice}/libmpv.framework';
  if (!await dir.exists()) {
    // Unpack beside it and rename into place, so an interrupted unzip
    // never leaves a half directory that a later build would trust.
    await dir.parent.create(recursive: true);
    final staging = await dir.parent.createTemp('unzip-');
    await _run('unzip', ['-q', zip.path, '-d', staging.path]);
    try {
      await staging.rename(dir.path);
    } on FileSystemException {
      // Another build unpacked the same zip first; its copy is identical.
      await staging.delete(recursive: true);
    }
  }
  // A macOS framework keeps its binary under Versions/; follow the link.
  final binary = await File('$framework/libmpv').resolveSymbolicLinks();
  final lipoArch = switch (arch) {
    Architecture.arm64 => 'arm64',
    Architecture.x64 => 'x86_64',
    _ => throw UnsupportedError('mpv_audio_kit: no Apple slice for $arch'),
  };
  final archs = (await _run('lipo', ['-archs', binary])).trim().split(' ');
  if (archs.length == 1) {
    if (archs.single != lipoArch) {
      throw StateError(
        'mpv_audio_kit: $binary is ${archs.single}, '
        'the build wants $lipoArch',
      );
    }
    await File(binary).copy(out.path);
  } else {
    await _run('lipo', [binary, '-thin', lipoArch, '-output', out.path]);
  }
}

Future<bool> _matches(File file, String sha256Hex) async {
  if (!await file.exists()) return false;
  final digest = await sha256.bind(file.openRead()).first;
  return digest.toString() == sha256Hex;
}

Future<String> _run(String executable, List<String> arguments) async {
  final result = await Process.run(executable, arguments);
  if (result.exitCode != 0) {
    throw ProcessException(
      executable,
      arguments,
      '${result.stderr}',
      result.exitCode,
    );
  }
  return result.stdout as String;
}
