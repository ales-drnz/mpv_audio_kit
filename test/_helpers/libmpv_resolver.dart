// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:io';

/// The file of the libmpv the build hook bundled for this `flutter test`
/// run, for the few tests that need the binary itself (reading its bytes,
/// loading it behind a shim) rather than the `@Native` bindings, which
/// resolve it on their own.
///
/// `flutter test` runs `hook/build.dart` for the host and places the code
/// asset under `build/native_assets/<os>/`, named as the hook names it. On
/// macOS the flutter tester installs the framework's binary as a bare
/// dylib, while an app build keeps the framework: both are looked for.
/// Returns `null` when it is not there.
String? resolveLibmpv() {
  final dir = '${Directory.current.path}/build/native_assets';
  final candidates = switch (Platform.operatingSystem) {
    'linux' => ['$dir/linux/libmpv_audio_kit.so'],
    'macos' => [
      '$dir/macos/libmpv_audio_kit',
      '$dir/macos/libmpv_audio_kit.framework/libmpv_audio_kit',
    ],
    'windows' => ['$dir\\windows\\mpv_audio_kit.dll'],
    _ => const <String>[],
  };
  for (final path in candidates) {
    if (File(path).existsSync()) return path;
  }
  return null;
}

List<int>? _libmpvBytes;

/// The libmpv-scripts release of the libmpv at [path], read from the
/// version string mpv keeps in the binary: `mpv v0.41.0+r17` gives 17.
/// `null` when the binary carries no release stamp (a build of upstream
/// mpv). Read while the tests are declared, before any player exists.
int? libmpvReleaseOf(String path) {
  final bytes = _libmpvBytes ??= File(path).readAsBytesSync();
  const prefix = 'mpv v';
  outer:
  for (var i = 0; i + prefix.length < bytes.length; i++) {
    for (var j = 0; j < prefix.length; j++) {
      if (bytes[i + j] != prefix.codeUnitAt(j)) continue outer;
    }
    final end = bytes.indexOf(0, i);
    if (end < 0 || end - i > 64) continue;
    final version = String.fromCharCodes(bytes.sublist(i, end));
    final release = RegExp(r'^mpv v[0-9.]+\+r(\d+)$').firstMatch(version);
    if (release != null) return int.parse(release.group(1)!);
  }
  return null;
}

/// Whether the libmpv at [path] carries [name] as a NUL-terminated string,
/// the form mpv's property table keeps its names in. Lets a suite that
/// needs a property of this build (`waveform-data`) decide its skip while
/// the tests are declared, before any player could ask the core.
bool libmpvNamesProperty(String path, String name) {
  final bytes = _libmpvBytes ??= File(path).readAsBytesSync();
  final needle = [0, ...name.codeUnits, 0];
  final first = needle[1];
  outer:
  for (var i = 1; i + needle.length - 1 <= bytes.length; i++) {
    if (bytes[i] != first || bytes[i - 1] != 0) continue;
    for (var j = 2; j < needle.length; j++) {
      if (bytes[i + j - 1] != needle[j]) continue outer;
    }
    return true;
  }
  return false;
}
