// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
part of '../player.dart';

/// Module for mpv hook registration and continuation.
///
/// Hooks let you intercept mpv's file-loading pipeline and modify how a
/// stream is opened — for example to lazily resolve a URL, inject per-file
/// HTTP headers, or redirect to a different source.
///
/// Usage pattern:
/// ```dart
/// player.registerHook('on_load');
/// player.stream.hook.listen((event) async {
///   if (event.name == 'on_load') {
///     final url = player.getRawProperty('stream-open-filename') ?? '';
///     // Optionally redirect the URL:
///     player.setRawProperty('stream-open-filename', newUrl);
///     // Optionally set per-file HTTP headers:
///     player.setRawProperty('file-local-options/http-header-fields', 'X-Token: abc');
///   }
///   player.continueHook(event.id); // must always be called
/// });
/// ```
mixin _HooksModule on _PlayerBase {

  /// Registers an mpv hook with [name] and optional [priority].
  ///
  /// Hook events are delivered via [PlayerStream.hook].
  /// Call [continueHook] with the event's [MpvHookEvent.id] when processing
  /// is complete. Until then, mpv suspends the operation guarded by this hook.
  ///
  /// If [timeout] is provided, the library automatically calls [continueHook]
  /// after the given duration if the consumer hasn't called it yet. This
  /// prevents mpv from stalling indefinitely due to unhandled exceptions in
  /// hook listeners.
  ///
  /// Idempotent per [name]: calling [registerHook] more than once for the
  /// same hook name on the same [Player] only updates the optional
  /// [timeout]; the underlying mpv registration happens once. mpv allows
  /// multiple registrations per name but its shutdown path can stall when
  /// several events for the same hook are still active at `quit` — the
  /// wrapper avoids that race by collapsing duplicates here.
  ///
  /// Available hook names (mpv 0.41):
  /// - `"on_load"` — before a stream is opened; can redirect the URL via
  ///   `stream-open-filename` or set per-file options.
  /// - `"on_load_fail"` — after a stream failed to open; useful for
  ///   fallback URLs (only retried if `stream-open-filename` is rewritten).
  /// - `"on_preloaded"` — after open, before track selection / decoder
  ///   creation. Useful for manual track selection.
  /// - `"on_loaded"` — after track selection, before playback starts.
  ///   Useful for acting on selected-track metadata.
  /// - `"on_unload"` — before closing a file. Cannot resume playback in
  ///   this state.
  /// - `"on_before_start_file"` — drains property changes before a new
  ///   file's `start-file` event fires.
  /// - `"on_after_end_file"` — drains property changes after `end-file`.
  ///
  /// Higher [priority] values run earlier. The default (0) is fine for most uses.
  void registerHook(String name, {int priority = 0, Duration? timeout}) {
    _checkNotDisposed();
    if (timeout != null) _hookTimeouts[name] = timeout;
    if (_registeredHookNames.contains(name)) return;
    _registeredHookNames.add(name);
    using((arena) {
      _lib.mpvHookAdd(
        _handle,
        0,
        name.toNativeUtf8(allocator: arena),
        priority,
      );
    });
  }

  /// Signals mpv that hook processing for [id] is complete.
  ///
  /// Should be called exactly once per [MpvHookEvent] received on
  /// [PlayerStream.hook], even if your processing fails — otherwise mpv
  /// will stall indefinitely waiting for the hook to return.
  ///
  /// Idempotent on a per-id basis: a second [continueHook] call for the
  /// same id (a buggy double-dispatch in the consumer, or a manual
  /// continue racing the auto-timeout fallback) is dropped on the
  /// wrapper side and never reaches mpv. mpv's behaviour for an
  /// already-continued id is undefined across versions, so the wrapper
  /// tracks the active set in [_activeHookIds].
  ///
  /// Calling with an invalid [id] (zero or negative — typo in a consumer
  /// dispatch table) is also a no-op: the wrapper logs a warning on
  /// [PlayerStream.internalLog] and skips the FFI call.
  void continueHook(int id) {
    _checkNotDisposed();
    if (id <= 0) {
      _internalLog(
        'continueHook: ignored invalid hook id $id (must be a positive '
        'integer obtained from MpvHookEvent.id)',
        level: 'warn',
      );
      return;
    }
    if (!_activeHookIds.remove(id)) {
      // Already continued (manual + auto-timer race, or consumer
      // double-dispatch). Drop silently — the first continue already
      // unblocked mpv.
      return;
    }
    _hookTimers.remove(id)?.cancel();
    _lib.mpvHookContinue(_handle, id);
  }
}
