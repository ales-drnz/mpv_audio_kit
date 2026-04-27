// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/src/reactive/reactive_property.dart';

void main() {
  group('ReactiveProperty<int>', () {
    test('seeds the current value and never emits it on subscribe', () async {
      final prop = ReactiveProperty<int>(42);
      expect(prop.value, 42);

      final received = <int>[];
      prop.stream.listen(received.add);
      // Microtask flush to surface anything that might have synchronously
      // landed in the broadcast controller; nothing should have.
      await Future<void>.delayed(Duration.zero);
      expect(received, isEmpty,
          reason: 'broadcast streams must not replay the seed value');
    });

    test('update emits and mutates value when value changes', () async {
      final prop = ReactiveProperty<int>(0);
      final received = <int>[];
      prop.stream.listen(received.add);

      expect(prop.update(1), isTrue);
      expect(prop.update(2), isTrue);

      await Future<void>.delayed(Duration.zero);
      expect(received, [1, 2]);
      expect(prop.value, 2);
    });

    test('update deduplicates equal values without emitting', () async {
      final prop = ReactiveProperty<int>(0);
      final received = <int>[];
      prop.stream.listen(received.add);

      expect(prop.update(1), isTrue);
      expect(prop.update(1), isFalse,
          reason: 'second write of equal value must dedup');
      expect(prop.update(1), isFalse);
      expect(prop.update(2), isTrue);

      await Future<void>.delayed(Duration.zero);
      expect(received, [1, 2]);
    });

    test('emitCurrent broadcasts without changing value', () async {
      final prop = ReactiveProperty<int>(7);
      final received = <int>[];
      prop.stream.listen(received.add);

      prop.emitCurrent();
      prop.emitCurrent();

      await Future<void>.delayed(Duration.zero);
      expect(received, [7, 7]);
      expect(prop.value, 7);
    });

    test('close is idempotent and isClosed flips', () async {
      final prop = ReactiveProperty<int>(0);
      expect(prop.isClosed, isFalse);
      await prop.close();
      expect(prop.isClosed, isTrue);
      // Second close must not throw.
      await prop.close();
      expect(prop.isClosed, isTrue);
    });

    test('update on a closed property is a no-op and returns false', () async {
      final prop = ReactiveProperty<int>(0);
      await prop.close();
      expect(prop.update(99), isFalse);
      expect(prop.value, 0,
          reason: 'closed property must not mutate its cached value');
    });

    test('multi-listener: each listener sees every change', () async {
      final prop = ReactiveProperty<int>(0);
      final a = <int>[];
      final b = <int>[];
      prop.stream.listen(a.add);
      prop.stream.listen(b.add);

      prop.update(1);
      prop.update(2);
      prop.update(2); // deduped
      prop.update(3);

      await Future<void>.delayed(Duration.zero);
      expect(a, [1, 2, 3]);
      expect(b, [1, 2, 3]);
    });
  });

  group('ReactiveProperty<bool> with custom equality', () {
    test('uses == for dedup, not identity', () async {
      // Booleans are canonical; this group also covers the structural
      // equality contract for future T types whose `==` is not identity.
      final prop = ReactiveProperty<bool>(false);
      final received = <bool>[];
      prop.stream.listen(received.add);

      prop.update(false); // dedup vs seed
      prop.update(true);
      prop.update(true); // dedup
      prop.update(false);

      await Future<void>.delayed(Duration.zero);
      expect(received, [true, false]);
    });
  });

  group('ReactiveProperty<Duration>', () {
    test('Duration uses structural equality', () async {
      final prop = ReactiveProperty<Duration>(Duration.zero);
      final received = <Duration>[];
      prop.stream.listen(received.add);

      prop.update(const Duration(seconds: 1));
      prop.update(Duration(milliseconds: 1000)); // == const Duration(seconds:1)

      await Future<void>.delayed(Duration.zero);
      expect(received, [const Duration(seconds: 1)]);
    });
  });
}
