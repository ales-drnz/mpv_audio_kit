// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'package:test/test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import '../_helpers/setter_test_helpers.dart';

/// Permanent guard: verifies that the file-split workaround for the
/// SIGSEGV-on-3rd-Player quirk (documented in CLAUDE.md) keeps holding.
///
/// `flutter test` runs each test file in its own Dart isolate group;
/// this file's [Player] is logically separate from the one in
/// `test/runtime/player_runtime_test.dart`, so it does not contribute
/// to the per-isolate Player count that triggers the libmpv-internal
/// segfault on the third instance. The other `setters_*_test.dart`
/// files in this directory rely on the same property — if a future
/// flutter_test change ever broke per-file isolation, this guard test
/// (or one of the parallel setter tests) would crash before the
/// breakage reached production builds.
///
/// Do not delete; do not collapse into a `setters_*` file.
void main() {
  final fixturePath = defaultFixturePath();

  setUpAll(() => initLibmpvOrSkip(fixturePath: fixturePath));

  group('runtime_extended file split — fresh Player in a new file', () {
    late Player player;

    setUpAll(() async {
      player = await buildPlayer();
    });

    tearDownAll(() async {
      await player.dispose();
    });

    test(
        'Player constructs, opens fixture, sets volume, disposes — without '
        'crashing on the 3rd-Player SIGSEGV quirk because flutter_test '
        'puts each file in its own isolate group', () async {
      // Open the file to confirm the AO + demuxer init path completes
      // (this is the path most likely to expose any cross-isolate
      // libmpv state corruption from the parallel runtime test file).
      // Pre-subscribe BEFORE openAndWaitForLoad so the duration emit
      // isn't missed if it lands before seekCompleted resolves.
      final durationSettled = player.stream.duration
          .firstWhere((d) => d.inMilliseconds > 0)
          .timeout(const Duration(seconds: 5));
      await openAndWaitForLoad(player, fixturePath);
      if (player.state.duration == Duration.zero) await durationSettled;
      expect(player.state.duration.inMilliseconds, inInclusiveRange(900, 1100));

      // Exercise a setter: setVolume runs an optimistic state update,
      // so checking `state.volume` synchronously is sufficient. (We
      // don't subscribe to the stream because the broadcast emission
      // happens during the setter and would have already passed.)
      await player.setVolume(72.0);
      expect(player.state.volume, 72.0);
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}
