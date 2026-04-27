// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:mpv_audio_kit/src/internal/json_parsers.dart';

void main() {
  group('parsePlaylistJson', () {
    test('parses a simple two-track playlist with current flag', () {
      final p = parsePlaylistJson(
        jsonStr:
            '[{"filename": "a.mp3", "current": true}, {"filename": "b.mp3"}]',
        mediaCache: const {},
        previous: const Playlist.empty(),
      );
      expect(p.medias.length, 2);
      expect(p.medias[0].uri, 'a.mp3');
      expect(p.medias[1].uri, 'b.mp3');
      expect(p.index, 0);
    });

    test('current flag on second item maps to index=1', () {
      final p = parsePlaylistJson(
        jsonStr:
            '[{"filename": "a.mp3"}, {"filename": "b.mp3", "current": true}]',
        mediaCache: const {},
        previous: const Playlist.empty(),
      );
      expect(p.index, 1);
    });

    test('attaches Media instances from mediaCache (preserves extras)', () {
      final cached = Media('a.mp3',
          extras: const {'title': 'Track A'}, httpHeaders: const {'X': 'Y'});
      final p = parsePlaylistJson(
        jsonStr: '[{"filename": "a.mp3", "current": true}]',
        mediaCache: {'a.mp3': cached},
        previous: const Playlist.empty(),
      );
      expect(p.medias[0], same(cached),
          reason:
              'consumer-supplied Media must round-trip identically; mpv '
              'only echoes the URI back so the wrapper has to re-attach '
              'extras + headers from cache');
    });

    test('falls back to Media(filename) when not in cache', () {
      final p = parsePlaylistJson(
        jsonStr: '[{"filename": "unknown.mp3"}]',
        mediaCache: const {},
        previous: const Playlist.empty(),
      );
      expect(p.medias[0], Media('unknown.mp3'));
    });

    test(
        'no current flag: falls back to PREVIOUS index, NOT 0 '
        '(regression test for the playlist-move transient)', () {
      // mpv emits the playlist mid-playlist-move without `current: true` on
      // any entry. Naively clamping `indexWhere == -1` to 0 incorrectly
      // marks the first item as "now playing", causing UI flicker on
      // re-orders.
      final p = parsePlaylistJson(
        jsonStr: '[{"filename": "a"}, {"filename": "b"}, {"filename": "c"}]',
        mediaCache: const {},
        previous: const Playlist([Media('a'), Media('b'), Media('c')],
            index: 2),
      );
      expect(p.index, 2);
    });

    test('no current flag + prev.index out-of-range → clamped to bounds', () {
      // Edge case: prev.index points past the new (shorter) playlist.
      final p = parsePlaylistJson(
        jsonStr: '[{"filename": "a"}]',
        mediaCache: const {},
        previous: const Playlist([Media('a'), Media('b'), Media('c')],
            index: 2),
      );
      expect(p.index, 0,
          reason: 'clamp prev.index=2 into [0, length-1] = [0, 0]');
    });

    test('empty array → empty playlist (index=0 not -1)', () {
      final p = parsePlaylistJson(
        jsonStr: '[]',
        mediaCache: const {},
        previous: const Playlist.empty(),
      );
      expect(p.medias, isEmpty);
      expect(p.index, 0);
    });

    test('throws FormatException on invalid JSON', () {
      expect(
          () => parsePlaylistJson(
                jsonStr: 'not valid {json',
                mediaCache: const {},
                previous: const Playlist.empty(),
              ),
          throwsA(isA<FormatException>()));
    });

    test('throws on wrong shape (non-array root)', () {
      expect(
          () => parsePlaylistJson(
                jsonStr: '{"this": "is not a list"}',
                mediaCache: const {},
                previous: const Playlist.empty(),
              ),
          throwsA(isA<TypeError>()));
    });
  });

  group('parseAudioDeviceListJson', () {
    test('parses a typical mpv audio-device-list payload', () {
      final list = parseAudioDeviceListJson(
        '[{"name": "auto", "description": "Autoselect"},'
        ' {"name": "coreaudio/AppleHDA", "description": "Built-in"}]',
      );
      expect(list.length, 2);
      expect(list[0].name, 'auto');
      expect(list[0].description, 'Autoselect');
      expect(list[1].name, 'coreaudio/AppleHDA');
      expect(list[1].description, 'Built-in');
    });

    test('missing name / description → "unknown" / "" defaults', () {
      final list = parseAudioDeviceListJson('[{"name": "x"}, {}]');
      expect(list[0].name, 'x');
      expect(list[0].description, '');
      expect(list[1].name, 'unknown');
      expect(list[1].description, '');
    });

    test('throws FormatException on malformed JSON', () {
      expect(() => parseAudioDeviceListJson('garbage'),
          throwsA(isA<FormatException>()));
    });
  });

  group('parseMetadataJson', () {
    test('parses string-only tag dictionary', () {
      final m = parseMetadataJson(
          '{"title": "Song", "artist": "Artist", "album": "Album"}');
      expect(m, isNotNull);
      expect(m!['title'], 'Song');
      expect(m['artist'], 'Artist');
      expect(m['album'], 'Album');
    });

    test('coerces non-string values to strings', () {
      // mpv's metadata source can occasionally yield int / double / bool
      // literals depending on the demuxer; the wrapper guarantees a
      // String→String surface to consumers.
      final m = parseMetadataJson(
          '{"track": 3, "year": 2024, "explicit": true}');
      expect(m, isNotNull);
      expect(m!['track'], '3');
      expect(m['year'], '2024');
      expect(m['explicit'], 'true');
    });

    test('returns null on empty/whitespace input (no-op signal)', () {
      // mpv emits "" on tracks with no tags; overwriting an existing
      // metadata map with `{}` would lose valid prior state during a
      // brief track-change window.
      expect(parseMetadataJson(''), isNull);
      expect(parseMetadataJson('   '), isNull);
      expect(parseMetadataJson('\n\t\n'), isNull);
    });

    test('throws FormatException on malformed JSON', () {
      expect(
          () => parseMetadataJson('{not valid'),
          throwsA(isA<FormatException>()));
    });

    test('throws TypeError on non-object root', () {
      expect(() => parseMetadataJson('["array", "instead", "of", "object"]'),
          throwsA(isA<TypeError>()));
    });
  });

  group('parseBufferingPercentage', () {
    test('cache-duration / target * 100, clamped to 0..100', () {
      // Full window: 30s out of 30s target → 100%
      expect(
          parseBufferingPercentage(
              '{"cache-duration": 30}', const Duration(seconds: 30)),
          100.0);
      // Half full: 15s / 30s → 50%
      expect(
          parseBufferingPercentage(
              '{"cache-duration": 15}', const Duration(seconds: 30)),
          50.0);
      // Empty: 0s / 30s → 0%
      expect(
          parseBufferingPercentage(
              '{"cache-duration": 0}', const Duration(seconds: 30)),
          0.0);
    });

    test('clamps overshoot (>100) to 100', () {
      // mpv occasionally reports cache-duration slightly past the target
      // because of demuxer fluctuations.
      expect(
          parseBufferingPercentage(
              '{"cache-duration": 50}', const Duration(seconds: 30)),
          100.0);
    });

    test('cacheSecsTarget=zero falls back to 1s denominator', () {
      // Default state has cacheSecs=1s, but during the first event burst
      // the target might still be zero. The percentage must not divide
      // by zero — the helper documents a 1s fallback.
      expect(
          parseBufferingPercentage(
              '{"cache-duration": 0.5}', Duration.zero),
          50.0);
      expect(
          parseBufferingPercentage(
              '{"cache-duration": 5}', Duration.zero),
          100.0,
          reason: 'with the 1s fallback, anything ≥1 saturates at 100');
    });

    test('missing cache-duration key → 0%', () {
      expect(
          parseBufferingPercentage('{}', const Duration(seconds: 30)), 0.0);
    });

    test('throws FormatException on malformed JSON', () {
      expect(
          () => parseBufferingPercentage(
              'not json', const Duration(seconds: 1)),
          throwsA(isA<FormatException>()));
    });
  });
}
