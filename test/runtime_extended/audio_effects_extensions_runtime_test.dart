// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// Per-extension runtime gate. Sibling of
// `audio_effects_chain_runtime_test.dart` — that one applies every
// typed filter with DEFAULT settings to catch "filter doesn't compile
// in this build". This one applies every filter that owns a typed
// extension (`*BandsX`, `*TapsX`, `*VoicesX`, …) with NON-DEFAULT
// values driven through the extension, and captures mpv `error` /
// `fatal` log lines.
//
// Why a separate test: the extensions hand-write the filter's mini-
// grammar (mcompand band syntax, chorus parallel CSVs, compand
// transfer points, etc.). A change in ffmpeg's parser — or a typo in
// our serialiser — would compile fine in Dart but fail at chain-build
// time inside libmpv. This test catches that drift.
//
// Each scenario:
//   1. Builds typed models the consumer would use.
//   2. Wraps them in `*Settings.withXxx()`.
//   3. Applies via `setAudioEffects` and waits for mpv to react.
//   4. Asserts no error / fatal log entry was emitted.

@TestOn('mac-os || linux || windows')
library;

import 'dart:io';

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

import '../_helpers/libmpv_resolver.dart';
import '../_helpers/mpv_error_capture.dart';

void main() {
  final fixturePath =
      '${Directory.current.path}/test/fixtures/sine_440hz_1s.wav';

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

  /// Drives [setEffects], waits for mpv to react, captures any
  /// `error` / `fatal` log line, then RESETS the chain. Reset is
  /// critical so the next scenario doesn't observe errors from the
  /// previous one bleeding through the drain window.
  Future<List<String>> tryEffects(Future<void> Function() setEffects) async {
    final errors = await captureMpvErrors(player, setEffects);
    await player.setAudioEffects(const AudioEffects());
    return errors.map((e) => e.text.trim()).toList();
  }

  group('Extension wire acceptance', () {
    test('AnequalizerBandsX — multi-band chain accepted by mpv', () async {
      final errors = await tryEffects(() async {
        await player.setAudioEffects(
          AudioEffects(
            anequalizer: const AnequalizerSettings(enabled: true).withBands([
              const AnequalizerBand(frequency: 100, bandwidth: 50, gain: -3),
              const AnequalizerBand(frequency: 1000, bandwidth: 500, gain: 2),
              const AnequalizerBand(frequency: 5000, bandwidth: 1000, gain: -2),
            ]),
          ),
        );
      });
      expect(
        errors,
        isEmpty,
        reason: 'AnequalizerBandsX produced unparseable params: $errors',
      );
    });

    test('McompandBandsX — three-band compander accepted by mpv', () async {
      // mcompand asserts every crossover < Nyquist of the input
      // sample rate. The fixture is 22.05 kHz (Nyquist 11.025 kHz),
      // so the top band's crossover lives well below that. Real-world
      // 44.1/48 kHz content can use the full 20 kHz range — the test
      // fixture is the constraint here, not the typed extension.
      final errors = await tryEffects(() async {
        await player.setAudioEffects(
          AudioEffects(
            mcompand: const McompandSettings(enabled: true).withBands([
              const McompandBand(
                thresholdDb: -30,
                ratio: 4,
                attackSeconds: 0.01,
                releaseSeconds: 0.2,
                kneeDb: 6,
                makeupDb: 0,
                crossoverHz: 200,
              ),
              const McompandBand(
                thresholdDb: -24,
                ratio: 3,
                attackSeconds: 0.005,
                releaseSeconds: 0.1,
                kneeDb: 6,
                makeupDb: 2,
                crossoverHz: 2000,
              ),
              const McompandBand(
                thresholdDb: -18,
                ratio: 2,
                attackSeconds: 0.003,
                releaseSeconds: 0.05,
                kneeDb: 6,
                makeupDb: 0,
                crossoverHz: 8000,
              ),
            ]),
          ),
        );
      });
      expect(
        errors,
        isEmpty,
        reason: 'McompandBandsX produced unparseable args: $errors',
      );
    });

    test(
      'SuperequalizerBandsX — every band non-unity accepted by mpv',
      () async {
        final gains = [
          for (var i = 0; i < kSuperequalizerBandCount; i++)
            1.0 + (i % 4) * 0.2,
        ];
        final errors = await tryEffects(() async {
          await player.setAudioEffects(
            AudioEffects(
              superequalizer: const SuperequalizerSettings(
                enabled: true,
              ).withBands(gains),
            ),
          );
        });
        expect(
          errors,
          isEmpty,
          reason: 'SuperequalizerBandsX produced unparseable params: $errors',
        );
      },
    );

    test('AechoTapsX — multi-tap echo accepted by mpv', () async {
      final errors = await tryEffects(() async {
        await player.setAudioEffects(
          AudioEffects(
            aecho: const AechoSettings(enabled: true).withTaps([
              const AechoTap(delayMs: 60, decay: 0.6),
              const AechoTap(delayMs: 120, decay: 0.4),
              const AechoTap(delayMs: 240, decay: 0.2),
            ]),
          ),
        );
      });
      expect(
        errors,
        isEmpty,
        reason: 'AechoTapsX produced unparseable CSVs: $errors',
      );
    });

    test('ChorusVoicesX — two-voice chorus accepted by mpv', () async {
      final errors = await tryEffects(() async {
        await player.setAudioEffects(
          AudioEffects(
            chorus:
                const ChorusSettings(
                  enabled: true,
                  delays: '',
                  decays: '',
                  speeds: '',
                  depths: '',
                ).withVoices([
                  const ChorusVoice(
                    delayMs: 30,
                    decay: 0.4,
                    depthMs: 1.5,
                    speedHz: 0.3,
                  ),
                  const ChorusVoice(
                    delayMs: 50,
                    decay: 0.5,
                    depthMs: 2.0,
                    speedHz: 0.4,
                  ),
                ]),
          ),
        );
      });
      expect(
        errors,
        isEmpty,
        reason: 'ChorusVoicesX produced unparseable CSVs: $errors',
      );
    });

    test('AdelayChannelsX — per-channel delays accepted by mpv', () async {
      final errors = await tryEffects(() async {
        await player.setAudioEffects(
          AudioEffects(
            adelay: const AdelaySettings(
              enabled: true,
            ).withChannelDelaysMs([100, 250]),
          ),
        );
      });
      expect(
        errors,
        isEmpty,
        reason: 'AdelayChannelsX produced unparseable delays: $errors',
      );
    });

    test(
      'CompandEnvelopesX — multi-channel envelopes accepted by mpv',
      () async {
        final errors = await tryEffects(() async {
          await player.setAudioEffects(
            AudioEffects(
              compand: const CompandSettings(enabled: true).withEnvelopes([
                const CompandEnvelope(attackSeconds: 0.005, decaySeconds: 0.1),
                const CompandEnvelope(attackSeconds: 0.01, decaySeconds: 0.2),
              ]),
            ),
          );
        });
        expect(
          errors,
          isEmpty,
          reason: 'CompandEnvelopesX produced unparseable CSVs: $errors',
        );
      },
    );

    test('AfftdnBandNoiseX — 15 custom band levels accepted by mpv', () async {
      final levels = [
        for (var i = 0; i < kAfftdnBandCount; i++) -8.0 + i.toDouble(),
      ];
      final errors = await tryEffects(() async {
        await player.setAudioEffects(
          AudioEffects(
            afftdn: const AfftdnSettings(
              enabled: true,
            ).withBandNoiseLevels(levels),
          ),
        );
      });
      expect(
        errors,
        isEmpty,
        reason: 'AfftdnBandNoiseX produced unparseable noise profile: $errors',
      );
    });

    test('CompandSoftKneeX — soft-knee value accepted by mpv', () async {
      final errors = await tryEffects(() async {
        await player.setAudioEffects(
          AudioEffects(
            compand: const CompandSettings(enabled: true).withSoftKnee(0.5),
          ),
        );
      });
      expect(
        errors,
        isEmpty,
        reason: 'CompandSoftKneeX produced unparseable params: $errors',
      );
    });

    test('AiirChannelsX — IIR coefficients accepted by mpv', () async {
      // A trivial single-channel pass-through IIR (1.0 over 1.0 → unity
      // transfer). Anything more aggressive risks instability and
      // would mask format errors with engine-side filter rejections;
      // we only need to verify the wire format.
      final errors = await tryEffects(() async {
        await player.setAudioEffects(
          AudioEffects(
            aiir: const AiirSettings(enabled: true).withChannels([
              const AiirChannel(gain: 1.0, zeros: [1.0], poles: [1.0]),
            ]),
          ),
        );
      });
      expect(
        errors,
        isEmpty,
        reason: 'AiirChannelsX produced unparseable coefficients: $errors',
      );
    });

    test('CompandPointsX — transfer-function curve accepted by mpv', () async {
      final errors = await tryEffects(() async {
        await player.setAudioEffects(
          AudioEffects(
            compand: const CompandSettings(enabled: true).withTransferPoints([
              const CompandPoint(inDb: -60, outDb: -60),
              const CompandPoint(inDb: -24, outDb: -24),
              const CompandPoint(inDb: 0, outDb: -12),
            ]),
          ),
        );
      });
      expect(
        errors,
        isEmpty,
        reason: 'CompandPointsX produced unparseable points: $errors',
      );
    });

    test('FirequalizerEntriesX — FIR curve accepted by mpv', () async {
      final errors = await tryEffects(() async {
        await player.setAudioEffects(
          AudioEffects(
            firequalizer: const FirequalizerSettings(enabled: true)
                .withGainEntries([
                  const FirequalizerEntry(frequencyHz: 100, gainDb: 0),
                  const FirequalizerEntry(frequencyHz: 1000, gainDb: -3),
                  const FirequalizerEntry(frequencyHz: 5000, gainDb: 3),
                  const FirequalizerEntry(frequencyHz: 15000, gainDb: 0),
                ]),
          ),
        );
      });
      expect(
        errors,
        isEmpty,
        reason: 'FirequalizerEntriesX produced unparseable entries: $errors',
      );
    });
  }, timeout: const Timeout(Duration(minutes: 3)));
}
