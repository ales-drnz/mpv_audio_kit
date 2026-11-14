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
        // A drive at the root is read as Windows reads it (see below).
        if (!_plain(path) || RegExp('^/[A-Za-z]:').hasMatch(path)) return;
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
            if (RegExp('^/[A-Za-z]:').hasMatch(path)) return;
            _expectNames(await probe.urlOf(item), path, item);
          },
          maxExamples: 150,
        );
      },
    );
  });

  // Two defects these tests found, left as they are (0.7.1 K8 writes
  // tests only), each with its smallest case. Both are in
  // MediaSessionController._fileUri and its _unescape.
  group('defects', () {
    setUp(open);
    tearDown(close);

    // _unescape decodes with allowMalformed, so the bytes of a Latin-1
    // name become U+FFFD, and the URL published names another file. The
    // item's own URL was already a URI of the right bytes.
    test(
      'a file:// item whose escapes are not UTF-8 keeps its bytes',
      () async {
        const item = 'file:///music/caf%E9.mp3';
        expect(fileUrlToPath(item, windows: false), isNull);
        expect(await probe.urlOf(item), item);
      },
      skip:
          'defect: published as file:///music/caf%EF%BF%BD.mp3, another '
          'file (_unescape decodes with allowMalformed)',
    );

    // /C:/Music is read as C:/Music on every host, which mpv does only on
    // Windows. With a slash after the colon the URI is the same; without
    // one the path is no drive path, and nothing is published.
    test(
      'a POSIX path that starts like a drive is published',
      () async {
        const item = 'file:///a:b/c.flac';
        const path = '/a:b/c.flac';
        expect(fileUrlToPath(item, windows: false), path);
        _expectNames(await probe.urlOf(item), path, item);
      },
      skip:
          'defect: nothing is published (the path is read as a Windows '
          'drive path on a POSIX host)',
    );
  });
}
