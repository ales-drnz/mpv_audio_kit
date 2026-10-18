// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

// The prefetch of libmpv-r18 (patch_prefetch_hook, patch_prefetch_state).
// mpv runs the `on_load` hook of the next entry while the current file
// plays. Up to r17 the patch hid the playing file's demuxer and moved its
// filename to the next entry for the length of the hook: a cache dump
// aborted the process, duration and tags went away, track changes did
// nothing (F271, F57, F272). The prefetch opened the next entry with the
// per-file options of the playing one, its HTTP headers included (F239),
// prefetch-state stayed `loading` after a failed open (F60) and kept the
// prefetch after a stop (F165).

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
  // a: 5 s, encoder tag Lavf62.12.100. b: 1 s stereo, Lavf63.1.102.
  final a = '$fixtures/sine_5s.flac';
  final b = '$fixtures/sine_stereo_1s.flac';
  final c = '$fixtures/sine_440hz_1s.wav';

  runtimeSuite(fixturePath: a, extraFixtures: [b, c], () {
    libmpvReleaseGroup(18, 'The prefetch of the next entry', () {
      late Player player;
      int? heldHook;

      setUp(() async {
        heldHook = null;
        player = await buildPlayer();
        await player.setPrefetchPlaylist(true);
        // The whole of a is read at once, so b is prefetched right after a
        // loads, not a second before a ends (a local file has no cache by
        // default).
        await player.setRawProperty('cache', 'yes');
      });

      tearDown(() async {
        final id = heldHook;
        if (id != null) await player.continueHook(id);
        await player.dispose();
      });

      // Plays a then b with `on_load` registered, and holds the hook of the
      // prefetch of b: returns once mpv waits in it, while a plays.
      Future<void> holdPrefetchOfB() async {
        await player.registerHook(Hook.load);
        final held = Completer<int>();
        player.stream.hook.listen((event) async {
          final url = await player.getRawProperty('stream-open-filename');
          if (!held.isCompleted && url == b) {
            held.complete(event.id);
          } else {
            await player.continueHook(event.id);
          }
        });
        await player.openAll([Media(a), Media(b)], play: true);
        heldHook = await held.future.timeout(const Duration(seconds: 10));
      }

      // F271: r17 set the demuxer to NULL around the hook, and
      // cache_dump_poll asserts one: the process aborted.
      test('a cache dump of the playing file survives the hook', () async {
        await holdPrefetchOfB();
        final dir = Directory.systemTemp.createTempSync('mak_dump');
        addTearDown(() => dir.deleteSync(recursive: true));
        // Open-ended: the command completes when the dump stops, at the
        // end of a.
        unawaited(
          player
              .sendRawCommand(['dump-cache', '0', 'no', '${dir.path}/a.mka'])
              .catchError((Object _) {}),
        );
        await Future<void>.delayed(const Duration(milliseconds: 500));
        expect(await player.getRawProperty('duration'), isNotNull);
      }, timeout: const Timeout(Duration(seconds: 30)));

      // F57: the hook sees the entry being loaded, the rest stays a's.
      test('the playing file keeps its duration and tags during the hook, '
          'while path names the entry being loaded', () async {
        await holdPrefetchOfB();
        final duration = double.tryParse(
          await player.getRawProperty('duration') ?? '',
        );
        expect(duration, closeTo(5, 0.1), reason: 'the duration of a');
        expect(
          await player.getRawProperty('metadata/by-key/encoder'),
          'Lavf62.12.100',
          reason: 'the tags of a',
        );
        expect(await player.getRawProperty('seekable'), 'yes');
        expect(await player.getRawProperty('media-title'), 'sine_5s.flac');
        expect(await player.getRawProperty('path'), b);
        expect(player.state.duration, const Duration(seconds: 5));
      }, timeout: const Timeout(Duration(seconds: 30)));

      // F272: with no demuxer, r17 added the track to nothing.
      test('an audio track added during the hook plays at once', () async {
        await holdPrefetchOfB();
        await player.addAudioTrack(Media(c));
        await waitUntil(
          () async =>
              await player.getRawProperty('current-tracks/audio/external') ==
              'yes',
          reason: 'the added track never became the playing one',
        );
      }, timeout: const Timeout(Duration(seconds: 30)));

      // F60: r17 reported `loading` until the transition, 5 s later.
      test('a prefetch that cannot open turns failed while the current '
          'file plays', () async {
        final sw = Stopwatch()..start();
        final failedAt = player.stream.prefetchState
            .firstWhere((s) => s == PrefetchState.failed)
            .then((_) => (sw.elapsed, player.state.playlist.index))
            .timeout(const Duration(seconds: 10));
        await player.openAll([Media(a), Media('$a.missing.flac')], play: true);
        final (elapsed, index) = await failedAt;
        expect(index, 0, reason: 'a still plays');
        expect(
          elapsed,
          lessThan(const Duration(seconds: 2)),
          reason: 'the failed open of b was reported only at the end of a',
        );
      }, timeout: const Timeout(Duration(seconds: 30)));

      // F165: r17 kept the prefetch, and `ready`, after a stop.
      test('a stop drops the prefetch and resets the state', () async {
        final ready = player.stream.prefetchState
            .firstWhere((s) => s == PrefetchState.ready)
            .timeout(const Duration(seconds: 10));
        await player.openAll([Media(a), Media(b)], play: true);
        await ready;
        await player.stop();
        await waitUntil(
          () async => await player.getRawProperty('prefetch-state') == 'idle',
          timeout: const Duration(seconds: 2),
          reason: 'the prefetch outlived the stop',
        );
      }, timeout: const Timeout(Duration(seconds: 30)));

      // F239: the opener reads the global options, which during playback
      // hold the per-file options of the playing entry.
      test('the HTTP headers of an entry do not reach the next one', () async {
        final server = await RangeHttpServer.start({
          'a.wav': longWav(2),
          'b.wav': longWav(1),
        });
        addTearDown(server.close);
        final loadedB = player.stream.playlist
            .firstWhere((p) => p.index == 1)
            .then((_) => player.stream.seekCompleted.first)
            .timeout(const Duration(seconds: 15));
        await player.openAll([
          Media(server.url('a.wav'), httpHeaders: const {'X-Token': 'of-a'}),
          Media(server.url('b.wav')),
        ], play: true);
        // r17 sends the prefetch of b while a plays, r18 opens b only at
        // the transition.
        await waitUntil(
          () => server.gets('/b.wav').isNotEmpty,
          timeout: const Duration(seconds: 15),
          reason: 'b was never requested',
        );
        final toB = server.gets('/b.wav');
        expect(
          toB.where((r) => r.headers.containsKey('x-token')),
          isEmpty,
          reason: 'requests for b: ${server.describe()}',
        );
        expect(
          server.gets('/a.wav').first.headers['x-token'],
          'of-a',
          reason: 'a carries its own header',
        );
        await loadedB;
      }, timeout: const Timeout(Duration(seconds: 30)));
    });
  });
}
