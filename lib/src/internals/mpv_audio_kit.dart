// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:meta/meta.dart';

import '../backend/backend.dart' as backend;

/// One-time initialization for `mpv_audio_kit`. Owns the choice of the
/// libmpv the players use and the cleanup of the cores that leaked across
/// Flutter Hot-Restarts, both of which the backend carries out.
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
  /// `releasesPcmSourcesAtInit`), it also releases the live PCM sources of
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
    backend.startBackend(libmpv: libmpv, hotRestartCleanup: hotRestartCleanup);
    _libraryPath = libmpv;
    _initialized = true;
    if (hotRestartCleanup) backend.backendInitialized();
  }
}
