// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import '../../events/player_exception.dart';
import '../../internals/core_events.dart';
import '../../internals/event_logic.dart';
import '../../internals/event_sequencer.dart';
import '../../mpv_constants.dart';
import '../mpv_session.dart';
import 'mpv_module.dart';
import 'web_client.dart';

/// Test-only: gets a line for each event the pump takes, each read it
/// sends and gets back, and each call that locks the core.
@visibleForTesting
void Function(String line)? debugWebSessionTrace;

/// Reply id of the pump's own `pause` observer: 2^40, above every id the
/// player hands out and exact in a JavaScript number.
const int _kPauseObserverReplyId = 1099511627776;

/// The events the read client is spared: it only sends reads, and drains
/// their replies.
const List<int> _kReadClientMuted = [
  MpvEventId.mpvEventLogMessage,
  MpvEventId.mpvEventStartFile,
  MpvEventId.mpvEventEndFile,
  MpvEventId.mpvEventFileLoaded,
  MpvEventId.mpvEventIdle,
  MpvEventId.mpvEventTick,
  MpvEventId.mpvEventClientMessage,
  MpvEventId.mpvEventVideoReconfig,
  MpvEventId.mpvEventAudioReconfig,
  MpvEventId.mpvEventSeek,
  MpvEventId.mpvEventPlaybackRestart,
  MpvEventId.mpvEventPropertyChange,
  MpvEventId.mpvEventQueueOverflow,
  MpvEventId.mpvEventHook,
];

/// A core in the web module, driven from the browser's main thread.
///
/// The main thread may not block, so the event pump has no loop of its
/// own: the module's wakeup bridge calls it whenever mpv wakes the client,
/// and it takes the events with `mpv_wait_event(h, 0)` through an
/// [EventSequencer] into the shared [EventLogic]. The logic's reads go out
/// asynchronously on a second client of the same core, whose queue holds
/// only their replies; while they are in flight the sequencer leaves the
/// player's client alone, so its events wait in mpv's queue as they do
/// behind the native pump's blocking reads.
///
/// The calls that lock the core (`mpv_initialize`, `mpv_hook_add`,
/// `mpv_hook_continue`, `mpv_terminate_destroy`) run on the main thread,
/// where Emscripten waits for the lock with a busy loop; their longest
/// runs are kept in [webCallMaxMicros].
@internal
final class WebSession implements MpvSession {
  /// A session over the module [_module] resolves with.
  WebSession(this._module);

  final Future<MpvModule> Function() _module;
  late final MpvModule _m;
  late final WebClient _client;
  late final EventLogic _logic;
  late final EventSequencer _sequencer;

  // The player's client and the read client; 0 until [start] created them
  // and after [terminateDestroy] freed them.
  int _handle = 0;
  int _reads = 0;
  int _handleBridge = 0;
  int _readsBridge = 0;

  // Non-broadcast, like the native pump's: one subscriber, and the events
  // that come before it are buffered.
  final _events = StreamController<MpvIsolateEvent>();
  bool _started = false;
  bool _stopped = false;
  int _nextRead = 1;
  final Map<int, Completer<Object?>> _pendingReads = {};

  @override
  Future<void> start(
    CoreRecipe recipe,
    void Function(MpvIsolateEvent event) onEvent,
  ) async {
    _events.stream.listen(onEvent);
    _m = await _module();
    final c = _m.c;
    final h = timedCall('mpv_create', () => c.mpvCreate());
    if (h == 0) throw const PlayerInitException('mpv_create() returned NULL');
    try {
      for (final option in recipe.preInitOptions.entries) {
        _m.withStrings([
          option.key,
          option.value,
        ], (p) => c.mpvSetOptionString(h, p[0], p[1]));
      }
      final level = recipe.logLevel;
      if (level != null) {
        _m.withStrings([level], (p) => c.mpvRequestLogMessages(h, p[0]));
      }
      final rc = timedCall('mpv_initialize', () => c.mpvInitialize(h));
      if (rc < 0) {
        timedCall('mpv_terminate_destroy', () => c.mpvTerminateDestroy(h));
        throw PlayerInitException('mpv_initialize() failed: rc=$rc');
      }
      // Synchronous like the native recipe: the core is idle this early.
      for (final property in recipe.postInitOptions.entries) {
        timedCall(
          'mpv_set_property_string',
          () => _m.withStrings([
            property.key,
            property.value,
          ], (p) => c.mpvSetPropertyString(h, p[0], p[1])),
        );
      }
      for (final spec in recipe.observes) {
        _observe(h, spec.replyId, spec.name, spec.format);
      }
      // Not registered with the logic: `pause` never reaches the player,
      // the logic reads it for the end of content only.
      _observe(h, _kPauseObserverReplyId, 'pause', MpvFormat.mpvFormatFlag);
      _reads = _m.withStrings(['mak_reads'], (p) => c.mpvCreateClient(h, p[0]));
      if (_reads == 0) throw StateError('mpv_create_client() returned NULL');
      for (final id in _kReadClientMuted) {
        c.mpvRequestEvent(_reads, id, 0);
      }
    } on PlayerInitException {
      rethrow;
    } catch (e, st) {
      // The player gets no core from a failed init, so the one created
      // above is destroyed here or never.
      if (_reads != 0) c.mpvDestroy(_reads);
      _reads = 0;
      timedCall('mpv_terminate_destroy', () => c.mpvTerminateDestroy(h));
      throw PlayerInitException('init crashed: $e\n$st');
    }
    _handle = h;
    _client = WebClient(_m, h);
    _logic = EventLogic(_WebReader(this), _send);
    for (final spec in recipe.observes) {
      _logic.observe(spec.name, spec.format);
    }
    _sequencer = EventSequencer(
      take: _take,
      flushTrailing: _logic.flushTrailing,
      waitSeconds: () => _logic.holdsValues ? _logic.waitSeconds(1) : null,
      onError: (e, st) =>
          _send(MpvEventInternalLog('error', 'event dispatch failed: $e\n$st')),
    );
    _started = true;
    _readsBridge = _m.attachWakeup(_reads, _drainReads);
    _handleBridge = _m.attachWakeup(h, _sequencer.pump);
    // The events mpv queued before the bridge existed raised no wakeup.
    scheduleMicrotask(_sequencer.pump);
  }

  void _observe(int h, int replyId, String name, int format) {
    _m.withStrings([
      name,
    ], (p) => _m.c.mpvObserveProperty(h, bigInt(replyId), p[0], format));
  }

  void _send(MpvIsolateEvent event) {
    if (!_events.isClosed) _events.add(event);
  }

  /// Takes the next event of the player's client and hands it to the
  /// logic, decoded out of the module's memory before anything else runs:
  /// the payload is valid only until the next `mpv_wait_event`.
  TakenEvent _take() {
    final int e;
    try {
      e = _m.c.mpvWaitEvent(_handle, 0);
    } catch (_) {
      // The module itself failed: no event can be taken any more.
      _sequencer.stop();
      rethrow;
    }
    final id = _m.i32(e);
    if (id == MpvEventId.mpvEventNone) return (false, null, false);
    debugWebSessionTrace?.call('take $id');
    return (true, _dispatch(e, id), id == MpvEventId.mpvEventShutdown);
  }

  Future<void>? _dispatch(int e, int id) {
    final m = _m;
    final error = m.i32(e + 4);
    final userdata = m.i64(e + 8);
    final data = m.u32(e + 16);
    switch (id) {
      case MpvEventId.mpvEventPropertyChange:
        final format = m.i32(data + 4);
        return _logic.property(
          m.string(m.u32(data))!,
          format,
          _changeValue(format, m.u32(data + 8)),
        );
      case MpvEventId.mpvEventShutdown:
        return _logic.dispatch(MpvEventShutdown());
      case MpvEventId.mpvEventStartFile:
        return _logic.dispatch(MpvEventStartFile(m.i64(data)));
      case MpvEventId.mpvEventFileLoaded:
        return _logic.dispatch(MpvEventFileLoaded());
      case MpvEventId.mpvEventEndFile:
        return _logic.dispatch(
          MpvEventEndFile(m.i64(data + 8), m.i32(data), m.i32(data + 4)),
        );
      case MpvEventId.mpvEventAudioReconfig:
        return _logic.audioReconfig();
      case MpvEventId.mpvEventSetPropertyReply:
        return _logic.dispatch(MpvEventReply(userdata, error));
      case MpvEventId.mpvEventCommandReply:
        // The payload is an `mpv_event_command`: its `mpv_node result`.
        final result = error >= 0 && data != 0 ? m.node(data) : null;
        return _logic.dispatch(MpvEventReply(userdata, error, result));
      case MpvEventId.mpvEventGetPropertyReply:
        return _logic.dispatch(
          MpvEventGetReply(userdata, error, error >= 0 ? _value(data) : null),
        );
      case MpvEventId.mpvEventLogMessage:
        return _logic.dispatch(
          MpvEventLog(
            m.string(m.u32(data)) ?? '',
            m.string(m.u32(data + 4)) ?? '',
            (m.string(m.u32(data + 8)) ?? '').trimRight(),
          ),
        );
      case MpvEventId.mpvEventHook:
        return _logic.dispatch(
          MpvEventHookFired(m.i64(data + 8), m.string(m.u32(data)) ?? ''),
        );
      case MpvEventId.mpvEventPlaybackRestart:
        return _logic.dispatch(MpvEventPlaybackRestart());
    }
    return null;
  }

  /// The value of a property change as [EventLogic.property] takes it.
  Object? _changeValue(int format, int data) {
    if (format == MpvFormat.mpvFormatNone || data == 0) {
      return kPropertyUnavailable;
    }
    return switch (format) {
      MpvFormat.mpvFormatDouble ||
      MpvFormat.mpvFormatFlag ||
      MpvFormat.mpvFormatInt64 ||
      MpvFormat.mpvFormatString ||
      MpvFormat.mpvFormatNode => _m.value(format, data),
      _ => kPropertyUnobserved,
    };
  }

  /// The value of the `mpv_event_property` at [property], as a read
  /// carries it; `null` without one.
  Object? _value(int property) {
    if (property == 0) return null;
    final data = _m.u32(property + 8);
    return data == 0 ? null : _m.value(_m.i32(property + 4), data);
  }

  /// Sends a read of [name] in [format] on the read client.
  Future<Object?> _read(String name, int format) {
    if (_stopped) return Future.value();
    final id = _nextRead++;
    debugWebSessionTrace?.call('read $id $name');
    final reply = Completer<Object?>();
    _pendingReads[id] = reply;
    final rc = _m.withStrings([
      name,
    ], (p) => _m.c.mpvGetPropertyAsync(_reads, bigInt(id), p[0], format));
    if (rc < 0) {
      _pendingReads.remove(id);
      return Future.value();
    }
    return reply.future;
  }

  /// Drains the read client: its queue holds the replies of [_read].
  void _drainReads() {
    while (_reads != 0) {
      final e = _m.c.mpvWaitEvent(_reads, 0);
      final id = _m.i32(e);
      if (id == MpvEventId.mpvEventNone) return;
      if (id != MpvEventId.mpvEventGetPropertyReply) continue;
      final reply = _pendingReads.remove(_m.i64(e + 8));
      if (reply == null) continue;
      Object? value;
      try {
        if (_m.i32(e + 4) >= 0) value = _value(_m.u32(e + 16));
      } catch (error) {
        // A read that cannot be decoded fails like a read mpv refused.
        _send(MpvEventInternalLog('warn', 'decoding a read failed: $error'));
      }
      debugWebSessionTrace?.call('read back ${_m.i64(e + 8)}');
      reply.complete(value);
    }
  }

  @override
  void onReply(int id, int error, Object? result) =>
      _client.onReply(id, error, result);

  @override
  void onGetReply(int id, int error, Object? value) =>
      _client.onGetReply(id, error, value);

  @override
  Future<void> hookAdd(String name, int priority) async {
    timedCall(
      'mpv_hook_add',
      () => _m.withStrings([
        name,
      ], (p) => _m.c.mpvHookAdd(_handle, bigInt(0), p[0], priority)),
    );
  }

  // The hook registration completes within its call.
  @override
  Future<bool> settleHookAdds(Duration bound) async => true;

  // The Hot Restart registry of the web (a record on globalThis that the
  // next start of the page reads, DESIGN 11) hooks in here.
  @override
  void track() {}

  @override
  void untrack() {}

  @override
  void requestStop() {
    _stopped = true;
    if (_started) _sequencer.stop();
    // Nothing read after a stop reaches the player, as natively.
    final pending = _pendingReads.values.toList(growable: false);
    _pendingReads.clear();
    for (final reply in pending) {
      reply.complete();
    }
  }

  /// One thread runs the pump and this call, so the pump is stopped once
  /// it returns.
  @override
  Future<bool> stop() async {
    requestStop();
    if (!_events.isClosed) unawaited(_events.close());
    return true;
  }

  @override
  void close() => _client.close();

  @override
  Future<void> terminateDestroy() async {
    final h = _handle;
    if (h == 0) return;
    _handle = 0;
    final reads = _reads;
    _reads = 0;
    _m.detachWakeup(reads, _readsBridge);
    _m.detachWakeup(h, _handleBridge);
    timedCall('mpv_destroy', () => _m.c.mpvDestroy(reads));
    timedCall('mpv_terminate_destroy', () => _m.c.mpvTerminateDestroy(h));
  }

  // ── MpvRequests, through the player's client ──────────────────────────

  @override
  bool get isClosed => _client.isClosed;

  @override
  Future<int> setProperty(String name, String value) =>
      _client.setProperty(name, value);

  @override
  Future<int> setNodeProperty(String name, Object? value) =>
      _client.setNodeProperty(name, value);

  @override
  Future<(int, Object?)> command(List<String> args) => _client.command(args);

  @override
  Future<(int, Object?)> getProperty(String name, int format) =>
      _client.getProperty(name, format);

  @override
  Future<void> settleWrites() => _client.settleWrites();

  @override
  String errorString(int code) => _client.errorString(code);

  @override
  void hookContinue(int id) => _client.hookContinue(id);

  @override
  void requestLogMessages(String level) => _client.requestLogMessages(level);
}

/// The reads of [EventLogic] on the read client of [_session].
final class _WebReader implements CoreReader {
  _WebReader(this._session);

  final WebSession _session;

  @override
  Future<String?> string(String name) =>
      _session._read(name, MpvFormat.mpvFormatString).then((v) => v as String?);

  @override
  Future<double?> float(String name) => _session
      ._read(name, MpvFormat.mpvFormatDouble)
      .then((v) => (v as num?)?.toDouble());

  @override
  Future<int?> int64(String name) =>
      _session._read(name, MpvFormat.mpvFormatInt64).then((v) => v as int?);

  @override
  Future<int?> flag(String name) =>
      _session._read(name, MpvFormat.mpvFormatFlag).then((v) => v as int?);

  @override
  Future<Object?> node(String name) =>
      _session._read(name, MpvFormat.mpvFormatNode);
}
