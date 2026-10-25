// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// The parity scenario (test/_helpers/parity_scenario.dart) on the native
// backend: its trace is the one the web backend must give too
// (test/web/web_parity_test.dart). MAK_PARITY_WRITE=1 rewrites
// test/web/parity_trace.txt from this run.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../_helpers/parity_scenario.dart';
import '../_helpers/setter_test_helpers.dart';

void main() {
  final dir = '${Directory.current.path}/test/fixtures';
  final fixtures = ParityFixtures(
    long: '$dir/sine_5s.flac',
    first: '$dir/sine_stereo_1s.flac',
    second: '$dir/sine_440hz_1s.wav',
    cover: '$dir/sine_with_cover.flac',
  );
  runtimeSuite(
    () {
      test('the parity scenario gives the trace both backends share', () async {
        final trace = await runParityScenario(fixtures);
        final golden = File('test/web/parity_trace.txt');
        if (Platform.environment['MAK_PARITY_WRITE'] == '1') {
          golden.writeAsStringSync('${trace.join('\n')}\n');
        }
        expect(trace, golden.readAsLinesSync());
      }, timeout: const Timeout(Duration(seconds: 90)));
    },
    fixturePath: fixtures.long,
    extraFixtures: [fixtures.first, fixtures.second, fixtures.cover],
  );
}
