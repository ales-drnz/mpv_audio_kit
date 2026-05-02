// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
part of 'player.dart';

/// Hook setters: register / continue mpv hooks. Hooks let you intercept
/// mpv's file-loading pipeline to lazily resolve a URL, inject per-file
/// HTTP headers, or redirect to a different source.
///
/// Usage pattern:
/// ```dart
/// player.registerHook(Hook.load);
/// player.stream.hook.listen((event) async {
///   if (event.hook == Hook.load) {
///     final url = await player.getRawProperty('stream-open-filename') ?? '';
///     // Optionally redirect the URL:
///     await player.setRawProperty('stream-open-filename', newUrl);
///     // Optionally set per-file HTTP headers:
///     await player.setRawProperty(
///         'file-local-options/http-header-fields', 'X-Token: abc');
///   }
///   player.continueHook(event.id); // must always be called
/// });
/// ```
mixin _HooksModule on _PlayerBase {
  /// Registers an mpv hook for [hook] with optional [priority].
  ///
  /// Hook events are delivered via [PlayerStream.hook]. Call
  /// [continueHook] with the event's [MpvHookEvent.id] when processing
  /// is complete — until then, mpv suspends the operation guarded by
  /// this hook.
  ///
  /// If [timeout] is provided, the library automatically calls
  /// [continueHook] after the given duration if the consumer hasn't
  /// called it yet. Prevents mpv from stalling indefinitely on
  /// unhandled exceptions in the listener.
  ///
  /// Idempotent per [hook]: calling [registerHook] more than once for
  /// the same hook on the same [Player] only updates the optional
  /// [timeout]; the underlying mpv registration happens once. mpv
  /// allows multiple registrations per name but its shutdown path can
  /// stall when several events for the same hook are still active at
  /// `quit` — the wrapper avoids that race by collapsing duplicates
  /// here.
  ///
  /// See [Hook] for the full set of available phases. Higher
  /// [priority] values run earlier; the default (0) is fine for most
  /// uses.
  void registerHook(Hook hook, {int priority = 0, Duration? timeout}) {
    _checkNotDisposed();
    final name = hook.mpvName;
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
