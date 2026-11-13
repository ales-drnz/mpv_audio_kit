// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

// The journey of a file name through the player, with libmpv: a Media
// opened by its path, by the URL an app makes of it and by file:// with
// the name raw comes back from the playlist as the Media the caller
// passed, and mpv opens that very file. One file for each piece that
// broke something once (test/_helpers/file_names.dart); the pure half of
// the journey is in test/internal/uri_resolver_property_test.dart.
//
// POSIX hosts: Windows forbids most of these names, and its paths have
// cases of their own in file_url_media_test.dart.

@TestOn('mac-os || linux')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

import '../_helpers/file_names.dart';
import '../_helpers/setter_test_helpers.dart';

void main() {
  final source = defaultFixturePath();

  runtimeSuite(fixturePath: source, () {
    late Directory dir;
    late Player player;

    setUpAll(() async {
      // A space and a # in the directory too.
      dir = Directory.systemTemp.createTempSync('mak uri #journey ');
      player = await buildPlayer();
    });

    tearDownAll(() async {
      await player.dispose();
      dir.deleteSync(recursive: true);
    });

    /// A copy of the fixture named [name], or `null` when this file
    /// system takes no such name.
    String? copyAs(String name) {
      try {
        return File(source).copySync('${dir.path}/$name').path;
      } on FileSystemException {
        return null;
      }
    }

    Future<void> expectPlaylist(List<Media> medias) async {
      if (player.state.playback.playlist.items.length != medias.length) {
        await player.stream.playlist
            .firstWhere((p) => p.items.length == medias.length)
            .timeout(const Duration(seconds: 15));
      }
      final items = player.state.playback.playlist.items;
      for (var i = 0; i < medias.length; i++) {
        expect(items[i].uri, medias[i].uri, reason: 'entry $i');
        expect(
          items[i].extras?['n'],
          i,
          reason: 'entry $i is the Media the caller passed: ${medias[i].uri}',
        );
      }
    }

    test(
      'every form of every name comes back from the playlist as it went in',
      () async {
        final pieces = [...plainPieces, ...percentPieces, ...openPercentPieces];
        final uris = <String>[];
        for (final (i, piece) in pieces.indexed) {
          final path = copyAs('$i a${piece}b.wav');
          if (path == null) continue;
          uris
            ..add(path)
            ..add(Uri.file(path, windows: false).toString());
          // Raw after file://, a % would be an escape of another name.
          if (!piece.contains('%')) uris.add('file://$path');
        }
        expect(uris.length, greaterThan(pieces.length * 2));
        final medias = [
          for (final (n, uri) in uris.indexed) Media(uri, extras: {'n': n}),
        ];
        await player.openAll(medias, play: false);
        await expectPlaylist(medias);
      },
      timeout: const Timeout(Duration(seconds: 60)),
    );

    // One open for each: the file mpv opens is the one that was named.
    const hard = [
      'a b.wav',
      'track #1.wav',
      'what?.wav',
      '100% ok.wav',
      'a%41b.wav',
      'a%%41b.wav',
      'a%zzb.wav',
      'Città vecchia.wav',
      '日本語 🎵.wav',
      'é.wav',
      r'back\slash.wav',
      'a:b;c&d=e+f.wav',
      "quote'\"s.wav",
      'tab\there.wav',
    ];
    for (final name in hard) {
      test('mpv opens ${name.replaceAll('\t', r'\t')} by its path and by the '
          'URL of it', () async {
        final path = copyAs('one $name');
        if (path == null) {
          markTestSkipped('this file system takes no such name');
          return;
        }
        final forms = [
          path,
          Uri.file(path, windows: false).toString(),
          if (!name.contains('%')) 'file://$path',
        ];
        for (final (n, uri) in forms.indexed) {
          final loaded = player.stream.seekCompleted.first.timeout(
            const Duration(seconds: 10),
          );
          final media = Media(uri, extras: {'n': 0, 'form': n});
          await player.open(media, play: false);
          await loaded;
          await expectPlaylist([media]);
          expect(
            player.state.playback.playlist.items.single.extras?['form'],
            n,
          );
          expect(
            await player.getRawProperty('path'),
            path,
            reason: 'opened as $uri',
          );
        }
      }, timeout: const Timeout(Duration(seconds: 60)));
    }

    test(
      'a Latin-1 name, which no Dart string holds, opens by its URL',
      () async {
        // The name is written by printf: byte 0xE9, no UTF-8.
        final made = Process.runSync('sh', [
          '-c',
          r'cp "$1" "$2/$(printf "caf\\351 %%1.wav")"',
          'sh',
          source,
          dir.path,
        ]);
        if (made.exitCode != 0) {
          markTestSkipped('this file system takes no name that is not UTF-8');
          return;
        }
        final url =
            '${Uri.directory(dir.path, windows: false)}caf%E9%20%251.wav';
        final loaded = player.stream.seekCompleted.first.timeout(
          const Duration(seconds: 10),
        );
        final media = Media(url, extras: {'n': 0});
        await player.open(media, play: false);
        await loaded;
        await expectPlaylist([media]);
        expect(
          await player.getRawProperty('file-size'),
          '${File(source).lengthSync()}',
          reason: 'mpv opened the file',
        );
      },
      timeout: const Timeout(Duration(seconds: 60)),
    );
  });
}
