// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

// Ground-truth probe: asks the REAL shipped libmpv whether every native
// option/property the audit plan relies on actually exists, and of what
// type. This converts "the agents claimed X exists" into "the binary
// confirmed X exists". Anything that prints MISSING is a bogus finding and
// must be dropped from the plan before any Dart code is written for it.
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
    // Plan item -> mpv OPTION name. We assert each exists and print its real type.
    const options = <String, String>{
      'demuxer-readahead-secs (#2 must be Double, not int)':
          'demuxer-readahead-secs',
      'audio-fallback-to-null (#5)': 'audio-fallback-to-null',
      'cache-pause-initial (#6)': 'cache-pause-initial',
      'force-seekable (#13)': 'force-seekable',
      'hls-bitrate (#14)': 'hls-bitrate',
      'audio-client-name (#16)': 'audio-client-name',
      'audio-set-media-role (#18)': 'audio-set-media-role',
      'audio-normalize-downmix (#19)': 'audio-normalize-downmix',
      'demuxer-cache-dir (#20)': 'demuxer-cache-dir',
      'volume-max (#10)': 'volume-max',
      'volume-gain-min (#10)': 'volume-gain-min',
      'volume-gain-max (#10)': 'volume-gain-max',
      'cookies (#24)': 'cookies',
      'http-proxy (#24)': 'http-proxy',
      'stream-record (#D3)': 'stream-record',
      'resume-playback (#9 watch-later)': 'resume-playback',
      'cache (sanity: known-good)': 'cache',
    };

    // Plan item -> mpv PROPERTY name (not option-backed). Checked via property-list.
    const properties = <String, String>{
      'ao-volume (#10)': 'ao-volume',
      'ao-mute (#10)': 'ao-mute',
      'demuxer-cache-state (#17)': 'demuxer-cache-state',
      'playlist-path (#22/D1)': 'playlist-path',
      'audio-spdif (#3 sanity)': 'audio-spdif',
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
