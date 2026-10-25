// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:flutter/foundation.dart';

import '../models/cover_art.dart';

export 'artwork_download_io.dart'
    if (dart.library.js_interop) 'artwork_download_web.dart';

/// Loads an artwork URL into a [CoverArt], trusting the extra CA bundle
/// `caFile` (the player's `tls-ca-file`, empty for none) on top of the
/// system roots; `null` on any failure.
typedef ArtworkFetcher = Future<CoverArt?> Function(Uri uri, String caFile);

/// Whether the media session downloads remote artwork in Dart on
/// [platform], handing the native side bytes instead of the URL. Remote
/// cover URLs often carry credentials in the query (Subsonic `u`, `t` and
/// `s`, Jellyfin `api_key`, Plex `X-Plex-Token`), and the OS would publish
/// them: MPRIS `mpris:artUrl` on the session bus (Linux), the session
/// metadata other apps with notification access read (Android), the
/// thumbnail source SMTC is given (Windows). Apple's Now Playing takes an
/// image, never a URL, so its plugin publishes the bytes it is sent.
///
/// Never in the browser, whatever [platform] the page runs on: the web
/// media session takes the URL, as the page could fetch it anyway.
@internal
bool downloadsArtworkOn(TargetPlatform platform) =>
    !kIsWeb &&
    switch (platform) {
      TargetPlatform.linux ||
      TargetPlatform.android ||
      TargetPlatform.windows ||
      TargetPlatform.iOS ||
      TargetPlatform.macOS => true,
      _ => false,
    };

/// Whether the media session also reads `file://` artwork in Dart on
/// [platform]: on Apple, whose plugin takes bytes only. Elsewhere the
/// native side opens the file.
@internal
bool readsArtworkFilesOn(TargetPlatform platform) =>
    platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
