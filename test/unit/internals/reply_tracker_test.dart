// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:mpv_audio_kit/src/internals/reply_tracker.dart';
import 'package:test/test.dart';

void main() {
  group('ReplyTracker', () {
    test('pairs each reply with its request', () async {
      final t = ReplyTracker(drained: (0, null));
      final (a, replyA) = t.open();
      final (b, replyB) = t.open();
      expect(a, isNot(b));
      t.complete(b, -12, 'b');
      t.complete(a, 0, 'a');
      expect(await replyA, (0, 'a'));
      expect(await replyB, (-12, 'b'));
      expect(t.hasPending, isFalse);
    });

    test('ignores unknown and repeated replies', () async {
      final t = ReplyTracker(drained: (0, null));
      final (id, reply) = t.open();
      t.complete(id + 100, 0);
      t.complete(id, 1);
      t.complete(id, 2);
      expect(await reply, (1, null));
    });

    test('reject resolves at once with the rc', () async {
      final t = ReplyTracker(drained: (0, null));
      final (id, reply) = t.open();
      t.reject(id, -1);
      expect(await reply, (-1, null));
    });

    test('settle waits for the requests pending now, not later ones', () async {
      final t = ReplyTracker(drained: (0, null));
      final (first, _) = t.open();
      var settled = false;
      final settle = t.settle().then((_) => settled = true);
      final (later, _) = t.open();
      await pumpEventQueue();
      expect(settled, isFalse);
      t.complete(first, 0);
      await settle;
      expect(settled, isTrue);
      expect(t.hasPending, isTrue, reason: 'the later request is still open');
      t.complete(later, 0);
    });

    test(
      'drain resolves every pending request with the drained value',
      () async {
        final t = ReplyTracker(drained: (-20, null));
        final (_, a) = t.open();
        final (_, b) = t.open();
        t.drain();
        expect(await a, (-20, null));
        expect(await b, (-20, null));
        expect(t.hasPending, isFalse);
      },
    );
  });
}
