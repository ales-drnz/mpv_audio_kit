// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

// Build hook: fetches the libmpv binary for the target from the
// libmpv-<release> GitHub release, checks its SHA-256 and bundles it as the
// code asset `package:mpv_audio_kit/libmpv`, which lib/src/mpv_bindings.dart
// binds with @Native. One script for every platform, in place of a Gradle
// task, two podspecs, two SwiftPM manifests and two CMake files.
//
// Offline builds and custom binaries: point the app at a local file with
//
//   hooks:
//     user_defines:
//       mpv_audio_kit:
//         libmpv: path/to/the/library
//
// in the app's pubspec. The file is bundled as is, without a checksum.

import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:crypto/crypto.dart';
import 'package:hooks/hooks.dart';

const _release = 'libmpv-r15';
const _baseUrl =
    'https://github.com/ales-drnz/mpv_audio_kit/releases/download/$_release';

/// SHA-256 of every release asset, from the release's manifest.json.
const _sha256 = <String, String>{
  'libmpv_android-arm64-v8a.so':
      'f79ce1b57bd5145b8b6393d2f81902c267c4733b46ca077dcea93accf4ff7895',
  'libmpv_android-armeabi-v7a.so':
      '8be60980283cf01baf6f58517728fcb9443f703bca3630eef608b79612e28307',
  'libmpv_android-x86_64.so':
      '66b4df635c6f127dcee1d52e503e265b98924b9b1a538697f89f76ae3f2fa702',
  'libmpv_ios.xcframework.zip':
      'a255868b6cbdfdd7ab54eaf74c9e68b5519e6ddfc7d77659cafb41ea27dae959',
  'libmpv_linux-aarch64.so':
      '65348ed29cf110f729ac66777e7f6590bcf38130f7d6a00da6c9a8a3e9f663d8',
  'libmpv_linux-x86_64.so':
      'b5e4ea8e714c8bebfc1bb742c6fc9d91067671162002b123c4e7b8b9be928a3f',
  'libmpv_macos.xcframework.zip':
      'ea488e31c3d1a8620cb2a25572bae90573bcb2f4c24746da3dd497b19ad499ca',
  'libmpv_windows-arm64.dll':
      'b7d118a54ce6fe9168af21d637fb1d76619a80314ecc00a708b6bdfe11671320',
  'libmpv_windows-x86_64.dll':
      '3073c09acdb2bd4819f22222983dc926087fbd069f8fee4e754cc03437ab081f',
};

void main(List<String> args) async {
  await build(args, (input, output) async {
    if (!input.config.buildCodeAssets) return;
    final code = input.config.code;
    final target = _Target.of(code);
    final out = File.fromUri(input.outputDirectory.resolve(target.fileName));

    final local = input.userDefines.path('libmpv');
    if (local != null) {
      await File.fromUri(local).copy(out.path);
    } else {
      final asset = await _fetch(target.asset, input.outputDirectoryShared);
      if (target.appleSlice == null) {
        await asset.copy(out.path);
      } else {
        await _extractAppleSlice(asset, target, code.targetArchitecture, out);
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

/// Which release asset a target needs, and the file name it is bundled
/// under. The name is the package's own, never `libmpv`, so it cannot
/// collide with another plugin's copy on disk or in the loader (bionic
/// matches a dlopen by name against the SONAMEs already loaded; the SONAME
/// inside is the same). On Apple the file becomes
/// `mpv_audio_kit.framework/mpv_audio_kit`.
class _Target {
  const _Target(this.asset, this.fileName, {this.appleSlice});

  final String asset;
  final String fileName;

  /// The xcframework directory holding the slice, on Apple.
  final String? appleSlice;

  static _Target of(CodeConfig code) {
    final arch = code.targetArchitecture;
    Never unsupported() => throw UnsupportedError(
      'mpv_audio_kit: no libmpv for ${code.targetOS} '
      '$arch in $_release',
    );
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
        'mpv_audio_kit',
        appleSlice: 'macos-arm64_x86_64',
      ),
      OS.iOS => _Target(
        'libmpv_ios.xcframework.zip',
        'mpv_audio_kit',
        appleSlice: code.iOS.targetSdk == IOSSdk.iPhoneSimulator
            ? 'ios-arm64_x86_64-simulator'
            : 'ios-arm64',
      ),
      _ => unsupported(),
    };
  }
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
  final partial = File('${cached.path}.part');
  await _download('$_baseUrl/$asset', partial);
  if (!await _matches(partial, expected)) {
    await partial.delete();
    throw StateError(
      'mpv_audio_kit: SHA-256 mismatch for $asset from $_baseUrl',
    );
  }
  return partial.rename(cached.path);
}

/// Copies the libmpv binary of the xcframework slice into [out], thinned to
/// [arch] when the slice is universal: Flutter runs the hook once per
/// architecture and merges the results itself.
Future<void> _extractAppleSlice(
  File zip,
  _Target target,
  Architecture arch,
  File out,
) async {
  final dir = Directory('${zip.parent.path}/unzipped');
  final framework =
      '${dir.path}/libmpv.xcframework/${target.appleSlice}/libmpv.framework';
  if (!await dir.exists()) {
    // Unpack beside it and rename into place: the hook may run once per
    // architecture in parallel, and a rename is atomic where an unzip
    // into a shared directory is not.
    final staging = await zip.parent.createTemp('unzip-');
    await _run('unzip', ['-q', zip.path, '-d', staging.path]);
    try {
      await staging.rename(dir.path);
    } on FileSystemException {
      // Another run won the rename; its copy is identical.
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

Future<void> _download(String url, File target) async {
  final client = HttpClient()..findProxy = HttpClient.findProxyFromEnvironment;
  try {
    final response = await (await client.getUrl(Uri.parse(url))).close();
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException(
        'mpv_audio_kit: HTTP ${response.statusCode} for $url',
      );
    }
    await response.pipe(target.openWrite());
  } finally {
    client.close();
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
