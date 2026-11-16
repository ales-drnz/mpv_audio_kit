// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

// Build hook: fetches the libmpv binary for the target from the
// libmpv-<release> GitHub release, checks its SHA-256 and bundles it as the
// code asset `package:mpv_audio_kit/libmpv`, which
// lib/src/ffi/mpv_library_bundled.dart binds with @Native. One script for
// every platform, in place of a Gradle task, two podspecs, two SwiftPM
// manifests and two CMake files.
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
// there, and this hook bundles nothing. Tizen, through flutter-tizen, is
// linux here and takes its own libmpv_tizen assets: on arm (the TVs) by
// itself, on x64 (the TV emulator) with
//
//   hooks:
//     user_defines:
//       mpv_audio_kit:
//         tizen: true

import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';

import 'package:mpv_audio_kit/src/internals/hook_download.dart';
import 'package:mpv_audio_kit/src/internals/libmpv_release.dart';

const _release = 'libmpv-$libmpvRelease';
const _baseUrl =
    'https://github.com/ales-drnz/mpv_audio_kit/releases/download/$_release';

/// SHA-256 of every release asset, from the release's manifest.json.
const _sha256 = <String, String>{
  'libmpv_android-arm64-v8a.so':
      '36884ee5c162f3a676cfbbebea737c3379981a372b56d3a0d72006ce560b0899',
  'libmpv_android-armeabi-v7a.so':
      '050b17820eea37e8e2e64704ed025d9daec7e51a74a18d6c6f0333b15ddc4557',
  'libmpv_android-x86_64.so':
      '1eb936ee38b8ba97db4bd6d5f5d8979d7e69a427011ca65b73d1fdc40e9ea549',
  'libmpv_ios.xcframework.zip':
      '18235b759fcd7591dc5da987119a32d16b76f45601e92b73d80d4b80406f09aa',
  'libmpv_linux-aarch64.so':
      '4f68d40ac29240d19f4a5770346496cc4b23f0d2436ef608bce8ff65f00727cb',
  'libmpv_linux-x86_64.so':
      'b44be4f526d74825fd9f4d2f9b6a2362cd3dabc5434ac83c412f652ff94495cd',
  'libmpv_macos.xcframework.zip':
      'a734a0526b3a536709ceb1cd7ee4caa4a2045e7ddfe910e376269bbe5f4234d3',
  'libmpv_tizen-armv7l.so':
      '6dbe648b566264c7d920d4c52e1ee39b253fc3ac004c4f39a40e2f953fa9f112',
  'libmpv_tizen-x86_64.so':
      'a388ced43ef043b1b929b56ef5b9dfeb24d302139a29838a56df9ef5189e3876',
  'libmpv_windows-arm64.dll':
      '50297806c489266eeccffa8d92315a465f382db621dca9173976b5f6a94e1aa7',
  'libmpv_windows-x86_64.dll':
      '1ba497325c21b83f23369f3e51f55792929454f278b2f81dc9f304a0b13eabaa',
};

/// The tizen user define, true or false. Anything else fails the build: an
/// emulator build would bundle the desktop library and fail when it loads.
bool _tizen(BuildInput input) => switch (input.userDefines['tizen']) {
  null || false => false,
  true => true,
  final other => throw ArgumentError(
    'mpv_audio_kit: the tizen user define is true or false, not $other',
  ),
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
    final target = _Target.of(
      code,
      iOSVersion: _iOSVersion(input),
      tizen: _tizen(input),
    );
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
        // beside it and its binary checked on each build; a local zip may,
        // so it is unpacked again each build.
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
          zipSha256: local == null ? _sha256[target.asset] : null,
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

  static _Target of(CodeConfig code, {int? iOSVersion, bool tizen = false}) {
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
      // flutter-tizen (https://github.com/flutter-tizen/flutter-tizen)
      // writes linux with the arch of the Tizen build: arm for the TVs,
      // which Flutter's Linux desktop never builds, and x64 for the TV
      // emulator, which it does, so there the app sets the tizen user define.
      OS.linux => _Target(switch ((arch, tizen)) {
        (Architecture.arm, _) => 'libmpv_tizen-armv7l.so',
        (Architecture.x64, true) => 'libmpv_tizen-x86_64.so',
        (Architecture.x64, false) => 'libmpv_linux-x86_64.so',
        (Architecture.arm64, false) => 'libmpv_linux-aarch64.so',
        _ => unsupported(),
      }, 'libmpv_audio_kit.so'),
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
/// build that asks for the same checksum. The assets of other releases are
/// pruned from [cacheDir] after it.
Future<File> _fetch(String asset, Uri cacheDir) async {
  final expected = _sha256[asset];
  if (expected == null || expected.isEmpty) {
    throw StateError('mpv_audio_kit: no SHA-256 pinned for $asset');
  }
  final file = await fetchPinned(
    asset: asset,
    release: _release,
    url: '$_baseUrl/$asset',
    sha256Hex: expected,
    cacheDir: cacheDir,
  );
  await pruneCache(cacheDir, _sha256.values);
  return file;
}

/// Copies the libmpv binary of the xcframework slice, unpacked from [zip]
/// into [dir] and checked by [unpackedBinary], into [out], thinned to
/// [arch] when the slice is universal: Flutter runs the hook once per
/// architecture and merges the results itself.
Future<void> _extractAppleSlice(
  File zip,
  Directory dir,
  _Target target,
  Architecture arch,
  File out, {
  String? zipSha256,
}) async {
  // A macOS framework keeps its binary under Versions/; the path returned
  // follows the link.
  final binary = await unpackedBinary(
    zip,
    dir,
    'libmpv.xcframework/${target.appleSlice}/libmpv.framework/libmpv',
    zipSha256: zipSha256,
  );
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
