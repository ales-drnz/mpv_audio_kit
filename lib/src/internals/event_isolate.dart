// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import '../events/player_exception.dart';
import '../mpv_bindings.dart' as mpv;
import 'build_mode.dart';
import 'core_events.dart';
import 'event_logic.dart';
import 'owner_watch.dart';

export 'core_events.dart';

part 'isolate_messages.dart';

// The native event pump: an isolate that waits on `mpv_wait_event`, decodes
// each event out of the core's memory over FFI and hands it to the shared
// [EventLogic], whose reads are synchronous client calls here.

// ── Tunables ─────────────────────────────────────────────────────────────────

/// `mpv_wait_event` timeout: a BOUNDED floor in every build.
///
/// The Dart VM cannot interrupt an isolate parked in a blocking FFI call
/// (dart-lang/sdk#46680): under an infinite `-1` timeout a `Player` left
/// undisposed at process exit wedges `WaitForIsolateShutdown` forever (the
/// macOS Dock-Quit hang), and Hot Restart's kill would hang too. A finite
/// timeout guarantees the loop re-reads its stop flag, and the VM gets a
/// safepoint, at least once per window even with zero cooperation.
///
/// Release and profile: `1.0` s, one cheap idle wakeup a second. The graceful
/// dispose path unblocks the wait instantly via `mpv_wakeup`
/// ([MpvEventIsolate.requestStop]), so this value is only the no-dispose
/// floor, never the common-case latency. Debug: `0.1` s for snappy Hot
/// Restart, which only debug builds have ([kHotRestartPossible]). It MUST
/// stay finite in release: an infinite timeout reintroduces the quit hang.
const double _kWaitEventTimeoutSeconds = kHotRestartPossible ? 0.1 : 1.0;

/// Maximum time [MpvEventIsolate.stop] waits for the background isolate
/// to finish unwinding after `MPV_EVENT_SHUTDOWN`. The loop's natural
/// exit is fast on every supported platform; this bound caps the worst
/// case (e.g. a stalled syscall in libmpv) before the caller proceeds
/// with `mpv_terminate_destroy`.
const Duration _kIsolateExitTimeout = Duration(seconds: 2);

// ── Isolate entry point ───────────────────────────────────────────────────────

void _applyOptionStrings(
  mpv.MpvLibrary lib,
  Pointer<mpv.MpvHandle> handle,
  Map<String, String> opts,
) {
  for (final entry in opts.entries) {
    using((arena) {
      lib.mpvSetOptionString(
        handle,
        entry.key.toNativeUtf8(allocator: arena),
        entry.value.toNativeUtf8(allocator: arena),
      );
    });
  }
}

void _applyPropertyStrings(
  mpv.MpvLibrary lib,
  Pointer<mpv.MpvHandle> handle,
  Map<String, String> props,
) {
  for (final entry in props.entries) {
    using((arena) {
      lib.mpvSetPropertyString(
        handle,
        entry.key.toNativeUtf8(allocator: arena),
        entry.value.toNativeUtf8(allocator: arena),
      );
    });
  }
}

void _applyObserves(
  mpv.MpvLibrary lib,
  Pointer<mpv.MpvHandle> handle,
  List<MpvObserveSpec> observes,
) {
  for (final spec in observes) {
    using((arena) {
      lib.mpvObserveProperty(
        handle,
        spec.replyId,
        spec.name.toNativeUtf8(allocator: arena),
        spec.format,
      );
    });
  }
}

void _isolateEntry(SendPort initialReplyPort) {
  final fromMain = ReceivePort();
  initialReplyPort.send(fromMain.sendPort);

  SendPort? toMain;
  Pointer<mpv.MpvHandle>? handle;
  mpv.MpvLibrary? lib;

  fromMain.listen((message) async {
    if (message is _InitMessage) {
      toMain = message.toMain;
      final wakeupCounter = message.wakeupCounterAddress != null
          ? Pointer<Int64>.fromAddress(message.wakeupCounterAddress!)
          : null;
      final stopFlag = Pointer<Int32>.fromAddress(message.stopFlagAddress);
      final ownerGone = Pointer<Int32>.fromAddress(message.ownerGoneAddress);
      try {
        // The heavy FFI sequence runs here: off the main isolate so
        // the host UI keeps rendering during cold start.
        lib = mpv.MpvLibrary.open(message.libraryPath);
        final h = lib!.mpvCreate();
        if (h == nullptr) {
          toMain!.send(_InitFailed('mpv_create() returned NULL'));
          fromMain.close();
          return;
        }
        handle = h;
        _applyOptionStrings(lib!, h, message.preInitOptions);
        if (message.logLevel != null) {
          using((arena) {
            lib!.mpvRequestLogMessages(
              h,
              message.logLevel!.toNativeUtf8(allocator: arena),
            );
          });
        }
        final rc = lib!.mpvInitialize(h);
        if (rc < 0) {
          lib!.mpvTerminateDestroy(h);
          toMain!.send(_InitFailed('mpv_initialize() failed: rc=$rc'));
          fromMain.close();
          return;
        }
        _applyPropertyStrings(lib!, h, message.postInitOptions);
        _applyObserves(lib!, h, message.observes);
        // Not registered with the logic: `pause` never reaches the main
        // isolate, the logic reads it for the end of content only.
        _applyObserves(lib!, h, const [
          MpvObserveSpec(
            'pause',
            mpv.MpvFormat.mpvFormatFlag,
            _kPauseObserverReplyId,
          ),
        ]);
        toMain!.send(_InitDone(h.address));
      } catch (e, st) {
        // The main isolate gets no handle from a failed init, so the core
        // created above is destroyed here or never.
        final h = handle;
        if (h != null) lib!.mpvTerminateDestroy(h);
        toMain!.send(_InitFailed('init crashed: $e\n$st'));
        fromMain.close();
        return;
      }
      // Per-isolate logic and cache: not shared across Player instances.
      final send = toMain!.send;
      final logic = EventLogic(_NativeReader(lib!, handle!, stopFlag), send);
      for (final spec in message.observes) {
        logic.observe(spec.name, spec.format);
      }
      // Returns when `_runEventLoop` breaks out of its loop: on the stop
      // flag dispose() sets right after its `quit` command
      // (MpvEventIsolate.requestStop), on MPV_EVENT_SHUTDOWN, or once the
      // owner isolate exited without dispose ([OwnerWatch]). The loop
      // blocks this isolate in mpv_wait_event and in the reads; its awaits
      // resume as microtasks, never through the event queue.
      await _runEventLoop(
        lib!,
        handle!,
        send,
        stopFlag,
        ownerGone,
        logic,
        wakeupCounter,
      );
      if (stopFlag.value == 0 && ownerGone.value != 0) {
        releaseOrphan(lib!, handle!);
      }
      // Drop the last live ReceivePort so the isolate ends on its own: the
      // exit listener armed in [MpvEventIsolate.start] then fires, and
      // [MpvEventIsolate.stop] awaits it before it frees the stop flag.
      // The core and the stop flag have their own explicit release.
      fromMain.close();
    }
  });
}

/// Reply id of the isolate's own `pause` observer, above every id the main
/// isolate hands out.
const int _kPauseObserverReplyId = 1 << 62;

Future<void> _runEventLoop(
  mpv.MpvLibrary lib,
  Pointer<mpv.MpvHandle> handle,
  void Function(MpvIsolateEvent) send,
  Pointer<Int32> stopFlag,
  Pointer<Int32> ownerGone,
  EventLogic logic,
  Pointer<Int64>? wakeupCounter,
) async {
  while (stopFlag.value == 0 && ownerGone.value == 0) {
    // Test-only telemetry; null in production.
    if (wakeupCounter != null) {
      wakeupCounter.value = wakeupCounter.value + 1;
    }
    final event = lib.mpvWaitEvent(
      handle,
      logic.waitSeconds(_kWaitEventTimeoutSeconds),
    );

    // Re-read the flag the instant the wait returns. `requestStop` sets the
    // flag THEN calls `mpv_wakeup`, so a wakeup-driven return lands here with
    // the flag already `1`: this is the lost-wakeup-safe exit edge, and it
    // does not depend on mpv emitting `MPV_EVENT_SHUTDOWN`.
    if (stopFlag.value != 0 || ownerGone.value != 0) {
      break;
    }

    final id = event.ref.eventId;

    // MPV_EVENT_NONE on a positive-timeout expiry, or on an `mpv_wakeup` with
    // no pending event: nothing to dispatch, loop and re-check the flag.
    if (id == mpv.MpvEventId.mpvEventNone) {
      logic.flushTrailing();
      continue;
    }

    // A single undecodable event must not kill the loop: the isolate is
    // spawned with the default `errorsAreFatal`, so an uncaught throw here
    // would silently terminate the worker and freeze every property stream
    // for the Player's lifetime while playback keeps running.
    try {
      // Decoded before any await: the payload is valid only until the next
      // mpv_wait_event.
      final reads = _dispatchEvent(logic, event);
      if (reads != null) await reads;
      logic.flushTrailing();
    } catch (e, st) {
      send(MpvEventInternalLog('error', 'event dispatch failed: $e\n$st'));
    }

    if (id == mpv.MpvEventId.mpvEventShutdown) {
      break;
    }
  }
}

/// Decodes [event] out of the core's memory and hands it to [logic].
/// Returns the future of the reads the event takes, if any.
Future<void>? _dispatchEvent(EventLogic logic, Pointer<mpv.MpvEvent> event) {
  final ev = event.ref;
  switch (ev.eventId) {
    case mpv.MpvEventId.mpvEventPropertyChange:
      final prop = ev.data.cast<mpv.MpvEventProperty>().ref;
      return logic.property(
        decodeMpvString(prop.name.cast()),
        prop.format,
        _propertyChangeValue(prop),
      );
    case mpv.MpvEventId.mpvEventShutdown:
      return logic.dispatch(MpvEventShutdown());
    case mpv.MpvEventId.mpvEventStartFile:
      return logic.dispatch(
        MpvEventStartFile(
          ev.data.cast<mpv.MpvEventStartFileData>().ref.playlistEntryId,
        ),
      );
    case mpv.MpvEventId.mpvEventFileLoaded:
      return logic.dispatch(MpvEventFileLoaded());
    case mpv.MpvEventId.mpvEventEndFile:
      final ef = ev.data.cast<mpv.MpvEventEndFile>().ref;
      return logic.dispatch(
        MpvEventEndFile(ef.playlistEntryId, ef.reason, ef.error),
      );
    case mpv.MpvEventId.mpvEventAudioReconfig:
      return logic.dispatch(MpvEventAudioReconfig());
    case mpv.MpvEventId.mpvEventSetPropertyReply:
      return logic.dispatch(MpvEventReply(ev.replyUserdata, ev.error));
    case mpv.MpvEventId.mpvEventCommandReply:
      // The payload is an `mpv_event_command`, whose only member is the
      // `mpv_node result` (`loadfile` returns `playlist_entry_id` in it).
      // Valid only until the next mpv_wait_event, hence decoded here.
      final error = ev.error;
      Object? result;
      if (error >= 0 && ev.data != nullptr) {
        result = decodeMpvNode(ev.data.cast<mpv.MpvNode>().ref);
      }
      return logic.dispatch(MpvEventReply(ev.replyUserdata, error, result));
    case mpv.MpvEventId.mpvEventGetPropertyReply:
      final error = ev.error;
      dynamic value;
      if (error >= 0 && ev.data != nullptr) {
        // The payload (an mpv_event_property) is owned by the event and
        // valid only until the next mpv_wait_event: decode (and copy)
        // before forwarding.
        value = _decodePropertyValue(ev.data.cast<mpv.MpvEventProperty>().ref);
      }
      return logic.dispatch(MpvEventGetReply(ev.replyUserdata, error, value));
    case mpv.MpvEventId.mpvEventLogMessage:
      final msg = ev.data.cast<mpv.MpvEventLogMessage>().ref;
      return logic.dispatch(
        MpvEventLog(
          decodeMpvString(msg.prefix.cast()),
          decodeMpvString(msg.level.cast()),
          decodeMpvString(msg.text.cast()).trimRight(),
        ),
      );
    case mpv.MpvEventId.mpvEventHook:
      final hook = ev.data.cast<mpv.MpvEventHook>().ref;
      return logic.dispatch(
        MpvEventHookFired(hook.id, decodeMpvString(hook.name.cast())),
      );
    case mpv.MpvEventId.mpvEventSeek:
      return logic.dispatch(MpvEventPlaybackSeek());
    case mpv.MpvEventId.mpvEventPlaybackRestart:
      return logic.dispatch(MpvEventPlaybackRestart());
  }
  return null;
}

/// The value of a property change as [EventLogic.property] takes it.
Object? _propertyChangeValue(mpv.MpvEventProperty prop) {
  if (prop.format == mpv.MpvFormat.mpvFormatNone || prop.data == nullptr) {
    return kPropertyUnavailable;
  }
  return switch (prop.format) {
    mpv.MpvFormat.mpvFormatDouble => prop.data.cast<Double>().value,
    mpv.MpvFormat.mpvFormatFlag => prop.data.cast<Int32>().value,
    mpv.MpvFormat.mpvFormatInt64 => prop.data.cast<Int64>().value,
    mpv.MpvFormat.mpvFormatString => decodeMpvString(
      prop.data.cast<Pointer<Utf8>>().value,
    ),
    mpv.MpvFormat.mpvFormatNode => decodeMpvNode(
      prop.data.cast<mpv.MpvNode>().ref,
    ),
    _ => kPropertyUnobserved,
  };
}

// ── Synchronous property reads (event-isolate side only) ─────────────────────

/// The reads of [EventLogic] as synchronous client calls. They block this
/// isolate until the playloop serves the request: safe here, never on the
/// main isolate. Each one answers null once a stop is requested
/// ([_stopRequested]).
final class _NativeReader implements CoreReader {
  _NativeReader(this._lib, this._handle, this._stopFlag);

  final mpv.MpvLibrary _lib;
  final Pointer<mpv.MpvHandle> _handle;
  final Pointer<Int32> _stopFlag;

  /// Whether dispose asked this isolate to stop
  /// ([MpvEventIsolate.requestStop]). One event takes up to a dozen
  /// synchronous reads, each a wait on the core. Read after read past the
  /// stop, against a busy core, they outlasted [_kIsolateExitTimeout], and
  /// dispose skipped the destroy. Nothing read after a stop reaches the
  /// main isolate anyway: [MpvEventIsolate.stop] closed the port.
  bool get _stopRequested => _stopFlag.value != 0;

  @override
  Future<String?> string(String name) async {
    if (_stopRequested) return null;
    return using<String?>((arena) {
      final n = name.toNativeUtf8(allocator: arena);
      final ptr = _lib.mpvGetPropertyString(_handle, n);
      if (ptr == nullptr) return null;
      final s = decodeMpvString(ptr.cast());
      _lib.mpvFree(ptr.cast());
      return s;
    });
  }

  @override
  Future<double?> float(String name) async {
    if (_stopRequested) return null;
    return using<double?>((arena) {
      final n = name.toNativeUtf8(allocator: arena);
      final buf = arena<Double>();
      final rc = _lib.mpvGetProperty(
        _handle,
        n,
        mpv.MpvFormat.mpvFormatDouble,
        buf.cast(),
      );
      return rc == mpv.MpvError.mpvErrorSuccess ? buf.value : null;
    });
  }

  @override
  Future<int?> int64(String name) async {
    if (_stopRequested) return null;
    return using<int?>((arena) {
      final n = name.toNativeUtf8(allocator: arena);
      final buf = arena<Int64>();
      final rc = _lib.mpvGetProperty(
        _handle,
        n,
        mpv.MpvFormat.mpvFormatInt64,
        buf.cast(),
      );
      return rc == mpv.MpvError.mpvErrorSuccess ? buf.value : null;
    });
  }

  @override
  Future<int?> flag(String name) async {
    if (_stopRequested) return null;
    return using<int?>((arena) {
      final n = name.toNativeUtf8(allocator: arena);
      final buf = arena<Int32>();
      final rc = _lib.mpvGetProperty(
        _handle,
        n,
        mpv.MpvFormat.mpvFormatFlag,
        buf.cast(),
      );
      return rc == mpv.MpvError.mpvErrorSuccess ? buf.value : null;
    });
  }

  @override
  Future<Object?> node(String name) async {
    if (_stopRequested) return null;
    final node = calloc<mpv.MpvNode>();
    try {
      final rc = using(
        (arena) => _lib.mpvGetProperty(
          _handle,
          name.toNativeUtf8(allocator: arena),
          mpv.MpvFormat.mpvFormatNode,
          node.cast(),
        ),
      );
      if (rc < 0) return null;
      // decodeMpvNode copies every borrowed string and byte buffer, so the
      // node contents can be freed before the tree is returned.
      return decodeMpvNode(node.ref);
    } finally {
      _lib.mpvFreeNodeContents(node);
      calloc.free(node);
    }
  }
}

/// Decodes the value of an `mpv_event_property` payload into the same Dart
/// shapes the property-change pipeline produces (no dedup or throttle:
/// replies are one-shot). Returns `null` for `data == nullptr` or an
/// unobserved format.
dynamic _decodePropertyValue(mpv.MpvEventProperty prop) {
  if (prop.data == nullptr) return null;
  return switch (prop.format) {
    mpv.MpvFormat.mpvFormatDouble => prop.data.cast<Double>().value,
    mpv.MpvFormat.mpvFormatFlag => prop.data.cast<Int32>().value,
    mpv.MpvFormat.mpvFormatInt64 => prop.data.cast<Int64>().value,
    mpv.MpvFormat.mpvFormatString => decodeMpvString(
      prop.data.cast<Pointer<Utf8>>().value,
    ),
    // Get replies carry the polled PCM, tap and waveform frames: their
    // bytes cross to the main isolate as TransferableTypedData, copied
    // once instead of twice.
    mpv.MpvFormat.mpvFormatNode => decodeMpvNode(
      prop.data.cast<mpv.MpvNode>().ref,
      transferBytes: true,
    ),
    _ => null,
  };
}

// ── String and node decoding ──────────────────────────────────────────────────

/// Decodes a NUL-terminated mpv-owned C string, replacing invalid UTF-8
/// sequences with U+FFFD instead of throwing.
///
/// mpv does not guarantee valid UTF-8 on every string it hands to the
/// client API: ICY response headers (`icy-name`, …) are copied into tags
/// verbatim, so a legacy latin-1 radio server delivers raw bytes like
/// `0xE9` here. A strict decode would throw [FormatException] mid-dispatch.
String decodeMpvString(Pointer<Utf8> ptr) {
  final units = ptr.cast<Uint8>();
  var length = 0;
  while (units[length] != 0) {
    length++;
  }
  return utf8.decode(units.asTypedList(length), allowMalformed: true);
}

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
///   - `MPV_FORMAT_BYTE_ARRAY`  → [Uint8List] copied out of mpv-owned memory,
///     or with [transferBytes] a [TransferableTypedData], which crosses to
///     the main isolate without a second copy (see [materializeBytes])
///
/// The returned tree owns its memory: any data borrowed from mpv (strings,
/// byte arrays) is copied during decoding so the caller can safely dispose
/// of the source `mpv_node` via `mpv_free_node_contents` immediately after.
///
/// Exposed at top-level (rather than file-private) so unit tests can build
/// synthetic `mpv_node` trees and exercise the decoder without spinning up
/// a real player.
dynamic decodeMpvNode(mpv.MpvNode node, {bool transferBytes = false}) {
  switch (node.format) {
    case mpv.MpvFormat.mpvFormatString:
      return decodeMpvString(node.u.string.cast());
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
          decodeMpvNode((list.values + i).ref, transferBytes: transferBytes),
      ];
    case mpv.MpvFormat.mpvFormatNodeMap:
      final list = node.u.list.ref;
      return <String, dynamic>{
        for (var i = 0; i < list.num; i++)
          decodeMpvString((list.keys + i).value.cast()): decodeMpvNode(
            (list.values + i).ref,
            transferBytes: transferBytes,
          ),
      };
    case mpv.MpvFormat.mpvFormatByteArray:
      final ba = node.u.ba.ref;
      // Copy out of mpv-owned memory before the caller frees the node.
      final bytes = ba.data.cast<Uint8>().asTypedList(ba.size);
      return transferBytes
          ? TransferableTypedData.fromList([bytes])
          : Uint8List.fromList(bytes);
    default:
      return null;
  }
}

/// Turns the [TransferableTypedData] byte arrays of a get reply back into
/// [Uint8List]s, in place, on the receiving isolate. Maps and lists are
/// walked; other values are returned as they are.
Object? materializeBytes(Object? value) {
  switch (value) {
    case TransferableTypedData():
      return value.materialize().asUint8List();
    case Map<String, dynamic>():
      for (final entry in value.entries.toList(growable: false)) {
        value[entry.key] = materializeBytes(entry.value);
      }
      return value;
    case List<dynamic>():
      for (var i = 0; i < value.length; i++) {
        value[i] = materializeBytes(value[i]);
      }
      return value;
    default:
      return value;
  }
}

// ── Public bridge ─────────────────────────────────────────────────────────────

/// Manages the dedicated isolate that runs the mpv event loop.
///
/// The mpv API is thread-safe: the main isolate continues to call
/// `mpv_set_property_async`, `mpv_command_async` etc. while this isolate
/// blocks on `mpv_wait_event`, keeping the Flutter render thread free.
class MpvEventIsolate {
  Isolate? _isolate;
  SendPort? _toIsolate;
  ReceivePort? _fromIsolate;
  ReceivePort? _exitPort;
  // Native stop flag (Int32): the main isolate sets it to 1 in [requestStop],
  // the worker reads it every loop turn. Allocated in [start], freed in [stop]
  // ONLY on confirmed worker exit, so no parked reader survives the free.
  Pointer<Int32>? _stopFlag;
  // Non-broadcast: a single subscriber and buffering for events that
  // arrive between isolate-start and the main-side listen registration.
  // Using a broadcast controller dropped the initial PROPERTY_CHANGE
  // burst (mpv emits one per `mpv_observe_property` call right after
  // the isolate begins polling: ~100 properties), leaving downstream
  // state partially populated.
  final _events = StreamController<MpvIsolateEvent>();

  /// The post-init event stream; single-subscription with buffering (see
  /// the [_events] field for why the initial burst must not be dropped).
  Stream<MpvIsolateEvent> get events => _events.stream;

  /// Spawns the event isolate, runs the heavy mpv init recipe inside
  /// it, and resolves with the live `mpv_handle*` address. Heavy FFI
  /// (`mpv_create`, `mpv_initialize`, ~100 `mpv_observe_property`)
  /// never touches the main isolate, so the host UI stays responsive
  /// during cold start.
  ///
  /// The [onEvent] listener is wired BEFORE `_InitDone` is forwarded,
  /// eliminating the broadcast race that otherwise drops the initial
  /// property-change burst.
  ///
  /// [wakeupCounterAddress] is test-only.
  Future<int> start({
    String? libraryPath,
    void Function(MpvIsolateEvent)? onEvent,
    required Map<String, String> preInitOptions,
    required Map<String, String> postInitOptions,
    required List<MpvObserveSpec> observes,
    String? logLevel,
    int? wakeupCounterAddress,
  }) async {
    if (onEvent != null) _events.stream.listen(onEvent);
    final ownerGone = await OwnerWatch.wordAddress();

    _stopFlag = calloc<Int32>()..value = 0;

    final initPort = ReceivePort();
    _isolate = await Isolate.spawn(_isolateEntry, initPort.sendPort);

    final completer = Completer<SendPort>();
    final sub = initPort.listen((msg) {
      if (msg is SendPort && !completer.isCompleted) {
        completer.complete(msg);
      }
    });
    _toIsolate = await completer.future;
    await sub.cancel();
    initPort.close();

    // Arm the exit listener BEFORE the isolate can possibly tear down.
    _exitPort = ReceivePort();
    _isolate!.addOnExitListener(_exitPort!.sendPort);

    final initDone = Completer<int>();
    final fromIsolate = ReceivePort();
    _fromIsolate = fromIsolate;
    fromIsolate.listen((msg) {
      if (msg is _InitDone) {
        if (!initDone.isCompleted) initDone.complete(msg.handleAddress);
        return;
      }
      if (msg is _InitFailed) {
        if (!initDone.isCompleted) {
          initDone.completeError(PlayerInitException(msg.message));
        }
        return;
      }
      // Drop messages that arrive after `stop()` has closed the
      // controller. Without this guard the queued message would throw
      // "Bad state: Cannot add new events after calling close",
      // visible only when many Player instances are created and
      // disposed in rapid succession.
      if (msg is MpvIsolateEvent && !_events.isClosed) {
        _events.add(msg);
      }
    });

    _toIsolate!.send(
      _InitMessage(
        fromIsolate.sendPort,
        libraryPath: libraryPath,
        preInitOptions: preInitOptions,
        postInitOptions: postInitOptions,
        observes: observes,
        logLevel: logLevel,
        wakeupCounterAddress: wakeupCounterAddress,
        stopFlagAddress: _stopFlag!.address,
        ownerGoneAddress: ownerGone,
      ),
    );

    return initDone.future;
  }

  /// Unblocks the event loop deterministically. Call from the main isolate in
  /// `Player.dispose()` AFTER `mpv_command(['quit'])`, immediately before
  /// [stop].
  ///
  /// Order is load-bearing: set the native stop flag FIRST (publish the
  /// intent), THEN `mpv_wakeup`. A parked `mpv_wait_event` returns at once
  /// with `MPV_EVENT_NONE`; the worker re-reads the flag and breaks. `mpv_wakeup`
  /// is thread-safe (libmpv) and guarantees no lost wakeups, so this works even
  /// if `quit` was dropped (`MPV_ERROR_EVENT_QUEUE_FULL`) or `MPV_EVENT_SHUTDOWN`
  /// is delayed by a stalled hook. Idempotent and null-safe.
  void requestStop(mpv.MpvLibrary lib, Pointer<mpv.MpvHandle> handle) {
    _stopFlag?.value = 1;
    lib.mpvWakeup(handle);
  }

  /// Awaits the worker isolate's ACTUAL termination.
  ///
  /// Returns `true` iff the exit was confirmed within [_kIsolateExitTimeout].
  /// On `false` the worker is NOT proven to have left `mpv_wait_event`, so the
  /// caller MUST NOT `mpv_terminate_destroy` the handle: freeing it while the
  /// isolate is still inside the syscall reads freed memory and SIGSEGVs at
  /// teardown. [Isolate.kill] is never used for the same reason (killing
  /// mid-FFI to libmpv is a non-deterministic crash).
  ///
  /// The native stop flag is freed ONLY on confirmed exit, when no parked
  /// reader can survive the free; on the timeout branch it is intentionally
  /// leaked (4 bytes, bounded by live Player count, reclaimed at process exit).
  Future<bool> stop() async {
    // Publish the stop intent unconditionally: callers that have no
    // (lib, handle) pair for [requestStop] (teardown before bring-up
    // completed) still need the worker's bounded wait to observe the
    // flag and exit on its next timeout expiry.
    _stopFlag?.value = 1;
    _fromIsolate?.close();
    _fromIsolate = null;
    // Fire-and-forget: closing the controller flushes any buffered
    // events to the (already-cancelled) subscriber; the load-bearing
    // wait is the isolate-exit await below, not this close.
    if (!_events.isClosed) unawaited(_events.close());

    final exitPort = _exitPort;
    final isolate = _isolate;
    if (isolate == null || exitPort == null) {
      _toIsolate = null;
      _exitPort = null;
      _freeStopFlag();
      return true;
    }

    _isolate = null;
    _toIsolate = null;
    _exitPort = null;

    // The exit listener was armed in `start()` before the isolate could
    // possibly tear down. The 2 s timeout is a safety net for a pathologically
    // stuck libmpv: clean exits land in single-digit ms via `mpv_wakeup`.
    try {
      await exitPort.first.timeout(_kIsolateExitTimeout);
      _freeStopFlag();
      return true;
    } on TimeoutException {
      // Leaked on purpose: drop the pointer so a later stop() (dispose
      // after a timed-out bring-up teardown) cannot free it under the
      // worker that may still read it.
      _stopFlag = null;
      return false;
    } finally {
      exitPort.close();
    }
  }

  void _freeStopFlag() {
    final flag = _stopFlag;
    if (flag != null) {
      calloc.free(flag);
      _stopFlag = null;
    }
  }
}
