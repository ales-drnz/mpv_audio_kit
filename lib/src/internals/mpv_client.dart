// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../mpv_bindings.dart';
import 'reply_tracker.dart';

/// The player's asynchronous channel to libmpv: property writes, commands
/// and property reads go out through the `mpv_*_async` calls, and their
/// replies come back through the event isolate ([onReply], [onGetReply]).
///
/// No call waits on the playloop, so the main isolate never blocks on a
/// busy core. After [close] no call reaches libmpv: the handle is about to
/// be freed, and a continuation resumed by the drain must not touch it.
final class MpvClient {
  /// Creates a client for [handle], bound through [lib].
  MpvClient(this._lib, this._handle);

  final MpvLibrary _lib;
  final Pointer<MpvHandle> _handle;

  // Writes and commands resolve as accepted when drained, the behavior of
  // a call racing dispose before the API went async; reads resolve as
  // failed, which surfaces as a `null` value.
  final ReplyTracker _writes = ReplyTracker(
    drained: (MpvError.mpvErrorSuccess, null),
  );
  final ReplyTracker _reads = ReplyTracker(
    drained: (MpvError.mpvErrorGeneric, null),
  );
  bool _closed = false;

  /// Whether [close] was called.
  bool get isClosed => _closed;

  /// Writes property [name] as a string. Resolves with mpv's rc.
  Future<int> setProperty(String name, String value) {
    if (_closed) return Future.value(MpvError.mpvErrorSuccess);
    return _send(
      _writes,
      (id) => using((arena) {
        final v = arena<Pointer<Utf8>>()
          ..value = value.toNativeUtf8(allocator: arena);
        return _lib.mpvSetPropertyAsync(
          _handle,
          id,
          name.toNativeUtf8(allocator: arena),
          MpvFormat.mpvFormatString,
          v.cast(),
        );
      }),
    ).then((reply) => reply.$1);
  }

  /// Writes property [name] as the node [build] allocates in the arena;
  /// mpv deep-copies it before the call returns. Resolves with mpv's rc.
  Future<int> setNodeProperty(
    String name,
    Pointer<MpvNode> Function(Arena arena) build,
  ) {
    if (_closed) return Future.value(MpvError.mpvErrorSuccess);
    return _send(
      _writes,
      (id) => using(
        (arena) => _lib.mpvSetPropertyAsync(
          _handle,
          id,
          name.toNativeUtf8(allocator: arena),
          MpvFormat.mpvFormatNode,
          build(arena).cast(),
        ),
      ),
    ).then((reply) => reply.$1);
  }

  /// Runs command [args]. Resolves with mpv's rc and the command's decoded
  /// result node (`loadfile` returns its `playlist_entry_id` there).
  Future<(int, Object?)> command(List<String> args) {
    if (_closed) return Future.value((MpvError.mpvErrorSuccess, null));
    return _send(
      _writes,
      (id) => using((arena) {
        final arr = arena<Pointer<Utf8>>(args.length + 1);
        for (var i = 0; i < args.length; i++) {
          arr[i] = args[i].toNativeUtf8(allocator: arena);
        }
        arr[args.length] = nullptr;
        return _lib.mpvCommandAsync(_handle, id, arr);
      }),
    );
  }

  /// Reads property [name] in [format]. Resolves with mpv's rc and the
  /// decoded value.
  Future<(int, Object?)> getProperty(String name, int format) {
    if (_closed) return Future.value((MpvError.mpvErrorGeneric, null));
    return _send(
      _reads,
      (id) => using(
        (arena) => _lib.mpvGetPropertyAsync(
          _handle,
          id,
          name.toNativeUtf8(allocator: arena),
          format,
        ),
      ),
    );
  }

  /// Resolves the write or command [id] with its reply.
  void onReply(int id, int error, Object? result) =>
      _writes.complete(id, error, result);

  /// Resolves the read [id] with its reply.
  void onGetReply(int id, int error, Object? value) =>
      _reads.complete(id, error, value);

  /// Completes when every write and command in flight now has executed.
  /// Reads and later requests are not waited on.
  Future<void> settleWrites() => _writes.settle();

  /// Stops every further call from reaching libmpv and resolves the
  /// pending requests (see [ReplyTracker.drain]). Call it once no reply
  /// can arrive anymore, right before the handle is freed.
  void close() {
    _closed = true;
    _writes.drain();
    _reads.drain();
  }

  /// mpv's description of error [code].
  String errorString(int code) {
    final p = _lib.mpvErrorString(code);
    return p == nullptr ? 'error $code' : p.cast<Utf8>().toDartString();
  }

  Future<(int, Object?)> _send(
    ReplyTracker tracker,
    int Function(int id) enqueue,
  ) {
    final (id, reply) = tracker.open();
    final int rc;
    try {
      rc = enqueue(id);
    } catch (_) {
      // Settle the slot, or settleWrites would wait on it forever.
      tracker.reject(id, MpvError.mpvErrorGeneric);
      rethrow;
    }
    // Rejected client-side (a parse error, a full reply queue): no reply
    // will come.
    if (rc < 0) tracker.reject(id, rc);
    return reply;
  }
}
