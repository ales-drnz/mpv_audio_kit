// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

// The prefetch of libmpv-r20 (patch_prefetch): mpv runs `on_prefetch`
// before it opens the next entry ahead of time, and keeps playing the
// current one while the hook is held. Up to r19 the prefetch ran `on_load`
// inside a nested hook loop that fed no audio: a resolver slower than the
// output buffer left a gap in the playing entry, and one still running at
// the end of the entry held the transition (F9). A consumer of
// `Hook.load` got the event twice for a prefetched entry (F241).

@TestOn('mac-os || linux || windows')
library;

import 'dart:async';
import 'dart:io';

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

import '../_helpers/long_wav.dart';
import '../_helpers/range_http_server.dart';
import '../_helpers/setter_test_helpers.dart';

void main() {
  final fixtures = '${Directory.current.path}/test/fixtures';
  // long: 5 s. short: 1 s. other: 1 s, another file.
  final long = '$fixtures/sine_5s.flac';
  final short = '$fixtures/sine_440hz_1s.wav';
  final other = '$fixtures/sine_stereo_1s.flac';

  runtimeSuite(fixturePath: long, extraFixtures: [short, other], () {
    libmpvReleaseGroup(20, 'The on_prefetch hook', () {
      late Player player;

      setUp(() async {
        player = await buildPlayer();
        await player.setPrefetchPlaylist(true);
        // The whole of an entry is read at once, so the next one is
        // prefetched right after it loads (a local file has no cache by
        // default).
        await player.setRawProperty('cache', 'yes');
      });

      tearDown(() => player.dispose());

      // Completes with the elapsed time once entry [index] loaded.
      Future<Duration> loadedAt(int index, Stopwatch sw) => player
          .stream
          .playlist
          .firstWhere((p) => p.index == index)
          .then((_) => player.stream.seekCompleted.first)
          .then((_) => sw.elapsed)
          .timeout(const Duration(seconds: 15));

      test('a Hook.load of the app runs once per entry, not for the '
          'prefetch (F241)', () async {
        await player.registerHook(Hook.load);
        final loads = <String>[];
        player.stream.hook.listen((event) async {
          if (event.hook == Hook.load) {
            loads.add(
              _slashes(
                await player.getRawProperty('stream-open-filename') ?? '',
              ),
            );
          }
          await player.continueHook(event.id);
        });
        final prefetched = player.stream.prefetchState
            .firstWhere((s) => s == PrefetchState.ready)
            .timeout(const Duration(seconds: 10));
        final sw = Stopwatch()..start();
        final loaded = loadedAt(1, sw);
        await player.openAll([Media(short), Media(long)], play: true);
        await prefetched;
        await loaded;
        expect(loads, [_slashes(short), _slashes(long)]);
      }, timeout: const Timeout(Duration(seconds: 30)));

      test('a Hook.prefetch of the app reads and redirects the early open, '
          'and names the entry', () async {
        final server = await RangeHttpServer.start({
          'b.wav': longWav(1),
          'c.wav': longWav(1),
        });
        addTearDown(server.close);
        await player.registerHook(Hook.prefetch);
        final seen = Completer<(String?, String?, String?, String?)>();
        player.stream.hook.listen((event) async {
          if (event.hook == Hook.prefetch && !seen.isCompleted) {
            final url = await player.getRawProperty('prefetch-open-filename');
            final id = await player.getRawProperty(
              'prefetch-playlist-entry-id',
            );
            final expected = await player.getRawProperty('playlist/1/id');
            final path = await player.getRawProperty('path');
            await player.setRawProperty(
              'prefetch-open-filename',
              server.url('c.wav'),
            );
            seen.complete((url, id, expected, path));
          }
          await player.continueHook(event.id);
        });
        await player.openAll([
          Media(long),
          Media(server.url('b.wav')),
        ], play: true);
        final (url, id, expected, path) = await seen.future.timeout(
          const Duration(seconds: 10),
        );
        expect(url, server.url('b.wav'));
        expect(id, isNotNull);
        expect(id, expected);
        expect(_slashes(path ?? ''), _slashes(long), reason: 'path is a\'s');
        await waitUntil(
          () => server.gets('/c.wav').isNotEmpty,
          timeout: const Duration(seconds: 10),
          reason: 'the prefetch did not open the URL written in the hook',
        );
        expect(server.gets('/b.wav'), isEmpty);
        expect(player.state.playlist.index, 0);
      }, timeout: const Timeout(Duration(seconds: 30)));
    });
  });
}

/// A path with forward slashes only: on Windows mpv reports the paths it
/// opens with backslashes.
String _slashes(String path) => path.replaceAll(r'\', '/');
