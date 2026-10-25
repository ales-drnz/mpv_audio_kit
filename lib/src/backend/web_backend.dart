// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:meta/meta.dart';

import '../pcm/pcm_native.dart';
import 'mpv_session.dart';

/// Not available yet on the web: the backend over the module in
/// WebAssembly lands next.
@internal
MpvSession createMpvSession({int? wakeupCounterAddress}) =>
    throw UnsupportedError('mpv_audio_kit: no web backend yet');

/// No step on the web yet.
@internal
void startBackend({String? libmpv, required bool hotRestartCleanup}) {}

/// No step on the web yet.
@internal
void backendInitialized() {}

/// Not available yet on the web.
@internal
PcmNative openPcmNative(String? path) =>
    throw UnsupportedError('mpv_audio_kit: no web backend yet');
