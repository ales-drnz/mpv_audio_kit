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
import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

import 'libmpv_resolver.dart';
import 'setter_test_helpers.dart';

/// Why the shim cannot be built on this host, or `null` when a C compiler
/// answers. Checked while the tests are declared, so a missing compiler
/// skips them (or fails them on CI) instead of letting them pass empty.
String? shimSkipReason() {
  try {
    if (Process.runSync('cc', ['--version']).exitCode == 0) return null;
  } on ProcessException {
    // Not on PATH.
  }
  return 'no host C compiler, cannot build the slow-core shim';
}

/// Declares a suite that runs [body] against libmpv behind the shim.
/// [shim] is set before [body]'s own setup runs. Without libmpv, a
/// fixture or a C compiler, the tests are skipped, and on CI they fail:
/// there all of them are always there.
void slowCoreShimSuite(
  void Function(SlowCoreShim Function() shim) body, {
  int getDelayUs = 0,
  int setDelayUs = 0,
  String? fixturePath,
  List<String> extraFixtures = const [],
}) {
  final noCc = shimSkipReason();
  if (noCc != null) {
    if (Platform.environment['CI'] == 'true') {
      test('a host C compiler is available', () => fail(noCc));
      return;
    }
    group(
      'slow-core shim',
      () => body(() => throw StateError(noCc)),
      skip: noCc,
    );
    return;
  }
  SlowCoreShim? built;
  runtimeSuite(
    initialize: false,
    fixturePath: fixturePath,
    extraFixtures: extraFixtures,
    () {
      setUpAll(() async {
        // rootBundle must work for the TLS CA bundle extraction in bring-up.
        TestWidgetsFlutterBinding.ensureInitialized();
        final shim = (await SlowCoreShim.build())!;
        shim.configure(
          realLibmpvPath: resolveLibmpv()!,
          getDelayUs: getDelayUs,
          setDelayUs: setDelayUs,
        );
        MpvAudioKit.ensureInitialized(
          libmpv: shim.path,
          hotRestartCleanup: false,
        );
        built = shim;
      });
      body(() => built!);
    },
  );
}

/// A compiled slow-core shim library, ready to be handed to
/// `MpvAudioKit.ensureInitialized(libmpv: …)`.
class SlowCoreShim {
  SlowCoreShim._(this.path) : _lib = DynamicLibrary.open(path);

  /// Absolute path of the compiled shim dylib/so.
  final String path;

  final DynamicLibrary _lib;

  /// Compiles the shim with the host C compiler into a fresh temp dir.
  /// Returns `null` when no usable `cc` is on PATH.
  static Future<SlowCoreShim?> build() async {
    if (shimSkipReason() != null) return null;
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
      '-lpthread',
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
    final fn = _lib
        .lookupFunction<
          Void Function(Pointer<Utf8>, Int32, Int32),
          void Function(Pointer<Utf8>, int, int)
        >('mak_shim_configure');
    _withString(realLibmpvPath, (p) => fn(p, getDelayUs, setDelayUs));
  }

  /// Sets a probe knob: `hook_add_delay_us` (a sleep in front of every
  /// `mpv_hook_add`), `destroy_delay_us` (a sleep in front of every
  /// `mpv_terminate_destroy`) or `hide_eof` (non-zero: synchronous flag
  /// reads of `eof-reached` answer 0, the reads the event isolate makes).
  void set(String knob, int value) {
    final fn = _lib
        .lookupFunction<
          Void Function(Pointer<Utf8>, Int32),
          void Function(Pointer<Utf8>, int)
        >('mak_shim_set');
    _withString(knob, (p) => fn(p, value));
  }

  /// Counts the synchronous reads of the property [name] from now on.
  /// Read the count with `counter('watched_gets')`.
  void watchGet(String name) {
    final fn = _lib
        .lookupFunction<
          Void Function(Pointer<Utf8>),
          void Function(Pointer<Utf8>)
        >('mak_shim_watch_get');
    _withString(name, fn);
  }

  /// Holds the reply to the next async request naming [name] (a command
  /// such as `loadfile`, or the property of a get or a set) for [hold]:
  /// mpv runs the request at once, and the reply reaches the player late,
  /// with every event behind it. `counter('replies_held')` counts the
  /// holds that started.
  void holdReply(String name, Duration hold) {
    final fn = _lib
        .lookupFunction<
          Void Function(Pointer<Utf8>, Int32),
          void Function(Pointer<Utf8>, int)
        >('mak_shim_hold_reply');
    _withString(name, (p) => fn(p, hold.inMicroseconds));
  }

  /// Refuses every `loadfile` whose URL contains [marker] before it
  /// reaches mpv, with the error of a full reply queue
  /// ([MpvError.mpvErrorEventQueueFull]), the only way mpv turns down an
  /// append. An empty [marker] refuses none. `counter('loadfiles_refused')`
  /// counts them.
  void refuseLoadfile(String marker) {
    final fn = _lib
        .lookupFunction<
          Void Function(Pointer<Utf8>),
          void Function(Pointer<Utf8>)
        >('mak_shim_refuse_loadfile');
    _withString(marker, fn);
  }

  /// A probe counter: `hook_adds_entered`, `hook_adds_inflight`,
  /// `inflight_at_destroy` (the most `mpv_hook_add` calls still running at
  /// an `mpv_terminate_destroy`), `late_hook_adds` (calls on a handle
  /// already destroyed, which the shim does not forward), `destroys`,
  /// `hooks_pending_at_destroy` (hooks mpv fired and nobody continued
  /// before the destroy), `watched_gets`, `replies_held` and
  /// `loadfiles_refused`.
  int counter(String name) {
    final fn = _lib
        .lookupFunction<
          Int32 Function(Pointer<Utf8>),
          int Function(Pointer<Utf8>)
        >('mak_shim_counter');
    return _withString(name, fn);
  }

  /// Zeroes the counters and the knobs. The stalls stay.
  void reset() =>
      _lib.lookupFunction<Void Function(), void Function()>('mak_shim_reset')();

  static T _withString<T>(String s, T Function(Pointer<Utf8>) f) {
    final p = s.toNativeUtf8();
    try {
      return f(p);
    } finally {
      calloc.free(p);
    }
  }
}
