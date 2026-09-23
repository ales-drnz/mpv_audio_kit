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

// Regression test: two DISTINCT bundle assets whose paths flatten to the
// SAME temp filename must materialize to DISTINCT files. The asset branch
// of `resolveUri` flattens path separators to `_` when deriving the temp
// filename, so `assets/fixtures/collide/x.wav` and
// `assets/fixtures/collide_x.wav` both map to
// `mpv_asset_assets_fixtures_collide_x.wav` — the second materialization
// overwrites the first while mpv may still be streaming it.
//
// The asset bytes are served through the standard flutter_test mock for
// the `flutter/assets` binary-messenger channel, which is exactly what
// `rootBundle.load` (used by the resolver) goes through — the real
// materialization code runs unmodified.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Both keys flatten to `assets_fixtures_collide_x.wav`.
  const keyA = 'assets/fixtures/collide/x.wav';
  const keyB = 'assets/fixtures/collide_x.wav';

  final payloadA = Uint8List.fromList(
    utf8.encode('PAYLOAD-A ${'a' * 64} END-A'),
  );
  final payloadB = Uint8List.fromList(
    utf8.encode('PAYLOAD-B ${'b' * 64} END-B'),
  );

  final materialized = <String>{};

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (ByteData? message) async {
          final key = utf8.decode(
            message!.buffer.asUint8List(
              message.offsetInBytes,
              message.lengthInBytes,
            ),
          );
          if (key == keyA) return ByteData.sublistView(payloadA);
          if (key == keyB) return ByteData.sublistView(payloadB);
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
    for (final path in materialized) {
      try {
        File(path).deleteSync();
      } on FileSystemException {
        // Best-effort temp cleanup.
      }
    }
    materialized.clear();
  });

  test('distinct assets with colliding flattened names materialize to '
      'distinct temp files with their own contents', () async {
    final a = await resolveUri('asset://$keyA');
    materialized.add(a.uri);

    // Setup sanity (not the regression assertion): the asset branch must
    // have actually materialized — a soft-fallback to the original URI
    // would mean the mock never served the bytes.
    expect(
      a.uri,
      isNot(startsWith('asset://')),
      reason:
          'asset A failed to materialize (soft-fallback) — test '
          'setup problem, not the collision bug',
    );
    expect(
      File(a.uri).readAsBytesSync(),
      equals(payloadA),
      reason: 'asset A materialized with wrong bytes — setup problem',
    );

    final b = await resolveUri('asset://$keyB');
    materialized.add(b.uri);

    expect(
      b.uri,
      isNot(startsWith('asset://')),
      reason:
          'asset B failed to materialize (soft-fallback) — test '
          'setup problem, not the collision bug',
    );
    expect(
      File(b.uri).readAsBytesSync(),
      equals(payloadB),
      reason: 'asset B materialized with wrong bytes — setup problem',
    );

    // GREEN contract: distinct assets resolve to distinct temp files…
    expect(
      b.uri,
      isNot(equals(a.uri)),
      reason:
          'distinct assets "$keyA" and "$keyB" materialized to the '
          'SAME temp file — flattened-name collision; the second copy '
          'overwrites the first while mpv may still be streaming it',
    );

    // …and the first file still holds the FIRST asset's bytes after the
    // second materialization.
    expect(
      File(a.uri).readAsBytesSync(),
      equals(payloadA),
      reason:
          'asset A\'s materialized file was overwritten by asset '
          'B\'s bytes',
    );
  });
}
