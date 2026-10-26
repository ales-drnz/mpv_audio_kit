// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

// TEMPORARY probe of front C4, removed before integration: how long a
// refused or silent smb2:// and http:// open takes to end on Windows. It
// only prints and always passes.

@TestOn('windows')
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

import '../_helpers/setter_test_helpers.dart';

Future<void> _probe(String what, String url, {Duration? networkTimeout}) async {
  final player = await buildPlayer(configuration: const PlayerConfiguration());
  final seen = <String>[];
  final clock = Stopwatch()..start();
  try {
    await player.setAudioNullUntimed(true);
    if (networkTimeout != null) await player.setNetworkTimeout(networkTimeout);
    final subs = [
      player.stream.log.listen(
        (e) => seen.add(
          '${clock.elapsedMilliseconds} ms log ${e.level.name} '
          '[${e.prefix}] ${e.text.trim()}',
        ),
      ),
      player.stream.endFile.listen(
        (e) => seen.add(
          '${clock.elapsedMilliseconds} ms end ${e.reason.name} ${e.error}',
        ),
      ),
    ];
    final settled = Future.any([
      player.stream.completed.firstWhere((c) => c),
      player.stream.error.firstWhere((e) => e is EndFileError),
    ]);
    clock.reset();
    await player.open(Media(url), play: true);
    var ended = true;
    try {
      await settled.timeout(const Duration(seconds: 75));
    } on TimeoutException {
      ended = false;
    }
    final ms = clock.elapsedMilliseconds;
    for (final s in subs) {
      await s.cancel();
    }
    // ignore: avoid_print
    print(
      'C4PROBE $what: ${ended ? 'ended after $ms ms' : 'not ended after $ms ms'}'
      ' (network timeout ${networkTimeout ?? 'default'})\n'
      '${seen.map((l) => '  $l').join('\n')}',
    );
  } finally {
    await player.dispose();
  }
}

void main() {
  runtimeSuite(() {
    test('refused and silent opens', () async {
      final closed = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final refused = closed.port;
      await closed.close();
      final silent = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final held = <Socket>[];
      silent.listen(held.add);
      try {
        await _probe('smb2 refused', 'smb2://127.0.0.1:$refused/share/a.flac');
        await _probe(
          'smb2 refused 5 s',
          'smb2://127.0.0.1:$refused/share/a.flac',
          networkTimeout: const Duration(seconds: 5),
        );
        await _probe(
          'smb2 silent 1 s',
          'smb2://127.0.0.1:${silent.port}/share/a.flac',
          networkTimeout: const Duration(seconds: 1),
        );
        await _probe('http refused', 'http://127.0.0.1:$refused/a.flac');
        await _probe(
          'http refused 5 s',
          'http://127.0.0.1:$refused/a.flac',
          networkTimeout: const Duration(seconds: 5),
        );
      } finally {
        for (final s in held) {
          s.destroy();
        }
        await silent.close();
      }
    }, timeout: const Timeout(Duration(minutes: 8)));
  });
}
