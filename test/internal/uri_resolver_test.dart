// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'package:test/test.dart';
import 'package:mpv_audio_kit/src/internals/uri_resolver.dart';

void main() {
  // Pass-through paths covered here. The `asset://` and Android
  // `content://` paths require a Flutter rootBundle / platform channel
  // context and are exercised via the integration suite in `test_app/`.
  group('resolveUri pass-through', () {
    test('plain filesystem path is returned unchanged with no dispose', () async {
      final r = await resolveUri('/tmp/example.mp3');
      expect(r.uri, '/tmp/example.mp3');
      expect(r.dispose, isNull);
    });

    test('file:// URI is returned unchanged with no dispose', () async {
      final r = await resolveUri('file:///tmp/example.mp3');
      expect(r.uri, 'file:///tmp/example.mp3');
      expect(r.dispose, isNull);
    });

    test('http(s):// URI is returned unchanged with no dispose', () async {
      final r1 = await resolveUri('https://example.com/song.mp3');
      expect(r1.uri, 'https://example.com/song.mp3');
      expect(r1.dispose, isNull);
      final r2 = await resolveUri('http://example.com/song.mp3');
      expect(r2.uri, 'http://example.com/song.mp3');
      expect(r2.dispose, isNull);
    });

    test('rtsp:// URI is returned unchanged', () async {
      final r = await resolveUri('rtsp://stream.example.com/live');
      expect(r.uri, 'rtsp://stream.example.com/live');
      expect(r.dispose, isNull);
    });

    test('content:// passes through on non-Android hosts', () async {
      // Android-only branch: every other platform must NOT try to invoke
      // the platform channel (which has no implementation here) and
      // simply pass the URI through. mpv would then reject the URI at
      // loadfile time — which is the expected error surface on host.
      final r = await resolveUri('content://media/external/audio/123');
      expect(r.uri, 'content://media/external/audio/123');
      expect(r.dispose, isNull);
    });
  });
}
