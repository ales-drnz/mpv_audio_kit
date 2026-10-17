// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../_helpers/dart_probe.dart';

const _probe = 'test/_helpers/probes/tracker_probe.dart';

/// The fake handle the probe registers.
const _fakeHandle = 0x5a5a0;

void main() {
  // The Hot Restart tracker in a fresh `dart` process of its own: the one
  // place a test can give it a new pid, a temp directory of its own and a
  // crash that does not take the test runner down.
  late Directory tmp;
  setUp(() => tmp = Directory.systemTemp.createTempSync('mak_tracker'));
  tearDown(() => tmp.deleteSync(recursive: true));

  Future<Map<String, dynamic>> probe(List<String> args) async =>
      probeReport(await runDartProbe(_probe, args: args, tempDir: tmp));

  // A process that exits leaves its sentinel behind, and a later process can
  // get the same pid. Read as a Hot Restart, the address in it belongs to
  // the dead process: 4096 is never mapped, so a read there crashes (F25).
  test(
    'a sentinel left by a dead process with our pid is never dereferenced',
    () async {
      final report = await probe(const ['own', '4096']);
      expect(report['first'], {'restarted': false, 'orphans': <int>[]});
      expect(report['second'], {
        'restarted': true,
        'orphans': [_fakeHandle],
      });
    },
  );

  test('a fresh process leaves no file in the temp directory', () async {
    final report = await probe(const []);
    expect(report['second'], {
      'restarted': true,
      'orphans': [_fakeHandle],
    });
    expect(tmp.listSync(), isEmpty);
  });

  // A child process inherits the environment, so it sees the buffer of its
  // parent: the pid in the value tells it apart. Here the parent is the
  // test process, and its value points at 4096, which is never mapped.
  test('a child process never reads the buffer of its parent', () async {
    final report = probeReport(
      await runDartProbe(
        _probe,
        tempDir: tmp,
        environment: {'MPV_AUDIO_KIT_ORPHAN_BUFFER': '$pid:4096'},
      ),
    );
    expect(report['first'], {'restarted': false, 'orphans': <int>[]});
    expect(report['second'], {
      'restarted': true,
      'orphans': [_fakeHandle],
    });
  });

  // On iOS no process can start: `kill -0` threw and ended the sweep of the
  // old sentinels at the first one (#24). The tracker now starts no process
  // at all. A PATH where nothing runs reproduces the iOS condition on any
  // host, and a PATH whose `kill` logs each call proves that none is made.
  group('the tracker starts no process', () {
    late Directory bin;
    setUp(() => bin = Directory('${tmp.path}/bin')..createSync());

    Future<ProcessResult> probeOn(String path) => runDartProbe(
      _probe,
      args: const ['other', '4096'],
      tempDir: tmp,
      environment: {'PATH': path},
    );

    test('so it works where none can start, as on iOS (#24)', () async {
      final result = await probeOn(bin.path);
      expect(result.stderr, isNot(contains('mpv_audio_kit:')));
      final report = probeReport(result);
      expect(report['first'], {'restarted': false, 'orphans': <int>[]});
      expect(report['second'], {
        'restarted': true,
        'orphans': [_fakeHandle],
      });
    });

    test('so no kill runs for a sentinel of another pid', () async {
      final log = File('${tmp.path}/kill.log');
      final kill = File('${bin.path}/kill')
        ..writeAsStringSync('#!/bin/sh\necho "\$@" >> "${log.path}"\nexit 1\n');
      expect(Process.runSync('chmod', ['+x', kill.path]).exitCode, 0);
      final report = probeReport(await probeOn(bin.path));
      expect(
        log.existsSync() ? log.readAsStringSync() : '',
        isEmpty,
        reason: 'the tracker ran kill',
      );
      expect(report['second'], {
        'restarted': true,
        'orphans': [_fakeHandle],
      });
    }, testOn: 'mac-os || linux');
  });

  test(
    'an unreadable sentinel with our pid leaves the tracker working',
    () async {
      final report = await probe(const ['own', 'abc']);
      expect(report['first'], {'restarted': false, 'orphans': <int>[]});
      expect(report['second'], {
        'restarted': true,
        'orphans': [_fakeHandle],
      });
    },
  );
}
