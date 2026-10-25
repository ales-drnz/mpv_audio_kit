// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// Files in the browser: a blob: URL of the page reaches the web module as
// makblob://, an asset:// as the asset's absolute URL; a File the user
// picked plays through Media.fromBlob, with its seeks, as does a blob: URL
// the app already holds (flutter test --platform chrome --wasm).

@TestOn('browser')
library;

import 'dart:js_interop';

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:mpv_audio_kit/src/internals/uri_resolver.dart';

import '../_helpers/parity_scenario.dart';
import 'web_module_helper.dart';

@JS('File')
extension type _File._(JSObject _) implements JSObject {
  external _File(JSArray<JSAny> parts, String name);
}

@JS('URL.createObjectURL')
external String _objectUrl(JSObject blob);

/// The fixture at [path] as a File named [name], as a picker gives it.
Future<JSObject> _pickedFile(String path, String name) async =>
    _File(<JSAny>[(await fetchBytes(path)).toJS].toJS, name);

Future<Player> _player() async {
  final player = Player();
  addTearDown(player.dispose);
  await player.ready;
  await player.setRawProperty('ao', 'null');
  return player;
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadTestModule();
    MpvAudioKit.ensureInitialized(hotRestartCleanup: false);
  });

  test(
    'blob: becomes makblob://, asset:// the absolute URL of the asset',
    () async {
      final blob = 'blob:$testOrigin/1b2c';
      expect((await resolveUri(blob)).uri, 'makblob://$testOrigin/1b2c');
      expect(await loadedName(blob), 'makblob://$testOrigin/1b2c');
      for (final asset in ['asset:///assets/a.flac', 'asset://assets/a.flac']) {
        final url = (await resolveUri(asset)).uri;
        expect(url, startsWith(testOrigin), reason: asset);
        expect(url, endsWith('/assets/assets/a.flac'), reason: asset);
      }
      expect(
        (await resolveUri('https://example.com/a.flac')).uri,
        'https://example.com/a.flac',
      );
    },
  );

  test('a picked File plays with Media.fromBlob, named after the file, and '
      'seeks', () async {
    final player = await _player();
    final media = Media.fromBlob(
      await _pickedFile('fixtures/sine_5s.flac', 'sine 5s.flac'),
    );
    expect(media.uri, startsWith('blob:'));
    expect(media.extras, {'title': 'sine 5s.flac'});
    await player.open(media, play: true);
    await waitUntil(
      () => player.state.duration > Duration.zero,
      what: 'the duration',
    );
    expect(player.state.duration.inMilliseconds, closeTo(5000, 50));
    expect(player.state.playlist.items.single.extras?['title'], 'sine 5s.flac');
    await player.seek(const Duration(milliseconds: 4500));
    await waitUntil(() => player.state.completed, what: 'the end after a seek');
  });

  test('a blob: URL the app holds plays as Media(url)', () async {
    final player = await _player();
    final url = _objectUrl(
      await _pickedFile('fixtures/sine_stereo_1s.flac', 'a.flac'),
    );
    await player.open(Media(url), play: true);
    await waitUntil(() => player.state.completed, what: 'the end');
    expect(player.state.playlist.items.single.uri, url);
  });

  test('Media.fromBlob keeps the title of the extras and refuses what is '
      'no Blob', () async {
    final file = await _pickedFile('fixtures/sine_stereo_1s.flac', 'a.flac');
    expect(Media.fromBlob(file, extras: {'title': 'Mine', 'id': 3}).extras, {
      'title': 'Mine',
      'id': 3,
    });
    expect(() => Media.fromBlob('blob:x'), throwsArgumentError);
    expect(() => Media.fromBlob(JSObject()), throwsArgumentError);
  });
}
