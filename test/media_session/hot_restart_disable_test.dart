// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// A Hot Restart keeps the engine and its plugins, so the OS media session
// the old VM enabled stays on: notification, lock screen and audio focus,
// still "playing" the old track, with no listener left for its buttons
// (F189). The new VM's MpvAudioKit.ensureInitialized turns it off. This
// file is a process of its own: the old VM is the tracker buffer published
// in the process environment before the init, as a Hot Restart leaves it.

@TestOn('mac-os || linux || windows')
library;

import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:mpv_audio_kit/src/internals/orphan_handle_tracker.dart';

const _channel = MethodChannel('mpv_audio_kit/media_session');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a hot restart disables the media session left by the old VM', () async {
    final calls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
          calls.add(call.method);
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, null),
    );

    // The old VM's tracker buffer, empty: no handle leaked, a session did.
    final buffer = calloc<Int64>(512);
    expect(
      ProcessEnvironment.native().set(
        OrphanHandleTracker.envName,
        '$pid:${buffer.address}',
      ),
      isTrue,
    );
    MpvAudioKit.ensureInitialized();
    expect(OrphanHandleTracker.instance.restarted, isTrue);
    await pumpEventQueue();

    expect(calls, ['disable']);
  });
}
