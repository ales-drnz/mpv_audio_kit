// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

import '../_helpers/setter_test_helpers.dart';

void main() {
  late Player player;

  setUpAll(() async {
    initLibmpvOrSkip();
    player = await buildPlayer();
    await openAndWaitForLoad(
      player,
      '${Directory.current.path}/test/fixtures/sine_440hz_1s.wav',
    );
  });

  tearDownAll(() => player.dispose());

  test(
    'getRawPropertyNode decodes structured properties as native trees',
    () async {
      final trackList = await player.getRawPropertyNode('track-list');
      expect(trackList, isA<List<dynamic>>());
      final tracks = trackList as List<dynamic>;
      expect(tracks, isNotEmpty);
      expect(tracks.first, isA<Map<String, dynamic>>());
      expect((tracks.first as Map<String, dynamic>)['type'], 'audio');

      final cacheState = await player.getRawPropertyNode('demuxer-cache-state');
      expect(cacheState, isA<Map<String, dynamic>>());
    },
    timeout: const Timeout(Duration(seconds: 15)),
  );

  test('getRawPropertyNode returns scalars for scalar properties', () async {
    final volume = await player.getRawPropertyNode('volume');
    expect(volume, isA<double>());
  }, timeout: const Timeout(Duration(seconds: 10)));

  test('getRawPropertyNode returns null for unknown properties', () async {
    expect(
      await player.getRawPropertyNode('definitely-not-a-property'),
      isNull,
    );
  }, timeout: const Timeout(Duration(seconds: 10)));
}
