// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

// TransportMachine, the transport axis of a player, on random sequences of
// calls and of what mpv sends back, in its FIFO order (kiri_check). The
// rule the intent must end on is written apart from the machine (_Spec):
// once mpv has said all, the intent is on exactly when the last call was
// play() and the core is not parked at the end. A second behavior checks
// the machine alone: no park generation spends twice, none while a load
// runs, and no event writes the intent on.

import 'package:kiri_check/kiri_check.dart';
import 'package:kiri_check/stateful_test.dart';
import 'package:mpv_audio_kit/src/internals/transport_machine.dart';
import 'package:test/test.dart';

/// What mpv sends back, in its FIFO order: the reply of a command, then
/// the restart of the move it causes, then the read of a park when the
/// move lands on the end.
sealed class _Item {}

final class _Reply extends _Item {
  _Reply(this.intent);

  /// The intent epoch of the play() that sent the command, null for a
  /// command of no call that sets the intent.
  final int? intent;
}

final class _Restart extends _Item {}

final class _ParkRead extends _Item {}

/// The machine behind a player that plays, pauses and seeks, as the rules
/// of e984aef and 0c37fc6 state them: play() at a park takes the park and
/// writes the intent on before its seek, and again after the reply of the
/// seek while it owns the intent; mpv queues that reply ahead of the
/// seek's restart, and the read of the park after it.
final class _Rig {
  final TransportMachine m = TransportMachine()..startFile();
  final List<_Item> queue = [];
  bool intent = false;

  /// Whether the core is at the end, ahead of what reached the player.
  bool parked = false;

  void _apply(List<TransportEffect> effects) {
    for (final e in effects) {
      if (e is WriteIntent) intent = e.value;
    }
  }

  /// [lateRead]: the read of the park the pump sent, which play() did not
  /// wait for (it reads the core itself), lands between the reply of the
  /// seek and its restart, still in the generation the seek leaves. A read
  /// not yet delivered moves there; one delivered comes again.
  void play(bool landsAtEnd, bool lateRead) {
    final (write, epoch) = m.claimIntent(true);
    intent = write.value;
    if (!parked) return;
    m.takePark();
    intent = true;
    if (lateRead) {
      final pending = queue.lastIndexWhere((i) => i is _ParkRead);
      if (pending >= 0) queue.removeAt(pending);
    }
    queue.addAll([
      _Reply(epoch),
      if (lateRead) _ParkRead(),
      _Restart(),
      if (landsAtEnd) _ParkRead(),
    ]);
    parked = landsAtEnd;
  }

  void pause() => intent = m.claimIntent(false).$1.value;

  void seekToEnd() {
    queue.addAll([_Reply(null), _Restart(), _ParkRead()]);
    parked = true;
  }

  void reachEnd() {
    queue.add(_ParkRead());
    parked = true;
  }

  void deliver() {
    switch (queue.removeAt(0)) {
      case _Reply(:final intent?) when m.owns(intent):
        m.takePark();
        this.intent = true;
      case _Reply():
        break;
      case _Restart():
        m.restart();
      case _ParkRead():
        _apply(m.endOfContent());
    }
  }
}

/// The rule the player owes the app, written apart from the machine: once
/// mpv has said all it queued, the intent is on exactly when the last
/// call was play() and the core is not parked at the end.
final class _Spec {
  bool lastPlay = false;
  bool parked = false;

  /// What mpv still has to say, as the rig queues it: the environment, not
  /// the machine.
  final List<String> queue = [];
  int get queued => queue.length;

  bool get expected => lastPlay && !parked;
}

final class _Behavior extends Behavior<_Spec, _Rig> {
  @override
  _Spec initialState() => _Spec();

  @override
  _Rig createSystem(_Spec s) => _Rig();

  @override
  void destroySystem(_Rig system) {}

  /// The intent once the queue is empty, or null while mpv has more to say.
  static bool? _settled(_Rig r) => r.queue.isEmpty ? r.intent : null;

  @override
  List<Command<_Spec, _Rig>> generateCommands(_Spec s) => [
    // Bit 0: the seek lands on the end again. Bit 1: a read of the park
    // lands between the reply of the seek and its restart.
    // A second play() before the reply of the first is left out: the
    // first then owns the intent no more, and a park read of a seek to the
    // end queued before it spends the intent while the seek of the first
    // play() plays (a seek to the end, play(), play(), then mpv delivers).
    // That is the behavior of 0.6.2 as of e984aef and 0c37fc6, an open
    // proposal, not a rule of this test.
    Action(
      'play()',
      integer(min: 0, max: 3),
      precondition: (s, _) => !s.queue.contains('play-reply'),
      nextState: (s, how) {
        if (s.parked) {
          final late = how >> 1 == 1;
          if (late) {
            final pending = s.queue.lastIndexOf('park');
            if (pending >= 0) s.queue.removeAt(pending);
          }
          s.queue.addAll([
            'play-reply',
            if (late) 'park',
            'restart',
            if (how & 1 == 1) 'park',
          ]);
          s.parked = how & 1 == 1;
        }
        s.lastPlay = true;
      },
      run: (r, how) {
        r.play(how & 1 == 1, how >> 1 == 1);
        return r.queue.isEmpty ? r.intent : null;
      },
      // At a park the seek is still queued; elsewhere play() is an
      // unpause, and the intent is on at once.
      postcondition: (s, _, got) => got == null || got,
    ),
    Action0(
      'pause()',
      nextState: (s) => s.lastPlay = false,
      run: (r) {
        r.pause();
        return _settled(r);
      },
      postcondition: (s, got) => got == null || got == false,
    ),
    Action0(
      'a seek to the end',
      nextState: (s) {
        s.queue.addAll(['reply', 'restart', 'park']);
        s.parked = true;
      },
      run: (r) => r.seekToEnd(),
    ),
    Action0(
      'playback reaches the end',
      precondition: (s) => s.lastPlay && !s.parked,
      nextState: (s) {
        s.queue.add('park');
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
        return _settled(r);
      },
      postcondition: (s, got) {
        // The state before the step: one item fewer is the queue after it.
        return got == null || s.queued != 1 || got == s.expected;
      },
    ),
  ];
}

void main() {
  property('the intent ends as the rule says, whatever mpv delivers first', () {
    runBehavior(_Behavior(), maxSteps: 60, maxCycles: 400);
  });

  property('no event spends the intent twice in one park generation', () {
    runBehavior(_InvariantBehavior(), maxSteps: 60, maxCycles: 400);
  });

  test('a read of the park that lands after the reply of play() spends '
      'nothing', () {
    final r = _Rig()
      ..play(false, false)
      ..reachEnd()
      ..play(false, true);
    while (r.queue.isNotEmpty) {
      r.deliver();
    }
    expect(r.intent, isTrue);
  });

  test('a call that leaves the park keeps the intent of its end', () {
    final m = TransportMachine()..startFile();
    m.takePark();
    expect(m.endOfContent(), isEmpty);
    m.restart();
    expect(m.endOfContent(), [WriteIntent.off]);
    expect(m.endOfContent(), isEmpty);
  });

  test('a spend during a load waits for it, and goes in the same park', () {
    final m = TransportMachine()..startFile();
    m.beginLoad();
    expect(m.endOfContent(), isEmpty);
    expect(m.endLoad(completed: true), [WriteIntent.off]);

    m.beginLoad();
    expect(m.endOfContent(), isEmpty);
    m.startFile();
    expect(m.endLoad(completed: true), isEmpty);
  });

  test('an idle core during a load asks the core when the loads end', () {
    final m = TransportMachine()..startFile();
    m.beginLoad();
    expect(m.idleActive(true), [SettleIdle.effect, ClearFinishedFile.effect]);
    expect(m.endLoad(completed: false), [ReadIdle.effect]);
    expect(m.idleRead(idle: true), [WriteIntent.off]);
    expect(m.idleRead(idle: true), isEmpty);
  });

  test('the startup idle burst keeps the intent', () {
    final m = TransportMachine();
    expect(m.idleActive(true), [SettleIdle.effect]);
  });

  test('a later call owns the intent', () {
    final m = TransportMachine();
    final (_, first) = m.claimIntent(true);
    final load = m.claimLoad();
    expect(m.restoreIntent(load, first, false), WriteIntent.off);
    final (_, second) = m.claimIntent(false);
    expect(m.owns(first), isFalse);
    expect(m.owns(second), isTrue);
    expect(m.restoreIntent(load, first, false), isNull);
    expect(m.intendedPlay(first, true, current: false), isFalse);
    expect(m.intendedPlay(second, true, current: false), isTrue);
  });
}

/// The machine alone: whatever the sequence, the intent of a park
/// generation is spent once at most, never while a load runs, and no
/// event writes it on.
final class _InvariantBehavior extends Behavior<_Count, TransportMachine> {
  @override
  _Count initialState() => _Count();

  @override
  TransportMachine createSystem(_Count s) => TransportMachine();

  @override
  void destroySystem(TransportMachine system) {}

  @override
  List<Command<_Count, TransportMachine>> generateCommands(_Count s) => [
    Action0('START_FILE', nextState: (_) {}, run: (m) => m.startFile()),
    Action0('PLAYBACK_RESTART', nextState: (_) {}, run: (m) => m.restart()),
    Action0('take', nextState: (_) {}, run: (m) => m.takePark()),
    Action0(
      'end of content',
      nextState: (_) {},
      run: (m) {
        final park = m.park;
        final loads = m.loadsInFlight;
        final effects = m.endOfContent();
        return (park, loads, effects);
      },
      postcondition: (s, r) {
        final (park, loads, effects) = r;
        final spent = effects.whereType<WriteIntent>().length;
        if (spent == 0) return true;
        if (loads > 0 || effects.any((e) => e == WriteIntent.on)) {
          return false;
        }
        return s.spentParks.add(park);
      },
    ),
    Action(
      'idle',
      boolean(),
      nextState: (_, _) {},
      run: (m, idle) {
        final effects = m.idleActive(idle);
        return effects.every((e) => e != WriteIntent.on);
      },
      postcondition: (_, _, ok) => ok,
    ),
    Action0('load', nextState: (_) {}, run: (m) => m.beginLoad()),
    Action(
      'load ends',
      boolean(),
      precondition: (_, _) => true,
      nextState: (_, _) {},
      run: (m, completed) {
        if (m.loadsInFlight == 0) return (m.park, <TransportEffect>[]);
        final park = m.park;
        return (park, m.endLoad(completed: completed));
      },
      postcondition: (s, _, r) {
        final (park, effects) = r;
        if (effects.any((e) => e == WriteIntent.on)) return false;
        if (effects.whereType<WriteIntent>().isEmpty) return true;
        return s.spentParks.add(park);
      },
    ),
    Action(
      'read',
      boolean(),
      nextState: (_, _) {},
      run: (m, idle) {
        return m.idleRead(idle: idle).every((e) => e != WriteIntent.on);
      },
      postcondition: (_, _, ok) => ok,
    ),
  ];
}

final class _Count {
  final Set<int> spentParks = {};
}
