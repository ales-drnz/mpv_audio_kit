// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'dart:async';
import 'dart:io';

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

import '../_helpers/setter_test_helpers.dart';

/// Regression coverage for two intent-axis / completed-axis invariants
/// around playlist navigation, against real libmpv.
///
/// 1. `jump()` starts playback (it unpauses before issuing
///    `playlist-play-index`), so it MUST also set the `playWhenReady`
///    intent — like `play()` / `open(play: true)` do. mpv's `pause`
///    property is deliberately unobserved, so nothing downstream can
///    correct a missed optimistic write: the OS play/pause button would
///    read "paused" while audio is audibly playing.
///
/// 2. `completed` must rise ONLY at the true end of content (last
///    playlist entry, no loop). A gapless mid-playlist advance emits
///    MPV_EVENT_END_FILE(EOF) for each finished entry; that per-entry
///    event must not pulse `completed` / `MpvPlaybackState.completed`
///    between two tracks — the same no-flicker contract the
///    `eof-reached` hook enforces via its end-of-content gate.
void main() {
  // 5-second fixture for the jump test: long enough that the jumped-to
  // track is still mid-playback while we assert.
  final longFixture = '${Directory.current.path}/test/fixtures/sine_5s.flac';
  // 1-second fixture for the boundary test: two of these drain in ~2 s.
  final shortFixture =
      '${Directory.current.path}/test/fixtures/sine_440hz_1s.wav';

  setUpAll(() {
    if (!initLibmpvOrSkip(fixturePath: longFixture)) return;
    initLibmpvOrSkip(fixturePath: shortFixture);
  });

  group('jump() intent axis', () {
    test('jump() from a paused playlist raises playWhenReady', () async {
      final player = await buildPlayer();
      addTearDown(() async {
        await player.stop();
        await player.dispose();
      });

      // Load two entries, paused. Anchor readiness on seekCompleted
      // (PLAYBACK_RESTART) — pre-subscribed before openAll.
      final loaded = Completer<void>();
      final loadSub = player.stream.seekCompleted.listen((_) {
        if (!loaded.isCompleted) loaded.complete();
      });
      await player.openAll([
        Media(longFixture),
        Media(longFixture),
      ], play: false);
      await loaded.future.timeout(const Duration(seconds: 10));
      await loadSub.cancel();
      expect(
        player.state.playWhenReady,
        isFalse,
        reason: 'opened with play: false — intent starts released',
      );

      // Pre-subscribe BEFORE jump(): the optimistic intent write (if
      // present) lands synchronously at the call site.
      final intentEmissions = <bool>[];
      final intentSub = player.stream.playWhenReady.listen(intentEmissions.add);

      // Anchor "the jumped-to entry is actually producing audio" on the
      // actual-output axis, pre-subscribed before jump() as well.
      final actuallyPlaying = player.stream.playing
          .firstWhere((p) => p)
          .timeout(const Duration(seconds: 10));

      await player.jump(1);
      await actuallyPlaying;

      // Give the intent a generous settling window. A correct jump()
      // sets it synchronously at the call, so this loop exits on the
      // first iteration when the invariant holds.
      final deadline = DateTime.now().add(const Duration(seconds: 2));
      while (!player.state.playWhenReady && DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 25));
      }
      final positionA = player.state.position;
      await Future<void>.delayed(const Duration(milliseconds: 400));
      final positionB = player.state.position;
      await intentSub.cancel();

      expect(
        player.state.playWhenReady,
        isTrue,
        reason:
            'jump() unpauses and starts the target entry, so the '
            'play/pause intent must rise like play()/open(play: true). '
            'Desync evidence: state.playing=${player.state.playing}, '
            'playlist index=${player.state.playlist.index}, '
            'position advanced $positionA -> $positionB, '
            'playWhenReady emissions since jump(): $intentEmissions '
            '(mpv "pause" is unobserved — nothing ever corrects this).',
      );
      expect(
        intentEmissions,
        contains(true),
        reason:
            'stream.playWhenReady must emit the rising intent edge '
            'after jump()',
      );
    }, timeout: const Timeout(Duration(seconds: 30)));
  });

  group('completed at gapless playlist boundary', () {
    test('completed never pulses true at a mid-playlist advance', () async {
      final player = await buildPlayer();
      addTearDown(player.dispose);

      // Per-emission context so a failure shows WHERE a flicker happened.
      final completedLog = <String>[];
      final completedValues = <bool>[];
      final playbackStates = <MpvPlaybackState>[];
      final epoch = DateTime.now();
      String ctx() {
        final t = DateTime.now().difference(epoch).inMilliseconds;
        return 't=${t}ms idx=${player.state.playlist.index} '
            'pos=${player.state.position.inMilliseconds}ms '
            'eof=${player.state.eofReached}';
      }

      final completedSub = player.stream.completed.listen((c) {
        completedValues.add(c);
        completedLog.add('completed=$c (${ctx()})');
      });
      final stateSub = player.stream.playbackState.listen((s) {
        playbackStates.add(s);
        completedLog.add('playbackState=$s (${ctx()})');
      });

      // The intent release fires only at the TRUE end of content (the
      // eof-reached hook gated by the end-of-content check), so it is a
      // boundary-proof "playlist fully drained" anchor. Pre-subscribed
      // before openAll; the initial false is never re-emitted (dedup),
      // so this completes only on the genuine final release.
      final drained = player.stream.playWhenReady
          .firstWhere((p) => !p)
          .timeout(const Duration(seconds: 15));

      await player.openAll([
        Media(shortFixture),
        Media(shortFixture),
      ], play: true);
      await drained;
      // Let trailing transitions land.
      await Future<void>.delayed(const Duration(milliseconds: 600));
      await completedSub.cancel();
      await stateSub.cancel();

      expect(
        player.state.completed,
        isTrue,
        reason: 'sanity: the playlist did reach its true end',
      );

      // A correct run shows exactly ONE rising edge of `completed`, at
      // the end of the LAST entry, never followed by false. The
      // mid-playlist END_FILE(EOF) of entry 0 must not surface.
      expect(
        completedValues,
        equals([true]),
        reason:
            'completed must rise exactly once, at the true end of '
            'content — a true->false->true sequence means the gapless '
            'track-0 -> track-1 boundary pulsed it. Full emission log:\n'
            '${completedLog.join('\n')}',
      );

      // Redundant probe on the derived stream, in case the boolean cell
      // coalesces: MpvPlaybackState.completed must only appear as the
      // final resting state, never mid-run.
      final firstCompleted = playbackStates.indexOf(MpvPlaybackState.completed);
      final lastNonCompleted = playbackStates.lastIndexWhere(
        (s) => s != MpvPlaybackState.completed,
      );
      expect(
        firstCompleted == -1 || lastNonCompleted < firstCompleted,
        isTrue,
        reason:
            'MpvPlaybackState.completed appeared mid-run (index '
            '$firstCompleted of $playbackStates) — transient completed '
            'pulse at the playlist boundary. Full emission log:\n'
            '${completedLog.join('\n')}',
      );
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}
