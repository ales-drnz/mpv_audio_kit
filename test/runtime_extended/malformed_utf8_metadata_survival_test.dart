// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'dart:async';
import 'dart:io';

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

import '../_helpers/setter_test_helpers.dart';

// Malformed UTF-8 in mpv-delivered metadata must not kill the event
// pipeline.
//
// SHOUTcast/Icecast servers classically emit latin-1 in their ICY
// response headers (`icy-name`, `icy-genre`, …). mpv copies those
// header values into tags verbatim — unlike the `StreamTitle` packet,
// they get NO charset conversion — and ICY tags arrive as timed
// metadata, which also bypasses the demuxer-open charset pass. So a
// station name containing the raw latin-1 byte 0xE9 ("é") reaches the
// client API, and the Dart side, as invalid UTF-8 inside the
// `metadata` property node.
//
// (Static container tags — e.g. a latin-1 ID3v1 title — do NOT
// reproduce this: mpv's `--metadata-codepage=auto` pass at demuxer
// open re-encodes them to valid UTF-8 before the client sees them.
// Verified empirically: an ID3v1 title byte 0xE9 arrives as U+00E9.)
//
// The contract under test: one malformed metadata string must not
// freeze the player. The tag still surfaces (replacement characters
// are fine) and the property pipeline stays alive afterwards.

const int _latin1EAcute = 0xE9; // 'é' in latin-1 — invalid UTF-8 on its own.

/// MP3 payload for the fake radio stream: the stock 1 s MP3 fixture
/// with its leading ID3v2 block stripped, repeated to ~30 s of audio.
List<int> buildStreamBody() {
  final src = File(
    '${Directory.current.path}/test/fixtures/codec/mp3_44100_stereo.mp3',
  ).readAsBytesSync();
  var body = src as List<int>;
  if (src.length > 10 && src[0] == 0x49 && src[1] == 0x44 && src[2] == 0x33) {
    final size = (src[6] << 21) | (src[7] << 14) | (src[8] << 7) | src[9];
    final total = 10 + size + ((src[5] & 0x10) != 0 ? 10 : 0);
    body = src.sublist(total);
  }
  return [for (var i = 0; i < 30; i++) ...body];
}

/// Minimal SHOUTcast-style server: replies to any request with an
/// `audio/mpeg` stream whose `icy-name` response header carries the
/// raw latin-1 byte 0xE9 — exactly what legacy radio servers send.
/// The header is built as raw bytes on purpose; no Dart string ever
/// holds the malformed sequence.
Future<ServerSocket> startIcyServer(List<int> mp3Body) async {
  final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((socket) {
    var responded = false;
    socket.listen(
      (_) {
        if (responded) return;
        responded = true;
        socket.add([
          ...'HTTP/1.0 200 OK\r\n'.codeUnits,
          ...'Content-Type: audio/mpeg\r\n'.codeUnits,
          ...'icy-name: Caf'.codeUnits,
          _latin1EAcute,
          ...' FM\r\n'.codeUnits,
          ...'\r\n'.codeUnits,
          ...mp3Body,
        ]);
        // Keep the socket open: a radio stream has no EOF. The server
        // close in tearDownAll tears it down.
      },
      onError: (Object _) {},
      cancelOnError: true,
    );
  });
  return server;
}

void main() {
  late ServerSocket server;
  late String streamUrl;
  late Player player;

  runtimeSuite(
    fixturePath:
        '${Directory.current.path}/test/fixtures/codec/mp3_44100_stereo.mp3',
    () {
      setUpAll(() async {
        server = await startIcyServer(buildStreamBody());
        streamUrl = 'http://${server.address.address}:${server.port}/stream';
        player = await buildPlayer();
      });

      tearDownAll(() async {
        await player.dispose();
        await server.close();
      });

      test('player survives an ICY station name with invalid UTF-8 '
          '(tag surfaces, pipeline stays alive)', () async {
        // Pre-subscribe BEFORE open — emits can land synchronously relative
        // to a late firstWhere (see CLAUDE.md, Common patterns).
        final icyArrived = player.stream.metadata
            .firstWhere((m) => m.keys.any((k) => k.toLowerCase() == 'icy-name'))
            .timeout(
              const Duration(seconds: 20),
              onTimeout: () => fail(
                'icy-name never surfaced — the metadata stream froze after mpv '
                'delivered a tag value with invalid UTF-8 (the event isolate '
                'presumably died decoding it)',
              ),
            );

        await player.open(Media(streamUrl), play: true);

        // (a) The malformed tag still surfaces — replacement characters are
        // acceptable, a frozen stream is not.
        final md = await icyArrived;
        final icyName = md.entries
            .firstWhere((e) => e.key.toLowerCase() == 'icy-name')
            .value;
        expect(
          icyName,
          startsWith('Caf'),
          reason: 'tag value must survive the bridge (lenient decode is fine)',
        );

        // (b) The pipeline is still alive AFTER the malformed string was
        // processed: position updates must keep flowing.
        final mark = player.state.position;
        await player.stream.position
            .firstWhere((p) => p > mark + const Duration(milliseconds: 300))
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () => fail(
                'position stopped advancing — property/event pipeline frozen '
                'after the malformed UTF-8 metadata was dispatched',
              ),
            );
      }, timeout: const Timeout(Duration(seconds: 50)));
    },
  );
}
