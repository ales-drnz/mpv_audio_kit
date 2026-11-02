// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

// doc/playback.md and doc/hooks.md say the headers of one entry go with
// its HLS playlist and every segment, and never with other entries. A local
// HLS server logs the headers of every request.

@TestOn('mac-os || linux || windows')
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

import '../_helpers/range_http_server.dart';
import '../_helpers/setter_test_helpers.dart';

void main() {
  final dir = '${Directory.current.path}/test/fixtures';
  final aacPath = '$dir/codec/aac_adts_44100.aac';
  const segments = 4;

  runtimeSuite(() {
    late Player player;
    late RangeHttpServer server;

    setUp(() async {
      final aac = File(aacPath).readAsBytesSync();
      final playlist = StringBuffer(
        '#EXTM3U\n#EXT-X-VERSION:3\n#EXT-X-TARGETDURATION:2\n'
        '#EXT-X-MEDIA-SEQUENCE:0\n',
      );
      for (var i = 0; i < segments; i++) {
        playlist.write('#EXTINF:1.044900,\ns$i.aac\n');
      }
      playlist.write('#EXT-X-ENDLIST\n');
      server = await RangeHttpServer.start({
        'a.m3u8': Uint8List.fromList(playlist.toString().codeUnits),
        for (var i = 0; i < segments; i++) 's$i.aac': aac,
        'b.aac': aac,
      });
      player = await buildPlayer();
      await player.setAudioNullUntimed(true);
    });

    tearDown(() async {
      await player.dispose();
      await server.close();
    });

    // Plays [medias] to the park of the last one.
    Future<void> playToEnd(List<Media> medias) async {
      final completed = player.stream.completed
          .firstWhere((c) => c)
          .timeout(const Duration(seconds: 30));
      await player.openAll(medias, play: true);
      await completed;
    }

    // Every GET of the playlist and its segments, at least one each.
    List<ServedRequest> hlsGets() {
      final gets = [
        ...server.gets('/a.m3u8'),
        for (var i = 0; i < segments; i++) ...server.gets('/s$i.aac'),
      ];
      expect(server.gets('/a.m3u8'), isNotEmpty, reason: server.describe());
      for (var i = 0; i < segments; i++) {
        expect(server.gets('/s$i.aac'), isNotEmpty, reason: server.describe());
      }
      return gets;
    }

    test('Media.httpHeaders go with the playlist and every segment, and '
        'not with the next entry', () async {
      await playToEnd([
        Media(server.url('a.m3u8'), httpHeaders: const {'X-Mak-Token': 'abc'}),
        Media(server.url('b.aac')),
      ]);
      for (final r in hlsGets()) {
        expect(r.headers['x-mak-token'], 'abc', reason: '$r');
      }
      final next = server.gets('/b.aac');
      expect(next, isNotEmpty, reason: server.describe());
      for (final r in next) {
        expect(r.headers.containsKey('x-mak-token'), isFalse, reason: '$r');
      }
    }, timeout: const Timeout(Duration(seconds: 60)));

    test('file-local http-header-fields set in Hook.load go with the '
        'playlist and every segment', () async {
      await player.registerHook(Hook.load);
      final sub = player.stream.hook.listen((event) async {
        if (event.hook != Hook.load) return;
        try {
          await player.setRawProperty(
            'file-local-options/http-header-fields',
            'X-Mak-Token: def',
          );
        } finally {
          await player.continueHook(event.id);
        }
      });
      addTearDown(sub.cancel);
      await playToEnd([Media(server.url('a.m3u8'))]);
      for (final r in hlsGets()) {
        expect(r.headers['x-mak-token'], 'def', reason: '$r');
      }
    }, timeout: const Timeout(Duration(seconds: 60)));
  });
}
