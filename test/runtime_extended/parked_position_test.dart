// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'dart:ffi';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

import '../_helpers/range_http_server.dart';
import '../_helpers/setter_test_helpers.dart';

/// Where the player stands once the last entry parks at its end. mpv
/// samples `time-pos` for its observers at a tick, at most every 50 ms, and
/// none comes while the core is parked; the event isolate reads the
/// position itself at the park. Played through the null output, untimed, a
/// one second entry loads, plays out and parks before the next tick: the
/// change mpv sampled at the load is still on its way after the park read,
/// with the position of the start. Each kind of source is played a few
/// times: on a Linux desktop the isolate is that late about 9 times in 10.
void main() {
  final oneSecond =
      '${Directory.current.path}/test/fixtures/sine_stereo_1s.flac';
  const end = Duration(seconds: 1);
  const rounds = 5;

  runtimeSuite(fixturePath: oneSecond, () {
    /// Plays [media], one second long, to its park, then stops it. Every
    /// position the player gives while `completed` is up must be the end,
    /// and so must the position its `endFile` carries. Stopping right
    /// after the park needs no wait: `completed` stays up until the
    /// `endFile` of the stop, and a change mpv still had to deliver for the
    /// entry reaches the player before it, or never (the unload samples
    /// `time-pos` again).
    Future<void> expectParkedAtEnd(Media Function() media) async {
      final wrong = <String>[];
      for (var round = 0; round < rounds; round++) {
        final player = await buildPlayer(
          configuration: const PlayerConfiguration(),
        );
        try {
          await player.setAudioNullUntimed(true);
          // Read in the listener: the state is the one the event that
          // moved the position left.
          final sub = player.stream.position.listen((p) {
            if (player.state.completed && (p - end).abs() > _tolerance) {
              wrong.add('round $round: position $p while completed');
            }
          });
          final completed = player.stream.completed
              .firstWhere((c) => c)
              .timeout(const Duration(seconds: 10));
          await player.open(media(), play: true);
          await completed;
          final ended = player.stream.endFile.first.timeout(
            const Duration(seconds: 5),
          );
          await player.stop();
          final position = (await ended).position;
          await sub.cancel();
          if (position == null || (position - end).abs() > _tolerance) {
            wrong.add('round $round: endFile at $position');
          }
        } finally {
          await player.dispose();
        }
      }
      expect(wrong, isEmpty);
    }

    test('a local file', () async {
      await expectParkedAtEnd(() => Media(oneSecond));
    }, timeout: const Timeout(Duration(seconds: 60)));

    test(
      'an fd:// descriptor',
      skip: Platform.isWindows ? 'POSIX descriptors' : false,
      () async {
        // A descriptor each: mpv reads one from where the last read left
        // it.
        await expectParkedAtEnd(() {
          final fd = _openFd(oneSecond);
          addTearDown(() => _closeFd(fd));
          return Media('fd://$fd');
        });
      },
      timeout: const Timeout(Duration(seconds: 60)),
    );

    test('a live PCM source', () async {
      await expectParkedAtEnd(() {
        const format = PcmFormat(sampleRate: 24000, channels: 1);
        final source = PcmSource.create(format);
        final d = ByteData(format.sampleRate * 2);
        for (var i = 0; i < format.sampleRate; i++) {
          final v = 0.3 * math.sin(2 * math.pi * 440 * i / format.sampleRate);
          d.setInt16(i * 2, (v * 32767).round(), Endian.little);
        }
        source.add(d.buffer.asUint8List());
        source.close();
        return source.toMedia();
      });
    }, timeout: const Timeout(Duration(seconds: 60)));

    test('an http file', () async {
      final server = await RangeHttpServer.start({
        'one.flac': File(oneSecond).readAsBytesSync(),
      });
      addTearDown(server.close);
      await expectParkedAtEnd(() => Media(server.url('one.flac')));
    }, timeout: const Timeout(Duration(seconds: 60)));
  });
}

/// How far from the end a position may land: mpv gives the end of these
/// sources to the microsecond.
const _tolerance = Duration(milliseconds: 5);

int _openFd(String path) {
  final open = DynamicLibrary.process()
      .lookupFunction<
        Int32 Function(Pointer<Utf8>, Int32),
        int Function(Pointer<Utf8>, int)
      >('open');
  final p = path.toNativeUtf8();
  try {
    final fd = open(p, 0);
    if (fd < 0) throw StateError('open($path) failed');
    return fd;
  } finally {
    malloc.free(p);
  }
}

void _closeFd(int fd) => DynamicLibrary.process()
    .lookupFunction<Int32 Function(Int32), int Function(int)>('close')(fd);
