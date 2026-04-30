import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

/// A service to persist and restore player settings across app restarts.
class SettingsService {
  static const String _keyPrefix = 'audio_kit_';

  final SharedPreferences _prefs;

  SettingsService(this._prefs);

  /// Helper: load-time SharedPreferences store seconds as `double`, but the
  /// 0.1.0 API takes [Duration] for every time-based setter.
  static Duration _secondsToDuration(double seconds) =>
      Duration(microseconds: (seconds * 1e6).round());

  static Future<SettingsService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsService(prefs);
  }

  /// Saves any player property to disk.
  Future<void> save(String key, dynamic value) async {
    final fullKey = '$_keyPrefix$key';
    if (value is String) {
      await _prefs.setString(fullKey, value);
    } else if (value is int) {
      await _prefs.setInt(fullKey, value);
    } else if (value is double) {
      await _prefs.setDouble(fullKey, value);
    } else if (value is bool) {
      await _prefs.setBool(fullKey, value);
    } else if (value is Duration) {
      await _prefs.setDouble(fullKey, value.inMicroseconds / 1e6);
    } else if (value is List<String>) {
      await _prefs.setStringList(fullKey, value);
    } else if (value is List<double>) {
      await _prefs.setString(fullKey, jsonEncode(value));
    } else if (value is Enum) {
      // Persist enums by their `mpvValue` (set via `dynamic`-checked
      // accessor below); the restore path uses the same wire format.
      final mpvValue = (value as dynamic).mpvValue as String?;
      if (mpvValue != null) await _prefs.setString(fullKey, mpvValue);
    }
  }

  /// Restores all saved settings to the [player] instance.
  Future<void> restore(Player player) async {
    // ── Volume & Basic Controls ──────────────────────────────────────────────

    // Playback volume (0.0 – volumeMax)
    final volume = _prefs.getDouble('${_keyPrefix}volume');
    if (volume != null) {
      await player.setVolume(volume);
    }

    // Maximum volume ceiling (default 100.0, allows software boost above 100)
    final volumeMax = _prefs.getDouble('${_keyPrefix}volume-max');
    if (volumeMax != null) {
      await player.setVolumeMax(volumeMax);
    }

    // Playback speed multiplier (1.0 = normal)
    final rate = _prefs.getDouble('${_keyPrefix}rate');
    if (rate != null) {
      await player.setRate(rate);
    }

    // Audio pitch multiplier (1.0 = normal)
    final pitch = _prefs.getDouble('${_keyPrefix}pitch');
    if (pitch != null) {
      await player.setPitch(pitch);
    }

    // Mute toggle (does not affect volume level)
    final mute = _prefs.getBool('${_keyPrefix}mute');
    if (mute != null) {
      await player.setMute(mute);
    }

    // ── Playlist / Playback Mode ─────────────────────────────────────────────

    // Loop mode: none, single, playlist
    final mode = _prefs.getString('${_keyPrefix}playlist_mode');
    if (mode != null) {
      final pMode = PlaylistMode.values.firstWhere(
        (e) => e.name == mode,
        orElse: () => PlaylistMode.none,
      );
      await player.setPlaylistMode(pMode);
    }

    // Shuffle playback order
    final shuffle = _prefs.getBool('${_keyPrefix}shuffle');
    if (shuffle != null) {
      await player.setShuffle(shuffle);
    }

    // ── Audio Engine / DSP ───────────────────────────────────────────────────

    // 10-band equalizer gains (JSON-encoded list of doubles, dB)
    final eqGains = _prefs.getString('${_keyPrefix}equalizer_gains');
    if (eqGains != null) {
      final List<dynamic> decoded = jsonDecode(eqGains);
      final gains = decoded.map((e) => (e as num).toDouble()).toList();
      player.setEqualizerGains(gains);
    }

    // Gapless audio playback (typed enum since 0.1.0)
    final gapless = _prefs.getString('${_keyPrefix}gapless-audio');
    if (gapless != null) {
      await player.setGaplessMode(GaplessMode.fromMpv(gapless));
    }

    // ReplayGain configuration aggregate. Each subkey is optional; we
    // start from the in-memory defaults so unset prefs don't override
    // them with zeros.
    final rgMode = _prefs.getString('${_keyPrefix}replaygain');
    final rgPreamp = _prefs.getDouble('${_keyPrefix}replaygain-preamp');
    final rgFallback = _prefs.getDouble('${_keyPrefix}replaygain-fallback');
    final rgClip = _prefs.getBool('${_keyPrefix}replaygain-clip');
    if (rgMode != null ||
        rgPreamp != null ||
        rgFallback != null ||
        rgClip != null) {
      await player.setReplayGain(player.state.replayGain.copyWith(
        mode: rgMode != null
            ? ReplayGainMode.fromMpv(rgMode)
            : player.state.replayGain.mode,
        preamp: rgPreamp ?? player.state.replayGain.preamp,
        fallback: rgFallback ?? player.state.replayGain.fallback,
        clip: rgClip ?? player.state.replayGain.clip,
      ));
    }

    // Additional volume gain in dB (applied after ReplayGain)
    final volumeGain = _prefs.getDouble('${_keyPrefix}volume-gain');
    if (volumeGain != null) {
      await player.setVolumeGain(volumeGain);
    }

    // Preserve pitch when changing playback speed
    final pitchCorrection = _prefs.getBool('${_keyPrefix}pitch-correction');
    if (pitchCorrection != null) {
      await player.setPitchCorrection(pitchCorrection);
    }

    // Audio delay offset (positive = audio later, since 0.1.0 takes Duration)
    final audioDelay = _prefs.getDouble('${_keyPrefix}audio-delay');
    if (audioDelay != null) {
      await player.setAudioDelay(_secondsToDuration(audioDelay));
    }

    // ── Routing & Hardware ───────────────────────────────────────────────────

    // Target sample rate in Hz (0 = auto/pass-through)
    final sampleRate = _prefs.getInt('${_keyPrefix}audio-samplerate');
    if (sampleRate != null) {
      await player.setAudioSampleRate(sampleRate);
    }

    // Target sample format (e.g. "s16", "float", "auto" to reset)
    final format = _prefs.getString('${_keyPrefix}audio-format');
    if (format != null) {
      await player.setAudioFormat(format);
    }

    // Target channel layout (e.g. "stereo", "5.1", "no" to reset to auto)
    final channels = _prefs.getString('${_keyPrefix}audio-channels');
    if (channels != null) {
      await player.setAudioChannels(channels);
    }

    // Application name reported to the audio server (e.g. PulseAudio)
    final clientName = _prefs.getString('${_keyPrefix}audio-client-name');
    if (clientName != null) {
      await player.setAudioClientName(clientName);
    }

    // Audio output driver (e.g. "coreaudio", "wasapi", "pipewire")
    final audioDriver = _prefs.getString('${_keyPrefix}ao');
    if (audioDriver != null) {
      await player.setAudioDriver(audioDriver);
    }

    // Audio output device identifier
    final deviceName = _prefs.getString('${_keyPrefix}audio-device');
    if (deviceName != null) {
      await player.setAudioDevice(AudioDevice(deviceName, deviceName));
    }

    // S/PDIF passthrough codecs (e.g. "ac3,dts", "" to disable)
    final spdif = _prefs.getString('${_keyPrefix}audio-spdif');
    if (spdif != null) {
      await player.setAudioSpdif(spdif);
    }

    // Exclusive access to the audio device (bypasses system mixer)
    final exclusive = _prefs.getBool('${_keyPrefix}audio-exclusive');
    if (exclusive != null) {
      await player.setAudioExclusive(exclusive);
    }

    // Audio buffer size (Duration since 0.1.0)
    final audioBuffer = _prefs.getDouble('${_keyPrefix}audio-buffer');
    if (audioBuffer != null) {
      await player.setAudioBuffer(_secondsToDuration(audioBuffer));
    }

    // ── Cache & Demuxer ──────────────────────────────────────────────────────

    // Cache configuration aggregate. Same partial-restore strategy as
    // ReplayGain: missing prefs keep the current defaults.
    final cMode = _prefs.getString('${_keyPrefix}cache');
    final cSecs = _prefs.getDouble('${_keyPrefix}cache-secs');
    final cOnDisk = _prefs.getBool('${_keyPrefix}cache-on-disk');
    final cPause = _prefs.getBool('${_keyPrefix}cache-pause');
    final cPauseWait = _prefs.getDouble('${_keyPrefix}cache-pause-wait');
    if (cMode != null ||
        cSecs != null ||
        cOnDisk != null ||
        cPause != null ||
        cPauseWait != null) {
      await player.setCache(player.state.cache.copyWith(
        mode: cMode != null
            ? CacheMode.fromMpv(cMode)
            : player.state.cache.mode,
        secs: cSecs != null && cSecs < 1000000
            ? _secondsToDuration(cSecs)
            : player.state.cache.secs,
        onDisk: cOnDisk ?? player.state.cache.onDisk,
        pause: cPause ?? player.state.cache.pause,
        pauseWait: cPauseWait != null
            ? _secondsToDuration(cPauseWait)
            : player.state.cache.pauseWait,
      ));
    }

    // Maximum bytes the demuxer may buffer
    final demuxMaxBytes = _prefs.getInt('${_keyPrefix}demuxer-max-bytes');
    if (demuxMaxBytes != null) {
      await player.setDemuxerMaxBytes(demuxMaxBytes);
    }

    // Demuxer read-ahead duration in seconds
    final demuxReadahead = _prefs.getInt('${_keyPrefix}demuxer-readahead-secs');
    if (demuxReadahead != null) {
      await player.setDemuxerReadaheadSecs(demuxReadahead);
    }

    // Maximum bytes the demuxer keeps for backward seeking
    final demuxMaxBack = _prefs.getInt('${_keyPrefix}demuxer-max-back-bytes');
    if (demuxMaxBack != null) {
      await player.setDemuxerMaxBackBytes(demuxMaxBack);
    }

    // ── Network ──────────────────────────────────────────────────────────────

    // Network request timeout (Duration since 0.1.0)
    final networkTimeout = _prefs.getDouble('${_keyPrefix}network-timeout');
    if (networkTimeout != null) {
      await player.setNetworkTimeout(_secondsToDuration(networkTimeout));
    }

    // Enable TLS certificate verification
    final tlsVerify = _prefs.getBool('${_keyPrefix}tls-verify');
    if (tlsVerify != null) {
      await player.setTlsVerify(tlsVerify);
    }

    // ── Streaming & Misc ─────────────────────────────────────────────────────

    // Keep audio device open with silence when idle
    final streamSilence = _prefs.getBool('${_keyPrefix}audio-stream-silence');
    if (streamSilence != null) {
      await player.setAudioStreamSilence(streamSilence);
    }

    // Null audio output runs without timing (useful for benchmarking)
    final audioNullUntimed = _prefs.getBool('${_keyPrefix}ao-null-untimed');
    if (audioNullUntimed != null) {
      await player.setAudioNullUntimed(audioNullUntimed);
    }

    // Active audio track ID — saved as int via stream.currentAudioTrack.
    // Negative sentinel = no track persisted; defer to mpv's auto choice.
    final audioTrackId = _prefs.getInt('${_keyPrefix}aid');
    if (audioTrackId != null && audioTrackId >= 0) {
      await player.setAudioTrack(audioTrackId);
    }
  }
}
