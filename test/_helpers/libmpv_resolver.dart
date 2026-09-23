// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:ffi';
import 'dart:io';

/// Resolves the bundled libmpv path for the current host so the runtime
/// test files don't need to repeat the platform branching.
///
/// The bundled binary lives under the repo root at:
///   - macOS  → `macos/mpv_audio_kit/Frameworks/libmpv.xcframework/macos-arm64_x86_64/libmpv.framework/libmpv`
///   - Linux  → `linux/libs/<arch>/libmpv.so`        (`<arch>`: `x86_64` | `aarch64`)
///   - Windows → `windows/libs/<arch>/libmpv.dll`    (`<arch>`: `x86_64` | `arm64`)
///
/// The host arch is derived from `Abi.current()`. Returns `null` on
/// platforms without a pre-built binary (Android, iOS) or when the file
/// is missing — call sites use it to mark the test group as skipped
/// instead of failing.
String? resolveLibmpv() {
  final root = Directory.current.path;
  if (Platform.isMacOS) {
    // The xcframework may carry the universal slice (a release build) or a
    // single-arch slice (a dev build, e.g. `go run . macos-arm64`). Try the
    // universal name first, then the host-arch one. Two base dirs cover the
    // SwiftPM layout (`macos/mpv_audio_kit/Frameworks/…`) and the older
    // pre-SwiftPM one.
    final archSlice = switch (Abi.current()) {
      Abi.macosArm64 => 'macos-arm64',
      Abi.macosX64 => 'macos-x86_64',
      _ => null,
    };
    final slices = ['macos-arm64_x86_64', ?archSlice];
    for (final base in [
      '$root/macos/mpv_audio_kit/Frameworks',
      '$root/macos/Frameworks',
    ]) {
      for (final slice in slices) {
        final p = '$base/libmpv.xcframework/$slice/libmpv.framework/libmpv';
        if (File(p).existsSync()) return p;
      }
    }
    return null;
  }
  if (Platform.isLinux) {
    final arch = switch (Abi.current()) {
      Abi.linuxArm64 => 'aarch64',
      Abi.linuxX64 => 'x86_64',
      _ => null,
    };
    if (arch == null) return null;
    final p = '$root/linux/libs/$arch/libmpv.so';
    return File(p).existsSync() ? p : null;
  }
  if (Platform.isWindows) {
    final arch = switch (Abi.current()) {
      Abi.windowsArm64 => 'arm64',
      Abi.windowsX64 => 'x86_64',
      _ => null,
    };
    if (arch == null) return null;
    final p = '$root\\windows\\libs\\$arch\\libmpv.dll';
    return File(p).existsSync() ? p : null;
  }
  return null;
}
