// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

// The artwork download of artwork_fetcher.dart in the browser, where
// [downloadsArtworkOn] is false: the web media session takes the URL.

import 'package:meta/meta.dart';

import '../models/cover_art.dart';
import 'artwork_fetcher.dart' show downloadsArtworkOn;

/// Never called in the browser ([downloadsArtworkOn] is false there);
/// answers `null`, the result of a failed download.
@internal
Future<CoverArt?> downloadArtwork(Uri uri, [String caFile = '']) async => null;
