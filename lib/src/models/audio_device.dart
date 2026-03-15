// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by MIT license that can be found in the LICENSE file.

/// Represents an audio output device detected by mpv.
class AudioDevice {
  /// Internal mpv device name, used with [Player.setAudioDevice].
  ///
  /// The special value `"auto"` lets mpv choose the default system device.
  final String name;

  /// Human-readable description shown in system mixer / device pickers.
  final String description;

  const AudioDevice(this.name, this.description);

  /// The default automatic device selection.
  const AudioDevice.auto()
      : name = 'auto',
        description = 'Auto';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AudioDevice && name == other.name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => 'AudioDevice($name, "$description")';
}
