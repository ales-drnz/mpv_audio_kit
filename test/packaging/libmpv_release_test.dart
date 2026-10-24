// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// The tests of a libmpv-scripts release against the binary this run
// bundles. On CI a test of a release the binary should have and lacks
// fails instead of skipping, and the tests may not need a release past the
// one the run expects: a skip there would leave the fix untested while CI
// stays green.

import 'dart:io';

import 'package:mpv_audio_kit/src/internals/libmpv_release.dart';
import 'package:test/test.dart';

import '../_helpers/libmpv_resolver.dart';
import '../_helpers/release_gate.dart';
import '../_helpers/setter_test_helpers.dart'
    show expectedLibmpvRelease, strictLibmpvRelease;

/// The highest release the tests of [dirs] are gated on, through
/// libmpvReleaseGroup, needsLibmpvRelease and test_app's skipBeforeRelease.
int highestCitedRelease(List<String> dirs) {
  final call = RegExp(
    r'(?:libmpvReleaseGroup|needsLibmpvRelease)\(\s*(\d+)'
    r'|skipBeforeRelease\([^,()]+,\s*(\d+)\s*\)',
  );
  var highest = 0;
  for (final dir in dirs) {
    for (final file in Directory(dir).listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      // This file's own samples of the three calls.
      if (file.path.endsWith('libmpv_release_test.dart')) continue;
      for (final m in call.allMatches(file.readAsStringSync())) {
        final n = int.parse(m.group(1) ?? m.group(2)!);
        if (n > highest) highest = n;
      }
    }
  }
  return highest;
}

void main() {
  final root = Directory.current.path;

  group('releaseGate', () {
    test('a binary with the release runs the test', () {
      expect(releaseGate(19, 19, 19, true), ReleaseGate.run);
      expect(releaseGate(18, 19, 19, true), ReleaseGate.run);
      expect(releaseGate(19, 20, 19, false), ReleaseGate.run);
    });

    test('on CI a release up to the expected one fails on a binary '
        'without it', () {
      // LIBMPV_SCRIPTS_RUN still on the r18 Build, with r19 expected.
      expect(releaseGate(19, 18, 19, true), ReleaseGate.fail);
      expect(releaseGate(18, 17, 19, true), ReleaseGate.fail);
      // A build of upstream mpv carries no release.
      expect(releaseGate(18, null, 19, true), ReleaseGate.fail);
    });

    test('a release past the expected one is skipped, which '
        'highestCitedRelease catches on CI', () {
      // 0.5.2: pin r17, groups of r18, no Build run.
      expect(releaseGate(18, 17, 17, true), ReleaseGate.skip);
      expect(releaseGate(20, 19, 19, true), ReleaseGate.skip);
    });

    test('off CI a missing release is skipped', () {
      expect(releaseGate(19, 18, 19, false), ReleaseGate.skip);
      expect(releaseGate(18, null, 19, false), ReleaseGate.skip);
    });

    test('releaseNumber reads the manifest and pin form', () {
      expect(releaseNumber('r19'), 19);
      expect(releaseNumber('20'), 20);
      expect(releaseNumber(''), isNull);
      expect(releaseNumber('libmpv-r19'), isNull);
    });
  });

  test('highestCitedRelease finds the three gates', () {
    final dir = Directory.systemTemp.createTempSync('mak_release_cited');
    addTearDown(() => dir.deleteSync(recursive: true));
    File('${dir.path}/a_test.dart').writeAsStringSync(
      "libmpvReleaseGroup(18, 'x', () {});\n"
      'if (needsLibmpvRelease(21) != null) {}\n',
    );
    File(
      '${dir.path}/b_test.dart',
    ).writeAsStringSync('if (await skipBeforeRelease(player, 22)) return;\n');
    expect(highestCitedRelease([dir.path]), 22);
  });

  test('the hook bundles the release of libmpvRelease', () {
    final hook = File('$root/hook/build.dart').readAsStringSync();
    final release = RegExp(
      r"const _release = '([^']*)';",
    ).firstMatch(hook)?.group(1);
    expect(release, anyOf('libmpv-$libmpvRelease', r'libmpv-$libmpvRelease'));
  });

  test('test_app keeps an equal copy of the release gate', () {
    final host = File('$root/test/_helpers/release_gate.dart');
    final device = File(
      '$root/test_app/integration_test/_helpers/release_gate.dart',
    );
    expect(device.readAsStringSync(), host.readAsStringSync());
  });

  test('the tests need no release past the one this run expects', () {
    final cited = highestCitedRelease([
      '$root/test',
      '$root/test_app/integration_test',
    ]);
    final expected = expectedLibmpvRelease();
    expect(
      cited,
      lessThanOrEqualTo(expected),
      reason:
          'tests of libmpv-r$cited run on a binary of r$expected and '
          'would skip: set LIBMPV_SCRIPTS_RUN to the Build of r$cited',
    );
  }, skip: strictLibmpvRelease ? false : 'checked on CI only');

  test('the bundled libmpv is the release this run expects', () {
    final lib = resolveLibmpv();
    // A missing libmpv fails the runtime suites on CI already.
    if (lib == null) return markTestSkipped('no bundled libmpv');
    final found = libmpvReleaseOf(lib);
    final expected = expectedLibmpvRelease();
    expect(
      found,
      expected,
      reason:
          'the bundled libmpv is '
          '${found == null ? 'not a libmpv-scripts build' : 'r$found'}, '
          'this run expects r$expected (MAK_LIBMPV_RELEASE, or '
          'libmpvRelease without it)',
    );
  }, skip: strictLibmpvRelease ? false : 'checked on CI only');
}
