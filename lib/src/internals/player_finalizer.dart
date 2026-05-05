// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

import 'dart:ffi';

import 'package:meta/meta.dart';

import '../mpv_bindings.dart';
import 'debug_log.dart';
import 'orphan_handle_tracker.dart';

/// Native-resource bag attached to a `Player` via [Finalizer].
///
/// Wraps the raw `mpv_handle*` and the `MpvLibrary` needed to call
/// `mpv_terminate_destroy` on it. The owning player flips [disposed]
/// the moment its `dispose()` runs; the finalizer then becomes a
/// no-op when the GC eventually collects the player.
@internal
class PlayerNativeResources {
  PlayerNativeResources(this.lib, this.handle);

  final MpvLibrary lib;
  final Pointer<MpvHandle> handle;
  bool disposed = false;
}

/// Process-wide finalizer that fires when a `Player` instance is
/// garbage-collected without its `dispose()` having run.
///
/// Standard cleanup goes through the explicit `Player.dispose()` path
/// — this is a safety net for consumers that drop a player on the
/// floor (e.g. an exception unwinds before they can `await dispose()`).
/// The handle still carries an exclusive-mode AO lock at that point,
/// so leaking it without a `quit` keeps the device captured until the
/// host process exits.
///
/// **Hot-Restart is a separate story.** Finalizers don't fire when
/// the Dart VM is replaced — for that path the [OrphanHandleTracker]
/// rehydrates the orphan list across VM lifetimes.
@internal
final Finalizer<PlayerNativeResources> playerFinalizer =
    Finalizer<PlayerNativeResources>(_finalize);

void _finalize(PlayerNativeResources resources) {
  if (resources.disposed) return;
  try {
    debugLog(
      'mpv_audio_kit: Player garbage-collected without dispose() '
      '(handle=${resources.handle.address}). Reclaiming via '
      'mpv_terminate_destroy. Always `await player.dispose()` to '
      'avoid this safety net.',
    );
    OrphanHandleTracker.instance.remove(resources.handle);
    resources.lib.mpvTerminateDestroy(resources.handle);
  } catch (e) {
    debugLog('mpv_audio_kit: finalizer cleanup failed: $e');
  } finally {
    resources.disposed = true;
  }
}
