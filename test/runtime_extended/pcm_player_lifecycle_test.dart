// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'dart:typed_data';

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:mpv_audio_kit/src/internals/pcm_native.dart';
import 'package:test/test.dart';

import '../_helpers/setter_test_helpers.dart';
import '../pcm/fake_pcm_native.dart';

// The player side of a live PCM source over a fake native layer: what the
// player does with the source, whatever mpv makes of the `mak-pcm://` URI.
int _id(PcmSource s) =>
    int.parse(s.toMedia().uri.substring('mak-pcm://'.length));

void main() {
  runtimeSuite(() {
    late FakePcmNative native;

    setUp(() {
      PcmSource.debugReset();
      native = FakePcmNative();
      debugPcmNativeOverride = native;
    });

    tearDown(() => debugPcmNativeOverride = null);

    const f = PcmFormat(sampleRate: 24000, channels: 1);

    test('dispose ends the sources the player holds as stopped', () async {
      final player = await buildPlayer();
      final a = await player.openPcmStream(f, play: false);
      final queued = PcmSource.create(f);
      await player.add(queued.toMedia());
      final other = PcmSource.create(f);
      await waitUntil(
        () => player.state.playlist.items.length == 2,
        reason: 'the live entries reach the playlist',
      );
      expect(player.state.playlist.items.first.isPcmStream, isTrue);
      await player.dispose();
      for (final s in [a, queued]) {
        await s.done.timeout(const Duration(seconds: 1));
        expect(s.state, PcmSourceState.stopped);
      }
      expect(native[_id(a)].state, PcmNative.stateAborted);
      expect(native[_id(a)].freed, isTrue);
      // A source the player never loaded stays the app's.
      expect(other.isDone, isFalse);
      other.abort();
    });

    for (final takeOver in ['open', 'stop']) {
      test('openPcmStream superseded by $takeOver ends as stopped', () async {
        final player = await buildPlayer();
        final opening = player.openPcmStream(f);
        if (takeOver == 'open') {
          await player.open(Media(defaultFixturePath()), play: false);
        } else {
          await player.stop();
        }
        final s = await opening;
        expect(s.state, PcmSourceState.stopped);
        await s.done.timeout(const Duration(seconds: 1));
        expect(native[_id(s)].freed, isTrue);
        await player.dispose();
      });
    }

    for (final how in ['remove', 'clearPlaylist', 'open', 'playlist-remove']) {
      test(
        'a queued source removed by $how before it plays ends as stopped',
        () async {
          final player = await buildPlayer();
          final s = PcmSource.create(f);
          s.add(Uint8List(4800));
          final fed = s.addStream(const Stream<Uint8List>.empty());
          await player.openAll([
            Media(defaultFixturePath()),
            s.toMedia(),
          ], play: false);
          await waitUntil(
            () => player.state.playlist.items.length == 2,
            reason: 'both entries reach the playlist',
          );
          switch (how) {
            case 'remove':
              await player.remove(1);
            case 'clearPlaylist':
              await player.clearPlaylist();
            case 'open':
              await player.open(Media(defaultFixturePath()), play: false);
            case 'playlist-remove':
              await player.sendRawCommand(['playlist-remove', '1']);
          }
          await s.done.timeout(const Duration(seconds: 3));
          await fed.timeout(const Duration(seconds: 1));
          await s.close();
          expect(s.state, PcmSourceState.stopped);
          await player.dispose();
        },
      );
    }

    for (final next in ['openPcmStream', 'stop']) {
      test(
        'a source replaced by $next before mpv shows it ends as stopped',
        () async {
          // The playlist observation merges changes, and mpv idle after a
          // failed load does not report a stop at all: the entry of the
          // first source can be gone before any playlist node listed it.
          for (var i = 0; i < 5; i++) {
            final player = await buildPlayer();
            try {
              final a = await player.openPcmStream(f, play: false);
              if (next == 'stop') {
                await player.stop();
              } else {
                (await player.openPcmStream(f, play: false)).abort();
              }
              await a.done.timeout(
                const Duration(seconds: 3),
                onTimeout: () => fail('round $i: ${a.state} after $next'),
              );
              expect(a.state, PcmSourceState.stopped);
              expect(native[_id(a)].freed, isTrue);
            } finally {
              await player.dispose();
            }
          }
        },
        timeout: const Timeout(Duration(seconds: 60)),
      );
    }

    test('addAudioTrack and openPlaylistFile refuse a live source', () async {
      final player = await buildPlayer();
      await openAndWaitForLoad(player, defaultFixturePath());
      final s = PcmSource.create(f);
      await expectLater(player.addAudioTrack(s.toMedia()), throwsArgumentError);
      await expectLater(
        player.openPlaylistFile(s.toMedia()),
        throwsArgumentError,
      );
      expect(s.isDone, isFalse);
      s.abort();
      await player.dispose();
    });

    test(
      'a media of a source that is done is refused before loading',
      () async {
        final player = await buildPlayer();
        final s = PcmSource.create(
          const PcmFormat(sampleRate: 24000, channels: 1),
        );
        final media = s.toMedia();
        s.abort();
        await expectLater(player.open(media), throwsArgumentError);
        await expectLater(player.add(media), throwsArgumentError);
        await expectLater(player.openAll([media]), throwsArgumentError);
        await player.dispose();
      },
    );

    test('openPcmStream on a disposed player throws', () async {
      final player = await buildPlayer();
      await player.dispose();
      await expectLater(
        player.openPcmStream(const PcmFormat(sampleRate: 24000, channels: 1)),
        throwsA(isA<PlayerDisposedException>()),
      );
      expect(native.sources, isEmpty);
    });
  });
}
