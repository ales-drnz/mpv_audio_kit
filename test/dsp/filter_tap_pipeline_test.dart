// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

// The filter tap's active list against a fake mpv, with no libmpv loaded.

import 'dart:async';

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
}
