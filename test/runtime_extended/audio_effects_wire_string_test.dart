// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

// F196: a string option went out as `[value]`, which mpv ends at the `]`
// that balances the first `[`. A path with a bracket broke the chain. The
// dump file of firequalizer shows the path the filter got.

@TestOn('mac-os || linux')
library;

import 'dart:io';

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

import '../_helpers/setter_test_helpers.dart';

void main() {
  final fixturePath =
      '${Directory.current.path}/test/fixtures/sine_stereo_48k_5s.flac';

  runtimeSuite(fixturePath: fixturePath, () {
    late Player player;
    late Directory dir;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('mak_wire_string');
      player = await buildPlayer();
      await player.open(Media(fixturePath), play: true);
      await player.stream.seekCompleted.first.timeout(
        const Duration(seconds: 10),
      );
    });

    tearDown(() async {
      await player.dispose();
      await dir.delete(recursive: true);
    });

    for (final name in ['a]b.txt', 'a[b.txt', 'x],lavfi-volume=volume=8']) {
      test('a path with a bracket reaches the filter whole ($name)', () async {
        final path = '${dir.path}/$name';
        await player.setAudioEffects([FirequalizerEffect(dumpfile: path)]);
        await waitUntil(
          () => File(path).existsSync(),
          timeout: const Duration(seconds: 5),
          reason: 'no dump at $path: ${dir.listSync()}',
        );
      }, timeout: const Timeout(Duration(seconds: 30)));
    }
  });
}
