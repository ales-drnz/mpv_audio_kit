// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// Async hook invoked by `Player.open()` / `Player.openAll()` /
/// `Player.add()` / `Player.replace()` for every media URI before it
/// reaches `loadfile`.
///
/// The wrapper itself is platform-agnostic and pure Dart — it does not
/// know about Android `content://` URIs, Flutter `asset://` bundles,
/// or any other host-platform schema. Consumers that need such
/// translation pass their resolver via [PlayerConfiguration.uriResolver];
/// the example app injects the bundled `FlutterUriResolver.normalizeUri`
/// for Android intent-URI / Flutter asset support.
///
/// When [PlayerConfiguration.uriResolver] is `null`, the wrapper uses
/// [defaultUriResolver] (an identity pass-through).
typedef UriResolver = Future<String> Function(String uri);

/// Identity pass-through. Returns the URI unchanged.
///
/// Used when [PlayerConfiguration.uriResolver] is `null` — appropriate
/// for absolute file paths, `http(s)://`, `smb2://`, and any other
/// scheme libmpv handles natively.
Future<String> defaultUriResolver(String uri) async => uri;
