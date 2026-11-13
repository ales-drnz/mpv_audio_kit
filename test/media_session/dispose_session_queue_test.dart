// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// The dispose of a player while the native side does not answer the
// media session of another one. The native side is mocked at the
// platform-channel boundary.

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

import '../_helpers/libmpv_resolver.dart';
import '../_helpers/setter_test_helpers.dart';

const _methodChannel = MethodChannel('mpv_audio_kit/media_session');
const _commandsName = 'mpv_audio_kit/media_session/commands';
const _commandsControl = MethodChannel(_commandsName);

void main() {
  late TestDefaultBinaryMessenger messenger;

  /// Answers every call of the two channels, `enable` once [enable] does.
  void mockChannels({Future<void>? enable}) {
    messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(_methodChannel, (call) async {
      if (call.method == 'enable' && enable != null) await enable;
      return null;
    });
    messenger.setMockMethodCallHandler(_commandsControl, (_) async => null);
  }

  tearDown(() {
    messenger.setMockMethodCallHandler(_methodChannel, null);
    messenger.setMockMethodCallHandler(_commandsControl, null);
  });

  // The media-session work of every player runs in one queue. A native
  // side that did not answer the enable of one player held the dispose of
  // every other, which never reached its core.
  test('dispose does not wait for the session of another player, nor '
      'without bound for its own', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final lib = resolveLibmpv();
    if (lib == null) {
      skipMissing('libmpv not bundled for this host');
      return;
    }
    MpvAudioKit.ensureInitialized(libmpv: lib, hotRestartCleanup: false);
    final enable = Completer<void>();
    mockChannels(enable: enable.future);

    final owner = await buildPlayer();
    final other = await buildPlayer();
    final published = owner.setMediaSession(const MediaSession());
    // The enable is on its way, and stays there.
    await Future<void>.delayed(const Duration(milliseconds: 100));

    await other.dispose().timeout(
      const Duration(seconds: 5),
      onTimeout: () => fail('dispose waited for the other player\'s session'),
    );

    // The owner's own dispose waits for its turn, up to a bound.
    final warned = owner.stream.internalLog.firstWhere(
      (e) => e.text.contains('did not release'),
    );
    final sw = Stopwatch()..start();
    await owner.dispose().timeout(
      const Duration(seconds: 15),
      onTimeout: () => fail('dispose waited for the native side for good'),
    );
    expect(sw.elapsed, greaterThan(const Duration(seconds: 4)));
    await warned.timeout(const Duration(seconds: 1));

    // The native side answers at last: the late controller is torn down
    // in its turn, without an error.
    enable.complete();
    await published.then<void>((_) {}, onError: (Object _) {});
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }, timeout: const Timeout(Duration(seconds: 60)));
}
