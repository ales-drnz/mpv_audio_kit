// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

void main() {
  const a = CacheRange(Duration(seconds: 1), Duration(seconds: 4));

  test('equal ranges are equal and hash alike', () {
    const b = CacheRange(Duration(seconds: 1), Duration(seconds: 4));
    expect(b, a);
    expect(b.hashCode, a.hashCode);
    expect(<CacheRange>{}..addAll([a, b]), hasLength(1));
  });

  test('a different start or end is a different range', () {
    expect(const CacheRange(Duration.zero, Duration(seconds: 4)), isNot(a));
    expect(
      const CacheRange(Duration(seconds: 1), Duration(seconds: 5)),
      isNot(a),
    );
  });

  test('toString shows both ends', () {
    expect(a.toString(), contains('0:00:01'));
    expect(a.toString(), contains('0:00:04'));
  });
}
