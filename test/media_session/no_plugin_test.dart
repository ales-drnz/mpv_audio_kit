// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
//
// A platform without a media session plugin (Tizen, webOS): nothing
// answers the method channel or the event channel. Turning the session on
// there does nothing at all: Flutter reports no error for the event
// channel, and no artwork URL is loaded for a session that does not exist.
// The test binding with no mock handler is such a platform.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:mpv_audio_kit/src/media_session/media_session_channel.dart';
import 'package:mpv_audio_kit/src/media_session/media_session_controller.dart';
import 'package:mpv_audio_kit/src/media_session/media_session_inputs.dart';

const _playback = MediaSessionPlaybackSnapshot(
  playing: false,
  position: Duration.zero,
  rate: 1,
  seekable: false,
  loop: Loop.off,
  shuffle: false,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('enable says no native side answered', () async {
    final native = await MediaSessionChannel().enable(
      session: const MediaSession(),
      metadata: const MediaSessionMetadataSnapshot(title: 'Song'),
      playback: _playback,
    );
    expect(native, isFalse);
  });

  test('the session without a plugin reports no error and loads no '
      'artwork', () async {
    final reported = <FlutterErrorDetails>[];
    final previous = FlutterError.onError;
    FlutterError.onError = reported.add;
    addTearDown(() => FlutterError.onError = previous);

    final metadata = StreamController<Map<String, String>>.broadcast();
    final playWhenReady = StreamController<bool>.broadcast();
    addTearDown(metadata.close);
    addTearDown(playWhenReady.close);
    const state = PlayerState(
      playback: PlaybackState(
        playlist: Playlist([
          Media(
            'https://nd.example/rest/stream.view?id=1',
            extras: {'art': 'https://nd.example/rest/getCoverArt.view?t=tok'},
          ),
        ]),
      ),
      file: FileState(metadata: {'title': 'Song'}),
      settings: PlayerSettings(mediaSession: MediaSession()),
    );
    final fetched = <String>[];
    final commands = <MediaSessionCommand>[];
    var resets = 0;

    final controller = await MediaSessionController.create(
      stateSnapshot: () => state,
      inputs: MediaSessionInputs(
        playWhenReady: playWhenReady.stream,
        playing: const Stream.empty(),
        buffering: const Stream.empty(),
        rate: const Stream.empty(),
        seekCompleted: const Stream.empty(),
        seekable: const Stream.empty(),
        loop: const Stream.empty(),
        shuffle: const Stream.empty(),
        duration: const Stream.empty(),
        metadata: metadata.stream,
        coverArt: const Stream.empty(),
        mediaTitle: const Stream.empty(),
        mediaSession: const Stream.empty(),
      ),
      onCommand: commands.add,
      onAudioOutputReset: () => resets++,
      artworkFetcher: (url, _) async {
        fetched.add(url);
        return null;
      },
    );
    await pumpEventQueue();
    expect(metadata.hasListener, isFalse, reason: 'nothing to push to');

    metadata.add(const {'title': 'Song'});
    playWhenReady.add(true);
    controller.appPaused();
    await pumpEventQueue();
    await controller.dispose();
    await pumpEventQueue();

    expect(
      reported.map((d) => d.exceptionAsString()),
      isEmpty,
      reason: 'no event channel is activated without a plugin',
    );
    expect(fetched, isEmpty, reason: 'no session, so no cover to load');
    expect(commands, isEmpty);
    expect(resets, 0);
  });
}
