// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:mpv_audio_kit/src/reactive/default_reactives.dart';
import 'package:mpv_audio_kit/src/reactive/node_parsers.dart';
import 'package:mpv_audio_kit/src/reactive/reactive_property.dart';
import 'package:test/test.dart';

void main() {
  group('ReactiveProperty<int>', () {
    test('stream replays the current value on subscribe', () async {
      final prop = ReactiveProperty<int>(42);
      expect(prop.value, 42);

      final received = <int>[];
      prop.stream.listen(received.add);
      await pumpEventQueue();
      expect(received, [42]);

      prop.update(43);
      final late = <int>[];
      prop.stream.listen(late.add);
      await pumpEventQueue();
      expect(received, [42, 43]);
      expect(late, [43], reason: 'a late subscriber starts from the latest');
    });

    test('changes does not replay the current value', () async {
      final prop = ReactiveProperty<int>(42);
      final received = <int>[];
      prop.changes.listen(received.add);
      await pumpEventQueue();
      expect(received, isEmpty);
    });

    test(
      'stream of a closed property replays the value, then closes',
      () async {
        final prop = ReactiveProperty<int>(5);
        await prop.close();
        expect(await prop.stream.toList(), [5]);
      },
    );

    test('update emits and mutates value when value changes', () async {
      final prop = ReactiveProperty<int>(0);
      final received = <int>[];
      prop.changes.listen(received.add);

      expect(prop.update(1), isTrue);
      expect(prop.update(2), isTrue);

      await pumpEventQueue();
      expect(received, [1, 2]);
      expect(prop.value, 2);
    });

    test('update deduplicates equal values without emitting', () async {
      final prop = ReactiveProperty<int>(0);
      final received = <int>[];
      prop.changes.listen(received.add);

      expect(prop.update(1), isTrue);
      expect(
        prop.update(1),
        isFalse,
        reason: 'second write of equal value must dedup',
      );
      expect(prop.update(1), isFalse);
      expect(prop.update(2), isTrue);

      await pumpEventQueue();
      expect(received, [1, 2]);
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
      expect(
        prop.value,
        0,
        reason: 'closed property must not mutate its cached value',
      );
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

      await pumpEventQueue();
      expect(a, [0, 1, 2, 3]);
      expect(b, [0, 1, 2, 3]);
    });
  });

  group('ReactiveProperty<bool> with custom equality', () {
    test('uses == for dedup, not identity', () async {
      // Booleans are canonical; this group also covers the structural
      // equality contract for future T types whose `==` is not identity.
      final prop = ReactiveProperty<bool>(false);
      final received = <bool>[];
      prop.changes.listen(received.add);

      prop.update(false); // dedup vs seed
      prop.update(true);
      prop.update(true); // dedup
      prop.update(false);

      await pumpEventQueue();
      expect(received, [true, false]);
    });
  });

  group('ReactiveProperty<Duration>', () {
    test('Duration uses structural equality', () async {
      final prop = ReactiveProperty<Duration>(Duration.zero);
      final received = <Duration>[];
      prop.changes.listen(received.add);

      prop.update(const Duration(seconds: 1));
      prop.update(
        const Duration(milliseconds: 1000),
      ); // == const Duration(seconds:1)

      await pumpEventQueue();
      expect(received, [const Duration(seconds: 1)]);
    });
  });

  group('aggregateStream', () {
    test(
      'a subscriber joining while a change is queued gets it once',
      () async {
        final a = ReactiveProperty<int>(0);
        final b = ReactiveProperty<int>(0);
        final sum = aggregateStream(() => a.value + b.value, [
          a.changes,
          b.changes,
        ]);

        final early = <int>[];
        sum.listen(early.add);
        await pumpEventQueue();

        a.update(1); // queued for the sources, the value is already 1
        final late = <int>[];
        sum.listen(late.add);
        await pumpEventQueue();

        expect(early, [0, 1]);
        expect(late, [1]);
      },
    );

    test('changes that keep the aggregate emit nothing', () async {
      final a = ReactiveProperty<int>(1);
      final b = ReactiveProperty<int>(1);
      final sum = aggregateStream(() => a.value + b.value, [
        a.changes,
        b.changes,
      ]);
      final got = <int>[];
      sum.listen(got.add);
      a.update(2);
      b.update(0);
      await pumpEventQueue();
      expect(got, [2]);
    });

    test('is done when the sources close', () async {
      final a = ReactiveProperty<int>(0);
      final done = aggregateStream(() => a.value, [a.changes]).drain<void>();
      await a.close();
      await expectLater(done, completes);
    });
  });

  group('collection cells compare by content', () {
    // mpv sends a fresh list on every node event, and the player reads
    // chapter-list again on each load: a list equal to the current one
    // must not reach the streams again.
    final r = DefaultPropertyReactives();
    const twoTracks = [
      {'id': 1, 'type': 'audio', 'codec': 'flac'},
      {'id': 2, 'type': 'audio', 'codec': 'opus'},
    ];
    const twoChapters = [
      {'time': 0.0, 'title': 'A'},
      {'time': 1.5, 'title': 'B'},
    ];

    test('tracks', () {
      expect(r.tracks.update(parseTrackListNode(twoTracks)), isTrue);
      expect(r.tracks.update(parseTrackListNode(twoTracks)), isFalse);
      expect(r.tracks.update(parseTrackListNode(twoTracks.sublist(1))), isTrue);
    });

    test('chapters', () {
      expect(r.chapters.update(parseChapterListNode(twoChapters)), isTrue);
      expect(r.chapters.update(parseChapterListNode(twoChapters)), isFalse);
      expect(r.chapters.update(const []), isTrue);
    });

    test('chapterMetadata', () {
      expect(r.chapterMetadata.update({'title': 'A'}), isTrue);
      expect(r.chapterMetadata.update({'title': 'A'}), isFalse);
      expect(r.chapterMetadata.update({'title': 'B'}), isTrue);
    });

    test('audioSpdif', () {
      expect(r.audioSpdif.update({Spdif.ac3, Spdif.dts}), isTrue);
      expect(r.audioSpdif.update({Spdif.dts, Spdif.ac3}), isFalse);
      expect(r.audioSpdif.update({Spdif.ac3}), isTrue);
    });
  });
}
