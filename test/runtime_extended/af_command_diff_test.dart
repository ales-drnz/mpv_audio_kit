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

    test('runtime param change goes through af-command: live graph updates, '
        'af string stays stale, state stays correct', () async {
      await player.setAudioEffects(const [
        BassEffect(f: 1000),
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

      // Parameter-only change on a command-capable filter → diff path.
      await putEffect(player, effectOf<BassEffect>(player).copyWith(g: 18));

      // State committed the new bundle…
      expect(effectOf<BassEffect>(player).g, 18);
      // …but the af STRING was not rewritten — the live graph was updated
      // in place via af-command (a rewrite would have produced g=18 here).
      final afterAf = await player.getRawProperty('af');
      expect(
        afterAf,
        initialAf,
        reason: 'diff path must not rewrite the af property string',
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

    test('topology change falls back to a full af rewrite', () async {
      await putEffect(player, const TrebleEffect(g: -2));
      final af = await player.getRawProperty('af');
      expect(
        af,
        contains('@aek_treble_0:'),
        reason: 'enabling a stage rebuilds the chain string',
      );
      // mpv normalizes option values with a length prefix (`g=%6%18.000`),
      // so match the normalized payload.
      expect(
        af,
        contains('18.000'),
        reason:
            'the rewrite re-emits the af-command-applied bass gain '
            'from state, healing the stale string',
      );
    }, timeout: const Timeout(Duration(seconds: 15)));

    test('FILE_LOADED resyncs a stale af string from state', () async {
      // Make the string stale again with a runtime-only change…
      await putEffect(player, effectOf<BassEffect>(player).copyWith(g: 6));
      expect(
        await player.getRawProperty('af'),
        contains('18.000'),
        reason: 'precondition: string still carries the pre-diff value',
      );

      // …then load a file: the dispatch layer rewrites the string so the
      // new chain is built with the live values.
      final loaded = player.stream.seekCompleted.first.timeout(
        const Duration(seconds: 10),
      );
      await player.open(Media(fixture), play: true);
      await loaded;
      // The resync runs on FILE_LOADED, just before PLAYBACK_RESTART.
      final af = await player.getRawProperty('af');
      expect(
        af,
        contains('6.000'),
        reason: 'stale af string must be rewritten from state on load',
      );
      expect(
        af,
        isNot(contains('18.000')),
        reason: 'the pre-diff value must be gone after the resync',
      );
    }, timeout: const Timeout(Duration(seconds: 20)));

    test('afcmd-1: a rewrite that FAILS after a diff re-arms the stale flag so '
        'the next load still resyncs the diff value', () async {
      // Clean baseline with a command-capable bass stage at a known gain.
      await player.setAudioEffects(const [BassEffect(f: 1000, g: 1)]);
      // Let frames reach the rebuilt graph, so the update below goes
      // through af-command rather than the rebuild that heals a failed one.
      final rebuiltAt = player.state.position;
      // abs(): the loop may wrap the position back to 0 meanwhile.
      await waitUntil(
        () =>
            (player.state.position - rebuiltAt).abs() >
            const Duration(milliseconds: 150),
      );
      // Runtime-only change → diff (af-command); the af STRING stays stale at
      // g=1 while the live graph and committed state move to g=9.
      await putEffect(player, effectOf<BassEffect>(player).copyWith(g: 9));
      expect(effectOf<BassEffect>(player).g, 9);
      expect(
        await player.getRawProperty('af'),
        isNot(contains('9.000')),
        reason: 'precondition: the diff did not rewrite the af string',
      );

      // Topology change whose rewrite mpv REJECTS (unknown raw filter) →
      // `_rewriteAfChain` throws. The eager clear of `_afStringStale` would
      // wrongly mark the string clean here; the fix re-arms it on failure.
      await expectLater(
        player.updateAudioEffects(
          (e) => [
            ...e,
            const RawAudioEffect('definitely_not_a_real_filter_zzz'),
          ],
        ),
        throwsA(isA<MpvCommandException>()),
      );
      // The optimistic commit rolled back to the diff'd bundle.
      expect(effectOf<BassEffect>(player).g, 9);
      expect(player.state.audioEffects.whereType<RawAudioEffect>(), isEmpty);

      // Load a file: the resync must fire (flag re-armed), rebuilding the chain
      // from committed state so the new af string carries the diff value.
      final loaded = player.stream.seekCompleted.first.timeout(
        const Duration(seconds: 10),
      );
      await player.open(Media(fixture), play: true);
      await loaded;
      expect(
        await player.getRawProperty('af'),
        contains('9.000'),
        reason:
            'a failed rewrite after a diff must NOT clear the stale flag; '
            'the FILE_LOADED resync re-asserts the diff value (g=9)',
      );
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('a value the running graph refuses throws and rolls back', () async {
      await player.setAudioEffects(const [BassEffect(f: 1000, g: 2)]);
      final before = player.state.audioEffects;
      // The string parses (lavfi-equalizer is a known filter), so only the
      // graph rebuild can reject `f=abc`.
      await expectLater(
        player.setAudioEffects(const [
          BassEffect(f: 1000, g: 2),
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

    test('a rebuild after live updates applies the requested values, not the '
        'live ones', () async {
      Future<double> settledMomentary() async {
        // The momentary window is 400 ms: let it fill with the new signal.
        await Future<void>.delayed(const Duration(milliseconds: 900));
        final l = await player.stream.loudnessMeter
            .skip(1)
            .firstWhere((l) => l.momentary != null)
            .timeout(const Duration(seconds: 10));
        return l.momentary!;
      }

      await player.setAudioEffects(const [
        BassEffect(f: 1000),
        Ebur128Effect(metadata: true),
      ]);
      final flat = await settledMomentary();

      // Live update: mpv's bass filter now runs at +18 dB while the
      // arguments it was created with still say 0.
      await putEffect(player, effectOf<BassEffect>(player).copyWith(g: 18));
      final boosted = await settledMomentary();
      expect(boosted, greaterThan(flat + 6));

      // A shape change back to g=0: mpv would keep the bass filter, whose
      // stored arguments equal the new ones, still running at +18 dB.
      await player.setAudioEffects(const [
        BassEffect(f: 1000),
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
  });
}
