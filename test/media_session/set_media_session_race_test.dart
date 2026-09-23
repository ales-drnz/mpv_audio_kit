// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// Regression test for the `setMediaSession` enable/enable race.
//
// Two overlapping non-null `setMediaSession(session)` calls fired in the
// same synchronous turn both evaluate `_mediaSessionController == null`
// BEFORE either suspends in `await MediaSessionController.create(...)`
// (`create` suspends at the channel `enable` invokeMethod). Both therefore
// allocate a controller; the post-await re-check only tests ownership and
// `state.mediaSession != null` — both still true for both calls — so the
// second assignment overwrites the first. The overwritten controller is
// stranded with its ~13 live stream subscriptions and keeps pushing every
// player state change to the native side (duplicate `updatePlayback` /
// `updateMetadata` traffic) with no path to disposal until process exit.
//
// Realistic trigger: enabling the session at app init while concurrently
// pushing the first track's metadata config (`setMediaSession` twice,
// un-awaited, in one turn).
//
// The race is purely Dart-side ordering; the native side is mocked at the
// platform-channel boundary (the same `mpv_audio_kit/media_session` method
// channel production uses), recording every invocation so the duplicate
// pushes are directly observable. A real Player drives the production
// mixin path (`_MediaSessionModule.setMediaSession`), so libmpv on the
// host is required — same skip rule as the runtime suites. One Player per
// file, per repo convention.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

import '../_helpers/setter_test_helpers.dart';

void main() {
  if (!initLibmpvOrSkip()) return;

  /// Every invocation that crossed the media-session method channel, in
  /// arrival order. Never cleared — phases assert on slices.
  final nativeCalls = <String>[];

  int countOf(String method, {int from = 0}) =>
      nativeCalls.skip(from).where((m) => m == method).length;

  late Player player;

  setUpAll(() async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    // The production method channel. Recording handler; `enable` is
    // delayed slightly (in the MOCK only) to keep the create() overlap
    // window wide and deterministic.
    messenger.setMockMethodCallHandler(
      const MethodChannel('mpv_audio_kit/media_session'),
      (call) async {
        nativeCalls.add(call.method);
        if (call.method == 'enable') {
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
        return null;
      },
    );
    // The command EventChannel's underlying method channel — ACK the
    // `listen`/`cancel` control messages so the controller's command
    // subscription doesn't surface a MissingPluginException.
    messenger.setMockMethodCallHandler(
      const MethodChannel('mpv_audio_kit/media_session/commands'),
      (call) async => null,
    );

    player = await buildPlayer();
  });

  tearDownAll(() async {
    await player.dispose();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('mpv_audio_kit/media_session'),
      null,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('mpv_audio_kit/media_session/commands'),
      null,
    );
  });

  /// Lets microtasks, the mock's enable delay, and the optimistic-write →
  /// observer round-trip settle before counting channel traffic.
  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 300));

  test(
    'two overlapping setMediaSession calls leave exactly ONE live '
    'controller (no duplicate native pushes, balanced enable/disable)',
    () async {
      // ── Phase 1: the race. Two un-awaited non-null enables in the same
      // synchronous turn (init-time enable + first-track config push).
      final first = player.setMediaSession(const MediaSession());
      final second = player.setMediaSession(
        const MediaSession(title: 'First Track'),
      );
      await first;
      await second;
      await settle();

      // ── Phase 2: drive ONE playback-state change and count pushes.
      // Every live controller subscribes to `stream.rate` and flushes one
      // coalesced `updatePlayback`. Exactly one controller must be alive,
      // so exactly one push may arrive. A stranded duplicate controller
      // doubles this.
      final mark = nativeCalls.length;
      await player.setRate(1.25);
      await settle();

      expect(
        countOf('updatePlayback', from: mark),
        1,
        reason:
            'one player state change must produce exactly one native '
            'updatePlayback push; more means a stranded duplicate '
            'MediaSessionController is still subscribed and double-pushing '
            '(calls since state change: ${nativeCalls.sublist(mark)})',
      );

      // ── Phase 3: full lifecycle balance. Disabling must tear down every
      // controller that was ever enabled — each native `enable` needs a
      // matching `disable` by the time the session is off. A stranded
      // controller is never disposed, so its enable stays unpaired.
      await player.setMediaSession(null);
      await settle();

      expect(
        countOf('disable'),
        countOf('enable'),
        reason:
            'after setMediaSession(null) every controller ever enabled '
            'must have been disposed (enable/disable balanced); an unpaired '
            'enable is a stranded controller leaking ~13 subscriptions '
            '(full call ledger: $nativeCalls)',
      );
    },
    timeout: const Timeout(Duration(seconds: 45)),
  );
}
