// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by MIT license that can be found in the LICENSE file.

/// mpv_audio_kit — Flutter audio player powered by libmpv.
///
/// Supports macOS, Windows, Linux, iOS, and Android.
///
/// ## Quick start
/// ```dart
/// import 'package:mpv_audio_kit/mpv_audio_kit.dart';
///
/// final player = Player();
///
/// player.stream.position.listen((pos) => print(pos));
/// player.stream.playing.listen((p)   => print('playing: $p'));
///
/// await player.open(Media('https://example.com/audio.mp3'));
/// await player.play();
///
/// // ...
/// await player.dispose();
/// ```
library;

export 'src/player.dart' show Player;
export 'src/models/media.dart'                show Media;
export 'src/models/playlist.dart'             show Playlist, PlaylistMode;
export 'src/models/audio_device.dart'         show AudioDevice;
export 'src/models/audio_filter.dart'         show AudioFilter;
export 'src/models/audio_params.dart'         show AudioParams;
export 'src/models/player_configuration.dart' show PlayerConfiguration;
export 'src/models/player_state.dart'         show PlayerState;
export 'src/models/player_stream.dart'        show PlayerStream;
export 'src/models/replay_gain.dart'          show ReplayGainMode;
export 'src/models/gapless_mode.dart'         show GaplessMode;
export 'src/mpv_bindings.dart'                show MpvLibraryException;
export 'src/mpv_audio_kit.dart'               show MpvAudioKit;
