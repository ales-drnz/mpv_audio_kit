// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

// What a MediaSessionController publishes as the URL of the current item
// (MPRIS `xesam:url`), for one item after another: a controller over a
// channel that records the metadata pushes, with no player behind it.

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:mpv_audio_kit/src/media_session/media_session_channel.dart';
import 'package:mpv_audio_kit/src/media_session/media_session_controller.dart';
import 'package:mpv_audio_kit/src/media_session/media_session_inputs.dart';

final class _Channel extends MediaSessionChannel {
  MediaSessionMetadataSnapshot? last;

  @override
  Stream<MediaSessionCommand> get commandStream => const Stream.empty();

  @override
  Stream<void> get audioOutputResets => const Stream.empty();

  @override
  Future<bool> enable({
    required MediaSession session,
    required MediaSessionMetadataSnapshot metadata,
    required MediaSessionPlaybackSnapshot playback,
  }) async {
    last = metadata;
    return true;
  }

  @override
  Future<void> updateConfig(MediaSession session) async {}

  @override
  Future<void> updateMetadata(MediaSessionMetadataSnapshot metadata) async =>
      last = metadata;

  @override
  Future<void> updatePlayback(MediaSessionPlaybackSnapshot playback) async {}

  @override
  Future<void> disable() async {}
}

/// The URL a session publishes for the item it is given.
final class SessionUrlProbe {
  SessionUrlProbe._();

  static const _real = MethodChannel('mpv_audio_kit/media_session');

  final _channel = _Channel();
  final _metadata = StreamController<Map<String, String>>.broadcast();
  final _never = StreamController<Never>.broadcast();
  late final MediaSessionController _controller;
  PlayerState _state = const PlayerState(
    settings: PlayerSettings(mediaSession: MediaSession()),
  );
  int _pushes = 0;

  /// A probe over a new controller. [close] ends it.
  static Future<SessionUrlProbe> open() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // The controller's own channel answers nothing here.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_real, (_) async => null);
    final probe = SessionUrlProbe._();
    final never = probe._never.stream;
    probe._controller = await MediaSessionController.create(
      stateSnapshot: () => probe._state,
      inputs: MediaSessionInputs(
        playWhenReady: never.cast(),
        playing: never.cast(),
        buffering: never.cast(),
        rate: never.cast(),
        seekCompleted: never.cast(),
        seekable: never.cast(),
        loop: never.cast(),
        shuffle: never.cast(),
        duration: never.cast(),
        metadata: probe._metadata.stream,
        coverArt: never.cast(),
        mediaTitle: never.cast(),
        mediaSession: never.cast(),
      ),
      onCommand: (_) {},
      channel: probe._channel,
    );
    return probe;
  }

  /// The URL published while [uri] is the current item, `null` when the
  /// session publishes none.
  Future<String?> urlOf(String uri) async {
    // A title of its own, so every item is a push: the controller sends
    // no metadata equal to the last.
    final tags = {'title': 'item ${_pushes++}'};
    _state = PlayerState(
      playback: PlaybackState(playlist: Playlist([Media(uri)])),
      file: FileState(metadata: tags),
      settings: const PlayerSettings(mediaSession: MediaSession()),
    );
    _channel.last = null;
    _metadata.add(tags);
    await pumpEventQueue();
    final pushed = _channel.last;
    if (pushed == null) fail('no metadata push for $uri');
    expect(pushed.title, tags['title']);
    return pushed.url;
  }

  /// Ends the controller and the streams.
  Future<void> close() async {
    await _controller.dispose();
    await _metadata.close();
    await _never.close();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_real, null);
  }
}
