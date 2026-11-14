// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

// TransportMachine under the calls of a player (play, pause, jump, open),
// each cut at its awaits, on random sequences (kiri_check). The file
// transport_machine_test.dart checks play, pause and a seek in mpv's FIFO
// order; here the calls are the ones that replace the content too, and
// two things are checked.
//
// The first rig (_Calls) keeps every call that waits on the core as a list
// of steps, and the sequence runs them in any order, between events of
// the core that come in any order too (not only the ones mpv can send).
// Whatever the order: the intent is on only while the last word was to
// play, so no late reply undoes a pause(), and no event of the core ever
// writes the intent on.
//
// The second rig (_Fifo) is the one of transport_machine_test with a jump
// and a load added, in mpv's FIFO order: once mpv has said all, the intent
// is on exactly when the last call asked to play and the core is not
// parked at the end.
//
// The steps mirror how the player uses the machine today
// (player_playback.part.dart play() and pause(), player_playlist.part.dart
// jump(), player_open.part.dart _open(), player_intent.part.dart
// trackLoad()): a change of that protocol changes them.

import 'dart:io';

import 'package:kiri_check/kiri_check.dart';
import 'package:kiri_check/stateful_test.dart';
import 'package:mpv_audio_kit/src/internals/transport_machine.dart';
import 'package:test/test.dart';

/// A call that waits on the core: what it does when the answer comes,
/// [flag] being what the core answered (parked, idle, a failure).
typedef _Step = void Function(bool flag);

/// The player's side of the machine, each call cut where the player
/// awaits the core.
final class _Calls {
  final TransportMachine m = TransportMachine();

  /// `state.playback.playWhenReady`.
  bool intent = false;

  /// What the app said last: the value of the last claim, or the intent a
  /// failed call put back.
  bool lastWord = false;

  /// Whether the last public call was pause().
  bool pausedLast = false;

  /// `state.playback.completed`: raised by a read of the end, cleared by
  /// START_FILE and PLAYBACK_RESTART.
  bool completed = false;

  /// Whether an effect of the core's events wrote the intent on.
  bool eventWroteOn = false;

  /// The calls that wait on the core.
  final List<_Step> waiting = [];

  int _claim(bool value) {
    final (write, epoch) = m.claimIntent(value);
    intent = write.value;
    lastWord = value;
    pausedLast = false;
    return epoch;
  }

  // The effects of an event, as _Transport._apply carries them out.
  void _apply(List<TransportEffect> effects) {
    for (final effect in effects) {
      switch (effect) {
        case WriteIntent(:final value):
          if (value) eventWroteOn = true;
          intent = value;
        case ReadIdle():
          waiting.add((idle) => _apply(m.idleRead(idle: idle)));
        case SettleIdle() || ClearFinishedFile():
          break;
      }
    }
  }

  /// Player.play().
  void play() {
    final epoch = _claim(true);
    // The reads of _parkedPaused.
    waiting.add((parked) {
      if (!m.owns(epoch)) return;
      if (!parked) {
        // The unpause, then the read of idle-active.
        waiting.add((idle) {
          if (idle && m.loadsInFlight == 0 && m.owns(epoch)) intent = false;
        });
        return;
      }
      m.takePark();
      intent = true;
      // The reply of the seek to the start.
      waiting.add((_) {
        if (m.wantsPlay(epoch)) {
          m.takePark();
          intent = true;
        }
        if (m.loadsInFlight > 0) return;
        // The reads that tell a source that cannot seek back.
        waiting.add((stuck) {
          if (stuck && m.loadsInFlight == 0 && m.owns(epoch)) intent = false;
        });
      });
    });
  }

  /// Player.pause().
  void pause() {
    _claim(false);
    pausedLast = true;
  }

  /// Player.jump().
  void jump() {
    final previous = intent;
    final epoch = _claim(true);
    // The check of the index.
    waiting.add((outOfRange) {
      if (outOfRange) {
        final write = m.restoreIntent(m.loadEpoch, epoch, previous);
        if (write != null) {
          intent = write.value;
          lastWord = previous;
        }
        return;
      }
      // The reply of playlist-play-index.
      waiting.add((_) {
        m.takePark();
        if (m.wantsPlay(epoch)) intent = true;
      });
    });
  }

  /// Player.open(play: [shouldPlay]). The gate is passed in the order of
  /// the calls, so the claims are made at the call.
  void open(bool shouldPlay) {
    m.beginLoad();
    final load = m.claimLoad();
    final previous = intent;
    final epoch = _claim(shouldPlay);
    void end() => _apply(m.endLoad(completed: completed));
    void restore() {
      final write = m.restoreIntent(load, epoch, previous);
      if (write == null) return;
      intent = write.value;
      lastWord = previous;
    }

    // resolveUri.
    waiting.add((fails) {
      if (fails) {
        restore();
        return end();
      }
      if (load != m.loadEpoch) return end();
      // The reads before the load: the last check of the epoch.
      waiting.add((_) {
        if (load != m.loadEpoch) return end();
        // The reply of loadfile.
        waiting.add((refused) {
          if (refused) {
            restore();
          } else {
            m.takePark();
          }
          end();
        });
      });
    });
  }

  /// Runs the call waiting at [index] (among the ones there are).
  void answer(int index, bool flag) {
    if (waiting.isEmpty) return;
    waiting.removeAt(index % waiting.length)(flag);
  }

  void startFile() {
    m.startFile();
    completed = false;
  }

  void restart() {
    m.restart();
    completed = false;
  }

  /// A read of the end of content (Player._settleEndOfContent).
  void endRead() {
    if (!m.hasLoadedFile) return;
    completed = true;
    _apply(m.endOfContent());
  }

  void idle(bool value) => _apply(m.idleActive(value));

  /// END_FILE with an error at the last entry: the player writes the
  /// intent off itself.
  void loadError() => intent = false;

  /// What holds after every step.
  bool get sound =>
      (!intent || lastWord) && (!pausedLast || !intent) && !eventWroteOn;
}

/// The source of the player's jump(), its white space folded: the steps
/// of the rigs are checked against it, so a change of the player without
/// the rig fails here.
String _jumpSource() {
  final source = File(
    '${Directory.current.path}/lib/src/player/mixins/'
    'player_playlist.part.dart',
  ).readAsStringSync();
  final start = source.indexOf('Future<void> jump(int index) async {');
  final end = source.indexOf('Future<void> move(', start);
  return source.substring(start, end).replaceAll(RegExp(r'\s+'), ' ');
}

final class _Nothing {}

final class _CallsBehavior extends Behavior<_Nothing, _Calls> {
  @override
  _Nothing initialState() => _Nothing();

  @override
  _Calls createSystem(_Nothing s) => _Calls();

  @override
  void destroySystem(_Calls system) {}

  /// An event of the core: it never turns the intent on.
  static bool _event(_Calls c, void Function() send) {
    final before = c.intent;
    send();
    return c.sound && (before || !c.intent);
  }

  static bool _call(_Calls c, void Function() call) {
    call();
    return c.sound;
  }

  @override
  List<Command<_Nothing, _Calls>> generateCommands(_Nothing s) => [
    Action0(
      'play()',
      nextState: (_) {},
      run: (c) => _call(c, c.play),
      postcondition: (_, ok) => ok,
    ),
    Action0(
      'pause()',
      nextState: (_) {},
      run: (c) => _call(c, c.pause),
      postcondition: (_, ok) => ok,
    ),
    Action0(
      'jump()',
      nextState: (_) {},
      run: (c) => _call(c, c.jump),
      postcondition: (_, ok) => ok,
    ),
    Action(
      'open(play)',
      boolean(),
      nextState: (_, _) {},
      run: (c, play) => _call(c, () => c.open(play)),
      postcondition: (_, _, ok) => ok,
    ),
    // Bit 0: what the core answers. The rest: which call gets its answer.
    // Two of them, so the calls move on as often as new ones come.
    for (final name in ['a call gets its answer', 'another call gets its'])
      Action(
        name,
        integer(min: 0, max: 63),
        nextState: (_, _) {},
        run: (c, how) => _call(c, () => c.answer(how >> 1, how & 1 == 1)),
        postcondition: (_, _, ok) => ok,
      ),
    Action0(
      'START_FILE',
      nextState: (_) {},
      run: (c) => _event(c, c.startFile),
      postcondition: (_, ok) => ok,
    ),
    Action0(
      'PLAYBACK_RESTART',
      nextState: (_) {},
      run: (c) => _event(c, c.restart),
      postcondition: (_, ok) => ok,
    ),
    Action0(
      'a read of the end',
      nextState: (_) {},
      run: (c) => _event(c, c.endRead),
      postcondition: (_, ok) => ok,
    ),
    Action(
      'idle-active',
      boolean(),
      nextState: (_, _) {},
      run: (c, idle) => _event(c, () => c.idle(idle)),
      postcondition: (_, _, ok) => ok,
    ),
    Action0(
      'a load error at the last entry',
      nextState: (_) {},
      run: (c) => _event(c, c.loadError),
      postcondition: (_, ok) => ok,
    ),
  ];
}

/// What mpv sends back, in its FIFO order.
sealed class _Item {}

/// The reply of the seek of a play() that claimed [intent], null for a
/// seek of no call that sets the intent.
final class _SeekReply extends _Item {
  _SeekReply(this.intent);
  final int? intent;
}

/// The reply of the playlist-play-index of a jump() that claimed [intent].
final class _JumpReply extends _Item {
  _JumpReply(this.intent);
  final int intent;
}

/// The reply of the loadfile of an open().
final class _LoadReply extends _Item {}

/// The end of that open(): what follows the reply runs after an await,
/// so the START_FILE of the load can come first.
final class _LoadEnd extends _Item {}

final class _StartFile extends _Item {}

final class _Restart extends _Item {}

final class _ParkRead extends _Item {}

/// The rig of transport_machine_test, with a jump and a load: every call
/// runs up to its command, and mpv queues the reply ahead of the events
/// of the move.
final class _Fifo {
  final TransportMachine m = TransportMachine()..startFile();
  final List<_Item> queue = [];
  bool intent = false;
  bool completed = false;

  /// Whether the core is at the end, ahead of what reached the player.
  bool parked = false;

  int _claim(bool value) {
    final (write, epoch) = m.claimIntent(value);
    intent = write.value;
    return epoch;
  }

  void _apply(List<TransportEffect> effects) {
    for (final e in effects) {
      if (e is WriteIntent) intent = e.value;
    }
  }

  void play(bool landsAtEnd) {
    final epoch = _claim(true);
    if (!parked) return;
    m.takePark();
    intent = true;
    queue.addAll([_SeekReply(epoch), _Restart(), if (landsAtEnd) _ParkRead()]);
    parked = landsAtEnd;
  }

  void pause() => _claim(false);

  void jump() {
    queue.addAll([_JumpReply(_claim(true)), _StartFile(), _Restart()]);
    parked = false;
  }

  /// [lateEnd]: the START_FILE of the load reaches the player before the
  /// open() returns.
  void open(bool shouldPlay, bool lateEnd) {
    m
      ..beginLoad()
      ..claimLoad();
    _claim(shouldPlay);
    queue.addAll([
      _LoadReply(),
      if (!lateEnd) _LoadEnd(),
      _StartFile(),
      if (lateEnd) _LoadEnd(),
      _Restart(),
    ]);
    parked = false;
  }

  void seekToEnd() {
    queue.addAll([_SeekReply(null), _Restart(), _ParkRead()]);
    parked = true;
  }

  void reachEnd() {
    queue.add(_ParkRead());
    parked = true;
  }

  void deliver() {
    switch (queue.removeAt(0)) {
      case _SeekReply(:final intent?) when m.wantsPlay(intent):
        m.takePark();
        this.intent = true;
      case _SeekReply():
        break;
      case _JumpReply(:final intent):
        m.takePark();
        if (m.wantsPlay(intent)) this.intent = true;
      case _LoadReply():
        m.takePark();
      case _LoadEnd():
        _apply(m.endLoad(completed: completed));
      case _StartFile():
        m.startFile();
        completed = false;
      case _Restart():
        m.restart();
        completed = false;
      case _ParkRead():
        completed = true;
        _apply(m.endOfContent());
    }
  }
}

/// The rule, apart from the machine: once mpv has said all it queued, the
/// intent is on exactly when the last call asked to play and the core is
/// not parked at the end.
final class _Spec {
  bool lastPlay = false;
  bool parked = false;

  /// What mpv still has to say, as the rig queues it: the environment, not
  /// the machine. A reply of a jump() is told from the rest.
  final List<bool> queue = [];
  int get queued => queue.length;
  bool get jumpOnItsWay => queue.contains(true);
  void add(int items, {bool jump = false}) =>
      queue.addAll([jump, for (var i = 1; i < items; i++) false]);

  bool get expected => lastPlay && !parked;
}

final class _FifoBehavior extends Behavior<_Spec, _Fifo> {
  _FifoBehavior({required this.playOverJump});

  /// Whether a play() may come before the reply of a jump().
  final bool playOverJump;

  @override
  _Spec initialState() => _Spec();

  @override
  _Fifo createSystem(_Spec s) => _Fifo();

  @override
  void destroySystem(_Fifo system) {}

  @override
  List<Command<_Spec, _Fifo>> generateCommands(_Spec s) => [
    Action(
      'play()',
      boolean(),
      precondition: (s, _) => playOverJump || !s.jumpOnItsWay,
      nextState: (s, landsAtEnd) {
        if (s.parked) {
          s.add(landsAtEnd ? 3 : 2);
          s.parked = landsAtEnd;
        }
        s.lastPlay = true;
      },
      run: (r, landsAtEnd) => r.play(landsAtEnd),
    ),
    Action0(
      'pause()',
      nextState: (s) => s.lastPlay = false,
      run: (r) => r.pause(),
    ),
    Action0(
      'jump()',
      nextState: (s) {
        s.add(3, jump: true);
        s.parked = false;
        s.lastPlay = true;
      },
      run: (r) => r.jump(),
    ),
    // Bit 0: play. Bit 1: the START_FILE comes before the open() returns.
    Action(
      'open(play)',
      integer(min: 0, max: 3),
      nextState: (s, how) {
        s.add(4);
        s.parked = false;
        s.lastPlay = how & 1 == 1;
      },
      run: (r, how) => r.open(how & 1 == 1, how >> 1 == 1),
    ),
    Action0(
      'a seek to the end',
      nextState: (s) {
        s.add(3);
        s.parked = true;
      },
      run: (r) => r.seekToEnd(),
    ),
    Action0(
      'playback reaches the end',
      precondition: (s) => s.lastPlay && !s.parked,
      nextState: (s) {
        s.add(1);
        s.parked = true;
      },
      run: (r) => r.reachEnd(),
    ),
    Action0(
      'mpv delivers all it queued',
      precondition: (s) => s.queued > 0,
      nextState: (s) => s.queue.clear(),
      run: (r) {
        while (r.queue.isNotEmpty) {
          r.deliver();
        }
        return r.intent;
      },
      postcondition: (s, got) => got == s.expected,
    ),
    Action0(
      'mpv delivers its next item',
      precondition: (s) => s.queued > 0,
      nextState: (s) => s.queue.removeAt(0),
      run: (r) {
        r.deliver();
        return r.queue.isEmpty ? r.intent : null;
      },
      // The state before the step: one item left is none after it.
      postcondition: (s, got) =>
          got == null || s.queued != 1 || got == s.expected,
    ),
  ];
}

void main() {
  property('no late answer undoes a pause(), and no event of the core '
      'turns the intent on', () {
    runBehavior(_CallsBehavior(), maxSteps: 80, maxCycles: 300);
  });

  property('with a jump and a load too, the intent ends as the rule says', () {
    runBehavior(
      _FifoBehavior(playOverJump: false),
      maxSteps: 60,
      maxCycles: 300,
    );
  });

  // jump() writes the intent on after the reply of its command while the
  // last call that claimed the intent played (wantsPlay(), as the reply of
  // the seek of play() since 0c37fc6). It asked owns() before: a play()
  // called before that reply owned the intent instead, and away from a
  // park it writes nothing after its claim. A read of the old park that
  // landed between the two spent the intent, and nothing took it back:
  // the entry of the jump played with the intent off.
  test('a play() before the reply of a jump() keeps the intent on', () {
    final r = _Fifo()
      ..play(false)
      ..reachEnd()
      ..jump()
      ..play(false);
    while (r.queue.isNotEmpty) {
      r.deliver();
    }
    expect(r.intent, isTrue);
  });

  test('the rigs write the intent after the reply of a jump() as jump() '
      'does', () {
    expect(
      _jumpSource(),
      contains(
        '_transport.takePark(); '
        'if (_transport.wantsPlay(intent)) _transport.writeIntent(true);',
      ),
    );
  });

  property('the same with a play() before the reply of a jump()', () {
    runBehavior(
      _FifoBehavior(playOverJump: true),
      maxSteps: 60,
      maxCycles: 300,
    );
  });

  // The cases the property above must reach, each by hand.
  group('a pause() has the last word', () {
    test('over the reply of the seek of a play() at the park', () {
      final c = _Calls()
        ..startFile()
        ..play()
        ..answer(0, true);
      expect(c.intent, isTrue);
      c
        ..pause()
        ..answer(0, false);
      expect(c.intent, isFalse);
      expect(c.sound, isTrue);
    });

    test('over the reads of a play() still on their way', () {
      final c = _Calls()
        ..startFile()
        ..play()
        ..pause()
        ..answer(0, true);
      expect(c.intent, isFalse);
      expect(c.waiting, isEmpty, reason: 'the play() wrote nothing more');
    });

    test('over the reply of a jump()', () {
      final c = _Calls()
        ..startFile()
        ..jump()
        ..answer(0, false)
        ..pause()
        ..answer(0, false);
      expect(c.intent, isFalse);
    });

    // The seek of the play() is still on its way when the pause() comes,
    // then a jump() claims the intent and gives it back: its index is out
    // of range. The reply of the seek must not take that for a play().
    test('over a jump() out of range and the reply of an earlier seek', () {
      final c = _Calls()
        ..startFile()
        ..play()
        ..answer(0, true)
        ..pause()
        ..jump()
        ..answer(1, true);
      expect(c.intent, isFalse, reason: 'the jump() put the pause back');
      c.answer(0, false);
      expect(c.intent, isFalse, reason: 'the reply of the seek of play()');
      expect(c.sound, isTrue);
    });

    test('the rig gives the intent back as jump() does', () {
      expect(
        _jumpSource(),
        contains(
          '_transport.restoreIntent(_transport.snapshotLoad(), intent, '
          'previous);',
        ),
      );
    });

    test('over a load that fails after it', () {
      final c = _Calls()
        ..startFile()
        ..play()
        ..open(true)
        ..pause()
        ..answer(1, true);
      expect(c.intent, isFalse, reason: 'the load no longer owns the intent');
    });
  });

  test('a failed load puts back the intent it replaced', () {
    final c = _Calls()
      ..startFile()
      ..play()
      ..answer(0, false)
      ..answer(0, false)
      ..open(false);
    expect(c.intent, isFalse);
    c.answer(0, true);
    expect(c.intent, isTrue);
    expect(c.sound, isTrue);
  });

  test('a park reached during a load that fails spends the intent it put '
      'back', () {
    final c = _Calls()
      ..startFile()
      ..play()
      ..answer(0, false)
      ..answer(0, false)
      ..open(true)
      ..endRead();
    expect(c.intent, isTrue, reason: 'the spend waits for the load');
    c.answer(0, true);
    expect(c.intent, isFalse);
  });

  test('a load that leaves the park keeps its intent', () {
    final r = _Fifo()
      ..play(false)
      ..reachEnd()
      ..open(true, false);
    while (r.queue.isNotEmpty) {
      r.deliver();
    }
    expect(r.intent, isTrue);
  });

  test('a jump() takes back the intent a late read of the park spent', () {
    final r = _Fifo()
      ..play(false)
      ..reachEnd()
      ..jump();
    r.deliver();
    expect(r.intent, isFalse, reason: 'the read of the old park');
    while (r.queue.isNotEmpty) {
      r.deliver();
    }
    expect(r.intent, isTrue);
  });
}
