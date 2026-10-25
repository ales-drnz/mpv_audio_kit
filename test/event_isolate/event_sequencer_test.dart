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

  late final EventSequencer sequencer = EventSequencer(
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

  test('no timer while nothing is held', () async {
    final q = _Queue()..events.add(('a', null));
    q.sequencer.pump();
    await Future<void>.delayed(const Duration(milliseconds: 40));
    expect(q.log, ['take a', 'flush', 'flush']);
  });
}
