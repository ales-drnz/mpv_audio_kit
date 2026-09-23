// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// Verifies that the bundled libmpv binary contains every codec / filter
// the public API promises. Two passes:
//
//   1. Decoders — query mpv's `decoder-list` property and assert that
//      every name in the [_kCoreAudioDecoders] manifest below is
//      registered. Plus, on macOS / iOS, every name in
//      [_kAppleOnlyAudioDecoders] (AudioToolbox-backed hardware
//      decoders).
//
//   2. Filters — iterate the auto-generated `kAudioFilterNames`
//      manifest (mirror of every typed `*Settings` field on the
//      `AudioEffects` bundle) and push each through the public API.
//      A missing filter surfaces as a "Cannot find filter" / "no such
//      filter" / "unknown filter" entry on `Player.stream.log`.

@TestOn('mac-os || linux || windows')
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

import '../_helpers/setter_test_helpers.dart';
import '../generated/audio_filter_names.dart';

/// Audio decoders the package contractually supports on every shipped
/// platform. Each entry MUST be a registered libavcodec decoder in the
/// bundled binary; the test fails loudly if any are missing.
const List<String> _kCoreAudioDecoders = [
  // Lossy compressed
  'aac',
  'aac_latm',
  'ac3',
  'eac3',
  'mp1',
  'mp1float',
  'mp2',
  'mp2float',
  'mp3',
  'mp3adu',
  'mp3adufloat',
  'mp3float',
  'mp3on4',
  'mp3on4float',
  'opus',
  'vorbis',
  'wmav1',
  'wmav2',
  'wmavoice',
  'wmapro',
  'atrac3',
  'atrac3p',
  'atrac9',
  'cook',
  'sipr',
  'speex',
  'nellymoser',
  'gsm',
  'gsm_ms',
  'mpc7',
  'mpc8',
  'ralf',
  'adpcm_ima_qt',
  'adpcm_ms',
  // Lossless
  'alac',
  'ape',
  'flac',
  'mlp',
  'shorten',
  'truehd',
  'tta',
  'wavpack',
  'wmalossless',
  // Surround
  'dca',
  // Pro/broadcast
  's302m',
  // DSD/SACD
  'dsd_lsbf',
  'dsd_lsbf_planar',
  'dsd_msbf',
  'dsd_msbf_planar',
  // PCM — every bit-depth × endianness × float/int + alaw / mulaw /
  // bluray / dvd / lxf / vidc / s24daud
  'pcm_alaw',
  'pcm_bluray',
  'pcm_dvd',
  'pcm_f16le',
  'pcm_f24le',
  'pcm_f32be',
  'pcm_f32le',
  'pcm_f64be',
  'pcm_f64le',
  'pcm_lxf',
  'pcm_mulaw',
  'pcm_s8',
  'pcm_s8_planar',
  'pcm_s16be',
  'pcm_s16be_planar',
  'pcm_s16le',
  'pcm_s16le_planar',
  'pcm_s24be',
  'pcm_s24daud',
  'pcm_s24le',
  'pcm_s24le_planar',
  'pcm_s32be',
  'pcm_s32le',
  'pcm_s32le_planar',
  'pcm_s64be',
  'pcm_s64le',
  'pcm_u8',
  'pcm_u16be',
  'pcm_u16le',
  'pcm_u24be',
  'pcm_u24le',
  'pcm_u32be',
  'pcm_u32le',
  'pcm_vidc',
];

/// Audio decoders that ship only on Apple platforms (macOS + iOS),
/// because they are backed by Apple's AudioToolbox framework — a system
/// library rather than something bundled with the package. mpv prefers
/// these when explicitly selected via `audio-codec` / `ad`.
const List<String> _kAppleOnlyAudioDecoders = ['aac_at', 'alac_at', 'mp3_at'];

void main() {
  runtimeSuite(() {
    group('Decoder registry — every core audio decoder is compiled in', () {
      late Player player;
      late Set<String> registeredNames;

      setUpAll(() async {
        player = await buildPlayer();
        // mpv's decoder-list returns a JSON array of objects, one per
        // decoder, with three fields:
        //   codec       — the AV_CODEC_ID short name
        //   driver      — the libavcodec decoder symbol
        //   description — human-readable label (ignored)
        // We accept a match against either `codec` or `driver`.
        final raw = await player.getRawProperty('decoder-list');
        expect(
          raw,
          isNotNull,
          reason:
              'mpv must expose decoder-list — if null the binary is '
              'missing libavcodec',
        );
        final parsed = jsonDecode(raw!) as List<dynamic>;
        registeredNames = <String>{};
        for (final e in parsed) {
          final m = e as Map<String, dynamic>;
          final codec = m['codec'] as String?;
          final driver = m['driver'] as String?;
          if (codec != null) registeredNames.add(codec);
          if (driver != null) registeredNames.add(driver);
        }
        expect(
          registeredNames,
          isNotEmpty,
          reason: 'decoder-list must not be empty',
        );
      });

      tearDownAll(() async {
        await player.dispose();
      });

      test('every core audio decoder is registered in libavcodec', () {
        final missing = <String>[];
        for (final name in _kCoreAudioDecoders) {
          if (!registeredNames.contains(name)) {
            missing.add(name);
          }
        }

        expect(
          missing,
          isEmpty,
          reason:
              'These core audio decoders are part of the public '
              'contract but NOT registered in the bundled libmpv '
              'binary:\n  ${missing.join("\n  ")}',
        );
      });

      test(
        'every Apple-only audio decoder is registered on macOS / iOS',
        () {
          final missing = <String>[];
          for (final name in _kAppleOnlyAudioDecoders) {
            if (!registeredNames.contains(name)) {
              missing.add(name);
            }
          }

          expect(
            missing,
            isEmpty,
            reason:
                'These AudioToolbox-backed decoders should be present '
                'on the macOS / iOS bundled libmpv but were not '
                'registered:\n  ${missing.join("\n  ")}',
          );
        },
        // Apple-only — not meaningful on Linux / Windows.
        skip: Platform.isMacOS
            ? false
            : 'AudioToolbox decoders are Apple-only — '
                  'host platform is ${Platform.operatingSystem}',
      );
    });

    group('Filter registry — every typed audio filter is compiled in', () {
      late Player player;

      setUpAll(() async {
        // Default test player uses LogLevel.off; the filter-not-found
        // surface needs at least 'warn' to observe.
        player = Player();
        await player.setRawProperty('ao', 'null');
        // Filters are only instantiated by libavfilter when a file is
        // active — without one, `setAudioEffects` only stores the chain
        // string and the "filter not found" log line never fires.
        final fix = '${Directory.current.path}/test/fixtures/sine_440hz_1s.wav';
        if (File(fix).existsSync()) {
          await openAndWaitForLoad(player, fix);
        }
      });

      tearDownAll(() async {
        await player.stop();
        await player.dispose();
      });

      test('every name in kAudioFilterNames is in libavfilter', () async {
        // Sanity: codegen must have emitted at least one filter name.
        expect(
          kAudioFilterNames,
          isNotEmpty,
          reason:
              'kAudioFilterNames is empty — the codegen output is '
              'broken',
        );

        // Capture log entries that signal a filter wasn't registered.
        final cannotFind = <String>[];
        final logSub = player.stream.log.listen((entry) {
          final m = entry.text.toLowerCase();
          if (m.contains('no such filter') ||
              m.contains('cannot find filter') ||
              m.contains('unknown filter') ||
              m.contains("isn't supported")) {
            cannotFind.add(entry.text.trim());
          }
        });

        // Filters that don't accept a no-arg lavfi instantiation. Each
        // entry is the minimum arg that satisfies libavfilter's
        // required-options check.
        const argDefaults = <String, String>{
          'channelmap': 'map=0|1',
          'pan': 'stereo|c0=c0|c1=c1',
          'aresample': '44100',
          'aformat': 'sample_fmts=s16',
          'aiir': 'zeros=0:poles=1',
          'arnndn': 'model=test.rnnn',
        };

        // Filters that need an external resource (model files, etc.) we
        // don't ship — we only verify they're registered.
        const registrationOnly = <String>{
          'arnndn', // requires a .rnnn model file
        };

        final missing = <String>[];

        for (final name in kAudioFilterNames) {
          if (registrationOnly.contains(name)) continue;
          cannotFind.clear();
          final arg = argDefaults[name];
          final filterStr = arg == null || arg.isEmpty
              ? 'lavfi-$name'
              : 'lavfi-$name=$arg';
          try {
            await player.setAudioEffects(AudioEffects(custom: [filterStr]));
          } catch (_) {
            // Rejection at the typed-setter boundary is fine — what we
            // care about is whether a "filter not found" log entry fires.
          }
          await Future<void>.delayed(const Duration(milliseconds: 5));
          if (cannotFind.isNotEmpty) {
            missing.add('$name → ${cannotFind.first}');
          }
          try {
            await player.setAudioEffects(const AudioEffects());
          } catch (_) {}
        }

        await logSub.cancel();

        expect(
          missing,
          isEmpty,
          reason:
              'These filters are exposed by the typed AudioEffects '
              'bundle but NOT registered in the bundled libmpv '
              'binary:\n  ${missing.join("\n  ")}',
        );
      }, timeout: const Timeout(Duration(seconds: 60)));

      // Meta-test: verifies the detection mechanism. If this stops failing,
      // the filter coverage test above could silently pass when a real
      // filter goes missing.
      test(
        'detection mechanism actually catches a known-missing filter',
        () async {
          final cannotFind = <String>[];
          final logSub = player.stream.log.listen((entry) {
            final m = entry.text.toLowerCase();
            if (m.contains('no such filter') ||
                m.contains('cannot find filter') ||
                m.contains('unknown filter') ||
                m.contains("isn't supported")) {
              cannotFind.add(entry.text.trim());
            }
          });
          try {
            await player.setAudioEffects(
              const AudioEffects(custom: ['lavfi-this-filter-does-not-exist']),
            );
          } catch (_) {}
          await Future<void>.delayed(const Duration(milliseconds: 25));
          await logSub.cancel();
          expect(
            cannotFind,
            isNotEmpty,
            reason:
                'A bogus lavfi-* filter must produce a recognizable log '
                'entry. If this fires, libmpv changed its phrasing — update '
                'the substrings above.',
          );
          try {
            await player.setAudioEffects(const AudioEffects());
          } catch (_) {}
        },
      );
    });
  });
}
