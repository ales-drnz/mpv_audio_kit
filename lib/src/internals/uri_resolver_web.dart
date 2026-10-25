// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// The host side of uri_resolver.dart in the browser. Every URI goes to mpv
// as it is for now: the web module reads http and https through fetch.
// The mapping of `blob:` (a file the user picked) to `makblob://` and of
// `asset://` to the URL of the asset on the page's origin belongs here
// (W4b).

import 'uri_resolver.dart' show ResolvedUri;

/// Whether local paths are Windows paths: never in the browser, whose
/// module has a POSIX file system of its own.
bool get hostIsWindows => false;

/// Resolves a [uri] that is no `file://` URL.
Future<ResolvedUri> resolveHostUri(String uri) async => ResolvedUri(uri);

/// The name [resolveHostUri] gives mpv for [uri].
Future<String> hostLoadedName(String uri) async => uri;
