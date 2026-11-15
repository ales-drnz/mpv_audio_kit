// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'dart:typed_data';

import 'package:mpv_audio_kit/src/pcm/pcm_native.dart';
import 'package:mpv_audio_kit/src/pcm/pcm_native_io.dart';
import 'package:test/test.dart';

import '../_helpers/libmpv_resolver.dart';

// The live PCM input of a libmpv opened by its path (`libmpv:` of
// ensureInitialized, and webOS always): its write copies each chunk
// through one native block, in several calls when the chunk is longer.
// Against the bundled libmpv, with no player: the counts of the C side.

void main() {
  final path = resolveLibmpv();

  group('PCM write of a libmpv opened by path', () {
    late PcmNative native;
    final ids = <int>[];

    setUpAll(() => native = openNativePcm(path));

    tearDown(() {
      for (final id in ids) {
        native
          ..abort(id)
          ..release(id);
      }
      ids.clear();
    });

    int create(int capacity) {
      final id = native.create(capacity);
      expect(id, greaterThan(0));
      ids.add(id);
      return id;
    }

    test('a chunk of several blocks is taken whole', () {
      final id = create(1 << 20);
      // 200 kB: three blocks of 64 KiB and a part of a fourth.
      expect(native.write(id, Uint8List(200000)), 200000);
      expect(native.buffered(id), 200000);
      // One block exactly, then less than one.
      expect(native.write(id, Uint8List(65536)), 65536);
      expect(native.write(id, Uint8List(10)), 10);
      expect(native.buffered(id), 265546);
      expect(native.write(id, Uint8List(0)), 0);
    });

    test('a chunk past the free space is taken up to it', () {
      final id = create(100000);
      expect(native.write(id, Uint8List(250000)), 100000);
      expect(native.buffered(id), 100000);
      expect(native.write(id, Uint8List(4)), 0);
    });

    test('two sources share the block', () {
      final a = create(1 << 20);
      final b = create(1 << 20);
      expect(native.write(a, Uint8List(70000)), 70000);
      expect(native.write(b, Uint8List(130000)), 130000);
      expect(native.write(a, Uint8List(1000)), 1000);
      expect(native.buffered(a), 71000);
      expect(native.buffered(b), 130000);
    });

    test('a write to a source that ended returns its error', () {
      final id = create(1 << 20);
      expect(native.write(id, Uint8List(1000)), 1000);
      native.abort(id);
      expect(native.write(id, Uint8List(200000)), PcmNative.errClosed);
      expect(native.write(0x7fffffff, Uint8List(8)), PcmNative.errUnknown);
    });
  }, skip: path == null ? 'no bundled libmpv to open by path' : null);
}
