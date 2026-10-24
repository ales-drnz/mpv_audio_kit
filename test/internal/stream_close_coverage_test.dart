// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

// Source checks behind the dispose of the streams, without libmpv. The
// runtime test (dispose_all_streams_done_test) proves the done of every
// stream listed in test/_helpers/player_streams.dart; these keep that
// list complete, and catch a controller or reactive left without its
// close, the class of 1dfaba8 (playWhenReady, audioDevice, audioEffects
// and playbackState never closed).

import 'dart:io';

import 'package:test/test.dart';

import '../_helpers/player_streams.dart';

String _read(String path) =>
    File('${Directory.current.path}/$path').readAsStringSync();

/// [source] without its line comments, so a name in a comment counts as
/// neither a declaration nor a close.
String _code(String source) => source.replaceAllMapped(
  RegExp(r'(^|\s)//.*$', multiLine: true),
  (m) => m.group(1)!,
);

/// The text between the braces that open right after [header] in
/// [source].
String _body(String source, String header) {
  final start = source.indexOf(header);
  if (start < 0) throw StateError('no "$header"');
  final open = source.indexOf('{', start + header.length - 1);
  var depth = 0;
  for (var i = open; i < source.length; i++) {
    if (source[i] == '{') depth++;
    if (source[i] == '}' && --depth == 0) {
      return source.substring(open + 1, i);
    }
  }
  throw StateError('unbalanced braces after "$header"');
}

/// The names of the fields of type [type] declared in [code], with any
/// type arguments and modifiers.
Set<String> _fields(String code, String type) => {
  for (final m in RegExp(
    '(?:final|late)\\s+$type<[^;{}()=]*>\\s+(\\w+)\\s*[;=]',
  ).allMatches(code))
    m.group(1)!,
};

/// The receivers `x` of every `x.close()` in [code].
Set<String> _closed(String code) => {
  for (final m in RegExp(r'([\w.]+)\.close\(\)').allMatches(code)) m.group(1)!,
};

void main() {
  test('player_streams.dart lists every Stream field of PlayerStream', () {
    final declared = _fields(
      _code(_read('lib/src/player/player_stream.dart')),
      'Stream',
    );
    expect(declared, hasLength(greaterThan(100)));
    expect(
      playerStreams.keys.toSet().difference(declared),
      isEmpty,
      reason: 'listed in player_streams.dart, not a field of PlayerStream',
    );
    expect(
      declared.difference(playerStreams.keys.toSet()),
      isEmpty,
      reason:
          'fields of PlayerStream missing from player_streams.dart: the '
          'runtime test would not check their done on dispose',
    );
  });

  group('_PlayerBase closes what backs its streams', () {
    final base = _body(
      _code(_read('lib/src/player/player.dart')),
      'abstract class _PlayerBase {',
    );
    // The closes live in _disposeImpl and in whatever it calls inside the
    // class, so the check reads the whole class body.
    final closed = _closed(base);

    test('every StreamController and ReactiveProperty of the class', () {
      final controllers = _fields(base, 'StreamController');
      final reactives = _fields(base, 'ReactiveProperty');
      // 13 controllers and 9 reactives at 0.5.3: a parse that finds
      // none would pass without checking anything.
      expect(controllers, hasLength(greaterThanOrEqualTo(13)));
      expect(reactives, hasLength(greaterThanOrEqualTo(9)));
      expect(
        {...controllers, ...reactives}.difference(closed),
        isEmpty,
        reason: 'never closed by the player, so their streams never end',
      );
    });

    test('every reactive of DefaultPropertyReactives', () {
      final declared = _fields(
        _code(_read('lib/src/reactive/default_reactives.dart')),
        'ReactiveProperty',
      );
      // Closed by PropertyRegistry.closeAll, through the spec that owns
      // the cell.
      final bySpec = {
        for (final m in RegExp(
          r'reactive:\s*r\.(\w+)',
        ).allMatches(_code(_read('lib/src/reactive/default_specs.dart'))))
          m.group(1)!,
      };
      final byHand = {
        for (final name in closed)
          if (name.startsWith('_reactives.'))
            name.substring('_reactives.'.length),
      };
      expect(declared, hasLength(greaterThan(80)));
      expect(byHand, isNotEmpty);
      expect(
        declared.difference({...bySpec, ...byHand}),
        isEmpty,
        reason:
            'neither owned by a spec nor closed by the player, so their '
            'streams never end',
      );
    });
  });
}
