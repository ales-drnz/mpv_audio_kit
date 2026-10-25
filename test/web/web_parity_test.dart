// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// The parity scenario (test/_helpers/parity_scenario.dart) on the web
// backend, with the module of test/web/module: its trace must be the one
// the native backend gives (test/web/parity_trace.txt, which
// test/runtime_extended/web_parity_native_test.dart checks on the VM).
// Two fixtures are files of the page over http (the test server answers
// no Range, so they play through without seeks), two are blobs, as a
// picked file arrives (seekable).

@TestOn('browser')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:mpv_audio_kit/src/backend/web/mpv_module.dart';

import '../_helpers/parity_scenario.dart';
import 'web_module_helper.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadTestModule();
    MpvAudioKit.ensureInitialized(hotRestartCleanup: false);
  });

  test('the parity scenario gives the native trace', () async {
    // Prints of a browser test do not reach the terminal: the steps go in
    // the failure instead.
    final steps = <String>[];
    parityLog = steps.add;
    Future<List<String>> run() async {
      steps.add('fixtures');
      final fixtures = ParityFixtures(
        long: await blobFixture('fixtures/sine_5s.flac'),
        first: testUrl('fixtures/sine_stereo_1s.flac'),
        second: await blobFixture('fixtures/sine_440hz_1s.wav'),
        cover: testUrl('fixtures/sine_with_cover.flac'),
      );
      return runParityScenario(fixtures);
    }

    final trace = await run().timeout(
      const Duration(seconds: 80),
      onTimeout: () => throw StateError('stuck after: ${steps.join(' | ')}'),
    );
    final golden = String.fromCharCodes(
      await fetchBytes('web/parity_trace.txt'),
    ).trimRight().split('\n');
    printOnFailure('core-locking calls, longest run in us: $webCallMaxMicros');
    expect(
      trace,
      golden,
      reason: 'steps: ${steps.join(' | ')}\ntrace:\n${trace.join('\n')}',
    );
  }, timeout: const Timeout(Duration(seconds: 90)));
}
