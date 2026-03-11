import 'package:mpv_audio_pro_kit/src/models/playlist.dart';
import 'package:mpv_audio_pro_kit/src/models/audio_device.dart';
import 'package:mpv_audio_pro_kit/src/models/audio_params.dart';

/// Immutable snapshot of the [Player]'s complete playback state.
///
/// Retrieve the current snapshot synchronously via `player.state`, or subscribe
/// to individual fields via the typed streams in `player.stream`.
class PlayerState {
  /// The currently loaded playlist and active track index.
  final Playlist playlist;

  /// Whether the player is currently playing (not paused and not buffering).
  final bool playing;

  /// Whether the current track has played to its end.
  ///
  /// Resets to `false` on the next [Player.play] or [Player.open] call.
  final bool completed;

  /// Current playback position.
  final Duration position;

  /// Total duration of the current track. Zero when unknown (e.g. live streams).
  final Duration duration;

  /// Current volume level, 0–100. Values above 100 amplify the signal.
  final double volume;

  /// Playback speed multiplier. 1.0 = normal speed.
  final double rate;

  /// Pitch multiplier. 1.0 = original pitch.
  final double pitch;

  /// Whether the player is currently buffering.
  final bool buffering;

  /// How far ahead the demuxer has buffered.
  final Duration buffer;

  /// Buffer fill percentage (0.0–100.0).
  final double bufferingPercentage;

  /// Current loop / repeat mode.
  final PlaylistMode playlistMode;

  /// Whether the playlist is in shuffle mode.
  final bool shuffle;

  /// Audio format parameters from the current output pipeline.
  final AudioParams audioParams;

  /// Current audio bitrate in bps. `null` if unavailable.
  final double? audioBitrate;

  /// The currently selected audio output device.
  final AudioDevice audioDevice;

  /// All audio output devices detected by mpv.
  final List<AudioDevice> audioDevices;

  /// Whether the player is muted.
  final bool mute;

  const PlayerState({
    this.playlist = const Playlist.empty(),
    this.playing = false,
    this.completed = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.volume = 100.0,
    this.rate = 1.0,
    this.pitch = 1.0,
    this.buffering = false,
    this.buffer = Duration.zero,
    this.bufferingPercentage = 0.0,
    this.playlistMode = PlaylistMode.none,
    this.shuffle = false,
    this.audioParams = const AudioParams(),
    this.audioBitrate,
    this.audioDevice = const AudioDevice('auto', 'Auto'),
    this.audioDevices = const [AudioDevice('auto', 'Auto')],
    this.mute = false,
  });

  PlayerState copyWith({
    Playlist? playlist,
    bool? playing,
    bool? completed,
    Duration? position,
    Duration? duration,
    double? volume,
    double? rate,
    double? pitch,
    bool? buffering,
    Duration? buffer,
    double? bufferingPercentage,
    PlaylistMode? playlistMode,
    bool? shuffle,
    AudioParams? audioParams,
    double? audioBitrate,
    AudioDevice? audioDevice,
    List<AudioDevice>? audioDevices,
    bool? mute,
  }) {
    return PlayerState(
      playlist: playlist ?? this.playlist,
      playing: playing ?? this.playing,
      completed: completed ?? this.completed,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      volume: volume ?? this.volume,
      rate: rate ?? this.rate,
      pitch: pitch ?? this.pitch,
      buffering: buffering ?? this.buffering,
      buffer: buffer ?? this.buffer,
      bufferingPercentage: bufferingPercentage ?? this.bufferingPercentage,
      playlistMode: playlistMode ?? this.playlistMode,
      shuffle: shuffle ?? this.shuffle,
      audioParams: audioParams ?? this.audioParams,
      audioBitrate: audioBitrate ?? this.audioBitrate,
      audioDevice: audioDevice ?? this.audioDevice,
      audioDevices: audioDevices ?? this.audioDevices,
      mute: mute ?? this.mute,
    );
  }

  @override
  String toString() => 'PlayerState('
      'playing: $playing, '
      'completed: $completed, '
      'position: $position, '
      'duration: $duration, '
      'volume: $volume, '
      'rate: $rate, '
      'pitch: $pitch, '
      'buffering: $buffering, '
      'buffer: $buffer, '
      'playlistMode: $playlistMode, '
      'shuffle: $shuffle, '
      'mute: $mute)';
}
