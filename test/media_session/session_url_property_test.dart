// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

// The URL the session publishes for a local item (MPRIS `xesam:url`), on
// random file names (kiri_check): a URI with nothing a URI cannot hold,
// which names the path mpv opens for the item. controller_test.dart has
// the cases one by one; `xesam:url` was corrected four times in two
// releases, a name at a time.
//
// POSIX paths: on Windows the controller reads a path as a Windows one,
// and controller_test has those cases.

@TestOn('mac-os || linux')
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiri_check/kiri_check.dart';
import 'package:mpv_audio_kit/src/internals/uri_resolver.dart';

import '../_helpers/file_names.dart';
import '../_helpers/session_url_probe.dart';

/// Whether [path] has a `.` or `..` segment, or an empty one: a URI
/// drops the first two, and the path it names is the same file.
bool _plain(String path) =>
    !path.split('/').skip(1).any((s) => s == '.' || s == '..' || s.isEmpty);

/// [url] is a `file:` URI of this machine with nothing but what a URI
/// holds raw, and names [path].
void _expectNames(String? url, String path, String item) {
  final reason = 'the item $item, the path $path';
  expect(url, isNotNull, reason: reason);
  expect(url, matches(RegExp(r'^file:///[\x21-\x7e]*$')), reason: reason);
  expect(url, isNot(contains(RegExp('[#?]'))), reason: reason);
  expect(Uri.parse(url!).toFilePath(windows: false), path, reason: reason);
  expect(
    fileUrlToPath(url, windows: false),
    path,
    reason: 'mpv opens the same file from the URL: $reason',
  );
}

/// The bytes after `file://` in [url], whose every `%` starts an escape,
/// each escape decoded.
List<int> _decoded(String url) {
  final src = utf8.encode(url.substring('file://'.length));
  final out = <int>[];
  for (var i = 0; i < src.length; i++) {
    if (src[i] != 0x25) {
      out.add(src[i]);
      continue;
    }
    out.add(int.parse(String.fromCharCodes(src, i + 1, i + 3), radix: 16));
    i += 2;
  }
  return out;
}

void main() {
  late SessionUrlProbe probe;
  Future<void> open() async => probe = await SessionUrlProbe.open();
  Future<void> close() => probe.close();

  property('a path is published as a URI that names it', () {
    forAll(
      segments([...plainPieces, ...percentPieces, ...openPercentPieces]),
      (names) async {
        // A plain path is literal: a % in it is a %.
        final path = '/${names.join('/')}';
        _expectNames(await probe.urlOf(path), path, path);
      },
      maxExamples: 150,
      setUpAll: open,
      tearDownAll: close,
    );
  });

  property('a file:// item is published as a URI of the path mpv opens', () {
    forAll(
      combine2(segments([...plainPieces, ...percentPieces]), boolean()),
      (parts) async {
        final (names, encoded) = parts;
        // As an app builds it (Uri.file), or with all that mpv takes after
        // file:// written raw.
        final raw = '/${names.join('/')}';
        final item = encoded
            ? Uri.file(raw, windows: false).toString()
            : 'file://$raw';
        final path = fileUrlToPath(item, windows: false)!;
        if (!_plain(path)) return;
        _expectNames(await probe.urlOf(item), path, item);
      },
      maxExamples: 150,
      setUpAll: open,
      tearDownAll: close,
    );
  });

  // mpv skips a malformed escape whole, three characters, so the %41
  // that starts inside one stays as it is (fileUrlToPath does the same).
  group('a malformed escape', () {
    setUp(open);
    tearDown(close);

    test('an escape inside a malformed one is not decoded', () async {
      const item = 'file:///%%41';
      const path = '/%%41';
      expect(fileUrlToPath(item, windows: false), path);
      _expectNames(await probe.urlOf(item), path, item);
    });

    test('a % at the end, or before one character, is kept', () async {
      for (final name in ['100%', '100%4', '%', '%%', '%%%41', '%4%41']) {
        final item = 'file:///$name';
        final path = fileUrlToPath(item, windows: false)!;
        _expectNames(await probe.urlOf(item), path, item);
      }
    });

    property(
      'a file:// item with an open % is published as the path mpv opens',
      () {
        forAll(
          segments([...plainPieces, ...percentPieces, ...openPercentPieces]),
          (names) async {
            final item = 'file:///${names.join('/')}';
            final path = fileUrlToPath(item, windows: false);
            if (path == null || !_plain(path)) return;
            _expectNames(await probe.urlOf(item), path, item);
          },
          maxExamples: 150,
        );
      },
    );
  });

  // The bytes of a Latin-1 name are no UTF-8, so no Dart string is the
  // path (fileUrlToPath gives null and the URL goes to mpv as it is). The
  // URL published names the same bytes: decoded to a string they would
  // become U+FFFD, the name of another file.
  group('a name that is not UTF-8', () {
    setUp(open);
    tearDown(close);

    test(
      'a file:// item whose escapes are not UTF-8 keeps its bytes',
      () async {
        const item = 'file:///music/caf%E9.mp3';
        expect(fileUrlToPath(item, windows: false), isNull);
        expect(await probe.urlOf(item), item);
      },
    );

    test('what a URI cannot hold raw is encoded beside those bytes', () async {
      expect(
        await probe.urlOf('file:///m sic/caf%e9 #1?%FF%41é.mp3'),
        'file:///m%20sic/caf%E9%20%231%3F%FFA%C3%A9.mp3',
      );
    });

    property('the URL published names the bytes mpv opens', () {
      forAll(
        segments([
          ...plainPieces,
          ...['%20', '%23', '%3F', '%25', '%41', '%C3%A9', '%F0%9F%8E%B5'],
          ...['%E9', '%e9', '%FF', '%C3', '%A9', '%80%20', '%F0%9F'],
        ]),
        (names) async {
          final item = 'file:///${names.join('/')}';
          final bytes = _decoded(item);
          final path = utf8.decode(bytes, allowMalformed: true);
          if (!_plain(path)) return;
          final url = await probe.urlOf(item);
          expect(url, isNotNull, reason: item);
          expect(url, matches(RegExp(r'^file:///[\x21-\x7e]*$')), reason: item);
          expect(url, isNot(contains(RegExp('[#?]'))), reason: item);
          expect(_decoded(url!), bytes, reason: item);
        },
        maxExamples: 150,
      );
    });
  });

  // mpv reads /C:/Music as C:/Music on Windows only. On a POSIX host it
  // is the path it looks like, and so is /a:b, which is no drive path.
  group('a path that starts like a drive', () {
    setUp(open);
    tearDown(close);

    test('a POSIX path that starts like a drive is published', () async {
      const item = 'file:///a:b/c.flac';
      const path = '/a:b/c.flac';
      expect(fileUrlToPath(item, windows: false), path);
      _expectNames(await probe.urlOf(item), path, item);
    });

    test('a POSIX path with a slash after the colon too', () async {
      const item = 'file:///C:/Music/a #1.flac';
      const path = '/C:/Music/a #1.flac';
      expect(await probe.urlOf(item), 'file:///C:/Music/a%20%231.flac');
      _expectNames(await probe.urlOf(item), path, item);
    });

    test('on Windows it is a drive path, as before', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      expect(
        await probe.urlOf('file:///C:/Music/a #1.flac'),
        'file:///C:/Music/a%20%231.flac',
      );
      expect(
        await probe.urlOf('file:///C:%5CMusic%5Ccaf%E9.mp3'),
        'file:///C:/Music/caf%E9.mp3',
      );
      expect(
        await probe.urlOf('file:///a:b/c.flac'),
        isNull,
        reason: 'a drive without a root: no URI names it',
      );
      expect(
        await probe.urlOf('file:///C:/Music/a*b.flac'),
        isNull,
        reason: 'no URI names a path Windows forbids',
      );
    });
  });
}
