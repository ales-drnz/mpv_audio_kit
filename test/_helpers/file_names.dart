// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

// File names for the property tests of the URI journey (kiri_check): made
// of pieces that each broke something once (a space, `#`, `?`, `%`,
// non-ASCII, a `%NN` escape written raw), not of uniform characters, which
// would almost never line two of them up.

import 'package:kiri_check/kiri_check.dart';

/// Pieces any POSIX file name can hold. No `/`, no NUL, no lone `.`.
const plainPieces = [
  'a', 'B', '7', 'song', '.flac', '-', '_', ' ', '  ', '#', '?', '&', '=',
  '+', ';', ',', "'", '"', '(', ')', '[', ']', '{', '}', '~', '!', '@',
  r'$', '^', '`', '|', r'\', ':', '*', '<', '>', '\t', 'é', 'à', 'ß',
  'Città', '日本語', '🎵', 'é', ' ', 'İ', 'ǅ', //
];

/// Pieces with a `%`: a literal one in a plain path, and in a `file://`
/// URL an escape mpv decodes, or a malformed one it keeps. Each is whole:
/// none leaves a `%` whose two next characters belong to the next piece.
const percentPieces = [
  '%20',
  '%23',
  '%3F',
  '%25',
  '%41',
  '%2e',
  '%C3%A9',
  '%E6%97%A5',
  '%F0%9F%8E%B5',
  '%zz', '%g0', '% of', '100% ok', //
];

/// Pieces that leave a `%` open, so that it takes characters of the next
/// piece into its malformed escape.
const openPercentPieces = ['%', '%4', '%%'];

/// Pieces Windows forbids in no file name.
const windowsPieces = [
  'a', 'B', '7', 'song', '.flac', '-', '_', ' ', '#', '&', '=', '+', ';',
  ',', "'", '(', ')', '[', ']', '{', '}', '~', '!', '@', r'$', '^', '`',
  'é', 'Città', '日本語', '🎵', '%', '%41', //
];

/// One to four path segments, each of one to five of [pieces], with no
/// segment that is `.` or `..`.
Arbitrary<List<String>> segments(List<String> pieces) =>
    list(
      list(constantFrom(pieces), minLength: 1, maxLength: 5),
      minLength: 1,
      maxLength: 4,
    ).map(
      (parts) => [
        for (final part in parts)
          if (part.join() case final name when name != '.' && name != '..')
            name
          else
            'x',
      ],
    );
