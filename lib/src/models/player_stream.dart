import 'package:mpv_audio_pro_kit/src/models/playlist.dart';
import 'package:mpv_audio_pro_kit/src/models/audio_device.dart';
import 'package:mpv_audio_pro_kit/src/models/audio_params.dart';

/// Typed event streams for subscribing to individual [Player] state changes.
///
/// Access via `player.stream`:
/// ```dart
/// player.stream.playing.listen((isPlaying) { ... });
/// player.stream.position.listen((pos) { ... });
/// ```
class PlayerStream {
  /// Emits whenever the active playlist changes (adds, removes, reorders).
  final Stream<Playlist> playlist;

  /// Emits `true` when playback starts, `false` when paused or stopped.
  final Stream<bool> playing;

  /// Emits `true` when the current track finishes playing to its end.
  final Stream<bool> completed;

  /// Emits the current playback position as a [Duration].
  final Stream<Duration> position;

  /// Emits the duration of the current track. Zero for live / unknown streams.
  final Stream<Duration> duration;

  /// Emits the current volume level (0–100+).
  final Stream<double> volume;

  /// Emits the current playback speed multiplier.
  final Stream<double> rate;

  /// Emits the current pitch multiplier.
  final Stream<double> pitch;

  /// Emits `true` while buffering data; `false` once playback resumes.
  final Stream<bool> buffering;

  /// Emits the current demuxer buffer depth as a [Duration].
  final Stream<Duration> buffer;

  /// Emits the buffer fill percentage (0.0–100.0).
  final Stream<double> bufferingPercentage;

  /// Emits the current [PlaylistMode] when it changes.
  final Stream<PlaylistMode> playlistMode;

  /// Emits `true` when shuffle mode is enabled.
  final Stream<bool> shuffle;

  /// Emits updated [AudioParams] when the audio output format changes.
  final Stream<AudioParams> audioParams;

  /// Emits the current audio bitrate in bps. `null` = unavailable.
  final Stream<double?> audioBitrate;

  /// Emits the currently selected [AudioDevice].
  final Stream<AudioDevice> audioDevice;

  /// Emits the full list of detected [AudioDevice]s when it changes.
  final Stream<List<AudioDevice>> audioDevices;

  /// Emits `true` when the player is muted.
  final Stream<bool> mute;

  /// Emits human-readable error messages from the mpv engine.
  final Stream<String> error;

  /// Emits raw log lines from the mpv engine at the configured log level.
  final Stream<String> log;

  const PlayerStream({
    required this.playlist,
    required this.playing,
    required this.completed,
    required this.position,
    required this.duration,
    required this.volume,
    required this.rate,
    required this.pitch,
    required this.buffering,
    required this.buffer,
    required this.bufferingPercentage,
    required this.playlistMode,
    required this.shuffle,
    required this.audioParams,
    required this.audioBitrate,
    required this.audioDevice,
    required this.audioDevices,
    required this.mute,
    required this.error,
    required this.log,
  });
}
