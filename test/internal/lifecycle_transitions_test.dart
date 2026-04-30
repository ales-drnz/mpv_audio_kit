// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:mpv_audio_kit/src/internal/lifecycle_transitions.dart';

void main() {
  group('computeLifecycle — partial updates', () {
    test('null fields leave state and "did-change" flags untouched', () {
      const prev = PlayerState(
          playing: true, buffering: false, completed: false);
      final r = computeLifecycle(prev: prev);
      expect(r.newState, prev);
      expect(r.playingDidChange, isFalse);
      expect(r.bufferingDidChange, isFalse);
      expect(r.completedDidChange, isFalse);
    });

    test('only the supplied fields are written into newState', () {
      const prev = PlayerState(
          playing: true, buffering: true, completed: false);
      final r = computeLifecycle(prev: prev, completed: true);
      expect(r.newState.playing, isTrue, reason: 'untouched');
      expect(r.newState.buffering, isTrue, reason: 'untouched');
      expect(r.newState.completed, isTrue);
      expect(r.completedDidChange, isTrue);
      expect(r.playingDidChange, isFalse);
      expect(r.bufferingDidChange, isFalse);
    });
  });

  group('computeLifecycle — dedup semantics', () {
    test('writing the same value as prev → no change flag', () {
      // The reactive layer dedups on the property side, but the
      // lifecycle helper has its own diff because the three flags drive
      // *different* reactives. A spurious emit on `_buffering` from
      // `_updateLifecycle(buffering: true)` when buffering was already
      // true would re-trigger consumers' loading-spinner UX.
      const prev = PlayerState(
          playing: true, buffering: false, completed: false);
      final r = computeLifecycle(
          prev: prev, playing: true, buffering: false, completed: false);
      expect(r.newState, prev);
      expect(r.playingDidChange, isFalse);
      expect(r.bufferingDidChange, isFalse);
      expect(r.completedDidChange, isFalse);
    });
  });

  group('computeLifecycle — regression suite for 0.0.9 bug class', () {
    test(
        'StartFile: prev=idle → buffering=true must signal change on '
        'buffering (the missing emit that broke loading spinners)', () {
      const prev = PlayerState(buffering: false);
      final r = computeLifecycle(
          prev: prev, buffering: true, completed: false);
      expect(r.newState.buffering, isTrue);
      expect(r.bufferingDidChange, isTrue,
          reason:
              '0.0.9 silently kept _bufferingCtrl unfed across the whole '
              'lifecycle — this assertion fails if that path returns');
    });

    test(
        'FileLoaded: prev=buffering → buffering=false must signal change '
        '(consumer must see "stopped buffering")', () {
      const prev = PlayerState(buffering: true);
      final r = computeLifecycle(prev: prev, buffering: false);
      expect(r.bufferingDidChange, isTrue);
    });

    test(
        'EndFile (eof): prev=playing → playing=false + completed=true '
        '(both flags must change on a clean finish)', () {
      const prev = PlayerState(
          playing: true, buffering: false, completed: false);
      final r = computeLifecycle(
          prev: prev, playing: false, buffering: false, completed: true);
      expect(r.newState.playing, isFalse);
      expect(r.newState.completed, isTrue);
      expect(r.playingDidChange, isTrue);
      expect(r.completedDidChange, isTrue,
          reason:
              '0.0.9 dropped the completed emit, breaking custom queue '
              '"track finished" handlers');
    });

    test(
        'EndFile (error): completed=false override must not be silenced '
        'when prev.completed was already false', () {
      const prev = PlayerState(completed: false);
      final r = computeLifecycle(prev: prev, completed: false);
      expect(r.completedDidChange, isFalse,
          reason: 'no-op writes are correctly silenced');
    });

    test(
        'idle-active=true: clears both playing and buffering '
        '(matches the onIdleActive callback wiring in default specs)',
        () {
      const prev = PlayerState(playing: true, buffering: true);
      final r = computeLifecycle(
          prev: prev, playing: false, buffering: false);
      expect(r.newState.playing, isFalse);
      expect(r.newState.buffering, isFalse);
      expect(r.playingDidChange, isTrue);
      expect(r.bufferingDidChange, isTrue);
    });
  });
}
