import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

/// A service to persist and restore player settings across app restarts.
class SettingsService {
  static const String _keyPrefix = 'audio_kit_';

  final SharedPreferences _prefs;

  SettingsService(this._prefs);

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
    } else if (value is List<String>) {
      await _prefs.setStringList(fullKey, value);
    } else if (value is List<double>) {
      await _prefs.setString(fullKey, jsonEncode(value));
    }
  }

  /// Restores all saved settings to the [player] instance.
  Future<void> restore(Player player) async {
    // Volume & Basic Controls
    final volume = _prefs.getDouble('${_keyPrefix}volume');
    if (volume != null) {
      await player.setVolume(volume);
    }

    final volumeMax = _prefs.getDouble('${_keyPrefix}volume-max');
    if (volumeMax != null) {
      await player.setVolumeMax(volumeMax);
    }

    final rate = _prefs.getDouble('${_keyPrefix}rate');
    if (rate != null) {
      await player.setRate(rate);
    }

    final pitch = _prefs.getDouble('${_keyPrefix}pitch');
    if (pitch != null) {
      await player.setPitch(pitch);
    }

    final mute = _prefs.getBool('${_keyPrefix}mute');
    if (mute != null) {
      await player.setMute(mute);
    }

    // Playlist / Playback Mode
    final mode = _prefs.getString('${_keyPrefix}playlist_mode');
    if (mode != null) {
      final pMode = PlaylistMode.values.firstWhere(
        (e) => e.name == mode,
        orElse: () => PlaylistMode.none,
      );
      await player.setPlaylistMode(pMode);
    }

    final shuffle = _prefs.getBool('${_keyPrefix}shuffle');
    if (shuffle != null) {
      await player.setShuffle(shuffle);
    }

    // Audio Engine / DSP
    final eqGains = _prefs.getString('${_keyPrefix}equalizer_gains');
    if (eqGains != null) {
      final List<dynamic> decoded = jsonDecode(eqGains);
      final gains = decoded.map((e) => (e as num).toDouble()).toList();
      player.setEqualizerGains(gains);
    }

    final gapless = _prefs.getString('${_keyPrefix}gapless-audio');
    if (gapless != null) {
      await player.setGaplessPlayback(gapless);
    }

    final replaygain = _prefs.getString('${_keyPrefix}replaygain');
    if (replaygain != null) {
      await player.setReplayGain(replaygain);
    }

    final replaygainPreamp = _prefs.getDouble('${_keyPrefix}replaygain-preamp');
    if (replaygainPreamp != null) {
      await player.setReplayGainPreamp(replaygainPreamp);
    }

    final replaygainFallback = _prefs.getDouble('${_keyPrefix}replaygain-fallback');
    if (replaygainFallback != null) {
      await player.setReplayGainFallback(replaygainFallback);
    }

    final replaygainClip = _prefs.getBool('${_keyPrefix}replaygain-clip');
    if (replaygainClip != null) {
      await player.setReplayGainClip(replaygainClip);
    }

    final volumeGain = _prefs.getDouble('${_keyPrefix}volume-gain');
    if (volumeGain != null) {
      await player.setVolumeGain(volumeGain);
    }

    final pitchCorrection = _prefs.getBool('${_keyPrefix}pitch-correction');
    if (pitchCorrection != null) {
      await player.setPitchCorrection(pitchCorrection);
    }

    final audioDelay = _prefs.getDouble('${_keyPrefix}audio-delay');
    if (audioDelay != null) {
      await player.setAudioDelay(audioDelay);
    }

    // Routing & Hardware
    final sampleRate = _prefs.getInt('${_keyPrefix}audio-samplerate');
    if (sampleRate != null) {
      await player.setAudioSampleRate(sampleRate);
    }

    final format = _prefs.getString('${_keyPrefix}audio-format');
    if (format != null && format != 'no' && format != 'auto') {
      await player.setAudioFormat(format);
    }

    final channels = _prefs.getString('${_keyPrefix}audio-channels');
    if (channels != null && channels != 'auto' && channels != 'no') {
      await player.setAudioChannels(channels);
    }

    final clientName = _prefs.getString('${_keyPrefix}audio-client-name');
    if (clientName != null) {
      await player.setAudioClientName(clientName);
    }

    final deviceName = _prefs.getString('${_keyPrefix}audio-device');
    if (deviceName != null) {
      await player.setAudioDevice(AudioDevice(deviceName, deviceName));
    }

    final spdif = _prefs.getString('${_keyPrefix}audio-spdif');
    if (spdif != null) {
      await player.setAudioSpdif(spdif);
    }

    final exclusive = _prefs.getBool('${_keyPrefix}audio-exclusive');
    if (exclusive != null) {
      await player.setAudioExclusive(exclusive);
    }

    final audioBuffer = _prefs.getDouble('${_keyPrefix}audio-buffer');
    if (audioBuffer != null) {
      await player.setAudioBuffer(audioBuffer);
    }

    // Cache & Demuxer
    final cacheMode = _prefs.getString('${_keyPrefix}cache');
    if (cacheMode != null) {
      await player.setCache(cacheMode);
    }

    final cacheSecs = _prefs.getDouble('${_keyPrefix}cache-secs');
    if (cacheSecs != null && cacheSecs < 1000000) {
      await player.setCacheSecs(cacheSecs);
    }

    final cacheOnDisk = _prefs.getBool('${_keyPrefix}cache-on-disk');
    if (cacheOnDisk != null) {
      await player.setCacheOnDisk(cacheOnDisk);
    }

    final cachePause = _prefs.getBool('${_keyPrefix}cache-pause');
    if (cachePause != null) {
      await player.setCachePause(cachePause);
    }

    final cachePauseWait = _prefs.getDouble('${_keyPrefix}cache-pause-wait');
    if (cachePauseWait != null) {
      await player.setCachePauseWait(cachePauseWait);
    }

    final demuxMaxBytes = _prefs.getInt('${_keyPrefix}demuxer-max-bytes');
    if (demuxMaxBytes != null) {
      await player.setDemuxerMaxBytes(demuxMaxBytes);
    }

    final demuxReadahead = _prefs.getInt('${_keyPrefix}demuxer-readahead-secs');
    if (demuxReadahead != null) {
      await player.setDemuxerReadaheadSecs(demuxReadahead);
    }

    final demuxMaxBack = _prefs.getInt('${_keyPrefix}demuxer-max-back-bytes');
    if (demuxMaxBack != null) {
      await player.setDemuxerMaxBackBytes(demuxMaxBack);
    }

    // Network
    final networkTimeout = _prefs.getDouble('${_keyPrefix}network-timeout');
    if (networkTimeout != null) {
      await player.setNetworkTimeout(networkTimeout);
    }

    final tlsVerify = _prefs.getBool('${_keyPrefix}tls-verify');
    if (tlsVerify != null) {
      await player.setTlsVerify(tlsVerify);
    }

    final streamSilence = _prefs.getBool('${_keyPrefix}stream-silence');
    if (streamSilence != null) {
      await player.setStreamSilence(streamSilence);
    }

    final aoNullUntimed = _prefs.getBool('${_keyPrefix}ao-null-untimed');
    if (aoNullUntimed != null) {
      await player.setAoNullUntimed(aoNullUntimed);
    }

    final audioTrack = _prefs.getString('${_keyPrefix}aid');
    if (audioTrack != null && audioTrack != '' && audioTrack != 'no') {
      await player.setAudioTrack(audioTrack);
    }
  }
}
