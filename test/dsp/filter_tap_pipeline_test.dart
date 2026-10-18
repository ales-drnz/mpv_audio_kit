// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

// The filter tap's active list and poll against a fake mpv, with no libmpv
// loaded.

import 'dart:async';
import 'dart:typed_data';

import 'package:mpv_audio_kit/src/dsp/filter_tap_pipeline.dart';
import 'package:test/test.dart';

void main() {
  test('analyzer-taps follows the listened labels', () async {
    final sets = <String>[];
    final p = FilterTapPipeline(
      asyncGet: (name, format) async => (-10, null),
      asyncSet: (name, value) async {
        sets.add('$name=$value');
        return 0;
      },
      pollInterval: const Duration(milliseconds: 5),
    );
    final pre = p.tapPre('aek_equalizer_0').listen((_) {});
    final pre2 = p.tapPre('aek_equalizer_0').listen((_) {});
    final post = p.tapPost('aek_equalizer_0').listen((_) {});
    final other = p.tapPost('aek_volume_0').listen((_) {});
    expect(sets, [
      'analyzer-taps=aek_equalizer_0',
      'analyzer-taps=aek_equalizer_0,aek_volume_0',
    ]);
    sets.clear();
    await pre.cancel();
    expect(sets, isEmpty, reason: 'a second pre listener is left');
    await pre2.cancel();
    await other.cancel();
    expect(sets, ['analyzer-taps=aek_equalizer_0']);
    await post.cancel();
    expect(sets.last, 'analyzer-taps=');
    await p.dispose();
  });

  test('dispose finishes with a paused listener', () async {
    final p = FilterTapPipeline(
      asyncGet: (name, format) async => (-10, null),
      asyncSet: (name, value) async => 0,
      pollInterval: const Duration(milliseconds: 5),
    );
    final done = Completer<void>();
    final sub = p
        .tapPost('aek_equalizer_0')
        .listen((_) {}, onDone: done.complete);
    sub.pause();
    // A paused listener takes the done only when it resumes: waiting for
    // it would hold the player's dispose, and its quit, forever.
    await p.dispose().timeout(const Duration(seconds: 1));
    expect(done.isCompleted, isFalse);
    sub.resume();
    await done.future.timeout(const Duration(seconds: 1));
    await sub.cancel();
  });

  test('a slice the playback position moved is emitted', () async {
    // The chain writes the ring once per decoded frame (about 104 ms with
    // a FLAC), while the slice follows the playback position: `seq` stays
    // the same over several polls whose `pts_ns` moved on.
    var ptsNs = 1000000000;
    Map<String, Object?> node() => {
      'aek_equalizer_0': {
        'post': {
          'seq': 7,
          'pts_ns': ptsNs,
          'sample_rate': 48000,
          'channels': 2,
          'samples': Uint8List(64),
        },
      },
    };
    final p = FilterTapPipeline(
      asyncGet: (name, format) async => (0, node()),
      asyncSet: (name, value) async => 0,
      pollInterval: const Duration(milliseconds: 5),
    );
    final got = <Duration>[];
    final sub = p
        .tapPost('aek_equalizer_0')
        .listen((f) => got.add(f.timestamp));
    Future<void> polls() =>
        Future<void>.delayed(const Duration(milliseconds: 40));
    await polls();
    expect(got, hasLength(1), reason: 'an unchanged slice is emitted once');
    for (var i = 0; i < 2; i++) {
      ptsNs += 33000000;
      await polls();
    }
    expect(got, [
      const Duration(microseconds: 1000000),
      const Duration(microseconds: 1033000),
      const Duration(microseconds: 1066000),
    ]);
    await sub.cancel();
    await p.dispose();
  });

  test('no read while the core is idle, the poll comes back after', () async {
    // F41: paused or stopped, the ring and the playback position stand
    // still. A new listener still gets one read, the slice held now.
    var gets = 0;
    final p = FilterTapPipeline(
      asyncGet: (name, format) async {
        gets++;
        return (-10, null);
      },
      asyncSet: (name, value) async => 0,
      pollInterval: const Duration(milliseconds: 5),
    )..setIdle(true);
    final sub = p.tapPost('aek_idle_0').listen((_) {});
    // The labels are a static of the isolate: a failure must not leave
    // this one to the tests that follow.
    addTearDown(() async {
      await sub.cancel();
      await p.dispose();
    });
    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(gets, 1, reason: 'one read for the new listener, then none');
    p.setIdle(false);
    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(gets, greaterThan(3), reason: 'it polls again');
    p.setIdle(true);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    gets = 0;
    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(gets, 0, reason: 'idle, it read $gets times');
  });

  group('two players', () {
    // analyzer-taps is a static of the libmpv process: each player writes
    // it through its own core, and a write replaces the whole list.
    final sets = <String>[];
    FilterTapPipeline player(String who, {Future<int>? reply}) =>
        FilterTapPipeline(
          asyncGet: (name, format) async => (-10, null),
          asyncSet: (name, value) {
            sets.add('$who $value');
            return reply ?? Future.value(0);
          },
          pollInterval: const Duration(milliseconds: 5),
        );
    Future<void> settle() =>
        Future<void>.delayed(const Duration(milliseconds: 5));

    setUp(sets.clear);

    test('one player keeps its taps when another taps or goes', () async {
      final a = player('A');
      final b = player('B');
      final eq = a.tapPre('aek_equalizer_0').listen((_) {});
      await settle();
      final bass = b.tapPost('aek_bass_0').listen((_) {});
      await settle();
      expect(sets.last, 'B aek_equalizer_0,aek_bass_0');
      // B goes with its listener still attached.
      await b.dispose();
      await settle();
      expect(sets.last, 'B aek_equalizer_0');
      await bass.cancel();
      await eq.cancel();
      await settle();
      expect(sets.last, 'A ');
      await a.dispose();
      await settle();
      expect(sets.last, 'A ', reason: 'nothing left to write');
    });

    test('a write joins the core already writing', () async {
      // A's core is busy (an audio output opening): B's list must not
      // land before A's.
      final reply = Completer<int>();
      final a = player('A', reply: reply.future);
      final b = player('B');
      final eq = a.tapPre('aek_equalizer_0').listen((_) {});
      final bass = b.tapPost('aek_bass_0').listen((_) {});
      expect(sets, ['A aek_equalizer_0', 'A aek_equalizer_0,aek_bass_0']);
      reply.complete(0);
      await settle();
      await bass.cancel();
      expect(sets.last, 'B aek_equalizer_0');
      await eq.cancel();
      await a.dispose();
      await b.dispose();
      await settle();
      expect(sets.last, 'A ');
    });
  });
}
