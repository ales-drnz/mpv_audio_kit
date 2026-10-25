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
      late List<String> warnings;

      setUp(() async {
        player = await buildPlayer();
        warnings = [];
        player.stream.internalLog.listen((e) => warnings.add(e.text));
        await player.setPrefetchPlaylist(true);
        // The whole of an entry is read at once, so the next one is
        // prefetched right after it loads (a local file has no cache by
        // default).
        await player.setRawProperty('cache', 'yes');
      });

      tearDown(() => player.dispose());

      Future<double?> timePos() async =>
          double.tryParse(await player.getRawProperty('time-pos') ?? '');

      // Completes with the elapsed time once entry [index] loaded.
      Future<Duration> loadedAt(int index, Stopwatch sw) => player
          .stream
          .playlist
          .firstWhere((p) => p.index == index)
          .then((_) => player.stream.seekCompleted.first)
          .then((_) => sw.elapsed)
          .timeout(const Duration(seconds: 15));

      bool droppedLate() => warnings.any(
        (w) => w.contains('on_prefetch') && w.contains('dropped the prefetch'),
      );

      test('the current entry plays on while the resolver of the next one '
          'runs (F9)', () async {
        final done = Completer<(double, double)>();
        var asked = false;
        await player.setSourceResolver((request) async {
          if (_slashes(request.uri) != _slashes(short) || asked) return null;
          asked = true;
          // From the moment the output runs: up to r19 it never does
          // while the hook is held.
          final until = DateTime.now().add(const Duration(seconds: 1));
          while ((await timePos() ?? 0) < 0.05 &&
              DateTime.now().isBefore(until)) {
            await Future<void>.delayed(const Duration(milliseconds: 20));
          }
          final before = await timePos() ?? 0;
          await Future<void>.delayed(const Duration(milliseconds: 1500));
          done.complete((before, await timePos() ?? 0));
          return null;
        });
        await player.openAll([Media(long), Media(short)], play: true);
        final (before, after) = await done.future.timeout(
          const Duration(seconds: 10),
        );
        expect(
          after - before,
          greaterThanOrEqualTo(1.2),
          reason: 'the playing entry went from $before s to $after s',
        );
        expect(player.state.playlist.index, 0);
      }, timeout: const Timeout(Duration(seconds: 30)));

      test(
        'the next entry starts on time while the resolver of its '
        'prefetch runs, and the resolver is asked again for its load',
        () async {
          var calls = 0;
          final late = Completer<void>();
          await player.setSourceResolver((request) async {
            if (_slashes(request.uri) != _slashes(long)) return null;
            if (++calls > 1) return null;
            // Past the end of the 1 s entry before it.
            await Future<void>.delayed(const Duration(seconds: 3));
            late.complete();
            return other;
          });
          final sw = Stopwatch()..start();
          final loaded = loadedAt(1, sw);
          await player.openAll([Media(short), Media(long)], play: true);
          final at = await loaded;
          expect(
            at,
            lessThan(const Duration(milliseconds: 2500)),
            reason: 'the entry waited for the resolver of its prefetch',
          );
          expect(calls, 2, reason: 'once for the prefetch, once for the load');
          await late.future.timeout(const Duration(seconds: 5));
          await waitUntil(droppedLate, reason: 'no warning: $warnings');
          expect(
            _slashes(await player.getRawProperty('path') ?? ''),
            _slashes(long),
            reason: 'the late URL of the prefetch reached the entry',
          );
        },
        timeout: const Timeout(Duration(seconds: 30)),
      );

      test('a URL the resolver gives after mpv dropped the prefetch changes '
          'nothing, and the next prefetch waits for it', () async {
        var calls = 0;
        DateTime? lateAt;
        DateTime? nextAt;
        await player.setSourceResolver((request) async {
          final uri = _slashes(request.uri);
          if (uri == _slashes(other) && player.state.playlist.index == 1) {
            nextAt ??= DateTime.now();
          }
          if (uri != _slashes(long) || ++calls > 1) return null;
          await Future<void>.delayed(const Duration(milliseconds: 2500));
          lateAt = DateTime.now();
          return short;
        });
        await player.openAll([
          Media(short),
          Media(long),
          Media(other),
        ], play: true);
        await waitUntil(
          () => nextAt != null,
          timeout: const Duration(seconds: 10),
          reason: 'the entry after the next one was never prefetched',
        );
        expect(lateAt, isNotNull);
        expect(
          nextAt!.isBefore(lateAt!),
          isFalse,
          reason: 'a new prefetch ran before the dropped one continued',
        );
        expect(droppedLate(), isTrue, reason: 'no warning: $warnings');
        expect(player.state.playlist.index, 1);
        expect(
          _slashes(await player.getRawProperty('path') ?? ''),
          _slashes(long),
        );
        expect(
          _slashes(await player.getRawProperty('playlist/2/filename') ?? ''),
          _slashes(other),
        );
      }, timeout: const Timeout(Duration(seconds: 30)));

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

      test('the prefetch gives the resolver the Media of its own entry '
          '(F14)', () async {
        final extras = <Object?>[];
        await player.setSourceResolver((request) {
          if (_slashes(request.uri) == _slashes(short) &&
              player.state.playlist.index == 0) {
            extras.add(request.media.extras?['n']);
          }
          return null;
        });
        // Two entries with the URL of the prefetched one: a lookup by URL
        // finds the later one.
        await player.openAll([
          Media(long),
          Media(short, extras: const {'n': 1}),
          Media(short, extras: const {'n': 2}),
        ], play: true);
        await waitUntil(
          () => extras.isNotEmpty,
          timeout: const Duration(seconds: 10),
          reason: 'the prefetch never ran the resolver',
        );
        expect(extras.first, 1);
      }, timeout: const Timeout(Duration(seconds: 30)));

      test('the deadline continues on_prefetch, and the playing entry never '
          'waits for it', () async {
        final done = Completer<(double, double)>();
        var asked = false;
        await player.setSourceResolver((request) async {
          if (_slashes(request.uri) != _slashes(short) || asked) return null;
          asked = true;
          final before = await timePos() ?? 0;
          await Future<void>.delayed(const Duration(seconds: 3));
          done.complete((before, await timePos() ?? 0));
          return other;
        }, timeout: const Duration(seconds: 1));
        await player.openAll([Media(long), Media(short)], play: true);
        await waitUntil(
          () => warnings.any(
            (w) => w.contains('"on_prefetch"') && w.contains('timed out'),
          ),
          timeout: const Duration(seconds: 10),
          reason: 'the deadline never continued the hook: $warnings',
        );
        await waitUntil(
          () async => await player.getRawProperty('prefetch-state') == 'ready',
          timeout: const Duration(seconds: 2),
          reason: 'the continued prefetch did not open the entry',
        );
        final (before, after) = await done.future.timeout(
          const Duration(seconds: 5),
        );
        expect(after - before, greaterThan(2.0), reason: '$before to $after');
        await waitUntil(
          () => warnings.any((w) => w.contains('after its hook timed out')),
          reason: 'the late URL was not dropped: $warnings',
        );
      }, timeout: const Timeout(Duration(seconds: 30)));

      // Each way to drop the next entry, and how to queue it again.
      for (final (name, drop, again)
          in <
            (
              String,
              Future<void> Function(Player),
              Future<void> Function(Player),
            )
          >[
            (
              'a stop',
              (p) => p.stop(),
              (p) => p.openAll([Media(long), Media(short)], play: true),
            ),
            (
              'a clearPlaylist',
              (p) => p.clearPlaylist(keepCurrent: true),
              (p) => p.add(Media(short)),
            ),
          ]) {
        test('$name while the resolver of the prefetch runs drops the '
            'prefetch at once, and the next one works', () async {
          var calls = 0;
          final held = Completer<void>();
          final release = Completer<void>();
          await player.setSourceResolver((request) async {
            if (_slashes(request.uri) != _slashes(short)) return null;
            if (++calls > 1) return null;
            held.complete();
            await release.future;
            return other;
          });
          await player.openAll([Media(long), Media(short)], play: true);
          await held.future.timeout(const Duration(seconds: 10));
          expect(await player.getRawProperty('prefetch-state'), 'loading');
          await drop(player);
          await waitUntil(
            () async => await player.getRawProperty('prefetch-state') == 'idle',
            timeout: const Duration(milliseconds: 500),
            reason: 'the prefetch outlived $name',
          );
          release.complete();
          await waitUntil(droppedLate, reason: 'no warning: $warnings');
          final ready = player.stream.prefetchState
              .firstWhere((s) => s == PrefetchState.ready)
              .timeout(const Duration(seconds: 10));
          await again(player);
          await ready;
          expect(calls, 2);
        }, timeout: const Timeout(Duration(seconds: 30)));
      }
    });
  });
}

/// A path with forward slashes only: on Windows mpv reports the paths it
/// opens with backslashes.
String _slashes(String path) => path.replaceAll(r'\', '/');
