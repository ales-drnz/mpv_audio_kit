// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// Builds and configures the slow-core libmpv interposer
// (`native/mak_slow_core_shim.c`). Tests point
// `MpvAudioKit.ensureInitialized(libmpv: shim.path)` at the compiled shim
// so every synchronous property/command call pays a configurable stall —
// a deterministic stand-in for a busy mpv playloop (e.g. CoreAudio waking
// a Bluetooth/AirPlay device for seconds during AO init).

import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

/// A compiled slow-core shim library, ready to be handed to
/// `MpvAudioKit.ensureInitialized(libmpv: …)`.
class SlowCoreShim {
  SlowCoreShim._(this.path);

  /// Absolute path of the compiled shim dylib/so.
  final String path;

  /// Compiles the shim with the host C compiler into a fresh temp dir.
  /// Returns `null` when no usable `cc` is on PATH (callers skip the test).
  static Future<SlowCoreShim?> build() async {
    try {
      final probe = await Process.run('cc', ['--version']);
      if (probe.exitCode != 0) return null;
    } on ProcessException {
      return null;
    }
    final src =
        '${Directory.current.path}/test/_helpers/native/mak_slow_core_shim.c';
    final outDir = Directory.systemTemp.createTempSync('mak_slow_core_shim');
    final ext = Platform.isMacOS ? 'dylib' : 'so';
    final out = '${outDir.path}/libmpv_slow_core_shim.$ext';
    final result = await Process.run('cc', [
      '-shared',
      '-fPIC',
      '-O1',
      '-o',
      out,
      src,
      '-ldl',
    ]);
    if (result.exitCode != 0) {
      throw StateError(
        'shim compile failed (rc=${result.exitCode}):\n'
        '${result.stdout}\n${result.stderr}',
      );
    }
    return SlowCoreShim._(out);
  }

  /// Points the shim at the real libmpv and sets the per-call stalls.
  /// Must run BEFORE the first `Player()` — the shim resolves the real
  /// symbols here, and every isolate that later dlopens the same path
  /// shares this process-wide state.
  void configure({
    required String realLibmpvPath,
    int getDelayUs = 0,
    int setDelayUs = 0,
  }) {
    final lib = DynamicLibrary.open(path);
    final fn = lib
        .lookupFunction<
          Void Function(Pointer<Utf8>, Int32, Int32),
          void Function(Pointer<Utf8>, int, int)
        >('mak_shim_configure');
    final p = realLibmpvPath.toNativeUtf8();
    try {
      fn(p, getDelayUs, setDelayUs);
    } finally {
      calloc.free(p);
    }
  }
}
