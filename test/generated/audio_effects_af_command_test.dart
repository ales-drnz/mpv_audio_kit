// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license
// that can be found in the LICENSE file.
//
// AUTO-GENERATED — do NOT edit by hand.
//
// Runtime af-command coverage. For every filter whose ffmpeg source
// declares `.process_command` (the schema's `supports_commands` flag
// — the gate for `AudioEffects.diffCommands`), enable the filter on a
// live playing mpv, then change each runtime-tunable option through
// `Player.updateAudioEffects` and assert the `af` property string did
// NOT change: the update was applied to the live graph in place via
// `af-command` instead of a full chain rewrite. A rewrite here means
// the flag (or an option's runtime flag) is wrong for the SHIPPED
// binary — fix the codegen and regenerate.
//
// Probe values stay close to each option's default: corner values can
// be DYNAMICALLY invalid even when statically inside the AVOption
// range (e.g. a biquad frequency above Nyquist), and a failed runtime
// reconfigure poisons the filter instance — every later command on it
// fails too, which would read here as a bogus unsupported command.
//
// Enum, duration and free-string options have no schema-derivable safe
// alternate value and are skipped (string-only filters carry curated
// hand-probed values instead). Command-capable filters with NO
// runtime-tunable options (anequalizer, compensationdelay) can never
// receive a diff command, so there is nothing to validate for them.

@TestOn('mac-os || linux || windows')
library;

// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, lines_longer_than_80_chars, unnecessary_const

import 'dart:io';

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

import '../_helpers/libmpv_resolver.dart';
import '../_helpers/setter_test_helpers.dart';

typedef AfCommandUpdate = ({
  String label,
  AudioEffects Function(AudioEffects) apply,
});

typedef AfCommandCase = ({
  String filter,
  String field,
  AudioEffects bundle,
  List<AfCommandUpdate> updates,
});

void main() {
  // The LONG fixture on purpose: the file loops for the whole run and
  // every loop wrap resets the filter chain — a shorter file would
  // multiply the command-vs-chain-reset races the retry below absorbs.
  final fixturePath = '${Directory.current.path}/test/fixtures/sine_5s.flac';
  final arnndnModelPath =
      '${Directory.current.path}/test/fixtures/arnndn_model.rnnn';

  late Player player;

  runtimeSuite(fixturePath: fixturePath, extraFixtures: [arnndnModelPath], () {
    setUpAll(() async {
      player = Player(
        configuration: const PlayerConfiguration(logLevel: LogLevel.error),
      );
      await player.setRawProperty('ao', 'null');
      // af-command needs a LIVE filter graph as its target: keep the
      // (silent) fixture playing on a loop for the whole run.
      await player.setLoop(Loop.file);
      await player.open(Media(fixturePath), play: true);
      await player.stream.seekCompleted.first.timeout(
        const Duration(seconds: 10),
      );
    });

    tearDownAll(() async {
      await player.dispose();
    });

    test(
      'every supports_commands filter applies af-command on its runtime options',
      () async {
        final cases = <AfCommandCase>[
          (
            filter: 'acompressor',
            field: 'acompressor',
            bundle: const AudioEffects(
              acompressor: AcompressorSettings(enabled: true),
            ),
            updates: <AfCommandUpdate>[
              (
                label: 'attack=21.0',
                apply: (AudioEffects e) =>
                    e.updateAcompressor((s) => s.copyWith(attack: 21.0)),
              ),
              (
                label: 'knee=3.82843',
                apply: (AudioEffects e) =>
                    e.updateAcompressor((s) => s.copyWith(knee: 3.82843)),
              ),
              (
                label: 'level_in=2.0',
                apply: (AudioEffects e) =>
                    e.updateAcompressor((s) => s.copyWith(level_in: 2.0)),
              ),
              (
                label: 'level_sc=2.0',
                apply: (AudioEffects e) =>
                    e.updateAcompressor((s) => s.copyWith(level_sc: 2.0)),
              ),
              (
                label: 'makeup=2.0',
                apply: (AudioEffects e) =>
                    e.updateAcompressor((s) => s.copyWith(makeup: 2.0)),
              ),
              (
                label: 'mix=0.5',
                apply: (AudioEffects e) =>
                    e.updateAcompressor((s) => s.copyWith(mix: 0.5)),
              ),
              (
                label: 'ratio=3.0',
                apply: (AudioEffects e) =>
                    e.updateAcompressor((s) => s.copyWith(ratio: 3.0)),
              ),
              (
                label: 'release=251.0',
                apply: (AudioEffects e) =>
                    e.updateAcompressor((s) => s.copyWith(release: 251.0)),
              ),
              (
                label: 'threshold=0.5625',
                apply: (AudioEffects e) =>
                    e.updateAcompressor((s) => s.copyWith(threshold: 0.5625)),
              ),
            ],
          ),
          (
            filter: 'acrusher',
            field: 'acrusher',
            bundle: const AudioEffects(
              acrusher: AcrusherSettings(enabled: true),
            ),
            updates: <AfCommandUpdate>[
              (
                label: 'aa=0.75',
                apply: (AudioEffects e) =>
                    e.updateAcrusher((s) => s.copyWith(aa: 0.75)),
              ),
              (
                label: 'bits=9.0',
                apply: (AudioEffects e) =>
                    e.updateAcrusher((s) => s.copyWith(bits: 9.0)),
              ),
              (
                label: 'dc=2.0',
                apply: (AudioEffects e) =>
                    e.updateAcrusher((s) => s.copyWith(dc: 2.0)),
              ),
              (
                label: 'level_in=2.0',
                apply: (AudioEffects e) =>
                    e.updateAcrusher((s) => s.copyWith(level_in: 2.0)),
              ),
              (
                label: 'level_out=2.0',
                apply: (AudioEffects e) =>
                    e.updateAcrusher((s) => s.copyWith(level_out: 2.0)),
              ),
              (
                label: 'lfo=true',
                apply: (AudioEffects e) =>
                    e.updateAcrusher((s) => s.copyWith(lfo: true)),
              ),
              (
                label: 'lforange=21.0',
                apply: (AudioEffects e) =>
                    e.updateAcrusher((s) => s.copyWith(lforange: 21.0)),
              ),
              (
                label: 'lforate=1.3',
                apply: (AudioEffects e) =>
                    e.updateAcrusher((s) => s.copyWith(lforate: 1.3)),
              ),
              (
                label: 'mix=0.75',
                apply: (AudioEffects e) =>
                    e.updateAcrusher((s) => s.copyWith(mix: 0.75)),
              ),
              (
                label: 'samples=2.0',
                apply: (AudioEffects e) =>
                    e.updateAcrusher((s) => s.copyWith(samples: 2.0)),
              ),
            ],
          ),
          (
            filter: 'adelay',
            field: 'adelay',
            bundle: const AudioEffects(
              adelay: AdelaySettings(enabled: true, delays: '100'),
            ),
            updates: <AfCommandUpdate>[
              (
                label: 'delays=400',
                apply: (AudioEffects e) =>
                    e.updateAdelay((s) => s.copyWith(delays: '400')),
              ),
            ],
          ),
          (
            filter: 'adenorm',
            field: 'adenorm',
            bundle: const AudioEffects(adenorm: AdenormSettings(enabled: true)),
            updates: <AfCommandUpdate>[
              (
                label: 'level=-350.0',
                apply: (AudioEffects e) =>
                    e.updateAdenorm((s) => s.copyWith(level: -350.0)),
              ),
            ],
          ),
          (
            filter: 'adrc',
            field: 'adrc',
            bundle: const AudioEffects(adrc: AdrcSettings(enabled: true)),
            updates: <AfCommandUpdate>[
              (
                label: 'attack=51.0',
                apply: (AudioEffects e) =>
                    e.updateAdrc((s) => s.copyWith(attack: 51.0)),
              ),
              (
                label: 'release=101.0',
                apply: (AudioEffects e) =>
                    e.updateAdrc((s) => s.copyWith(release: 101.0)),
              ),
            ],
          ),
          (
            filter: 'adynamicequalizer',
            field: 'adynamicequalizer',
            bundle: const AudioEffects(
              adynamicequalizer: AdynamicequalizerSettings(enabled: true),
            ),
            updates: <AfCommandUpdate>[
              (
                label: 'attack=21.0',
                apply: (AudioEffects e) =>
                    e.updateAdynamicequalizer((s) => s.copyWith(attack: 21.0)),
              ),
              (
                label: 'dfrequency=1001.0',
                apply: (AudioEffects e) => e.updateAdynamicequalizer(
                  (s) => s.copyWith(dfrequency: 1001.0),
                ),
              ),
              (
                label: 'dqfactor=2.0',
                apply: (AudioEffects e) =>
                    e.updateAdynamicequalizer((s) => s.copyWith(dqfactor: 2.0)),
              ),
              (
                label: 'makeup=1.0',
                apply: (AudioEffects e) =>
                    e.updateAdynamicequalizer((s) => s.copyWith(makeup: 1.0)),
              ),
              (
                label: 'range=51.0',
                apply: (AudioEffects e) =>
                    e.updateAdynamicequalizer((s) => s.copyWith(range: 51.0)),
              ),
              (
                label: 'ratio=2.0',
                apply: (AudioEffects e) =>
                    e.updateAdynamicequalizer((s) => s.copyWith(ratio: 2.0)),
              ),
              (
                label: 'release=201.0',
                apply: (AudioEffects e) => e.updateAdynamicequalizer(
                  (s) => s.copyWith(release: 201.0),
                ),
              ),
              (
                label: 'tfrequency=1001.0',
                apply: (AudioEffects e) => e.updateAdynamicequalizer(
                  (s) => s.copyWith(tfrequency: 1001.0),
                ),
              ),
              (
                label: 'threshold=1.0',
                apply: (AudioEffects e) => e.updateAdynamicequalizer(
                  (s) => s.copyWith(threshold: 1.0),
                ),
              ),
              (
                label: 'tqfactor=2.0',
                apply: (AudioEffects e) =>
                    e.updateAdynamicequalizer((s) => s.copyWith(tqfactor: 2.0)),
              ),
            ],
          ),
          (
            filter: 'adynamicsmooth',
            field: 'adynamicsmooth',
            bundle: const AudioEffects(
              adynamicsmooth: AdynamicsmoothSettings(enabled: true),
            ),
            updates: <AfCommandUpdate>[
              (
                label: 'basefreq=22051.0',
                apply: (AudioEffects e) => e.updateAdynamicsmooth(
                  (s) => s.copyWith(basefreq: 22051.0),
                ),
              ),
              (
                label: 'sensitivity=3.0',
                apply: (AudioEffects e) =>
                    e.updateAdynamicsmooth((s) => s.copyWith(sensitivity: 3.0)),
              ),
            ],
          ),
          (
            filter: 'aemphasis',
            field: 'aemphasis',
            bundle: const AudioEffects(
              aemphasis: AemphasisSettings(enabled: true),
            ),
            updates: <AfCommandUpdate>[
              (
                label: 'level_in=2.0',
                apply: (AudioEffects e) =>
                    e.updateAemphasis((s) => s.copyWith(level_in: 2.0)),
              ),
              (
                label: 'level_out=2.0',
                apply: (AudioEffects e) =>
                    e.updateAemphasis((s) => s.copyWith(level_out: 2.0)),
              ),
            ],
          ),
          (
            filter: 'aexciter',
            field: 'aexciter',
            bundle: const AudioEffects(
              aexciter: AexciterSettings(enabled: true),
            ),
            updates: <AfCommandUpdate>[
              (
                label: 'amount=2.0',
                apply: (AudioEffects e) =>
                    e.updateAexciter((s) => s.copyWith(amount: 2.0)),
              ),
              (
                label: 'blend=1.0',
                apply: (AudioEffects e) =>
                    e.updateAexciter((s) => s.copyWith(blend: 1.0)),
              ),
              (
                label: 'ceil=10000.0',
                apply: (AudioEffects e) =>
                    e.updateAexciter((s) => s.copyWith(ceil: 10000.0)),
              ),
              (
                label: 'drive=9.25',
                apply: (AudioEffects e) =>
                    e.updateAexciter((s) => s.copyWith(drive: 9.25)),
              ),
              (
                label: 'freq=7501.0',
                apply: (AudioEffects e) =>
                    e.updateAexciter((s) => s.copyWith(freq: 7501.0)),
              ),
              (
                label: 'level_in=2.0',
                apply: (AudioEffects e) =>
                    e.updateAexciter((s) => s.copyWith(level_in: 2.0)),
              ),
              (
                label: 'level_out=2.0',
                apply: (AudioEffects e) =>
                    e.updateAexciter((s) => s.copyWith(level_out: 2.0)),
              ),
              (
                label: 'listen=true',
                apply: (AudioEffects e) =>
                    e.updateAexciter((s) => s.copyWith(listen: true)),
              ),
            ],
          ),
          (
            filter: 'afade',
            field: 'afade',
            bundle: const AudioEffects(afade: AfadeSettings(enabled: true)),
            updates: <AfCommandUpdate>[
              (
                label: 'nb_samples=44101',
                apply: (AudioEffects e) =>
                    e.updateAfade((s) => s.copyWith(nb_samples: 44101)),
              ),
              (
                label: 'ns=44101',
                apply: (AudioEffects e) =>
                    e.updateAfade((s) => s.copyWith(ns: 44101)),
              ),
              (
                label: 'silence=0.5',
                apply: (AudioEffects e) =>
                    e.updateAfade((s) => s.copyWith(silence: 0.5)),
              ),
              (
                label: 'ss=1',
                apply: (AudioEffects e) =>
                    e.updateAfade((s) => s.copyWith(ss: 1)),
              ),
              (
                label: 'start_sample=1',
                apply: (AudioEffects e) =>
                    e.updateAfade((s) => s.copyWith(start_sample: 1)),
              ),
              (
                label: 'unity=0.5',
                apply: (AudioEffects e) =>
                    e.updateAfade((s) => s.copyWith(unity: 0.5)),
              ),
            ],
          ),
          (
            filter: 'afftdn',
            field: 'afftdn',
            bundle: const AudioEffects(afftdn: AfftdnSettings(enabled: true)),
            updates: <AfCommandUpdate>[
              (
                label: 'ad=0.75',
                apply: (AudioEffects e) =>
                    e.updateAfftdn((s) => s.copyWith(ad: 0.75)),
              ),
              (
                label: 'adaptivity=0.75',
                apply: (AudioEffects e) =>
                    e.updateAfftdn((s) => s.copyWith(adaptivity: 0.75)),
              ),
              (
                label: 'floor_offset=1.5',
                apply: (AudioEffects e) =>
                    e.updateAfftdn((s) => s.copyWith(floor_offset: 1.5)),
              ),
              (
                label: 'fo=1.5',
                apply: (AudioEffects e) =>
                    e.updateAfftdn((s) => s.copyWith(fo: 1.5)),
              ),
              (
                label: 'gain_smooth=1',
                apply: (AudioEffects e) =>
                    e.updateAfftdn((s) => s.copyWith(gain_smooth: 1)),
              ),
              (
                label: 'gs=1',
                apply: (AudioEffects e) =>
                    e.updateAfftdn((s) => s.copyWith(gs: 1)),
              ),
              (
                label: 'nf=-49.0',
                apply: (AudioEffects e) =>
                    e.updateAfftdn((s) => s.copyWith(nf: -49.0)),
              ),
              (
                label: 'noise_floor=-49.0',
                apply: (AudioEffects e) =>
                    e.updateAfftdn((s) => s.copyWith(noise_floor: -49.0)),
              ),
              (
                label: 'noise_reduction=13.0',
                apply: (AudioEffects e) =>
                    e.updateAfftdn((s) => s.copyWith(noise_reduction: 13.0)),
              ),
              (
                label: 'nr=13.0',
                apply: (AudioEffects e) =>
                    e.updateAfftdn((s) => s.copyWith(nr: 13.0)),
              ),
              (
                label: 'residual_floor=-37.0',
                apply: (AudioEffects e) =>
                    e.updateAfftdn((s) => s.copyWith(residual_floor: -37.0)),
              ),
              (
                label: 'rf=-37.0',
                apply: (AudioEffects e) =>
                    e.updateAfftdn((s) => s.copyWith(rf: -37.0)),
              ),
              (
                label: 'tn=true',
                apply: (AudioEffects e) =>
                    e.updateAfftdn((s) => s.copyWith(tn: true)),
              ),
              (
                label: 'tr=true',
                apply: (AudioEffects e) =>
                    e.updateAfftdn((s) => s.copyWith(tr: true)),
              ),
              (
                label: 'track_noise=true',
                apply: (AudioEffects e) =>
                    e.updateAfftdn((s) => s.copyWith(track_noise: true)),
              ),
              (
                label: 'track_residual=true',
                apply: (AudioEffects e) =>
                    e.updateAfftdn((s) => s.copyWith(track_residual: true)),
              ),
            ],
          ),
          (
            filter: 'afreqshift',
            field: 'afreqshift',
            bundle: const AudioEffects(
              afreqshift: AfreqshiftSettings(enabled: true),
            ),
            updates: <AfCommandUpdate>[
              (
                label: 'level=0.5',
                apply: (AudioEffects e) =>
                    e.updateAfreqshift((s) => s.copyWith(level: 0.5)),
              ),
              (
                label: 'order=9',
                apply: (AudioEffects e) =>
                    e.updateAfreqshift((s) => s.copyWith(order: 9)),
              ),
              (
                label: 'shift=1.0',
                apply: (AudioEffects e) =>
                    e.updateAfreqshift((s) => s.copyWith(shift: 1.0)),
              ),
            ],
          ),
          (
            filter: 'afwtdn',
            field: 'afwtdn',
            bundle: const AudioEffects(afwtdn: AfwtdnSettings(enabled: true)),
            updates: <AfCommandUpdate>[
              (
                label: 'adaptive=true',
                apply: (AudioEffects e) =>
                    e.updateAfwtdn((s) => s.copyWith(adaptive: true)),
              ),
              (
                label: 'percent=86.0',
                apply: (AudioEffects e) =>
                    e.updateAfwtdn((s) => s.copyWith(percent: 86.0)),
              ),
              (
                label: 'profile=true',
                apply: (AudioEffects e) =>
                    e.updateAfwtdn((s) => s.copyWith(profile: true)),
              ),
              (
                label: 'sigma=0.5',
                apply: (AudioEffects e) =>
                    e.updateAfwtdn((s) => s.copyWith(sigma: 0.5)),
              ),
              (
                label: 'softness=2.0',
                apply: (AudioEffects e) =>
                    e.updateAfwtdn((s) => s.copyWith(softness: 2.0)),
              ),
            ],
          ),
          (
            filter: 'agate',
            field: 'agate',
            bundle: const AudioEffects(agate: AgateSettings(enabled: true)),
            updates: <AfCommandUpdate>[
              (
                label: 'attack=21.0',
                apply: (AudioEffects e) =>
                    e.updateAgate((s) => s.copyWith(attack: 21.0)),
              ),
              (
                label: 'knee=3.82843',
                apply: (AudioEffects e) =>
                    e.updateAgate((s) => s.copyWith(knee: 3.82843)),
              ),
              (
                label: 'level_in=2.0',
                apply: (AudioEffects e) =>
                    e.updateAgate((s) => s.copyWith(level_in: 2.0)),
              ),
              (
                label: 'level_sc=2.0',
                apply: (AudioEffects e) =>
                    e.updateAgate((s) => s.copyWith(level_sc: 2.0)),
              ),
              (
                label: 'makeup=2.0',
                apply: (AudioEffects e) =>
                    e.updateAgate((s) => s.copyWith(makeup: 2.0)),
              ),
              (
                label: 'range=0.530625',
                apply: (AudioEffects e) =>
                    e.updateAgate((s) => s.copyWith(range: 0.530625)),
              ),
              (
                label: 'ratio=3.0',
                apply: (AudioEffects e) =>
                    e.updateAgate((s) => s.copyWith(ratio: 3.0)),
              ),
              (
                label: 'release=251.0',
                apply: (AudioEffects e) =>
                    e.updateAgate((s) => s.copyWith(release: 251.0)),
              ),
              (
                label: 'threshold=0.5625',
                apply: (AudioEffects e) =>
                    e.updateAgate((s) => s.copyWith(threshold: 0.5625)),
              ),
            ],
          ),
          (
            filter: 'alimiter',
            field: 'alimiter',
            bundle: const AudioEffects(
              alimiter: AlimiterSettings(enabled: true),
            ),
            updates: <AfCommandUpdate>[
              (
                label: 'asc=true',
                apply: (AudioEffects e) =>
                    e.updateAlimiter((s) => s.copyWith(asc: true)),
              ),
              (
                label: 'asc_level=0.75',
                apply: (AudioEffects e) =>
                    e.updateAlimiter((s) => s.copyWith(asc_level: 0.75)),
              ),
              (
                label: 'attack=6.0',
                apply: (AudioEffects e) =>
                    e.updateAlimiter((s) => s.copyWith(attack: 6.0)),
              ),
              (
                label: 'latency=true',
                apply: (AudioEffects e) =>
                    e.updateAlimiter((s) => s.copyWith(latency: true)),
              ),
              (
                label: 'level=false',
                apply: (AudioEffects e) =>
                    e.updateAlimiter((s) => s.copyWith(level: false)),
              ),
              (
                label: 'level_in=2.0',
                apply: (AudioEffects e) =>
                    e.updateAlimiter((s) => s.copyWith(level_in: 2.0)),
              ),
              (
                label: 'level_out=2.0',
                apply: (AudioEffects e) =>
                    e.updateAlimiter((s) => s.copyWith(level_out: 2.0)),
              ),
              (
                label: 'limit=0.53125',
                apply: (AudioEffects e) =>
                    e.updateAlimiter((s) => s.copyWith(limit: 0.53125)),
              ),
              (
                label: 'release=51.0',
                apply: (AudioEffects e) =>
                    e.updateAlimiter((s) => s.copyWith(release: 51.0)),
              ),
            ],
          ),
          (
            filter: 'allpass',
            field: 'allpass',
            bundle: const AudioEffects(allpass: AllpassSettings(enabled: true)),
            updates: <AfCommandUpdate>[
              (
                label: 'f=3001.0',
                apply: (AudioEffects e) =>
                    e.updateAllpass((s) => s.copyWith(f: 3001.0)),
              ),
              (
                label: 'frequency=3001.0',
                apply: (AudioEffects e) =>
                    e.updateAllpass((s) => s.copyWith(frequency: 3001.0)),
              ),
              (
                label: 'm=0.5',
                apply: (AudioEffects e) =>
                    e.updateAllpass((s) => s.copyWith(m: 0.5)),
              ),
              (
                label: 'mix=0.5',
                apply: (AudioEffects e) =>
                    e.updateAllpass((s) => s.copyWith(mix: 0.5)),
              ),
              (
                label: 'n=true',
                apply: (AudioEffects e) =>
                    e.updateAllpass((s) => s.copyWith(n: true)),
              ),
              (
                label: 'normalize=true',
                apply: (AudioEffects e) =>
                    e.updateAllpass((s) => s.copyWith(normalize: true)),
              ),
              (
                label: 'o=1',
                apply: (AudioEffects e) =>
                    e.updateAllpass((s) => s.copyWith(o: 1)),
              ),
              (
                label: 'order=1',
                apply: (AudioEffects e) =>
                    e.updateAllpass((s) => s.copyWith(order: 1)),
              ),
              (
                label: 'w=1.707',
                apply: (AudioEffects e) =>
                    e.updateAllpass((s) => s.copyWith(w: 1.707)),
              ),
              (
                label: 'width=1.707',
                apply: (AudioEffects e) =>
                    e.updateAllpass((s) => s.copyWith(width: 1.707)),
              ),
            ],
          ),
          (
            filter: 'anlmdn',
            field: 'anlmdn',
            bundle: const AudioEffects(anlmdn: AnlmdnSettings(enabled: true)),
            updates: <AfCommandUpdate>[
              (
                label: 'm=12.0',
                apply: (AudioEffects e) =>
                    e.updateAnlmdn((s) => s.copyWith(m: 12.0)),
              ),
              (
                label: 's=1.00001',
                apply: (AudioEffects e) =>
                    e.updateAnlmdn((s) => s.copyWith(s: 1.00001)),
              ),
              (
                label: 'smooth=12.0',
                apply: (AudioEffects e) =>
                    e.updateAnlmdn((s) => s.copyWith(smooth: 12.0)),
              ),
              (
                label: 'strength=1.00001',
                apply: (AudioEffects e) =>
                    e.updateAnlmdn((s) => s.copyWith(strength: 1.00001)),
              ),
            ],
          ),
          (
            filter: 'aphaseshift',
            field: 'aphaseshift',
            bundle: const AudioEffects(
              aphaseshift: AphaseshiftSettings(enabled: true),
            ),
            updates: <AfCommandUpdate>[
              (
                label: 'level=0.5',
                apply: (AudioEffects e) =>
                    e.updateAphaseshift((s) => s.copyWith(level: 0.5)),
              ),
              (
                label: 'order=9',
                apply: (AudioEffects e) =>
                    e.updateAphaseshift((s) => s.copyWith(order: 9)),
              ),
              (
                label: 'shift=0.5',
                apply: (AudioEffects e) =>
                    e.updateAphaseshift((s) => s.copyWith(shift: 0.5)),
              ),
            ],
          ),
          (
            filter: 'apsyclip',
            field: 'apsyclip',
            bundle: const AudioEffects(
              apsyclip: ApsyclipSettings(enabled: true),
            ),
            updates: <AfCommandUpdate>[
              (
                label: 'adaptive=0.75',
                apply: (AudioEffects e) =>
                    e.updateApsyclip((s) => s.copyWith(adaptive: 0.75)),
              ),
              (
                label: 'clip=0.507812',
                apply: (AudioEffects e) =>
                    e.updateApsyclip((s) => s.copyWith(clip: 0.507812)),
              ),
              (
                label: 'diff=true',
                apply: (AudioEffects e) =>
                    e.updateApsyclip((s) => s.copyWith(diff: true)),
              ),
              (
                label: 'iterations=11',
                apply: (AudioEffects e) =>
                    e.updateApsyclip((s) => s.copyWith(iterations: 11)),
              ),
              (
                label: 'level=true',
                apply: (AudioEffects e) =>
                    e.updateApsyclip((s) => s.copyWith(level: true)),
              ),
              (
                label: 'level_in=2.0',
                apply: (AudioEffects e) =>
                    e.updateApsyclip((s) => s.copyWith(level_in: 2.0)),
              ),
              (
                label: 'level_out=2.0',
                apply: (AudioEffects e) =>
                    e.updateApsyclip((s) => s.copyWith(level_out: 2.0)),
              ),
            ],
          ),
          (
            filter: 'arnndn',
            field: 'arnndn',
            bundle: AudioEffects(
              arnndn: ArnndnSettings(enabled: true, model: arnndnModelPath),
            ),
            updates: <AfCommandUpdate>[
              (
                label: 'mix=0.0',
                apply: (AudioEffects e) =>
                    e.updateArnndn((s) => s.copyWith(mix: 0.0)),
              ),
            ],
          ),
          (
            filter: 'asoftclip',
            field: 'asoftclip',
            bundle: const AudioEffects(
              asoftclip: AsoftclipSettings(enabled: true),
            ),
            updates: <AfCommandUpdate>[
              (
                label: 'output=2.0',
                apply: (AudioEffects e) =>
                    e.updateAsoftclip((s) => s.copyWith(output: 2.0)),
              ),
              (
                label: 'oversample=2',
                apply: (AudioEffects e) =>
                    e.updateAsoftclip((s) => s.copyWith(oversample: 2)),
              ),
              (
                label: 'param=2.0',
                apply: (AudioEffects e) =>
                    e.updateAsoftclip((s) => s.copyWith(param: 2.0)),
              ),
              (
                label: 'threshold=0.500001',
                apply: (AudioEffects e) =>
                    e.updateAsoftclip((s) => s.copyWith(threshold: 0.500001)),
              ),
            ],
          ),
          (
            filter: 'asubboost',
            field: 'asubboost',
            bundle: const AudioEffects(
              asubboost: AsubboostSettings(enabled: true),
            ),
            updates: <AfCommandUpdate>[
              (
                label: 'boost=3.0',
                apply: (AudioEffects e) =>
                    e.updateAsubboost((s) => s.copyWith(boost: 3.0)),
              ),
              (
                label: 'cutoff=101.0',
                apply: (AudioEffects e) =>
                    e.updateAsubboost((s) => s.copyWith(cutoff: 101.0)),
              ),
              (
                label: 'decay=0.5',
                apply: (AudioEffects e) =>
                    e.updateAsubboost((s) => s.copyWith(decay: 0.5)),
              ),
              (
                label: 'delay=21.0',
                apply: (AudioEffects e) =>
                    e.updateAsubboost((s) => s.copyWith(delay: 21.0)),
              ),
              (
                label: 'dry=0.5',
                apply: (AudioEffects e) =>
                    e.updateAsubboost((s) => s.copyWith(dry: 0.5)),
              ),
              (
                label: 'feedback=0.95',
                apply: (AudioEffects e) =>
                    e.updateAsubboost((s) => s.copyWith(feedback: 0.95)),
              ),
              (
                label: 'slope=0.75',
                apply: (AudioEffects e) =>
                    e.updateAsubboost((s) => s.copyWith(slope: 0.75)),
              ),
              (
                label: 'wet=0.5',
                apply: (AudioEffects e) =>
                    e.updateAsubboost((s) => s.copyWith(wet: 0.5)),
              ),
            ],
          ),
          (
            filter: 'asubcut',
            field: 'asubcut',
            bundle: const AudioEffects(asubcut: AsubcutSettings(enabled: true)),
            updates: <AfCommandUpdate>[
              (
                label: 'cutoff=21.0',
                apply: (AudioEffects e) =>
                    e.updateAsubcut((s) => s.copyWith(cutoff: 21.0)),
              ),
              (
                label: 'level=0.5',
                apply: (AudioEffects e) =>
                    e.updateAsubcut((s) => s.copyWith(level: 0.5)),
              ),
              (
                label: 'order=11',
                apply: (AudioEffects e) =>
                    e.updateAsubcut((s) => s.copyWith(order: 11)),
              ),
            ],
          ),
          (
            filter: 'asupercut',
            field: 'asupercut',
            bundle: const AudioEffects(
              asupercut: AsupercutSettings(enabled: true),
            ),
            updates: <AfCommandUpdate>[
              (
                label: 'cutoff=20001.0',
                apply: (AudioEffects e) =>
                    e.updateAsupercut((s) => s.copyWith(cutoff: 20001.0)),
              ),
              (
                label: 'level=0.5',
                apply: (AudioEffects e) =>
                    e.updateAsupercut((s) => s.copyWith(level: 0.5)),
              ),
              (
                label: 'order=11',
                apply: (AudioEffects e) =>
                    e.updateAsupercut((s) => s.copyWith(order: 11)),
              ),
            ],
          ),
          (
            filter: 'asuperpass',
            field: 'asuperpass',
            bundle: const AudioEffects(
              asuperpass: AsuperpassSettings(enabled: true),
            ),
            updates: <AfCommandUpdate>[
              (
                label: 'centerf=1001.0',
                apply: (AudioEffects e) =>
                    e.updateAsuperpass((s) => s.copyWith(centerf: 1001.0)),
              ),
              (
                label: 'level=1.5',
                apply: (AudioEffects e) =>
                    e.updateAsuperpass((s) => s.copyWith(level: 1.5)),
              ),
              (
                label: 'order=5',
                apply: (AudioEffects e) =>
                    e.updateAsuperpass((s) => s.copyWith(order: 5)),
              ),
              (
                label: 'qfactor=2.0',
                apply: (AudioEffects e) =>
                    e.updateAsuperpass((s) => s.copyWith(qfactor: 2.0)),
              ),
            ],
          ),
          (
            filter: 'asuperstop',
            field: 'asuperstop',
            bundle: const AudioEffects(
              asuperstop: AsuperstopSettings(enabled: true),
            ),
            updates: <AfCommandUpdate>[
              (
                label: 'centerf=1001.0',
                apply: (AudioEffects e) =>
                    e.updateAsuperstop((s) => s.copyWith(centerf: 1001.0)),
              ),
              (
                label: 'level=1.5',
                apply: (AudioEffects e) =>
                    e.updateAsuperstop((s) => s.copyWith(level: 1.5)),
              ),
              (
                label: 'order=5',
                apply: (AudioEffects e) =>
                    e.updateAsuperstop((s) => s.copyWith(order: 5)),
              ),
              (
                label: 'qfactor=2.0',
                apply: (AudioEffects e) =>
                    e.updateAsuperstop((s) => s.copyWith(qfactor: 2.0)),
              ),
            ],
          ),
          (
            filter: 'atempo',
            field: 'atempo',
            bundle: const AudioEffects(atempo: AtempoSettings(enabled: true)),
            updates: <AfCommandUpdate>[
              (
                label: 'tempo=2.0',
                apply: (AudioEffects e) =>
                    e.updateAtempo((s) => s.copyWith(tempo: 2.0)),
              ),
            ],
          ),
          (
            filter: 'atilt',
            field: 'atilt',
            bundle: const AudioEffects(atilt: AtiltSettings(enabled: true)),
            updates: <AfCommandUpdate>[
              (
                label: 'freq=10001.0',
                apply: (AudioEffects e) =>
                    e.updateAtilt((s) => s.copyWith(freq: 10001.0)),
              ),
              (
                label: 'level=2.0',
                apply: (AudioEffects e) =>
                    e.updateAtilt((s) => s.copyWith(level: 2.0)),
              ),
              (
                label: 'order=6',
                apply: (AudioEffects e) =>
                    e.updateAtilt((s) => s.copyWith(order: 6)),
              ),
              (
                label: 'slope=0.5',
                apply: (AudioEffects e) =>
                    e.updateAtilt((s) => s.copyWith(slope: 0.5)),
              ),
              (
                label: 'width=1001.0',
                apply: (AudioEffects e) =>
                    e.updateAtilt((s) => s.copyWith(width: 1001.0)),
              ),
            ],
          ),
          (
            filter: 'bandpass',
            field: 'bandpass',
            bundle: const AudioEffects(
              bandpass: BandpassSettings(enabled: true),
            ),
            updates: <AfCommandUpdate>[
              (
                label: 'csg=true',
                apply: (AudioEffects e) =>
                    e.updateBandpass((s) => s.copyWith(csg: true)),
              ),
              (
                label: 'f=3001.0',
                apply: (AudioEffects e) =>
                    e.updateBandpass((s) => s.copyWith(f: 3001.0)),
              ),
              (
                label: 'frequency=3001.0',
                apply: (AudioEffects e) =>
                    e.updateBandpass((s) => s.copyWith(frequency: 3001.0)),
              ),
              (
                label: 'm=0.5',
                apply: (AudioEffects e) =>
                    e.updateBandpass((s) => s.copyWith(m: 0.5)),
              ),
              (
                label: 'mix=0.5',
                apply: (AudioEffects e) =>
                    e.updateBandpass((s) => s.copyWith(mix: 0.5)),
              ),
              (
                label: 'n=true',
                apply: (AudioEffects e) =>
                    e.updateBandpass((s) => s.copyWith(n: true)),
              ),
              (
                label: 'normalize=true',
                apply: (AudioEffects e) =>
                    e.updateBandpass((s) => s.copyWith(normalize: true)),
              ),
              (
                label: 'w=1.5',
                apply: (AudioEffects e) =>
                    e.updateBandpass((s) => s.copyWith(w: 1.5)),
              ),
              (
                label: 'width=1.5',
                apply: (AudioEffects e) =>
                    e.updateBandpass((s) => s.copyWith(width: 1.5)),
              ),
            ],
          ),
          (
            filter: 'bandreject',
            field: 'bandreject',
            bundle: const AudioEffects(
              bandreject: BandrejectSettings(enabled: true),
            ),
            updates: <AfCommandUpdate>[
              (
                label: 'f=3001.0',
                apply: (AudioEffects e) =>
                    e.updateBandreject((s) => s.copyWith(f: 3001.0)),
              ),
              (
                label: 'frequency=3001.0',
                apply: (AudioEffects e) =>
                    e.updateBandreject((s) => s.copyWith(frequency: 3001.0)),
              ),
              (
                label: 'm=0.5',
                apply: (AudioEffects e) =>
                    e.updateBandreject((s) => s.copyWith(m: 0.5)),
              ),
              (
                label: 'mix=0.5',
                apply: (AudioEffects e) =>
                    e.updateBandreject((s) => s.copyWith(mix: 0.5)),
              ),
              (
                label: 'n=true',
                apply: (AudioEffects e) =>
                    e.updateBandreject((s) => s.copyWith(n: true)),
              ),
              (
                label: 'normalize=true',
                apply: (AudioEffects e) =>
                    e.updateBandreject((s) => s.copyWith(normalize: true)),
              ),
              (
                label: 'w=1.5',
                apply: (AudioEffects e) =>
                    e.updateBandreject((s) => s.copyWith(w: 1.5)),
              ),
              (
                label: 'width=1.5',
                apply: (AudioEffects e) =>
                    e.updateBandreject((s) => s.copyWith(width: 1.5)),
              ),
            ],
          ),
          (
            filter: 'bass',
            field: 'bass',
            bundle: const AudioEffects(bass: BassSettings(enabled: true)),
            updates: <AfCommandUpdate>[
              (
                label: 'f=101.0',
                apply: (AudioEffects e) =>
                    e.updateBass((s) => s.copyWith(f: 101.0)),
              ),
              (
                label: 'frequency=101.0',
                apply: (AudioEffects e) =>
                    e.updateBass((s) => s.copyWith(frequency: 101.0)),
              ),
              (
                label: 'g=1.0',
                apply: (AudioEffects e) =>
                    e.updateBass((s) => s.copyWith(g: 1.0)),
              ),
              (
                label: 'gain=1.0',
                apply: (AudioEffects e) =>
                    e.updateBass((s) => s.copyWith(gain: 1.0)),
              ),
              (
                label: 'm=0.5',
                apply: (AudioEffects e) =>
                    e.updateBass((s) => s.copyWith(m: 0.5)),
              ),
              (
                label: 'mix=0.5',
                apply: (AudioEffects e) =>
                    e.updateBass((s) => s.copyWith(mix: 0.5)),
              ),
              (
                label: 'n=true',
                apply: (AudioEffects e) =>
                    e.updateBass((s) => s.copyWith(n: true)),
              ),
              (
                label: 'normalize=true',
                apply: (AudioEffects e) =>
                    e.updateBass((s) => s.copyWith(normalize: true)),
              ),
              (
                label: 'w=1.5',
                apply: (AudioEffects e) =>
                    e.updateBass((s) => s.copyWith(w: 1.5)),
              ),
              (
                label: 'width=1.5',
                apply: (AudioEffects e) =>
                    e.updateBass((s) => s.copyWith(width: 1.5)),
              ),
            ],
          ),
          (
            filter: 'biquad',
            field: 'biquad',
            bundle: const AudioEffects(biquad: BiquadSettings(enabled: true)),
            updates: <AfCommandUpdate>[
              (
                label: 'a0=2.0',
                apply: (AudioEffects e) =>
                    e.updateBiquad((s) => s.copyWith(a0: 2.0)),
              ),
              (
                label: 'a1=1.0',
                apply: (AudioEffects e) =>
                    e.updateBiquad((s) => s.copyWith(a1: 1.0)),
              ),
              (
                label: 'a2=1.0',
                apply: (AudioEffects e) =>
                    e.updateBiquad((s) => s.copyWith(a2: 1.0)),
              ),
              (
                label: 'b0=1.0',
                apply: (AudioEffects e) =>
                    e.updateBiquad((s) => s.copyWith(b0: 1.0)),
              ),
              (
                label: 'b1=1.0',
                apply: (AudioEffects e) =>
                    e.updateBiquad((s) => s.copyWith(b1: 1.0)),
              ),
              (
                label: 'b2=1.0',
                apply: (AudioEffects e) =>
                    e.updateBiquad((s) => s.copyWith(b2: 1.0)),
              ),
              (
                label: 'm=0.5',
                apply: (AudioEffects e) =>
                    e.updateBiquad((s) => s.copyWith(m: 0.5)),
              ),
              (
                label: 'mix=0.5',
                apply: (AudioEffects e) =>
                    e.updateBiquad((s) => s.copyWith(mix: 0.5)),
              ),
              (
                label: 'n=true',
                apply: (AudioEffects e) =>
                    e.updateBiquad((s) => s.copyWith(n: true)),
              ),
              (
                label: 'normalize=true',
                apply: (AudioEffects e) =>
                    e.updateBiquad((s) => s.copyWith(normalize: true)),
              ),
            ],
          ),
          (
            filter: 'crossfeed',
            field: 'crossfeed',
            bundle: const AudioEffects(
              crossfeed: CrossfeedSettings(enabled: true),
            ),
            updates: <AfCommandUpdate>[
              (
                label: 'level_in=0.95',
                apply: (AudioEffects e) =>
                    e.updateCrossfeed((s) => s.copyWith(level_in: 0.95)),
              ),
              (
                label: 'level_out=0.5',
                apply: (AudioEffects e) =>
                    e.updateCrossfeed((s) => s.copyWith(level_out: 0.5)),
              ),
              (
                label: 'range=0.75',
                apply: (AudioEffects e) =>
                    e.updateCrossfeed((s) => s.copyWith(range: 0.75)),
              ),
              (
                label: 'slope=0.75',
                apply: (AudioEffects e) =>
                    e.updateCrossfeed((s) => s.copyWith(slope: 0.75)),
              ),
              (
                label: 'strength=0.6',
                apply: (AudioEffects e) =>
                    e.updateCrossfeed((s) => s.copyWith(strength: 0.6)),
              ),
            ],
          ),
          (
            filter: 'crystalizer',
            field: 'crystalizer',
            bundle: const AudioEffects(
              crystalizer: CrystalizerSettings(enabled: true),
            ),
            updates: <AfCommandUpdate>[
              (
                label: 'c=false',
                apply: (AudioEffects e) =>
                    e.updateCrystalizer((s) => s.copyWith(c: false)),
              ),
              (
                label: 'i=3.0',
                apply: (AudioEffects e) =>
                    e.updateCrystalizer((s) => s.copyWith(i: 3.0)),
              ),
            ],
          ),
          (
            filter: 'dialoguenhance',
            field: 'dialoguenhance',
            bundle: const AudioEffects(
              dialoguenhance: DialoguenhanceSettings(enabled: true),
            ),
            updates: <AfCommandUpdate>[
              (
                label: 'enhance=2.0',
                apply: (AudioEffects e) =>
                    e.updateDialoguenhance((s) => s.copyWith(enhance: 2.0)),
              ),
              (
                label: 'original=0.5',
                apply: (AudioEffects e) =>
                    e.updateDialoguenhance((s) => s.copyWith(original: 0.5)),
              ),
              (
                label: 'voice=3.0',
                apply: (AudioEffects e) =>
                    e.updateDialoguenhance((s) => s.copyWith(voice: 3.0)),
              ),
            ],
          ),
          (
            filter: 'dynaudnorm',
            field: 'dynaudnorm',
            bundle: const AudioEffects(
              dynaudnorm: DynaudnormSettings(enabled: true),
            ),
            updates: <AfCommandUpdate>[
              (
                label: 'altboundary=true',
                apply: (AudioEffects e) =>
                    e.updateDynaudnorm((s) => s.copyWith(altboundary: true)),
              ),
              (
                label: 'b=true',
                apply: (AudioEffects e) =>
                    e.updateDynaudnorm((s) => s.copyWith(b: true)),
              ),
              (
                label: 'c=true',
                apply: (AudioEffects e) =>
                    e.updateDynaudnorm((s) => s.copyWith(c: true)),
              ),
              (
                label: 'compress=1.0',
                apply: (AudioEffects e) =>
                    e.updateDynaudnorm((s) => s.copyWith(compress: 1.0)),
              ),
              (
                label: 'correctdc=true',
                apply: (AudioEffects e) =>
                    e.updateDynaudnorm((s) => s.copyWith(correctdc: true)),
              ),
              (
                label: 'coupling=false',
                apply: (AudioEffects e) =>
                    e.updateDynaudnorm((s) => s.copyWith(coupling: false)),
              ),
              (
                label: 'f=501',
                apply: (AudioEffects e) =>
                    e.updateDynaudnorm((s) => s.copyWith(f: 501)),
              ),
              (
                label: 'framelen=501',
                apply: (AudioEffects e) =>
                    e.updateDynaudnorm((s) => s.copyWith(framelen: 501)),
              ),
              (
                label: 'g=32',
                apply: (AudioEffects e) =>
                    e.updateDynaudnorm((s) => s.copyWith(g: 32)),
              ),
              (
                label: 'gausssize=32',
                apply: (AudioEffects e) =>
                    e.updateDynaudnorm((s) => s.copyWith(gausssize: 32)),
              ),
              (
                label: 'm=11.0',
                apply: (AudioEffects e) =>
                    e.updateDynaudnorm((s) => s.copyWith(m: 11.0)),
              ),
              (
                label: 'maxgain=11.0',
                apply: (AudioEffects e) =>
                    e.updateDynaudnorm((s) => s.copyWith(maxgain: 11.0)),
              ),
              (
                label: 'n=false',
                apply: (AudioEffects e) =>
                    e.updateDynaudnorm((s) => s.copyWith(n: false)),
              ),
              (
                label: 'o=0.5',
                apply: (AudioEffects e) =>
                    e.updateDynaudnorm((s) => s.copyWith(o: 0.5)),
              ),
              (
                label: 'overlap=0.5',
                apply: (AudioEffects e) =>
                    e.updateDynaudnorm((s) => s.copyWith(overlap: 0.5)),
              ),
              (
                label: 'p=0.975',
                apply: (AudioEffects e) =>
                    e.updateDynaudnorm((s) => s.copyWith(p: 0.975)),
              ),
              (
                label: 'peak=0.975',
                apply: (AudioEffects e) =>
                    e.updateDynaudnorm((s) => s.copyWith(peak: 0.975)),
              ),
              (
                label: 'r=0.5',
                apply: (AudioEffects e) =>
                    e.updateDynaudnorm((s) => s.copyWith(r: 0.5)),
              ),
              (
                label: 's=1.0',
                apply: (AudioEffects e) =>
                    e.updateDynaudnorm((s) => s.copyWith(s: 1.0)),
              ),
              (
                label: 't=0.5',
                apply: (AudioEffects e) =>
                    e.updateDynaudnorm((s) => s.copyWith(t: 0.5)),
              ),
              (
                label: 'targetrms=0.5',
                apply: (AudioEffects e) =>
                    e.updateDynaudnorm((s) => s.copyWith(targetrms: 0.5)),
              ),
              (
                label: 'threshold=0.5',
                apply: (AudioEffects e) =>
                    e.updateDynaudnorm((s) => s.copyWith(threshold: 0.5)),
              ),
            ],
          ),
          (
            filter: 'equalizer',
            field: 'equalizer',
            bundle: const AudioEffects(
              equalizer: EqualizerSettings(enabled: true),
            ),
            updates: <AfCommandUpdate>[
              (
                label: 'f=1.0',
                apply: (AudioEffects e) =>
                    e.updateEqualizer((s) => s.copyWith(f: 1.0)),
              ),
              (
                label: 'frequency=1.0',
                apply: (AudioEffects e) =>
                    e.updateEqualizer((s) => s.copyWith(frequency: 1.0)),
              ),
              (
                label: 'g=1.0',
                apply: (AudioEffects e) =>
                    e.updateEqualizer((s) => s.copyWith(g: 1.0)),
              ),
              (
                label: 'gain=1.0',
                apply: (AudioEffects e) =>
                    e.updateEqualizer((s) => s.copyWith(gain: 1.0)),
              ),
              (
                label: 'm=0.5',
                apply: (AudioEffects e) =>
                    e.updateEqualizer((s) => s.copyWith(m: 0.5)),
              ),
              (
                label: 'mix=0.5',
                apply: (AudioEffects e) =>
                    e.updateEqualizer((s) => s.copyWith(mix: 0.5)),
              ),
              (
                label: 'n=true',
                apply: (AudioEffects e) =>
                    e.updateEqualizer((s) => s.copyWith(n: true)),
              ),
              (
                label: 'normalize=true',
                apply: (AudioEffects e) =>
                    e.updateEqualizer((s) => s.copyWith(normalize: true)),
              ),
              (
                label: 'w=2.0',
                apply: (AudioEffects e) =>
                    e.updateEqualizer((s) => s.copyWith(w: 2.0)),
              ),
              (
                label: 'width=2.0',
                apply: (AudioEffects e) =>
                    e.updateEqualizer((s) => s.copyWith(width: 2.0)),
              ),
            ],
          ),
          (
            filter: 'extrastereo',
            field: 'extrastereo',
            bundle: const AudioEffects(
              extrastereo: ExtrastereoSettings(enabled: true),
            ),
            updates: <AfCommandUpdate>[
              (
                label: 'c=false',
                apply: (AudioEffects e) =>
                    e.updateExtrastereo((s) => s.copyWith(c: false)),
              ),
              (
                label: 'm=3.5',
                apply: (AudioEffects e) =>
                    e.updateExtrastereo((s) => s.copyWith(m: 3.5)),
              ),
            ],
          ),
          (
            filter: 'firequalizer',
            field: 'firequalizer',
            bundle: const AudioEffects(
              firequalizer: FirequalizerSettings(enabled: true),
            ),
            updates: <AfCommandUpdate>[
              (
                label: 'gain=0',
                apply: (AudioEffects e) =>
                    e.updateFirequalizer((s) => s.copyWith(gain: '0')),
              ),
            ],
          ),
          (
            filter: 'highpass',
            field: 'highpass',
            bundle: const AudioEffects(
              highpass: HighpassSettings(enabled: true),
            ),
            updates: <AfCommandUpdate>[
              (
                label: 'f=3001.0',
                apply: (AudioEffects e) =>
                    e.updateHighpass((s) => s.copyWith(f: 3001.0)),
              ),
              (
                label: 'frequency=3001.0',
                apply: (AudioEffects e) =>
                    e.updateHighpass((s) => s.copyWith(frequency: 3001.0)),
              ),
              (
                label: 'm=0.5',
                apply: (AudioEffects e) =>
                    e.updateHighpass((s) => s.copyWith(m: 0.5)),
              ),
              (
                label: 'mix=0.5',
                apply: (AudioEffects e) =>
                    e.updateHighpass((s) => s.copyWith(mix: 0.5)),
              ),
              (
                label: 'n=true',
                apply: (AudioEffects e) =>
                    e.updateHighpass((s) => s.copyWith(n: true)),
              ),
              (
                label: 'normalize=true',
                apply: (AudioEffects e) =>
                    e.updateHighpass((s) => s.copyWith(normalize: true)),
              ),
              (
                label: 'w=1.707',
                apply: (AudioEffects e) =>
                    e.updateHighpass((s) => s.copyWith(w: 1.707)),
              ),
              (
                label: 'width=1.707',
                apply: (AudioEffects e) =>
                    e.updateHighpass((s) => s.copyWith(width: 1.707)),
              ),
            ],
          ),
          (
            filter: 'highshelf',
            field: 'highshelf',
            bundle: const AudioEffects(
              highshelf: HighshelfSettings(enabled: true),
            ),
            updates: <AfCommandUpdate>[
              (
                label: 'f=3001.0',
                apply: (AudioEffects e) =>
                    e.updateHighshelf((s) => s.copyWith(f: 3001.0)),
              ),
              (
                label: 'frequency=3001.0',
                apply: (AudioEffects e) =>
                    e.updateHighshelf((s) => s.copyWith(frequency: 3001.0)),
              ),
              (
                label: 'g=1.0',
                apply: (AudioEffects e) =>
                    e.updateHighshelf((s) => s.copyWith(g: 1.0)),
              ),
              (
                label: 'gain=1.0',
                apply: (AudioEffects e) =>
                    e.updateHighshelf((s) => s.copyWith(gain: 1.0)),
              ),
              (
                label: 'm=0.5',
                apply: (AudioEffects e) =>
                    e.updateHighshelf((s) => s.copyWith(m: 0.5)),
              ),
              (
                label: 'mix=0.5',
                apply: (AudioEffects e) =>
                    e.updateHighshelf((s) => s.copyWith(mix: 0.5)),
              ),
              (
                label: 'n=true',
                apply: (AudioEffects e) =>
                    e.updateHighshelf((s) => s.copyWith(n: true)),
              ),
              (
                label: 'normalize=true',
                apply: (AudioEffects e) =>
                    e.updateHighshelf((s) => s.copyWith(normalize: true)),
              ),
              (
                label: 'w=1.5',
                apply: (AudioEffects e) =>
                    e.updateHighshelf((s) => s.copyWith(w: 1.5)),
              ),
              (
                label: 'width=1.5',
                apply: (AudioEffects e) =>
                    e.updateHighshelf((s) => s.copyWith(width: 1.5)),
              ),
            ],
          ),
          (
            filter: 'lowpass',
            field: 'lowpass',
            bundle: const AudioEffects(lowpass: LowpassSettings(enabled: true)),
            updates: <AfCommandUpdate>[
              (
                label: 'f=501.0',
                apply: (AudioEffects e) =>
                    e.updateLowpass((s) => s.copyWith(f: 501.0)),
              ),
              (
                label: 'frequency=501.0',
                apply: (AudioEffects e) =>
                    e.updateLowpass((s) => s.copyWith(frequency: 501.0)),
              ),
              (
                label: 'm=0.5',
                apply: (AudioEffects e) =>
                    e.updateLowpass((s) => s.copyWith(m: 0.5)),
              ),
              (
                label: 'mix=0.5',
                apply: (AudioEffects e) =>
                    e.updateLowpass((s) => s.copyWith(mix: 0.5)),
              ),
              (
                label: 'n=true',
                apply: (AudioEffects e) =>
                    e.updateLowpass((s) => s.copyWith(n: true)),
              ),
              (
                label: 'normalize=true',
                apply: (AudioEffects e) =>
                    e.updateLowpass((s) => s.copyWith(normalize: true)),
              ),
              (
                label: 'w=1.707',
                apply: (AudioEffects e) =>
                    e.updateLowpass((s) => s.copyWith(w: 1.707)),
              ),
              (
                label: 'width=1.707',
                apply: (AudioEffects e) =>
                    e.updateLowpass((s) => s.copyWith(width: 1.707)),
              ),
            ],
          ),
          (
            filter: 'lowshelf',
            field: 'lowshelf',
            bundle: const AudioEffects(
              lowshelf: LowshelfSettings(enabled: true),
            ),
            updates: <AfCommandUpdate>[
              (
                label: 'f=101.0',
                apply: (AudioEffects e) =>
                    e.updateLowshelf((s) => s.copyWith(f: 101.0)),
              ),
              (
                label: 'frequency=101.0',
                apply: (AudioEffects e) =>
                    e.updateLowshelf((s) => s.copyWith(frequency: 101.0)),
              ),
              (
                label: 'g=1.0',
                apply: (AudioEffects e) =>
                    e.updateLowshelf((s) => s.copyWith(g: 1.0)),
              ),
              (
                label: 'gain=1.0',
                apply: (AudioEffects e) =>
                    e.updateLowshelf((s) => s.copyWith(gain: 1.0)),
              ),
              (
                label: 'm=0.5',
                apply: (AudioEffects e) =>
                    e.updateLowshelf((s) => s.copyWith(m: 0.5)),
              ),
              (
                label: 'mix=0.5',
                apply: (AudioEffects e) =>
                    e.updateLowshelf((s) => s.copyWith(mix: 0.5)),
              ),
              (
                label: 'n=true',
                apply: (AudioEffects e) =>
                    e.updateLowshelf((s) => s.copyWith(n: true)),
              ),
              (
                label: 'normalize=true',
                apply: (AudioEffects e) =>
                    e.updateLowshelf((s) => s.copyWith(normalize: true)),
              ),
              (
                label: 'w=1.5',
                apply: (AudioEffects e) =>
                    e.updateLowshelf((s) => s.copyWith(w: 1.5)),
              ),
              (
                label: 'width=1.5',
                apply: (AudioEffects e) =>
                    e.updateLowshelf((s) => s.copyWith(width: 1.5)),
              ),
            ],
          ),
          (
            filter: 'rubberband',
            field: 'rubberband',
            bundle: const AudioEffects(
              rubberband: RubberbandSettings(enabled: true),
            ),
            updates: <AfCommandUpdate>[
              (
                label: 'pitch=2.0',
                apply: (AudioEffects e) =>
                    e.updateRubberband((s) => s.copyWith(pitch: 2.0)),
              ),
              (
                label: 'tempo=2.0',
                apply: (AudioEffects e) =>
                    e.updateRubberband((s) => s.copyWith(tempo: 2.0)),
              ),
            ],
          ),
          (
            filter: 'silenceremove',
            field: 'silenceremove',
            bundle: const AudioEffects(
              silenceremove: SilenceremoveSettings(enabled: true),
            ),
            updates: <AfCommandUpdate>[
              (
                label: 'start_threshold=1.0',
                apply: (AudioEffects e) => e.updateSilenceremove(
                  (s) => s.copyWith(start_threshold: 1.0),
                ),
              ),
              (
                label: 'stop_threshold=1.0',
                apply: (AudioEffects e) => e.updateSilenceremove(
                  (s) => s.copyWith(stop_threshold: 1.0),
                ),
              ),
            ],
          ),
          (
            filter: 'speechnorm',
            field: 'speechnorm',
            bundle: const AudioEffects(
              speechnorm: SpeechnormSettings(enabled: true),
            ),
            updates: <AfCommandUpdate>[
              (
                label: 'c=3.0',
                apply: (AudioEffects e) =>
                    e.updateSpeechnorm((s) => s.copyWith(c: 3.0)),
              ),
              (
                label: 'compression=3.0',
                apply: (AudioEffects e) =>
                    e.updateSpeechnorm((s) => s.copyWith(compression: 3.0)),
              ),
              (
                label: 'e=3.0',
                apply: (AudioEffects e) =>
                    e.updateSpeechnorm((s) => s.copyWith(e: 3.0)),
              ),
              (
                label: 'expansion=3.0',
                apply: (AudioEffects e) =>
                    e.updateSpeechnorm((s) => s.copyWith(expansion: 3.0)),
              ),
              (
                label: 'f=0.5005',
                apply: (AudioEffects e) =>
                    e.updateSpeechnorm((s) => s.copyWith(f: 0.5005)),
              ),
              (
                label: 'fall=0.5005',
                apply: (AudioEffects e) =>
                    e.updateSpeechnorm((s) => s.copyWith(fall: 0.5005)),
              ),
              (
                label: 'i=true',
                apply: (AudioEffects e) =>
                    e.updateSpeechnorm((s) => s.copyWith(i: true)),
              ),
              (
                label: 'invert=true',
                apply: (AudioEffects e) =>
                    e.updateSpeechnorm((s) => s.copyWith(invert: true)),
              ),
              (
                label: 'l=true',
                apply: (AudioEffects e) =>
                    e.updateSpeechnorm((s) => s.copyWith(l: true)),
              ),
              (
                label: 'link=true',
                apply: (AudioEffects e) =>
                    e.updateSpeechnorm((s) => s.copyWith(link: true)),
              ),
              (
                label: 'm=0.5',
                apply: (AudioEffects e) =>
                    e.updateSpeechnorm((s) => s.copyWith(m: 0.5)),
              ),
              (
                label: 'p=0.975',
                apply: (AudioEffects e) =>
                    e.updateSpeechnorm((s) => s.copyWith(p: 0.975)),
              ),
              (
                label: 'peak=0.975',
                apply: (AudioEffects e) =>
                    e.updateSpeechnorm((s) => s.copyWith(peak: 0.975)),
              ),
              (
                label: 'r=0.5005',
                apply: (AudioEffects e) =>
                    e.updateSpeechnorm((s) => s.copyWith(r: 0.5005)),
              ),
              (
                label: 'raise=0.5005',
                apply: (AudioEffects e) =>
                    e.updateSpeechnorm((s) => s.copyWith(raise: 0.5005)),
              ),
              (
                label: 'rms=0.5',
                apply: (AudioEffects e) =>
                    e.updateSpeechnorm((s) => s.copyWith(rms: 0.5)),
              ),
              (
                label: 't=0.5',
                apply: (AudioEffects e) =>
                    e.updateSpeechnorm((s) => s.copyWith(t: 0.5)),
              ),
              (
                label: 'threshold=0.5',
                apply: (AudioEffects e) =>
                    e.updateSpeechnorm((s) => s.copyWith(threshold: 0.5)),
              ),
            ],
          ),
          (
            filter: 'stereotools',
            field: 'stereotools',
            bundle: const AudioEffects(
              stereotools: StereotoolsSettings(enabled: true),
            ),
            updates: <AfCommandUpdate>[
              (
                label: 'balance_in=0.5',
                apply: (AudioEffects e) =>
                    e.updateStereotools((s) => s.copyWith(balance_in: 0.5)),
              ),
              (
                label: 'balance_out=0.5',
                apply: (AudioEffects e) =>
                    e.updateStereotools((s) => s.copyWith(balance_out: 0.5)),
              ),
              (
                label: 'base=0.5',
                apply: (AudioEffects e) =>
                    e.updateStereotools((s) => s.copyWith(base: 0.5)),
              ),
              (
                label: 'delay=1.0',
                apply: (AudioEffects e) =>
                    e.updateStereotools((s) => s.copyWith(delay: 1.0)),
              ),
              (
                label: 'level_in=2.0',
                apply: (AudioEffects e) =>
                    e.updateStereotools((s) => s.copyWith(level_in: 2.0)),
              ),
              (
                label: 'level_out=2.0',
                apply: (AudioEffects e) =>
                    e.updateStereotools((s) => s.copyWith(level_out: 2.0)),
              ),
              (
                label: 'mlev=2.0',
                apply: (AudioEffects e) =>
                    e.updateStereotools((s) => s.copyWith(mlev: 2.0)),
              ),
              (
                label: 'mpan=0.5',
                apply: (AudioEffects e) =>
                    e.updateStereotools((s) => s.copyWith(mpan: 0.5)),
              ),
              (
                label: 'mutel=true',
                apply: (AudioEffects e) =>
                    e.updateStereotools((s) => s.copyWith(mutel: true)),
              ),
              (
                label: 'muter=true',
                apply: (AudioEffects e) =>
                    e.updateStereotools((s) => s.copyWith(muter: true)),
              ),
              (
                label: 'phase=1.0',
                apply: (AudioEffects e) =>
                    e.updateStereotools((s) => s.copyWith(phase: 1.0)),
              ),
              (
                label: 'phasel=true',
                apply: (AudioEffects e) =>
                    e.updateStereotools((s) => s.copyWith(phasel: true)),
              ),
              (
                label: 'phaser=true',
                apply: (AudioEffects e) =>
                    e.updateStereotools((s) => s.copyWith(phaser: true)),
              ),
              (
                label: 'sbal=0.5',
                apply: (AudioEffects e) =>
                    e.updateStereotools((s) => s.copyWith(sbal: 0.5)),
              ),
              (
                label: 'sclevel=2.0',
                apply: (AudioEffects e) =>
                    e.updateStereotools((s) => s.copyWith(sclevel: 2.0)),
              ),
              (
                label: 'slev=2.0',
                apply: (AudioEffects e) =>
                    e.updateStereotools((s) => s.copyWith(slev: 2.0)),
              ),
              (
                label: 'softclip=true',
                apply: (AudioEffects e) =>
                    e.updateStereotools((s) => s.copyWith(softclip: true)),
              ),
            ],
          ),
          (
            filter: 'stereowiden',
            field: 'stereowiden',
            bundle: const AudioEffects(
              stereowiden: StereowidenSettings(enabled: true),
            ),
            updates: <AfCommandUpdate>[
              (
                label: 'crossfeed=0.55',
                apply: (AudioEffects e) =>
                    e.updateStereowiden((s) => s.copyWith(crossfeed: 0.55)),
              ),
              (
                label: 'drymix=0.9',
                apply: (AudioEffects e) =>
                    e.updateStereowiden((s) => s.copyWith(drymix: 0.9)),
              ),
              (
                label: 'feedback=0.6',
                apply: (AudioEffects e) =>
                    e.updateStereowiden((s) => s.copyWith(feedback: 0.6)),
              ),
            ],
          ),
          (
            filter: 'surround',
            field: 'surround',
            bundle: const AudioEffects(
              surround: SurroundSettings(enabled: true),
            ),
            updates: <AfCommandUpdate>[
              (
                label: 'allx=0.0',
                apply: (AudioEffects e) =>
                    e.updateSurround((s) => s.copyWith(allx: 0.0)),
              ),
              (
                label: 'ally=0.0',
                apply: (AudioEffects e) =>
                    e.updateSurround((s) => s.copyWith(ally: 0.0)),
              ),
              (
                label: 'angle=91.0',
                apply: (AudioEffects e) =>
                    e.updateSurround((s) => s.copyWith(angle: 91.0)),
              ),
              (
                label: 'bc_in=2.0',
                apply: (AudioEffects e) =>
                    e.updateSurround((s) => s.copyWith(bc_in: 2.0)),
              ),
              (
                label: 'bc_out=2.0',
                apply: (AudioEffects e) =>
                    e.updateSurround((s) => s.copyWith(bc_out: 2.0)),
              ),
              (
                label: 'bcx=1.5',
                apply: (AudioEffects e) =>
                    e.updateSurround((s) => s.copyWith(bcx: 1.5)),
              ),
              (
                label: 'bcy=1.5',
                apply: (AudioEffects e) =>
                    e.updateSurround((s) => s.copyWith(bcy: 1.5)),
              ),
              (
                label: 'bl_in=2.0',
                apply: (AudioEffects e) =>
                    e.updateSurround((s) => s.copyWith(bl_in: 2.0)),
              ),
              (
                label: 'bl_out=2.0',
                apply: (AudioEffects e) =>
                    e.updateSurround((s) => s.copyWith(bl_out: 2.0)),
              ),
              (
                label: 'blx=1.5',
                apply: (AudioEffects e) =>
                    e.updateSurround((s) => s.copyWith(blx: 1.5)),
              ),
              (
                label: 'bly=1.5',
                apply: (AudioEffects e) =>
                    e.updateSurround((s) => s.copyWith(bly: 1.5)),
              ),
              (
                label: 'br_in=2.0',
                apply: (AudioEffects e) =>
                    e.updateSurround((s) => s.copyWith(br_in: 2.0)),
              ),
              (
                label: 'br_out=2.0',
                apply: (AudioEffects e) =>
                    e.updateSurround((s) => s.copyWith(br_out: 2.0)),
              ),
              (
                label: 'brx=1.5',
                apply: (AudioEffects e) =>
                    e.updateSurround((s) => s.copyWith(brx: 1.5)),
              ),
              (
                label: 'bry=1.5',
                apply: (AudioEffects e) =>
                    e.updateSurround((s) => s.copyWith(bry: 1.5)),
              ),
              (
                label: 'fc_in=2.0',
                apply: (AudioEffects e) =>
                    e.updateSurround((s) => s.copyWith(fc_in: 2.0)),
              ),
              (
                label: 'fc_out=2.0',
                apply: (AudioEffects e) =>
                    e.updateSurround((s) => s.copyWith(fc_out: 2.0)),
              ),
              (
                label: 'fcx=1.5',
                apply: (AudioEffects e) =>
                    e.updateSurround((s) => s.copyWith(fcx: 1.5)),
              ),
              (
                label: 'fcy=1.5',
                apply: (AudioEffects e) =>
                    e.updateSurround((s) => s.copyWith(fcy: 1.5)),
              ),
              (
                label: 'fl_in=2.0',
                apply: (AudioEffects e) =>
                    e.updateSurround((s) => s.copyWith(fl_in: 2.0)),
              ),
              (
                label: 'fl_out=2.0',
                apply: (AudioEffects e) =>
                    e.updateSurround((s) => s.copyWith(fl_out: 2.0)),
              ),
              (
                label: 'flx=1.5',
                apply: (AudioEffects e) =>
                    e.updateSurround((s) => s.copyWith(flx: 1.5)),
              ),
              (
                label: 'fly=1.5',
                apply: (AudioEffects e) =>
                    e.updateSurround((s) => s.copyWith(fly: 1.5)),
              ),
              (
                label: 'focus=0.5',
                apply: (AudioEffects e) =>
                    e.updateSurround((s) => s.copyWith(focus: 0.5)),
              ),
              (
                label: 'fr_in=2.0',
                apply: (AudioEffects e) =>
                    e.updateSurround((s) => s.copyWith(fr_in: 2.0)),
              ),
              (
                label: 'fr_out=2.0',
                apply: (AudioEffects e) =>
                    e.updateSurround((s) => s.copyWith(fr_out: 2.0)),
              ),
              (
                label: 'frx=1.5',
                apply: (AudioEffects e) =>
                    e.updateSurround((s) => s.copyWith(frx: 1.5)),
              ),
              (
                label: 'fry=1.5',
                apply: (AudioEffects e) =>
                    e.updateSurround((s) => s.copyWith(fry: 1.5)),
              ),
              (
                label: 'level_in=2.0',
                apply: (AudioEffects e) =>
                    e.updateSurround((s) => s.copyWith(level_in: 2.0)),
              ),
              (
                label: 'level_out=2.0',
                apply: (AudioEffects e) =>
                    e.updateSurround((s) => s.copyWith(level_out: 2.0)),
              ),
              (
                label: 'lfe=false',
                apply: (AudioEffects e) =>
                    e.updateSurround((s) => s.copyWith(lfe: false)),
              ),
              (
                label: 'lfe_in=2.0',
                apply: (AudioEffects e) =>
                    e.updateSurround((s) => s.copyWith(lfe_in: 2.0)),
              ),
              (
                label: 'lfe_out=2.0',
                apply: (AudioEffects e) =>
                    e.updateSurround((s) => s.copyWith(lfe_out: 2.0)),
              ),
              (
                label: 'overlap=0.75',
                apply: (AudioEffects e) =>
                    e.updateSurround((s) => s.copyWith(overlap: 0.75)),
              ),
              (
                label: 'sl_in=2.0',
                apply: (AudioEffects e) =>
                    e.updateSurround((s) => s.copyWith(sl_in: 2.0)),
              ),
              (
                label: 'sl_out=2.0',
                apply: (AudioEffects e) =>
                    e.updateSurround((s) => s.copyWith(sl_out: 2.0)),
              ),
              (
                label: 'slx=1.5',
                apply: (AudioEffects e) =>
                    e.updateSurround((s) => s.copyWith(slx: 1.5)),
              ),
              (
                label: 'sly=1.5',
                apply: (AudioEffects e) =>
                    e.updateSurround((s) => s.copyWith(sly: 1.5)),
              ),
              (
                label: 'smooth=0.5',
                apply: (AudioEffects e) =>
                    e.updateSurround((s) => s.copyWith(smooth: 0.5)),
              ),
              (
                label: 'sr_in=2.0',
                apply: (AudioEffects e) =>
                    e.updateSurround((s) => s.copyWith(sr_in: 2.0)),
              ),
              (
                label: 'sr_out=2.0',
                apply: (AudioEffects e) =>
                    e.updateSurround((s) => s.copyWith(sr_out: 2.0)),
              ),
              (
                label: 'srx=1.5',
                apply: (AudioEffects e) =>
                    e.updateSurround((s) => s.copyWith(srx: 1.5)),
              ),
              (
                label: 'sry=1.5',
                apply: (AudioEffects e) =>
                    e.updateSurround((s) => s.copyWith(sry: 1.5)),
              ),
            ],
          ),
          (
            filter: 'tiltshelf',
            field: 'tiltshelf',
            bundle: const AudioEffects(
              tiltshelf: TiltshelfSettings(enabled: true),
            ),
            updates: <AfCommandUpdate>[
              (
                label: 'f=3001.0',
                apply: (AudioEffects e) =>
                    e.updateTiltshelf((s) => s.copyWith(f: 3001.0)),
              ),
              (
                label: 'frequency=3001.0',
                apply: (AudioEffects e) =>
                    e.updateTiltshelf((s) => s.copyWith(frequency: 3001.0)),
              ),
              (
                label: 'g=1.0',
                apply: (AudioEffects e) =>
                    e.updateTiltshelf((s) => s.copyWith(g: 1.0)),
              ),
              (
                label: 'gain=1.0',
                apply: (AudioEffects e) =>
                    e.updateTiltshelf((s) => s.copyWith(gain: 1.0)),
              ),
              (
                label: 'm=0.5',
                apply: (AudioEffects e) =>
                    e.updateTiltshelf((s) => s.copyWith(m: 0.5)),
              ),
              (
                label: 'mix=0.5',
                apply: (AudioEffects e) =>
                    e.updateTiltshelf((s) => s.copyWith(mix: 0.5)),
              ),
              (
                label: 'n=true',
                apply: (AudioEffects e) =>
                    e.updateTiltshelf((s) => s.copyWith(n: true)),
              ),
              (
                label: 'normalize=true',
                apply: (AudioEffects e) =>
                    e.updateTiltshelf((s) => s.copyWith(normalize: true)),
              ),
              (
                label: 'w=1.5',
                apply: (AudioEffects e) =>
                    e.updateTiltshelf((s) => s.copyWith(w: 1.5)),
              ),
              (
                label: 'width=1.5',
                apply: (AudioEffects e) =>
                    e.updateTiltshelf((s) => s.copyWith(width: 1.5)),
              ),
            ],
          ),
          (
            filter: 'treble',
            field: 'treble',
            bundle: const AudioEffects(treble: TrebleSettings(enabled: true)),
            updates: <AfCommandUpdate>[
              (
                label: 'f=3001.0',
                apply: (AudioEffects e) =>
                    e.updateTreble((s) => s.copyWith(f: 3001.0)),
              ),
              (
                label: 'frequency=3001.0',
                apply: (AudioEffects e) =>
                    e.updateTreble((s) => s.copyWith(frequency: 3001.0)),
              ),
              (
                label: 'g=1.0',
                apply: (AudioEffects e) =>
                    e.updateTreble((s) => s.copyWith(g: 1.0)),
              ),
              (
                label: 'gain=1.0',
                apply: (AudioEffects e) =>
                    e.updateTreble((s) => s.copyWith(gain: 1.0)),
              ),
              (
                label: 'm=0.5',
                apply: (AudioEffects e) =>
                    e.updateTreble((s) => s.copyWith(m: 0.5)),
              ),
              (
                label: 'mix=0.5',
                apply: (AudioEffects e) =>
                    e.updateTreble((s) => s.copyWith(mix: 0.5)),
              ),
              (
                label: 'n=true',
                apply: (AudioEffects e) =>
                    e.updateTreble((s) => s.copyWith(n: true)),
              ),
              (
                label: 'normalize=true',
                apply: (AudioEffects e) =>
                    e.updateTreble((s) => s.copyWith(normalize: true)),
              ),
              (
                label: 'w=1.5',
                apply: (AudioEffects e) =>
                    e.updateTreble((s) => s.copyWith(w: 1.5)),
              ),
              (
                label: 'width=1.5',
                apply: (AudioEffects e) =>
                    e.updateTreble((s) => s.copyWith(width: 1.5)),
              ),
            ],
          ),
          (
            filter: 'virtualbass',
            field: 'virtualbass',
            bundle: const AudioEffects(
              virtualbass: VirtualbassSettings(enabled: true),
            ),
            updates: <AfCommandUpdate>[
              (
                label: 'strength=2.0',
                apply: (AudioEffects e) =>
                    e.updateVirtualbass((s) => s.copyWith(strength: 2.0)),
              ),
            ],
          ),
        ];

        for (final c in cases) {
          await player.setAudioEffects(c.bundle);
          var baseline = await player.getRawProperty('af');
          expect(
            baseline,
            contains('@aek_${c.field}:'),
            reason: '${c.filter}: enabled stage must carry its chain label',
          );
          for (final u in c.updates) {
            await player.updateAudioEffects(u.apply);
            var after = await player.getRawProperty('af');
            if (after != baseline) {
              // An af-command can lose the race against a chain (re)build —
              // right after the baseline rewrite or on a loop wrap — and the
              // player then falls back to a rewrite BY DESIGN. Re-arm the
              // baseline values, give the graph a moment, and retry once:
              // only a SECOND rewrite is a real unsupported-command signal.
              await player.setAudioEffects(c.bundle);
              await Future<void>.delayed(const Duration(milliseconds: 250));
              baseline = await player.getRawProperty('af');
              await player.updateAudioEffects(u.apply);
              after = await player.getRawProperty('af');
            }
            expect(
              after,
              baseline,
              reason:
                  '${c.filter} ${u.label}: the af string was rewritten — '
                  'the runtime update did not go through af-command, so '
                  'supports_commands (or the option runtime flag) is wrong '
                  'for the shipped binary',
            );
          }
        }

        // Leave a clean chain behind for whatever runs next.
        await player.setAudioEffects(const AudioEffects());
      },
      timeout: const Timeout(Duration(minutes: 4)),
    );
  });
}
