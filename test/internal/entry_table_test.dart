// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/src/internals/entry_table.dart';
import 'package:mpv_audio_kit/src/models/media.dart';

/// The playlist entries the player loaded, by entry id: their Media, and
/// what they hold until mpv can no longer read it. One rule tells that an
/// entry left: a playlist taken after mpv added it does not list it.
void main() {
  late EntryTable table;
  late List<String> closed;
  late List<List<Object?>?> reads;
  late List<Completer<List<Object?>?>> pendingReads;

  Future<void> Function() closer(String uri) =>
      () async => closed.add(uri);

  Future<void> runAll(List<Future<void> Function()> releases) async {
    for (final r in releases) {
      await r();
    }
  }

  /// A playlist report listing [ids], each as `fd://<id>`.
  List<Object?> report(List<int> ids) => [
    for (final id in ids) {'id': id, 'filename': 'fd://$id'},
  ];

  /// Loads entry [id] as `fd://<id>`, with a release when [held].
  EntryRecord add(int? id, {bool held = true, Media? media, LiveSource? live}) {
    final entry = table.pending(
      'fd://$id',
      media ?? Media('fd://$id'),
      held ? closer('fd://$id') : null,
    );
    table.onAdded(entry, id, live: live);
    return entry;
  }

  setUp(() {
    closed = [];
    reads = [];
    pendingReads = [];
    table = EntryTable(
      readPlaylist: () {
        final read = Completer<List<Object?>?>();
        pendingReads.add(read);
        return read.future;
      },
      confirmDelay: const Duration(days: 1),
    );
  });

  group('the rule', () {
    test('an entry a newer report does not list has left', () {
      add(7, held: false);
      add(8, held: false);
      table.onPlaylist(report([7, 8]));
      table.onPlaylist(report([8]));
      expect(table.media.keys, [8]);
      expect(table.mediaOf(7), isNull);
    });

    test('left even when no report listed it: a newer entry was', () {
      add(5, held: false);
      table.onPlaylist(report([6]));
      expect(table.media.keys, isEmpty);
    });

    test('a report older than the entry does not tell', () {
      add(9, held: false);
      table.onPlaylist(report([4]));
      expect(table.media.keys, [9], reason: 'taken before mpv added 9');
      table.onPlaylist(report([10]));
      expect(table.media.keys, isEmpty);
    });

    test('two entries with the same URI keep their own Media', () {
      const a = Media('x://same', extras: {'n': 1});
      const b = Media('x://same', extras: {'n': 2});
      table.onAdded(table.pending('x://same', a, null), 3);
      table.onAdded(table.pending('x://same', b, null), 4);
      expect(table.media[3], same(a));
      expect(table.media[4], same(b));
    });

    test('a reply without an id records nothing to look up', () {
      add(null, held: false);
      expect(table.media, isEmpty);
    });

    test('the last report is kept for a late reply', () {
      final node = report([1]);
      table.onPlaylist(node);
      expect(table.lastNode, same(node));
    });
  });

  group('the entry being loaded', () {
    test('from its START_FILE to its FILE_LOADED', () {
      const media = Media('fd://2');
      add(2, held: false, media: media);
      expect(table.loading, isNull, reason: 'a prefetch has no START_FILE');
      table.onStartFile(2);
      expect(table.loading, 2);
      expect(table.mediaOf(table.loading), same(media));
      table.onFileLoaded();
      expect(table.loading, isNull);
    });

    test('until its END_FILE when it fails', () {
      table.onStartFile(3);
      table.onEndFile();
      expect(table.loading, isNull);
    });
  });

  // An `fd://` descriptor: mpv never closes it, and reads it again on every
  // open of the entry, so it is released once the entry has left the
  // playlist and mpv has moved on from it.
  group('a release', () {
    test('kept while listed, released after the next file settles', () async {
      add(7);
      table.onPlaylist(report([7]));
      table.onStartFile(7);
      await runAll(table.takeSettled());
      expect(closed, isEmpty, reason: 'still in the playlist');

      // Removed: the stream on its way out may still read it.
      table.onPlaylist(report([]));
      await runAll(table.takeSettled());
      expect(closed, isEmpty, reason: 'no file started since it left');
      expect(table.media, isEmpty);

      table.onStartFile(8);
      await runAll(table.takeSettled());
      expect(closed, ['fd://7']);
      await runAll(table.takeAll());
      expect(closed, ['fd://7'], reason: 'released once');
    });

    test('an entry not listed yet is not released', () async {
      add(8);
      table.onPlaylist([
        {'id': 3, 'filename': 'other'},
      ]);
      table.onStartFile(3);
      await runAll(table.takeSettled());
      expect(closed, isEmpty);
    });

    // A load overtaken right after its loadfile: the next one replaced the
    // entry before any report listed it. The ids tell the reports apart.
    test('added, then dropped before any report listed it', () async {
      add(20);
      table.onPlaylist(report([19]));
      table.onStartFile(19);
      await runAll(table.takeSettled());
      expect(closed, isEmpty, reason: 'that report is older than the entry');

      table.onPlaylist(report([21]));
      await runAll(table.takeSettled());
      expect(closed, isEmpty, reason: 'no file started since it left');
      table.onStartFile(21);
      await runAll(table.takeSettled());
      expect(closed, ['fd://20']);
    });

    // Before the reply a report can only name the entry by its URI.
    group('before the loadfile reply', () {
      test('listed by URI, then gone, it waits for a file start', () async {
        table.pending('fd://9', const Media('fd://9'), closer('fd://9'));
        table.onPlaylist(report([9]));
        table.onPlaylist(report([]));
        await runAll(table.takeSettled());
        expect(closed, isEmpty);
        table.onStartFile(10);
        await runAll(table.takeSettled());
        expect(closed, ['fd://9']);
      });

      test('listed again before the release, it stays', () async {
        table.pending('fd://9', const Media('fd://9'), closer('fd://9'));
        table.onPlaylist(report([9]));
        table.onPlaylist(report([]));
        table.onPlaylist(report([9]));
        table.onStartFile(10);
        await runAll(table.takeSettled());
        expect(closed, isEmpty);
      });

      test('the reply keeps what the URI already told', () async {
        final entry = table.pending(
          'fd://11',
          const Media('fd://11'),
          closer('x'),
        );
        table.onPlaylist(report([11]));
        table.onPlaylist(report([]));
        table.onAdded(entry, 11);
        table.onStartFile(12);
        await runAll(table.takeSettled());
        expect(closed, ['x']);
      });
    });

    test('a refused loadfile gives it back to the load call', () async {
      final entry = table.pending(
        'fd://12',
        const Media('fd://12'),
        closer('a'),
      );
      table.drop(entry);
      await runAll(table.takeAll());
      expect(closed, isEmpty);
    });

    test('dispose releases every one, listed or not, replied or not', () async {
      add(11);
      add(12);
      table.pending('fd://13', const Media('fd://13'), closer('fd://13'));
      add(14, held: false);
      table.onPlaylist(report([11]));
      await runAll(table.takeAll());
      expect(closed..sort(), ['fd://11', 'fd://12', 'fd://13']);
      expect(table.media.keys, [14], reason: 'its Media stays');
    });
  });

  // A live PCM source: nothing reads it once its entry left, so it ends
  // then, unless another entry plays it.
  group('a live source', () {
    late List<Object> ended;

    LiveSource live(Object key, [Future<void>? done]) => (
      key: key,
      done: done ?? Completer<void>().future,
      end: () => ended.add(key),
    );

    setUp(() => ended = []);

    test('ends when its entry leaves', () {
      final source = Object();
      add(1, held: false, live: live(source));
      table.onPlaylist(report([1]));
      expect(table.holdsLive(source), isTrue);
      expect(table.liveIds(source), {1});
      table.onPlaylist(report([]));
      expect(ended, [source]);
      expect(table.holdsLive(source), isFalse);
      table.onPlaylist(report([]));
      expect(ended, [source], reason: 'once');
    });

    test('plays on while another entry holds it', () {
      final source = Object();
      add(1, held: false, live: live(source));
      add(2, held: false, live: live(source));
      expect(table.liveIds(source), {1, 2});
      table.onPlaylist(report([2]));
      expect(ended, isEmpty);
      table.onPlaylist(report([]));
      expect(ended, [source]);
    });

    test('a report that cannot tell asks for a read of the playlist', () {
      final source = Object();
      add(5, held: false, live: live(source));
      table.onPlaylist(report([]));
      expect(table.unseenHeld, isTrue);
      expect(pendingReads, hasLength(1));
      expect(ended, isEmpty);
    });

    test('the read ends the sources of the entries it does not list', () async {
      final kept = Object();
      final gone = Object();
      add(5, held: false, live: live(kept));
      add(6, held: false, live: live(gone));
      table.onPlaylist(report([]));
      // Added after the read went out: the read cannot tell.
      final newer = Object();
      add(7, held: false, live: live(newer));
      pendingReads.single.complete(report([5]));
      await pumpEventQueue();
      expect(ended, [gone]);
      expect(table.holdsLive(newer), isTrue);
      expect(
        table.media.keys,
        containsAll([5, 6, 7]),
        reason: 'the Media waits for a report',
      );
    });

    test('a read is made a while after the entry is added', () async {
      table = EntryTable(
        readPlaylist: () async {
          reads.add(null);
          return report([]);
        },
        confirmDelay: Duration.zero,
      );
      final source = Object();
      add(3, held: false, live: live(source));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(reads, hasLength(1));
      expect(ended, [source]);
    });

    test(
      'one read at a time, and one more if a report asked meanwhile',
      () async {
        add(5, held: false, live: live(Object()));
        table.onPlaylist(report([]));
        table.onPlaylist(report([]));
        expect(pendingReads, hasLength(1));
        pendingReads.single.complete(report([5]));
        await pumpEventQueue();
        expect(pendingReads, hasLength(2));
      },
    );

    test('a source that is through lets go of its entries', () async {
      final source = Object();
      final done = Completer<void>();
      add(1, held: false, live: live(source, done.future));
      done.complete();
      await pumpEventQueue();
      expect(table.holdsLive(source), isFalse);
      table.onPlaylist(report([2]));
      expect(ended, isEmpty);
    });

    test('dispose ends every one, once, and asks no more reads', () async {
      final a = Object();
      final b = Object();
      add(1, held: false, live: live(a));
      add(2, held: false, live: live(a));
      add(3, held: false, live: live(b));
      table.onPlaylist(report([]));
      table.onPlaylist(report([]));
      table.endLive();
      expect(ended, [a, b]);
      pendingReads.single.complete(null);
      await pumpEventQueue();
      expect(pendingReads, hasLength(1));
    });
  });

  group('an external track', () {
    test('kept until the file it joined ends', () async {
      table.onEndFile(); // an earlier file, reported before the add
      final settle = table.holdTrack(closer('fd://20'));
      await runAll(table.takeSettled());
      expect(closed, isEmpty, reason: 'mpv has not taken it yet');

      await settle(true);
      table.onStartFile(1);
      await runAll(table.takeSettled());
      expect(closed, isEmpty, reason: 'the file still plays');

      table.onEndFile();
      await runAll(table.takeSettled());
      expect(closed, ['fd://20']);
    });

    test('released at once when the add fails', () async {
      final settle = table.holdTrack(closer('fd://21'));
      await settle(false);
      expect(closed, ['fd://21']);
      await runAll(table.takeAll());
      expect(closed, ['fd://21']);
    });

    test('dispose releases it, added or not', () async {
      table.holdTrack(closer('fd://22'));
      final settle = table.holdTrack(closer('fd://23'));
      await settle(true);
      await runAll(table.takeAll());
      expect(closed..sort(), ['fd://22', 'fd://23']);
      // The add replying after the dispose does not release it again.
      await settle(true);
      expect(closed, hasLength(2));
    });
  });
}
