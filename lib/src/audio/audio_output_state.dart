// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// Lifecycle of mpv's audio output (AO), reported by the
/// `audio-output-state` mpv property. Authoritative replacement for
/// inferring AO state from `audio-out-params/format` after a delay —
/// the four values below cover every transition `ao_init_best()` can
/// produce.
enum AudioOutputState {
  /// No audio output is currently active. Default state and what mpv reports
  /// when no file is loaded or the file has been unloaded.
  closed('closed'),

  /// `ao_init_best()` is in flight. Useful for "connecting…" UI feedback on
  /// slow audio backends (PipeWire negotiation, BT device init, …).
  initializing('initializing'),

  /// AO opened successfully and is producing samples.
  active('active'),

  /// `ao_init_best()` returned a NULL handle — the audio output failed to
  /// open. mpv emits a parallel error on the engine log channel; the
  /// wrapper surfaces a typed `MpvLogError` on `Player.stream.error` when
  /// this state arrives.
  failed('failed');

  const AudioOutputState(this.mpvValue);

  /// The wire-level string mpv expects.
  final String mpvValue;

  /// Maps a raw mpv-side value back to the enum. Unknown → [closed].
  static AudioOutputState fromMpv(String raw) => switch (raw) {
        'closed' => closed,
        'initializing' => initializing,
        'active' => active,
        'failed' => failed,
        _ => closed,
      };
}
