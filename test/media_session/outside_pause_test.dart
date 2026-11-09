// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

// The web's outside pause of the session's <audio> element under each
// interruption policy (0.7.0): the command it sends, as an interruption on
// iOS and Android, and what counts as an outside pause or play of the
// element. test/web/web_audio_test.dart checks the element in Chrome.

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:mpv_audio_kit/src/media_session/outside_pause.dart';
import 'package:test/test.dart';

List<String?> _run(
  InterruptionPolicy policy,
  List<(bool element, bool playing)> changes,
) {
  final f = OutsidePauseFollower()..policy = policy;
  return [
    for (final (element, playing) in changes)
      f.onOutside(elementPlaying: element, playing: playing),
  ];
}

void main() {
  test('pauseAndResume pauses, then plays when the element plays again', () {
    expect(
      _run(InterruptionPolicy.pauseAndResume, [(false, true), (true, false)]),
      ['pause', 'play'],
    );
  });

  test('pauseOnly pauses and never plays', () {
    expect(_run(InterruptionPolicy.pauseOnly, [(false, true), (true, false)]), [
      'pause',
      null,
    ]);
  });

  test('keepPlaying sends nothing', () {
    expect(
      _run(InterruptionPolicy.keepPlaying, [(false, true), (true, true)]),
      [null, null],
    );
  });

  test('a player already paused is neither paused nor played', () {
    expect(
      _run(InterruptionPolicy.pauseAndResume, [(false, false), (true, false)]),
      [null, null],
    );
  });

  test('a play of the user since forgets the pause', () {
    final f = OutsidePauseFollower();
    expect(f.onOutside(elementPlaying: false, playing: true), 'pause');
    f.reset();
    expect(f.onOutside(elementPlaying: true, playing: true), isNull);
  });

  test('the policy by its name, the default for another', () {
    expect(
      OutsidePauseFollower.policyOf('pauseOnly'),
      InterruptionPolicy.pauseOnly,
    );
    expect(
      OutsidePauseFollower.policyOf('keepPlaying'),
      InterruptionPolicy.keepPlaying,
    );
    expect(
      OutsidePauseFollower.policyOf(null),
      InterruptionPolicy.pauseAndResume,
    );
    expect(
      OutsidePauseFollower.policyOf('other'),
      InterruptionPolicy.pauseAndResume,
    );
  });

  test(
    'an outside pause while the player is paused forgets an earlier one',
    () {
      // The element replayed at a gesture, the player left paused, then the
      // browser pauses and plays the element again: nothing to resume.
      final f = OutsidePauseFollower();
      expect(f.onOutside(elementPlaying: false, playing: true), 'pause');
      expect(f.onOutside(elementPlaying: false, playing: false), isNull);
      expect(f.onOutside(elementPlaying: true, playing: false), isNull);
    },
  );

  group('the element watch', () {
    test('a pause of a playing element is an outside pause, once', () {
      final w = OutsideElementWatch();
      expect(w.onPause(), isFalse, reason: 'it never played');
      w.onOutputPlay(elementPaused: true);
      expect(w.onPlaying(), isFalse);
      expect(w.onPause(), isTrue);
      expect(w.onPause(), isFalse);
    });

    test('a play from outside after an outside pause says so', () {
      final w = OutsideElementWatch();
      w.onOutputPlay(elementPaused: true);
      w.onPlaying();
      w.onPause();
      expect(w.onPlaying(), isTrue);
      expect(w.onPlaying(), isFalse, reason: 'no pause since');
    });

    test('a play of the output after an outside pause does not', () {
      final w = OutsideElementWatch();
      w.onOutputPlay(elementPaused: true);
      w.onPlaying();
      w.onPause();
      w.onOutputPlay(elementPaused: true);
      expect(w.onPlaying(), isFalse);
    });

    test('play() on a playing element leaves no flag for the next play', () {
      final w = OutsideElementWatch();
      w.onOutputPlay(elementPaused: true);
      w.onPlaying();
      w.onOutputPlay(elementPaused: false);
      w.onPause();
      expect(w.onPlaying(), isTrue);
    });

    test('a refused play() leaves none either', () {
      final w = OutsideElementWatch();
      w.onOutputPlay(elementPaused: true);
      w.onPlaying();
      w.onPause();
      w.onOutputPlay(elementPaused: true);
      w.onPlayRefused();
      expect(w.onPlaying(), isTrue);
    });

    test('a new route forgets the outside pause', () {
      final w = OutsideElementWatch();
      w.onOutputPlay(elementPaused: true);
      w.onPlaying();
      w.onPause();
      w.reset();
      expect(w.onPlaying(), isFalse);
    });

    test('the output plays the element when the context runs', () {
      final w = OutsideElementWatch();
      expect(w.onContextState('suspended'), isFalse);
      expect(w.onContextState('running'), isTrue);
    });
  });
}
