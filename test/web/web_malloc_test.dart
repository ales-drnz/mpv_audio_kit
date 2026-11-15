// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// The module's memory has a ceiling, and its malloc returns NULL past it.
// Nothing is then written at address 0: the allocation throws, a PCM write
// answers out of memory as the native one does, and a command resolves
// with mpv's MPV_ERROR_NOMEM. On a stand-in for the module, whose malloc
// can be made to fail (flutter test --platform chrome --wasm).

@TestOn('browser')
library;

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/src/backend/web/mpv_module.dart';
import 'package:mpv_audio_kit/src/backend/web/web_client.dart';
import 'package:mpv_audio_kit/src/backend/web/web_pcm.dart';
import 'package:mpv_audio_kit/src/mpv_constants.dart';
import 'package:mpv_audio_kit/src/pcm/pcm_native.dart';

import 'fake_module.dart';

final Matcher _outOfMemory = throwsA(
  isA<StateError>().having(
    (e) => e.message,
    'message',
    contains('out of memory'),
  ),
);

void main() {
  test('malloc and newString throw when the module has no memory left', () {
    final fake = FakeModule()..allocationsLeft = 0;
    final module = MpvModule(fake.instance);
    expect(() => module.malloc(64), _outOfMemory);
    expect(() => module.newString('volume'), _outOfMemory);
  });

  test('withStrings frees the strings made before the one that failed', () {
    final fake = FakeModule()..allocationsLeft = 1;
    final module = MpvModule(fake.instance);
    expect(
      () => module.withStrings(['volume', '50'], (p) => fail('ran')),
      _outOfMemory,
    );
    expect(fake.allocated, hasLength(1));
    expect(fake.freed, fake.allocated);
  });

  test('a PCM write answers out of memory and leaves address 0 alone', () {
    final fake = FakeModule()..allocationsLeft = 0;
    final pcm = WebPcmNative(MpvModule(fake.instance));
    final rc = pcm.write(1, Uint8List.fromList(List.filled(32, 0xff)));
    expect(rc, PcmNative.errNoMemory);
    expect(fake.bytes.sublist(0, 32), everyElement(0));
    expect(fake.calls, isNot(contains('_mak_pcm_write')));
  });

  test('a command resolves with MPV_ERROR_NOMEM, and the writes '
      'settle', () async {
    final fake = FakeModule();
    final client = WebClient(MpvModule(fake.instance), 1);
    // The two strings fit, the argv array does not.
    fake.allocationsLeft = 2;
    final (error, result) = await client.command(['seek', '10']);
    expect(error, MpvError.mpvErrorNomem);
    expect(result, isNull);
    expect(fake.calls, isNot(contains('_mpv_command_async')));
    expect(fake.bytes.sublist(0, 16), everyElement(0));
    expect(fake.freed, fake.allocated);
    await client.settleWrites().timeout(const Duration(seconds: 2));
  });
}
