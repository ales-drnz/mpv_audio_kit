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

/// The temp copies of `asset://` sources are deleted when the last player
/// goes, and copied again when one is needed after that.
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

  test(
    'deleteCopiedAssets removes the copies, a later resolve copies again',
    () async {
      final first = await resolveUri('asset://$key');
      expect(File(first.uri).existsSync(), isTrue);

      await deleteCopiedAssets();
      expect(File(first.uri).existsSync(), isFalse);

      final again = await resolveUri('asset://$key');
      expect(File(again.uri).readAsBytesSync(), payload);
      await deleteCopiedAssets();
    },
  );

  test('a copy made while a deletion runs survives it', () async {
    final first = await resolveUri('asset://$key');
    // A new player resolving the same asset right after the last one went.
    final deletion = deleteCopiedAssets();
    final again = await resolveUri('asset://$key');
    await deletion;
    expect(File(first.uri).existsSync(), isFalse);
    expect(again.uri, isNot(first.uri));
    expect(File(again.uri).readAsBytesSync(), payload);
    await deleteCopiedAssets();
  });

  test('copies live in a directory of their own', () async {
    final resolved = await resolveUri('asset://$key');
    expect(
      File(resolved.uri).parent.path,
      isNot(Directory.systemTemp.path),
      reason: 'another process deleting its copies must not reach ours',
    );
    await deleteCopiedAssets();
  });
}
