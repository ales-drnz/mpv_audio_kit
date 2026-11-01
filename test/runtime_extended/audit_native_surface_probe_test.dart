// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

// Ground-truth probe: asks the REAL shipped libmpv whether each native
// option/property listed below exists, and of what type, so a libmpv bump
// that drops or renames one fails here instead of at a setter call site.
// Each label names the option or property, with a note where the check
// carries more than existence.
//
// Options are introspected via `option-info/<name>/type` (non-null => the
// option exists; the value is mpv's own type name: Flag/Double/Integer/
// String/Choice/Time/...). Plain properties (not backed by an option) are
// checked against the `property-list`.

@TestOn('mac-os || linux || windows')
library;

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

import '../_helpers/setter_test_helpers.dart';

void main() {
  runtimeSuite(() {
    // Label -> mpv OPTION name. We assert each exists and print its real type.
    const options = <String, String>{
      'demuxer-readahead-secs (must be Double, not int)':
          'demuxer-readahead-secs',
      'audio-fallback-to-null': 'audio-fallback-to-null',
      'cache-pause-initial': 'cache-pause-initial',
      'force-seekable': 'force-seekable',
      'hls-bitrate': 'hls-bitrate',
      'audio-client-name': 'audio-client-name',
      'audio-set-media-role': 'audio-set-media-role',
      'audio-normalize-downmix': 'audio-normalize-downmix',
      'demuxer-cache-dir': 'demuxer-cache-dir',
      'volume-max': 'volume-max',
      'volume-gain-min': 'volume-gain-min',
      'volume-gain-max': 'volume-gain-max',
      'cookies': 'cookies',
      'http-proxy': 'http-proxy',
      'stream-record': 'stream-record',
      'resume-playback (watch-later)': 'resume-playback',
      'cache (sanity: known-good)': 'cache',
    };

    // Label -> mpv PROPERTY name (not option-backed). Checked via property-list.
    const properties = <String, String>{
      'ao-volume': 'ao-volume',
      'ao-mute': 'ao-mute',
      'demuxer-cache-state': 'demuxer-cache-state',
      'playlist-path': 'playlist-path',
      'audio-spdif (sanity)': 'audio-spdif',
      'volume (sanity: known-good)': 'volume',
    };

    group('native surface ground-truth (real libmpv)', () {
      late Player player;
      setUpAll(() async {
        player =
            await buildPlayer(); // ao=null, no fixture needed for introspection
      });
      tearDownAll(() => player.dispose());

      test('every planned OPTION exists in the shipped libmpv', () async {
        final results = <String, String?>{};
        for (final e in options.entries) {
          final type = await player.getRawProperty(
            'option-info/${e.value}/type',
          );
          results[e.key] = type;
        }
        // ignore: avoid_print
        print('\n── OPTIONS (real mpv option-info/<name>/type) ──');
        results.forEach((label, type) {
          // ignore: avoid_print
          print(
            '  ${type == null ? '❌ MISSING' : '✅ ${type.padRight(9)}'}  $label',
          );
        });

        final missing = results.entries
            .where((e) => e.value == null)
            .map((e) => e.key);
        expect(
          missing,
          isEmpty,
          reason: 'these planned options do NOT exist in libmpv: $missing',
        );
      }, timeout: const Timeout(Duration(seconds: 20)));

      test('every planned PROPERTY exists in the shipped libmpv', () async {
        final list = await player.getRawProperty('property-list') ?? '';
        final names = list.split(',').map((s) => s.trim()).toSet();
        // ignore: avoid_print
        print('\n── PROPERTIES (membership in real mpv property-list) ──');
        final missing = <String>[];
        for (final e in properties.entries) {
          final present = names.contains(e.value);
          if (!present) missing.add(e.key);
          // ignore: avoid_print
          print('  ${present ? '✅ present  ' : '❌ MISSING  '}  ${e.key}');
        }
        expect(
          list,
          isNotEmpty,
          reason: 'property-list itself must be readable',
        );
        expect(
          missing,
          isEmpty,
          reason: 'these planned properties are not in property-list: $missing',
        );
      }, timeout: const Timeout(Duration(seconds: 20)));
    });
  });
}
