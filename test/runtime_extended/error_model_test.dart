// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

import '../_helpers/setter_test_helpers.dart';

/// The error contract: invalid arguments throw [ArgumentError] or
/// [RangeError] before reaching libmpv, a rejection throws
/// [MpvCommandException], a source that can't be prepared throws
/// [SourceException], and navigating past either end returns `false`.
void main() {
  final fx = defaultFixturePath();

  runtimeSuite(fixturePath: fx, () {
    group('Error model', () {
      late Player player;

      setUp(() async {
        player = await buildPlayer();
      });

      tearDown(() => player.dispose());

      test('next and previous report whether they moved', () async {
        await player.openAll([Media(fx), Media(fx)], play: false);
        await waitUntil(() => player.state.playlist.index == 0);

        expect(await player.previous(), isFalse);
        expect(await player.next(), isTrue);
        await waitUntil(() => player.state.playlist.index == 1);
        expect(await player.next(), isFalse);
        expect(await player.nextPlaylist(), isFalse);
      }, timeout: const Timeout(Duration(seconds: 15)));

      test('next on an empty player returns false', () async {
        expect(await player.next(), isFalse);
        expect(await player.previous(), isFalse);
      });

      test('playlist indices are checked against mpv', () async {
        await openAndWaitForLoad(player, fx);
        // An add still in flight counts: the check reads mpv, not state.
        final added = player.add(Media(fx));
        await added;
        await player.jump(1);

        await expectLater(player.jump(2), throwsRangeError);
        await expectLater(player.remove(-1), throwsRangeError);
        await expectLater(player.remove(2), throwsRangeError);
        await expectLater(player.move(2, 0), throwsRangeError);
        await expectLater(player.move(0, 3), throwsRangeError);
        await expectLater(player.replace(5, Media(fx)), throwsRangeError);
        // `to == length` moves to the end.
        await player.move(0, 2);
      }, timeout: const Timeout(Duration(seconds: 15)));

      test('out-of-range values throw before reaching mpv', () async {
        await expectLater(player.setVolume(-5), throwsRangeError);
        await expectLater(player.setRate(0), throwsRangeError);
        await expectLater(player.setPitch(1000), throwsRangeError);
        await expectLater(player.setVolume(double.nan), throwsArgumentError);
      });

      test('a rejected command throws MpvCommandException', () async {
        await expectLater(
          player.seek(const Duration(seconds: 1)),
          throwsA(
            isA<MpvCommandException>()
                .having((e) => e.name, 'name', 'seek')
                .having((e) => e.code, 'code', MpvError.mpvErrorCommand),
          ),
        );
      });

      test('a missing asset throws SourceException', () async {
        await expectLater(
          player.open(const Media('asset://assets/does_not_exist.wav')),
          throwsA(
            isA<SourceException>().having(
              (e) => e.uri,
              'uri',
              'asset://assets/does_not_exist.wav',
            ),
          ),
        );
      });

      test('every exception is an PlayerException', () async {
        await player.dispose();
        Object? error;
        try {
          await player.setVolume(10);
        } on PlayerException catch (e) {
          error = e;
        }
        expect(error, isA<PlayerDisposedException>());
      });
    });
  });
}
