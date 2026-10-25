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

/// Whether the media session loads artwork URLs in Dart on [platform]:
/// it downloads an `http(s)://` one and reads a `file://` one, and the
/// native side only ever gets bytes. Remote cover URLs often carry
/// credentials in the query (Subsonic `u`, `t` and `s`, Jellyfin
/// `api_key`, Plex `X-Plex-Token`), and the OS would publish them: MPRIS
/// `mpris:artUrl` on the session bus (Linux), the session metadata other
/// apps with notification access read (Android), the thumbnail source SMTC
/// is given (Windows). Apple's Now Playing takes an image, never a URL.
@internal
bool downloadsArtworkOn(TargetPlatform platform) => switch (platform) {
  TargetPlatform.linux ||
  TargetPlatform.android ||
  TargetPlatform.windows ||
  TargetPlatform.iOS ||
  TargetPlatform.macOS => true,
  _ => false,
};
