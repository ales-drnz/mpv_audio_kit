// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// Regression test for overlapping `setMediaSession` calls.
//
// Calls that are not awaited overlap: two enables in one turn (the session
// enabled at app init while the first track pushes its config), a `null`
// followed by a new session, or a dispose followed by a new Player. Each
// must end with the native session in the state Dart believes: on, with
// one live controller, and with the OS commands still reaching the
// player. A controller torn down late used to send its `disable` after
// the winner's `enable`, and its cancel took the command channel handler
// with it, so the lock screen entry vanished while the commands went
// nowhere (F17).
//
// The checks read only the final native state, not how the code gets
// there: the last lifecycle call, the last control call of the command
// channel, a command injected from the platform side, and the number of
// pushes per state change.
//
// The native side is mocked at the platform-channel boundary (the same
// channels production uses). A real Player drives the production mixin
// path, so libmpv on the host is required, as in the runtime suites.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

import '../_helpers/setter_test_helpers.dart';

const _methodChannel = MethodChannel('mpv_audio_kit/media_session');
const _commandsName = 'mpv_audio_kit/media_session/commands';
const _commandsControl = MethodChannel(_commandsName);

void main() {
  runtimeSuite(() {
    /// Every call that crossed the two media-session channels, in arrival
    /// order: the method channel by name, the command channel's control
    /// calls as `commands.listen` and `commands.cancel`. Never cleared.
    final ledger = <String>[];

    int countOf(String method, {int from = 0}) =>
        ledger.skip(from).where((m) => m == method).length;

    String lastOf(Set<String> methods) =>
        ledger.lastWhere(methods.contains, orElse: () => 'none');

    late Player player;
    late TestDefaultBinaryMessenger messenger;

    setUpAll(() async {
      messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      // `enable` is delayed slightly (in the MOCK only) to keep the
      // overlap window wide and deterministic.
      messenger.setMockMethodCallHandler(_methodChannel, (call) async {
        ledger.add(call.method);
        if (call.method == 'enable') {
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
        return null;
      });
      messenger.setMockMethodCallHandler(_commandsControl, (call) async {
        ledger.add('commands.${call.method}');
        return null;
      });

      player = await buildPlayer();
    });

    tearDownAll(() async {
      await player.dispose();
      messenger.setMockMethodCallHandler(_methodChannel, null);
      messenger.setMockMethodCallHandler(_commandsControl, null);
    });

    /// Lets microtasks, the mock's enable delay, and the optimistic-write →
    /// observer round-trip settle before reading the ledger.
    Future<void> settle() =>
        Future<void>.delayed(const Duration(milliseconds: 300));

    /// The native session is on and its command channel is listened to.
    void expectSessionOn(String when) {
      expect(
        lastOf(const {'enable', 'disable'}),
        'enable',
        reason:
            '$when: the last lifecycle call must leave the native '
            'session on (ledger: $ledger)',
      );
      expect(
        lastOf(const {'commands.listen', 'commands.cancel'}),
        'commands.listen',
        reason:
            '$when: the command channel must still be listened to '
            '(ledger: $ledger)',
      );
    }

    /// A command sent from the platform side reaches [player]. `like` is
    /// emit-only, so it changes nothing in the player.
    Future<void> expectCommandDelivered(String when) async {
      final received = player.stream.mediaSessionCommands
          .firstWhere((c) => c is MediaSessionCommandLike)
          .timeout(
            const Duration(seconds: 1),
            onTimeout: () =>
                fail('$when: an OS command never reached the player'),
          );
      await messenger.handlePlatformMessage(
        _commandsName,
        const StandardMethodCodec().encodeSuccessEnvelope({'type': 'like'}),
        (_) {},
      );
      await received;
    }

    /// One player state change produces exactly one native push: more
    /// means a second controller is still subscribed.
    Future<void> expectOnePushPerChange(String when, double rate) async {
      final mark = ledger.length;
      await player.setRate(rate);
      await settle();
      expect(
        countOf('updatePlayback', from: mark),
        1,
        reason:
            '$when: one state change must push one updatePlayback '
            '(calls since: ${ledger.sublist(mark)})',
      );
    }

    test('two enables in one turn leave the session on', () async {
      final first = player.setMediaSession(const MediaSession());
      final second = player.setMediaSession(
        const MediaSession(title: 'First Track'),
      );
      await first;
      await second;
      await settle();

      expectSessionOn('two enables');
      await expectCommandDelivered('two enables');
      await expectOnePushPerChange('two enables', 1.25);
    }, timeout: const Timeout(Duration(seconds: 45)));

    test('null then a session in one turn leaves the session on', () async {
      final off = player.setMediaSession(null);
      final on = player.setMediaSession(const MediaSession(title: 'Again'));
      await off;
      await on;
      await settle();

      expectSessionOn('null then a session');
      await expectCommandDelivered('null then a session');
      await expectOnePushPerChange('null then a session', 1.5);
    }, timeout: const Timeout(Duration(seconds: 45)));

    test('null turns the session off and stops the pushes', () async {
      await player.setMediaSession(null);
      await settle();

      expect(
        lastOf(const {'enable', 'disable'}),
        'disable',
        reason:
            'setMediaSession(null) must end with the session off '
            '(ledger: $ledger)',
      );
      final mark = ledger.length;
      await player.setRate(1.0);
      await settle();
      expect(
        countOf('updatePlayback', from: mark),
        0,
        reason:
            'no controller may push after the session is off '
            '(calls since: ${ledger.sublist(mark)})',
      );
    }, timeout: const Timeout(Duration(seconds: 45)));

    test(
      'a dispose not awaited, then a new Player, leaves the session on',
      () async {
        await player.setMediaSession(const MediaSession());
        await settle();

        final disposing = player.dispose();
        player = Player(
          configuration: const PlayerConfiguration(logLevel: LogLevel.off),
        );
        final enabling = player.setMediaSession(
          const MediaSession(title: 'New Player'),
        );
        await player.setRawProperty('ao', 'null');
        await enabling;
        await disposing;
        await settle();

        expectSessionOn('dispose then a new Player');
        await expectCommandDelivered('dispose then a new Player');
      },
      timeout: const Timeout(Duration(seconds: 45)),
    );
  });
}
