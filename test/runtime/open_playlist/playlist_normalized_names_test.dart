// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

// From mpv 0.42 the playlist names a local file by its absolute, normalized
// path (common/playlist.c, mp_normalize_path): a relative path, a `./`, a
// `//` and a `..` come back rewritten. The state still shows the Media the
// caller gave, with its extras, because the player follows the entries by
// mpv's entry id, not by name. The path of the file (`state.file.path`,
// mpv's `path`) is mpv's name for it, rewritten the same way.

@TestOn('linux || mac-os')
library;

import 'dart:async';
import 'dart:io';

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

import '../../_helpers/setter_test_helpers.dart';

void main() {
  runtimeSuite(() {
    final root = Directory.current.path;
    for (final (label, uri) in [
      ('relative', 'test/fixtures/sine_5s.flac'),
      ('dot and double slash', '$root/test/./fixtures//sine_5s.flac'),
      ('dot dot', '$root/test/fixtures/../fixtures/sine_5s.flac'),
    ]) {
      test('a $label path keeps its Media in the playlist', () async {
        final player = await buildPlayer();
        addTearDown(player.dispose);
        final media = Media(uri, extras: const {'tag': 'mine'});
        final loaded = Completer<void>();
        final sub = player.stream.seekCompleted.listen((_) {
          if (!loaded.isCompleted) loaded.complete();
        });
        addTearDown(sub.cancel);
        await player.open(media, play: false);
        await loaded.future.timeout(const Duration(seconds: 10));

        final name = await player.getRawProperty('playlist/0/filename');
        // The working directory joined and cleaned up; with a `..` mpv
        // takes the realpath instead.
        final plain = '$root/test/fixtures/sine_5s.flac';
        expect(
          name,
          uri.contains('..') ? File(plain).resolveSymbolicLinksSync() : plain,
          reason: 'mpv 0.42 stores the absolute, normalized path',
        );
        final items = player.state.playback.playlist.items;
        expect(items, hasLength(1));
        expect(items.single.uri, uri);
        expect(items.single.extras, const {'tag': 'mine'});
        expect(player.state.playback.playlist.current, same(items.single));
        await waitUntil(() => player.state.file.path.isNotEmpty);
        expect(
          player.state.file.path,
          name,
          reason: 'the path of the file is the name mpv gives the entry',
        );
      }, timeout: const Timeout(Duration(seconds: 20)));
    }
  });
}
