// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// A playlist of two entries plays through on the web backend, from blobs
// (as picked files arrive) and from files of the page over http, and parks
// at the end of the second: auto-advance, END_FILE and the end of content
// with its reads (test/web/fetch_module.sh, flutter test --platform chrome
// --wasm).

@TestOn('browser')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

import '../_helpers/parity_scenario.dart';
import 'web_module_helper.dart';

Future<List<String>> _playThrough(List<String> uris) async {
  final player = Player();
  final log = <String>[];
  player.stream.endFile.listen((e) => log.add('end ${e.reason.name}'));
  player.stream.completed.listen((c) => log.add('completed $c'));
  try {
    await player.ready;
    await player.setRawProperty('ao', 'null');
    await player
        .openAll([for (final u in uris) Media(u)], play: true)
        .timeout(const Duration(seconds: 10));
    await waitUntil(
      () => player.state.completed,
      timeout: const Duration(seconds: 12),
      what: 'the end of the playlist',
    );
    expect(player.state.playlist.index, 1);
  } finally {
    await player.dispose().timeout(const Duration(seconds: 10));
  }
  return log;
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadTestModule();
    MpvAudioKit.ensureInitialized(hotRestartCleanup: false);
  });

  test('two blobs play through and park', () async {
    final log = await _playThrough([
      await blobFixture('fixtures/sine_stereo_1s.flac'),
      await blobFixture('fixtures/sine_440hz_1s.wav'),
    ]);
    expect(log, containsAllInOrder(['end eof', 'completed true']));
  }, timeout: const Timeout(Duration(seconds: 40)));

  test('two files of the page play through and park', () async {
    final log = await _playThrough([
      testUrl('fixtures/sine_stereo_1s.flac'),
      testUrl('fixtures/sine_440hz_1s.wav'),
    ]);
    expect(log, containsAllInOrder(['end eof', 'completed true']));
  }, timeout: const Timeout(Duration(seconds: 40)));
}
