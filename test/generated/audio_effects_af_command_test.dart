// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license
// that can be found in the LICENSE file.
//
// AUTO-GENERATED — do NOT edit by hand.
//
// Runtime af-command coverage. For every filter whose ffmpeg source
// declares `.process_command` (the schema's `supports_commands` flag
// — the gate for live updates in `audioEffectsDiff`), enable the filter on a
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

import '../_helpers/setter_test_helpers.dart';

typedef AfCommandUpdate = ({
  String label,
  List<AudioEffect> Function(List<AudioEffect>) apply,
});

typedef AfCommandCase = ({
  String filter,
  String field,
  List<AudioEffect> bundle,
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
            field: 'acompressor_0',
            bundle: const [AcompressorEffect()],
            updates: <AfCommandUpdate>[
              (
                label: 'attack=21.0',
                apply: (e) => [
                  (e.single as AcompressorEffect).copyWith(attack: 21.0),
                ],
              ),
              (
                label: 'knee=3.82843',
                apply: (e) => [
                  (e.single as AcompressorEffect).copyWith(knee: 3.82843),
                ],
              ),
              (
                label: 'levelIn=2.0',
                apply: (e) => [
                  (e.single as AcompressorEffect).copyWith(levelIn: 2.0),
                ],
              ),
              (
                label: 'levelSc=2.0',
                apply: (e) => [
                  (e.single as AcompressorEffect).copyWith(levelSc: 2.0),
                ],
              ),
              (
                label: 'makeup=2.0',
                apply: (e) => [
                  (e.single as AcompressorEffect).copyWith(makeup: 2.0),
                ],
              ),
              (
                label: 'mix=0.5',
                apply: (e) => [
                  (e.single as AcompressorEffect).copyWith(mix: 0.5),
                ],
              ),
              (
                label: 'ratio=3.0',
                apply: (e) => [
                  (e.single as AcompressorEffect).copyWith(ratio: 3.0),
                ],
              ),
              (
                label: 'release=251.0',
                apply: (e) => [
                  (e.single as AcompressorEffect).copyWith(release: 251.0),
                ],
              ),
              (
                label: 'threshold=0.5625',
                apply: (e) => [
                  (e.single as AcompressorEffect).copyWith(threshold: 0.5625),
                ],
              ),
            ],
          ),
          (
            filter: 'acrusher',
            field: 'acrusher_0',
            bundle: const [AcrusherEffect()],
            updates: <AfCommandUpdate>[
              (
                label: 'aa=0.75',
                apply: (e) => [(e.single as AcrusherEffect).copyWith(aa: 0.75)],
              ),
              (
                label: 'bits=9.0',
                apply: (e) => [
                  (e.single as AcrusherEffect).copyWith(bits: 9.0),
                ],
              ),
              (
                label: 'dc=2.0',
                apply: (e) => [(e.single as AcrusherEffect).copyWith(dc: 2.0)],
              ),
              (
                label: 'levelIn=2.0',
                apply: (e) => [
                  (e.single as AcrusherEffect).copyWith(levelIn: 2.0),
                ],
              ),
              (
                label: 'levelOut=2.0',
                apply: (e) => [
                  (e.single as AcrusherEffect).copyWith(levelOut: 2.0),
                ],
              ),
              (
                label: 'lfo=true',
                apply: (e) => [
                  (e.single as AcrusherEffect).copyWith(lfo: true),
                ],
              ),
              (
                label: 'lforange=21.0',
                apply: (e) => [
                  (e.single as AcrusherEffect).copyWith(lforange: 21.0),
                ],
              ),
              (
                label: 'lforate=1.3',
                apply: (e) => [
                  (e.single as AcrusherEffect).copyWith(lforate: 1.3),
                ],
              ),
              (
                label: 'mix=0.75',
                apply: (e) => [
                  (e.single as AcrusherEffect).copyWith(mix: 0.75),
                ],
              ),
              (
                label: 'samples=2.0',
                apply: (e) => [
                  (e.single as AcrusherEffect).copyWith(samples: 2.0),
                ],
              ),
            ],
          ),
          (
            filter: 'adelay',
            field: 'adelay_0',
            bundle: const [AdelayEffect(delays: '100')],
            updates: <AfCommandUpdate>[
              (
                label: 'delays=400',
                apply: (e) => [
                  (e.single as AdelayEffect).copyWith(delays: '400'),
                ],
              ),
            ],
          ),
          (
            filter: 'adenorm',
            field: 'adenorm_0',
            bundle: const [AdenormEffect()],
            updates: <AfCommandUpdate>[
              (
                label: 'level=-350.0',
                apply: (e) => [
                  (e.single as AdenormEffect).copyWith(level: -350.0),
                ],
              ),
            ],
          ),
          (
            filter: 'adrc',
            field: 'adrc_0',
            bundle: const [AdrcEffect()],
            updates: <AfCommandUpdate>[
              (
                label: 'attack=51.0',
                apply: (e) => [(e.single as AdrcEffect).copyWith(attack: 51.0)],
              ),
              (
                label: 'release=101.0',
                apply: (e) => [
                  (e.single as AdrcEffect).copyWith(release: 101.0),
                ],
              ),
            ],
          ),
          (
            filter: 'adynamicequalizer',
            field: 'adynamicequalizer_0',
            bundle: const [AdynamicequalizerEffect()],
            updates: <AfCommandUpdate>[
              (
                label: 'attack=21.0',
                apply: (e) => [
                  (e.single as AdynamicequalizerEffect).copyWith(attack: 21.0),
                ],
              ),
              (
                label: 'dfrequency=1001.0',
                apply: (e) => [
                  (e.single as AdynamicequalizerEffect).copyWith(
                    dfrequency: 1001.0,
                  ),
                ],
              ),
              (
                label: 'dqfactor=2.0',
                apply: (e) => [
                  (e.single as AdynamicequalizerEffect).copyWith(dqfactor: 2.0),
                ],
              ),
              (
                label: 'makeup=1.0',
                apply: (e) => [
                  (e.single as AdynamicequalizerEffect).copyWith(makeup: 1.0),
                ],
              ),
              (
                label: 'range=51.0',
                apply: (e) => [
                  (e.single as AdynamicequalizerEffect).copyWith(range: 51.0),
                ],
              ),
              (
                label: 'ratio=2.0',
                apply: (e) => [
                  (e.single as AdynamicequalizerEffect).copyWith(ratio: 2.0),
                ],
              ),
              (
                label: 'release=201.0',
                apply: (e) => [
                  (e.single as AdynamicequalizerEffect).copyWith(
                    release: 201.0,
                  ),
                ],
              ),
              (
                label: 'tfrequency=1001.0',
                apply: (e) => [
                  (e.single as AdynamicequalizerEffect).copyWith(
                    tfrequency: 1001.0,
                  ),
                ],
              ),
              (
                label: 'threshold=1.0',
                apply: (e) => [
                  (e.single as AdynamicequalizerEffect).copyWith(
                    threshold: 1.0,
                  ),
                ],
              ),
              (
                label: 'tqfactor=2.0',
                apply: (e) => [
                  (e.single as AdynamicequalizerEffect).copyWith(tqfactor: 2.0),
                ],
              ),
            ],
          ),
          (
            filter: 'adynamicsmooth',
            field: 'adynamicsmooth_0',
            bundle: const [AdynamicsmoothEffect()],
            updates: <AfCommandUpdate>[
              (
                label: 'basefreq=22051.0',
                apply: (e) => [
                  (e.single as AdynamicsmoothEffect).copyWith(
                    basefreq: 22051.0,
                  ),
                ],
              ),
              (
                label: 'sensitivity=3.0',
                apply: (e) => [
                  (e.single as AdynamicsmoothEffect).copyWith(sensitivity: 3.0),
                ],
              ),
            ],
          ),
          (
            filter: 'aemphasis',
            field: 'aemphasis_0',
            bundle: const [AemphasisEffect()],
            updates: <AfCommandUpdate>[
              (
                label: 'levelIn=2.0',
                apply: (e) => [
                  (e.single as AemphasisEffect).copyWith(levelIn: 2.0),
                ],
              ),
              (
                label: 'levelOut=2.0',
                apply: (e) => [
                  (e.single as AemphasisEffect).copyWith(levelOut: 2.0),
                ],
              ),
            ],
          ),
          (
            filter: 'aexciter',
            field: 'aexciter_0',
            bundle: const [AexciterEffect()],
            updates: <AfCommandUpdate>[
              (
                label: 'amount=2.0',
                apply: (e) => [
                  (e.single as AexciterEffect).copyWith(amount: 2.0),
                ],
              ),
              (
                label: 'blend=1.0',
                apply: (e) => [
                  (e.single as AexciterEffect).copyWith(blend: 1.0),
                ],
              ),
              (
                label: 'ceil=10000.0',
                apply: (e) => [
                  (e.single as AexciterEffect).copyWith(ceil: 10000.0),
                ],
              ),
              (
                label: 'drive=9.25',
                apply: (e) => [
                  (e.single as AexciterEffect).copyWith(drive: 9.25),
                ],
              ),
              (
                label: 'freq=7501.0',
                apply: (e) => [
                  (e.single as AexciterEffect).copyWith(freq: 7501.0),
                ],
              ),
              (
                label: 'levelIn=2.0',
                apply: (e) => [
                  (e.single as AexciterEffect).copyWith(levelIn: 2.0),
                ],
              ),
              (
                label: 'levelOut=2.0',
                apply: (e) => [
                  (e.single as AexciterEffect).copyWith(levelOut: 2.0),
                ],
              ),
              (
                label: 'listen=true',
                apply: (e) => [
                  (e.single as AexciterEffect).copyWith(listen: true),
                ],
              ),
            ],
          ),
          (
            filter: 'afade',
            field: 'afade_0',
            bundle: const [AfadeEffect()],
            updates: <AfCommandUpdate>[
              (
                label: 'nbSamples=44101',
                apply: (e) => [
                  (e.single as AfadeEffect).copyWith(nbSamples: 44101),
                ],
              ),
              (
                label: 'ns=44101',
                apply: (e) => [(e.single as AfadeEffect).copyWith(ns: 44101)],
              ),
              (
                label: 'silence=0.5',
                apply: (e) => [
                  (e.single as AfadeEffect).copyWith(silence: 0.5),
                ],
              ),
              (
                label: 'ss=1',
                apply: (e) => [(e.single as AfadeEffect).copyWith(ss: 1)],
              ),
              (
                label: 'startSample=1',
                apply: (e) => [
                  (e.single as AfadeEffect).copyWith(startSample: 1),
                ],
              ),
              (
                label: 'unity=0.5',
                apply: (e) => [(e.single as AfadeEffect).copyWith(unity: 0.5)],
              ),
            ],
          ),
          (
            filter: 'afftdn',
            field: 'afftdn_0',
            bundle: const [AfftdnEffect()],
            updates: <AfCommandUpdate>[
              (
                label: 'ad=0.75',
                apply: (e) => [(e.single as AfftdnEffect).copyWith(ad: 0.75)],
              ),
              (
                label: 'adaptivity=0.75',
                apply: (e) => [
                  (e.single as AfftdnEffect).copyWith(adaptivity: 0.75),
                ],
              ),
              (
                label: 'floorOffset=1.5',
                apply: (e) => [
                  (e.single as AfftdnEffect).copyWith(floorOffset: 1.5),
                ],
              ),
              (
                label: 'fo=1.5',
                apply: (e) => [(e.single as AfftdnEffect).copyWith(fo: 1.5)],
              ),
              (
                label: 'gainSmooth=1',
                apply: (e) => [
                  (e.single as AfftdnEffect).copyWith(gainSmooth: 1),
                ],
              ),
              (
                label: 'gs=1',
                apply: (e) => [(e.single as AfftdnEffect).copyWith(gs: 1)],
              ),
              (
                label: 'nf=-49.0',
                apply: (e) => [(e.single as AfftdnEffect).copyWith(nf: -49.0)],
              ),
              (
                label: 'noiseFloor=-49.0',
                apply: (e) => [
                  (e.single as AfftdnEffect).copyWith(noiseFloor: -49.0),
                ],
              ),
              (
                label: 'noiseReduction=13.0',
                apply: (e) => [
                  (e.single as AfftdnEffect).copyWith(noiseReduction: 13.0),
                ],
              ),
              (
                label: 'nr=13.0',
                apply: (e) => [(e.single as AfftdnEffect).copyWith(nr: 13.0)],
              ),
              (
                label: 'residualFloor=-37.0',
                apply: (e) => [
                  (e.single as AfftdnEffect).copyWith(residualFloor: -37.0),
                ],
              ),
              (
                label: 'rf=-37.0',
                apply: (e) => [(e.single as AfftdnEffect).copyWith(rf: -37.0)],
              ),
              (
                label: 'tn=true',
                apply: (e) => [(e.single as AfftdnEffect).copyWith(tn: true)],
              ),
              (
                label: 'tr=true',
                apply: (e) => [(e.single as AfftdnEffect).copyWith(tr: true)],
              ),
              (
                label: 'trackNoise=true',
                apply: (e) => [
                  (e.single as AfftdnEffect).copyWith(trackNoise: true),
                ],
              ),
              (
                label: 'trackResidual=true',
                apply: (e) => [
                  (e.single as AfftdnEffect).copyWith(trackResidual: true),
                ],
              ),
            ],
          ),
          (
            filter: 'afreqshift',
            field: 'afreqshift_0',
            bundle: const [AfreqshiftEffect()],
            updates: <AfCommandUpdate>[
              (
                label: 'level=0.5',
                apply: (e) => [
                  (e.single as AfreqshiftEffect).copyWith(level: 0.5),
                ],
              ),
              (
                label: 'order=9',
                apply: (e) => [
                  (e.single as AfreqshiftEffect).copyWith(order: 9),
                ],
              ),
              (
                label: 'shift=1.0',
                apply: (e) => [
                  (e.single as AfreqshiftEffect).copyWith(shift: 1.0),
                ],
              ),
            ],
          ),
          (
            filter: 'afwtdn',
            field: 'afwtdn_0',
            bundle: const [AfwtdnEffect()],
            updates: <AfCommandUpdate>[
              (
                label: 'adaptive=true',
                apply: (e) => [
                  (e.single as AfwtdnEffect).copyWith(adaptive: true),
                ],
              ),
              (
                label: 'percent=86.0',
                apply: (e) => [
                  (e.single as AfwtdnEffect).copyWith(percent: 86.0),
                ],
              ),
              (
                label: 'profile=true',
                apply: (e) => [
                  (e.single as AfwtdnEffect).copyWith(profile: true),
                ],
              ),
              (
                label: 'sigma=0.5',
                apply: (e) => [(e.single as AfwtdnEffect).copyWith(sigma: 0.5)],
              ),
              (
                label: 'softness=2.0',
                apply: (e) => [
                  (e.single as AfwtdnEffect).copyWith(softness: 2.0),
                ],
              ),
            ],
          ),
          (
            filter: 'agate',
            field: 'agate_0',
            bundle: const [AgateEffect()],
            updates: <AfCommandUpdate>[
              (
                label: 'attack=21.0',
                apply: (e) => [
                  (e.single as AgateEffect).copyWith(attack: 21.0),
                ],
              ),
              (
                label: 'knee=3.82843',
                apply: (e) => [
                  (e.single as AgateEffect).copyWith(knee: 3.82843),
                ],
              ),
              (
                label: 'levelIn=2.0',
                apply: (e) => [
                  (e.single as AgateEffect).copyWith(levelIn: 2.0),
                ],
              ),
              (
                label: 'levelSc=2.0',
                apply: (e) => [
                  (e.single as AgateEffect).copyWith(levelSc: 2.0),
                ],
              ),
              (
                label: 'makeup=2.0',
                apply: (e) => [(e.single as AgateEffect).copyWith(makeup: 2.0)],
              ),
              (
                label: 'range=0.530625',
                apply: (e) => [
                  (e.single as AgateEffect).copyWith(range: 0.530625),
                ],
              ),
              (
                label: 'ratio=3.0',
                apply: (e) => [(e.single as AgateEffect).copyWith(ratio: 3.0)],
              ),
              (
                label: 'release=251.0',
                apply: (e) => [
                  (e.single as AgateEffect).copyWith(release: 251.0),
                ],
              ),
              (
                label: 'threshold=0.5625',
                apply: (e) => [
                  (e.single as AgateEffect).copyWith(threshold: 0.5625),
                ],
              ),
            ],
          ),
          (
            filter: 'alimiter',
            field: 'alimiter_0',
            bundle: const [AlimiterEffect()],
            updates: <AfCommandUpdate>[
              (
                label: 'asc=true',
                apply: (e) => [
                  (e.single as AlimiterEffect).copyWith(asc: true),
                ],
              ),
              (
                label: 'ascLevel=0.75',
                apply: (e) => [
                  (e.single as AlimiterEffect).copyWith(ascLevel: 0.75),
                ],
              ),
              (
                label: 'attack=6.0',
                apply: (e) => [
                  (e.single as AlimiterEffect).copyWith(attack: 6.0),
                ],
              ),
              (
                label: 'latency=true',
                apply: (e) => [
                  (e.single as AlimiterEffect).copyWith(latency: true),
                ],
              ),
              (
                label: 'level=false',
                apply: (e) => [
                  (e.single as AlimiterEffect).copyWith(level: false),
                ],
              ),
              (
                label: 'levelIn=2.0',
                apply: (e) => [
                  (e.single as AlimiterEffect).copyWith(levelIn: 2.0),
                ],
              ),
              (
                label: 'levelOut=2.0',
                apply: (e) => [
                  (e.single as AlimiterEffect).copyWith(levelOut: 2.0),
                ],
              ),
              (
                label: 'limit=0.53125',
                apply: (e) => [
                  (e.single as AlimiterEffect).copyWith(limit: 0.53125),
                ],
              ),
              (
                label: 'release=51.0',
                apply: (e) => [
                  (e.single as AlimiterEffect).copyWith(release: 51.0),
                ],
              ),
            ],
          ),
          (
            filter: 'allpass',
            field: 'allpass_0',
            bundle: const [AllpassEffect()],
            updates: <AfCommandUpdate>[
              (
                label: 'f=3001.0',
                apply: (e) => [(e.single as AllpassEffect).copyWith(f: 3001.0)],
              ),
              (
                label: 'frequency=3001.0',
                apply: (e) => [
                  (e.single as AllpassEffect).copyWith(frequency: 3001.0),
                ],
              ),
              (
                label: 'm=0.5',
                apply: (e) => [(e.single as AllpassEffect).copyWith(m: 0.5)],
              ),
              (
                label: 'mix=0.5',
                apply: (e) => [(e.single as AllpassEffect).copyWith(mix: 0.5)],
              ),
              (
                label: 'n=true',
                apply: (e) => [(e.single as AllpassEffect).copyWith(n: true)],
              ),
              (
                label: 'normalize=true',
                apply: (e) => [
                  (e.single as AllpassEffect).copyWith(normalize: true),
                ],
              ),
              (
                label: 'o=1',
                apply: (e) => [(e.single as AllpassEffect).copyWith(o: 1)],
              ),
              (
                label: 'order=1',
                apply: (e) => [(e.single as AllpassEffect).copyWith(order: 1)],
              ),
              (
                label: 'w=1.707',
                apply: (e) => [(e.single as AllpassEffect).copyWith(w: 1.707)],
              ),
              (
                label: 'width=1.707',
                apply: (e) => [
                  (e.single as AllpassEffect).copyWith(width: 1.707),
                ],
              ),
            ],
          ),
          (
            filter: 'anlmdn',
            field: 'anlmdn_0',
            bundle: const [AnlmdnEffect()],
            updates: <AfCommandUpdate>[
              (
                label: 'm=12.0',
                apply: (e) => [(e.single as AnlmdnEffect).copyWith(m: 12.0)],
              ),
              (
                label: 's=1.00001',
                apply: (e) => [(e.single as AnlmdnEffect).copyWith(s: 1.00001)],
              ),
              (
                label: 'smooth=12.0',
                apply: (e) => [
                  (e.single as AnlmdnEffect).copyWith(smooth: 12.0),
                ],
              ),
              (
                label: 'strength=1.00001',
                apply: (e) => [
                  (e.single as AnlmdnEffect).copyWith(strength: 1.00001),
                ],
              ),
            ],
          ),
          (
            filter: 'aphaseshift',
            field: 'aphaseshift_0',
            bundle: const [AphaseshiftEffect()],
            updates: <AfCommandUpdate>[
              (
                label: 'level=0.5',
                apply: (e) => [
                  (e.single as AphaseshiftEffect).copyWith(level: 0.5),
                ],
              ),
              (
                label: 'order=9',
                apply: (e) => [
                  (e.single as AphaseshiftEffect).copyWith(order: 9),
                ],
              ),
              (
                label: 'shift=0.5',
                apply: (e) => [
                  (e.single as AphaseshiftEffect).copyWith(shift: 0.5),
                ],
              ),
            ],
          ),
          (
            filter: 'apsyclip',
            field: 'apsyclip_0',
            bundle: const [ApsyclipEffect()],
            updates: <AfCommandUpdate>[
              (
                label: 'adaptive=0.75',
                apply: (e) => [
                  (e.single as ApsyclipEffect).copyWith(adaptive: 0.75),
                ],
              ),
              (
                label: 'clip=0.507812',
                apply: (e) => [
                  (e.single as ApsyclipEffect).copyWith(clip: 0.507812),
                ],
              ),
              (
                label: 'diff=true',
                apply: (e) => [
                  (e.single as ApsyclipEffect).copyWith(diff: true),
                ],
              ),
              (
                label: 'iterations=11',
                apply: (e) => [
                  (e.single as ApsyclipEffect).copyWith(iterations: 11),
                ],
              ),
              (
                label: 'level=true',
                apply: (e) => [
                  (e.single as ApsyclipEffect).copyWith(level: true),
                ],
              ),
              (
                label: 'levelIn=2.0',
                apply: (e) => [
                  (e.single as ApsyclipEffect).copyWith(levelIn: 2.0),
                ],
              ),
              (
                label: 'levelOut=2.0',
                apply: (e) => [
                  (e.single as ApsyclipEffect).copyWith(levelOut: 2.0),
                ],
              ),
            ],
          ),
          (
            filter: 'arnndn',
            field: 'arnndn_0',
            bundle: [ArnndnEffect(model: arnndnModelPath)],
            updates: <AfCommandUpdate>[
              (
                label: 'mix=0.0',
                apply: (e) => [(e.single as ArnndnEffect).copyWith(mix: 0.0)],
              ),
            ],
          ),
          (
            filter: 'asoftclip',
            field: 'asoftclip_0',
            bundle: const [AsoftclipEffect()],
            updates: <AfCommandUpdate>[
              (
                label: 'output=2.0',
                apply: (e) => [
                  (e.single as AsoftclipEffect).copyWith(output: 2.0),
                ],
              ),
              (
                label: 'oversample=2',
                apply: (e) => [
                  (e.single as AsoftclipEffect).copyWith(oversample: 2),
                ],
              ),
              (
                label: 'param=2.0',
                apply: (e) => [
                  (e.single as AsoftclipEffect).copyWith(param: 2.0),
                ],
              ),
              (
                label: 'threshold=0.500001',
                apply: (e) => [
                  (e.single as AsoftclipEffect).copyWith(threshold: 0.500001),
                ],
              ),
            ],
          ),
          (
            filter: 'asubboost',
            field: 'asubboost_0',
            bundle: const [AsubboostEffect()],
            updates: <AfCommandUpdate>[
              (
                label: 'boost=3.0',
                apply: (e) => [
                  (e.single as AsubboostEffect).copyWith(boost: 3.0),
                ],
              ),
              (
                label: 'cutoff=101.0',
                apply: (e) => [
                  (e.single as AsubboostEffect).copyWith(cutoff: 101.0),
                ],
              ),
              (
                label: 'decay=0.5',
                apply: (e) => [
                  (e.single as AsubboostEffect).copyWith(decay: 0.5),
                ],
              ),
              (
                label: 'delay=21.0',
                apply: (e) => [
                  (e.single as AsubboostEffect).copyWith(delay: 21.0),
                ],
              ),
              (
                label: 'dry=0.5',
                apply: (e) => [
                  (e.single as AsubboostEffect).copyWith(dry: 0.5),
                ],
              ),
              (
                label: 'feedback=0.95',
                apply: (e) => [
                  (e.single as AsubboostEffect).copyWith(feedback: 0.95),
                ],
              ),
              (
                label: 'slope=0.75',
                apply: (e) => [
                  (e.single as AsubboostEffect).copyWith(slope: 0.75),
                ],
              ),
              (
                label: 'wet=0.5',
                apply: (e) => [
                  (e.single as AsubboostEffect).copyWith(wet: 0.5),
                ],
              ),
            ],
          ),
          (
            filter: 'asubcut',
            field: 'asubcut_0',
            bundle: const [AsubcutEffect()],
            updates: <AfCommandUpdate>[
              (
                label: 'cutoff=21.0',
                apply: (e) => [
                  (e.single as AsubcutEffect).copyWith(cutoff: 21.0),
                ],
              ),
              (
                label: 'level=0.5',
                apply: (e) => [
                  (e.single as AsubcutEffect).copyWith(level: 0.5),
                ],
              ),
              (
                label: 'order=11',
                apply: (e) => [(e.single as AsubcutEffect).copyWith(order: 11)],
              ),
            ],
          ),
          (
            filter: 'asupercut',
            field: 'asupercut_0',
            bundle: const [AsupercutEffect()],
            updates: <AfCommandUpdate>[
              (
                label: 'cutoff=20001.0',
                apply: (e) => [
                  (e.single as AsupercutEffect).copyWith(cutoff: 20001.0),
                ],
              ),
              (
                label: 'level=0.5',
                apply: (e) => [
                  (e.single as AsupercutEffect).copyWith(level: 0.5),
                ],
              ),
              (
                label: 'order=11',
                apply: (e) => [
                  (e.single as AsupercutEffect).copyWith(order: 11),
                ],
              ),
            ],
          ),
          (
            filter: 'asuperpass',
            field: 'asuperpass_0',
            bundle: const [AsuperpassEffect()],
            updates: <AfCommandUpdate>[
              (
                label: 'centerf=1001.0',
                apply: (e) => [
                  (e.single as AsuperpassEffect).copyWith(centerf: 1001.0),
                ],
              ),
              (
                label: 'level=1.5',
                apply: (e) => [
                  (e.single as AsuperpassEffect).copyWith(level: 1.5),
                ],
              ),
              (
                label: 'order=5',
                apply: (e) => [
                  (e.single as AsuperpassEffect).copyWith(order: 5),
                ],
              ),
              (
                label: 'qfactor=2.0',
                apply: (e) => [
                  (e.single as AsuperpassEffect).copyWith(qfactor: 2.0),
                ],
              ),
            ],
          ),
          (
            filter: 'asuperstop',
            field: 'asuperstop_0',
            bundle: const [AsuperstopEffect()],
            updates: <AfCommandUpdate>[
              (
                label: 'centerf=1001.0',
                apply: (e) => [
                  (e.single as AsuperstopEffect).copyWith(centerf: 1001.0),
                ],
              ),
              (
                label: 'level=1.5',
                apply: (e) => [
                  (e.single as AsuperstopEffect).copyWith(level: 1.5),
                ],
              ),
              (
                label: 'order=5',
                apply: (e) => [
                  (e.single as AsuperstopEffect).copyWith(order: 5),
                ],
              ),
              (
                label: 'qfactor=2.0',
                apply: (e) => [
                  (e.single as AsuperstopEffect).copyWith(qfactor: 2.0),
                ],
              ),
            ],
          ),
          (
            filter: 'atempo',
            field: 'atempo_0',
            bundle: const [AtempoEffect()],
            updates: <AfCommandUpdate>[
              (
                label: 'tempo=2.0',
                apply: (e) => [(e.single as AtempoEffect).copyWith(tempo: 2.0)],
              ),
            ],
          ),
          (
            filter: 'atilt',
            field: 'atilt_0',
            bundle: const [AtiltEffect()],
            updates: <AfCommandUpdate>[
              (
                label: 'freq=10001.0',
                apply: (e) => [
                  (e.single as AtiltEffect).copyWith(freq: 10001.0),
                ],
              ),
              (
                label: 'level=2.0',
                apply: (e) => [(e.single as AtiltEffect).copyWith(level: 2.0)],
              ),
              (
                label: 'order=6',
                apply: (e) => [(e.single as AtiltEffect).copyWith(order: 6)],
              ),
              (
                label: 'slope=0.5',
                apply: (e) => [(e.single as AtiltEffect).copyWith(slope: 0.5)],
              ),
              (
                label: 'width=1001.0',
                apply: (e) => [
                  (e.single as AtiltEffect).copyWith(width: 1001.0),
                ],
              ),
            ],
          ),
          (
            filter: 'bandpass',
            field: 'bandpass_0',
            bundle: const [BandpassEffect()],
            updates: <AfCommandUpdate>[
              (
                label: 'csg=true',
                apply: (e) => [
                  (e.single as BandpassEffect).copyWith(csg: true),
                ],
              ),
              (
                label: 'f=3001.0',
                apply: (e) => [
                  (e.single as BandpassEffect).copyWith(f: 3001.0),
                ],
              ),
              (
                label: 'frequency=3001.0',
                apply: (e) => [
                  (e.single as BandpassEffect).copyWith(frequency: 3001.0),
                ],
              ),
              (
                label: 'm=0.5',
                apply: (e) => [(e.single as BandpassEffect).copyWith(m: 0.5)],
              ),
              (
                label: 'mix=0.5',
                apply: (e) => [(e.single as BandpassEffect).copyWith(mix: 0.5)],
              ),
              (
                label: 'n=true',
                apply: (e) => [(e.single as BandpassEffect).copyWith(n: true)],
              ),
              (
                label: 'normalize=true',
                apply: (e) => [
                  (e.single as BandpassEffect).copyWith(normalize: true),
                ],
              ),
              (
                label: 'w=1.5',
                apply: (e) => [(e.single as BandpassEffect).copyWith(w: 1.5)],
              ),
              (
                label: 'width=1.5',
                apply: (e) => [
                  (e.single as BandpassEffect).copyWith(width: 1.5),
                ],
              ),
            ],
          ),
          (
            filter: 'bandreject',
            field: 'bandreject_0',
            bundle: const [BandrejectEffect()],
            updates: <AfCommandUpdate>[
              (
                label: 'f=3001.0',
                apply: (e) => [
                  (e.single as BandrejectEffect).copyWith(f: 3001.0),
                ],
              ),
              (
                label: 'frequency=3001.0',
                apply: (e) => [
                  (e.single as BandrejectEffect).copyWith(frequency: 3001.0),
                ],
              ),
              (
                label: 'm=0.5',
                apply: (e) => [(e.single as BandrejectEffect).copyWith(m: 0.5)],
              ),
              (
                label: 'mix=0.5',
                apply: (e) => [
                  (e.single as BandrejectEffect).copyWith(mix: 0.5),
                ],
              ),
              (
                label: 'n=true',
                apply: (e) => [
                  (e.single as BandrejectEffect).copyWith(n: true),
                ],
              ),
              (
                label: 'normalize=true',
                apply: (e) => [
                  (e.single as BandrejectEffect).copyWith(normalize: true),
                ],
              ),
              (
                label: 'w=1.5',
                apply: (e) => [(e.single as BandrejectEffect).copyWith(w: 1.5)],
              ),
              (
                label: 'width=1.5',
                apply: (e) => [
                  (e.single as BandrejectEffect).copyWith(width: 1.5),
                ],
              ),
            ],
          ),
          (
            filter: 'bass',
            field: 'bass_0',
            bundle: const [BassEffect()],
            updates: <AfCommandUpdate>[
              (
                label: 'f=101.0',
                apply: (e) => [(e.single as BassEffect).copyWith(f: 101.0)],
              ),
              (
                label: 'frequency=101.0',
                apply: (e) => [
                  (e.single as BassEffect).copyWith(frequency: 101.0),
                ],
              ),
              (
                label: 'g=1.0',
                apply: (e) => [(e.single as BassEffect).copyWith(g: 1.0)],
              ),
              (
                label: 'gain=1.0',
                apply: (e) => [(e.single as BassEffect).copyWith(gain: 1.0)],
              ),
              (
                label: 'm=0.5',
                apply: (e) => [(e.single as BassEffect).copyWith(m: 0.5)],
              ),
              (
                label: 'mix=0.5',
                apply: (e) => [(e.single as BassEffect).copyWith(mix: 0.5)],
              ),
              (
                label: 'n=true',
                apply: (e) => [(e.single as BassEffect).copyWith(n: true)],
              ),
              (
                label: 'normalize=true',
                apply: (e) => [
                  (e.single as BassEffect).copyWith(normalize: true),
                ],
              ),
              (
                label: 'w=1.5',
                apply: (e) => [(e.single as BassEffect).copyWith(w: 1.5)],
              ),
              (
                label: 'width=1.5',
                apply: (e) => [(e.single as BassEffect).copyWith(width: 1.5)],
              ),
            ],
          ),
          (
            filter: 'biquad',
            field: 'biquad_0',
            bundle: const [BiquadEffect()],
            updates: <AfCommandUpdate>[
              (
                label: 'a0=2.0',
                apply: (e) => [(e.single as BiquadEffect).copyWith(a0: 2.0)],
              ),
              (
                label: 'a1=1.0',
                apply: (e) => [(e.single as BiquadEffect).copyWith(a1: 1.0)],
              ),
              (
                label: 'a2=1.0',
                apply: (e) => [(e.single as BiquadEffect).copyWith(a2: 1.0)],
              ),
              (
                label: 'b0=1.0',
                apply: (e) => [(e.single as BiquadEffect).copyWith(b0: 1.0)],
              ),
              (
                label: 'b1=1.0',
                apply: (e) => [(e.single as BiquadEffect).copyWith(b1: 1.0)],
              ),
              (
                label: 'b2=1.0',
                apply: (e) => [(e.single as BiquadEffect).copyWith(b2: 1.0)],
              ),
              (
                label: 'm=0.5',
                apply: (e) => [(e.single as BiquadEffect).copyWith(m: 0.5)],
              ),
              (
                label: 'mix=0.5',
                apply: (e) => [(e.single as BiquadEffect).copyWith(mix: 0.5)],
              ),
              (
                label: 'n=true',
                apply: (e) => [(e.single as BiquadEffect).copyWith(n: true)],
              ),
              (
                label: 'normalize=true',
                apply: (e) => [
                  (e.single as BiquadEffect).copyWith(normalize: true),
                ],
              ),
            ],
          ),
          (
            filter: 'crossfeed',
            field: 'crossfeed_0',
            bundle: const [CrossfeedEffect()],
            updates: <AfCommandUpdate>[
              (
                label: 'levelIn=0.95',
                apply: (e) => [
                  (e.single as CrossfeedEffect).copyWith(levelIn: 0.95),
                ],
              ),
              (
                label: 'levelOut=0.5',
                apply: (e) => [
                  (e.single as CrossfeedEffect).copyWith(levelOut: 0.5),
                ],
              ),
              (
                label: 'range=0.75',
                apply: (e) => [
                  (e.single as CrossfeedEffect).copyWith(range: 0.75),
                ],
              ),
              (
                label: 'slope=0.75',
                apply: (e) => [
                  (e.single as CrossfeedEffect).copyWith(slope: 0.75),
                ],
              ),
              (
                label: 'strength=0.6',
                apply: (e) => [
                  (e.single as CrossfeedEffect).copyWith(strength: 0.6),
                ],
              ),
            ],
          ),
          (
            filter: 'crystalizer',
            field: 'crystalizer_0',
            bundle: const [CrystalizerEffect()],
            updates: <AfCommandUpdate>[
              (
                label: 'c=false',
                apply: (e) => [
                  (e.single as CrystalizerEffect).copyWith(c: false),
                ],
              ),
              (
                label: 'i=3.0',
                apply: (e) => [
                  (e.single as CrystalizerEffect).copyWith(i: 3.0),
                ],
              ),
            ],
          ),
          (
            filter: 'dialoguenhance',
            field: 'dialoguenhance_0',
            bundle: const [DialoguenhanceEffect()],
            updates: <AfCommandUpdate>[
              (
                label: 'enhance=2.0',
                apply: (e) => [
                  (e.single as DialoguenhanceEffect).copyWith(enhance: 2.0),
                ],
              ),
              (
                label: 'original=0.5',
                apply: (e) => [
                  (e.single as DialoguenhanceEffect).copyWith(original: 0.5),
                ],
              ),
              (
                label: 'voice=3.0',
                apply: (e) => [
                  (e.single as DialoguenhanceEffect).copyWith(voice: 3.0),
                ],
              ),
            ],
          ),
          (
            filter: 'dynaudnorm',
            field: 'dynaudnorm_0',
            bundle: const [DynaudnormEffect()],
            updates: <AfCommandUpdate>[
              (
                label: 'altboundary=true',
                apply: (e) => [
                  (e.single as DynaudnormEffect).copyWith(altboundary: true),
                ],
              ),
              (
                label: 'b=true',
                apply: (e) => [
                  (e.single as DynaudnormEffect).copyWith(b: true),
                ],
              ),
              (
                label: 'c=true',
                apply: (e) => [
                  (e.single as DynaudnormEffect).copyWith(c: true),
                ],
              ),
              (
                label: 'compress=1.0',
                apply: (e) => [
                  (e.single as DynaudnormEffect).copyWith(compress: 1.0),
                ],
              ),
              (
                label: 'correctdc=true',
                apply: (e) => [
                  (e.single as DynaudnormEffect).copyWith(correctdc: true),
                ],
              ),
              (
                label: 'coupling=false',
                apply: (e) => [
                  (e.single as DynaudnormEffect).copyWith(coupling: false),
                ],
              ),
              (
                label: 'f=501',
                apply: (e) => [(e.single as DynaudnormEffect).copyWith(f: 501)],
              ),
              (
                label: 'framelen=501',
                apply: (e) => [
                  (e.single as DynaudnormEffect).copyWith(framelen: 501),
                ],
              ),
              (
                label: 'g=32',
                apply: (e) => [(e.single as DynaudnormEffect).copyWith(g: 32)],
              ),
              (
                label: 'gausssize=32',
                apply: (e) => [
                  (e.single as DynaudnormEffect).copyWith(gausssize: 32),
                ],
              ),
              (
                label: 'm=11.0',
                apply: (e) => [
                  (e.single as DynaudnormEffect).copyWith(m: 11.0),
                ],
              ),
              (
                label: 'maxgain=11.0',
                apply: (e) => [
                  (e.single as DynaudnormEffect).copyWith(maxgain: 11.0),
                ],
              ),
              (
                label: 'n=false',
                apply: (e) => [
                  (e.single as DynaudnormEffect).copyWith(n: false),
                ],
              ),
              (
                label: 'o=0.5',
                apply: (e) => [(e.single as DynaudnormEffect).copyWith(o: 0.5)],
              ),
              (
                label: 'overlap=0.5',
                apply: (e) => [
                  (e.single as DynaudnormEffect).copyWith(overlap: 0.5),
                ],
              ),
              (
                label: 'p=0.975',
                apply: (e) => [
                  (e.single as DynaudnormEffect).copyWith(p: 0.975),
                ],
              ),
              (
                label: 'peak=0.975',
                apply: (e) => [
                  (e.single as DynaudnormEffect).copyWith(peak: 0.975),
                ],
              ),
              (
                label: 'r=0.5',
                apply: (e) => [(e.single as DynaudnormEffect).copyWith(r: 0.5)],
              ),
              (
                label: 's=1.0',
                apply: (e) => [(e.single as DynaudnormEffect).copyWith(s: 1.0)],
              ),
              (
                label: 't=0.5',
                apply: (e) => [(e.single as DynaudnormEffect).copyWith(t: 0.5)],
              ),
              (
                label: 'targetrms=0.5',
                apply: (e) => [
                  (e.single as DynaudnormEffect).copyWith(targetrms: 0.5),
                ],
              ),
              (
                label: 'threshold=0.5',
                apply: (e) => [
                  (e.single as DynaudnormEffect).copyWith(threshold: 0.5),
                ],
              ),
            ],
          ),
          (
            filter: 'equalizer',
            field: 'equalizer_0',
            bundle: const [EqualizerEffect()],
            updates: <AfCommandUpdate>[
              (
                label: 'f=1.0',
                apply: (e) => [(e.single as EqualizerEffect).copyWith(f: 1.0)],
              ),
              (
                label: 'frequency=1.0',
                apply: (e) => [
                  (e.single as EqualizerEffect).copyWith(frequency: 1.0),
                ],
              ),
              (
                label: 'g=1.0',
                apply: (e) => [(e.single as EqualizerEffect).copyWith(g: 1.0)],
              ),
              (
                label: 'gain=1.0',
                apply: (e) => [
                  (e.single as EqualizerEffect).copyWith(gain: 1.0),
                ],
              ),
              (
                label: 'm=0.5',
                apply: (e) => [(e.single as EqualizerEffect).copyWith(m: 0.5)],
              ),
              (
                label: 'mix=0.5',
                apply: (e) => [
                  (e.single as EqualizerEffect).copyWith(mix: 0.5),
                ],
              ),
              (
                label: 'n=true',
                apply: (e) => [(e.single as EqualizerEffect).copyWith(n: true)],
              ),
              (
                label: 'normalize=true',
                apply: (e) => [
                  (e.single as EqualizerEffect).copyWith(normalize: true),
                ],
              ),
              (
                label: 'w=2.0',
                apply: (e) => [(e.single as EqualizerEffect).copyWith(w: 2.0)],
              ),
              (
                label: 'width=2.0',
                apply: (e) => [
                  (e.single as EqualizerEffect).copyWith(width: 2.0),
                ],
              ),
            ],
          ),
          (
            filter: 'extrastereo',
            field: 'extrastereo_0',
            bundle: const [ExtrastereoEffect()],
            updates: <AfCommandUpdate>[
              (
                label: 'c=false',
                apply: (e) => [
                  (e.single as ExtrastereoEffect).copyWith(c: false),
                ],
              ),
              (
                label: 'm=3.5',
                apply: (e) => [
                  (e.single as ExtrastereoEffect).copyWith(m: 3.5),
                ],
              ),
            ],
          ),
          (
            filter: 'firequalizer',
            field: 'firequalizer_0',
            bundle: const [FirequalizerEffect()],
            updates: <AfCommandUpdate>[
              (
                label: 'gain=0',
                apply: (e) => [
                  (e.single as FirequalizerEffect).copyWith(gain: '0'),
                ],
              ),
            ],
          ),
          (
            filter: 'highpass',
            field: 'highpass_0',
            bundle: const [HighpassEffect()],
            updates: <AfCommandUpdate>[
              (
                label: 'f=3001.0',
                apply: (e) => [
                  (e.single as HighpassEffect).copyWith(f: 3001.0),
                ],
              ),
              (
                label: 'frequency=3001.0',
                apply: (e) => [
                  (e.single as HighpassEffect).copyWith(frequency: 3001.0),
                ],
              ),
              (
                label: 'm=0.5',
                apply: (e) => [(e.single as HighpassEffect).copyWith(m: 0.5)],
              ),
              (
                label: 'mix=0.5',
                apply: (e) => [(e.single as HighpassEffect).copyWith(mix: 0.5)],
              ),
              (
                label: 'n=true',
                apply: (e) => [(e.single as HighpassEffect).copyWith(n: true)],
              ),
              (
                label: 'normalize=true',
                apply: (e) => [
                  (e.single as HighpassEffect).copyWith(normalize: true),
                ],
              ),
              (
                label: 'w=1.707',
                apply: (e) => [(e.single as HighpassEffect).copyWith(w: 1.707)],
              ),
              (
                label: 'width=1.707',
                apply: (e) => [
                  (e.single as HighpassEffect).copyWith(width: 1.707),
                ],
              ),
            ],
          ),
          (
            filter: 'highshelf',
            field: 'highshelf_0',
            bundle: const [HighshelfEffect()],
            updates: <AfCommandUpdate>[
              (
                label: 'f=3001.0',
                apply: (e) => [
                  (e.single as HighshelfEffect).copyWith(f: 3001.0),
                ],
              ),
              (
                label: 'frequency=3001.0',
                apply: (e) => [
                  (e.single as HighshelfEffect).copyWith(frequency: 3001.0),
                ],
              ),
              (
                label: 'g=1.0',
                apply: (e) => [(e.single as HighshelfEffect).copyWith(g: 1.0)],
              ),
              (
                label: 'gain=1.0',
                apply: (e) => [
                  (e.single as HighshelfEffect).copyWith(gain: 1.0),
                ],
              ),
              (
                label: 'm=0.5',
                apply: (e) => [(e.single as HighshelfEffect).copyWith(m: 0.5)],
              ),
              (
                label: 'mix=0.5',
                apply: (e) => [
                  (e.single as HighshelfEffect).copyWith(mix: 0.5),
                ],
              ),
              (
                label: 'n=true',
                apply: (e) => [(e.single as HighshelfEffect).copyWith(n: true)],
              ),
              (
                label: 'normalize=true',
                apply: (e) => [
                  (e.single as HighshelfEffect).copyWith(normalize: true),
                ],
              ),
              (
                label: 'w=1.5',
                apply: (e) => [(e.single as HighshelfEffect).copyWith(w: 1.5)],
              ),
              (
                label: 'width=1.5',
                apply: (e) => [
                  (e.single as HighshelfEffect).copyWith(width: 1.5),
                ],
              ),
            ],
          ),
          (
            filter: 'lowpass',
            field: 'lowpass_0',
            bundle: const [LowpassEffect()],
            updates: <AfCommandUpdate>[
              (
                label: 'f=501.0',
                apply: (e) => [(e.single as LowpassEffect).copyWith(f: 501.0)],
              ),
              (
                label: 'frequency=501.0',
                apply: (e) => [
                  (e.single as LowpassEffect).copyWith(frequency: 501.0),
                ],
              ),
              (
                label: 'm=0.5',
                apply: (e) => [(e.single as LowpassEffect).copyWith(m: 0.5)],
              ),
              (
                label: 'mix=0.5',
                apply: (e) => [(e.single as LowpassEffect).copyWith(mix: 0.5)],
              ),
              (
                label: 'n=true',
                apply: (e) => [(e.single as LowpassEffect).copyWith(n: true)],
              ),
              (
                label: 'normalize=true',
                apply: (e) => [
                  (e.single as LowpassEffect).copyWith(normalize: true),
                ],
              ),
              (
                label: 'w=1.707',
                apply: (e) => [(e.single as LowpassEffect).copyWith(w: 1.707)],
              ),
              (
                label: 'width=1.707',
                apply: (e) => [
                  (e.single as LowpassEffect).copyWith(width: 1.707),
                ],
              ),
            ],
          ),
          (
            filter: 'lowshelf',
            field: 'lowshelf_0',
            bundle: const [LowshelfEffect()],
            updates: <AfCommandUpdate>[
              (
                label: 'f=101.0',
                apply: (e) => [(e.single as LowshelfEffect).copyWith(f: 101.0)],
              ),
              (
                label: 'frequency=101.0',
                apply: (e) => [
                  (e.single as LowshelfEffect).copyWith(frequency: 101.0),
                ],
              ),
              (
                label: 'g=1.0',
                apply: (e) => [(e.single as LowshelfEffect).copyWith(g: 1.0)],
              ),
              (
                label: 'gain=1.0',
                apply: (e) => [
                  (e.single as LowshelfEffect).copyWith(gain: 1.0),
                ],
              ),
              (
                label: 'm=0.5',
                apply: (e) => [(e.single as LowshelfEffect).copyWith(m: 0.5)],
              ),
              (
                label: 'mix=0.5',
                apply: (e) => [(e.single as LowshelfEffect).copyWith(mix: 0.5)],
              ),
              (
                label: 'n=true',
                apply: (e) => [(e.single as LowshelfEffect).copyWith(n: true)],
              ),
              (
                label: 'normalize=true',
                apply: (e) => [
                  (e.single as LowshelfEffect).copyWith(normalize: true),
                ],
              ),
              (
                label: 'w=1.5',
                apply: (e) => [(e.single as LowshelfEffect).copyWith(w: 1.5)],
              ),
              (
                label: 'width=1.5',
                apply: (e) => [
                  (e.single as LowshelfEffect).copyWith(width: 1.5),
                ],
              ),
            ],
          ),
          (
            filter: 'rubberband',
            field: 'rubberband_0',
            bundle: const [RubberbandEffect()],
            updates: <AfCommandUpdate>[
              (
                label: 'pitch=2.0',
                apply: (e) => [
                  (e.single as RubberbandEffect).copyWith(pitch: 2.0),
                ],
              ),
              (
                label: 'tempo=2.0',
                apply: (e) => [
                  (e.single as RubberbandEffect).copyWith(tempo: 2.0),
                ],
              ),
            ],
          ),
          (
            filter: 'silenceremove',
            field: 'silenceremove_0',
            bundle: const [SilenceremoveEffect()],
            updates: <AfCommandUpdate>[
              (
                label: 'startThreshold=1.0',
                apply: (e) => [
                  (e.single as SilenceremoveEffect).copyWith(
                    startThreshold: 1.0,
                  ),
                ],
              ),
              (
                label: 'stopThreshold=1.0',
                apply: (e) => [
                  (e.single as SilenceremoveEffect).copyWith(
                    stopThreshold: 1.0,
                  ),
                ],
              ),
            ],
          ),
          (
            filter: 'speechnorm',
            field: 'speechnorm_0',
            bundle: const [SpeechnormEffect()],
            updates: <AfCommandUpdate>[
              (
                label: 'c=3.0',
                apply: (e) => [(e.single as SpeechnormEffect).copyWith(c: 3.0)],
              ),
              (
                label: 'compression=3.0',
                apply: (e) => [
                  (e.single as SpeechnormEffect).copyWith(compression: 3.0),
                ],
              ),
              (
                label: 'e=3.0',
                apply: (e) => [(e.single as SpeechnormEffect).copyWith(e: 3.0)],
              ),
              (
                label: 'expansion=3.0',
                apply: (e) => [
                  (e.single as SpeechnormEffect).copyWith(expansion: 3.0),
                ],
              ),
              (
                label: 'f=0.5005',
                apply: (e) => [
                  (e.single as SpeechnormEffect).copyWith(f: 0.5005),
                ],
              ),
              (
                label: 'fall=0.5005',
                apply: (e) => [
                  (e.single as SpeechnormEffect).copyWith(fall: 0.5005),
                ],
              ),
              (
                label: 'i=true',
                apply: (e) => [
                  (e.single as SpeechnormEffect).copyWith(i: true),
                ],
              ),
              (
                label: 'invert=true',
                apply: (e) => [
                  (e.single as SpeechnormEffect).copyWith(invert: true),
                ],
              ),
              (
                label: 'l=true',
                apply: (e) => [
                  (e.single as SpeechnormEffect).copyWith(l: true),
                ],
              ),
              (
                label: 'link=true',
                apply: (e) => [
                  (e.single as SpeechnormEffect).copyWith(link: true),
                ],
              ),
              (
                label: 'm=0.5',
                apply: (e) => [(e.single as SpeechnormEffect).copyWith(m: 0.5)],
              ),
              (
                label: 'p=0.975',
                apply: (e) => [
                  (e.single as SpeechnormEffect).copyWith(p: 0.975),
                ],
              ),
              (
                label: 'peak=0.975',
                apply: (e) => [
                  (e.single as SpeechnormEffect).copyWith(peak: 0.975),
                ],
              ),
              (
                label: 'r=0.5005',
                apply: (e) => [
                  (e.single as SpeechnormEffect).copyWith(r: 0.5005),
                ],
              ),
              (
                label: 'raise=0.5005',
                apply: (e) => [
                  (e.single as SpeechnormEffect).copyWith(raise: 0.5005),
                ],
              ),
              (
                label: 'rms=0.5',
                apply: (e) => [
                  (e.single as SpeechnormEffect).copyWith(rms: 0.5),
                ],
              ),
              (
                label: 't=0.5',
                apply: (e) => [(e.single as SpeechnormEffect).copyWith(t: 0.5)],
              ),
              (
                label: 'threshold=0.5',
                apply: (e) => [
                  (e.single as SpeechnormEffect).copyWith(threshold: 0.5),
                ],
              ),
            ],
          ),
          (
            filter: 'stereotools',
            field: 'stereotools_0',
            bundle: const [StereotoolsEffect()],
            updates: <AfCommandUpdate>[
              (
                label: 'balanceIn=0.5',
                apply: (e) => [
                  (e.single as StereotoolsEffect).copyWith(balanceIn: 0.5),
                ],
              ),
              (
                label: 'balanceOut=0.5',
                apply: (e) => [
                  (e.single as StereotoolsEffect).copyWith(balanceOut: 0.5),
                ],
              ),
              (
                label: 'base=0.5',
                apply: (e) => [
                  (e.single as StereotoolsEffect).copyWith(base: 0.5),
                ],
              ),
              (
                label: 'delay=1.0',
                apply: (e) => [
                  (e.single as StereotoolsEffect).copyWith(delay: 1.0),
                ],
              ),
              (
                label: 'levelIn=2.0',
                apply: (e) => [
                  (e.single as StereotoolsEffect).copyWith(levelIn: 2.0),
                ],
              ),
              (
                label: 'levelOut=2.0',
                apply: (e) => [
                  (e.single as StereotoolsEffect).copyWith(levelOut: 2.0),
                ],
              ),
              (
                label: 'mlev=2.0',
                apply: (e) => [
                  (e.single as StereotoolsEffect).copyWith(mlev: 2.0),
                ],
              ),
              (
                label: 'mpan=0.5',
                apply: (e) => [
                  (e.single as StereotoolsEffect).copyWith(mpan: 0.5),
                ],
              ),
              (
                label: 'mutel=true',
                apply: (e) => [
                  (e.single as StereotoolsEffect).copyWith(mutel: true),
                ],
              ),
              (
                label: 'muter=true',
                apply: (e) => [
                  (e.single as StereotoolsEffect).copyWith(muter: true),
                ],
              ),
              (
                label: 'phase=1.0',
                apply: (e) => [
                  (e.single as StereotoolsEffect).copyWith(phase: 1.0),
                ],
              ),
              (
                label: 'phasel=true',
                apply: (e) => [
                  (e.single as StereotoolsEffect).copyWith(phasel: true),
                ],
              ),
              (
                label: 'phaser=true',
                apply: (e) => [
                  (e.single as StereotoolsEffect).copyWith(phaser: true),
                ],
              ),
              (
                label: 'sbal=0.5',
                apply: (e) => [
                  (e.single as StereotoolsEffect).copyWith(sbal: 0.5),
                ],
              ),
              (
                label: 'sclevel=2.0',
                apply: (e) => [
                  (e.single as StereotoolsEffect).copyWith(sclevel: 2.0),
                ],
              ),
              (
                label: 'slev=2.0',
                apply: (e) => [
                  (e.single as StereotoolsEffect).copyWith(slev: 2.0),
                ],
              ),
              (
                label: 'softclip=true',
                apply: (e) => [
                  (e.single as StereotoolsEffect).copyWith(softclip: true),
                ],
              ),
            ],
          ),
          (
            filter: 'stereowiden',
            field: 'stereowiden_0',
            bundle: const [StereowidenEffect()],
            updates: <AfCommandUpdate>[
              (
                label: 'crossfeed=0.55',
                apply: (e) => [
                  (e.single as StereowidenEffect).copyWith(crossfeed: 0.55),
                ],
              ),
              (
                label: 'drymix=0.9',
                apply: (e) => [
                  (e.single as StereowidenEffect).copyWith(drymix: 0.9),
                ],
              ),
              (
                label: 'feedback=0.6',
                apply: (e) => [
                  (e.single as StereowidenEffect).copyWith(feedback: 0.6),
                ],
              ),
            ],
          ),
          (
            filter: 'surround',
            field: 'surround_0',
            bundle: const [SurroundEffect()],
            updates: <AfCommandUpdate>[
              (
                label: 'allx=0.0',
                apply: (e) => [
                  (e.single as SurroundEffect).copyWith(allx: 0.0),
                ],
              ),
              (
                label: 'ally=0.0',
                apply: (e) => [
                  (e.single as SurroundEffect).copyWith(ally: 0.0),
                ],
              ),
              (
                label: 'angle=91.0',
                apply: (e) => [
                  (e.single as SurroundEffect).copyWith(angle: 91.0),
                ],
              ),
              (
                label: 'bcIn=2.0',
                apply: (e) => [
                  (e.single as SurroundEffect).copyWith(bcIn: 2.0),
                ],
              ),
              (
                label: 'bcOut=2.0',
                apply: (e) => [
                  (e.single as SurroundEffect).copyWith(bcOut: 2.0),
                ],
              ),
              (
                label: 'bcx=1.5',
                apply: (e) => [(e.single as SurroundEffect).copyWith(bcx: 1.5)],
              ),
              (
                label: 'bcy=1.5',
                apply: (e) => [(e.single as SurroundEffect).copyWith(bcy: 1.5)],
              ),
              (
                label: 'blIn=2.0',
                apply: (e) => [
                  (e.single as SurroundEffect).copyWith(blIn: 2.0),
                ],
              ),
              (
                label: 'blOut=2.0',
                apply: (e) => [
                  (e.single as SurroundEffect).copyWith(blOut: 2.0),
                ],
              ),
              (
                label: 'blx=1.5',
                apply: (e) => [(e.single as SurroundEffect).copyWith(blx: 1.5)],
              ),
              (
                label: 'bly=1.5',
                apply: (e) => [(e.single as SurroundEffect).copyWith(bly: 1.5)],
              ),
              (
                label: 'brIn=2.0',
                apply: (e) => [
                  (e.single as SurroundEffect).copyWith(brIn: 2.0),
                ],
              ),
              (
                label: 'brOut=2.0',
                apply: (e) => [
                  (e.single as SurroundEffect).copyWith(brOut: 2.0),
                ],
              ),
              (
                label: 'brx=1.5',
                apply: (e) => [(e.single as SurroundEffect).copyWith(brx: 1.5)],
              ),
              (
                label: 'bry=1.5',
                apply: (e) => [(e.single as SurroundEffect).copyWith(bry: 1.5)],
              ),
              (
                label: 'fcIn=2.0',
                apply: (e) => [
                  (e.single as SurroundEffect).copyWith(fcIn: 2.0),
                ],
              ),
              (
                label: 'fcOut=2.0',
                apply: (e) => [
                  (e.single as SurroundEffect).copyWith(fcOut: 2.0),
                ],
              ),
              (
                label: 'fcx=1.5',
                apply: (e) => [(e.single as SurroundEffect).copyWith(fcx: 1.5)],
              ),
              (
                label: 'fcy=1.5',
                apply: (e) => [(e.single as SurroundEffect).copyWith(fcy: 1.5)],
              ),
              (
                label: 'flIn=2.0',
                apply: (e) => [
                  (e.single as SurroundEffect).copyWith(flIn: 2.0),
                ],
              ),
              (
                label: 'flOut=2.0',
                apply: (e) => [
                  (e.single as SurroundEffect).copyWith(flOut: 2.0),
                ],
              ),
              (
                label: 'flx=1.5',
                apply: (e) => [(e.single as SurroundEffect).copyWith(flx: 1.5)],
              ),
              (
                label: 'fly=1.5',
                apply: (e) => [(e.single as SurroundEffect).copyWith(fly: 1.5)],
              ),
              (
                label: 'focus=0.5',
                apply: (e) => [
                  (e.single as SurroundEffect).copyWith(focus: 0.5),
                ],
              ),
              (
                label: 'frIn=2.0',
                apply: (e) => [
                  (e.single as SurroundEffect).copyWith(frIn: 2.0),
                ],
              ),
              (
                label: 'frOut=2.0',
                apply: (e) => [
                  (e.single as SurroundEffect).copyWith(frOut: 2.0),
                ],
              ),
              (
                label: 'frx=1.5',
                apply: (e) => [(e.single as SurroundEffect).copyWith(frx: 1.5)],
              ),
              (
                label: 'fry=1.5',
                apply: (e) => [(e.single as SurroundEffect).copyWith(fry: 1.5)],
              ),
              (
                label: 'levelIn=2.0',
                apply: (e) => [
                  (e.single as SurroundEffect).copyWith(levelIn: 2.0),
                ],
              ),
              (
                label: 'levelOut=2.0',
                apply: (e) => [
                  (e.single as SurroundEffect).copyWith(levelOut: 2.0),
                ],
              ),
              (
                label: 'lfe=false',
                apply: (e) => [
                  (e.single as SurroundEffect).copyWith(lfe: false),
                ],
              ),
              (
                label: 'lfeIn=2.0',
                apply: (e) => [
                  (e.single as SurroundEffect).copyWith(lfeIn: 2.0),
                ],
              ),
              (
                label: 'lfeOut=2.0',
                apply: (e) => [
                  (e.single as SurroundEffect).copyWith(lfeOut: 2.0),
                ],
              ),
              (
                label: 'overlap=0.75',
                apply: (e) => [
                  (e.single as SurroundEffect).copyWith(overlap: 0.75),
                ],
              ),
              (
                label: 'slIn=2.0',
                apply: (e) => [
                  (e.single as SurroundEffect).copyWith(slIn: 2.0),
                ],
              ),
              (
                label: 'slOut=2.0',
                apply: (e) => [
                  (e.single as SurroundEffect).copyWith(slOut: 2.0),
                ],
              ),
              (
                label: 'slx=1.5',
                apply: (e) => [(e.single as SurroundEffect).copyWith(slx: 1.5)],
              ),
              (
                label: 'sly=1.5',
                apply: (e) => [(e.single as SurroundEffect).copyWith(sly: 1.5)],
              ),
              (
                label: 'smooth=0.5',
                apply: (e) => [
                  (e.single as SurroundEffect).copyWith(smooth: 0.5),
                ],
              ),
              (
                label: 'srIn=2.0',
                apply: (e) => [
                  (e.single as SurroundEffect).copyWith(srIn: 2.0),
                ],
              ),
              (
                label: 'srOut=2.0',
                apply: (e) => [
                  (e.single as SurroundEffect).copyWith(srOut: 2.0),
                ],
              ),
              (
                label: 'srx=1.5',
                apply: (e) => [(e.single as SurroundEffect).copyWith(srx: 1.5)],
              ),
              (
                label: 'sry=1.5',
                apply: (e) => [(e.single as SurroundEffect).copyWith(sry: 1.5)],
              ),
            ],
          ),
          (
            filter: 'tiltshelf',
            field: 'tiltshelf_0',
            bundle: const [TiltshelfEffect()],
            updates: <AfCommandUpdate>[
              (
                label: 'f=3001.0',
                apply: (e) => [
                  (e.single as TiltshelfEffect).copyWith(f: 3001.0),
                ],
              ),
              (
                label: 'frequency=3001.0',
                apply: (e) => [
                  (e.single as TiltshelfEffect).copyWith(frequency: 3001.0),
                ],
              ),
              (
                label: 'g=1.0',
                apply: (e) => [(e.single as TiltshelfEffect).copyWith(g: 1.0)],
              ),
              (
                label: 'gain=1.0',
                apply: (e) => [
                  (e.single as TiltshelfEffect).copyWith(gain: 1.0),
                ],
              ),
              (
                label: 'm=0.5',
                apply: (e) => [(e.single as TiltshelfEffect).copyWith(m: 0.5)],
              ),
              (
                label: 'mix=0.5',
                apply: (e) => [
                  (e.single as TiltshelfEffect).copyWith(mix: 0.5),
                ],
              ),
              (
                label: 'n=true',
                apply: (e) => [(e.single as TiltshelfEffect).copyWith(n: true)],
              ),
              (
                label: 'normalize=true',
                apply: (e) => [
                  (e.single as TiltshelfEffect).copyWith(normalize: true),
                ],
              ),
              (
                label: 'w=1.5',
                apply: (e) => [(e.single as TiltshelfEffect).copyWith(w: 1.5)],
              ),
              (
                label: 'width=1.5',
                apply: (e) => [
                  (e.single as TiltshelfEffect).copyWith(width: 1.5),
                ],
              ),
            ],
          ),
          (
            filter: 'treble',
            field: 'treble_0',
            bundle: const [TrebleEffect()],
            updates: <AfCommandUpdate>[
              (
                label: 'f=3001.0',
                apply: (e) => [(e.single as TrebleEffect).copyWith(f: 3001.0)],
              ),
              (
                label: 'frequency=3001.0',
                apply: (e) => [
                  (e.single as TrebleEffect).copyWith(frequency: 3001.0),
                ],
              ),
              (
                label: 'g=1.0',
                apply: (e) => [(e.single as TrebleEffect).copyWith(g: 1.0)],
              ),
              (
                label: 'gain=1.0',
                apply: (e) => [(e.single as TrebleEffect).copyWith(gain: 1.0)],
              ),
              (
                label: 'm=0.5',
                apply: (e) => [(e.single as TrebleEffect).copyWith(m: 0.5)],
              ),
              (
                label: 'mix=0.5',
                apply: (e) => [(e.single as TrebleEffect).copyWith(mix: 0.5)],
              ),
              (
                label: 'n=true',
                apply: (e) => [(e.single as TrebleEffect).copyWith(n: true)],
              ),
              (
                label: 'normalize=true',
                apply: (e) => [
                  (e.single as TrebleEffect).copyWith(normalize: true),
                ],
              ),
              (
                label: 'w=1.5',
                apply: (e) => [(e.single as TrebleEffect).copyWith(w: 1.5)],
              ),
              (
                label: 'width=1.5',
                apply: (e) => [(e.single as TrebleEffect).copyWith(width: 1.5)],
              ),
            ],
          ),
          (
            filter: 'virtualbass',
            field: 'virtualbass_0',
            bundle: const [VirtualbassEffect()],
            updates: <AfCommandUpdate>[
              (
                label: 'strength=2.0',
                apply: (e) => [
                  (e.single as VirtualbassEffect).copyWith(strength: 2.0),
                ],
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
        await player.setAudioEffects(const []);
      },
      timeout: const Timeout(Duration(minutes: 4)),
    );
  });
}
