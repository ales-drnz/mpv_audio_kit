// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// The sequencer of the web pump, without libmpv: a script stands for mpv's
// queue, and the reads of an event complete when the test says.

import 'dart:async';
import 'dart:collection';

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/src/internals/event_sequencer.dart';

/// One scripted event: its name, and the reads it takes (none when null).
typedef _Event = (String name, Completer<void>? reads);

/// mpv's queue as a script, and a log of what the sequencer did.
final class _Queue {
  final Queue<_Event> events = Queue();
  final List<String> log = [];
  double? holdSeconds;
  Object? throwOn;

  EventSequencer? sequencerOverride;
  EventSequencer get sequencer => sequencerOverride ?? _sequencer;
  late final EventSequencer _sequencer = EventSequencer(
    take: take,
    flushTrailing: () => log.add('flush'),
    waitSeconds: () => holdSeconds,
    onError: (e, _) => log.add('error $e'),
  );

  TakenEvent take() {
    if (events.isEmpty) return (false, null, false);
    final (name, reads) = events.removeFirst();
    log.add('take $name');
    if (name == throwOn) throw StateError(name);
    return (true, reads?.future, name == 'shutdown');
  }
}

void main() {
  test('takes every event in order, flushing after each and at the end', () {
    final q = _Queue()..events.addAll([('a', null), ('b', null)]);
    q.sequencer.pump();
    expect(q.log, ['take a', 'flush', 'take b', 'flush', 'flush']);
  });

  test(
    'with an empty queue the reads of idle come before the next take',
    () async {
      final due = Completer<void>();
      final log = <String>[];
      final events = Queue<String>()..add('a');
      Future<void>? idleReads = due.future;
      late final EventSequencer sequencer;
      sequencer = EventSequencer(
        take: () {
          if (events.isEmpty) return (false, null, false);
          log.add('take ${events.removeFirst()}');
          return (true, null, false);
        },
        flushTrailing: () => log.add('flush'),
        waitSeconds: () => null,
        onError: (e, _) => log.add('error $e'),
        idle: () {
          log.add('idle');
          final reads = idleReads;
          idleReads = null;
          return reads;
        },
      );
      sequencer.pump();
      expect(log, ['take a', 'flush', 'idle']);
      expect(sequencer.stepping, isTrue);
      events.add('b');
      sequencer.pump();
      expect(log, ['take a', 'flush', 'idle'], reason: 'b waits for the reads');
      due.complete();
      await pumpEventQueue();
      expect(log, [
        'take a',
        'flush',
        'idle',
        'flush',
        'take b',
        'flush',
        'idle',
      ]);
    },
  );

  test('takes nothing while the reads of an event are in flight', () async {
    final reads = Completer<void>();
    final q = _Queue()..events.addAll([('loaded', reads), ('next', null)]);
    q.sequencer.pump();
    expect(q.log, ['take loaded']);
    expect(q.sequencer.stepping, isTrue);
    // Wakeups meanwhile take nothing: the next event stays in the queue.
    q.sequencer.pump();
    q.sequencer.pump();
    expect(q.log, ['take loaded']);
    expect(q.events.single.$1, 'next');
    reads.complete();
    await pumpEventQueue();
    expect(q.log, ['take loaded', 'flush', 'take next', 'flush', 'flush']);
    expect(q.sequencer.stepping, isFalse);
  });

  test('an event that arrives during the reads comes after them', () async {
    final reads = Completer<void>();
    final q = _Queue()..events.add(('loaded', reads));
    q.sequencer.pump();
    q.events.add(('late', null));
    q.sequencer.pump();
    expect(q.log, ['take loaded']);
    reads.complete();
    await pumpEventQueue();
    expect(q.log.indexOf('take late'), greaterThan(q.log.indexOf('flush')));
  });

  test('an event that throws is reported and the next one is taken', () {
    final q = _Queue()
      ..throwOn = 'bad'
      ..events.addAll([('bad', null), ('good', null)]);
    q.sequencer.pump();
    expect(q.log, [
      'take bad',
      'error Bad state: bad',
      'take good',
      'flush',
      'flush',
    ]);
  });

  test('reads that fail are reported, with no flush for that event', () async {
    final reads = Completer<void>();
    final q = _Queue()..events.addAll([('loaded', reads), ('next', null)]);
    q.sequencer.pump();
    reads.completeError(StateError('read'));
    await pumpEventQueue();
    expect(q.log, [
      'take loaded',
      'error Bad state: read',
      'take next',
      'flush',
      'flush',
    ]);
  });

  test('the last event stops the sequencer', () {
    final q = _Queue()..events.addAll([('shutdown', null), ('after', null)]);
    q.sequencer.pump();
    expect(q.log, ['take shutdown', 'flush']);
    expect(q.sequencer.stopped, isTrue);
    q.sequencer.pump();
    expect(q.log, ['take shutdown', 'flush']);
  });

  test('a stop during the reads takes nothing after them', () async {
    final reads = Completer<void>();
    final q = _Queue()..events.addAll([('loaded', reads), ('next', null)]);
    q.sequencer.pump();
    q.sequencer.stop();
    reads.complete();
    await pumpEventQueue();
    expect(q.log, ['take loaded']);
  });

  test('a held value is flushed when its window closes', () async {
    final q = _Queue()
      ..holdSeconds = 0.01
      ..events.add(('a', null));
    q.sequencer.pump();
    expect(q.log, ['take a', 'flush', 'flush']);
    q.holdSeconds = null;
    await Future<void>.delayed(const Duration(milliseconds: 60));
    // The timer pumped again: the queue was empty, so it flushed.
    expect(q.log, ['take a', 'flush', 'flush', 'flush']);
  });

  test('a wakeup during take is served by the same loop, never nested', () {
    final q = _Queue();
    var depth = 0;
    var deepest = 0;
    final sequencer = EventSequencer(
      take: () {
        depth++;
        if (depth > deepest) deepest = depth;
        try {
          final taken = q.take();
          // The web module can run a posted wakeup in the middle of a call:
          // here, one that announces an event queued meanwhile.
          if (q.log.length == 1) {
            q.events.add(('late', null));
            q.sequencer.pump();
          }
          return taken;
        } finally {
          depth--;
        }
      },
      flushTrailing: () => q.log.add('flush'),
      waitSeconds: () => null,
      onError: (e, _) => q.log.add('error $e'),
    );
    q.sequencerOverride = sequencer;
    q.events.add(('first', null));
    sequencer.pump();
    expect(deepest, 1);
    expect(q.log, ['take first', 'flush', 'take late', 'flush', 'flush']);
  });

  test('no timer while nothing is held', () async {
    final q = _Queue()..events.add(('a', null));
    q.sequencer.pump();
    await Future<void>.delayed(const Duration(milliseconds: 40));
    expect(q.log, ['take a', 'flush', 'flush']);
  });
}
