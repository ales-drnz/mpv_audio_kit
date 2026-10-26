// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:meta/meta.dart';

import '../backend/backend.dart' as backend;
import '../player/player.dart' show Player;

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

  /// Whether the browser holds the sound of every player until the user
  /// interacts with the page: its autoplay policy starts the page's audio
  /// output suspended. Meanwhile a playing player stays at its position
  /// and nothing is heard. The first click, tap or key press resumes it,
  /// and so does [Player.play] called from one. Always `false` outside the
  /// web.
  ///
  /// An app that starts playback on its own (a restored session) can show
  /// a prompt while this is `true`.
  static bool get needsUserGesture => backend.outputNeedsGesture;

  /// [needsUserGesture] at each change, from the moment the web module has
  /// loaded. Never emits outside the web.
  static Stream<bool> get needsUserGestureStream =>
      backend.outputNeedsGestureChanges;

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
  /// app's pubspec instead. A custom libmpv should carry the patches of
  /// libmpv-scripts 0.3.0 (libmpv-r20) or later. With an older build, or
  /// one of upstream mpv, the player still plays, and a warning on
  /// `PlayerStream.internalLog` lists what each missing patch takes away.
  /// On Windows an unpatched mpv also crashes the process at every
  /// [Player] dispose, and `previousPlaylist` can crash it too.
  ///
  /// On the web [libmpv] is the URL of the `libmpv.mjs` of another build of
  /// the web module, with its `libmpv.wasm` and
  /// `mak_webaudio_processor.js` beside it on the page's origin; `null`
  /// loads the one the package ships as web assets. The module loads in the
  /// background from this call on, and the first [Player] waits for it.
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
  /// On the web it destroys the players, PCM sources and audio output the
  /// app left in the page before a Hot Restart, and reuses its module.
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
