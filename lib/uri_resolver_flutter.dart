// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// Optional Flutter-aware helper for translating host-platform URI
/// schemes that libmpv does not handle natively
/// (`asset://` Flutter bundle paths, `content://` Android intent URIs).
///
/// The wrapper itself does not import `package:flutter/*` so the core
/// can be tested with `dart test`. Flutter consumers wire this helper
/// in by setting [PlayerConfiguration.uriResolver]:
///
/// ```dart
/// import 'package:mpv_audio_kit/mpv_audio_kit.dart';
/// import 'package:mpv_audio_kit/uri_resolver_flutter.dart';
///
/// final player = Player(
///   configuration: const PlayerConfiguration(
///     uriResolver: FlutterUriResolver.normalizeUri,
///   ),
/// );
/// ```
library;

export 'src/utils/flutter_uri_resolver.dart' show FlutterUriResolver;
