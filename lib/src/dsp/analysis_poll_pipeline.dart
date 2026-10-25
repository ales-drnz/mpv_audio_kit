// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import '../mpv_constants.dart';
import 'dsp_async_io.dart';
import 'shared_property_writer.dart';

/// The polling shared by the per-file analyses (waveform, loudness scan).
///
/// Listener-gated by [setEnabled]: while a listener is attached the player
/// writes the analysis' enable property `true` (the native side only runs
/// while it is set) and the pipeline polls its data property on a low-rate
/// timer. On the last cancel the property goes back to `false` and the
/// timer stops, so an idle analysis costs nothing.
///
/// The enable property is a static of the libmpv process, shared by every
/// player: it stays on while a pipeline of this isolate holds it, and the
/// last one to let go (a cancel, or [dispose]) turns it off. A listener
/// that comes back while the file's result stands gets it from the
/// player's replay, and the property stays off until the next file
/// ([reset]): writing it on would decode the whole file again.
///
/// A subclass decodes each poll in [onData]: it [emit]s partial values and
/// calls [finish] with the final one, which stops polling until the next
/// [reset] (a new file) or [clear] (no file).
@internal
abstract class AnalysisPollPipeline<T extends Object> {
  AnalysisPollPipeline({
    required AsyncPropertyGet asyncGet,
    required AsyncPropertySet asyncSet,
    required String enabledProperty,
    required String dataProperty,
    Duration pollInterval = const Duration(milliseconds: 120),
  }) : _asyncGet = asyncGet,
       _asyncSet = asyncSet,
       _enabledProperty = enabledProperty,
       _dataProperty = dataProperty,
       _pollInterval = pollInterval;

  final AsyncPropertyGet _asyncGet;
  final AsyncPropertySet _asyncSet;
  final String _enabledProperty;
  final String _dataProperty;
  final Duration _pollInterval;

  final StreamController<T?> _ctrl = StreamController<T?>.broadcast();
  Timer? _pollTimer;
  T? _result;
  bool _enabled = false;
  // Whether this pipeline holds the native enable property on.
  bool _nativeOn = false;
  late final _Switch _switch = _switches.putIfAbsent(
    _enabledProperty,
    () => _Switch(_enabledProperty),
  );

  // The enable properties, one per analysis, by name.
  static final Map<String, _Switch> _switches = {};
  bool _disposed = false;
  // No file loaded (after [clear]): mpv still holds the last file's
  // analysis, so nothing is polled until the next [reset].
  bool _idle = false;
  // Guards against overlapping async polls; see [LoudnessMeterPipeline].
  bool _polling = false;

  Stream<T?> get stream => _ctrl.stream;

  /// Arms or disarms the analysis. Driven by the `onListen` and `onCancel`
  /// of the player's controller. Writes the enable property and starts or
  /// stops polling.
  void setEnabled(bool enabled) {
    if (_disposed || enabled == _enabled) return;
    _enabled = enabled;
    if (enabled) {
      // A finished result already reaches a new subscriber through the
      // player's replay of the last value: the native side stays off until
      // the next file. Only a pending result arms it and polls.
      if (_result == null) {
        _setNative(true);
        _armTimer();
      }
    } else {
      _setNative(false);
      stopPolling();
    }
  }

  /// Drops the current result and emits `null` so renderers clear stale
  /// data on the track-change boundary. Rearms the polling timer when the
  /// analysis is still enabled.
  void reset() {
    if (_disposed) return;
    _idle = false;
    _drop();
    if (_enabled) {
      _setNative(true);
      _armTimer();
    }
  }

  /// Drops the current result and emits `null` once no file is loaded,
  /// without polling again until the next [reset].
  void clear() {
    if (_disposed) return;
    _idle = true;
    _drop();
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    stopPolling();
    // The flag outlives this player: left on, the next player in the
    // process would analyze every file it loads.
    _setNative(false);
    if (!_ctrl.isClosed) await _ctrl.close();
  }

  void _setNative(bool on) {
    if (on == _nativeOn) return;
    _nativeOn = on;
    final sw = _switch;
    if (on) {
      sw.holders++;
      // Written on every enable, held already or not: on a core with a
      // file loaded it starts the analysis of that file, so it goes
      // through this player's core.
      sw.writer.write(_asyncSet, () => _nativeOn ? 'yes' : null);
    } else if (--sw.holders == 0) {
      // Off only when no other player of this isolate holds it.
      sw.writer.write(
        _asyncSet,
        () => sw.holders == 0 ? 'no' : null,
        anyCore: true,
      );
    }
  }

  /// Decodes one reply of the data property, a map.
  @protected
  void onData(Map<Object?, Object?> value);

  /// Forgets what [onData] remembers between polls (progress seen, ...).
  @protected
  void onDrop();

  @protected
  void emit(T? value) {
    if (!_ctrl.isClosed) _ctrl.add(value);
  }

  /// Emits the final [value] and stops polling until the next [reset].
  @protected
  void finish(T value) {
    _result = value;
    stopPolling();
    emit(value);
  }

  @protected
  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  void _drop() {
    _result = null;
    onDrop();
    stopPolling();
    emit(null);
  }

  void _armTimer() {
    if (_disposed || _idle || _result != null) return;
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _poll());
    _poll();
  }

  void _poll() {
    if (_disposed || _polling || _result != null) return;
    _polling = true;
    unawaited(_doPoll().whenComplete(() => _polling = false));
  }

  Future<void> _doPoll() async {
    final (rc, value) = await _asyncGet(_dataProperty, MpvFormat.mpvFormatNode);
    if (_disposed || _idle || _result != null) return;
    if (rc < 0 || value is! Map) return;
    try {
      onData(value);
    } catch (_) {
      // A single malformed node must never escape the poll: an uncaught
      // throw would tear down the poll loop and freeze the analysis until
      // the next file. The next tick retries against fresh native state.
    }
  }
}

/// One enable property: how many pipelines of this isolate hold it on, and
/// the writer that orders their writes across the players' cores.
final class _Switch {
  _Switch(String property) : writer = SharedPropertyWriter(property);

  final SharedPropertyWriter writer;
  int holders = 0;
}
