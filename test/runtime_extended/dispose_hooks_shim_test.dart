// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// dispose() against hooks, checked at the libmpv boundary through the
// slow-core shim: what mpv_terminate_destroy leaves behind (a hook fired
// and never continued, an mpv_hook_add still running or started after it).

@TestOn('mac-os || linux')
@Timeout(Duration(minutes: 2))
library;

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

import '../_helpers/setter_test_helpers.dart';
import '../_helpers/slow_core_shim.dart';

const _sessionChannel = MethodChannel('mpv_audio_kit/media_session');
const _commandsChannel = MethodChannel('mpv_audio_kit/media_session/commands');

void main() {
  final fixturePath = defaultFixturePath();

  slowCoreShimSuite(fixturePath: fixturePath, (shim) {
    setUp(() => shim().reset());

    tearDown(() {
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(_sessionChannel, null);
      messenger.setMockMethodCallHandler(_commandsChannel, null);
      shim().reset();
    });

    test('a hook timeout during the media session release still lets mpv '
        'shut down', () async {
      // The session release outlasts the hook timeout below, so the timer
      // fires while dispose awaits it.
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(_sessionChannel, (call) async {
        if (call.method == 'disable') {
          await Future<void>.delayed(const Duration(milliseconds: 400));
        }
        return null;
      });
      messenger.setMockMethodCallHandler(_commandsChannel, (_) async => null);

      final player = await buildPlayer();
      await player.setMediaSession(const MediaSession());
      await player.registerHook(
        Hook.load,
        timeout: const Duration(milliseconds: 50),
      );
      // Left pending on purpose: only the timeout or dispose continues it.
      final fired = player.stream.hook.first.timeout(
        const Duration(seconds: 10),
      );
      unawaited(
        player.open(Media(fixturePath), play: false).catchError((_) {}),
      );
      await fired;

      await player.dispose().timeout(const Duration(seconds: 20));

      expect(
        shim().counter('destroys'),
        1,
        reason: 'dispose must free the handle, not leak it',
      );
      expect(
        shim().counter('hooks_pending_at_destroy'),
        0,
        reason:
            'a hook timer firing during the session release dropped the '
            'id without continuing it, and mpv waited on it at shutdown',
      );
    });

    test('dispose waits for a source resolver registration that starts '
        'during it', () async {
      // Each mpv_hook_add takes long enough for dispose to start while the
      // resolver's first registration (on_load) runs, before its second
      // (on_load_fail).
      const delay = Duration(milliseconds: 400);
      shim().set('hook_add_delay_us', delay.inMicroseconds);

      final player = await buildPlayer();
      unawaited(
        player.setSourceResolver((r) => null).catchError((Object _) {}),
      );
      await waitUntil(
        () => shim().counter('hook_adds_entered') >= 1,
        reason: 'the resolver never registered its hook',
      );
      await player.dispose().timeout(const Duration(seconds: 20));
      // A registration started after the handle was freed lands now.
      await Future<void>.delayed(delay * 2);

      expect(shim().counter('destroys'), 1);
      expect(
        shim().counter('inflight_at_destroy'),
        0,
        reason: 'mpv_hook_add was still running when the handle was freed',
      );
      expect(
        shim().counter('late_hook_adds'),
        0,
        reason: 'an mpv_hook_add started on a handle already freed',
      );
    });
  });
}
