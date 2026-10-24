// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

@TestOn('mac-os || linux')
@Timeout(Duration(minutes: 2))
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

import '../_helpers/setter_test_helpers.dart';
import '../_helpers/slow_core_shim.dart';

void main() {
  slowCoreShimSuite(fixturePath: defaultFixturePath(), (shim) {
    setUp(() => shim().reset());
    tearDown(() => shim().reset());

    // F148: a payload the event isolate failed to read reached stream.log
    // with the prefix 'event-isolate', as if mpv had logged it, and at the
    // error level also stream.error as a LogError, whatever the configured
    // log level. It is the library's own diagnostic: internalLog.
    test('a diagnostic of the event isolate goes to internalLog, not to the '
        "engine's log or error", () async {
      // Read at FILE_LOADED: the payload read fails.
      shim().breakNodeGet('chapter-list');
      final player = await buildPlayer();
      final log = <MpvLogEntry>[];
      final errors = <PlayerError>[];
      final internal = <MpvLogEntry>[];
      final subs = [
        player.stream.log.listen(log.add),
        player.stream.error.listen(errors.add),
        player.stream.internalLog.listen(internal.add),
      ];
      try {
        await openAndWaitForLoad(player, defaultFixturePath());
        expect(shim().counter('broken_gets'), greaterThan(0));
        await waitUntil(
          () => internal.any((e) => e.text.contains('payload read failed')),
          reason:
              'no internalLog entry for the failed read (log: $log, '
              'errors: $errors)',
        );
        expect(
          log,
          isEmpty,
          reason: 'logLevel is off: the engine log carries nothing',
        );
        expect(errors, isEmpty);
      } finally {
        for (final sub in subs) {
          await sub.cancel();
        }
        await player.dispose();
      }
    });
  });
}
