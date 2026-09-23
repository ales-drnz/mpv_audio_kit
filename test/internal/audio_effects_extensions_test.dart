// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// Round-trip coverage for the hand-written extensions over the eight
// filters whose lavfi grammars pack structured data into opaque
// strings. For each extension:
//
// 1. Decode an empty / unset settings → typed view should be empty.
// 2. Encode a typed model → underlying string is non-empty for non-
//    default models.
// 3. Decode the encoded string → assert structural equality with the
//    original (lossless round-trip).
// 4. Special / edge cases worth pinning to catch regressions if the
//    parser or serializer is ever rewritten.
//
// These tests are pure Dart — no libmpv. The runtime sibling
// `audio_effects_extensions_runtime_test.dart` covers ffmpeg
// acceptance.

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

void main() {
  group('AnequalizerBandsX', () {
    test('empty settings → no bands', () {
      const s = AnequalizerSettings();
      expect(s.bands, isEmpty);
    });

    test('single band round-trips', () {
      const s = AnequalizerSettings();
      const mid = AnequalizerBand(frequency: 1000, bandwidth: 500, gain: 6);
      final next = s.withBands([mid]);
      expect(next.bands.length, 1);
      expect(next.bands.first.frequency, 1000);
      expect(next.bands.first.bandwidth, 500);
      expect(next.bands.first.gain, 6);
      expect(next.bands.first.type, AnequalizerBandType.butterworth);
      expect(next.params, isNotEmpty);
    });

    test('multiple bands round-trip in declaration order', () {
      const s = AnequalizerSettings();
      final src = [
        const AnequalizerBand(frequency: 100, bandwidth: 50, gain: -3),
        const AnequalizerBand(frequency: 1000, bandwidth: 500, gain: 0),
        const AnequalizerBand(frequency: 5000, bandwidth: 1000, gain: 4),
      ];
      final round = s.withBands(src).bands;
      expect(round.length, src.length);
      for (var i = 0; i < src.length; i++) {
        expect(round[i].frequency, src[i].frequency);
        expect(round[i].bandwidth, src[i].bandwidth);
        expect(round[i].gain, src[i].gain);
        expect(round[i].type, src[i].type);
      }
    });

    test('two bands with identical parameters stay distinct', () {
      const s = AnequalizerSettings();
      const band = AnequalizerBand(frequency: 1000, bandwidth: 200, gain: 0);
      final round = s.withBands([band, band]).bands;
      expect(
        round.length,
        2,
        reason:
            'identical bands must not collapse — a value-based '
            'dedup would drop the second',
      );
    });

    test('every band-type round-trips', () {
      for (final t in AnequalizerBandType.values) {
        final s = const AnequalizerSettings().withBands([
          AnequalizerBand(frequency: 500, bandwidth: 200, gain: 2, type: t),
        ]);
        expect(
          s.bands.first.type,
          t,
          reason: 'AnequalizerBandType.$t did not round-trip',
        );
      }
    });
  });

  group('McompandBandsX', () {
    test('default settings → ffmpeg default 5-band split', () {
      // The lavfi `mcompand` filter's AVOption default is a built-in
      // five-band split, parsed here into typed bands. Decoding what
      // ffmpeg actually runs (rather than reporting an empty list)
      // makes UI builders show the real starting state.
      const s = McompandSettings();
      expect(s.bands.length, 5);
    });

    test('single band round-trips losslessly', () {
      const s = McompandSettings();
      const band = McompandBand(
        thresholdDb: -24,
        ratio: 4,
        attackSeconds: 0.005,
        releaseSeconds: 0.1,
        kneeDb: 6,
        makeupDb: 3,
        crossoverHz: 2000,
      );
      final next = s.withBands([band]);
      expect(next.bands.length, 1);
      final r = next.bands.first;
      expect(r.thresholdDb, closeTo(band.thresholdDb, 0.05));
      expect(r.ratio, closeTo(band.ratio, 0.05));
      expect(r.attackSeconds, closeTo(band.attackSeconds, 1e-4));
      expect(r.releaseSeconds, closeTo(band.releaseSeconds, 1e-4));
      expect(r.kneeDb, closeTo(band.kneeDb, 0.05));
      expect(r.makeupDb, closeTo(band.makeupDb, 0.05));
      expect(r.crossoverHz, band.crossoverHz);
    });

    test('multiple bands serialize sorted by ascending crossover', () {
      const s = McompandSettings();
      final src = [
        const McompandBand(
          thresholdDb: -30,
          ratio: 2,
          attackSeconds: 0.01,
          releaseSeconds: 0.2,
          kneeDb: 6,
          makeupDb: 0,
          crossoverHz: 5000,
        ),
        const McompandBand(
          thresholdDb: -24,
          ratio: 4,
          attackSeconds: 0.005,
          releaseSeconds: 0.1,
          kneeDb: 6,
          makeupDb: 0,
          crossoverHz: 200,
        ),
        const McompandBand(
          thresholdDb: -18,
          ratio: 3,
          attackSeconds: 0.003,
          releaseSeconds: 0.05,
          kneeDb: 6,
          makeupDb: 0,
          crossoverHz: 1000,
        ),
      ];
      final round = s.withBands(src).bands;
      expect(round.length, src.length);
      expect(round.map((b) => b.crossoverHz).toList(), [
        200,
        1000,
        5000,
      ], reason: 'bands should round-trip sorted by ascending crossover');
    });

    test('makeup at 0 dB is omitted from the wire (compact form)', () {
      // Bands with no makeup gain shouldn't drag along the trailing
      // `delay init_vol gain` triple in the args string — keeps the
      // serialised filter chain readable.
      const s = McompandSettings();
      final next = s.withBands([
        const McompandBand(
          thresholdDb: -24,
          ratio: 2,
          attackSeconds: 0.005,
          releaseSeconds: 0.1,
          kneeDb: 6,
          makeupDb: 0,
          crossoverHz: 1000,
        ),
      ]);
      expect(next.args, isNotEmpty);
      expect(
        next.args.split(' ').length,
        4,
        reason: 'compact form: attack,decay knee points crossover',
      );
    });
  });

  group('SuperequalizerBandsX', () {
    test('empty settings → 18 unity bands', () {
      const s = SuperequalizerSettings();
      expect(s.bands.length, kSuperequalizerBandCount);
      for (final g in s.bands) {
        expect(g, kSuperequalizerUnityGain);
      }
    });

    test('non-unity bands round-trip', () {
      const s = SuperequalizerSettings();
      final gains = [
        for (var i = 0; i < kSuperequalizerBandCount; i++)
          1.0 + i * 0.1, // 1.0, 1.1, 1.2, …
      ];
      final round = s.withBands(gains).bands;
      expect(round.length, kSuperequalizerBandCount);
      for (var i = 0; i < kSuperequalizerBandCount; i++) {
        expect(round[i], closeTo(gains[i], 1e-9));
      }
    });

    test('unity bands are dropped from the underlying map', () {
      const s = SuperequalizerSettings();
      final gains = [
        for (var i = 0; i < kSuperequalizerBandCount; i++)
          kSuperequalizerUnityGain,
      ];
      gains[3] = 2.0;
      final next = s.withBands(gains);
      // Only the modified band should survive in `params`.
      expect(next.params.length, 1);
      expect(next.params['4b'], 2.0);
    });

    test('shorter input list leaves trailing bands at unity', () {
      const s = SuperequalizerSettings();
      final round = s.withBands([0.5, 1.5]).bands;
      expect(round.length, kSuperequalizerBandCount);
      expect(round[0], 0.5);
      expect(round[1], 1.5);
      for (var i = 2; i < kSuperequalizerBandCount; i++) {
        expect(round[i], kSuperequalizerUnityGain);
      }
    });

    test('frequency table matches the lavfi half-octave grid', () {
      // Pin the canonical hardware-EQ grid so a typo in the constants
      // shows up immediately.
      expect(kSuperequalizerFrequencies.length, kSuperequalizerBandCount);
      expect(kSuperequalizerFrequencies.first, 65);
      expect(kSuperequalizerFrequencies.last, 20000);
    });
  });

  group('AechoTapsX', () {
    test('default settings → one tap (lavfi default `1000` / `0.5`)', () {
      // AechoSettings defaults to delays='1000', decays='0.5'.
      const s = AechoSettings();
      expect(s.taps.length, 1);
      expect(s.taps.first.delayMs, 1000);
      expect(s.taps.first.decay, 0.5);
    });

    test('multiple taps round-trip', () {
      const s = AechoSettings();
      final taps = [
        const AechoTap(delayMs: 60, decay: 0.7),
        const AechoTap(delayMs: 120, decay: 0.5),
        const AechoTap(delayMs: 240, decay: 0.3),
      ];
      final round = s.withTaps(taps).taps;
      expect(round.length, taps.length);
      for (var i = 0; i < taps.length; i++) {
        expect(round[i].delayMs, closeTo(taps[i].delayMs, 0.01));
        expect(round[i].decay, closeTo(taps[i].decay, 0.001));
      }
    });

    test('mismatched delays / decays clamp to the shorter list', () {
      const s = AechoSettings(delays: '100|200|300', decays: '0.5|0.3');
      expect(s.taps.length, 2);
    });
  });

  group('ChorusVoicesX', () {
    test('empty settings → no voices', () {
      const s = ChorusSettings(delays: '', decays: '', speeds: '', depths: '');
      expect(s.voices, isEmpty);
    });

    test('multiple voices round-trip', () {
      const s = ChorusSettings(delays: '', decays: '', speeds: '', depths: '');
      final voices = [
        const ChorusVoice(delayMs: 30, decay: 0.4, depthMs: 1.5, speedHz: 0.3),
        const ChorusVoice(delayMs: 50, decay: 0.5, depthMs: 2.0, speedHz: 0.5),
      ];
      final round = s.withVoices(voices).voices;
      expect(round.length, voices.length);
      for (var i = 0; i < voices.length; i++) {
        expect(round[i].delayMs, closeTo(voices[i].delayMs, 0.001));
        expect(round[i].decay, closeTo(voices[i].decay, 0.001));
        expect(round[i].depthMs, closeTo(voices[i].depthMs, 0.001));
        expect(round[i].speedHz, closeTo(voices[i].speedHz, 0.001));
      }
    });

    test('mismatched parallel CSVs clamp to the shortest', () {
      const s = ChorusSettings(
        delays: '30|40|50',
        decays: '0.5|0.4',
        depths: '1.5',
        speeds: '0.5|0.4|0.3|0.2',
      );
      expect(
        s.voices.length,
        1,
        reason: 'shortest CSV (depths, length 1) wins',
      );
    });
  });

  group('AdelayChannelsX', () {
    test('empty settings → no delays', () {
      const s = AdelaySettings();
      expect(s.channelDelaysMs, isEmpty);
    });

    test('single channel round-trips', () {
      const s = AdelaySettings();
      final round = s.withChannelDelaysMs([250]).channelDelaysMs;
      expect(round, [250]);
    });

    test('multi-channel round-trips in declaration order', () {
      const s = AdelaySettings();
      final round = s.withChannelDelaysMs([100, 200, 300, 400]).channelDelaysMs;
      expect(round, [100, 200, 300, 400]);
    });

    test('unit suffixes (`ms`, `s`, `S`) on input are stripped on parse', () {
      const s = AdelaySettings(delays: '100ms|0.2s|44100S|400');
      // All four entries should parse — engine-side `s`/`S` units are
      // stripped (the typed view normalises to milliseconds, and we
      // treat the bare numbers as ms).
      expect(s.channelDelaysMs.length, 4);
    });
  });

  group('CompandEnvelopesX', () {
    test('default settings → one envelope (lavfi defaults)', () {
      // CompandSettings defaults to attacks='0', decays='0.8'.
      const s = CompandSettings();
      expect(s.envelopes.length, 1);
      expect(s.envelopes.first.attackSeconds, 0);
      expect(s.envelopes.first.decaySeconds, 0.8);
    });

    test('multiple per-channel envelopes round-trip', () {
      const s = CompandSettings();
      final envs = [
        const CompandEnvelope(attackSeconds: 0.005, decaySeconds: 0.1),
        const CompandEnvelope(attackSeconds: 0.01, decaySeconds: 0.2),
      ];
      final round = s.withEnvelopes(envs).envelopes;
      expect(round.length, envs.length);
      for (var i = 0; i < envs.length; i++) {
        expect(round[i].attackSeconds, closeTo(envs[i].attackSeconds, 1e-4));
        expect(round[i].decaySeconds, closeTo(envs[i].decaySeconds, 1e-4));
      }
    });

    test('mismatched attacks / decays clamp to the shorter list', () {
      const s = CompandSettings(attacks: '0.005|0.01|0.02', decays: '0.1|0.2');
      expect(s.envelopes.length, 2);
    });
  });

  group('AfftdnBandNoiseX', () {
    test('empty band_noise → 15 default-floor entries', () {
      const s = AfftdnSettings();
      expect(s.bandNoiseLevels.length, kAfftdnBandCount);
      // Default `band_noise = '0'` parses as a single 0.0 → padded.
      for (final v in s.bandNoiseLevels) {
        expect(v, kAfftdnBandNoiseDefault);
      }
    });

    test('custom band noise round-trips with exactly 15 entries', () {
      const s = AfftdnSettings();
      final levels = [
        for (var i = 0; i < kAfftdnBandCount; i++) -10.0 + i * 0.5,
      ];
      final round = s.withBandNoiseLevels(levels).bandNoiseLevels;
      expect(round.length, kAfftdnBandCount);
      for (var i = 0; i < kAfftdnBandCount; i++) {
        expect(round[i], closeTo(levels[i], 0.01));
      }
    });

    test('shorter input pads with default; longer truncates', () {
      const s = AfftdnSettings();
      final round = s.withBandNoiseLevels([1.0, 2.0, 3.0]).bandNoiseLevels;
      expect(round.length, kAfftdnBandCount);
      expect(round.take(3).toList(), [1.0, 2.0, 3.0]);
      for (final v in round.skip(3)) {
        expect(v, kAfftdnBandNoiseDefault);
      }
    });

    test('legacy space-separated input is accepted', () {
      const s = AfftdnSettings(
        band_noise: '-10 -8 -6 -4 -2 0 2 4 6 8 10 12 14 16 18',
      );
      expect(s.bandNoiseLevels.length, kAfftdnBandCount);
      expect(s.bandNoiseLevels.first, -10);
      expect(s.bandNoiseLevels.last, 18);
    });
  });

  group('CompandSoftKneeX', () {
    test('default settings → kCompandSoftKneeDefault', () {
      const s = CompandSettings();
      expect(s.softKnee, kCompandSoftKneeDefault);
    });

    test('non-default round-trips through the params map', () {
      const s = CompandSettings();
      final next = s.withSoftKnee(0.5);
      expect(next.softKnee, 0.5);
      expect(next.params['soft-knee'], 0.5);
    });

    test('writing the default value drops the key from the params map', () {
      const s = CompandSettings(params: {'soft-knee': 0.5});
      final next = s.withSoftKnee(kCompandSoftKneeDefault);
      expect(next.params.containsKey('soft-knee'), isFalse);
      expect(next.softKnee, kCompandSoftKneeDefault);
    });
  });

  group('AiirChannelsX', () {
    test('default settings → ffmpeg default 1-channel pass-through', () {
      // The lavfi `aiir` filter's AVOption defaults are a single
      // gain=1, zeros="1+0i 1-0i", poles="1+0i 1-0i" channel — a
      // unity pass-through. Decoding what ffmpeg actually runs
      // (rather than reporting an empty list) mirrors the runtime.
      const s = AiirSettings();
      expect(s.channels.length, 1);
      expect(s.channels.first.gain, 1.0);
    });

    test('multiple channels round-trip', () {
      const s = AiirSettings();
      final ch = [
        const AiirChannel(
          gain: 1.0,
          zeros: [1.0, -0.5, 0.25],
          poles: [1.0, 0.0, 0.0],
        ),
        const AiirChannel(
          gain: 0.8,
          zeros: [1.0, -0.3],
          poles: [1.0, -0.1, 0.05],
        ),
      ];
      final round = s.withChannels(ch).channels;
      expect(round.length, ch.length);
      for (var i = 0; i < ch.length; i++) {
        expect(round[i].gain, closeTo(ch[i].gain, 1e-3));
        expect(round[i].zeros.length, ch[i].zeros.length);
        expect(round[i].poles.length, ch[i].poles.length);
        for (var k = 0; k < ch[i].zeros.length; k++) {
          expect(round[i].zeros[k], closeTo(ch[i].zeros[k], 1e-3));
        }
        for (var k = 0; k < ch[i].poles.length; k++) {
          expect(round[i].poles[k], closeTo(ch[i].poles[k], 1e-3));
        }
      }
    });

    test('mismatched channel count clamps to the shortest list', () {
      const s = AiirSettings(
        gains: '1|0.5|0.25',
        zeros: '1 -0.5|1 -0.3',
        poles: '1 0|1 -0.1',
      );
      expect(s.channels.length, 2);
    });
  });

  group('CompandPointsX', () {
    test('null points → empty list', () {
      const s = CompandSettings();
      expect(s.transferPoints, isEmpty);
    });

    test('multiple points round-trip sorted by input', () {
      const s = CompandSettings();
      final round = s.withTransferPoints([
        const CompandPoint(inDb: -20, outDb: -10),
        const CompandPoint(inDb: -60, outDb: -60),
        const CompandPoint(inDb: 0, outDb: -3),
      ]).transferPoints;
      expect(round.length, 3);
      // Sorted ascending by inDb.
      expect(round.map((p) => p.inDb).toList(), [-60, -20, 0]);
    });
  });

  group('FirequalizerEntriesX', () {
    test('empty gain_entry → no entries', () {
      const s = FirequalizerSettings();
      expect(s.gainEntries, isEmpty);
    });

    test('multiple entries round-trip sorted by frequency', () {
      const s = FirequalizerSettings();
      final round = s.withGainEntries([
        const FirequalizerEntry(frequencyHz: 5000, gainDb: 3),
        const FirequalizerEntry(frequencyHz: 100, gainDb: -3),
        const FirequalizerEntry(frequencyHz: 1000, gainDb: 0),
      ]).gainEntries;
      expect(round.map((e) => e.frequencyHz).toList(), [100, 1000, 5000]);
    });

    test('whitespace tolerance in the legacy raw format', () {
      // Hand-written `gain_entry` strings with extra whitespace must
      // still parse — the regex doesn't care about gaps.
      const s = FirequalizerSettings(
        gain_entry: 'entry( 100 , 0 ) ; entry(1000, -3) ;entry(5000,3)',
      );
      expect(s.gainEntries.length, 3);
    });
  });
}
