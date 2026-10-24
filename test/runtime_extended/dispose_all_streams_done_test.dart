// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

// Every stream of PlayerStream must emit done when the player is disposed:
// a subscriber awaiting `.first` across a dispose must not hang. The list
// is test/_helpers/player_streams.dart, which a unit test keeps equal to
// the fields of player_stream.dart, plus a pre and a post tap.

@TestOn('mac-os || linux || windows')
library;

import 'dart:async';

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

import '../_helpers/player_streams.dart';
import '../_helpers/setter_test_helpers.dart';

void main() {
  runtimeSuite(() {
    test('dispose() sends done on every stream of PlayerStream', () async {
      final player = await buildPlayer();
      await player.ready;

      final done = <String, Completer<void>>{};
      final subs = <StreamSubscription<Object?>>[];
      void watch(String name, Stream<Object?> stream) {
        final c = done[name] = Completer<void>();
        subs.add(stream.listen((_) {}, onDone: c.complete));
      }

      for (final MapEntry(:key, :value) in playerStreams.entries) {
        watch(key, value(player.stream));
      }
      watch(
        'tap pre',
        player.stream.tap(AudioFilter.equalizer, side: TapSide.pre),
      );
      watch(
        'tap post',
        player.stream.tap(AudioFilter.equalizer, side: TapSide.post),
      );

      // With a file loaded the analysis pipelines the listeners armed
      // have work in flight when the dispose lands.
      await openAndWaitForLoad(player, defaultFixturePath());
      await player.dispose();

      final open = <String>[];
      await Future.wait([
        for (final MapEntry(:key, :value) in done.entries)
          value.future
              .timeout(const Duration(seconds: 2))
              .catchError((Object _) => open.add(key)),
      ]);
      for (final sub in subs) {
        unawaited(sub.cancel());
      }

      expect(done, hasLength(playerStreams.length + 2));
      expect(
        open,
        isEmpty,
        reason:
            'These streams did not emit done within 2 s of dispose(): '
            'a subscriber awaiting `.first` across a dispose hangs.',
      );
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}
