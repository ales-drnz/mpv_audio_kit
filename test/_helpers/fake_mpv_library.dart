// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:mpv_audio_kit/src/mpv_bindings.dart';

/// An [MpvLibrary] for the tests that run without a core: each call goes
/// to the function of the same name set on it. A call whose function is
/// not set throws a [StateError], so a stray call fails the test instead
/// of reaching a real libmpv.
class FakeMpvLibrary implements MpvLibrary {
  /// What [mpvCreate] does.
  Pointer<MpvHandle> Function()? create;

  /// What [mpvInitialize] does.
  int Function(Pointer<MpvHandle>)? initialize;

  /// What [mpvTerminateDestroy] does.
  void Function(Pointer<MpvHandle>)? terminateDestroy;

  /// What [mpvWakeup] does.
  void Function(Pointer<MpvHandle>)? wakeup;

  /// What [mpvSetOptionString] does.
  int Function(Pointer<MpvHandle>, Pointer<Utf8>, Pointer<Utf8>)?
  setOptionString;

  /// What [mpvSetPropertyString] does.
  int Function(Pointer<MpvHandle>, Pointer<Utf8>, Pointer<Utf8>)?
  setPropertyString;

  /// What [mpvGetPropertyString] does.
  Pointer<Utf8> Function(Pointer<MpvHandle>, Pointer<Utf8>)? getPropertyString;

  /// What [mpvGetProperty] does.
  int Function(Pointer<MpvHandle>, Pointer<Utf8>, int, Pointer<Void>)?
  getProperty;

  /// What [mpvSetPropertyAsync] does.
  int Function(Pointer<MpvHandle>, int, Pointer<Utf8>, int, Pointer<Void>)?
  setPropertyAsync;

  /// What [mpvGetPropertyAsync] does.
  int Function(Pointer<MpvHandle>, int, Pointer<Utf8>, int)? getPropertyAsync;

  /// What [mpvCommandAsync] does.
  int Function(Pointer<MpvHandle>, int, Pointer<Pointer<Utf8>>)? commandAsync;

  /// What [mpvCommandString] does.
  int Function(Pointer<MpvHandle>, Pointer<Utf8>)? commandString;

  /// What [mpvWaitEvent] does.
  Pointer<MpvEvent> Function(Pointer<MpvHandle>, double)? waitEvent;

  /// What [mpvObserveProperty] does.
  int Function(Pointer<MpvHandle>, int, Pointer<Utf8>, int)? observeProperty;

  /// What [mpvFree] does.
  void Function(Pointer<Void>)? free;

  /// What [mpvFreeNodeContents] does.
  void Function(Pointer<MpvNode>)? freeNodeContents;

  /// What [mpvErrorString] does.
  Pointer<Utf8> Function(int)? errorString;

  /// What [mpvRequestLogMessages] does.
  int Function(Pointer<MpvHandle>, Pointer<Utf8>)? requestLogMessages;

  /// What [mpvHookAdd] does.
  int Function(Pointer<MpvHandle>, int, Pointer<Utf8>, int)? hookAdd;

  /// What [mpvHookContinue] does.
  int Function(Pointer<MpvHandle>, int)? hookContinue;

  @override
  Pointer<MpvHandle> mpvCreate() => _set(create, 'mpvCreate')();

  @override
  int mpvInitialize(Pointer<MpvHandle> ctx) =>
      _set(initialize, 'mpvInitialize')(ctx);

  @override
  void mpvTerminateDestroy(Pointer<MpvHandle> ctx) =>
      _set(terminateDestroy, 'mpvTerminateDestroy')(ctx);

  @override
  void mpvWakeup(Pointer<MpvHandle> ctx) => _set(wakeup, 'mpvWakeup')(ctx);

  @override
  int mpvSetOptionString(
    Pointer<MpvHandle> ctx,
    Pointer<Utf8> name,
    Pointer<Utf8> data,
  ) => _set(setOptionString, 'mpvSetOptionString')(ctx, name, data);

  @override
  int mpvSetPropertyString(
    Pointer<MpvHandle> ctx,
    Pointer<Utf8> name,
    Pointer<Utf8> data,
  ) => _set(setPropertyString, 'mpvSetPropertyString')(ctx, name, data);

  @override
  Pointer<Utf8> mpvGetPropertyString(
    Pointer<MpvHandle> ctx,
    Pointer<Utf8> name,
  ) => _set(getPropertyString, 'mpvGetPropertyString')(ctx, name);

  @override
  int mpvGetProperty(
    Pointer<MpvHandle> ctx,
    Pointer<Utf8> name,
    int format,
    Pointer<Void> data,
  ) => _set(getProperty, 'mpvGetProperty')(ctx, name, format, data);

  @override
  int mpvSetPropertyAsync(
    Pointer<MpvHandle> ctx,
    int replyUserdata,
    Pointer<Utf8> name,
    int format,
    Pointer<Void> data,
  ) => _set(setPropertyAsync, 'mpvSetPropertyAsync')(
    ctx,
    replyUserdata,
    name,
    format,
    data,
  );

  @override
  int mpvGetPropertyAsync(
    Pointer<MpvHandle> ctx,
    int replyUserdata,
    Pointer<Utf8> name,
    int format,
  ) => _set(getPropertyAsync, 'mpvGetPropertyAsync')(
    ctx,
    replyUserdata,
    name,
    format,
  );

  @override
  int mpvCommandAsync(
    Pointer<MpvHandle> ctx,
    int replyUserdata,
    Pointer<Pointer<Utf8>> args,
  ) => _set(commandAsync, 'mpvCommandAsync')(ctx, replyUserdata, args);

  @override
  int mpvCommandString(Pointer<MpvHandle> ctx, Pointer<Utf8> args) =>
      _set(commandString, 'mpvCommandString')(ctx, args);

  @override
  Pointer<MpvEvent> mpvWaitEvent(Pointer<MpvHandle> ctx, double timeout) =>
      _set(waitEvent, 'mpvWaitEvent')(ctx, timeout);

  @override
  int mpvObserveProperty(
    Pointer<MpvHandle> ctx,
    int replyUserdata,
    Pointer<Utf8> name,
    int format,
  ) => _set(observeProperty, 'mpvObserveProperty')(
    ctx,
    replyUserdata,
    name,
    format,
  );

  @override
  void mpvFree(Pointer<Void> data) => _set(free, 'mpvFree')(data);

  @override
  void mpvFreeNodeContents(Pointer<MpvNode> node) =>
      _set(freeNodeContents, 'mpvFreeNodeContents')(node);

  @override
  Pointer<Utf8> mpvErrorString(int error) =>
      _set(errorString, 'mpvErrorString')(error);

  @override
  int mpvRequestLogMessages(Pointer<MpvHandle> ctx, Pointer<Utf8> minLevel) =>
      _set(requestLogMessages, 'mpvRequestLogMessages')(ctx, minLevel);

  @override
  int mpvHookAdd(
    Pointer<MpvHandle> ctx,
    int replyUserdata,
    Pointer<Utf8> name,
    int priority,
  ) => _set(hookAdd, 'mpvHookAdd')(ctx, replyUserdata, name, priority);

  @override
  int mpvHookContinue(Pointer<MpvHandle> ctx, int id) =>
      _set(hookContinue, 'mpvHookContinue')(ctx, id);

  static T _set<T extends Function>(T? f, String name) =>
      f ?? (throw StateError('FakeMpvLibrary.$name called, and not set'));
}
