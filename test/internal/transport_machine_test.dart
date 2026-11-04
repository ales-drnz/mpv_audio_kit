// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

// TransportMachine, the transport axis of a player, against a model of its
// rules on random sequences of events and calls (kiri_check). The model
// keeps the set of the park generations that spent or gave away the
// intent, where the machine keeps the last one only: the two agree only if
// no rule ever asks about an older generation.

import 'package:kiri_check/kiri_check.dart';
import 'package:kiri_check/stateful_test.dart';
import 'package:mpv_audio_kit/src/internals/transport_machine.dart';
import 'package:test/test.dart';

/// The rules, written from their description.
final class _Model {
  int park = 0;
  bool started = false;
  final Set<int> settled = {};
  int loads = 0;
  int? waiting;
  bool idleReset = false;

  /// Every intent write of an event so far, by the generation it was in.
  final Map<int, int> spends = {};

  List<TransportEffect> endOfContent() {
    if (settled.contains(park)) return [];
    if (loads > 0) {
      waiting = park;
      return [];
    }
    settled.add(park);
    return [WriteIntent.off];
  }

  List<TransportEffect> idleActive(bool idle) {
    if (!idle) {
      idleReset = false;
      return [];
    }
    if (!started) return [SettleIdle.effect];
    if (loads > 0) {
      idleReset = true;
      return [SettleIdle.effect, ClearFinishedFile.effect];
    }
    return [SettleIdle.effect, WriteIntent.off, ClearFinishedFile.effect];
  }

  List<TransportEffect> endLoad(bool completed) {
    loads--;
    if (loads > 0) return [];
    final w = waiting;
    waiting = null;
    return [
      if (w == park && !settled.contains(park) && completed) WriteIntent.off,
      if (idleReset) ReadIdle.effect,
    ];
  }

  /// Applies the side of [endLoad] the effects do not show.
  void afterEndLoad(List<TransportEffect> effects) {
    if (effects.whereType<WriteIntent>().isNotEmpty) settled.add(park);
  }

  List<TransportEffect> idleRead(bool idle) {
    if (!idleReset || loads > 0) return [];
    idleReset = false;
    return [if (idle) WriteIntent.off];
  }
}

final class _Behavior extends Behavior<_Model, TransportMachine> {
  @override
  _Model initialState() => _Model();

  @override
  TransportMachine createSystem(_Model s) => TransportMachine();

  @override
  void destroySystem(TransportMachine system) {}

  /// The model's expected effects for one step, computed on a copy so the
  /// postcondition sees the state before the step.
  bool _same(List<TransportEffect> got, List<TransportEffect> want) {
    if (got.length != want.length) return false;
    for (var i = 0; i < got.length; i++) {
      if (got[i] != want[i]) return false;
    }
    return true;
  }

  static _Model _copy(_Model s) => _Model()
    ..park = s.park
    ..started = s.started
    ..settled.addAll(s.settled)
    ..loads = s.loads
    ..waiting = s.waiting
    ..idleReset = s.idleReset;

  @override
  List<Command<_Model, TransportMachine>> generateCommands(_Model s) => [
    Action0(
      'START_FILE',
      nextState: (s) {
        s.park++;
        s.started = true;
      },
      run: (m) {
        m.startFile();
        return m.park;
      },
      postcondition: (s, park) => park == s.park + 1,
    ),
    Action0(
      'PLAYBACK_RESTART',
      nextState: (s) => s.park++,
      run: (m) {
        m.restart();
        return m.park;
      },
      postcondition: (s, park) => park == s.park + 1,
    ),
    Action0(
      'a call leaves the park',
      nextState: (s) => s.settled.add(s.park),
      run: (m) => m.takePark(),
    ),
    Action0(
      'end of content',
      nextState: (s) {
        final effects = s.endOfContent();
        if (effects.isNotEmpty) s.spends[s.park] = (s.spends[s.park] ?? 0) + 1;
      },
      run: (m) => m.endOfContent(),
      postcondition: (s, got) => _same(got, _copy(s).endOfContent()),
    ),
    Action(
      'idle-active',
      boolean(),
      nextState: (s, idle) => s.idleActive(idle),
      run: (m, idle) => m.idleActive(idle),
      postcondition: (s, idle, got) => _same(got, _copy(s).idleActive(idle)),
    ),
    Action0(
      'a load starts',
      nextState: (s) => s.loads++,
      run: (m) {
        m.claimLoad();
        m.beginLoad();
        return m.loadsInFlight;
      },
      postcondition: (s, loads) => loads == s.loads + 1,
    ),
    Action(
      'a load ends',
      boolean(),
      precondition: (s, _) => s.loads > 0,
      nextState: (s, completed) {
        final effects = s.endLoad(completed);
        s.afterEndLoad(effects);
        if (effects.whereType<WriteIntent>().isNotEmpty) {
          s.spends[s.park] = (s.spends[s.park] ?? 0) + 1;
        }
      },
      run: (m, completed) => m.endLoad(completed: completed),
      postcondition: (s, completed, got) =>
          _same(got, _copy(s).endLoad(completed)),
    ),
    Action(
      'the core answers idle-active',
      boolean(),
      nextState: (s, idle) => s.idleRead(idle),
      run: (m, idle) => m.idleRead(idle: idle),
      postcondition: (s, idle, got) => _same(got, _copy(s).idleRead(idle)),
    ),
    Action(
      'a call sets the intent',
      boolean(),
      nextState: (s, _) {},
      run: (m, value) => m.claimIntent(value).$1,
      postcondition: (s, value, got) => got.value == value,
    ),
  ];
}

void main() {
  property('the machine follows the model of its rules', () {
    runBehavior(_Behavior(), maxSteps: 60, maxCycles: 400);
  });

  property('no event spends the intent twice in one park generation', () {
    runBehavior(_InvariantBehavior(), maxSteps: 60, maxCycles: 400);
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
