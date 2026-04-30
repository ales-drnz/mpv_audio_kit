// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'mpv_bindings.dart' as mpv;

// ── Tunables ─────────────────────────────────────────────────────────────────

/// Throttle window for the high-frequency `time-pos` property. mpv emits a
/// position update on every output sample buffer, which is roughly the audio
/// device's tick (~10ms on most outputs) — way more than any consumer UI
/// needs. ~33ms ≈ 30Hz is comfortably inside human-perception territory for
/// a progress bar update and keeps the message bus uncluttered.
const int _kTimePosThrottleMs = 33;

/// Maximum time [MpvEventIsolate.stop] waits for the background isolate
/// to finish unwinding after `MPV_EVENT_SHUTDOWN`. The loop's natural
/// exit is fast on every supported platform; this bound caps the worst
/// case (e.g. a stalled syscall in libmpv) before the caller proceeds
/// with `mpv_terminate_destroy`.
const Duration _kIsolateExitTimeout = Duration(seconds: 2);

// ── Messages: main → isolate ─────────────────────────────────────────────────

/// Sent once when the isolate starts to hand it the mpv handle address and
/// the [SendPort] on which it should send events back.
class _InitMessage {
  final int handleAddress;
  final SendPort toMain;
  final String? libraryPath;
  _InitMessage(this.handleAddress, this.toMain, {this.libraryPath});
}

/// Tells the event loop isolate to exit cleanly.
class _ShutdownMessage {}

// ── Events: isolate → main ───────────────────────────────────────────────────

sealed class MpvIsolateEvent {}

class MpvEventStartFile extends MpvIsolateEvent {}

class MpvEventFileLoaded extends MpvIsolateEvent {}

/// mpv fired MPV_EVENT_SEEK — a seek request was accepted and playback
/// has been suspended while mpv reinitializes its pipeline.
class MpvEventPlaybackSeek extends MpvIsolateEvent {}

/// mpv fired MPV_EVENT_PLAYBACK_RESTART — the seek (or file load) has
/// finished reinitializing and playback is about to resume.
/// This is the authoritative "seek request is finished" signal.
class MpvEventPlaybackRestart extends MpvIsolateEvent {}

class MpvEndFileEvent extends MpvIsolateEvent {
  final int reason; // MpvEndFileReason.*
  final int error;
  MpvEndFileEvent(this.reason, this.error);
}

class MpvEventShutdown extends MpvIsolateEvent {}

class MpvEventPropertyDouble extends MpvIsolateEvent {
  final String name;
  final double value;
  MpvEventPropertyDouble(this.name, this.value);
}

class MpvEventPropertyInt extends MpvIsolateEvent {
  final String name;
  final int value;
  MpvEventPropertyInt(this.name, this.value);
}

class MpvEventPropertyString extends MpvIsolateEvent {
  final String name;
  final String value;
  MpvEventPropertyString(this.name, this.value);
}

/// mpv emitted a property change with `MPV_FORMAT_NODE`. [value] is the
/// recursively-decoded tree: `Map<String, dynamic>` for `MPV_FORMAT_NODE_MAP`,
/// `List<dynamic>` for `MPV_FORMAT_NODE_ARRAY`, a primitive (`String`, `int`,
/// `double`, `bool`), `Uint8List` for `MPV_FORMAT_BYTE_ARRAY`, or `null` for
/// `MPV_FORMAT_NONE`.
class MpvEventPropertyNode extends MpvIsolateEvent {
  final String name;
  final dynamic value;
  MpvEventPropertyNode(this.name, this.value);
}

class MpvEventLog extends MpvIsolateEvent {
  final String prefix;
  final String level;
  final String text;
  MpvEventLog(this.prefix, this.level, this.text);
}

class MpvEventHookFired extends MpvIsolateEvent {
  final int id;
  final String name;
  MpvEventHookFired(this.id, this.name);
}

// ── Isolate entry point ───────────────────────────────────────────────────────

void _isolateEntry(SendPort initialReplyPort) {
  final fromMain = ReceivePort();
  initialReplyPort.send(fromMain.sendPort);

  SendPort? toMain;
  Pointer<mpv.MpvHandle>? handle;
  mpv.MpvLibrary? lib;
  bool running = true;

  // Per-isolate deduplication state — not shared across Player instances.
  final lastValues = <String, dynamic>{};
  final lastTimestamps = <String, int>{};

  fromMain.listen((message) {
    if (message is _InitMessage) {
      toMain = message.toMain;
      lib = mpv.MpvLibrary.open(message.libraryPath);
      handle = Pointer<mpv.MpvHandle>.fromAddress(message.handleAddress);
      // Start the blocking event loop.
      _runEventLoop(
          lib!, handle!, toMain!, () => running, lastValues, lastTimestamps);
    } else if (message is _ShutdownMessage) {
      running = false;
      fromMain.close();
    }
  });
}

void _runEventLoop(
  mpv.MpvLibrary lib,
  Pointer<mpv.MpvHandle> handle,
  SendPort toMain,
  bool Function() isRunning,
  Map<String, dynamic> lastValues,
  Map<String, int> lastTimestamps,
) {
  while (isRunning()) {
    // Short timeout (50 ms) so the cooperative-shutdown signal from
    // the main isolate is picked up promptly by the next iteration
    // — avoids racing `mpv_terminate_destroy` against an in-flight
    // `mpv_wait_event` call. mpv produces audio-frame ticks at
    // ~10 ms granularity so 50 ms here is well under the
    // event-emission cadence.
    final event = lib.mpvWaitEvent(handle, 0.05);
    final id = event.ref.eventId;

    if (id == mpv.MpvEventId.mpvEventNone) {
      continue;
    }

    _dispatchEvent(lib, handle, toMain, event, lastValues, lastTimestamps);

    if (id == mpv.MpvEventId.mpvEventShutdown) {
      break;
    }
  }
}

void _dispatchEvent(
  mpv.MpvLibrary lib,
  Pointer<mpv.MpvHandle> handle,
  SendPort toMain,
  Pointer<mpv.MpvEvent> event,
  Map<String, dynamic> lastValues,
  Map<String, int> lastTimestamps,
) {
  final id = event.ref.eventId;
  switch (id) {
    case mpv.MpvEventId.mpvEventShutdown:
      toMain.send(MpvEventShutdown());

    case mpv.MpvEventId.mpvEventStartFile:
      toMain.send(MpvEventStartFile());

    case mpv.MpvEventId.mpvEventFileLoaded:
      toMain.send(MpvEventFileLoaded());

    case mpv.MpvEventId.mpvEventEndFile:
      final ef = event.ref.data.cast<mpv.MpvEventEndFile>().ref;
      toMain.send(MpvEndFileEvent(ef.reason, ef.error));

    case mpv.MpvEventId.mpvEventPropertyChange:
      _dispatchProperty(
        lib,
        toMain,
        event.ref.data.cast<mpv.MpvEventProperty>().ref,
        lastValues,
        lastTimestamps,
      );

    case mpv.MpvEventId.mpvEventLogMessage:
      _dispatchLog(toMain, event.ref.data.cast<mpv.MpvEventLogMessage>().ref);

    case mpv.MpvEventId.mpvEventHook:
      final hook = event.ref.data.cast<mpv.MpvEventHook>().ref;
      final name = hook.name.cast<Utf8>().toDartString();
      toMain.send(MpvEventHookFired(hook.id, name));

    case mpv.MpvEventId.mpvEventSeek:
      toMain.send(MpvEventPlaybackSeek());

    case mpv.MpvEventId.mpvEventPlaybackRestart:
      // Authoritative "seek finished" signal. The main isolate polls
      // time-pos synchronously in response so the new position is
      // visible on the stream before any throttled time-pos event.
      toMain.send(MpvEventPlaybackRestart());
  }
}

void _dispatchProperty(
  mpv.MpvLibrary lib,
  SendPort toMain,
  mpv.MpvEventProperty prop,
  Map<String, dynamic> lastValues,
  Map<String, int> lastTimestamps,
) {
  final name = prop.name.cast<Utf8>().toDartString();

  if (prop.format == mpv.MpvFormat.mpvFormatDouble && prop.data != nullptr) {
    final v = prop.data.cast<Double>().value;

    if (name == 'time-pos') {
      final now = DateTime.now().millisecondsSinceEpoch;
      final last = lastTimestamps[name] ?? 0;
      if (now - last < _kTimePosThrottleMs) {
        return;
      }
      lastTimestamps[name] = now;
    }

    if (lastValues[name] == v) {
      return;
    }
    lastValues[name] = v;

    toMain.send(MpvEventPropertyDouble(name, v));
    return;
  }

  if (prop.format == mpv.MpvFormat.mpvFormatFlag && prop.data != nullptr) {
    final v = prop.data.cast<Int32>().value;
    if (lastValues[name] == v) {
      return;
    }
    lastValues[name] = v;
    toMain.send(MpvEventPropertyInt(name, v));
    return;
  }

  if (prop.format == mpv.MpvFormat.mpvFormatInt64 && prop.data != nullptr) {
    final v = prop.data.cast<Int64>().value;
    if (lastValues[name] == v) {
      return;
    }
    lastValues[name] = v;
    toMain.send(MpvEventPropertyInt(name, v));
    return;
  }

  if (prop.format == mpv.MpvFormat.mpvFormatString && prop.data != nullptr) {
    final s = prop.data.cast<Pointer<Utf8>>().value.cast<Utf8>().toDartString();
    if (lastValues[name] == s) {
      return;
    }
    lastValues[name] = s;
    toMain.send(MpvEventPropertyString(name, s));
    return;
  }

  if (prop.format == mpv.MpvFormat.mpvFormatNode && prop.data != nullptr) {
    final decoded = decodeMpvNode(prop.data.cast<mpv.MpvNode>().ref);
    // Best-effort dedup via JSON encoding: deterministic for Map/List/scalar
    // trees that mpv emits and avoids walking the tree twice with a
    // dedicated deep-equality check. Falls through with no dedup if the
    // decoded value contains something `jsonEncode` can't serialize (e.g. a
    // Uint8List from MPV_FORMAT_BYTE_ARRAY embedded inside a node — not
    // observed in practice for our property set).
    final key = _nodeDedupKey(decoded);
    if (key != null && lastValues[name] == key) {
      return;
    }
    if (key != null) lastValues[name] = key;
    toMain.send(MpvEventPropertyNode(name, decoded));
    return;
  }

  // Fallthrough: format is one mpv emitted that the wrapper does not
  // observe (NONE / OSD_STRING / NODE_ARRAY / NODE_MAP / BYTE_ARRAY at
  // the top level — those types only appear inside a NODE for our
  // property set), or `data == nullptr` which mpv uses to signal
  // "property unavailable" mid-stream. Silently drop: re-emitting the
  // last cached value would be wrong, and pushing a sentinel would
  // break dedup downstream.
}

void _dispatchLog(SendPort toMain, mpv.MpvEventLogMessage msg) {
  final prefix = msg.prefix.cast<Utf8>().toDartString();
  final level = msg.level.cast<Utf8>().toDartString();
  final text = msg.text.cast<Utf8>().toDartString().trimRight();
  toMain.send(MpvEventLog(prefix, level, text));
}

// ── Node decoding ─────────────────────────────────────────────────────────────

/// Recursively converts an mpv `mpv_node` C struct into a Dart-native tree.
///
/// Maps:
///   - `MPV_FORMAT_NONE`        → `null`
///   - `MPV_FORMAT_STRING`      → [String]
///   - `MPV_FORMAT_FLAG`        → [bool]
///   - `MPV_FORMAT_INT64`       → [int]
///   - `MPV_FORMAT_DOUBLE`      → [double]
///   - `MPV_FORMAT_NODE_ARRAY`  → `List<dynamic>` of recursively-decoded children
///   - `MPV_FORMAT_NODE_MAP`    → `Map<String, dynamic>` of recursively-decoded children
///   - `MPV_FORMAT_BYTE_ARRAY`  → [Uint8List] copied out of mpv-owned memory
///
/// The returned tree owns its memory: any data borrowed from mpv (strings,
/// byte arrays) is copied during decoding so the caller can safely dispose
/// of the source `mpv_node` via `mpv_free_node_contents` immediately after.
///
/// Exposed at top-level (rather than file-private) so unit tests can build
/// synthetic `mpv_node` trees and exercise the decoder without spinning up
/// a real player.
dynamic decodeMpvNode(mpv.MpvNode node) {
  switch (node.format) {
    case mpv.MpvFormat.mpvFormatString:
      return node.u.string.cast<Utf8>().toDartString();
    case mpv.MpvFormat.mpvFormatFlag:
      return node.u.flag != 0;
    case mpv.MpvFormat.mpvFormatInt64:
      return node.u.int64;
    case mpv.MpvFormat.mpvFormatDouble:
      return node.u.double_;
    case mpv.MpvFormat.mpvFormatNodeArray:
      final list = node.u.list.ref;
      return [
        for (var i = 0; i < list.num; i++)
          decodeMpvNode((list.values + i).ref),
      ];
    case mpv.MpvFormat.mpvFormatNodeMap:
      final list = node.u.list.ref;
      return <String, dynamic>{
        for (var i = 0; i < list.num; i++)
          (list.keys + i).value.cast<Utf8>().toDartString():
              decodeMpvNode((list.values + i).ref),
      };
    case mpv.MpvFormat.mpvFormatByteArray:
      final ba = node.u.ba.ref;
      // Copy out of mpv-owned memory before the caller frees the node.
      return Uint8List.fromList(
          ba.data.cast<Uint8>().asTypedList(ba.size));
    default:
      return null;
  }
}

String? _nodeDedupKey(dynamic decoded) {
  try {
    return jsonEncode(decoded);
  } catch (_) {
    return null;
  }
}

// ── Public bridge ─────────────────────────────────────────────────────────────

/// Manages the dedicated isolate that runs the mpv event loop.
///
/// The mpv API is thread-safe: the main isolate continues to call
/// [mpv_set_property], [mpv_command] etc. while this isolate blocks on
/// [mpv_wait_event], keeping the Flutter render thread free.
class MpvEventIsolate {
  Isolate? _isolate;
  SendPort? _toIsolate;
  ReceivePort? _fromIsolate;
  final _events = StreamController<MpvIsolateEvent>.broadcast();

  Stream<MpvIsolateEvent> get events => _events.stream;

  /// Spawns the event loop isolate and wires it to [handle].
  Future<void> start(Pointer<mpv.MpvHandle> handle,
      {String? libraryPath}) async {
    final initPort = ReceivePort();
    _isolate = await Isolate.spawn(_isolateEntry, initPort.sendPort);

    // The isolate immediately sends back its own receive port.
    final completer = Completer<SendPort>();
    final sub = initPort.listen((msg) {
      if (msg is SendPort && !completer.isCompleted) {
        completer.complete(msg);
      }
    });
    _toIsolate = await completer.future;
    await sub.cancel();
    initPort.close();

    // Open the main ReceivePort, tell the isolate to start.
    final fromIsolate = ReceivePort();
    _fromIsolate = fromIsolate;
    fromIsolate.listen((msg) {
      // Defensive against the teardown race: stop() closes [_events]
      // immediately after asking the isolate to shut down, but messages
      // already queued on the receive port may still drain through this
      // listener afterwards. Without this guard the queued message would
      // throw "Bad state: Cannot add new events after calling close" on
      // the broadcast controller — visible only when many Player
      // instances are created and disposed in rapid succession (e.g. a
      // test suite).
      if (msg is MpvIsolateEvent && !_events.isClosed) {
        _events.add(msg);
      }
    });

    _toIsolate!.send(_InitMessage(handle.address, fromIsolate.sendPort,
        libraryPath: libraryPath));
  }

  /// Signals the isolate to exit and **awaits its actual termination**
  /// before returning.
  ///
  /// `mpv_terminate_destroy` is called by the player just before this in
  /// dispose(); it causes the isolate's blocking [mpv_wait_event] to
  /// return with MPV_EVENT_SHUTDOWN and the loop exits naturally on its
  /// next iteration.
  ///
  /// **Awaiting the isolate exit is load-bearing.** [Isolate.kill] is a
  /// cooperative request that returns before the isolate has actually
  /// finished. If `dispose()` returns while the isolate is still inside
  /// [mpv_wait_event] on a destroyed handle, the next syscall in the
  /// loop reads freed memory and produces a non-deterministic
  /// SIGSEGV at process teardown — visible across the whole test
  /// suite, not just the calling test.
  Future<void> stop() async {
    _fromIsolate?.close();
    _fromIsolate = null;
    if (!_events.isClosed) _events.close();

    final isolate = _isolate;
    if (isolate == null) {
      _toIsolate = null;
      return;
    }

    // Register the exit listener BEFORE we ask the isolate to leave;
    // the port must be alive when the isolate posts its termination.
    final exitPort = ReceivePort();
    isolate.addOnExitListener(exitPort.sendPort);

    // Cooperative shutdown only — sending [_ShutdownMessage] flips the
    // isolate's `running` flag, the next mpv_wait_event poll (50 ms
    // max) returns, the loop body exits, the isolate's main function
    // completes, and the VM tears the isolate down cleanly. We do NOT
    // call [Isolate.kill] here: forcibly killing an isolate while it
    // is inside an FFI call to libmpv produces a non-deterministic
    // SIGSEGV at process teardown — a price the cooperative path
    // does not pay.
    _toIsolate?.send(_ShutdownMessage());
    _isolate = null;
    _toIsolate = null;

    // Wait for the isolate to actually exit. ~100 ms in practice
    // (one mpv_wait_event poll cycle + microtask drain). The
    // 2-second cap is a safety net for a libmpv stuck in a
    // pathological state — we'd rather return than hang dispose().
    try {
      await exitPort.first.timeout(_kIsolateExitTimeout);
    } on TimeoutException {
      // Fall through.
    } finally {
      exitPort.close();
    }
  }
}
