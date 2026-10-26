// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

import '../_helpers/long_wav.dart';
import '../_helpers/range_http_server.dart';
import '../_helpers/setter_test_helpers.dart';

void main() {
  // With the prefetch on, the resolver ran for the prefetch of the
  // next entry and again when the transition loaded it. A resolver whose
  // URL changes on every call (a Subsonic salt, a signed CDN URL with a
  // timestamp) made mpv drop the prefetch as "wrong URL" and open the
  // entry again: no gapless, and the download done twice.
  runtimeSuite(() {
    late RangeHttpServer server;
    late Player player;

    setUp(() async {
      server = await RangeHttpServer.start({
        'a.wav': longWav(2),
        'b.wav': longWav(2),
        'x_q1.wav': longWav(3),
        'x_q2.wav': longWav(4),
      });
      player = await buildPlayer();
    });

    tearDown(() async {
      await player.dispose();
      await server.close();
    });

    test('a prefetched entry calls the resolver once, and the transition '
        'uses the prefetch', () async {
      final calls = <String, int>{};
      var salt = 0;
      await player.setSourceResolver((request) {
        final name = request.media.extras?['name'] as String?;
        if (name == null) return null;
        if (!request.isRetry) {
          calls[request.media.uri] = (calls[request.media.uri] ?? 0) + 1;
        }
        // A fresh URL on every call: the server ignores the query.
        return '${server.url(name)}?s=${++salt}';
      });
      await player.setPrefetchPlaylist(true);
      final used = player.stream.prefetchState
          .firstWhere((s) => s == PrefetchState.used)
          .then((_) => true)
          .timeout(const Duration(seconds: 15), onTimeout: () => false)
          .catchError((Object _) => false);
      final secondLoaded = player.stream.playlist
          .firstWhere((p) => p.index == 1)
          .then((_) => player.stream.seekCompleted.first)
          .timeout(const Duration(seconds: 15));

      await player.openAll(const [
        Media('resolve://a', extras: {'name': 'a.wav'}),
        Media('resolve://b', extras: {'name': 'b.wav'}),
      ], play: true);
      await secondLoaded;

      expect(
        calls['resolve://b'],
        1,
        reason:
            'the transition must reuse the URL the resolver gave for the '
            'prefetch of b, not ask again (requests: ${server.describe()})',
      );
      expect(
        await used,
        isTrue,
        reason:
            'the transition must use the prefetched b '
            '(requests: ${server.describe()})',
      );
      expect(calls['resolve://a'], 1);
    }, timeout: const Timeout(Duration(seconds: 40)));

    test('an open of the prefetched entry asks the resolver again', () async {
      final calls = <String>[];
      await player.setSourceResolver((request) {
        final name = request.media.extras?['name'] as String?;
        if (name == null) return null;
        calls.add(request.media.uri);
        return server.url(name);
      });
      await player.setPrefetchPlaylist(true);
      // Paused: the cache of a still fills, and b is prefetched.
      await player.openAll(const [
        Media('resolve://a', extras: {'name': 'a.wav'}),
        Media('resolve://b', extras: {'name': 'b.wav'}),
      ], play: false);
      await waitUntil(
        () => calls.contains('resolve://b'),
        timeout: const Duration(seconds: 10),
        reason: 'the prefetch of b never ran the resolver',
      );
      // A new open is a new load, not the transition the prefetch served:
      // the URL is asked for again, as it would be without a prefetch.
      final loaded = player.stream.seekCompleted.first.timeout(
        const Duration(seconds: 10),
      );
      await player.open(
        const Media('resolve://b', extras: {'name': 'b.wav'}),
        play: false,
      );
      await loaded;
      expect(
        calls.where((uri) => uri == 'resolve://b'),
        hasLength(2),
        reason: 'the open of b must ask the resolver: $calls',
      );
    }, timeout: const Timeout(Duration(seconds: 40)));

    libmpvReleaseGroup(20, 'The prefetch of libmpv-r20', () {
      // kit-core-3: the URL the resolver gave for the prefetch was kept by
      // URL, so a later entry with the same URL and other extras (another
      // quality of the same track) took it without a call of its own.
      test('a later entry with the URL of the prefetched one asks the '
          'resolver for its own Media', () async {
        final asked = <Object?>[];
        await player.setSourceResolver((request) {
          final q = request.media.extras?['q'];
          asked.add(q);
          return switch (request.uri) {
            'resolve://a' => server.url('a.wav'),
            'resolve://c' => server.url('b.wav'),
            'resolve://x' => server.url('x_q$q.wav'),
            _ => null,
          };
        });
        await player.setPrefetchPlaylist(true);
        // Paused: the cache of a fills, and x with q 1 is prefetched.
        await player.openAll(const [
          Media('resolve://a'),
          Media('resolve://x', extras: {'q': 1}),
          Media('resolve://c'),
          Media('resolve://x', extras: {'q': 2}),
        ], play: false);
        await waitUntil(
          () => asked.contains(1),
          timeout: const Duration(seconds: 10),
          reason: 'the prefetch of x never ran the resolver',
        );
        await Future<void>.delayed(const Duration(milliseconds: 300));
        // The jump keeps the load epoch: only the entry tells the two apart.
        final loaded = player.stream.playlist
            .firstWhere((p) => p.index == 3)
            .then((_) => player.stream.seekCompleted.first)
            .timeout(const Duration(seconds: 10));
        await player.jump(3);
        await loaded;
        expect(
          asked,
          contains(2),
          reason: 'the entry with q 2 must reach the resolver: $asked',
        );
        // x with q 2 lasts 4 s, x with q 1 3 s.
        await waitUntil(
          () => player.state.duration > Duration.zero,
          timeout: const Duration(seconds: 5),
          reason: 'no duration',
        );
        expect(player.state.duration.inMilliseconds, closeTo(4000, 50));
      }, timeout: const Timeout(Duration(seconds: 40)));
    });
  });
}
