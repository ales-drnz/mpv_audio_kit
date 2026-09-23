// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license
// that can be found in the LICENSE file.
//
// AUTO-GENERATED — do NOT edit by hand.
//
// Runtime init coverage. For every whitelisted audio filter, build
// the typed Settings with `enabled: true` (REQUIRED params filled
// from the codegen's curated SAMPLE_VALUES), apply the bundle to a
// live mpv via `setAudioEffects`, and assert mpv emits NO error /
// fatal log line — i.e. the filter actually initialises.
//
// This is the companion to the wire-shape coverage test: it catches
// filters that are wire-valid but fail at mpv init time because a
// MANDATORY ffmpeg option was left unset (e.g. `chorus()` with no
// delays/decays/speeds/depths → AVERROR(EINVAL)).

@TestOn('mac-os || linux || windows')
library;

// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, lines_longer_than_80_chars, unnecessary_const

import 'dart:io';

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

import '../_helpers/mpv_error_capture.dart';
import '../_helpers/setter_test_helpers.dart';

typedef RuntimeCase = ({String filter, List<AudioEffect> bundle});

const List<RuntimeCase> _kRuntimeCases = [
  (filter: 'acompressor', bundle: const [AcompressorEffect()]),
  (filter: 'acontrast', bundle: const [AcontrastEffect()]),
  (filter: 'acrusher', bundle: const [AcrusherEffect()]),
  (filter: 'adeclick', bundle: const [AdeclickEffect()]),
  (filter: 'adeclip', bundle: const [AdeclipEffect()]),
  (filter: 'adecorrelate', bundle: const [AdecorrelateEffect()]),
  (filter: 'adelay', bundle: const [AdelayEffect()]),
  (filter: 'adenorm', bundle: const [AdenormEffect()]),
  (filter: 'aderivative', bundle: const [AderivativeEffect()]),
  (filter: 'adrc', bundle: const [AdrcEffect()]),
  (filter: 'adynamicequalizer', bundle: const [AdynamicequalizerEffect()]),
  (filter: 'adynamicsmooth', bundle: const [AdynamicsmoothEffect()]),
  (filter: 'aecho', bundle: const [AechoEffect()]),
  (filter: 'aemphasis', bundle: const [AemphasisEffect()]),
  (filter: 'aeval', bundle: const [AevalEffect(exprs: 'val(0)|val(1)')]),
  (filter: 'aexciter', bundle: const [AexciterEffect()]),
  (filter: 'afade', bundle: const [AfadeEffect()]),
  (filter: 'afftdn', bundle: const [AfftdnEffect()]),
  (filter: 'afftfilt', bundle: const [AfftfiltEffect()]),
  (filter: 'aformat', bundle: const [AformatEffect()]),
  (filter: 'afreqshift', bundle: const [AfreqshiftEffect()]),
  (filter: 'afwtdn', bundle: const [AfwtdnEffect()]),
  (filter: 'agate', bundle: const [AgateEffect()]),
  (filter: 'aiir', bundle: const [AiirEffect()]),
  (filter: 'aintegral', bundle: const [AintegralEffect()]),
  (filter: 'alimiter', bundle: const [AlimiterEffect()]),
  (filter: 'allpass', bundle: const [AllpassEffect()]),
  (filter: 'anequalizer', bundle: const [AnequalizerEffect()]),
  (filter: 'anlmdn', bundle: const [AnlmdnEffect()]),
  (filter: 'apad', bundle: const [ApadEffect()]),
  (filter: 'aphaser', bundle: const [AphaserEffect()]),
  (filter: 'aphaseshift', bundle: const [AphaseshiftEffect()]),
  (filter: 'apsyclip', bundle: const [ApsyclipEffect()]),
  (filter: 'apulsator', bundle: const [ApulsatorEffect()]),
  (filter: 'aresample', bundle: const [AresampleEffect()]),
  (filter: 'asetrate', bundle: const [AsetrateEffect()]),
  (filter: 'asoftclip', bundle: const [AsoftclipEffect()]),
  (filter: 'asubboost', bundle: const [AsubboostEffect()]),
  (filter: 'asubcut', bundle: const [AsubcutEffect()]),
  (filter: 'asupercut', bundle: const [AsupercutEffect()]),
  (filter: 'asuperpass', bundle: const [AsuperpassEffect()]),
  (filter: 'asuperstop', bundle: const [AsuperstopEffect()]),
  (filter: 'atempo', bundle: const [AtempoEffect()]),
  (filter: 'atilt', bundle: const [AtiltEffect()]),
  (filter: 'bandpass', bundle: const [BandpassEffect()]),
  (filter: 'bandreject', bundle: const [BandrejectEffect()]),
  (filter: 'bass', bundle: const [BassEffect()]),
  (filter: 'biquad', bundle: const [BiquadEffect()]),
  (filter: 'channelmap', bundle: const [ChannelmapEffect(map: '0|1')]),
  (
    filter: 'chorus',
    bundle: const [
      ChorusEffect(
        delays: '55|60',
        decays: '0.4|0.32',
        speeds: '0.25|0.4',
        depths: '2|1.3',
      ),
    ],
  ),
  (filter: 'compand', bundle: const [CompandEffect()]),
  (filter: 'compensationdelay', bundle: const [CompensationdelayEffect()]),
  (filter: 'crossfeed', bundle: const [CrossfeedEffect()]),
  (filter: 'crystalizer', bundle: const [CrystalizerEffect()]),
  (filter: 'dcshift', bundle: const [DcshiftEffect()]),
  (filter: 'deesser', bundle: const [DeesserEffect()]),
  (filter: 'dialoguenhance', bundle: const [DialoguenhanceEffect()]),
  (filter: 'drmeter', bundle: const [DrmeterEffect()]),
  (filter: 'dynaudnorm', bundle: const [DynaudnormEffect()]),
  (filter: 'earwax', bundle: const [EarwaxEffect()]),
  (filter: 'ebur128', bundle: const [Ebur128Effect()]),
  (filter: 'equalizer', bundle: const [EqualizerEffect()]),
  (filter: 'extrastereo', bundle: const [ExtrastereoEffect()]),
  (filter: 'firequalizer', bundle: const [FirequalizerEffect()]),
  (filter: 'flanger', bundle: const [FlangerEffect()]),
  (filter: 'haas', bundle: const [HaasEffect()]),
  (filter: 'hdcd', bundle: const [HdcdEffect()]),
  (filter: 'highpass', bundle: const [HighpassEffect()]),
  (filter: 'highshelf', bundle: const [HighshelfEffect()]),
  (filter: 'loudnorm', bundle: const [LoudnormEffect()]),
  (filter: 'lowpass', bundle: const [LowpassEffect()]),
  (filter: 'lowshelf', bundle: const [LowshelfEffect()]),
  (filter: 'mcompand', bundle: const [McompandEffect()]),
  (filter: 'pan', bundle: const [PanEffect(args: 'stereo|c0=c0|c1=c1')]),
  (filter: 'rubberband', bundle: const [RubberbandEffect()]),
  (filter: 'silenceremove', bundle: const [SilenceremoveEffect()]),
  (filter: 'speechnorm', bundle: const [SpeechnormEffect()]),
  (filter: 'stereotools', bundle: const [StereotoolsEffect()]),
  (filter: 'stereowiden', bundle: const [StereowidenEffect()]),
  (filter: 'superequalizer', bundle: const [SuperequalizerEffect()]),
  (filter: 'surround', bundle: const [SurroundEffect()]),
  (filter: 'tiltshelf', bundle: const [TiltshelfEffect()]),
  (filter: 'treble', bundle: const [TrebleEffect()]),
  (filter: 'tremolo', bundle: const [TremoloEffect()]),
  (filter: 'vibrato', bundle: const [VibratoEffect()]),
  (filter: 'virtualbass', bundle: const [VirtualbassEffect()]),
];

void main() {
  final fixturePath =
      '${Directory.current.path}/test/fixtures/sine_440hz_1s.wav';
  // arnndn's required `model` is a path to a real .rnnn FILE on disk
  // (generated by scripts/generate_filter_fixtures.sh), so — unlike the
  // inline-string required params — it can't live in the const case
  // list; it's resolved here and appended to the init loop.
  final arnndnModelPath =
      '${Directory.current.path}/test/fixtures/arnndn_model.rnnn';

  late Player player;

  runtimeSuite(fixturePath: fixturePath, extraFixtures: [arnndnModelPath], () {
    setUpAll(() async {
      player = Player(
        configuration: const PlayerConfiguration(logLevel: LogLevel.error),
      );
      await player.setRawProperty('ao', 'null');
      await player.open(Media(fixturePath), play: false);
      await player.stream.seekCompleted.first.timeout(
        const Duration(seconds: 10),
      );
    });

    tearDownAll(() async {
      await player.dispose();
    });

    test(
      'every whitelisted filter initialises in mpv with required params filled',
      () async {
        // arnndn is appended here (not in the const list) because its
        // model arg is a runtime-resolved fixture path.
        final cases = <RuntimeCase>[
          ..._kRuntimeCases,
          (filter: 'arnndn', bundle: [ArnndnEffect(model: arnndnModelPath)]),
        ];
        final failures = <String, List<String>>{};
        for (final c in cases) {
          final errors = await captureMpvErrors(player, () async {
            await player.setAudioEffects(c.bundle);
          });
          if (errors.isNotEmpty) {
            failures[c.filter] = errors.map((e) => e.text.trim()).toList();
          }
          // Reset between iterations so a failure doesn't bleed forward.
          await player.setAudioEffects(const []);
        }

        if (failures.isNotEmpty) {
          final buf = StringBuffer()
            ..writeln(
              '${failures.length} of ${cases.length} filters produced mpv init errors:',
            )
            ..writeln();
          final keys = failures.keys.toList()..sort();
          for (final key in keys) {
            buf.writeln('  - $key:');
            for (final msg in failures[key]!) {
              buf.writeln('      $msg');
            }
          }
          fail(buf.toString());
        }
      },
      timeout: const Timeout(Duration(minutes: 8)),
    );

    group('required-param filters always emit their mandatory options', () {
      test('aeval wire string contains every required option', () {
        const s = AevalEffect(exprs: 'val(0)|val(1)');
        final wire = s.toFilterString();
        expect(
          wire,
          contains('exprs='),
          reason:
              'aeval.exprs is mandatory and must always be in the wire string',
        );
        expect(wire, startsWith('lavfi-aeval'));
      });
      test(
        'arnndn wire string contains every required option (also init-tested at runtime)',
        () {
          const s = ArnndnEffect(model: '');
          final wire = s.toFilterString();
          expect(
            wire,
            contains('model='),
            reason:
                'arnndn.model is mandatory and must always be in the wire string',
          );
          expect(wire, startsWith('lavfi-arnndn'));
        },
      );
      test('channelmap wire string contains every required option', () {
        const s = ChannelmapEffect(map: '0|1');
        final wire = s.toFilterString();
        expect(
          wire,
          contains('map='),
          reason:
              'channelmap.map is mandatory and must always be in the wire string',
        );
        expect(wire, startsWith('lavfi-channelmap'));
      });
      test('chorus wire string contains every required option', () {
        const s = ChorusEffect(
          delays: '55|60',
          decays: '0.4|0.32',
          speeds: '0.25|0.4',
          depths: '2|1.3',
        );
        final wire = s.toFilterString();
        expect(
          wire,
          contains('delays='),
          reason:
              'chorus.delays is mandatory and must always be in the wire string',
        );
        expect(
          wire,
          contains('decays='),
          reason:
              'chorus.decays is mandatory and must always be in the wire string',
        );
        expect(
          wire,
          contains('speeds='),
          reason:
              'chorus.speeds is mandatory and must always be in the wire string',
        );
        expect(
          wire,
          contains('depths='),
          reason:
              'chorus.depths is mandatory and must always be in the wire string',
        );
        expect(wire, startsWith('lavfi-chorus'));
      });
      test('pan wire string contains every required option', () {
        const s = PanEffect(args: 'stereo|c0=c0|c1=c1');
        final wire = s.toFilterString();
        expect(
          wire,
          contains('args='),
          reason: 'pan.args is mandatory and must always be in the wire string',
        );
        expect(wire, startsWith('lavfi-pan'));
      });
    });
  });
}
