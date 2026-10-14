// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:mpv_audio_kit/src/internals/pcm_native.dart';

/// One source of [FakePcmNative]: a byte FIFO and the native state.
final class FakeSource {
  FakeSource(this.capacity);
  final int capacity;
  final BytesBuilder fifo = BytesBuilder();
  final List<int> writes = [];
  int consumed = 0;
  int state = PcmNative.stateOpen;
  bool released = false;
  bool opened = false;
  final List<int> read = [];
}

/// The `mak_pcm_*` API in memory, with a reader the test drives.
final class FakePcmNative implements PcmNative {
  final Map<int, FakeSource> sources = {};
  int _next = 0;
  int releaseAllCalls = 0;

  FakeSource operator [](int id) => sources[id]!;

  FakeSource get last => sources[_next]!;

  @override
  int create(int capacityBytes) {
    sources[++_next] = FakeSource(capacityBytes);
    return _next;
  }

  @override
  int write(int id, Uint8List data) {
    final s = sources[id];
    if (s == null || s.released) return PcmNative.errUnknown;
    if (s.state >= PcmNative.stateFinished) return PcmNative.errClosed;
    final room = s.capacity - s.fifo.length;
    final n = data.length < room ? data.length : room;
    if (n <= 0) return 0;
    s.fifo.add(Uint8List.sublistView(data, 0, n));
    s.writes.add(n);
    return n;
  }

  @override
  int finish(int id) {
    final s = sources[id];
    if (s == null) return PcmNative.errUnknown;
    if (s.state < PcmNative.stateFinished) s.state = PcmNative.stateFinished;
    _maybeDrained(s);
    return 0;
  }

  @override
  int abort(int id) {
    final s = sources[id];
    if (s == null) return PcmNative.errUnknown;
    s.fifo.clear();
    s.state = PcmNative.stateAborted;
    return 0;
  }

  @override
  int buffered(int id) => sources[id]?.fifo.length ?? PcmNative.errUnknown;

  @override
  int consumed(int id) => sources[id]?.consumed ?? PcmNative.errUnknown;

  @override
  int state(int id) {
    final s = sources[id];
    if (s == null || s.released) return PcmNative.errUnknown;
    return s.state;
  }

  @override
  int release(int id) {
    final s = sources[id];
    if (s == null) return PcmNative.errUnknown;
    s.released = true;
    if (s.state < PcmNative.stateFinished) s.state = PcmNative.stateAborted;
    return 0;
  }

  @override
  void releaseAll() {
    releaseAllCalls++;
    for (final id in sources.keys) {
      abort(id);
      release(id);
    }
  }

  /// The reader opens source [id].
  void open(int id) {
    final s = this[id]..opened = true;
    if (s.state == PcmNative.stateOpen) s.state = PcmNative.stateReading;
  }

  /// The reader takes up to [n] bytes of source [id].
  Uint8List readBytes(int id, int n) {
    final s = this[id];
    final all = s.fifo.takeBytes();
    final take = n < all.length ? n : all.length;
    s.fifo.add(Uint8List.sublistView(all, take));
    s.consumed += take;
    s.read.addAll(all.sublist(0, take));
    _maybeDrained(s);
    return Uint8List.sublistView(all, 0, take);
  }

  /// The reader closes source [id] before the end.
  void closeReader(int id) {
    final s = this[id];
    if (s.state != PcmNative.stateDrained) {
      s.state = PcmNative.stateReaderClosed;
    }
  }

  void _maybeDrained(FakeSource s) {
    if (s.opened && s.state == PcmNative.stateFinished && s.fifo.isEmpty) {
      s.state = PcmNative.stateDrained;
    }
  }
}
