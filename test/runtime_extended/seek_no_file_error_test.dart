// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

// Regression test (red phase): typed command methods discard mpv's
// return code. `sendRawCommand` throws MpvException on rc < 0; the
// typed `seek()` funnels through the same command path but ignores the
// rc, so seeking with no file loaded "succeeds" silently instead of
// surfacing the rejection. Contract under test: typed commands mirror
// the raw escape hatch and throw on mpv rejection.

@TestOn('mac-os || linux || windows')
library;

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

import '../_helpers/setter_test_helpers.dart';

void main() {
  setUpAll(() => initLibmpvOrSkip());

  late Player player;

  setUpAll(() async {
    player = await buildPlayer();
    await player.ready;
  });

  tearDownAll(() async {
    await player.dispose();
  });

  test('sanity: raw seek command with no file loaded is rejected by mpv '
      '(sendRawCommand throws)', () async {
    // Documents that mpv really returns rc < 0 here. If THIS test
    // fails, the premise (mpv rejects seek with no file) is wrong and
    // the typed-seek expectation below needs a different repro.
    await expectLater(
      player.sendRawCommand(['seek', '5', 'absolute']),
      throwsA(isA<MpvException>()),
      reason:
          'mpv is expected to reject `seek` while idle with rc < 0; '
          'sendRawCommand surfaces that as MpvException.',
    );
  }, timeout: const Timeout(Duration(seconds: 30)));

  test('typed seek() with no file loaded must throw MpvException like '
      'the raw command path does', () async {
    await expectLater(
      player.seek(const Duration(seconds: 5)),
      throwsA(isA<MpvException>()),
      reason:
          'seek() funnels through the same mpv command as '
          "sendRawCommand(['seek', ...]) — which throws here — but "
          'discards the return code and reports silent success. Typed '
          'commands must surface mpv rejections.',
    );
  }, timeout: const Timeout(Duration(seconds: 30)));
}
