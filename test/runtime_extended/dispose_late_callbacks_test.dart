// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

import '../_helpers/setter_test_helpers.dart';

/// Work an app finishes after a dispose (a hook listener, a source
/// resolver) must not surface as an unhandled error.
void main() {
  final fixturePath = defaultFixturePath();

  /// Runs [body] in a zone that collects the errors nobody handled.
  Future<List<Object>> unhandledIn(Future<void> Function() body) async {
    final errors = <Object>[];
    final done = Completer<void>();
    unawaited(
      runZonedGuarded(() async {
        try {
          await body();
        } finally {
          // Let the late continuations run inside the zone.
          await Future<void>.delayed(const Duration(milliseconds: 300));
          done.complete();
        }
      }, (e, _) => errors.add(e)),
    );
    await done.future;
    return errors;
  }

  runtimeSuite(fixturePath: fixturePath, () {
    test('continueHook from a listener after dispose', () async {
      final errors = await unhandledIn(() async {
        final player = await buildPlayer();
        await player.registerHook(Hook.load);
        final hooked = Completer<int>();
        player.stream.hook.listen((e) {
          if (!hooked.isCompleted) hooked.complete(e.id);
        });
        unawaited(player.open(Media(fixturePath), play: false));
        final id = await hooked.future.timeout(const Duration(seconds: 10));
        await player.dispose();
        // The dartdoc example: the listener continues without await.
        unawaited(player.continueHook(id));
      });
      expect(errors, isEmpty);
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('a source resolver that fails after dispose', () async {
      final errors = await unhandledIn(() async {
        final player = await buildPlayer();
        final called = Completer<void>();
        final answer = Completer<String?>();
        await player.setSourceResolver((_) {
          if (!called.isCompleted) called.complete();
          return answer.future;
        });
        unawaited(player.open(Media(fixturePath), play: false));
        await called.future.timeout(const Duration(seconds: 10));
        await player.dispose();
        answer.completeError(StateError('network gone'));
      });
      expect(errors, isEmpty);
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}
