// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

import '../_helpers/setter_test_helpers.dart';

/// On an auto-advance the cover, the waveform reset and the first envelope
/// of the next track must find `state.playlist` and `state.path` already on
/// that track (#21). Before, with prefetch on, they often arrived while the
/// state still named the previous one.
void main() {
  final source = '${Directory.current.path}/test/fixtures/sine_with_cover.flac';

  setUpAll(() => initLibmpvOrSkip(fixturePath: source));

  late Directory dir;
  late List<String> paths;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('mpv_audio_kit_advance_');
    paths = [
      for (final name in ['a', 'b', 'c'])
        File(source)
            .copySync('${dir.path}/$name.flac')
            .path
            .replaceAll(r'\', '/'),
    ];
  });

  tearDown(() => dir.deleteSync(recursive: true));

  /// Plays the three copies through and returns, for every cover, waveform
  /// reset and first envelope, the playlist index and path the state held.
  Future<List<(String, int, String)>> playThrough({
    required bool prefetch,
  }) async {
    final player = await buildPlayer();
    await player.setPrefetchPlaylist(prefetch);
    final seen = <(String, int, String)>[];
    var envelopeSeen = false;
    // mpv reports a Windows path with backslashes: compare with slashes.
    void record(String what) => seen.add(
          (
            what,
            player.state.playlist.index,
            player.state.path.replaceAll(r'\', '/'),
          ),
        );
    final subs = <StreamSubscription<Object?>>[
      player.stream.coverArt.listen((_) => record('cover')),
      player.stream.waveform.listen((w) {
        if (w == null) {
          envelopeSeen = false;
          record('reset');
        } else if (!envelopeSeen) {
          envelopeSeen = true;
          record('envelope');
        }
      }),
    ];
    try {
      final done = player.stream.completed
          .firstWhere((c) => c)
          .timeout(const Duration(seconds: 30));
      await player.openAll([for (final p in paths) Media(p)], play: true);
      await done;
    } finally {
      for (final s in subs) {
        await s.cancel();
      }
      await player.dispose();
    }
    return seen;
  }

  for (final prefetch in [true, false]) {
    test(
      'cover and waveform follow the state (prefetch: $prefetch)',
      () async {
        // Three runs of two track changes each: the race showed up in about
        // half of the prefetched changes.
        for (var run = 0; run < 3; run++) {
          final seen = await playThrough(prefetch: prefetch);
          // The opening null cover precedes the first file.
          final perTrack = seen.where((e) => e.$3.isNotEmpty).toList();
          for (var i = 0; i < paths.length; i++) {
            for (final what in ['cover', 'reset', 'envelope']) {
              final hits = perTrack
                  .where((e) => e.$1 == what && e.$3 == paths[i])
                  .toList();
              expect(
                hits,
                isNotEmpty,
                reason: 'run $run: no $what while the state named track $i',
              );
            }
          }
          for (final e in perTrack) {
            expect(
              paths.indexOf(e.$3),
              e.$2,
              reason: 'run $run: ${e.$1} saw index ${e.$2} with path ${e.$3}',
            );
          }
          final order = [
            for (final e in perTrack)
              if (e.$1 == 'cover') e.$2,
          ];
          expect(
            order,
            [0, 1, 2],
            reason: 'run $run: one cover per track, each with its own index',
          );
        }
      },
      timeout: const Timeout(Duration(seconds: 90)),
    );
  }
}
