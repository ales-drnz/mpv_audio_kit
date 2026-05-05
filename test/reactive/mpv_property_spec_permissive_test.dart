// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

import 'package:test/test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:mpv_audio_kit/src/reactive/mpv_property_spec.dart';
import 'package:mpv_audio_kit/src/reactive/reactive_property.dart';

void main() {
  // Regression for the rigid-cast bug in 0.0.x: int64 / double specs
  // unwrapped the raw payload via `raw as int` / `raw as double`, which
  // crashed the dispatch pipeline whenever the event isolate forwarded
  // a numeric property in the "other" format (e.g. a property observed
  // as INT64 but delivered as a double — possible at the FFI boundary
  // when mpv promotes a value crossing 2^53). The fix is `(raw as num)
  // .toInt()` / `.toDouble()`.
  group('MpvPropertySpec.int64 accepts int and double payloads', () {
    final reactive = ReactiveProperty<int>(0);
    final spec = MpvPropertySpec<int>.int64(
      name: 'demuxer-max-bytes',
      reactive: reactive,
      parse: (raw, _) => raw,
      reduce: (v, s) => s,
    );

    test('int payload', () {
      final out = spec.parseAndDispatch(123, const PlayerState());
      expect(out, isNotNull);
      expect(reactive.value, 123);
    });

    test('double payload (e.g. promoted across 2^53)', () {
      final out = spec.parseAndDispatch(456.0, const PlayerState());
      expect(out, isNotNull);
      expect(reactive.value, 456);
    });
  });

  group('MpvPropertySpec.float accepts double and int payloads', () {
    final reactive = ReactiveProperty<double>(0.0);
    final spec = MpvPropertySpec<double>.double(
      name: 'time-pos',
      reactive: reactive,
      parse: (raw, _) => raw,
      reduce: (v, s) => s,
    );

    test('double payload', () {
      final out = spec.parseAndDispatch(1.5, const PlayerState());
      expect(out, isNotNull);
      expect(reactive.value, 1.5);
    });

    test('int payload', () {
      final out = spec.parseAndDispatch(2, const PlayerState());
      expect(out, isNotNull);
      expect(reactive.value, 2.0);
    });
  });
}
