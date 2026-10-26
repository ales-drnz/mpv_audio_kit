// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

// The waveform of an HTTP stream that cannot seek and does not tell its
// length (#29), such as a transcode a music server sends chunked, without
// byte ranges. With Media.waveformDurationHint, libmpv-r20 decodes it from
// mpv's cache as it downloads, and the waveform turns final before
// playback; without it the waveform grows from playback.
//
// A loopback server (test/_helpers/range_http_server.dart) sends
// vbr_no_xing.mp3 chunked, throttled to about 4.5 s: an MP3 without a Xing
// header, whose length mpv cannot tell without the file size. It decodes
// to 266112 samples at 44.1 kHz, 6.034 s.

@TestOn('linux || mac-os || windows')
library;

import 'dart:io';

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

import '../_helpers/range_http_server.dart';
import '../_helpers/setter_test_helpers.dart';

const _name = 'transcode.mp3';

/// The length the fixture decodes to.
const _length = Duration(microseconds: 6034286);

/// The native state of the analyzer (`ready`, `decoding`, `rolling`, ...),
/// or `null` when there is none.
Future<String?> _nativeState(Player player) async {
  final node = await player.getRawPropertyNode('waveform-data');
  return node is Map ? node['state'] as String? : null;
}

void main() {
  final fixture =
      '${Directory.current.path}/test/fixtures/extra/vbr_no_xing.mp3';

  analysisSuite(extraFixtures: [fixture], () {
    late RangeHttpServer server;
    late Player player;
    final waves = <WaveformData?>[];

    setUp(() async {
      server = await RangeHttpServer.start(
        {_name: File(fixture).readAsBytesSync()},
        mode: ServeMode.chunked,
        bytesPerSecond: 16 * 1024,
      );
      player = await buildPlayer();
      waves.clear();
      final sub = player.stream.waveform.listen(waves.add);
      addTearDown(() async {
        await sub.cancel();
        await player.dispose();
        await server.close();
      });
    });

    libmpvReleaseGroup(
      20,
      'The duration hint of a stream without a length',
      () {
        test(
          'fills the waveform from the cache, final before playback',
          () async {
            await player.open(
              Media(server.url(_name), waveformDurationHint: _length),
              play: false,
            );
            await waitUntil(
              () async => await _nativeState(player) == 'ready',
              timeout: const Duration(seconds: 20),
              reason: 'the analysis did not turn ready',
            );
            await waitUntil(
              () => waves.isNotEmpty && waves.last?.decoding == false,
              reason: 'the final envelope did not come',
            );
            final w = waves.last!;
            expect(w.live, isFalse);
            expect(w.duration, _length);
            // The filled bins run from the start with no hole; the axis ends
            // at most a bin or two after the audio.
            final empty = w.filled.indexWhere((b) => b == 0);
            expect(
              empty < 0 || w.filled.skip(empty).every((b) => b == 0),
              isTrue,
              reason: 'a hole in the envelope',
            );
            expect(
              w.filled.where((b) => b != 0).length,
              greaterThanOrEqualTo(w.bins - 2),
              reason: 'the bins of the stream are filled',
            );
            expect(
              waves.whereType<WaveformData>().where((w) => w.decoding),
              isNotEmpty,
              reason: 'partial envelopes while the stream downloads',
            );
            expect(
              server.gets('/$_name'),
              hasLength(1),
              reason: 'one download\n${server.describe()}',
            );
            expect(player.state.position, Duration.zero);
          },
          timeout: const Timeout(Duration(seconds: 40)),
        );

        test('entries with hints of their own still open ahead', () async {
          // The other per-entry options keep an entry that differs in them
          // from opening ahead; the hint does not.
          await player.setPrefetchPlaylist(true);
          final states = <PrefetchState>[];
          final sub = player.stream.prefetchState.listen(states.add);
          addTearDown(sub.cancel);
          final path = defaultFixturePath();
          await player.openAll([
            Media(path, waveformDurationHint: const Duration(seconds: 1)),
            Media(path, waveformDurationHint: const Duration(seconds: 2)),
          ], play: true);
          await waitUntil(
            () =>
                player.state.playlist.index == 1 &&
                player.state.position > const Duration(milliseconds: 200),
            timeout: const Duration(seconds: 10),
            reason: 'the second entry never played',
          );
          expect(states, contains(PrefetchState.used), reason: '$states');
          expect(
            await player.getRawProperty('waveform-duration-hint'),
            '2.000000',
            reason: 'the second entry plays with its own hint',
          );
        }, timeout: const Timeout(Duration(seconds: 30)));
      },
    );

    test('without a hint the waveform grows from playback', () async {
      await player.open(Media(server.url(_name)), play: false);
      await waitUntil(
        () => server.gets('/$_name').any((r) => r.completed),
        timeout: const Duration(seconds: 20),
        reason: 'the stream was not sent',
      );
      await Future<void>.delayed(const Duration(seconds: 1));
      expect(await _nativeState(player), 'rolling');
      expect(waves.whereType<WaveformData>().where((w) => !w.live), isEmpty);
    }, timeout: const Timeout(Duration(seconds: 40)));
  });
}
