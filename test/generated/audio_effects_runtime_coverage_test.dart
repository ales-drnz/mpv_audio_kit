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

import '../_helpers/libmpv_resolver.dart';
import '../_helpers/mpv_error_capture.dart';

typedef RuntimeCase = ({String filter, AudioEffects bundle});

const List<RuntimeCase> _kRuntimeCases = [
  (
    filter: 'acompressor',
    bundle: const AudioEffects(acompressor: AcompressorSettings(enabled: true)),
  ),
  (
    filter: 'acontrast',
    bundle: const AudioEffects(acontrast: AcontrastSettings(enabled: true)),
  ),
  (
    filter: 'acrusher',
    bundle: const AudioEffects(acrusher: AcrusherSettings(enabled: true)),
  ),
  (
    filter: 'adeclick',
    bundle: const AudioEffects(adeclick: AdeclickSettings(enabled: true)),
  ),
  (
    filter: 'adeclip',
    bundle: const AudioEffects(adeclip: AdeclipSettings(enabled: true)),
  ),
  (
    filter: 'adecorrelate',
    bundle: const AudioEffects(
      adecorrelate: AdecorrelateSettings(enabled: true),
    ),
  ),
  (
    filter: 'adelay',
    bundle: const AudioEffects(adelay: AdelaySettings(enabled: true)),
  ),
  (
    filter: 'adenorm',
    bundle: const AudioEffects(adenorm: AdenormSettings(enabled: true)),
  ),
  (
    filter: 'aderivative',
    bundle: const AudioEffects(aderivative: AderivativeSettings(enabled: true)),
  ),
  (
    filter: 'adrc',
    bundle: const AudioEffects(adrc: AdrcSettings(enabled: true)),
  ),
  (
    filter: 'adynamicequalizer',
    bundle: const AudioEffects(
      adynamicequalizer: AdynamicequalizerSettings(enabled: true),
    ),
  ),
  (
    filter: 'adynamicsmooth',
    bundle: const AudioEffects(
      adynamicsmooth: AdynamicsmoothSettings(enabled: true),
    ),
  ),
  (
    filter: 'aecho',
    bundle: const AudioEffects(aecho: AechoSettings(enabled: true)),
  ),
  (
    filter: 'aemphasis',
    bundle: const AudioEffects(aemphasis: AemphasisSettings(enabled: true)),
  ),
  (
    filter: 'aeval',
    bundle: const AudioEffects(
      aeval: AevalSettings(enabled: true, exprs: 'val(0)|val(1)'),
    ),
  ),
  (
    filter: 'aexciter',
    bundle: const AudioEffects(aexciter: AexciterSettings(enabled: true)),
  ),
  (
    filter: 'afade',
    bundle: const AudioEffects(afade: AfadeSettings(enabled: true)),
  ),
  (
    filter: 'afftdn',
    bundle: const AudioEffects(afftdn: AfftdnSettings(enabled: true)),
  ),
  (
    filter: 'afftfilt',
    bundle: const AudioEffects(afftfilt: AfftfiltSettings(enabled: true)),
  ),
  (
    filter: 'aformat',
    bundle: const AudioEffects(aformat: AformatSettings(enabled: true)),
  ),
  (
    filter: 'afreqshift',
    bundle: const AudioEffects(afreqshift: AfreqshiftSettings(enabled: true)),
  ),
  (
    filter: 'afwtdn',
    bundle: const AudioEffects(afwtdn: AfwtdnSettings(enabled: true)),
  ),
  (
    filter: 'agate',
    bundle: const AudioEffects(agate: AgateSettings(enabled: true)),
  ),
  (
    filter: 'aiir',
    bundle: const AudioEffects(aiir: AiirSettings(enabled: true)),
  ),
  (
    filter: 'aintegral',
    bundle: const AudioEffects(aintegral: AintegralSettings(enabled: true)),
  ),
  (
    filter: 'alimiter',
    bundle: const AudioEffects(alimiter: AlimiterSettings(enabled: true)),
  ),
  (
    filter: 'allpass',
    bundle: const AudioEffects(allpass: AllpassSettings(enabled: true)),
  ),
  (
    filter: 'anequalizer',
    bundle: const AudioEffects(anequalizer: AnequalizerSettings(enabled: true)),
  ),
  (
    filter: 'anlmdn',
    bundle: const AudioEffects(anlmdn: AnlmdnSettings(enabled: true)),
  ),
  (
    filter: 'apad',
    bundle: const AudioEffects(apad: ApadSettings(enabled: true)),
  ),
  (
    filter: 'aphaser',
    bundle: const AudioEffects(aphaser: AphaserSettings(enabled: true)),
  ),
  (
    filter: 'aphaseshift',
    bundle: const AudioEffects(aphaseshift: AphaseshiftSettings(enabled: true)),
  ),
  (
    filter: 'apsyclip',
    bundle: const AudioEffects(apsyclip: ApsyclipSettings(enabled: true)),
  ),
  (
    filter: 'apulsator',
    bundle: const AudioEffects(apulsator: ApulsatorSettings(enabled: true)),
  ),
  (
    filter: 'aresample',
    bundle: const AudioEffects(aresample: AresampleSettings(enabled: true)),
  ),
  (
    filter: 'asetrate',
    bundle: const AudioEffects(asetrate: AsetrateSettings(enabled: true)),
  ),
  (
    filter: 'asoftclip',
    bundle: const AudioEffects(asoftclip: AsoftclipSettings(enabled: true)),
  ),
  (
    filter: 'asubboost',
    bundle: const AudioEffects(asubboost: AsubboostSettings(enabled: true)),
  ),
  (
    filter: 'asubcut',
    bundle: const AudioEffects(asubcut: AsubcutSettings(enabled: true)),
  ),
  (
    filter: 'asupercut',
    bundle: const AudioEffects(asupercut: AsupercutSettings(enabled: true)),
  ),
  (
    filter: 'asuperpass',
    bundle: const AudioEffects(asuperpass: AsuperpassSettings(enabled: true)),
  ),
  (
    filter: 'asuperstop',
    bundle: const AudioEffects(asuperstop: AsuperstopSettings(enabled: true)),
  ),
  (
    filter: 'atempo',
    bundle: const AudioEffects(atempo: AtempoSettings(enabled: true)),
  ),
  (
    filter: 'atilt',
    bundle: const AudioEffects(atilt: AtiltSettings(enabled: true)),
  ),
  (
    filter: 'bandpass',
    bundle: const AudioEffects(bandpass: BandpassSettings(enabled: true)),
  ),
  (
    filter: 'bandreject',
    bundle: const AudioEffects(bandreject: BandrejectSettings(enabled: true)),
  ),
  (
    filter: 'bass',
    bundle: const AudioEffects(bass: BassSettings(enabled: true)),
  ),
  (
    filter: 'biquad',
    bundle: const AudioEffects(biquad: BiquadSettings(enabled: true)),
  ),
  (
    filter: 'channelmap',
    bundle: const AudioEffects(
      channelmap: ChannelmapSettings(enabled: true, map: '0|1'),
    ),
  ),
  (
    filter: 'chorus',
    bundle: const AudioEffects(
      chorus: ChorusSettings(
        enabled: true,
        delays: '55|60',
        decays: '0.4|0.32',
        speeds: '0.25|0.4',
        depths: '2|1.3',
      ),
    ),
  ),
  (
    filter: 'compand',
    bundle: const AudioEffects(compand: CompandSettings(enabled: true)),
  ),
  (
    filter: 'compensationdelay',
    bundle: const AudioEffects(
      compensationdelay: CompensationdelaySettings(enabled: true),
    ),
  ),
  (
    filter: 'crossfeed',
    bundle: const AudioEffects(crossfeed: CrossfeedSettings(enabled: true)),
  ),
  (
    filter: 'crystalizer',
    bundle: const AudioEffects(crystalizer: CrystalizerSettings(enabled: true)),
  ),
  (
    filter: 'dcshift',
    bundle: const AudioEffects(dcshift: DcshiftSettings(enabled: true)),
  ),
  (
    filter: 'deesser',
    bundle: const AudioEffects(deesser: DeesserSettings(enabled: true)),
  ),
  (
    filter: 'dialoguenhance',
    bundle: const AudioEffects(
      dialoguenhance: DialoguenhanceSettings(enabled: true),
    ),
  ),
  (
    filter: 'drmeter',
    bundle: const AudioEffects(drmeter: DrmeterSettings(enabled: true)),
  ),
  (
    filter: 'dynaudnorm',
    bundle: const AudioEffects(dynaudnorm: DynaudnormSettings(enabled: true)),
  ),
  (
    filter: 'earwax',
    bundle: const AudioEffects(earwax: EarwaxSettings(enabled: true)),
  ),
  (
    filter: 'ebur128',
    bundle: const AudioEffects(ebur128: Ebur128Settings(enabled: true)),
  ),
  (
    filter: 'equalizer',
    bundle: const AudioEffects(equalizer: EqualizerSettings(enabled: true)),
  ),
  (
    filter: 'extrastereo',
    bundle: const AudioEffects(extrastereo: ExtrastereoSettings(enabled: true)),
  ),
  (
    filter: 'firequalizer',
    bundle: const AudioEffects(
      firequalizer: FirequalizerSettings(enabled: true),
    ),
  ),
  (
    filter: 'flanger',
    bundle: const AudioEffects(flanger: FlangerSettings(enabled: true)),
  ),
  (
    filter: 'haas',
    bundle: const AudioEffects(haas: HaasSettings(enabled: true)),
  ),
  (
    filter: 'hdcd',
    bundle: const AudioEffects(hdcd: HdcdSettings(enabled: true)),
  ),
  (
    filter: 'highpass',
    bundle: const AudioEffects(highpass: HighpassSettings(enabled: true)),
  ),
  (
    filter: 'highshelf',
    bundle: const AudioEffects(highshelf: HighshelfSettings(enabled: true)),
  ),
  (
    filter: 'loudnorm',
    bundle: const AudioEffects(loudnorm: LoudnormSettings(enabled: true)),
  ),
  (
    filter: 'lowpass',
    bundle: const AudioEffects(lowpass: LowpassSettings(enabled: true)),
  ),
  (
    filter: 'lowshelf',
    bundle: const AudioEffects(lowshelf: LowshelfSettings(enabled: true)),
  ),
  (
    filter: 'mcompand',
    bundle: const AudioEffects(mcompand: McompandSettings(enabled: true)),
  ),
  (
    filter: 'pan',
    bundle: const AudioEffects(
      pan: PanSettings(enabled: true, args: 'stereo|c0=c0|c1=c1'),
    ),
  ),
  (
    filter: 'rubberband',
    bundle: const AudioEffects(rubberband: RubberbandSettings(enabled: true)),
  ),
  (
    filter: 'silenceremove',
    bundle: const AudioEffects(
      silenceremove: SilenceremoveSettings(enabled: true),
    ),
  ),
  (
    filter: 'speechnorm',
    bundle: const AudioEffects(speechnorm: SpeechnormSettings(enabled: true)),
  ),
  (
    filter: 'stereotools',
    bundle: const AudioEffects(stereotools: StereotoolsSettings(enabled: true)),
  ),
  (
    filter: 'stereowiden',
    bundle: const AudioEffects(stereowiden: StereowidenSettings(enabled: true)),
  ),
  (
    filter: 'superequalizer',
    bundle: const AudioEffects(
      superequalizer: SuperequalizerSettings(enabled: true),
    ),
  ),
  (
    filter: 'surround',
    bundle: const AudioEffects(surround: SurroundSettings(enabled: true)),
  ),
  (
    filter: 'tiltshelf',
    bundle: const AudioEffects(tiltshelf: TiltshelfSettings(enabled: true)),
  ),
  (
    filter: 'treble',
    bundle: const AudioEffects(treble: TrebleSettings(enabled: true)),
  ),
  (
    filter: 'tremolo',
    bundle: const AudioEffects(tremolo: TremoloSettings(enabled: true)),
  ),
  (
    filter: 'vibrato',
    bundle: const AudioEffects(vibrato: VibratoSettings(enabled: true)),
  ),
  (
    filter: 'virtualbass',
    bundle: const AudioEffects(virtualbass: VirtualbassSettings(enabled: true)),
  ),
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

  setUpAll(() async {
    final lib = resolveLibmpv();
    if (lib == null) {
      markTestSkipped('libmpv not found');
      return;
    }
    if (!File(fixturePath).existsSync()) {
      markTestSkipped('Fixture missing: $fixturePath');
      return;
    }
    if (!File(arnndnModelPath).existsSync()) {
      markTestSkipped(
        'Fixture missing: $arnndnModelPath (run scripts/generate_filter_fixtures.sh)',
      );
      return;
    }

    MpvAudioKit.ensureInitialized(libmpv: lib, hotRestartCleanup: false);

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
        (
          filter: 'arnndn',
          bundle: AudioEffects(
            arnndn: ArnndnSettings(enabled: true, model: arnndnModelPath),
          ),
        ),
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
        await player.setAudioEffects(const AudioEffects());
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
      const s = AevalSettings(enabled: true, exprs: 'val(0)|val(1)');
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
        const s = ArnndnSettings(enabled: true, model: '');
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
      const s = ChannelmapSettings(enabled: true, map: '0|1');
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
      const s = ChorusSettings(
        enabled: true,
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
      const s = PanSettings(enabled: true, args: 'stereo|c0=c0|c1=c1');
      final wire = s.toFilterString();
      expect(
        wire,
        contains('args='),
        reason: 'pan.args is mandatory and must always be in the wire string',
      );
      expect(wire, startsWith('lavfi-pan'));
    });
  });
}
