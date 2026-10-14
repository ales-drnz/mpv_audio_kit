// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

// The filter tap's active list against a fake mpv, with no libmpv loaded.

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
}
