// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../_helpers/dart_probe.dart';
import '../_helpers/libmpv_resolver.dart';
import '../_helpers/setter_test_helpers.dart';

const _probe = 'test/_helpers/probes/build_mode_probe.dart';

void main() {
  // Hot Restart exists only in debug builds. A profile build runs AOT like
  // release, yet `dart.vm.product` is false there: keyed on that alone, it
  // woke the idle event isolate ten times a second and kept the Hot Restart
  // tracker on (F30). `flutter test` cannot compile a profile build, so a
  // `dart` process compiled with `dart.vm.profile` runs the probe.
  runtimeSuite(initialize: false, () {
    late Directory tmp;
    setUp(() => tmp = Directory.systemTemp.createTempSync('mak_build_mode'));
    tearDown(() => tmp.deleteSync(recursive: true));

    Future<Map<String, dynamic>> probe(List<String> defines) async =>
        probeReport(
          await runDartProbe(
            _probe,
            args: [resolveLibmpv()!],
            defines: defines,
            tempDir: tmp,
          ),
        );

    test('a debug build polls at 0.1 s and tracks handles', () async {
      final report = await probe(const []);
      expect(report['wakeups'], greaterThanOrEqualTo(10), reason: '$report');
      expect(report['orphans'], [0x5a5a0], reason: '$report');
    });

    test('a profile build waits like release and tracks no handles', () async {
      final report = await probe(const ['dart.vm.profile=true']);
      expect(report['wakeups'], lessThanOrEqualTo(5), reason: '$report');
      expect(report['orphans'], isEmpty, reason: '$report');
    });
  });
}
