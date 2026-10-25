// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

// The artwork download of artwork_fetcher.dart in the browser. The media
// session channel takes bytes only, so the web one will need them too: a
// fetch of the URL, where CORS allows it (W4b).

import 'package:meta/meta.dart';

import '../models/cover_art.dart';

/// No download in the browser yet: answers `null`, the result of a failed
/// download, so artwork URLs show no artwork there.
@internal
Future<CoverArt?> downloadArtwork(Uri uri, [String caFile = '']) async => null;
