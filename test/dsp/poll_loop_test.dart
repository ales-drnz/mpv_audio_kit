// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

// The poll loop the DSP pipelines share: its timer calls the pipeline's
// tick, and a poll does not start while the one before is in flight.

import 'dart:async';

import 'package:mpv_audio_kit/src/dsp/poll_loop.dart';
import 'package:test/test.dart';

void main() {
  const period = Duration(milliseconds: 5);

  test('a poll does not start while the one before runs', () async {
    var polls = 0;
    var reply = Completer<void>();
    final loop = PollLoop(() {}, () {
      polls++;
      return reply.future;
    });
    loop
      ..run()
      ..run();
    expect(polls, 1);
    reply.complete();
    await pumpEventQueue();
    reply = Completer<void>();
    loop.run();
    expect(polls, 2);
    reply.complete();
  });

  test('a poll that fails lets the next one start', () async {
    var polls = 0;
    final errors = <Object>[];
    final loop = PollLoop(() {}, () {
      polls++;
      return Future<void>.error(StateError('read failed'));
    });
    await runZonedGuarded(() async {
      loop.run();
      await pumpEventQueue();
      loop.run();
      await pumpEventQueue();
    }, (e, _) => errors.add(e));
    expect(polls, 2);
    expect(errors, hasLength(2));
  });

  test('the timer ticks until it is disarmed', () async {
    var ticks = 0;
    final loop = PollLoop(() => ticks++, () async {});
    expect(loop.isArmed, isFalse);
    loop.arm(period);
    expect(loop.isArmed, isTrue);
    await Future<void>.delayed(period * 6);
    expect(ticks, greaterThan(0));
    loop.disarm();
    expect(loop.isArmed, isFalse);
    final stopped = ticks;
    await Future<void>.delayed(period * 6);
    expect(ticks, stopped);
  });

  test('arm keeps a running timer, rearm replaces it', () async {
    var ticks = 0;
    final loop = PollLoop(() => ticks++, () async {})
      ..arm(const Duration(hours: 1))
      ..arm(period);
    await Future<void>.delayed(period * 6);
    expect(ticks, 0, reason: 'the second arm kept the first timer');
    loop.rearm(period);
    await Future<void>.delayed(period * 6);
    expect(ticks, greaterThan(0));
    loop.disarm();
  });
}
