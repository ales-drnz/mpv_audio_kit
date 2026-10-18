// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart' show RootIsolateToken;
import 'package:meta/meta.dart';

import '../media_session/media_session_channel.dart';
import '../mpv_bindings.dart';
import 'debug_log.dart';
import 'orphan_handle_tracker.dart';
import 'owner_watch.dart';
import 'pcm_native.dart';

/// How long Hot-Restart cleanup waits, after waking a leaked core with
/// `quit`, before destroying its handle. The previous VM's event isolate
/// may still be parked inside `mpv_wait_event` on that handle, and a Dart
/// isolate blocked in a synchronous FFI call can't be killed until it
/// returns to a safepoint: destroying the handle before then frees the
/// mutex it sleeps on (use-after-free). This comfortably exceeds the
/// 0.1 s debug wait-event timeout so the isolate has provably unwound.
const Duration _kOrphanReapDelay = Duration(milliseconds: 500);

/// Two-phase teardown for libmpv handles leaked across a Hot-Restart.
///
/// Phase 1 sends `quit` to each handle, which wakes the leaked core so the
/// previous VM's event isolate returns from `mpv_wait_event`, sees
/// MPV_EVENT_SHUTDOWN and is reaped. `quit` alone does NOT free the core's
/// worker threads or audio output. Phase 2, after [delay], destroys each
/// handle (`mpv_terminate_destroy` joins the core thread and releases the
/// audio output): deferred so the destroy never races an isolate still
/// inside the syscall (use-after-free).
///
/// With [stopAnalysis], phase 1 first turns off the waveform, the loudness
/// scan and the analyzer taps. libmpv keeps them per process, not per core,
/// and the previous VM never ran the dispose that turns them off: left on,
/// every file the new VM opens is decoded for nobody.
@internal
Future<void> reapOrphanedHandles(
  MpvLibrary lib,
  List<Pointer<MpvHandle>> references, {
  Duration delay = _kOrphanReapDelay,
  bool stopAnalysis = true,
}) async {
  const tag = 'mpv_audio_kit:';
  for (final ref in references) {
    for (final command in [if (stopAnalysis) ...analysisOffCommands, 'quit']) {
      final cmd = command.toNativeUtf8();
      try {
        lib.mpvCommandString(ref, cmd);
      } catch (e) {
        debugLog('$tag Error sending "$command" to a leaked handle: $e');
      } finally {
        calloc.free(cmd);
      }
    }
  }

  await Future<void>.delayed(delay);

  for (final ref in references) {
    try {
      lib.mpvTerminateDestroy(ref);
    } catch (e) {
      debugLog('$tag Error terminating leaked handle: $e');
    }
  }
}

/// One-time initialization for `mpv_audio_kit`. Owns the libmpv
/// `DynamicLibrary` lookup and the orphaned-handle cleanup that fires
/// across Flutter Hot-Restarts.
abstract final class MpvAudioKit {
  MpvAudioKit._();

  static bool _initialized = false;
  static String? _libraryPath;

  /// Whether [ensureInitialized] ran in this isolate.
  @internal
  static bool get isInitialized => _initialized;

  /// Returns the path used to initialize the library, if provided.
  static String? get libraryPath => _libraryPath;

  /// Initializes the native backend for `mpv_audio_kit`.
  /// Must be called before creating any [Player] instances.
  ///
  /// Its settings hold per isolate: a [Player] created in another isolate
  /// needs a call there too, with the same [libmpv] and
  /// `hotRestartCleanup: false`.
  ///
  /// Handles cleanup of orphaned `libmpv` native resources
  /// (e.g., handles that leaked across a Flutter Hot-Restart).
  ///
  /// [libmpv] (optional): explicit path or filename for the native
  /// `libmpv` library to load via `DynamicLibrary.open`. When `null`
  /// (the default), the libmpv the package's build hook bundles with the
  /// app is used. Pass an explicit path only when shipping a custom
  /// libmpv build alongside your app; to bundle one in place of the
  /// default, set `hooks: user_defines: mpv_audio_kit: libmpv:` in the
  /// app's pubspec instead. On Windows a custom libmpv needs the patches
  /// of libmpv-scripts 0.1.7 or later: with an unpatched mpv, every
  /// [Player] dispose crashes the process, and `previousPlaylist` can
  /// crash it too.
  ///
  /// [hotRestartCleanup] (default: `true`): recovers libmpv handles
  /// leaked across a Flutter Hot-Restart so they don't keep
  /// exclusive-mode audio devices locked. In the root isolate only (see
  /// [releasesPcmSourcesAtInit]), it also releases the live PCM sources of
  /// the replaced VM, turns off the waveform, loudness scan and filter taps
  /// its listeners left on, and disables its OS media session. Pass `false`
  /// in test runners, background isolates and other multi-VM scenarios
  /// that share a pid: in a debug build the tracker would otherwise take
  /// the live handles of the other isolate for orphans and destroy them.
  static void ensureInitialized({
    String? libmpv,
    bool hotRestartCleanup = true,
  }) {
    if (_initialized) {
      return;
    }

    _applyPlatformQuirks();

    if (!hotRestartCleanup) {
      _libraryPath = libmpv;
      _initialized = true;
      return;
    }

    OrphanHandleTracker.instance.ensureInitialized((references) {
      if (references.isEmpty) {
        return;
      }

      const tag = 'mpv_audio_kit: OrphanHandleTracker:';
      debugLog('$tag Found ${references.length} orphaned reference(s).');
      debugLog('$tag Releasing leaked handles (Hot-Restart fix):');

      for (final ref in references) {
        debugLog(' - Address: ${ref.address}');
      }

      // Best effort: MpvLibraryException is not public, and a library
      // that cannot be reopened leaves the handles to the process exit.
      final MpvLibrary lib;
      try {
        lib = MpvLibrary.open(libmpv);
      } on MpvLibraryException catch (e) {
        debugLog('$tag cannot reopen libmpv: ${e.message}');
        return;
      }
      // The analysis switches are process-wide, like the PCM sources below:
      // only the root isolate a Hot-Restart replaced turns them off.
      unawaited(
        reapOrphanedHandles(
          lib,
          references,
          stopAnalysis: releasesPcmSourcesAtInit(
            restarted: OrphanHandleTracker.instance.restarted,
          ),
        ),
      );
    });

    _libraryPath = libmpv;
    _initialized = true;
    if (releasesPcmSourcesAtInit(
      restarted: OrphanHandleTracker.instance.restarted,
    )) {
      _releasePcmSources();
      _disableMediaSession();
    }
  }

  /// Aborts and frees the live PCM sources of the VM a Hot-Restart
  /// replaced: the native side outlives it, and their readers would wait
  /// on input that never comes. See [releasesPcmSourcesAtInit].
  static void _releasePcmSources() {
    try {
      pcmNative().releaseAll();
    } catch (e) {
      // A custom libmpv without the live PCM input: nothing to release.
      debugLog('mpv_audio_kit: no PCM sources to release: $e');
    }
  }

  /// Turns off the OS media session of the VM a Hot-Restart replaced. The
  /// engine and its plugins outlive the VM: the notification, the lock
  /// screen entry and the audio focus stay, still showing the old track,
  /// and their buttons reach no listener. Sent before any `enable` of
  /// this VM, on the same channel, so it lands first.
  static void _disableMediaSession() {
    // Needs the services binding (`WidgetsFlutterBinding.ensureInitialized`
    // first, as the README shows): without it the session stays on.
    unawaited(
      MediaSessionChannel().disable().catchError((Object e) {
        debugLog('mpv_audio_kit: cannot disable the old media session: $e');
      }),
    );
  }

  /// Sets `LC_NUMERIC=C` process-wide on Linux and macOS: mandated
  /// by libmpv's API contract (`mpv/client.h`; mpv aborts loading
  /// otherwise).
  ///
  /// Process-wide is non-negotiable: mpv spawns its own threads at
  /// `mpv_create` time, and POSIX threads inherit `LC_GLOBAL_LOCALE`,
  /// not `uselocale`. Other locale categories (`LC_TIME`,
  /// `LC_MESSAGES`, …) are left untouched.
  static void _applyPlatformQuirks() {
    if (Platform.isWindows || Platform.isAndroid) {
      return;
    }

    try {
      final DynamicLibrary libc = Platform.isLinux
          ? DynamicLibrary.open('libc.so.6')
          : DynamicLibrary.open('libSystem.B.dylib');

      final setlocale = libc
          .lookupFunction<
            Pointer<Utf8> Function(Int32, Pointer<Utf8>),
            Pointer<Utf8> Function(int, Pointer<Utf8>)
          >('setlocale');

      // The LC_NUMERIC constant is libc-specific: glibc (Linux) numbers
      // it 1, the BSD layout (macOS and iOS) numbers it 4: there, 1 is
      // LC_COLLATE, which would leave the numeric locale untouched.
      final lcNumeric = Platform.isLinux ? 1 : 4;
      using((arena) {
        setlocale(lcNumeric, 'C'.toNativeUtf8(allocator: arena));
      });
    } catch (e) {
      debugLog(
        'mpv_audio_kit: setlocale failed: $e. '
        'mpv might fail to initialize if system locale is not compatible.',
      );
    }
  }
}

/// Whether [MpvAudioKit.ensureInitialized] releases every live PCM source
/// of the process: only after a Hot-Restart ([restarted], which the
/// debug-only orphan tracker detects), and only in the root isolate.
///
/// The sources are process-wide. A release at every init would cut those
/// of the other players and isolates, and the tracker also reports a
/// restart to a second isolate of the same process (the process
/// environment already holds its buffer), whose own release would cut the
/// sources of the first.
/// Hot-Restart replaces the root isolate, which alone holds a
/// `RootIsolateToken`. A second Flutter engine in the process (add-to-app)
/// has a root isolate of its own: pass `hotRestartCleanup: false` there.
/// The orphan reap turns off the analysis switches, process-wide too, under
/// the same guard.
@internal
bool releasesPcmSourcesAtInit({required bool restarted}) =>
    restarted && RootIsolateToken.instance != null;
