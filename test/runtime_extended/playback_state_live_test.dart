// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

import '../_helpers/range_http_server.dart';
import '../_helpers/setter_test_helpers.dart';

// `idle` means no file is loaded, and a UI hides its transport controls on
// it. It used to be derived from a zero duration, so every load flashed
// `idle` between the end of loading and the first duration report, and a
// stream with no known duration would read as idle when paused.

void main() {
  const fixture = 'test/fixtures/codec/aac_adts_44100.aac';
  runtimeSuite(fixturePath: fixture, () {
    test('a stream is never idle while loaded, playing or paused', () async {
      // ADTS frames concatenate: the fixture repeated, sent as a throttled
      // chunked body with no length, like a radio stream.
      final frames = File(fixture).readAsBytesSync();
      final body = BytesBuilder(copy: false);
      for (var i = 0; i < 30; i++) {
        body.add(frames);
      }
      final server = await RangeHttpServer.start(
        {'live.aac': body.takeBytes()},
        mode: ServeMode.chunked,
        // About twice the bitrate: the body never ends while the test runs.
        bytesPerSecond: 32000,
      );
      final player = await buildPlayer();
      final states = <MpvPlaybackState>[];
      final sub = player.stream.playbackState.listen(states.add);
      try {
        await player.open(Media(server.url('live.aac')), play: true);
        await waitUntil(
          () => states.isNotEmpty && states.last == MpvPlaybackState.playing,
          reason: 'the stream starts playing: $states',
        );
        await player.pause();
        await waitUntil(
          () => states.last != MpvPlaybackState.playing,
          reason: 'pause reaches playbackState',
        );
        // Let any later emission land.
        await Future<void>.delayed(const Duration(milliseconds: 200));
        expect(states.last, MpvPlaybackState.paused);

        final loaded = states.skipWhile((s) => s == MpvPlaybackState.idle);
        expect(
          loaded,
          isNot(contains(MpvPlaybackState.idle)),
          reason: 'idle while the stream was loaded: $states',
        );

        await player.stop();
        await waitUntil(
          () => states.last == MpvPlaybackState.idle,
          reason: 'stop unloads the stream: idle',
        );
      } finally {
        await sub.cancel();
        await player.dispose();
        await server.close();
      }
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}
