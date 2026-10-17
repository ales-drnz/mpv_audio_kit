// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import 'dsp_async_io.dart';

/// Orders the writes of one mpv property whose native state is a static of
/// the libmpv process, shared by every player (`analyzer-taps`,
/// `waveform-enabled`, `loudness-scan-enabled`).
///
/// Each player writes through its own core. mpv runs the writes of one core
/// in order, but two cores run theirs side by side: a write through one
/// core can land before an earlier one through another, and the process
/// keeps the stale value. So the writes in flight all go through one core
/// at a time. A write of a value joins the core already writing. A write
/// that has to go through its own core (it acts on that core's file) waits
/// until the other core is done, and is then asked for its value again.
///
/// One per isolate: the players of another isolate do not see it.
@internal
final class SharedPropertyWriter {
  SharedPropertyWriter(this.name);

  /// The mpv property written.
  final String name;

  // The core with writes in flight, by its player's write function, and
  // how many.
  AsyncPropertySet? _busy;
  int _inFlight = 0;
  // The writes that wait for [_busy], one per core, in arrival order.
  final Map<AsyncPropertySet, String? Function()> _waiting = {};

  /// Writes the value [value] returns, unless it returns `null`, through
  /// [through]. With [anyCore], the value goes through the core already
  /// writing, when there is one. Otherwise a write through another core
  /// waits for it to finish, and [value] is called only then.
  void write(
    AsyncPropertySet through,
    String? Function() value, {
    bool anyCore = false,
  }) {
    var via = through;
    final busy = _busy;
    if (busy != null && busy != via) {
      if (!anyCore) {
        _waiting[via] = value;
        return;
      }
      via = busy;
    }
    final next = value();
    if (next == null) return;
    _busy = via;
    _inFlight++;
    unawaited(
      via(
        name,
        next,
      ).then<void>((_) {}, onError: (Object _) {}).whenComplete(_settle),
    );
  }

  void _settle() {
    if (--_inFlight > 0) return;
    _busy = null;
    final waiting = Map.of(_waiting);
    _waiting.clear();
    waiting.forEach(write);
  }
}
