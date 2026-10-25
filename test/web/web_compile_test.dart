// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// The package compiles for the browser with every web compiler: DDC (the
// default of `flutter test --platform chrome`, which cannot isolate the
// page and so runs no core here), dart2wasm (`--wasm`), and through DDC
// the JavaScript number rules dart2js shares (no integer literal beyond
// 2^53). The runtime suites of test/web need `--wasm`.

@TestOn('browser')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

void main() {
  test('the package compiles for the browser', () {
    expect(const PlayerState().playing, isFalse);
    expect(ApadEffect.padLenMax, greaterThan(9007199254740991 ~/ 2));
  });
}
