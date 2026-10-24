// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:async';

import 'package:mpv_audio_kit/src/internals/mpv_requests.dart';
import 'package:mpv_audio_kit/src/mpv_bindings.dart' show MpvError;

/// [MpvRequests] in memory, without libmpv: the writes land in
/// [properties] and [nodes], the commands in [commands], and the reads
/// answer from [reads]. Every request goes into [requests] in the order it
/// was sent, so a test can check the order without a core.
final class FakeMpv implements MpvRequests {
  /// Property values: every accepted [setProperty] writes here.
  final Map<String, String> properties = {};

  /// Node values: every accepted [setNodeProperty] writes here.
  final Map<String, Object?> nodes = {};

  /// The commands sent, accepted or not.
  final List<List<String>> commands = [];

  /// The answers of [getProperty], by name. A missing name reads as
  /// [MpvError.mpvErrorPropertyUnavailable].
  final Map<String, (int, Object?)> reads = {};

  /// Every request as `kind name-or-args`, in the order sent.
  final List<String> requests = [];

  /// The ids [hookContinue] was called with.
  final List<int> continued = [];

  /// The levels [requestLogMessages] was called with.
  final List<String> logLevels = [];

  /// The rc of a write: success unless the test says otherwise. A refused
  /// write leaves [properties] or [nodes] as they were.
  int Function(String name, Object? value) writeRc = (_, _) =>
      MpvError.mpvErrorSuccess;

  /// The reply of a command: success with no result unless the test says
  /// otherwise.
  (int, Object?) Function(List<String> args) commandReply = (_) =>
      (MpvError.mpvErrorSuccess, null);

  /// Messages of [errorString], by code; `error <code>` otherwise.
  final Map<int, String> errorMessages = {};

  final List<Completer<void>> _held = [];
  bool _holding = false;

  /// From now on the replies wait until [release]; [settleWrites] waits
  /// for them too.
  void hold() => _holding = true;

  /// Delivers the held replies, in the order the requests went out.
  void release() {
    _holding = false;
    final held = List.of(_held);
    _held.clear();
    for (final c in held) {
      c.complete();
    }
  }

  @override
  bool isClosed = false;

  Future<T> _reply<T>(T value) async {
    if (_holding) {
      final c = Completer<void>();
      _held.add(c);
      await c.future;
    }
    return value;
  }

  @override
  Future<int> setProperty(String name, String value) {
    requests.add('set $name');
    final rc = writeRc(name, value);
    if (rc >= 0) properties[name] = value;
    return _reply(rc);
  }

  @override
  Future<int> setNodeProperty(String name, Object? value) {
    requests.add('node $name');
    final rc = writeRc(name, value);
    if (rc >= 0) nodes[name] = value;
    return _reply(rc);
  }

  @override
  Future<(int, Object?)> command(List<String> args) {
    requests.add('command ${args.join(' ')}');
    commands.add(args);
    return _reply(commandReply(args));
  }

  @override
  Future<(int, Object?)> getProperty(String name, int format) {
    requests.add('get $name');
    return _reply(reads[name] ?? (MpvError.mpvErrorPropertyUnavailable, null));
  }

  @override
  Future<void> settleWrites() => Future.wait([for (final c in _held) c.future]);

  @override
  String errorString(int code) => errorMessages[code] ?? 'error $code';

  @override
  void hookContinue(int id) {
    requests.add('continue $id');
    continued.add(id);
  }

  @override
  void requestLogMessages(String level) {
    requests.add('log $level');
    logLevels.add(level);
  }
}
