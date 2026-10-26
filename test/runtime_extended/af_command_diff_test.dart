// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

import '../_helpers/setter_test_helpers.dart';

void main() {
  late Player player;
  final fixture = '${Directory.current.path}/test/fixtures/sine_5s.flac';

  runtimeSuite(() {
    setUpAll(() async {
      player = await buildPlayer();
      await openAndWaitForLoad(player, fixture);
      // Loop so audio keeps flowing: a lavfi graph is built on its first
      // frame, and af-command has nothing to reach before that.
      await player.setLoop(Loop.file);
      await player.play();
    });

    tearDownAll(() => player.dispose());

    // The fixture loops every 5 s, and a wrap resets the filters: start
    // each test at the beginning so its checks end before one. Waiting for
    // the landing also lets the filters settle before the test's first
    // write.
    setUp(() async {
      final landed = player.stream.seekCompleted.first;
      await player.seek(Duration.zero);
      await landed.timeout(const Duration(seconds: 5));
    });

    /// The momentary loudness once its 400 ms window holds only the
    /// current signal.
    Future<double> settledMomentary() async {
      await Future<void>.delayed(const Duration(milliseconds: 900));
      final l = await player.stream.loudnessMeter
          .skip(1)
          .firstWhere((l) => l.momentary != null)
          .timeout(const Duration(seconds: 10));
      return l.momentary!;
    }

    /// The chain writes (`af set`) mpv ran during [body] and the half
    /// second after it, from its debug log.
    Future<List<String>> chainWrites(Future<void> Function() body) async {
      final writes = <String>[];
      player.setLogLevel(LogLevel.debug);
      final sub = player.stream.log.listen((e) {
        if (e.text.startsWith('Run command: af,')) writes.add(e.text);
      });
      try {
        await body();
        await Future<void>.delayed(const Duration(milliseconds: 500));
      } finally {
        await sub.cancel();
        player.setLogLevel(LogLevel.off);
      }
      return writes;
    }

    test('topology change falls back to a full af rewrite', () async {
      await player.setAudioEffects(const [BassEffect(frequency: 1000)]);
      await putEffect(player, effectOf<BassEffect>(player).copyWith(gain: 18));
      await putEffect(player, const TrebleEffect(gain: -2));
      final af = await player.getRawProperty('af');
      expect(
        af,
        contains('@aek_treble_0:'),
        reason: 'enabling a stage rebuilds the chain string',
      );
      // mpv normalizes option values with a length prefix (`gain=%6%18.000`),
      // so match the normalized payload.
      expect(
        af,
        contains('18.000'),
        reason: 'the rewrite carries the bass gain set live, from the state',
      );
    }, timeout: const Timeout(Duration(seconds: 15)));

    test('a value the running graph refuses throws and rolls back', () async {
      await player.setAudioEffects(const [
        BassEffect(frequency: 1000, gain: 2),
      ]);
      final before = player.state.audioEffects;
      // The string parses (lavfi-equalizer is a known filter), so only the
      // graph rebuild can reject `f=abc`.
      await expectLater(
        player.setAudioEffects(const [
          BassEffect(frequency: 1000, gain: 2),
          RawAudioEffect('lavfi-equalizer=f=abc'),
        ]),
        throwsA(isA<MpvCommandException>()),
      );
      expect(player.state.audioEffects, before);
      expect(
        await player.getRawProperty('af'),
        isNot(contains('equalizer')),
        reason: 'mpv keeps the old chain when the rebuild fails',
      );
    }, timeout: const Timeout(Duration(seconds: 20)));

    test(
      'two refused calls in a row leave the list mpv last accepted',
      () async {
        const accepted = [BassEffect(frequency: 1000, gain: 2)];
        await player.setAudioEffects(accepted);
        // The second call keeps the first one's bad stage: when both are
        // refused, rolling back to the first call's list would leave the state
        // on a chain mpv never ran.
        final first = player.setAudioEffects(const [
          BassEffect(frequency: 1000, gain: 2),
          RawAudioEffect('lavfi-equalizer=f=abc'),
        ]);
        final second = player.updateAudioEffects(
          (fx) => [...fx, const TrebleEffect()],
        );
        await expectLater(first, throwsA(isA<MpvCommandException>()));
        await expectLater(second, throwsA(isA<MpvCommandException>()));
        expect(player.state.audioEffects, accepted);
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    test(
      'a live update on top of a refused rewrite rolls back with it',
      () async {
        const accepted = [BassEffect(frequency: 1000, gain: 2)];
        await player.setAudioEffects(accepted);
        // The update changes only the bass gain, which mpv takes live on the
        // chain it still runs; the list it belongs to holds the bad stage.
        final rewrite = player.setAudioEffects(const [
          BassEffect(frequency: 1000, gain: 2),
          RawAudioEffect('lavfi-equalizer=f=abc'),
        ]);
        final live = player.updateAudioEffects(
          (fx) => [
            for (final e in fx) e is BassEffect ? e.copyWith(gain: 6) : e,
          ],
        );
        await expectLater(rewrite, throwsA(isA<MpvCommandException>()));
        await expectLater(live, throwsA(isA<MpvCommandException>()));
        expect(player.state.audioEffects, accepted);
        expect(await player.getRawProperty('af'), isNot(contains('equalizer')));
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    test('an agate threshold change reaches the running gate', () async {
      // The fixture peaks at -18 dBFS: a threshold of 1.0 gates it down to
      // the 24 dB floor, a threshold of 0.001 lets it through.
      await player.setAudioEffects(const [
        AgateEffect(threshold: 1),
        Ebur128Effect(metadata: true),
      ]);
      final gated = await settledMomentary();
      await putEffect(
        player,
        effectOf<AgateEffect>(player).copyWith(threshold: 0.001),
      );
      final open = await settledMomentary();
      expect(
        open,
        greaterThan(gated + 12),
        reason:
            'agate computes its threshold when it is set up, so a live '
            'command leaves the gate closed (gated $gated, open $open)',
      );
    }, timeout: const Timeout(Duration(seconds: 40)));

    // libmpv-r20 saves an af-command that took in the arguments of its
    // filter and in `af` (af_command_args). Up to r19 mpv rebuilt each
    // filter from the arguments of the last `af set` at a seek, a loop, a
    // track switch and a load, and the player wrote the chain again from
    // the state there.
    libmpvReleaseGroup(20, 'af-command keeps its value', () {
      test('runtime param change goes through af-command: the live graph '
          'and the af string update, with no rebuild', () async {
        await player.setAudioEffects(const [
          BassEffect(frequency: 1000),
          Ebur128Effect(metadata: true),
        ]);

        final initialAf = await player.getRawProperty('af');
        expect(
          initialAf,
          contains('@aek_bass_0:'),
          reason: 'typed stages carry their stable chain label',
        );

        // Wait for the meter to settle on the unboosted signal.
        final before = await player.stream.loudnessMeter
            .firstWhere((l) => l.momentary != null)
            .timeout(const Duration(seconds: 10));

        // Parameter-only change on a command-capable filter: diff path.
        final writes = await chainWrites(
          () => putEffect(
            player,
            effectOf<BassEffect>(player).copyWith(gain: 18),
          ),
        );
        expect(effectOf<BassEffect>(player).gain, 18);
        expect(writes, isEmpty, reason: 'the diff path rewrote the chain');
        expect(
          await player.getRawProperty('af'),
          contains('18.000'),
          reason: 'mpv saves the value af-command set in af',
        );

        // And the audio actually changed: the boosted shelf raises the
        // measured momentary loudness well above the unboosted level.
        final after = await player.stream.loudnessMeter
            .firstWhere(
              (l) => (l.momentary ?? -999) > (before.momentary ?? -999) + 6,
            )
            .timeout(const Duration(seconds: 10));
        expect(
          after.momentary!,
          greaterThan(before.momentary! + 6),
          reason: 'af-command must drive the LIVE graph',
        );
      }, timeout: const Timeout(Duration(seconds: 40)));

      test('a load keeps the values set live', () async {
        await putEffect(player, effectOf<BassEffect>(player).copyWith(gain: 6));
        expect(await player.getRawProperty('af'), contains('6.000'));
        final loaded = player.stream.seekCompleted.first.timeout(
          const Duration(seconds: 10),
        );
        await player.open(Media(fixture), play: true);
        await loaded;
        final af = await player.getRawProperty('af');
        expect(af, contains('6.000'));
        expect(af, isNot(contains('18.000')));
      }, timeout: const Timeout(Duration(seconds: 20)));

      test('a refused rewrite after a live update keeps its value through '
          'the next load', () async {
        await player.setAudioEffects(const [
          BassEffect(frequency: 1000, gain: 1),
        ]);
        // Let frames reach the rebuilt graph, so the update below goes
        // through af-command rather than the rebuild that heals a failed one.
        final rebuiltAt = player.state.position;
        // abs(): the loop may wrap the position back to 0 meanwhile.
        await waitUntil(
          () =>
              (player.state.position - rebuiltAt).abs() >
              const Duration(milliseconds: 150),
        );
        await putEffect(player, effectOf<BassEffect>(player).copyWith(gain: 9));
        expect(effectOf<BassEffect>(player).gain, 9);
        expect(await player.getRawProperty('af'), contains('9.000'));

        // A topology change whose rewrite mpv refuses (unknown raw filter).
        await expectLater(
          player.updateAudioEffects(
            (e) => [
              ...e,
              const RawAudioEffect('definitely_not_a_real_filter_zzz'),
            ],
          ),
          throwsA(isA<MpvCommandException>()),
        );
        // The optimistic commit rolled back to the updated bundle.
        expect(effectOf<BassEffect>(player).gain, 9);
        expect(player.state.audioEffects.whereType<RawAudioEffect>(), isEmpty);
        expect(await player.getRawProperty('af'), contains('9.000'));

        final loaded = player.stream.seekCompleted.first.timeout(
          const Duration(seconds: 10),
        );
        await player.open(Media(fixture), play: true);
        await loaded;
        expect(await player.getRawProperty('af'), contains('9.000'));
      }, timeout: const Timeout(Duration(seconds: 30)));

      test('a rebuild after live updates applies the requested values, not '
          'the live ones', () async {
        await player.setAudioEffects(const [
          BassEffect(frequency: 1000),
          Ebur128Effect(metadata: true),
        ]);
        final flat = await settledMomentary();

        // Live update: mpv's bass filter now runs at +18 dB.
        await putEffect(
          player,
          effectOf<BassEffect>(player).copyWith(gain: 18),
        );
        final boosted = await settledMomentary();
        expect(boosted, greaterThan(flat + 6));

        // A shape change back to gain=0: mpv keeps a filter whose saved
        // arguments equal the new ones, so they must hold the +18 dB.
        await player.setAudioEffects(const [
          BassEffect(frequency: 1000),
          TrebleEffect(),
          Ebur128Effect(metadata: true),
        ]);
        final after = await settledMomentary();
        expect(
          after,
          closeTo(flat, 3),
          reason:
              'the bass stage must be back at 0 dB (flat $flat, '
              'boosted $boosted, after $after)',
        );
      }, timeout: const Timeout(Duration(seconds: 40)));

      test('a seek keeps the values set live', () async {
        await player.setAudioEffects(const [
          BassEffect(frequency: 1000),
          Ebur128Effect(metadata: true),
        ]);
        final flat = await settledMomentary();
        await putEffect(
          player,
          effectOf<BassEffect>(player).copyWith(gain: 18),
        );
        final boosted = await settledMomentary();
        expect(boosted, greaterThan(flat + 6));

        // lavfi frees its graph on a seek and rebuilds each filter from its
        // arguments.
        await player.seek(const Duration(seconds: 1));
        final after = await settledMomentary();
        expect(
          after,
          closeTo(boosted, 3),
          reason:
              'the bass stage must stay at +18 dB (flat $flat, '
              'boosted $boosted, after $after)',
        );
      }, timeout: const Timeout(Duration(seconds: 40)));

      test('a seek after a live update writes no chain', () async {
        await player.setAudioEffects(const [BassEffect(frequency: 1000)]);
        await Future<void>.delayed(const Duration(milliseconds: 500));
        await putEffect(player, effectOf<BassEffect>(player).copyWith(gain: 9));
        final writes = await chainWrites(() async {
          final landed = player.stream.seekCompleted.first;
          await player.seek(const Duration(seconds: 1));
          await landed.timeout(const Duration(seconds: 5));
        });
        expect(writes, isEmpty, reason: 'the seek rewrote the chain');
        expect(await player.getRawProperty('af'), contains('9.000'));
      }, timeout: const Timeout(Duration(seconds: 20)));

      // F50: the write back after a refusal must rebuild the stage the
      // live update moved, which an older libmpv kept at its old arguments.
      test('a live update on top of a refused rewrite leaves the audio of '
          'the list mpv accepted (F50)', () async {
        const accepted = [
          BassEffect(frequency: 1000),
          Ebur128Effect(metadata: true),
        ];
        await player.setAudioEffects(accepted);
        final flat = await settledMomentary();
        final rewrite = player.setAudioEffects(const [
          BassEffect(frequency: 1000),
          Ebur128Effect(metadata: true),
          RawAudioEffect('lavfi-equalizer=f=abc'),
        ]);
        final live = player.updateAudioEffects(
          (fx) => [
            for (final e in fx) e is BassEffect ? e.copyWith(gain: 18) : e,
          ],
        );
        await expectLater(rewrite, throwsA(isA<MpvCommandException>()));
        await expectLater(live, throwsA(isA<MpvCommandException>()));
        expect(player.state.audioEffects, accepted);
        final after = await settledMomentary();
        expect(
          after,
          closeTo(flat, 3),
          reason:
              'the bass stage must be back at 0 dB (flat $flat, after '
              '$after)',
        );
      }, timeout: const Timeout(Duration(seconds: 40)));

      test('an audio track switch keeps the values set live', () async {
        // Two 5 s FLAC tracks, made with:
        //   ffmpeg -f lavfi -i sine=frequency=440:sample_rate=22050:duration=5
        //     -f lavfi -i sine=frequency=660:sample_rate=22050:duration=5
        //     -map 0 -map 1 -c:a flac multitrack_two_audio_5s.mka
        final twoTracks =
            '${Directory.current.path}/test/fixtures/multitrack_two_audio_5s.mka';
        await player.setLoop(Loop.off);
        addTearDown(() async {
          await openAndWaitForLoad(player, fixture);
          await player.setLoop(Loop.file);
          await player.play();
        });
        await openAndWaitForLoad(player, twoTracks);
        await player.play();
        await player.setAudioEffects(const [BassEffect(frequency: 1000)]);
        await Future<void>.delayed(const Duration(milliseconds: 500));
        await putEffect(player, effectOf<BassEffect>(player).copyWith(gain: 9));
        expect(
          await player.getRawProperty('af'),
          contains('9.000'),
          reason: 'precondition: the update went live and was saved',
        );

        // mpv builds the chain for the new track from the saved arguments.
        await player.setAudioTrack(const Track.id(2));
        await waitUntil(
          () async => (await player.getRawProperty('af'))!.contains('9.000'),
          reason: 'the chain of the new track keeps the live value',
        );
      }, timeout: const Timeout(Duration(seconds: 20)));
    });
  });
}
