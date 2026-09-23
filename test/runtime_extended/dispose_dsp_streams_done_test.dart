// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

// Regression test (red phase): the four DSP stream controllers behind
// `stream.fft` / `stream.pcm` / `stream.spectrum` / `stream.waveform`
// must be closed by `dispose()` so subscribers receive `done`. A
// subscriber awaiting e.g. `stream.waveform.first` that races a dispose
// must not hang forever.

@TestOn('mac-os || linux || windows')
library;

import 'dart:async';

import 'package:test/test.dart';

import '../_helpers/setter_test_helpers.dart';

void main() {
  runtimeSuite(() {
    test('dispose() closes the DSP streams (fft/pcm/spectrum/waveform) — '
        'subscribers must receive done', () async {
      final player = await buildPlayer();
      await player.ready;

      Completer<void> watchDone<T>(Stream<T> stream) {
        final done = Completer<void>();
        stream.listen((_) {}, onDone: done.complete);
        return done;
      }

      // Control: `seekCompleted` IS in the dispose close list today.
      // It proves the harness detects `done` correctly — if this one
      // fails, the failure is in the test setup, not the audited bug.
      final controlDone = watchDone(player.stream.seekCompleted);

      final dspDone = <String, Completer<void>>{
        'fft': watchDone(player.stream.fft),
        'pcm': watchDone(player.stream.pcm),
        'spectrum': watchDone(player.stream.spectrum),
        'waveform': watchDone(player.stream.waveform),
      };

      await player.dispose();

      await expectLater(
        controlDone.future.timeout(const Duration(seconds: 2)),
        completes,
        reason:
            'Control stream seekCompleted did not emit done after '
            'dispose() — harness problem, not the audited bug.',
      );

      final neverClosed = <String>[];
      for (final entry in dspDone.entries) {
        try {
          await entry.value.future.timeout(const Duration(seconds: 2));
        } on TimeoutException {
          neverClosed.add(entry.key);
        }
      }

      expect(
        neverClosed,
        isEmpty,
        reason:
            'These DSP streams never emitted done after dispose() — '
            'their Player-side StreamControllers are not closed, so a '
            'subscriber awaiting `.first` across a dispose hangs forever.',
      );
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}
