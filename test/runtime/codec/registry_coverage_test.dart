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
//      manifest (one entry per typed effect class) and push each
//      through the public API.
//      A missing filter surfaces as a "Cannot find filter" / "no such
//      filter" / "unknown filter" entry on `Player.stream.log`.

@TestOn('mac-os || linux || windows')
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

import '../../_helpers/filter_sets.dart';
import '../../_helpers/setter_test_helpers.dart';
import '../../generated/audio_filter_names.dart';

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

/// The filter set after each one the check tries. It never exists, and
/// mpv keeps its log in order, so its line comes after any line of the
/// filter tried before it: the check waits for it, with a ceiling, instead
/// of a fixed window that a slow log could outlast.
const _sentinel = 'lavfi-mak-sentinel-filter-does-not-exist';

/// Whether a log line says that a filter is not in libavfilter.
bool _saysMissing(String text) {
  final m = text.toLowerCase();
  return m.contains('no such filter') ||
      m.contains('cannot find filter') ||
      m.contains('unknown filter') ||
      m.contains("isn't supported");
}

/// Sets [filter], then [_sentinel], and returns the lines of [lines] (what
/// the caller's listener keeps of [_saysMissing]) that came before the
/// sentinel's: those of [filter]. The meta-tests run it as the check does.
Future<List<String>> _missingLines(
  Player player,
  List<String> lines,
  String filter,
) async {
  lines.clear();
  for (final f in [filter, _sentinel]) {
    try {
      await player.setAudioEffects([RawAudioEffect(f)]);
    } catch (_) {
      // Rejection at the typed-setter boundary is fine: what counts is
      // whether a "filter not found" log entry fires.
    }
  }
  await waitUntil(
    () => lines.any((l) => l.contains(_sentinel)),
    timeout: const Duration(seconds: 10),
    reason:
        'A bogus lavfi-* filter must produce a recognizable log entry. If '
        'this fires, libmpv changed its phrasing: update _saysMissing.',
  );
  return lines.takeWhile((l) => !l.contains(_sentinel)).toList();
}

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
        // Without the fixture no filter would be built and the test would
        // pass without checking anything: a missing one fails the load.
        final fix = '${Directory.current.path}/test/fixtures/sine_440hz_1s.wav';
        await openAndWaitForLoad(player, fix);
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
          if (_saysMissing(entry.text)) cannotFind.add(entry.text.trim());
        });

        // Filters of kFiltersNeedingParams that don't accept a no-arg
        // lavfi instantiation. Each entry is the minimum arg that
        // satisfies libavfilter's required-options check.
        const argDefaults = <String, String>{
          'channelmap': 'map=0|1',
          'pan': 'stereo|c0=c0|c1=c1',
        };

        // Filters that need an external resource are left out here: the
        // generated audio_effects_runtime_coverage_test builds them with
        // the model file of test/fixtures.
        const registrationOnly = <String>{
          'arnndn', // requires a .rnnn model file
        };

        final missing = <String>[];

        // The others start from their bare name in
        // audio_effects_chain_runtime_test, which fails on any error, a
        // missing filter included.
        for (final name in kAudioFilterNames) {
          if (!kFiltersNeedingParams.contains(name)) continue;
          if (registrationOnly.contains(name)) continue;
          final arg = argDefaults[name];
          final filterStr = arg == null || arg.isEmpty
              ? 'lavfi-$name'
              : 'lavfi-$name=$arg';
          final lines = await _missingLines(player, cannotFind, filterStr);
          if (lines.isNotEmpty) missing.add('$name → ${lines.first}');
        }
        try {
          await player.setAudioEffects(const []);
        } catch (_) {}

        await logSub.cancel();

        expect(
          missing,
          isEmpty,
          reason:
              'These filters have a typed effect class '
              'but are NOT registered in the bundled libmpv '
              'binary:\n  ${missing.join("\n  ")}',
        );
      }, timeout: const Timeout(Duration(seconds: 120)));

      // Meta-tests: the detection the check above runs. If these stop
      // failing, the check could pass silently when a filter goes missing.
      group('detection', () {
        late List<String> lines;
        late StreamSubscription<MpvLogEntry> logSub;
        // A log that reaches the listener this much later than mpv wrote
        // it, line by line in order: what a slow host gives.
        var lag = Duration.zero;

        setUp(() {
          lines = <String>[];
          lag = Duration.zero;
          logSub = player.stream.log.listen((entry) {
            if (!_saysMissing(entry.text)) return;
            final text = entry.text.trim();
            if (lag == Duration.zero) {
              lines.add(text);
            } else {
              Future<void>.delayed(lag, () => lines.add(text));
            }
          });
        });

        tearDown(() async {
          await logSub.cancel();
          try {
            await player.setAudioEffects(const []);
          } catch (_) {}
        });

        test('catches a known-missing filter', () async {
          final found = await _missingLines(
            player,
            lines,
            'lavfi-this-filter-does-not-exist',
          );
          expect(found, hasLength(1));
          expect(found.single, contains('this-filter-does-not-exist'));
        });

        test('catches it when its log comes 300 ms late', () async {
          lag = const Duration(milliseconds: 300);
          final found = await _missingLines(
            player,
            lines,
            'lavfi-this-filter-does-not-exist',
          );
          expect(found, hasLength(1));
        });

        test('reports nothing for a filter that is there', () async {
          expect(
            await _missingLines(player, lines, 'lavfi-acompressor'),
            isEmpty,
          );
        });
      });
    });
  });
}
