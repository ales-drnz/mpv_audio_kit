// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:mpv_audio_kit/src/internal/node_parsers.dart';

void main() {
  group('parsePlaylistNode', () {
    test('parses a simple two-track playlist with current flag', () {
      final p = parsePlaylistNode(
        raw: [
          {'filename': 'a.mp3', 'current': true},
          {'filename': 'b.mp3'},
        ],
        mediaCache: const {},
        previous: const Playlist.empty(),
      );
      expect(p.medias.length, 2);
      expect(p.medias[0].uri, 'a.mp3');
      expect(p.medias[1].uri, 'b.mp3');
      expect(p.index, 0);
    });

    test('current flag on second item maps to index=1', () {
      final p = parsePlaylistNode(
        raw: [
          {'filename': 'a.mp3'},
          {'filename': 'b.mp3', 'current': true},
        ],
        mediaCache: const {},
        previous: const Playlist.empty(),
      );
      expect(p.index, 1);
    });

    test('attaches Media instances from mediaCache (preserves extras)', () {
      final cached = Media('a.mp3',
          extras: const {'title': 'Track A'}, httpHeaders: const {'X': 'Y'});
      final p = parsePlaylistNode(
        raw: [
          {'filename': 'a.mp3', 'current': true},
        ],
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
      final p = parsePlaylistNode(
        raw: [
          {'filename': 'unknown.mp3'},
        ],
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
      final p = parsePlaylistNode(
        raw: [
          {'filename': 'a'},
          {'filename': 'b'},
          {'filename': 'c'},
        ],
        mediaCache: const {},
        previous: const Playlist(
            [Media('a'), Media('b'), Media('c')],
            index: 2),
      );
      expect(p.index, 2);
    });

    test('no current flag + prev.index out-of-range → clamped to bounds', () {
      // Edge case: prev.index points past the new (shorter) playlist.
      final p = parsePlaylistNode(
        raw: [
          {'filename': 'a'},
        ],
        mediaCache: const {},
        previous: const Playlist(
            [Media('a'), Media('b'), Media('c')],
            index: 2),
      );
      expect(p.index, 0,
          reason: 'clamp prev.index=2 into [0, length-1] = [0, 0]');
    });

    test('empty array → empty playlist (index=0 not -1)', () {
      final p = parsePlaylistNode(
        raw: const [],
        mediaCache: const {},
        previous: const Playlist.empty(),
      );
      expect(p.medias, isEmpty);
      expect(p.index, 0);
    });

    test('non-list raw → falls back to previous unchanged', () {
      // mpv could in principle deliver MPV_FORMAT_NONE (decoded as null)
      // during a brief unobservable window. The wrapper must keep the
      // previous playlist visible rather than collapsing to empty.
      final previous = const Playlist([Media('a')], index: 0);
      expect(parsePlaylistNode(
        raw: null,
        mediaCache: const {},
        previous: previous,
      ), same(previous));
      expect(parsePlaylistNode(
        raw: 'unexpected scalar',
        mediaCache: const {},
        previous: previous,
      ), same(previous));
    });

    test('malformed entry (non-map) is tolerated, fills empty slot', () {
      final p = parsePlaylistNode(
        raw: [
          {'filename': 'a.mp3'},
          'garbage entry',
          {'filename': 'b.mp3', 'current': true},
        ],
        mediaCache: const {},
        previous: const Playlist.empty(),
      );
      expect(p.medias.length, 3);
      expect(p.medias[0].uri, 'a.mp3');
      expect(p.medias[1].uri, '');
      expect(p.medias[2].uri, 'b.mp3');
      expect(p.index, 2);
    });
  });

  group('parseAudioDeviceListNode', () {
    test('parses a typical mpv audio-device-list payload', () {
      final list = parseAudioDeviceListNode([
        {'name': 'auto', 'description': 'Autoselect'},
        {'name': 'coreaudio/AppleHDA', 'description': 'Built-in'},
      ]);
      expect(list.length, 2);
      expect(list[0].name, 'auto');
      expect(list[0].description, 'Autoselect');
      expect(list[1].name, 'coreaudio/AppleHDA');
      expect(list[1].description, 'Built-in');
    });

    test('missing name / description → "unknown" / "" defaults', () {
      final list = parseAudioDeviceListNode([
        {'name': 'x'},
        const <String, dynamic>{},
      ]);
      expect(list[0].name, 'x');
      expect(list[0].description, '');
      expect(list[1].name, 'unknown');
      expect(list[1].description, '');
    });

    test('non-list raw → empty list', () {
      expect(parseAudioDeviceListNode(null), isEmpty);
      expect(parseAudioDeviceListNode('garbage'), isEmpty);
      expect(parseAudioDeviceListNode(<String, dynamic>{}), isEmpty);
    });
  });

  group('parseMetadataNode', () {
    test('parses string-only tag dictionary', () {
      final m = parseMetadataNode(<String, dynamic>{
        'title': 'Song',
        'artist': 'Artist',
        'album': 'Album',
      });
      expect(m, isNotNull);
      expect(m!['title'], 'Song');
      expect(m['artist'], 'Artist');
      expect(m['album'], 'Album');
    });

    test('coerces non-string values to strings', () {
      // mpv's metadata source can occasionally yield int / double / bool
      // literals depending on the demuxer; the wrapper guarantees a
      // String→String surface to consumers.
      final m = parseMetadataNode(<String, dynamic>{
        'track': 3,
        'year': 2024,
        'explicit': true,
      });
      expect(m, isNotNull);
      expect(m!['track'], '3');
      expect(m['year'], '2024');
      expect(m['explicit'], 'true');
    });

    test('returns null on empty/null input (no-op signal)', () {
      // mpv emits MPV_FORMAT_NONE (decoded null) or an empty map on tracks
      // with no tags; overwriting an existing metadata map with `{}` would
      // lose valid prior state during a brief track-change window.
      expect(parseMetadataNode(null), isNull);
      expect(parseMetadataNode(<String, dynamic>{}), isNull);
    });

    test('returns null on non-map raw (defensive)', () {
      expect(parseMetadataNode('garbage'), isNull);
      expect(parseMetadataNode(<String>['array']), isNull);
    });
  });

  group('parseDemuxerCacheStateNode', () {
    test('cache-duration / target * 100, clamped to 0..100', () {
      // Full window: 30s out of 30s target → 100%
      expect(
        parseDemuxerCacheStateNode(
            <String, dynamic>{'cache-duration': 30}, const Duration(seconds: 30)),
        100.0,
      );
      // Half full: 15s / 30s → 50%
      expect(
        parseDemuxerCacheStateNode(
            <String, dynamic>{'cache-duration': 15}, const Duration(seconds: 30)),
        50.0,
      );
      // Empty: 0s / 30s → 0%
      expect(
        parseDemuxerCacheStateNode(
            <String, dynamic>{'cache-duration': 0}, const Duration(seconds: 30)),
        0.0,
      );
    });

    test('clamps overshoot (>100) to 100', () {
      // mpv occasionally reports cache-duration slightly past the target
      // because of demuxer fluctuations.
      expect(
        parseDemuxerCacheStateNode(
            <String, dynamic>{'cache-duration': 50}, const Duration(seconds: 30)),
        100.0,
      );
    });

    test('cacheSecsTarget=zero falls back to 1s denominator', () {
      // Default state has cacheSecs=1s, but during the first event burst
      // the target might still be zero. The percentage must not divide
      // by zero — the helper documents a 1s fallback.
      expect(
        parseDemuxerCacheStateNode(
            <String, dynamic>{'cache-duration': 0.5}, Duration.zero),
        50.0,
      );
      expect(
        parseDemuxerCacheStateNode(
            <String, dynamic>{'cache-duration': 5}, Duration.zero),
        100.0,
        reason: 'with the 1s fallback, anything ≥1 saturates at 100',
      );
    });

    test('missing cache-duration key → 0%', () {
      expect(
        parseDemuxerCacheStateNode(
            <String, dynamic>{}, const Duration(seconds: 30)),
        0.0,
      );
    });

    test('non-map raw → 0%', () {
      expect(
          parseDemuxerCacheStateNode(null, const Duration(seconds: 1)), 0.0);
      expect(
          parseDemuxerCacheStateNode('garbage', const Duration(seconds: 1)),
          0.0);
    });
  });

  group('parseAudioParamsNode', () {
    test('parses the 5 wire-side fields from MPV_FORMAT_NODE_MAP', () {
      final p = parseAudioParamsNode(<String, dynamic>{
        'format': 'floatp',
        'samplerate': 48000,
        'channels': '5.1',
        'channel-count': 6,
        'hr-channels': '5.1 surround',
      });
      expect(p.format, 'floatp');
      expect(p.sampleRate, 48000);
      expect(p.channels, '5.1');
      expect(p.channelCount, 6);
      expect(p.hrChannels, '5.1 surround');
      // codec / codecName are NOT in the node map — separate properties.
      expect(p.codec, isNull);
      expect(p.codecName, isNull);
    });

    test('empty strings and zero ints map to null (no-mpv-data signal)', () {
      // mpv emits empty strings / zeros during a brief reconfig window
      // before the new format is known. Surfacing those as null keeps
      // consumers from rendering "0 Hz" or "" mid-transition.
      final p = parseAudioParamsNode(<String, dynamic>{
        'format': '',
        'samplerate': 0,
        'channels': '',
        'channel-count': 0,
        'hr-channels': '',
      });
      expect(p.format, isNull);
      expect(p.sampleRate, isNull);
      expect(p.channels, isNull);
      expect(p.channelCount, isNull);
      expect(p.hrChannels, isNull);
    });

    test('missing keys map to null', () {
      final p = parseAudioParamsNode(const <String, dynamic>{});
      expect(p.format, isNull);
      expect(p.sampleRate, isNull);
      expect(p.channels, isNull);
      expect(p.channelCount, isNull);
      expect(p.hrChannels, isNull);
    });

    test('accepts num for samplerate (defensive — mpv uses int64)', () {
      final p = parseAudioParamsNode(<String, dynamic>{
        'samplerate': 44100.0, // implausible but safe to coerce
      });
      expect(p.sampleRate, 44100);
    });

    test('non-map raw → empty AudioParams', () {
      expect(parseAudioParamsNode(null), const AudioParams());
      expect(parseAudioParamsNode('garbage'), const AudioParams());
      expect(parseAudioParamsNode(<dynamic>[]), const AudioParams());
    });
  });
}
