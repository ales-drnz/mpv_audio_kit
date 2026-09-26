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
/// asset under `build/native_assets/<os>/`, named as the hook names it.
/// Returns `null` when it is not there.
String? resolveLibmpv() {
  final dir = '${Directory.current.path}/build/native_assets';
  final path = switch (Platform.operatingSystem) {
    'linux' => '$dir/linux/libmpv_audio_kit.so',
    'macos' => '$dir/macos/libmpv_audio_kit.framework/libmpv_audio_kit',
    'windows' => '$dir\\windows\\mpv_audio_kit.dll',
    _ => null,
  };
  return path != null && File(path).existsSync() ? path : null;
}
