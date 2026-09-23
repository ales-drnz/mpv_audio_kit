// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

import '../_helpers/setter_test_helpers.dart';

void main() {
  // Regression — `Media.httpHeaders` used to be applied via
  // `mpv_set_option_string('http-header-fields', ...)`, which writes
  // to the GLOBAL option. A subsequent `open(media2)` without headers
  // would leak `media1`'s headers (e.g. an Authorization token) onto
  // the second load. The fix routes per-file headers through
  // `file-local-options/http-header-fields`, which mpv resets at the
  // file boundary. This test asserts the GLOBAL option stays clear
  // after an `open()` that carried headers.
  final fixturePath = defaultFixturePath();

  setUpAll(() => initLibmpvOrSkip(fixturePath: fixturePath));

  group('HTTP header isolation across consecutive open()', () {
    late Player player;

    setUpAll(() async {
      // No fixture pre-open — each test opens its own Media to
      // exercise the headers code path explicitly.
      player = await buildPlayerWithFixture();
    });

    tearDownAll(() async {
      await player.dispose();
    });

    test('open(media with headers) reaches mpv as file-local options for '
        'the active entry', () async {
      await player.open(
        Media(
          fixturePath,
          httpHeaders: const {
            'X-Test-Token': 'leak-canary-12345',
            'X-Other': 'nope',
          },
        ),
        play: false,
      );

      // Wait for the file to settle so the loadfile-time options are
      // applied to the active entry.
      await player.stream.seekCompleted.first.timeout(
        const Duration(seconds: 5),
      );

      // Headers must have reached mpv. The bare property name is
      // resolved against mpv's file-local override during playback,
      // so the merged value should contain both headers verbatim.
      final effective = await player.getRawProperty('http-header-fields') ?? '';
      expect(
        effective,
        contains('X-Test-Token: leak-canary-12345'),
        reason: 'first header must be applied for the active entry',
      );
      expect(
        effective,
        contains('X-Other: nope'),
        reason: 'second header must be applied for the active entry',
      );
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('open(headers=A) followed by open(no headers) does not load the '
        'second file with leftover headers', () async {
      // Open A with headers.
      await player.open(
        Media(
          fixturePath,
          httpHeaders: const {'X-Test-Token': 'should-not-survive'},
        ),
        play: false,
      );
      await player.stream.seekCompleted.first.timeout(
        const Duration(seconds: 5),
      );

      // Open B without headers — the wrapper must NOT carry over A's
      // header set. Verify by reading the global option after the
      // second open: it must remain empty (no leak path).
      await player.open(Media(fixturePath), play: false);
      await player.stream.seekCompleted.first.timeout(
        const Duration(seconds: 5),
      );

      final global = await player.getRawProperty('http-header-fields');
      expect(
        global == null || global.isEmpty,
        isTrue,
        reason:
            'consecutive open() calls must not pollute the global '
            'http-header-fields option',
      );
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}
