// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:path_provider/path_provider.dart';

import 'release_gate.dart';

/// The thread of mpv's Android audio output (ao_audiotrack.c).
const audiotrackThread = 'ao/audiotrack';

/// The CPU time this process's threads named [name] have used, read from
/// /proc (Linux and Android). Zero when there is none.
Duration threadCpu(String name) {
  var ticks = 0;
  for (final task in Directory('/proc/self/task').listSync()) {
    try {
      if (File('${task.path}/comm').readAsStringSync().trim() != name) {
        continue;
      }
      final stat = File('${task.path}/stat').readAsStringSync();
      // After the name in parentheses: state is field 3, utime 14, stime 15.
      final fields = stat.substring(stat.lastIndexOf(')') + 2).split(' ');
      ticks += int.parse(fields[11]) + int.parse(fields[12]);
    } on FileSystemException {
      // The thread ended meanwhile.
    }
  }
  // USER_HZ is 100 on Android and Linux.
  return Duration(milliseconds: ticks * 10);
}

/// Whether this process has a thread named [name].
bool threadExists(String name) {
  for (final task in Directory('/proc/self/task').listSync()) {
    try {
      if (File('${task.path}/comm').readAsStringSync().trim() == name) {
        return true;
      }
    } on FileSystemException {
      // The thread ended meanwhile.
    }
  }
  return false;
}

/// The CPU time the threads named [name] use over [window].
Future<Duration> threadCpuOver(String name, Duration window) async {
  final before = threadCpu(name);
  await Future<void>.delayed(window);
  return threadCpu(name) - before;
}

/// Writes [seconds] of a quiet 440 Hz tone, mono 16-bit at 24 kHz, to the
/// temporary directory as [name] and returns its path.
Future<String> writeToneWav(String name, int seconds) async {
  const rate = 24000;
  final frames = rate * seconds;
  final d = ByteData(44 + frames * 2);
  void ascii(int at, String s) {
    for (var k = 0; k < s.length; k++) {
      d.setUint8(at + k, s.codeUnitAt(k));
    }
  }

  ascii(0, 'RIFF');
  d.setUint32(4, 36 + frames * 2, Endian.little);
  ascii(8, 'WAVEfmt ');
  d.setUint32(16, 16, Endian.little);
  d.setUint16(20, 1, Endian.little);
  d.setUint16(22, 1, Endian.little);
  d.setUint32(24, rate, Endian.little);
  d.setUint32(28, rate * 2, Endian.little);
  d.setUint16(32, 2, Endian.little);
  d.setUint16(34, 16, Endian.little);
  ascii(36, 'data');
  d.setUint32(40, frames * 2, Endian.little);
  for (var i = 0; i < frames; i++) {
    final v = 0.1 * math.sin(2 * math.pi * 440 * i / rate);
    d.setInt16(44 + i * 2, (v * 32767).round(), Endian.little);
  }
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$name');
  await file.writeAsBytes(d.buffer.asUint8List(), flush: true);
  return file.path;
}

/// The libmpv-scripts release of the libmpv [player] runs on, from
/// `mpv-version` ("mpv v0.41.0+r17" gives 17), or `null` without a stamp.
Future<int?> libmpvRelease(Player player) async {
  final version = await player.getRawProperty('mpv-version') ?? '';
  final m = RegExp(r'\+r(\d+)$').firstMatch(version.trim());
  return m == null ? null : int.parse(m.group(1)!);
}

/// Skips the running test when [player] runs on a libmpv older than
/// [release], which does not have the fix the test checks, and returns
/// whether it skipped. The device jobs of CI pass `--dart-define=MAK_CI=true`
/// and `MAK_LIBMPV_RELEASE`, the release of the binary they test: there a
/// release up to that one fails the test instead (see [releaseGate]).
Future<bool> skipBeforeRelease(Player player, int release) async {
  const ci = bool.fromEnvironment('MAK_CI');
  const name = String.fromEnvironment('MAK_LIBMPV_RELEASE');
  final expected = releaseNumber(name);
  if (ci && expected == null) {
    fail('MAK_CI without a release in MAK_LIBMPV_RELEASE ("$name")');
  }
  final found = await libmpvRelease(player);
  final bundled = found == null ? 'not a libmpv-scripts build' : 'r$found';
  switch (releaseGate(release, found, expected ?? 0, ci)) {
    case ReleaseGate.run:
      return false;
    case ReleaseGate.fail:
      fail(
        'tests a fix of libmpv-r$release, which this run expects with '
        '$name, but this libmpv is $bundled',
      );
    case ReleaseGate.skip:
      markTestSkipped(
        'tests a fix of libmpv-r$release, this libmpv is $bundled',
      );
      return true;
  }
}
