// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../mpv_bindings.dart';
import '../player_state.dart';
import 'reactive_property.dart';

/// Declarative description of a single mpv property exposed by the player.
///
/// One spec collects everything needed to bridge an mpv property to a
/// Dart-side value: the [ReactiveProperty] that owns the cell, the mpv
/// property name + format used to call `mpv_observe_property`, the
/// raw → typed parser, and the reducer that folds the new value into
/// [PlayerState]. Adding an observed property to the public API is a
/// one-line edit to the spec list.
///
/// The five named factory constructors ([MpvPropertySpec.double],
/// [MpvPropertySpec.flag], [MpvPropertySpec.int64], [MpvPropertySpec.string],
/// [MpvPropertySpec.node]) only differ in which [MpvFormat] they bind to mpv
/// and what raw Dart type the parser accepts. Funnelling them through a
/// single `parseAndDispatch` pipeline (parse → dedup → reactive update →
/// state reduce → onChange) keeps "format → spec → dispatch" a single
/// source of truth — adding a format is one new factory and one new branch
/// in the event isolate, no chance to wire one and forget the other.
///
/// The [T] generic is the type of the [reactive] cell. For most
/// properties [T] is also the parsed value type (a scalar like `double` or
/// `bool`). For aggregate properties — where a single mpv property updates
/// only one field of a larger config — the parser folds the parsed value
/// into the current [PlayerState]'s aggregate and returns the *whole*
/// aggregate, so the reactive holds and dedups on the full struct. This
/// is why every parse callback receives the current [PlayerState].
class MpvPropertySpec<T> {
  /// Internal canonical constructor. All factories funnel through here so the
  /// dispatch pipeline ([parseAndDispatch]) is implemented exactly once.
  MpvPropertySpec._({
    required this.name,
    required this.format,
    required this.reactive,
    required T Function(dynamic raw, PlayerState state) parse,
    required PlayerState Function(T value, PlayerState state) reduce,
    void Function(T value)? onChange,
  })  : _parse = parse,
        _reduce = reduce,
        _onChange = onChange;

  /// Spec for an mpv property delivered as `MPV_FORMAT_DOUBLE`.
  factory MpvPropertySpec.double({
    required String name,
    required ReactiveProperty<T> reactive,
    required T Function(double raw, PlayerState state) parse,
    required PlayerState Function(T value, PlayerState state) reduce,
    void Function(T value)? onChange,
  }) =>
      MpvPropertySpec._(
        name: name,
        format: MpvFormat.mpvFormatDouble,
        reactive: reactive,
        parse: (raw, state) => parse(raw as double, state),
        reduce: reduce,
        onChange: onChange,
      );

  /// Spec for an mpv property delivered as `MPV_FORMAT_FLAG`. The event
  /// isolate forwards flag values as `int` (0/1); we accept either
  /// representation defensively so future format changes don't silently
  /// miss flags.
  factory MpvPropertySpec.flag({
    required String name,
    required ReactiveProperty<T> reactive,
    required T Function(bool raw, PlayerState state) parse,
    required PlayerState Function(T value, PlayerState state) reduce,
    void Function(T value)? onChange,
  }) =>
      MpvPropertySpec._(
        name: name,
        format: MpvFormat.mpvFormatFlag,
        reactive: reactive,
        parse: (raw, state) =>
            parse(raw is int ? raw == 1 : raw as bool, state),
        reduce: reduce,
        onChange: onChange,
      );

  /// Spec for an mpv property delivered as `MPV_FORMAT_INT64`.
  factory MpvPropertySpec.int64({
    required String name,
    required ReactiveProperty<T> reactive,
    required T Function(int raw, PlayerState state) parse,
    required PlayerState Function(T value, PlayerState state) reduce,
    void Function(T value)? onChange,
  }) =>
      MpvPropertySpec._(
        name: name,
        format: MpvFormat.mpvFormatInt64,
        reactive: reactive,
        parse: (raw, state) => parse(raw as int, state),
        reduce: reduce,
        onChange: onChange,
      );

  /// Spec for an mpv property delivered as `MPV_FORMAT_STRING`.
  factory MpvPropertySpec.string({
    required String name,
    required ReactiveProperty<T> reactive,
    required T Function(String raw, PlayerState state) parse,
    required PlayerState Function(T value, PlayerState state) reduce,
    void Function(T value)? onChange,
  }) =>
      MpvPropertySpec._(
        name: name,
        format: MpvFormat.mpvFormatString,
        reactive: reactive,
        parse: (raw, state) => parse(raw as String, state),
        reduce: reduce,
        onChange: onChange,
      );

  /// Spec for an mpv property delivered as `MPV_FORMAT_NODE`. The raw value
  /// passed to [parse] is a Dart-native tree (`Map<String, dynamic>`,
  /// `List<dynamic>`, scalar, or `null`) decoded by the event isolate from
  /// mpv's `mpv_node` recursive struct. Use this for properties mpv exposes
  /// natively as structured data — `playlist`, `metadata`,
  /// `audio-device-list`, `audio-params`, `audio-out-params`,
  /// `demuxer-cache-state`, `track-list` — instead of observing them as
  /// strings and parsing JSON in Dart.
  factory MpvPropertySpec.node({
    required String name,
    required ReactiveProperty<T> reactive,
    required T Function(dynamic raw, PlayerState state) parse,
    required PlayerState Function(T value, PlayerState state) reduce,
    void Function(T value)? onChange,
  }) =>
      MpvPropertySpec._(
        name: name,
        format: MpvFormat.mpvFormatNode,
        reactive: reactive,
        parse: parse,
        reduce: reduce,
        onChange: onChange,
      );

  /// The mpv property name passed to `mpv_observe_property` / `mpv_set_property`.
  final String name;

  /// One of the [MpvFormat] integer constants — selects the wire format used
  /// by mpv when delivering value updates.
  final int format;

  /// The Dart-side value cell. Updated by [parseAndDispatch] on each property
  /// change; exposed publicly through `Player.stream`.
  final ReactiveProperty<T> reactive;

  final T Function(dynamic raw, PlayerState state) _parse;
  final PlayerState Function(T value, PlayerState state) _reduce;
  final void Function(T value)? _onChange;

  /// Folds [next] into the player's [PlayerState]. Returning the same state
  /// (== identity) is a valid no-op for properties that don't have a
  /// corresponding [PlayerState] field (e.g. `prefetch-state`, which is
  /// stream-only).
  PlayerState reduce(T next, PlayerState state) => _reduce(next, state);

  /// Optional side-effect callback fired after [reactive] has been updated
  /// and [reduce] has been applied. Use sparingly — keep cross-property
  /// orchestration out of specs and in the player itself.
  void Function(T next)? get onChange => _onChange;

  /// Parses a raw mpv-side value and applies the full update pipeline:
  /// parse → dedup → reactive update → state reduce → onChange. Returns
  /// the new [PlayerState], or `null` if the value was deduplicated (no
  /// change).
  PlayerState? parseAndDispatch(dynamic raw, PlayerState state) {
    final value = _parse(raw, state);
    if (!reactive.update(value)) return null;
    final next = _reduce(value, state);
    _onChange?.call(value);
    return next;
  }
}
