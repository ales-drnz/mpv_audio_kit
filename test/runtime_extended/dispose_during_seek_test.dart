// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'dart:io';

import 'package:test/test.dart';
import '../_helpers/setter_test_helpers.dart';

void main() {
  // Dispose-during-seek — verifies the cooperative shutdown protocol
  // survives a teardown that races libmpv's mid-seek state. The seek
  // command is in flight when dispose() is called; mpv must finish (or
  // abort) the seek inside its own thread before terminate_destroy
  // returns, and the wrapper must not surface a `Bad state: Cannot add
  // new events after closing` from the property observer firing
  // post-controller-close.
  final fixturePath =
      '${Directory.current.path}/test/fixtures/with_chapters.mka';

  setUpAll(() => initLibmpvOrSkip(fixturePath: fixturePath));

  test('dispose() called while a seek is in flight teardowns cleanly',
      () async {
    final player = await buildPlayerWithFixture(fixturePath: fixturePath);

    // Kick off a seek WITHOUT awaiting — dispose() races the seek's
    // PLAYBACK_RESTART. The wrapper's dispose protocol issues `quit` to
    // mpv before calling terminate_destroy; mpv should abort the in-
    // flight seek as part of its quit response.
    // ignore: unawaited_futures
    player.seek(const Duration(seconds: 2));

    // No await delay — fire dispose immediately to maximize the race
    // window. If the cooperative shutdown is correct, this returns
    // without throwing or hanging.
    await player.dispose();

    // Let libmpv's worker threads unwind before the test process exits
    // — the cosmetic flutter_test "did not complete" flake is sensitive
    // to threads still alive at subprocess kill time.
    await Future.delayed(const Duration(seconds: 1));
  }, timeout: const Timeout(Duration(seconds: 30)));
}
