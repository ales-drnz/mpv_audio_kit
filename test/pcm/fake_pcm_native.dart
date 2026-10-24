// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:mpv_audio_kit/src/pcm/pcm_native.dart';

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
  bool readerOpen = false;
  bool freed = false;
  final List<int> read = [];
}

/// The `mak_pcm_*` API in memory, with a reader the test drives.
final class FakePcmNative implements PcmNative {
  final Map<int, FakeSource> sources = {};
  // Far from the ids of the real libmpv, which shares one id space per
  // process: a fake id never names a real source.
  static const int firstId = 1 << 40;
  int _next = firstId - 1;
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
    if (s == null || s.freed) return PcmNative.errUnknown;
    if (s.released || s.state >= PcmNative.stateFinished) {
      return PcmNative.errClosed;
    }
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

  int aborts = 0;

  @override
  int abort(int id) {
    final s = sources[id];
    if (s == null || s.freed) return PcmNative.errUnknown;
    aborts++;
    // A no-op once the reader drained or closed it.
    if (s.state == PcmNative.stateDrained ||
        s.state == PcmNative.stateReaderClosed) {
      return 0;
    }
    s.fifo.clear();
    s.state = PcmNative.stateAborted;
    return 0;
  }

  @override
  int buffered(int id) {
    final s = sources[id];
    return s == null || s.freed ? PcmNative.errUnknown : s.fifo.length;
  }

  @override
  int consumed(int id) {
    final s = sources[id];
    return s == null || s.freed ? PcmNative.errUnknown : s.consumed;
  }

  @override
  int state(int id) {
    final s = sources[id];
    if (s == null || s.freed) return PcmNative.errUnknown;
    return s.state;
  }

  @override
  int release(int id) {
    final s = sources[id];
    if (s == null || s.freed) return PcmNative.errUnknown;
    if (s.released) return PcmNative.errClosed;
    s.released = true;
    if (s.state < PcmNative.stateFinished) s.state = PcmNative.stateAborted;
    // Freed at once unless a reader still holds it.
    if (!s.opened || !s.readerOpen) s.freed = true;
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
    final s = this[id]
      ..opened = true
      ..readerOpen = true;
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
    final s = this[id]..readerOpen = false;
    if (s.state != PcmNative.stateDrained &&
        s.state != PcmNative.stateAborted) {
      s.state = PcmNative.stateReaderClosed;
    }
    if (s.released) s.freed = true;
  }

  void _maybeDrained(FakeSource s) {
    if (s.opened && s.state == PcmNative.stateFinished && s.fifo.isEmpty) {
      s.state = PcmNative.stateDrained;
    }
  }
}
