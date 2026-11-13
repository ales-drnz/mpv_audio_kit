// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// The view MpvModule reads the memory through is kept between reads and
// made again when the memory grows: a growth replaces the buffer, and a
// view of the old one reads nothing (it is detached) or misses what lies
// past its end. On a stand-in for the module, whose memory grows on demand
// (flutter test --platform chrome --wasm).

@TestOn('browser')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/src/backend/web/mpv_module.dart';

import 'fake_module.dart';

void main() {
  test('reads and writes follow the memory through a growth', () {
    final fake = FakeModule();
    final module = MpvModule(fake.instance);
    module.setU32(8192, 0xdeadbeef);
    expect(module.u32(8192), 0xdeadbeef);
    final before = fake.bytes.length;
    fake.grow(1);
    // What was written is still there, and the new page is in reach.
    expect(module.u32(8192), 0xdeadbeef);
    module.setF64(before + 16, 1.5);
    expect(module.f64(before + 16), 1.5);
    module.setI64(before + 32, -5);
    expect(module.i64(before + 32), -5);
    expect(fake.bytes[8192], 0xef);
  });
}
