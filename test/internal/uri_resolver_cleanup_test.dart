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

  test('a copy has a fixed path in the package directory', () async {
    final resolved = await resolveUri('asset://$key');
    final file = File(resolved.uri);
    expect(file.readAsBytesSync(), payload);
    expect(
      file.parent.path,
      '${Directory.systemTemp.path}${Platform.pathSeparator}'
      'mpv_audio_kit_assets',
    );
  });

  test('a copy that went missing is written again at the same path', () async {
    final first = await resolveUri('asset://$key');
    File(first.uri).deleteSync();
    final again = await resolveUri('asset://$key');
    expect(again.uri, first.uri);
    expect(File(again.uri).readAsBytesSync(), payload);
  });

  test('no partial file is left beside the copy', () async {
    final resolved = await resolveUri('asset://$key');
    final leftovers = File(
      resolved.uri,
    ).parent.listSync().where((e) => e.path.endsWith('.part'));
    expect(leftovers, isEmpty);
  });
}
