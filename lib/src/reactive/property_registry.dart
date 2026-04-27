// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:ffi';
import 'package:ffi/ffi.dart';

import '../models/player_state.dart';
import '../mpv_bindings.dart';
import 'mpv_property_spec.dart';

/// A flat collection of [MpvPropertySpec]s with a single dispatch entry-point.
///
/// The registry owns the mapping from mpv property name → spec, allocates
/// reply-id integers for `mpv_observe_property`, and exposes lifecycle
/// methods used by [Player]:
///
/// - [register] / [registerAll]: collect specs at construction time.
/// - [observeAll]: call `mpv_observe_property` once per spec on a live mpv
///   handle.
/// - [dispatch]: route an incoming property-change event (parsed earlier on
///   the event-isolate) to the matching spec, returning the post-reduce
///   [PlayerState] or `null` if the property is not in the registry / the
///   value was deduplicated.
/// - [closeAll]: tear down the underlying [ReactiveProperty] broadcast
///   controllers when the player is disposed.
class PropertyRegistry {
  PropertyRegistry();

  final Map<String, MpvPropertySpec> _byName = {};

  /// Registers a single spec. Subsequent calls with the same [MpvPropertySpec.name]
  /// overwrite — useful for tests and for player subclasses that want to
  /// shadow a default spec.
  void register(MpvPropertySpec spec) {
    _byName[spec.name] = spec;
  }

  /// Registers a batch of specs.
  void registerAll(Iterable<MpvPropertySpec> specs) {
    for (final spec in specs) {
      _byName[spec.name] = spec;
    }
  }

  /// All registered specs.
  Iterable<MpvPropertySpec> get specs => _byName.values;

  /// Looks up a spec by mpv property name. Returns `null` for unknown names.
  MpvPropertySpec? specFor(String name) => _byName[name];

  /// Calls `mpv_observe_property` for every registered spec.
  ///
  /// Reply IDs are auto-assigned starting at 1, in the same order as
  /// [register] calls. The event isolate doesn't decode reply IDs; mpv
  /// dispatches property changes by name on the receive side, so reply IDs
  /// are effectively only for diagnostics in `mpv -v` logs.
  void observeAll(MpvLibrary lib, Pointer<MpvHandle> handle) {
    var replyId = 1;
    for (final spec in _byName.values) {
      using((arena) {
        lib.mpvObserveProperty(
          handle,
          replyId,
          spec.name.toNativeUtf8(allocator: arena),
          spec.format,
        );
      });
      replyId++;
    }
  }

  /// Routes a property-change event to its registered spec.
  ///
  /// Returns the new [PlayerState] when a spec was matched and the value
  /// actually changed, or `null` when:
  /// - no spec is registered for [name] (the caller may handle it via custom
  ///   logic — see complex properties in `Player`); or
  /// - the spec deduplicated the value (the [ReactiveProperty]'s previous
  ///   value was equal).
  PlayerState? dispatch(String name, dynamic raw, PlayerState state) {
    final spec = _byName[name];
    if (spec == null) return null;
    return spec.parseAndDispatch(raw, state);
  }

  /// Closes every registered [ReactiveProperty]'s underlying broadcast
  /// controller. Idempotent — safe to call repeatedly during teardown.
  Future<void> closeAll() async {
    final futures = <Future<void>>[];
    for (final spec in _byName.values) {
      futures.add(spec.reactive.close());
    }
    await Future.wait(futures);
  }
}
