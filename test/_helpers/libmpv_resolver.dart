// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:io';

/// Resolves the bundled libmpv path for the current host so the runtime
/// test files don't need to repeat the platform branching.
///
/// The build scripts in `scripts/build_libmpv_*.sh` write each
/// platform's binary to a stable location at the repo root:
///   - macOS  → `macos/libs/libmpv.dylib`
///   - Linux  → `linux/libs/libmpv.so`
///   - Windows → `windows/libs/libmpv-2.dll`
///
/// Returns `null` on platforms without a pre-built binary (Android,
/// iOS) or when the file is missing — call sites use it to mark the
/// test group as skipped instead of failing.
String? resolveLibmpv() {
  final root = Directory.current.path;
  if (Platform.isMacOS) {
    final p = '$root/macos/libs/libmpv.dylib';
    return File(p).existsSync() ? p : null;
  }
  if (Platform.isLinux) {
    final p = '$root/linux/libs/libmpv.so';
    return File(p).existsSync() ? p : null;
  }
  if (Platform.isWindows) {
    final p = '$root\\windows\\libs\\libmpv-2.dll';
    return File(p).existsSync() ? p : null;
  }
  return null;
}
