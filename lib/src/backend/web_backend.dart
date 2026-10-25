// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:meta/meta.dart';

import '../pcm/pcm_native.dart';
import 'mpv_session.dart';
import 'web/mpv_module.dart';
import 'web/web_pcm.dart';
import 'web/web_session.dart';

/// Where the module (libmpv.mjs, with libmpv.wasm beside it) is loaded
/// from when `MpvAudioKit.ensureInitialized` names none: the package's
/// web assets as Flutter serves them. Their delivery belongs to W4b.
@internal
const String kDefaultWebModuleUrl =
    'assets/packages/mpv_audio_kit/web/libmpv.mjs';

String? _url;
Future<MpvModule>? _loading;
MpvModule? _loaded;

/// Test-only: the module every session uses, in place of loading the one
/// at the URL `MpvAudioKit.ensureInitialized` got.
@visibleForTesting
Future<MpvModule>? debugWebModule;

/// The module the sessions use, loaded once.
Future<MpvModule> _module() async => _loaded =
    await (debugWebModule ??
        (_loading ??= loadMpvModule(_url ?? kDefaultWebModuleUrl)));

/// A session over the module in WebAssembly, on the main thread.
/// [wakeupCounterAddress] is a native test hook and has no meaning here.
@internal
MpvSession createMpvSession({int? wakeupCounterAddress}) => WebSession(_module);

/// Starts loading the module: from [libmpv], a URL, or else from
/// [kDefaultWebModuleUrl]. A failure reaches the first player's bring-up.
@internal
void startBackend({String? libmpv, required bool hotRestartCleanup}) {
  _url = libmpv;
  _module().ignore();
}

/// The Hot Restart registry of the web (DESIGN 11, W4b) starts here.
@internal
void backendInitialized() {}

/// The live PCM input of the module. The module loads asynchronously:
/// until it has, there is none.
@internal
PcmNative openPcmNative(String? path) {
  final module = _loaded;
  if (module == null) {
    throw StateError(
      'mpv_audio_kit: the web module has not loaded yet; '
      'create a PcmSource once a Player is ready',
    );
  }
  return WebPcmNative(module);
}
