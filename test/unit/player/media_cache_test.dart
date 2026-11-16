// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:mpv_audio_kit/src/player/media_cache.dart';
import 'package:test/test.dart';

void main() {
  const a = Media('a.flac');
  const b = Media('b.flac');

  List<Map<String, Object?>> node(List<String> names) => [
    for (final name in names) {'filename': name},
  ];

  group('MediaCache.prune', () {
    test('drops the keys no entry holds and mpv does not list', () {
      final cache = MediaCache()
        ..['a.flac'] = a
        ..['/abs/a.flac'] = a
        ..['b.flac'] = b
        ..['gone.flac'] = const Media('gone.flac');
      cache.prune(node(['/abs/a.flac', 'b.flac']), [a], busy: false);
      // a by its Media, b by the name mpv lists.
      expect(cache.byUri.keys, {'a.flac', '/abs/a.flac', 'b.flac'});
    });

    test('waits while a load is under way', () {
      final cache = MediaCache()..['a.flac'] = a;
      cache.prune(node([]), const [], busy: true);
      expect(cache['a.flac'], a);
      cache.entryLoads++;
      cache.prune(node([]), const [], busy: false);
      expect(cache['a.flac'], a);
      cache.entryLoads--;
      cache.prune(node([]), const [], busy: false);
      expect(cache['a.flac'], isNull);
    });

    test('leaves the cache alone for a node that is no list', () {
      final cache = MediaCache()..['a.flac'] = a;
      cache.prune(null, const [], busy: false);
      expect(cache['a.flac'], a);
    });

    test('keeps the URLs of a resolver', () {
      final cache = MediaCache()
        ..putResolved('https://cdn/1', const Media('x'), load: true);
      cache.prune(node([]), const [], busy: false);
      expect(cache.byUri.keys, {'https://cdn/1'});
    });
  });

  group('MediaCache.putResolved', () {
    test('a load turns the URLs of earlier loads over', () {
      final cache = MediaCache()..['a.flac'] = a;
      for (var i = 0; i < 10; i++) {
        cache.putResolved('https://cdn/$i', a, load: true);
      }
      expect(cache.byUri.keys, {'a.flac', 'https://cdn/9'});
    });

    test('the URL held for the prefetch stays through a load', () {
      final cache = MediaCache()
        ..putResolved('https://cdn/next', b, load: false)
        ..putResolved('https://cdn/1', a, load: true, kept: 'https://cdn/next')
        ..putResolved('https://cdn/2', a, load: true, kept: 'https://cdn/next');
      expect(cache.byUri.keys, {'https://cdn/next', 'https://cdn/2'});
    });

    test('a key a load wrote is not turned over', () {
      final cache = MediaCache()
        ..['b.flac'] = b
        ..putResolved('b.flac', a, load: true)
        ..putResolved('https://cdn/2', a, load: true);
      expect(cache.byUri.keys, {'b.flac', 'https://cdn/2'});
    });
  });

  test('clear and keepOnly forget the resolver keys too', () {
    final cache = MediaCache()
      ..['a.flac'] = a
      ..putResolved('https://cdn/1', b, load: true)
      ..keepOnly(a);
    expect(cache.byUri.keys, {'a.flac'});
    // A later load under the same URL is a load's key again.
    cache
      ..['https://cdn/1'] = b
      ..putResolved('https://cdn/2', a, load: true);
    expect(cache.byUri.keys, {'a.flac', 'https://cdn/1', 'https://cdn/2'});
    cache.clear();
    expect(cache.byUri, isEmpty);
  });
}
