// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'package:mpv_audio_kit/src/internals/uri_resolver.dart';
import 'package:test/test.dart';

void main() {
  // Pass-through paths covered here. The `asset://` and Android
  // `content://` paths require a Flutter rootBundle / platform channel
  // context and are exercised via the integration suite in `test_app/`.
  group('resolveUri pass-through', () {
    test('plain filesystem path is returned unchanged with no dispose',
        () async {
      final r = await resolveUri('/tmp/example.mp3');
      expect(r.uri, '/tmp/example.mp3');
      expect(r.dispose, isNull);
    });

    test('file:// URI becomes the path mpv stores, with no dispose',
        () async {
      final r = await resolveUri('file:///tmp/example%20one.mp3');
      expect(r.uri, '/tmp/example one.mp3');
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

  // Expected values follow mpv's mp_file_url_to_filename (stream_file.c).
  group('fileUrlToPath', () {
    test('drops the scheme whatever its case', () {
      expect(fileUrlToPath('file:///a/b.flac'), '/a/b.flac');
      expect(fileUrlToPath('FILE:///a/b.flac'), '/a/b.flac');
    });

    test('decodes %NN escapes byte by byte, UTF-8 included', () {
      expect(fileUrlToPath('file:///a%20b/c%2Cd.flac'), '/a b/c,d.flac');
      expect(fileUrlToPath('file:///m%C3%BAsica.flac'), '/música.flac');
      expect(fileUrlToPath('file:///%41%6a'), '/Aj');
    });

    test('keeps malformed escapes as they are', () {
      expect(fileUrlToPath('file:///a%zzb'), '/a%zzb');
      expect(fileUrlToPath('file:///a%-1b'), '/a%-1b');
      expect(fileUrlToPath('file:///a%2'), '/a%2');
      expect(fileUrlToPath('file:///a%'), '/a%');
      // mpv skips the whole malformed triplet, so `%z%41` keeps `%41`.
      expect(fileUrlToPath('file:///%z%41'), '/%z%41');
    });

    test('drops the slash before a Windows drive letter on Windows only',
        () {
      expect(fileUrlToPath('file:///C:/a%20b.flac', windows: true),
          'C:/a b.flac',);
      expect(fileUrlToPath('file:///C:/a%20b.flac', windows: false),
          '/C:/a b.flac',);
      expect(fileUrlToPath('file:///a/b.flac', windows: true), '/a/b.flac');
    });

    test('returns null for every other URI', () {
      expect(fileUrlToPath('/a/b.flac'), isNull);
      expect(fileUrlToPath('https://x.org/a%20b.mp3'), isNull);
      expect(fileUrlToPath('asset://audio/a.mp3'), isNull);
      expect(fileUrlToPath('file:'), isNull);
    });
  });
}
