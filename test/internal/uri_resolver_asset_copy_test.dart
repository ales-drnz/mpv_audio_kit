// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/src/internals/uri_resolver.dart';

/// The temp copies of `asset://` sources keep one fixed path per asset, so
/// a relaunch or a killed process leaves nothing that grows.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const key = 'assets/fixtures/cleanup.wav';
  final payload = Uint8List.fromList(utf8.encode('CLEANUP-PAYLOAD'));

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (ByteData? message) async {
          final asked = utf8.decode(
            message!.buffer.asUint8List(
              message.offsetInBytes,
              message.lengthInBytes,
            ),
          );
          return asked == key ? ByteData.sublistView(payload) : null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
  });

  test('a copy lives in a directory of this user and app', () async {
    final resolved = await resolveUri('asset://$key');
    final file = File(resolved.uri);
    expect(file.readAsBytesSync(), payload);
    final dir = file.parent;
    // Not a name every user and app on the machine would share.
    expect(
      dir.path.split(Platform.pathSeparator).last,
      startsWith('mpv_audio_kit_assets_'),
    );
    final runtime = Platform.environment['XDG_RUNTIME_DIR'];
    if (Platform.isLinux && runtime != null && runtime.isNotEmpty) {
      // An XDG_RUNTIME_DIR inherited from another user (su, sudo -E) is
      // not writable: the copy falls back to temp instead of failing.
      final writable = _canCreateIn(runtime);
      expect(
        dir.parent.path,
        writable ? runtime : Directory.systemTemp.path,
        reason: writable ? 'per-user on Linux' : 'temp fallback',
      );
    }
  });

  test('a copy that went missing is written again at the same path', () async {
    final first = await resolveUri('asset://$key');
    File(first.uri).deleteSync();
    final again = await resolveUri('asset://$key');
    expect(again.uri, first.uri);
    expect(File(again.uri).readAsBytesSync(), payload);
  });

  test(
    'the name of an asset is the path of its copy, before any copy',
    () async {
      // Another key: this process never copied it, as after a relaunch.
      const fresh = 'assets/fixtures/named.wav';
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler('flutter/assets', (ByteData? message) async {
            return ByteData.sublistView(payload);
          });
      final name = await loadedName('asset:///$fresh');
      expect(File(name).existsSync(), isFalse, reason: 'nothing was copied');
      final resolved = await resolveUri('asset:///$fresh');
      expect(name, resolved.uri);
      File(resolved.uri).deleteSync();
    },
  );

  test('no partial file is left beside the copy', () async {
    final resolved = await resolveUri('asset://$key');
    final leftovers = File(
      resolved.uri,
    ).parent.listSync().where((e) => e.path.endsWith('.part'));
    expect(leftovers, isEmpty);
  });
}

bool _canCreateIn(String path) {
  try {
    Directory(path).createTempSync('mpv_audio_kit_probe_').deleteSync();
    return true;
  } on FileSystemException {
    return false;
  }
}
