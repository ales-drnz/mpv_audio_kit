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

export 'src/player/player.dart' show Player;
export 'src/models/cover_art.dart' show CoverArt;
export 'src/types/settings/audio_effects.dart' show AudioEffects;
export 'src/types/settings/bass_treble_settings.dart' show BassTrebleSettings;
export 'src/types/settings/cache_settings.dart' show CacheSettings;
export 'src/types/enums/cache.dart' show Cache;
export 'src/models/chapter.dart' show Chapter;
export 'src/types/settings/compressor_settings.dart' show CompressorSettings;
export 'src/types/settings/crossfeed_settings.dart'
    show CrossfeedSettings, CrossfeedIntensity;
export 'src/types/settings/equalizer_settings.dart' show EqualizerSettings;
export 'src/types/settings/loudness_settings.dart' show LoudnessSettings;
export 'src/models/media.dart' show Media;
export 'src/models/mpv_track.dart' show MpvTrack;
export 'src/types/settings/pitch_tempo_settings.dart' show PitchTempoSettings;
export 'src/types/settings/silence_trim_settings.dart' show SilenceTrimSettings;
export 'src/types/settings/stereo_settings.dart' show StereoSettings;
export 'src/types/settings/replay_gain_settings.dart' show ReplayGainSettings;
export 'src/types/enums/replay_gain.dart' show ReplayGain;
export 'src/models/playlist.dart' show Playlist;
export 'src/types/enums/loop.dart' show Loop;
export 'src/types/sealed/channels.dart' show Channels;
export 'src/models/device.dart' show Device;
export 'src/types/enums/format.dart' show Format;
export 'src/models/audio_params.dart' show AudioParams;
export 'src/types/enums/spdif.dart' show Spdif;
export 'src/types/sealed/track.dart' show Track;
export 'src/types/state/audio_output_state.dart' show AudioOutputState;
export 'src/types/enums/cover.dart' show Cover;
export 'src/types/enums/gapless.dart' show Gapless;
export 'src/types/state/mpv_playback_state.dart' show MpvPlaybackState;
export 'src/events/mpv_log_entry.dart' show MpvLogEntry;
export 'src/events/mpv_hook_event.dart' show MpvHookEvent;
export 'src/types/enums/hook.dart' show Hook;
export 'src/types/state/mpv_prefetch_state.dart' show MpvPrefetchState;
export 'src/events/mpv_player_error.dart'
    show
        MpvPlayerError,
        MpvEndFileError,
        MpvEndFileErrorX,
        MpvLogError,
        MpvEndFileReason,
        MpvFileEndedEvent,
        MpvFileEndedEventX;
export 'src/player/player_configuration.dart' show PlayerConfiguration;
export 'src/player/player_state.dart' show PlayerState;
export 'src/player/player_stream.dart' show PlayerStream;
export 'src/mpv_bindings.dart' show MpvLibraryException, MpvError;
export 'src/events/exceptions.dart' show MpvException;
export 'src/internals/library_loader.dart' show MpvAudioKit;
