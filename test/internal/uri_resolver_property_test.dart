// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

// The path of a file through a `file://` URL and back, on random names
// (kiri_check): fileUrlToPath gives the path the URL was made from,
// whatever the name holds, as a POSIX path, a Windows drive path and a
// share. uri_resolver_test.dart has the cases one by one.

@TestOn('mac-os || linux || windows')
library;

import 'package:kiri_check/kiri_check.dart';
import 'package:mpv_audio_kit/src/internals/uri_resolver.dart';
import 'package:test/test.dart';

import '../_helpers/file_names.dart';

/// Whether [path] has a `.` or `..` segment, or an empty one: `Uri.file`
/// removes the first two, so a URL made from it names the path without.
bool _plain(String path) =>
    !path.split('/').skip(1).any((s) => s == '.' || s == '..' || s.isEmpty);

void main() {
  property('a POSIX path comes back from the URL made of it', () {
    forAll(segments([...plainPieces, ...percentPieces]), (names) async {
      final path = '/${names.join('/')}';
      final url = Uri.file(path, windows: false).toString();
      expect(url, matches(RegExp(r'^file:///[\x21-\x7e]*$')));
      expect(fileUrlToPath(url, windows: false), path);
      // As a POSIX host reads them: on Windows a host before a path with
      // no drive makes a share (Test (Windows), run 43581359254).
      expect(
        fileUrlToPath(
          url.replaceFirst('file://', 'FILE://localhost'),
          windows: false,
        ),
        path,
        reason: 'the scheme in any case, and localhost for no host',
      );
      if (hostIsWindows) return;
      expect((await resolveUri(url)).uri, path);
      expect(await loadedName(url), path);
      expect((await resolveUri(path)).uri, path, reason: 'a path as it is');
    }, maxExamples: 300);
  });

  property('a POSIX path with no % comes back from file:// and itself', () {
    // mpv takes all that follows file:// as the path: a raw space, a # or
    // a ? is part of the name.
    forAll(segments(plainPieces), (names) {
      final path = '/${names.join('/')}';
      expect(fileUrlToPath('file://$path', windows: false), path);
    }, maxExamples: 300);
  });

  property('whatever follows file://, a path that comes out goes back in', () {
    // Escapes mpv decodes, malformed ones it keeps, a % left open before
    // the next piece: no throw, and a path it gives makes a URL that gives
    // the same path.
    forAll(segments([...plainPieces, ...percentPieces, ...openPercentPieces]), (
      names,
    ) {
      final path = fileUrlToPath('file:///${names.join('/')}', windows: false);
      // An open % can take the start of a UTF-8 escape with it: what is
      // left of the escape is not UTF-8, and the URL goes to mpv as it is.
      if (path == null || !_plain(path)) return;
      final url = Uri.file(path, windows: false).toString();
      expect(fileUrlToPath(url, windows: false), path);
    }, maxExamples: 300);
  });

  property('escapes that are not UTF-8 give no path, and no throw', () {
    forAll(
      combine3(
        segments([...plainPieces, ...percentPieces]),
        constantFrom(['%E9', '%FF', '%C3', '%C3(', '%ED%A0%80', '%F8%88']),
        segments(plainPieces),
      ),
      (parts) {
        final (before, bad, after) = parts;
        // A piece that cannot go on the bad bytes follows them.
        final raw = '${before.join('/')}${bad}a${after.join('/')}';
        expect(fileUrlToPath('file:///$raw', windows: false), isNull);
        expect(fileUrlToPath('file:///$raw', windows: true), isNull);
      },
      maxExamples: 200,
    );
  });

  property('a Windows drive path comes back from the URL made of it', () {
    forAll(
      combine2(constantFrom(['C', 'c', 'D', 'z']), segments(windowsPieces)),
      (parts) {
        final (drive, names) = parts;
        final path = '$drive:\\${names.join(r'\')}';
        final mpv = path.replaceAll(r'\', '/');
        final url = Uri.file(path, windows: true).toString();
        expect(url, startsWith('file:///$drive:/'));
        expect(fileUrlToPath(url, windows: true), mpv);
        expect(
          fileUrlToPath(
            url.replaceFirst('file:///', 'file://localhost/'),
            windows: true,
          ),
          mpv,
        );
        expect(
          fileUrlToPath(url.replaceFirst('file:///', 'file://'), windows: true),
          mpv,
          reason: 'a drive right after the scheme is a drive, not a host',
        );
      },
      maxExamples: 300,
    );
  });

  property('a Windows share comes back from the URL made of it', () {
    forAll(
      combine2(
        // In lower case: Uri.file writes a host that way.
        constantFrom(['server', 'nas', 'nas-2', '192.168.1.10']),
        segments(windowsPieces),
      ),
      (parts) {
        final (host, names) = parts;
        final path = '\\\\$host\\share\\${names.join(r'\')}';
        final url = Uri.file(path, windows: true).toString();
        expect(fileUrlToPath(url, windows: true), path);
      },
      maxExamples: 200,
    );
  });
}
