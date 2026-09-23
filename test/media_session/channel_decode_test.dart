// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
//
// Tests the native → Dart command direction: the wire maps the Swift
// `MediaSessionPlugin` emits on the event channel are decoded into typed
// `MediaSessionCommand` values by `MediaSessionChannel`. Drives the REAL
// EventChannel through a mock stream handler so the actual decode path
// runs — the controller suite stubs the channel and never exercises it,
// leaving the encode≠decode protocol seam otherwise untested.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:mpv_audio_kit/src/media_session/media_session_channel.dart';

const _eventChannel = EventChannel('mpv_audio_kit/media_session/commands');

/// Feeds [events] through the OS event channel and returns the decoded,
/// non-null commands the channel surfaces to consumers.
Future<List<MediaSessionCommand>> _decode(List<Object?> events) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockStreamHandler(
        _eventChannel,
        MockStreamHandler.inline(
          onListen: (arguments, sink) {
            for (final e in events) {
              sink.success(e);
            }
            sink.endOfStream();
          },
        ),
      );
  return MediaSessionChannel().commandStream.toList();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(_eventChannel, null);
  });

  group('MediaSessionChannel — command decode', () {
    test('decodes every payload-less command type', () async {
      final cmds = await _decode([
        {'type': 'play'},
        {'type': 'pause'},
        {'type': 'playPause'},
        {'type': 'stop'},
        {'type': 'next'},
        {'type': 'previous'},
      ]);
      expect(cmds, [
        MediaSessionCommand.play,
        MediaSessionCommand.pause,
        MediaSessionCommand.playPause,
        MediaSessionCommand.stop,
        MediaSessionCommand.next,
        MediaSessionCommand.previous,
      ]);
    });

    test('decodes seekTo / seekBy with millisecond payloads', () async {
      final cmds = await _decode([
        {'type': 'seekTo', 'positionMs': 1500},
        {'type': 'seekBy', 'offsetMs': -15000},
      ]);
      expect(cmds, [
        const MediaSessionCommand.seekTo(Duration(milliseconds: 1500)),
        const MediaSessionCommand.seekBy(Duration(milliseconds: -15000)),
      ]);
    });

    test('decodes setRepeatMode / setShuffle / setPlaybackRate', () async {
      final cmds = await _decode([
        {'type': 'setRepeatMode', 'loop': 'playlist'},
        {'type': 'setShuffle', 'shuffle': true},
        {'type': 'setPlaybackRate', 'rate': 1.5},
      ]);
      expect(cmds, [
        const MediaSessionCommand.setRepeatMode(Loop.playlist),
        const MediaSessionCommand.setShuffle(true),
        const MediaSessionCommand.setPlaybackRate(1.5),
      ]);
    });

    test('accepts an integer rate (num) for setPlaybackRate', () async {
      final cmds = await _decode([
        {'type': 'setPlaybackRate', 'rate': 2},
      ]);
      expect(cmds, [const MediaSessionCommand.setPlaybackRate(2.0)]);
    });

    test('an unknown loop name falls back to Loop.off', () async {
      final cmds = await _decode([
        {'type': 'setRepeatMode', 'loop': 'sideways'},
      ]);
      expect(cmds, [const MediaSessionCommand.setRepeatMode(Loop.off)]);
    });

    test('malformed / unknown events are filtered, never thrown', () async {
      final cmds = await _decode([
        'not-a-map',
        {'noType': true},
        {'type': 42},
        {'type': 'frobnicate'},
        {'type': 'seekTo'}, // missing positionMs
        {'type': 'seekTo', 'positionMs': '5'}, // wrong type
        {'type': 'seekBy', 'offsetMs': 1.5}, // wrong type
        {'type': 'setShuffle', 'shuffle': 'yes'}, // wrong type
        {'type': 'setRepeatMode'}, // missing loop
        {'type': 'play'}, // the one valid event survives
      ]);
      expect(cmds, [MediaSessionCommand.play]);
    });
  });
}
