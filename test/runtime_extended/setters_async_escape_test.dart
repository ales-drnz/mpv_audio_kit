// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'package:test/test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import '../_helpers/setter_test_helpers.dart';

void main() {
  final fixturePath = defaultFixturePath();

  setUpAll(() => initLibmpvOrSkip(fixturePath: fixturePath));

  group('Async escape hatches (getRawProperty / setRawProperty / sendRawCommand)',
      () {
    late Player player;

    setUpAll(() async {
      player = await buildPlayerWithFixture(fixturePath: fixturePath);
    });

    tearDownAll(() async {
      await player.dispose();
    });

    test(
        'getRawProperty / setRawProperty / sendRawCommand all return Future '
        'and round-trip through libmpv', () async {
      // setRawProperty returns Future<void> — reads correctly via
      // getRawProperty.
      await player.setRawProperty('volume', '42');
      final raw = await player.getRawProperty('volume');
      expect(raw, isNotNull);
      // mpv reports volume as a decimal string ("42.000000").
      expect(double.parse(raw!), 42.0);

      // sendRawCommand is fire-and-forget; verify it doesn't throw on a
      // valid command (`set` is a known-safe noop counterpart).
      await player.sendRawCommand(['set', 'volume', '50']);
      // Roundtrip back via getRawProperty.
      final after = await player.getRawProperty('volume');
      expect(double.parse(after!), 50.0);
    }, timeout: const Timeout(Duration(seconds: 15)));

    test('setRawProperty surfaces mpv errors as MpvException', () async {
      // Typo in the property name — mpv returns
      // MPV_ERROR_PROPERTY_NOT_FOUND (-8). Pre-fix, the rc was
      // discarded and the call silently succeeded.
      await expectLater(
        () => player.setRawProperty('voluem', '50'),
        throwsA(isA<MpvException>()
            .having((e) => e.name, 'name', 'voluem')
            .having((e) => e.code, 'code', lessThan(0))),
      );
    }, timeout: const Timeout(Duration(seconds: 5)));

    test('sendRawCommand surfaces mpv errors as MpvException', () async {
      // Unknown command — mpv returns MPV_ERROR_INVALID_PARAMETER.
      await expectLater(
        () => player.sendRawCommand(['this-command-does-not-exist']),
        throwsA(isA<MpvException>()
            .having((e) => e.name, 'name', 'this-command-does-not-exist')
            .having((e) => e.code, 'code', lessThan(0))),
      );
    }, timeout: const Timeout(Duration(seconds: 5)));
  });
}
