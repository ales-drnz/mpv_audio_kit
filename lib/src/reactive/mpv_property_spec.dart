// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../mpv_bindings.dart';
import '../models/player_state.dart';
import 'reactive_property.dart';

/// Declarative description of a single mpv property exposed by the player.
///
/// One spec captures everything that previously had to be wired across six
/// disconnected sites: the [ReactiveProperty] that owns the Dart-side value,
/// the mpv property name + format used to call `mpv_observe_property`, the
/// raw → typed parser, and the reducer that folds the new value into
/// [PlayerState]. The result is that adding an observed property to the
/// public API is a one-line edit to the spec list.
///
/// Concrete spec types ([MpvDoubleSpec], [MpvFlagSpec], [MpvStringSpec],
/// [MpvIntSpec]) only differ in which [MpvFormat] they bind to mpv and what
/// raw Dart type they accept from the event isolate.
abstract class MpvPropertySpec<T> {
  /// The mpv property name passed to `mpv_observe_property` / `mpv_set_property`.
  String get name;

  /// One of the [MpvFormat] integer constants — selects the wire format used
  /// by mpv when delivering value updates.
  int get format;

  /// The Dart-side value cell. Updated by [parseAndDispatch] on each property
  /// change; exposed publicly through `Player.stream`.
  ReactiveProperty<T> get reactive;

  /// Folds [next] into the player's [PlayerState]. Returning the same state
  /// (== identity) is a valid no-op for properties that don't have a
  /// corresponding [PlayerState] field (e.g. the patched `prefetch-state`,
  /// which is stream-only).
  PlayerState reduce(T next, PlayerState state);

  /// Optional side-effect callback fired after [reactive] has been updated
  /// and [reduce] has been applied. Use sparingly — keep cross-property
  /// orchestration out of specs and in the player itself.
  void Function(T next)? get onChange => null;

  /// Parses a raw mpv-side value and applies the full update pipeline:
  /// dedup → reactive update → state reduce → onChange. Returns the new
  /// [PlayerState], or `null` if the value was deduplicated (no change).
  PlayerState? parseAndDispatch(dynamic raw, PlayerState state);
}

/// Spec for an mpv property delivered as `MPV_FORMAT_DOUBLE`.
class MpvDoubleSpec<T> extends MpvPropertySpec<T> {
  MpvDoubleSpec({
    required this.name,
    required this.reactive,
    required T Function(double raw) parse,
    required PlayerState Function(T value, PlayerState state) reduce,
    void Function(T value)? onChange,
  })  : _parse = parse,
        _reduce = reduce,
        _onChange = onChange;

  @override
  final String name;

  @override
  final ReactiveProperty<T> reactive;

  final T Function(double raw) _parse;
  final PlayerState Function(T value, PlayerState state) _reduce;
  final void Function(T value)? _onChange;

  @override
  int get format => MpvFormat.mpvFormatDouble;

  @override
  PlayerState reduce(T next, PlayerState state) => _reduce(next, state);

  @override
  void Function(T next)? get onChange => _onChange;

  @override
  PlayerState? parseAndDispatch(dynamic raw, PlayerState state) {
    final value = _parse(raw as double);
    if (!reactive.update(value)) return null;
    final next = _reduce(value, state);
    _onChange?.call(value);
    return next;
  }
}

/// Spec for an mpv property delivered as `MPV_FORMAT_FLAG` (a 0/1 int that
/// the event isolate has already decoded into a Dart `bool`).
class MpvFlagSpec<T> extends MpvPropertySpec<T> {
  MpvFlagSpec({
    required this.name,
    required this.reactive,
    required T Function(bool raw) parse,
    required PlayerState Function(T value, PlayerState state) reduce,
    void Function(T value)? onChange,
  })  : _parse = parse,
        _reduce = reduce,
        _onChange = onChange;

  @override
  final String name;

  @override
  final ReactiveProperty<T> reactive;

  final T Function(bool raw) _parse;
  final PlayerState Function(T value, PlayerState state) _reduce;
  final void Function(T value)? _onChange;

  @override
  int get format => MpvFormat.mpvFormatFlag;

  @override
  PlayerState reduce(T next, PlayerState state) => _reduce(next, state);

  @override
  void Function(T next)? get onChange => _onChange;

  @override
  PlayerState? parseAndDispatch(dynamic raw, PlayerState state) {
    // The event isolate forwards flag values as `int` (0/1); accept either
    // representation defensively so future changes don't silently miss flags.
    final asBool = raw is int ? raw == 1 : raw as bool;
    final value = _parse(asBool);
    if (!reactive.update(value)) return null;
    final next = _reduce(value, state);
    _onChange?.call(value);
    return next;
  }
}

/// Spec for an mpv property delivered as `MPV_FORMAT_INT64`.
class MpvIntSpec<T> extends MpvPropertySpec<T> {
  MpvIntSpec({
    required this.name,
    required this.reactive,
    required T Function(int raw) parse,
    required PlayerState Function(T value, PlayerState state) reduce,
    void Function(T value)? onChange,
  })  : _parse = parse,
        _reduce = reduce,
        _onChange = onChange;

  @override
  final String name;

  @override
  final ReactiveProperty<T> reactive;

  final T Function(int raw) _parse;
  final PlayerState Function(T value, PlayerState state) _reduce;
  final void Function(T value)? _onChange;

  @override
  int get format => MpvFormat.mpvFormatInt64;

  @override
  PlayerState reduce(T next, PlayerState state) => _reduce(next, state);

  @override
  void Function(T next)? get onChange => _onChange;

  @override
  PlayerState? parseAndDispatch(dynamic raw, PlayerState state) {
    final value = _parse(raw as int);
    if (!reactive.update(value)) return null;
    final next = _reduce(value, state);
    _onChange?.call(value);
    return next;
  }
}

/// Spec for an mpv property delivered as `MPV_FORMAT_STRING`.
class MpvStringSpec<T> extends MpvPropertySpec<T> {
  MpvStringSpec({
    required this.name,
    required this.reactive,
    required T Function(String raw) parse,
    required PlayerState Function(T value, PlayerState state) reduce,
    void Function(T value)? onChange,
  })  : _parse = parse,
        _reduce = reduce,
        _onChange = onChange;

  @override
  final String name;

  @override
  final ReactiveProperty<T> reactive;

  final T Function(String raw) _parse;
  final PlayerState Function(T value, PlayerState state) _reduce;
  final void Function(T value)? _onChange;

  @override
  int get format => MpvFormat.mpvFormatString;

  @override
  PlayerState reduce(T next, PlayerState state) => _reduce(next, state);

  @override
  void Function(T next)? get onChange => _onChange;

  @override
  PlayerState? parseAndDispatch(dynamic raw, PlayerState state) {
    final value = _parse(raw as String);
    if (!reactive.update(value)) return null;
    final next = _reduce(value, state);
    _onChange?.call(value);
    return next;
  }
}
