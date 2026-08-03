// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

import '../_helpers/setter_test_helpers.dart';

void main() {
  final fixturePath = defaultFixturePath();

  setUpAll(() => initLibmpvOrSkip(fixturePath: fixturePath));

  group('Source resolver end-to-end', () {
    late Player player;

    setUpAll(() async {
      player = await buildPlayer();
    });

    tearDownAll(() async {
      // Stop + clear before dispose; on_load hooks can leave a demuxer
      // thread mid-flight that delays the dispose chain otherwise.
      await player.setSourceResolver(null);
      await player.stop();
      await player.clearPlaylist();
      await player.dispose();
    });

    Future<void> waitForLoad(Future<void> Function() load,
        {Duration timeout = const Duration(seconds: 10),}) async {
      // Anchor on `seekCompleted` (mpv's PLAYBACK_RESTART, one per
      // successful loadfile) — robust against ReactiveProperty dedup
      // when consecutive tests load the same fixture.
      final loaded = player.stream.seekCompleted.first.timeout(timeout);
      await load();
      await loaded;
    }

    test(
        'resolves a placeholder URL from Media.extras before the stream '
        'opens', () async {
      final requests = <SourceResolveRequest>[];
      await player.setSourceResolver((request) {
        requests.add(request);
        // The issue-#15 shape: branch on consumer-attached extras, hand
        // back the real (possibly temporary) playback URL.
        return request.media.extras?['path'] as String?;
      });

      await waitForLoad(() => player.open(
            Media('resolve://sine', extras: {'path': fixturePath}),
            play: false,
          ),);

      expect(requests, isNotEmpty);
      final first = requests.first;
      expect(first.uri, 'resolve://sine',
          reason: 'the resolver sees the URL mpv was about to open',);
      expect(first.media.extras?['path'], fixturePath,
          reason: 'the original Media rides along, extras intact',);
      expect(first.isRetry, isFalse);
    }, timeout: const Timeout(Duration(seconds: 30)),);

    test('returning null keeps the current URL (no-op default)', () async {
      var calls = 0;
      await player.setSourceResolver((request) {
        calls++;
        return null; // not ours — leave the source alone
      });

      await waitForLoad(() => player.open(Media(fixturePath), play: false));

      expect(calls, greaterThan(0),
          reason: 'the resolver is consulted on every load attempt',);
    }, timeout: const Timeout(Duration(seconds: 30)),);

    test(
        'a failed open re-invokes the resolver with isRetry=true and the '
        'fresh URL is retried', () async {
      // Models a token service: the first minted URL is already expired,
      // a refresh (triggered by the retry pass) mints a working one. The
      // resolver always answers with the service's CURRENT url — the
      // realistic shape, robust to mpv re-running `on_load` for the
      // retried attempt.
      final deadUrl = '$fixturePath.does-not-exist.wav';
      var refreshed = false;
      final retries = <SourceResolveRequest>[];
      await player.setSourceResolver((request) {
        if (request.isRetry) {
          retries.add(request);
          refreshed = true;
        }
        return refreshed ? fixturePath : deadUrl;
      });

      await waitForLoad(() => player.open(
            const Media('resolve://expired'),
            play: false,
          ),);

      expect(retries, hasLength(1));
      expect(retries.single.uri, deadUrl,
          reason: 'the retry sees the URL that just failed',);
      expect(retries.single.media.uri, 'resolve://expired',
          reason: 'the rewritten URL still maps back to the original Media',);
    }, timeout: const Timeout(Duration(seconds: 30)),);

    test(
        'the resolver-driven retry is capped at one per load (no '
        'open-fail-reopen loop)', () async {
      var retryCalls = 0;
      final failed = Completer<void>();
      final sub = player.stream.endFile.listen((event) {
        if (event.reason == MpvEndFileReason.error &&
            !failed.isCompleted) {
          failed.complete();
        }
      });
      await player.setSourceResolver((request) {
        if (request.isRetry) retryCalls++;
        // Always a fresh-but-broken URL — without the cap this would
        // loop forever.
        return '$fixturePath.broken-$retryCalls.wav';
      });

      try {
        await player.open(const Media('resolve://always-broken'), play: false);
        await failed.future.timeout(const Duration(seconds: 10));
        // Give a hypothetical runaway loop a beat to show itself.
        await Future<void>.delayed(const Duration(milliseconds: 300));
        expect(retryCalls, 1,
            reason: 'exactly one resolver-driven retry per load attempt',);
      } finally {
        await sub.cancel();
      }
    }, timeout: const Timeout(Duration(seconds: 30)),);

    test(
        'composes with a consumer-registered Hook.load: resolver runs '
        'first, the hook sees the rewritten URL', () async {
      await player.setSourceResolver(
          (request) => request.media.extras?['path'] as String?,);

      final seenByHook = Completer<String>();
      final sub = player.stream.hook.listen((event) async {
        if (event.hook == Hook.load && !seenByHook.isCompleted) {
          seenByHook.complete(
              await player.getRawProperty('stream-open-filename') ?? '',);
        }
        await player.continueHook(event.id);
      });

      try {
        await player.registerHook(Hook.load);
        await waitForLoad(() => player.open(
              Media('resolve://composed', extras: {'path': fixturePath}),
              play: false,
            ),);
        expect(await seenByHook.future, fixturePath,
            reason: 'the consumer hook observes the already-resolved URL',);
      } finally {
        await sub.cancel();
      }
    }, timeout: const Timeout(Duration(seconds: 30)),);

    test('setSourceResolver(null) uninstalls the callback', () async {
      var calls = 0;
      await player.setSourceResolver((request) {
        calls++;
        return null;
      });
      await player.setSourceResolver(null);

      // The previous test registered Hook.load as a CONSUMER hook, so
      // its events still surface on the stream and the continue
      // obligation is ours for the rest of this player's life.
      final sub = player.stream.hook
          .listen((event) => unawaited(player.continueHook(event.id)));

      try {
        await waitForLoad(() => player.open(Media(fixturePath), play: false));
      } finally {
        await sub.cancel();
      }

      expect(calls, 0);
    }, timeout: const Timeout(Duration(seconds: 30)),);
  });
}
