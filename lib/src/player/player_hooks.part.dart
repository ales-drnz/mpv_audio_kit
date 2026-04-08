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
  /// Common hook names:
  /// - `"on_load"` — before a stream is opened; can redirect the URL.
  /// - `"on_load_fail"` — after a stream fails to open.
  /// - `"on_preloaded"` — after the file is pre-loaded but before playback starts.
  ///
  /// Higher [priority] values run earlier. The default (0) is fine for most uses.
  void registerHook(String name, {int priority = 0, Duration? timeout}) {
    _checkNotDisposed();
    if (timeout != null) _hookTimeouts[name] = timeout;
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
  /// Must be called exactly once per [MpvHookEvent] received on
  /// [PlayerStream.hook], even if your processing fails — otherwise mpv
  /// will stall indefinitely waiting for the hook to return.
  void continueHook(int id) {
    _hookTimers.remove(id)?.cancel();
    _checkNotDisposed();
    _lib.mpvHookContinue(_handle, id);
  }

}
