// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

import '../_helpers/setter_test_helpers.dart';

/// A Media opened by `file://` URL keeps its extras in the playlist and in
/// the source resolver (#23). mpv names the entry by the decoded path, so
/// a lookup by the URL the caller passed found nothing.
void main() {
  final source = defaultFixturePath();

  setUpAll(() => initLibmpvOrSkip(fixturePath: source));

  late Directory dir;
  late List<String> urls;

  setUp(() {
    // A space in the directory name: the URL carries it as %20.
    dir = Directory.systemTemp.createTempSync('mpv audio kit ');
    urls = [
      for (final name in ['a', 'b', 'c'])
        Uri.file(File(source).copySync('${dir.path}/$name.wav').path)
            .toString(),
    ];
  });

  tearDown(() => dir.deleteSync(recursive: true));

  test('openAll and add keep the extras of file:// entries', () async {
    expect(urls.first, contains('%20'));
    final player = await buildPlayer();
    try {
      final loaded = player.stream.seekCompleted.first
          .timeout(const Duration(seconds: 10));
      await player.openAll(
        [
          Media(urls[0], extras: {'n': 0}),
          Media(urls[1], extras: {'n': 1}),
        ],
        play: false,
      );
      await player.add(Media(urls[2], extras: {'n': 2}));
      await loaded;
      if (player.state.playlist.items.length != 3) {
        await player.stream.playlist
            .firstWhere((p) => p.items.length == 3)
            .timeout(const Duration(seconds: 10));
      }

      final items = player.state.playlist.items;
      expect([for (final m in items) m.extras?['n']], [0, 1, 2]);
      expect([for (final m in items) m.uri], urls,
          reason: 'the playlist hands back the Media the caller passed',);
    } finally {
      await player.dispose();
    }
  }, timeout: const Timeout(Duration(seconds: 30)),);

  test('the source resolver receives the extras of a file:// Media',
      () async {
    final player = await buildPlayer();
    try {
      final requests = <SourceResolveRequest>[];
      await player.setSourceResolver((request) {
        requests.add(request);
        return null;
      });
      final loaded = player.stream.seekCompleted.first
          .timeout(const Duration(seconds: 10));
      await player.open(Media(urls[0], extras: {'n': 0}), play: false);
      await loaded;

      expect(requests, isNotEmpty);
      expect(requests.first.media.extras?['n'], 0);
      expect(requests.first.media.uri, urls[0]);
    } finally {
      await player.setSourceResolver(null);
      await player.dispose();
    }
  }, timeout: const Timeout(Duration(seconds: 30)),);
}
