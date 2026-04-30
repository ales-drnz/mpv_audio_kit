// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

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
export 'src/cover/cover_art_raw.dart' show CoverArtRaw;
export 'src/models/cache_config.dart' show CacheConfig;
export 'src/models/chapter.dart' show Chapter;
export 'src/models/media.dart' show Media;
export 'src/models/mpv_track.dart' show MpvTrack;
export 'src/models/replay_gain_config.dart' show ReplayGainConfig;
export 'src/models/playlist.dart' show Playlist, PlaylistMode;
export 'src/models/audio_device.dart' show AudioDevice;
export 'src/models/audio_filter.dart' show AudioFilter;
export 'src/models/audio_params.dart' show AudioParams;
export 'src/models/enums.dart'
    show
        GaplessMode,
        ReplayGainMode,
        AudioDisplayMode,
        CoverArtAutoMode,
        CacheMode,
        AudioOutputState,
        PlaybackLifecycle;
export 'src/models/mpv_log_entry.dart' show MpvLogEntry;
export 'src/models/mpv_hook_event.dart' show MpvHookEvent;
export 'src/models/mpv_prefetch_state.dart' show MpvPrefetchState;
export 'src/models/mpv_player_error.dart'
    show
        MpvPlayerError,
        MpvEndFileError,
        MpvEndFileErrorX,
        MpvLogError,
        MpvEndFileReason,
        MpvFileEndedEvent,
        MpvFileEndedEventX;
export 'src/models/player_configuration.dart' show PlayerConfiguration;
export 'src/models/player_state.dart' show PlayerState;
export 'src/player_stream.dart' show PlayerStream;
export 'src/mpv_bindings.dart' show MpvLibraryException, MpvError;
export 'src/library_loader.dart' show MpvAudioKit;
