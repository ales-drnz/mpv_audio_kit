// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// The OS media session on the web: the web plugin serves the channels the
// native plugins serve, on navigator.mediaSession. What a headless browser
// can show is checked here: the metadata and artwork the page sets, the
// playback state, the action handlers (called as the OS would) and the
// commands they send, the page's output routed through an <audio> element
// while the session is on, and the artwork download with and without CORS
// (net_server.dart, test/web/with_net_server.sh). Whether the browser then
// shows its controls is a matter of the desktop or phone it runs on.

@TestOn('browser')
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:mpv_audio_kit/src/backend/web_backend.dart';
import 'package:mpv_audio_kit/src/media_session/artwork_download_web.dart';
import 'package:mpv_audio_kit/src/media_session/media_session_channel.dart';
import 'package:mpv_audio_kit/src/web/mpv_audio_kit_web.dart';

import '../_helpers/parity_scenario.dart';
import 'web_module_helper.dart';

const String _net = String.fromEnvironment('MAK_WEB_NET');

@JS('navigator.mediaSession')
external JSObject get _session;

/// The handlers the page sets, by action, as the OS would call them.
final Map<String, JSFunction?> _handlers = {};

/// Records every setActionHandler call on navigator.mediaSession.
void _captureHandlers() {
  final original = _session['setActionHandler'] as JSFunction;
  _session['setActionHandler'] = ((String action, JSFunction? handler) {
    _handlers[action] = handler;
    original.callAsFunction(_session, action.toJS, handler);
  }).toJS;
}

JSObject? get _metadata => _session['metadata'] as JSObject?;

String? _field(String name) => (_metadata?[name] as JSString?)?.toDart;

String? get _artworkSrc {
  final artwork = _metadata?['artwork'] as JSArray<JSObject>?;
  final list = artwork?.toDart ?? const <JSObject>[];
  return list.isEmpty ? null : (list.first['src'] as JSString).toDart;
}

String get _playbackState => (_session['playbackState'] as JSString).toDart;

void _call(String action, [Map<String, Object> details = const {}]) {
  final js = JSObject()..['action'] = action.toJS;
  details.forEach((k, v) => js[k] = (v as num).toJS);
  _handlers[action]!.callAsFunction(null, js);
}

const _playback = MediaSessionPlaybackSnapshot(
  playing: true,
  position: Duration(seconds: 3),
  rate: 1,
  seekable: true,
  loop: Loop.off,
  shuffle: false,
);

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    _captureHandlers();
    // A test page drops every platform message: as flutterTester, but
    // with the messages delivered, so the plugin's channels work.
    ui_web.TestEnvironment.setUp(
      const ui_web.TestEnvironment(
        forceTestFonts: true,
        disableFontFallbacks: true,
        keepSemanticsDisabledOnUpdate: true,
        defaultToTestUrlStrategy: true,
      ),
    );
    MpvAudioKitWeb.registerWith(webPluginRegistrar);
    // What the generated plugin registrant of an app does.
    webPluginRegistrar.registerMessageHandler();
    await loadTestModule();
    MpvAudioKit.ensureInitialized(hotRestartCleanup: false);
  });

  test('the channel sets the metadata, the state and the handlers, which '
      'send the commands', () async {
    final channel = MediaSessionChannel();
    final commands = <MediaSessionCommand>[];
    final sub = channel.commandStream.listen(commands.add);
    addTearDown(sub.cancel);
    await channel.enable(
      session: MediaSession(
        actions: MediaAction.values.toSet(),
        fastForwardInterval: const Duration(seconds: 10),
      ),
      metadata: MediaSessionMetadataSnapshot(
        title: 'Title',
        artist: 'Artist',
        album: 'Album',
        duration: const Duration(seconds: 60),
        artwork: CoverArt(
          bytes: Uint8List.fromList([1, 2, 3]),
          mimeType: 'image/png',
        ),
      ),
      playback: _playback,
    );
    expect(
      [_field('title'), _field('artist'), _field('album')],
      ['Title', 'Artist', 'Album'],
    );
    expect(_artworkSrc, startsWith('blob:'));
    expect(_playbackState, 'playing');
    for (final action in [
      'play',
      'pause',
      'nexttrack',
      'previoustrack',
      'seekto',
      'seekforward',
      'seekbackward',
      'stop',
    ]) {
      expect(_handlers[action], isNotNull, reason: action);
    }

    _call('pause');
    _call('nexttrack');
    _call('seekto', {'seekTime': 12.5});
    _call('seekforward');
    _call('seekbackward', {'seekOffset': 5});
    await waitUntil(() => commands.length == 5, what: 'the commands');
    expect(commands, [
      MediaSessionCommand.pause,
      MediaSessionCommand.next,
      const MediaSessionCommand.seekTo(Duration(milliseconds: 12500)),
      const MediaSessionCommand.seekBy(Duration(seconds: 10)),
      const MediaSessionCommand.seekBy(Duration(seconds: -5)),
    ]);

    await channel.updateMetadata(
      const MediaSessionMetadataSnapshot(
        title: 'Next',
        artworkUrl: 'https://example.com/cover.jpg',
      ),
    );
    expect(_field('title'), 'Next');
    expect(_artworkSrc, 'https://example.com/cover.jpg');
    await channel.updatePlayback(
      const MediaSessionPlaybackSnapshot(
        playing: false,
        position: Duration.zero,
        rate: 1,
        seekable: false,
        loop: Loop.off,
        shuffle: false,
      ),
    );
    expect(_playbackState, 'paused');

    await channel.disable();
    expect(_metadata, isNull);
    expect(_playbackState, 'none');
    expect(_handlers['play'], isNull);
  });

  test('a player with a media session plays through an <audio> element, '
      'and back to the destination without one', () async {
    final player = Player();
    addTearDown(player.dispose);
    await player.ready;
    await player.setRawProperty('ao', 'null');
    await player.setMediaSession(const MediaSession());
    await player.open(
      Media(testUrl('fixtures/sine_5s.flac'), extras: {'title': 'Sine'}),
      play: false,
    );
    await waitUntil(() => _field('title') == 'Sine', what: 'the title');
    final output = await webAudioOutput();
    expect(output.element, isNotNull);
    expect(output.element!['srcObject'], isNotNull);
    await player.setMediaSession(null);
    await waitUntil(() => output.element == null, what: 'the route back');
    expect(_metadata, isNull);
  });

  group('artwork', skip: _net.isEmpty ? 'needs with_net_server.sh' : false, () {
    test('a URL with CORS is downloaded, one without is not', () async {
      final cover = await downloadArtwork(
        Uri.parse('$_net/file/sine_with_cover.flac'),
      );
      expect(cover?.bytes.length, 15477);
      expect(cover?.mimeType, 'application/octet-stream');
      expect(
        await downloadArtwork(Uri.parse('$_net/nocors/sine_with_cover.flac')),
        isNull,
      );
      expect(await downloadArtwork(Uri.parse('file:///cover.png')), isNull);
    });

    test('the session shows a downloaded cover as a blob, and hands the '
        'browser a URL it could not download', () async {
      final player = Player();
      addTearDown(player.dispose);
      await player.ready;
      await player.setRawProperty('ao', 'null');
      await player.setMediaSession(
        MediaSession(
          artwork: MediaSessionArtwork.uri(
            Uri.parse('$_net/file/sine_with_cover.flac'),
          ),
        ),
      );
      await player.open(Media(testUrl('fixtures/sine_5s.flac')), play: false);
      await waitUntil(
        () => _artworkSrc?.startsWith('blob:') ?? false,
        what: 'the downloaded cover',
      );
      const uncors = '$_net/nocors/sine_with_cover.flac';
      await player.setMediaSession(
        MediaSession(artwork: MediaSessionArtwork.uri(Uri.parse(uncors))),
      );
      await waitUntil(() => _artworkSrc == uncors, what: 'the URL');
      // The download failed: the URL stays.
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(_artworkSrc, uncors);
    });
  });
}
