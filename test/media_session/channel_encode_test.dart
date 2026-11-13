// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
//
// Tests the Dart → native direction: what `MediaSessionChannel` writes on
// the method channel, read back through the real codec by a mock handler.
// The native sides read these maps by key and by type.

import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:mpv_audio_kit/src/media_session/media_session_channel.dart';

const _methodChannel = MethodChannel('mpv_audio_kit/media_session');

const _playback = MediaSessionPlaybackSnapshot(
  playing: false,
  position: Duration.zero,
  rate: 1,
  seekable: false,
  loop: Loop.off,
  shuffle: false,
);

/// The arguments of the `enable` the channel sends for [session] and
/// [metadata], as the native side decodes them.
Future<Map<Object?, Object?>> _enableArguments({
  MediaSession session = const MediaSession(),
  MediaSessionMetadataSnapshot metadata = const MediaSessionMetadataSnapshot(),
}) async {
  Object? sent;
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_methodChannel, (call) async {
        if (call.method == 'enable') sent = call.arguments;
        return null;
      });
  await MediaSessionChannel().enable(
    session: session,
    metadata: metadata,
    playback: _playback,
  );
  return sent! as Map<Object?, Object?>;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_methodChannel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  // The contract with the native sides: each reads these maps by key. A
  // key renamed, dropped or added here must be followed on Android, Apple,
  // Linux, Windows and the web, so the set is fixed in one place.
  group('the keys of an enable', () {
    const config = {
      'actions',
      'isFavorite',
      'interruptionPolicy',
      'fastForwardIntervalMs',
      'rewindIntervalMs',
      'supportedPlaybackRates',
    };
    const metadata = {
      'title',
      'artist',
      'album',
      'artworkBytes',
      'artworkMime',
      'durationMs',
      'trackNumber',
      'discNumber',
      'albumArtist',
      'genre',
      'url',
    };
    const playback = {
      'playing',
      'positionMs',
      'rate',
      'seekable',
      'loop',
      'shuffle',
      'completed',
      'seek',
      'actualPlaying',
      'buffering',
      'hasNext',
      'hasPrevious',
      'appPauses',
    };

    Set<Object?> keys(Map<Object?, Object?> sent, String map) =>
        (sent[map]! as Map).keys.toSet();

    test('are config, metadata and playback, each with its own', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final sent = await _enableArguments();
      expect(sent.keys.toSet(), {'config', 'metadata', 'playback'});
      expect(keys(sent, 'config'), config);
      expect(keys(sent, 'metadata'), metadata);
      expect(keys(sent, 'playback'), playback);
    });

    test('add appName on Windows, and desktopEntry too on Linux', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      expect(keys(await _enableArguments(), 'config'), {...config, 'appName'});
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      expect(keys(await _enableArguments(), 'config'), {
        ...config,
        'appName',
        'desktopEntry',
      });
      for (final platform in [TargetPlatform.iOS, TargetPlatform.macOS]) {
        debugDefaultTargetPlatformOverride = platform;
        expect(keys(await _enableArguments(), 'config'), config);
      }
    });

    test('add artworkUrl only when the snapshot has one', () async {
      final sent = await _enableArguments(
        metadata: const MediaSessionMetadataSnapshot(
          artworkUrl: 'https://example.com/cover.jpg',
        ),
      );
      expect(keys(sent, 'metadata'), {...metadata, 'artworkUrl'});
    });

    test('carry the playback flags as booleans', () async {
      final sent = await _enableArguments();
      final map = sent['playback']! as Map;
      for (final key in ['completed', 'actualPlaying', 'buffering', 'seek']) {
        expect(map[key], isA<bool>(), reason: key);
      }
    });
  });

  test('supportedPlaybackRates crosses as a plain list, whatever list the '
      'app gave', () async {
    // A Float64List is a List<double>, and the codec writes it as typed
    // data: the native sides read a list of doubles and would fall back to
    // their default rates.
    final sent = await _enableArguments(
      session: MediaSession(
        supportedPlaybackRates: Float64List.fromList([1, 1.5]),
      ),
    );
    final rates = (sent['config']! as Map)['supportedPlaybackRates'];
    expect(rates, isNot(isA<TypedData>()));
    expect(rates, [1.0, 1.5]);
  });
}
