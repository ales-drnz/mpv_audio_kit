// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
//
// `downloadArtwork` on the app's assets and on Android's ContentResolver,
// through the test binding (artwork_fetcher_test.dart runs without it: the
// binding answers every HTTP request with a 400).

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/src/media_session/artwork_fetcher.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  group('an Android content cover', () {
    const channel = MethodChannel('mpv_audio_kit');
    // The calls the plugin got, and what it answers.
    late List<MethodCall> calls;
    late Object? Function(MethodCall) answer;

    setUp(() {
      calls = [];
      answer = (_) => null;
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return answer(call);
      });
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
    });
    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
      messenger.setMockMethodCallHandler(channel, null);
    });

    test('a content:// or android.resource:// URL is read by the '
        'ContentResolver, with the 20 MB limit', () async {
      answer = (_) => {
        'bytes': Uint8List.fromList(const [7, 8]),
        'mimeType': 'image/jpeg',
      };
      final art = Uri.parse('content://media/external/audio/albumart/12');
      final cover = await downloadArtwork(art);
      expect(cover?.bytes, [7, 8]);
      expect(cover?.mimeType, 'image/jpeg');

      final res = Uri.parse('android.resource://com.example/drawable/cover');
      expect((await downloadArtwork(res))?.bytes, [7, 8]);
      expect(calls.map((c) => c.method), ['readArtwork', 'readArtwork']);
      expect(calls.map((c) => c.arguments), [
        {'uri': '$art', 'maxBytes': 20 * 1024 * 1024},
        {'uri': '$res', 'maxBytes': 20 * 1024 * 1024},
      ]);
    });

    test('takes the MIME type of the extension when the provider '
        'names none', () async {
      answer = (_) => {
        'bytes': Uint8List.fromList(const [1]),
        'mimeType': null,
      };
      final cover = await downloadArtwork(
        Uri.parse('content://com.example.files/covers/a.png'),
      );
      expect(cover?.mimeType, 'image/png');
    });

    test('returns null when the provider has nothing or refuses', () async {
      final art = Uri.parse('content://media/external/audio/albumart/12');
      expect(await downloadArtwork(art), isNull);
      answer = (_) => {'bytes': Uint8List(0), 'mimeType': 'image/jpeg'};
      expect(await downloadArtwork(art), isNull);
      answer = (_) => throw PlatformException(code: 'ERROR');
      expect(await downloadArtwork(art), isNull);
    });

    test('is not read on the other platforms', () async {
      answer = (_) => {
        'bytes': Uint8List.fromList(const [7]),
        'mimeType': 'image/jpeg',
      };
      for (final platform in [
        TargetPlatform.linux,
        TargetPlatform.windows,
        TargetPlatform.iOS,
        TargetPlatform.macOS,
      ]) {
        debugDefaultTargetPlatformOverride = platform;
        expect(
          await downloadArtwork(Uri.parse('content://media/x/1')),
          isNull,
          reason: '$platform',
        );
      }
      expect(calls, isEmpty);
    });
  });

  group('an asset:// cover', () {
    // The asset keys asked of the bundle, and the assets it has.
    late List<String> asked;
    late Map<String, Uint8List> assets;

    setUp(() {
      asked = [];
      assets = {};
      messenger.setMockMessageHandler('flutter/assets', (message) async {
        final key = utf8.decode(message!.buffer.asUint8List());
        asked.add(key);
        final bytes = assets[key];
        return bytes == null ? null : ByteData.sublistView(bytes);
      });
    });
    tearDown(() => messenger.setMockMessageHandler('flutter/assets', null));

    test('is read from the bundle, with the MIME type of its '
        'extension', () async {
      assets['assets/covers/default.webp'] = Uint8List.fromList(const [9]);
      final cover = await downloadArtwork(
        Uri.parse('asset:///assets/covers/default.webp'),
      );
      expect(cover?.bytes, [9]);
      expect(cover?.mimeType, 'image/webp');
      // The key as Media takes it, with two slashes or three.
      final two = Uri.parse('asset://assets/covers/default.webp');
      expect((await downloadArtwork(two))?.bytes, [9]);
      expect(asked, [
        'assets/covers/default.webp',
        'assets/covers/default.webp',
      ]);
    });

    test('returns null when it is missing, empty or over 20 MB', () async {
      expect(await downloadArtwork(Uri.parse('asset:///none.png')), isNull);
      assets['empty.png'] = Uint8List(0);
      expect(await downloadArtwork(Uri.parse('asset:///empty.png')), isNull);
      assets['big.png'] = Uint8List(20 * 1024 * 1024 + 1);
      expect(await downloadArtwork(Uri.parse('asset:///big.png')), isNull);
    });
  });
}
