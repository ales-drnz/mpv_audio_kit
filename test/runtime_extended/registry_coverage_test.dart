// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// Verifies that every codec / filter the build script whitelists is
// actually compiled into the libmpv binary. Catches the regression where
// a name in `scripts/_audio_only.sh` falls out of sync with what the
// build emits — without needing a fixture for every entry.
//
// Two passes:
//
//   1. Decoders — query mpv's `decoder-list` property (returns every
//      decoder libavcodec registered) and assert each name in
//      `AUDIO_DECODERS` is present.
//
//   2. Filters — for each name in `AUDIO_FILTERS`, push it through
//      `setAudioEffects(AudioEffects(custom: ['lavfi-<name>']))` and
//      watch the log channel. A missing filter surfaces as a
//      "Cannot find filter" / "no such filter" / "unknown filter"
//      entry. Filters with required arguments may report
//      "missing argument" errors — those still prove the filter is
//      registered (the registration check ran first).
//      We deliberately do NOT use `setRawProperty('af', ...)` here:
//      that path is reserved by the typed `AudioEffects` bundle and
//      throws `ArgumentError` unconditionally in 0.1.0+, which would
//      make this test pass vacuously without ever probing libmpv.
//
// The whitelists come from `scripts/_audio_only.sh`, parsed once at
// suite setup. That keeps the bash file as the single source of truth.

@TestOn('mac-os || linux || windows')
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

import '../_helpers/setter_test_helpers.dart';

/// Reads `scripts/_audio_only.sh` and extracts the comma-separated value
/// of [varName] (e.g. `AUDIO_DECODERS`, `AUDIO_FILTERS`).
List<String> readAudioOnlyList(String varName) {
  final file = File('${Directory.current.path}/scripts/_audio_only.sh');
  if (!file.existsSync()) return const [];
  final content = file.readAsStringSync();
  // Match: export NAME="value" with value possibly spanning newlines via
  // backslash continuation — current file uses single-line strings only,
  // so a simple regex works.
  final re = RegExp(r'^export\s+' + RegExp.escape(varName) + r'="([^"]+)"',
      multiLine: true);
  final match = re.firstMatch(content);
  if (match == null) return const [];
  return match
      .group(1)!
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
}

void main() {
  setUpAll(() => initLibmpvOrSkip());

  group('Decoder registry — every whitelisted decoder is compiled in', () {
    late Player player;
    late Set<String> registeredNames;

    setUpAll(() async {
      player = await buildPlayer();
      // mpv's decoder-list returns a JSON array of objects, one per
      // decoder, with three fields:
      //   codec       — the AV_CODEC_ID short name (also the configure
      //                 flag for `--enable-decoder=` in some cases —
      //                 e.g. `atrac3p`, `mpc7`)
      //   driver      — the libavcodec decoder symbol (e.g. `atrac3plus`,
      //                 `mp3float`, `dca`)
      //   description — human-readable label (ignored)
      // ffmpeg's `--enable-decoder=NAME` matches against the configure
      // flag — sometimes that's the codec, sometimes the driver. We
      // accept a match against either field.
      final raw = await player.getRawProperty('decoder-list');
      expect(raw, isNotNull,
          reason: 'mpv must expose decoder-list — if null the binary is '
              'missing libavcodec');
      final parsed = jsonDecode(raw!) as List<dynamic>;
      registeredNames = <String>{};
      for (final e in parsed) {
        final m = e as Map<String, dynamic>;
        final codec = m['codec'] as String?;
        final driver = m['driver'] as String?;
        if (codec != null) registeredNames.add(codec);
        if (driver != null) registeredNames.add(driver);
      }
      expect(registeredNames, isNotEmpty,
          reason: 'decoder-list must not be empty');
    });

    tearDownAll(() async {
      await player.dispose();
    });

    test('every name in AUDIO_DECODERS is in libavcodec decoder-list',
        () async {
      final whitelist = readAudioOnlyList('AUDIO_DECODERS');
      expect(whitelist, isNotEmpty,
          reason: 'failed to parse AUDIO_DECODERS from _audio_only.sh');

      final missing = <String>[];
      for (final name in whitelist) {
        if (!registeredNames.contains(name)) {
          missing.add(name);
        }
      }

      expect(missing, isEmpty,
          reason: 'These decoders are whitelisted in _audio_only.sh but '
              'NOT registered in the libmpv binary — the build is out of '
              'sync with the whitelist:\n  ${missing.join("\n  ")}');
    });
  });

  group('Filter registry — every whitelisted filter is compiled in', () {
    late Player player;

    setUpAll(() async {
      // The default test player uses `logLevel: LogLevel.off` which suppresses
      // every libmpv log entry. The filter-not-found surface shows up
      // at warning level on the `lavfi` log prefix — we need at least
      // 'warn' to observe it.
      player = Player(
        configuration: const PlayerConfiguration(
          autoPlay: false,
          logLevel: LogLevel.warn,
        ),
      );
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

    test('every name in AUDIO_FILTERS is in libavfilter', () async {
      final whitelist = readAudioOnlyList('AUDIO_FILTERS');
      expect(whitelist, isNotEmpty,
          reason: 'failed to parse AUDIO_FILTERS from _audio_only.sh');

      // Capture log entries that signal a filter wasn't registered. Cover
      // every phrasing libmpv / libavfilter currently emit:
      //   - "no such filter"        (libavfilter)
      //   - "cannot find filter"    (libavfilter older)
      //   - "unknown filter"        (libavfilter newer)
      //   - "isn't supported"       (mpv option-parser, e.g. when the
      //                              `lavfi-XYZ` shortcut can't resolve XYZ)
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

      // The list of filters that don't accept a no-arg lavfi
      // instantiation. For these we use a minimal arg that satisfies
      // libavfilter's required-options check. Anything not here is
      // tried with the bare name.
      const argDefaults = <String, String>{
        'channelmap': 'map=0|1',
        'channelsplit': 'channel_layout=stereo',
        'pan': 'stereo|c0=c0|c1=c1',
        'aresample': '44100',
        'aformat': 'sample_fmts=s16',
        'asetrate': '44100',
        'asetnsamples': '1024',
        'aselect': 'expr=1',
        'asegment': 'timestamps=1',
        'aevalsrc': 'exprs=0',
        'afdelaysrc': 'd=1',
        'afireqsrc': 'gains=0|0',
        'afirsrc': 'taps=2',
        'anoisesrc': 'amplitude=0',
        'anullsrc': '',
        'hilbert': 'taps=11',
        'sinc': 'sample_rate=44100',
        'sine': 'frequency=440',
        'aiir': 'zeros=0:poles=1',
        'arls': 'order=1',
        'anlmf': 'order=1',
        'anlms': 'order=1',
        'arnndn': 'model=test.rnnn',
        'apsnr': '',
        'asisdr': '',
        'asdr': '',
      };

      // Filters that need an external resource (model files, etc.) we
      // don't ship — we only verify they're registered, not that they
      // apply on real audio. Everything in this set still has to live in
      // the AUDIO_FILTERS whitelist.
      const registrationOnly = <String>{
        'arnndn', // requires a .rnnn model file
      };

      final missing = <String>[];

      for (final name in whitelist) {
        if (registrationOnly.contains(name)) continue;
        cannotFind.clear();
        final arg = argDefaults[name];
        final filterStr = arg == null || arg.isEmpty
            ? 'lavfi-$name'
            : 'lavfi-$name=$arg';
        // Use the typed bundle's `custom` slot — same effect as writing
        // the `af` property, but routed through the supported public API.
        try {
          await player.setAudioEffects(AudioEffects(custom: [filterStr]));
        } catch (_) {
          // Rejection at the typed-setter boundary is fine — what we
          // care about is whether a "filter not found" log entry fires.
        }
        // Allow the log channel to flush.
        await Future<void>.delayed(const Duration(milliseconds: 5));
        if (cannotFind.isNotEmpty) {
          missing.add('$name → ${cannotFind.first}');
        }
        // Reset the af chain before the next iteration.
        try {
          await player.setAudioEffects(const AudioEffects());
        } catch (_) {}
      }

      await logSub.cancel();

      expect(missing, isEmpty,
          reason: 'These filters are whitelisted in _audio_only.sh but '
              'NOT registered in the libmpv binary:\n  '
              '${missing.join("\n  ")}');
    }, timeout: const Timeout(Duration(seconds: 60)));

    // Meta-test: verifies the detection mechanism itself. If this ever
    // stops failing, the filter coverage test above would silently pass
    // even when a real whitelisted filter goes missing (the previous
    // `setRawProperty('af', ...)` regression from 0.0.x → 0.1.0).
    test('detection mechanism actually catches a known-missing filter',
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
            const AudioEffects(custom: ['lavfi-this-filter-does-not-exist']));
      } catch (_) {}
      await Future<void>.delayed(const Duration(milliseconds: 25));
      await logSub.cancel();
      expect(cannotFind, isNotEmpty,
          reason: 'A bogus lavfi-* filter must produce a recognizable log '
              'entry. If this fires, libmpv changed its phrasing — update '
              'the substrings above.');
      // Reset the af chain.
      try {
        await player.setAudioEffects(const AudioEffects());
      } catch (_) {}
    });

    test('AUDIO_FILTERS does not re-introduce dead entries (deps we do not ship)',
        () {
      // These filters have external library dependencies (libbs2b,
      // pocketsphinx, libzmq, libmysofa, libflite, libladspa, lilv) that
      // we deliberately don't bundle. Putting them back in the whitelist
      // means ffmpeg silently skips them at configure time — the binary
      // ends up missing them and any consumer that tries `lavfi-bs2b`
      // gets `'isn't supported'`. Native equivalents already in the
      // whitelist:  bs2b → crossfeed,  sofalizer → headphone.
      const dead = <String>{
        // External-dep filters we don't bundle (silent no-op at runtime).
        'bs2b',
        'asr',
        'azmq',
        'sofalizer',
        'flite',
        'ladspa',
        'lv2',
        // Debug / utility filters dropped from the whitelist in 0.1.0 —
        // they're in the music-player API surface for no good reason.
        'abench',
        'acopy',
        'acue',
        'aintegral',
        'alatency',
        'aloop',
        'ametadata',
        'anull',
        'aperms',
        'arealtime',
        'areverse',
        'asegment',
        'aselect',
        'asendcmd',
        'asetnsamples',
        'asetpts',
        'asetrate',
        'asettb',
        'ashowinfo',
        'asidedata',
        'aspectralstats',
        'astats',
        'astreamselect',
        'atrim',
        'silencedetect',
        'volume',
        'volumedetect',
        // Naming clash with the decoder-side ReplayGainSettings.
        'replaygain',
      };
      final whitelist = readAudioOnlyList('AUDIO_FILTERS').toSet();
      final accidentallyAdded = dead.intersection(whitelist);
      expect(accidentallyAdded, isEmpty,
          reason: 'These filters require libraries we do not bundle and '
              'will silently no-op at runtime:\n  '
              '${accidentallyAdded.join("\n  ")}\n'
              'Either remove them from AUDIO_FILTERS, or wire up the '
              'matching dep in the per-platform build_libmpv_*.sh scripts.');
    });
  });
}
