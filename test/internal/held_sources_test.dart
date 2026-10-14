// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/src/internals/held_sources.dart';

/// The `fd://` descriptors of Android `content://` entries: mpv never
/// closes them, so the player releases each one once the entry has left
/// the playlist and mpv has moved on from it.
void main() {
  late HeldSources held;
  late List<String> closed;

  Future<void> Function() closer(String uri) =>
      () async => closed.add(uri);

  Future<void> runAll(List<Future<void> Function()> releases) async {
    for (final r in releases) {
      await r();
    }
  }

  setUp(() {
    held = HeldSources();
    closed = [];
  });

  test('kept while listed, released after the next file settles', () async {
    held.hold('fd://7', closer('fd://7'));
    held.onPlaylist(['fd://7']);
    held.onStartFile();
    await runAll(held.takeSettled());
    expect(closed, isEmpty, reason: 'still in the playlist');

    // Removed: the stream on its way out may still read it.
    held.onPlaylist(const []);
    await runAll(held.takeSettled());
    expect(closed, isEmpty, reason: 'no file started since it left');

    held.onStartFile();
    await runAll(held.takeSettled());
    expect(closed, ['fd://7']);
    expect(held.isEmpty, isTrue);
  });

  test('an entry not listed yet is not released', () async {
    held.hold('fd://8', closer('fd://8'));
    held.onPlaylist(['other']);
    held.onStartFile();
    await runAll(held.takeSettled());
    expect(closed, isEmpty);
  });

  test('listed again before the release, it stays', () async {
    held.hold('fd://9', closer('fd://9'));
    held.onPlaylist(['fd://9']);
    held.onPlaylist(const []);
    held.onPlaylist(['fd://9']);
    held.onStartFile();
    await runAll(held.takeSettled());
    expect(closed, isEmpty);
  });

  test('the abort release runs once and drops the hold', () async {
    final abort = held.hold('fd://10', closer('fd://10'));
    await abort();
    await abort();
    expect(closed, ['fd://10']);
    expect(held.isEmpty, isTrue);
    await runAll(held.takeAll());
    expect(closed, ['fd://10']);
  });

  test('dispose releases every hold, listed or not', () async {
    held.hold('fd://11', closer('fd://11'));
    held.hold('fd://12', closer('fd://12'));
    held.onPlaylist(['fd://11']);
    await runAll(held.takeAll());
    expect(closed..sort(), ['fd://11', 'fd://12']);
    expect(held.isEmpty, isTrue);
  });

  group('external track', () {
    test('kept until the file it joined ends', () async {
      held.onEndFile(); // an earlier file, reported before the add
      final settle = held.holdTrack(closer('fd://20'));
      await runAll(held.takeSettled());
      expect(closed, isEmpty, reason: 'mpv has not taken it yet');

      await settle(true);
      held.onStartFile();
      await runAll(held.takeSettled());
      expect(closed, isEmpty, reason: 'the file still plays');

      held.onEndFile();
      await runAll(held.takeSettled());
      expect(closed, ['fd://20']);
      expect(held.isEmpty, isTrue);
    });

    test('released at once when the add fails', () async {
      final settle = held.holdTrack(closer('fd://21'));
      expect(held.isEmpty, isFalse);
      await settle(false);
      expect(closed, ['fd://21']);
      expect(held.isEmpty, isTrue);
    });

    test('dispose releases it, added or not', () async {
      held.holdTrack(closer('fd://22'));
      final settle = held.holdTrack(closer('fd://23'));
      await settle(true);
      await runAll(held.takeAll());
      expect(closed..sort(), ['fd://22', 'fd://23']);
      // The add replying after the dispose does not release it again.
      await settle(true);
      expect(closed, hasLength(2));
    });
  });
}
