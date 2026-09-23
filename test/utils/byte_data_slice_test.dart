// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:test/test.dart';

/// Pins the documented `ByteData.buffer.asUint8List(...)` semantics that
/// `lib/src/internals/uri_resolver.dart` relies on.
///
/// The bug shape: `data.buffer.asUint8List()` (no offset / length args)
/// returns a view of the FULL backing buffer regardless of `data`'s
/// own slice — so when Flutter's `rootBundle` packs multiple assets
/// into one buffer, writing without explicit offset / length spills
/// sibling assets into the cached file. The resolver now passes
/// `data.offsetInBytes` and `data.lengthInBytes` explicitly.
void main() {
  group('ByteData / Uint8List slicing', () {
    test('no-arg asUint8List returns the full backing buffer', () {
      final backing = Uint8List(64);
      for (var i = 0; i < backing.length; i++) {
        backing[i] = i;
      }
      // Slice the middle 16 bytes as a ByteData view.
      final view = ByteData.sublistView(backing, 16, 32);
      expect(view.lengthInBytes, 16);
      expect(view.offsetInBytes, 16);

      // No-arg form spans the entire backing buffer — proving the bug
      // shape rather than the fix shape.
      final fullView = view.buffer.asUint8List();
      expect(fullView.length, 64);
      expect(fullView[0], 0);
      expect(fullView[63], 63);
    });

    test('explicit offset+length asUint8List returns just the view slice', () {
      final backing = Uint8List(64);
      for (var i = 0; i < backing.length; i++) {
        backing[i] = i;
      }
      final view = ByteData.sublistView(backing, 16, 32);

      final slice = view.buffer.asUint8List(
        view.offsetInBytes,
        view.lengthInBytes,
      );
      expect(slice.length, 16);
      expect(slice.first, 16);
      expect(slice.last, 31);
    });

    test('the slice does not include sibling-asset bytes', () {
      // Simulate Flutter's bundled-asset shape: two assets back-to-back
      // in a single buffer.
      final assetA = Uint8List.fromList(List.filled(40, 0xAA));
      final assetB = Uint8List.fromList(List.filled(40, 0xBB));
      final packed = Uint8List(80)
        ..setRange(0, 40, assetA)
        ..setRange(40, 80, assetB);

      // ByteData view of asset B only.
      final viewB = ByteData.sublistView(packed, 40, 80);

      // Buggy: would silently include asset A's bytes.
      final naive = viewB.buffer.asUint8List();
      expect(naive.length, 80);
      expect(
        naive.any((b) => b == 0xAA),
        isTrue,
        reason: 'no-arg asUint8List leaks sibling bytes',
      );

      // Fixed: respects the slice boundaries.
      final correct = viewB.buffer.asUint8List(
        viewB.offsetInBytes,
        viewB.lengthInBytes,
      );
      expect(correct.length, 40);
      expect(correct.every((b) => b == 0xBB), isTrue);
    });
  });
}
