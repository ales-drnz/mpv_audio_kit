// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:mpv_audio_kit/src/internals/uri_resolver_io.dart';

const _channel = MethodChannel('mpv_audio_kit');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() => debugResolvesContentUris = true);
  tearDown(() {
    debugResolvesContentUris = false;
    messenger.setMockMethodCallHandler(_channel, null);
  });

  // resolveUri documents a SourceException when a content:// URI cannot
  // be resolved. Without the plugin on the other side (an engine that did
  // not register it) the MissingPluginException came out as it was.
  test(
    'a content:// URI without the plugin fails with SourceException',
    () async {
      await expectLater(
        resolveHostUri('content://media/external/audio/1'),
        throwsA(
          isA<SourceException>().having(
            (e) => e.toString(),
            'message',
            contains('content://media/external/audio/1'),
          ),
        ),
      );
    },
  );

  test(
    'a content:// URI the plugin refuses fails with SourceException',
    () async {
      messenger.setMockMethodCallHandler(
        _channel,
        (call) => Future.error(
          PlatformException(code: 'denied', message: 'no permission'),
        ),
      );
      await expectLater(
        resolveHostUri('content://media/external/audio/1'),
        throwsA(isA<SourceException>()),
      );
    },
  );

  test(
    'a content:// URI resolves to the descriptor the plugin gives',
    () async {
      final calls = <String>[];
      messenger.setMockMethodCallHandler(_channel, (call) async {
        calls.add(call.method);
        return call.method == 'openFileDescriptor' ? 42 : null;
      });
      final resolved = await resolveHostUri('content://media/external/audio/1');
      expect(resolved.uri, 'fd://42');
      await resolved.dispose?.call();
      expect(calls, ['openFileDescriptor', 'closeFileDescriptor']);
    },
  );
}
