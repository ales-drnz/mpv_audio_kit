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
export 'src/network/cache_config.dart' show CacheConfig, CacheMode;
export 'src/playback/chapter.dart' show Chapter;
export 'src/dsp/compressor_config.dart' show CompressorConfig;
export 'src/dsp/equalizer_config.dart' show EqualizerConfig;
export 'src/dsp/loudness_config.dart' show LoudnessConfig;
export 'src/playback/media.dart' show Media;
export 'src/playback/mpv_track.dart' show MpvTrack;
export 'src/dsp/pitch_tempo_config.dart' show PitchTempoConfig;
export 'src/audio/replay_gain_config.dart' show ReplayGainConfig, ReplayGainMode;
export 'src/playback/playlist.dart' show Playlist;
export 'src/playback/loop_mode.dart' show LoopMode;
export 'src/audio/audio_device.dart' show AudioDevice;
export 'src/audio/audio_params.dart' show AudioParams;
export 'src/playback/audio_track_mode.dart' show AudioTrackMode;
export 'src/cover/audio_display_mode.dart' show AudioDisplayMode;
export 'src/audio/audio_output_state.dart' show AudioOutputState;
export 'src/cover/cover_art_auto_mode.dart' show CoverArtAutoMode;
export 'src/audio/gapless_mode.dart' show GaplessMode;
export 'src/playback/playback_lifecycle.dart' show PlaybackLifecycle;
export 'src/events/mpv_log_entry.dart' show MpvLogEntry;
export 'src/events/mpv_hook_event.dart' show MpvHookEvent;
export 'src/events/mpv_prefetch_state.dart' show MpvPrefetchState;
export 'src/events/mpv_player_error.dart'
    show
        MpvPlayerError,
        MpvEndFileError,
        MpvEndFileErrorX,
        MpvLogError,
        MpvEndFileReason,
        MpvFileEndedEvent,
        MpvFileEndedEventX;
export 'src/player_configuration.dart' show PlayerConfiguration;
export 'src/player_state.dart' show PlayerState;
export 'src/player_stream.dart' show PlayerStream;
export 'src/mpv_bindings.dart' show MpvLibraryException, MpvError;
export 'src/exceptions.dart' show MpvException;
export 'src/library_loader.dart' show MpvAudioKit;
