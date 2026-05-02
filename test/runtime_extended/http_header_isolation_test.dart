// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'package:test/test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
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

    test(
        'open(media with headers) does NOT leak headers to the global '
        'http-header-fields option', () async {
      // Sanity: global http-header-fields starts empty.
      final before = await player.getRawProperty('http-header-fields');
      expect(before == null || before.isEmpty, isTrue,
          reason: 'global http-header-fields must start empty');

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

      // Wait for the file to settle so any header application has
      // landed in mpv's state.
      await player.stream.seekCompleted.first
          .timeout(const Duration(seconds: 5));

      // The fix uses `file-local-options/http-header-fields` which
      // mpv applies for the active file only and never writes to the
      // global option. Confirm the global stays empty — the leak the
      // regression test guards against.
      final globalAfter = await player.getRawProperty('http-header-fields');
      expect(globalAfter == null || globalAfter.isEmpty, isTrue,
          reason: 'global http-header-fields must NOT carry per-file '
              'headers — those belong to file-local-options/...');
    }, timeout: const Timeout(Duration(seconds: 30)));

    test(
        'open(headers=A) followed by open(no headers) does not load the '
        'second file with leftover headers', () async {
      // Open A with headers.
      await player.open(
        Media(
          fixturePath,
          httpHeaders: const {'X-Test-Token': 'should-not-survive'},
        ),
        play: false,
      );
      await player.stream.seekCompleted.first
          .timeout(const Duration(seconds: 5));

      // Open B without headers — the wrapper must NOT carry over A's
      // header set. Verify by reading the global option after the
      // second open: it must remain empty (no leak path).
      await player.open(Media(fixturePath), play: false);
      await player.stream.seekCompleted.first
          .timeout(const Duration(seconds: 5));

      final global = await player.getRawProperty('http-header-fields');
      expect(global == null || global.isEmpty, isTrue,
          reason: 'consecutive open() calls must not pollute the global '
              'http-header-fields option');
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}
