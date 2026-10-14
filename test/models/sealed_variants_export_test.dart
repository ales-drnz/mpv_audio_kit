// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// The variants of the public sealed types are reachable from the package
// barrel alone, so an app can switch on them and read their payload (the
// artwork's cover or URL, a track id, a custom channel layout). This file
// compiles only if they are exported.

import 'dart:typed_data';

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

String _artwork(MediaSessionArtwork a) => switch (a) {
  MediaSessionArtworkEmbedded() => 'embedded',
  MediaSessionArtworkNone() => 'none',
  MediaSessionArtworkCustom(:final cover) => 'custom ${cover.mimeType}',
  MediaSessionArtworkUri(:final uri) => 'uri $uri',
};

String _track(Track t) => switch (t) {
  TrackAuto() => 'auto',
  TrackOff() => 'off',
  TrackId(:final trackId) => 'id $trackId',
};

void main() {
  test('MediaSessionArtwork variants switch exhaustively', () {
    final cover = CoverArt(
      bytes: Uint8List.fromList([1, 2, 3]),
      mimeType: 'image/png',
    );
    expect(_artwork(MediaSessionArtwork.embedded), 'embedded');
    expect(_artwork(MediaSessionArtwork.none), 'none');
    expect(_artwork(MediaSessionArtwork.custom(cover)), 'custom image/png');
    expect(
      _artwork(MediaSessionArtwork.uri(Uri.parse('https://a.b/c.jpg'))),
      'uri https://a.b/c.jpg',
    );
  });

  test('Track variants switch exhaustively', () {
    expect(_track(Track.auto), 'auto');
    expect(_track(Track.off), 'off');
    expect(_track(const Track.id(2)), 'id 2');
  });

  test('a custom channel layout is matched by its variant', () {
    const Channels custom = Channels.custom('fl-fr-lfe');
    expect(custom, isA<ChannelsCustom>());
    expect((custom as ChannelsCustom).mpvLayout, 'fl-fr-lfe');
    expect(Channels.stereo, isNot(isA<ChannelsCustom>()));
  });
}
