import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

/// Persists Player settings across app restarts.
///
/// Single source of truth for what is persisted and how — every property
/// is wired with one declarative line in [wire]. Each binding handles
/// both directions:
///   - **Restore**: read from SharedPreferences (with stale-type cleanup)
///     and apply to the live Player on first call.
///   - **Save**: subscribe to the matching stream and write back on every
///     change.
///
/// Adding a new persistent property = one line in [wire]. No matching
/// pair to maintain in [player_page.dart].
class SettingsService {
  static const String _keyPrefix = 'audio_kit_';

  final SharedPreferences _prefs;
  final List<StreamSubscription<dynamic>> _subs = [];

  SettingsService(this._prefs);

  static Future<SettingsService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsService(prefs);
  }

  /// Cancels every persistence subscription. Call from app shutdown if
  /// you ever construct more than one [SettingsService] in a process.
  Future<void> dispose() async {
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
  }

  /// Wires save + restore for every persisted property in one pass.
  /// Call once after Player construction.
  Future<void> wire(Player player) async {
    // ── Volume / playback transport ───────────────────────────────────
    await _bindDouble(player.stream.volume, 'volume', player.setVolume);
    await _bindDouble(player.stream.volumeMax, 'volume-max', player.setVolumeMax);
    await _bindDouble(player.stream.volumeGain, 'volume-gain', player.setVolumeGain);
    await _bindDouble(player.stream.rate, 'rate', player.setRate);
    await _bindDouble(player.stream.pitch, 'pitch', player.setPitch);
    await _bindBool(player.stream.mute, 'mute', player.setMute);
    await _bindBool(player.stream.pitchCorrection, 'pitch-correction',
        player.setPitchCorrection);
    await _bindDuration(
        player.stream.audioDelay, 'audio-delay', player.setAudioDelay);

    // ── Playlist mode + shuffle ───────────────────────────────────────
    await _bindEnumByName<LoopMode>(
      player.stream.loop,
      'playlist_mode',
      LoopMode.values,
      player.setLoop,
    );
    await _bindBool(player.stream.shuffle, 'shuffle', player.setShuffle);
    await _bindBool(player.stream.prefetchPlaylist, 'prefetch-playlist',
        player.setPrefetchPlaylist);

    // ── Audio output / driver / device ────────────────────────────────
    await _bindString(player.stream.audioDriver, 'ao', player.setAudioDriver);
    await _bindMapped<AudioDevice, String>(
      stream: player.stream.audioDevice,
      key: 'audio-device',
      apply: player.setAudioDevice,
      toStored: (d) => d.name,
      fromStored: (s) => AudioDevice(s, s),
    );
    await _bindString(
        player.stream.audioSpdif, 'audio-spdif', player.setAudioSpdif);
    await _bindBool(player.stream.audioExclusive, 'audio-exclusive',
        player.setAudioExclusive);
    await _bindDuration(
        player.stream.audioBuffer, 'audio-buffer', player.setAudioBuffer);
    await _bindBool(player.stream.audioStreamSilence, 'audio-stream-silence',
        player.setAudioStreamSilence);
    await _bindBool(player.stream.audioNullUntimed, 'ao-null-untimed',
        player.setAudioNullUntimed);

    // ── Audio signal format ───────────────────────────────────────────
    await _bindInt(player.stream.audioSampleRate, 'audio-samplerate',
        player.setAudioSampleRate);
    await _bindString(
        player.stream.audioFormat, 'audio-format', player.setAudioFormat);
    await _bindString(player.stream.audioChannels, 'audio-channels',
        player.setAudioChannels);
    await _bindString(player.stream.audioClientName, 'audio-client-name',
        player.setAudioClientName);

    // ── DSP ───────────────────────────────────────────────────────────
    await _bindEqualizerGains(player);

    // ── Aggregates (cache, replayGain) ────────────────────────────────
    await _bindCache(player);
    await _bindReplayGain(player);
    await _bindMpvEnum<GaplessMode>(
      player.stream.gapless,
      'gapless-audio',
      GaplessMode.fromMpv,
      player.setGapless,
    );

    // ── Demuxer ───────────────────────────────────────────────────────
    await _bindInt(player.stream.demuxerMaxBytes, 'demuxer-max-bytes',
        player.setDemuxerMaxBytes);
    await _bindInt(player.stream.demuxerReadaheadSecs,
        'demuxer-readahead-secs', player.setDemuxerReadaheadSecs);
    await _bindInt(player.stream.demuxerMaxBackBytes,
        'demuxer-max-back-bytes', player.setDemuxerMaxBackBytes);

    // ── Network ───────────────────────────────────────────────────────
    await _bindDuration(player.stream.networkTimeout, 'network-timeout',
        player.setNetworkTimeout);
    await _bindBool(player.stream.tlsVerify, 'tls-verify', player.setTlsVerify);

    // ── Cover art ─────────────────────────────────────────────────────
    await _bindMpvEnum<AudioDisplayMode>(
      player.stream.audioDisplay,
      'audio-display',
      AudioDisplayMode.fromMpv,
      player.setAudioDisplay,
    );
    await _bindMpvEnum<CoverArtAutoMode>(
      player.stream.coverArtAuto,
      'cover-art-auto',
      CoverArtAutoMode.fromMpv,
      player.setCoverArtAuto,
    );

    // ── Active audio track ────────────────────────────────────────────
    await _bindAudioTrack(player);
  }

  // ── Generic helpers ─────────────────────────────────────────────────
  //
  // Each helper:
  //   1. reads the stored value with stale-type cleanup (untyped get +
  //      runtime check, so a value saved by an older app build with a
  //      different type doesn't throw _TypeError),
  //   2. applies it to the player,
  //   3. subscribes to the stream and writes every future emit.

  Future<void> _bindBool(
    Stream<bool> stream,
    String key,
    Future<void> Function(bool) apply,
  ) async {
    final fk = '$_keyPrefix$key';
    final raw = _prefs.get(fk);
    if (raw is bool) {
      await apply(raw);
    } else if (raw != null) {
      await _prefs.remove(fk);
    }
    _subs.add(stream.listen((v) => _prefs.setBool(fk, v)));
  }

  Future<void> _bindInt(
    Stream<int> stream,
    String key,
    Future<void> Function(int) apply,
  ) async {
    final fk = '$_keyPrefix$key';
    final raw = _prefs.get(fk);
    if (raw is int) {
      await apply(raw);
    } else if (raw != null) {
      await _prefs.remove(fk);
    }
    _subs.add(stream.listen((v) => _prefs.setInt(fk, v)));
  }

  Future<void> _bindDouble(
    Stream<double> stream,
    String key,
    Future<void> Function(double) apply,
  ) async {
    final fk = '$_keyPrefix$key';
    final raw = _prefs.get(fk);
    if (raw is double) {
      await apply(raw);
    } else if (raw != null) {
      await _prefs.remove(fk);
    }
    _subs.add(stream.listen((v) => _prefs.setDouble(fk, v)));
  }

  Future<void> _bindString(
    Stream<String> stream,
    String key,
    Future<void> Function(String) apply,
  ) async {
    final fk = '$_keyPrefix$key';
    final raw = _prefs.get(fk);
    if (raw is String) {
      await apply(raw);
    } else if (raw != null) {
      await _prefs.remove(fk);
    }
    _subs.add(stream.listen((v) => _prefs.setString(fk, v)));
  }

  /// `Duration` <-> `double` (seconds, fractional).
  Future<void> _bindDuration(
    Stream<Duration> stream,
    String key,
    Future<void> Function(Duration) apply,
  ) async {
    final fk = '$_keyPrefix$key';
    final raw = _prefs.get(fk);
    if (raw is double) {
      // Defensive: previous app builds wrote tens-of-seconds-as-int; an
      // unreasonably large value (> 1e6 seconds = ~12 days) is almost
      // certainly corrupt. Skip rather than apply.
      if (raw < 1e6) {
        await apply(Duration(microseconds: (raw * 1e6).round()));
      }
    } else if (raw != null) {
      await _prefs.remove(fk);
    }
    _subs.add(stream.listen(
        (v) => _prefs.setDouble(fk, v.inMicroseconds / 1e6)));
  }

  /// Enum stored by `.name` — for Dart-native enums like [LoopMode].
  Future<void> _bindEnumByName<E extends Enum>(
    Stream<E> stream,
    String key,
    List<E> values,
    Future<void> Function(E) apply,
  ) async {
    final fk = '$_keyPrefix$key';
    final raw = _prefs.get(fk);
    if (raw is String) {
      final found = values.where((e) => e.name == raw).cast<E?>().firstOrNull;
      if (found != null) {
        await apply(found);
      } else {
        await _prefs.remove(fk);
      }
    } else if (raw != null) {
      await _prefs.remove(fk);
    }
    _subs.add(stream.listen((v) => _prefs.setString(fk, v.name)));
  }

  /// Enum stored by `.mpvValue` — for the package-level enums (those
  /// expose `.fromMpv` / `.mpvValue` on the wire format mpv uses).
  Future<void> _bindMpvEnum<E>(
    Stream<E> stream,
    String key,
    E Function(String raw) fromMpv,
    Future<void> Function(E) apply,
  ) async {
    final fk = '$_keyPrefix$key';
    final raw = _prefs.get(fk);
    if (raw is String) {
      await apply(fromMpv(raw));
    } else if (raw != null) {
      await _prefs.remove(fk);
    }
    _subs.add(stream.listen(
        (v) => _prefs.setString(fk, (v as dynamic).mpvValue as String)));
  }

  /// Bidirectional mapped binding for non-primitive values stored as
  /// strings (e.g. `AudioDevice` ↔ `AudioDevice.name`).
  Future<void> _bindMapped<T, S>({
    required Stream<T> stream,
    required String key,
    required Future<void> Function(T) apply,
    required S Function(T) toStored,
    required T Function(S) fromStored,
  }) async {
    final fk = '$_keyPrefix$key';
    final raw = _prefs.get(fk);
    if (raw is S) {
      await apply(fromStored(raw));
    } else if (raw != null) {
      await _prefs.remove(fk);
    }
    _subs.add(stream.listen((v) {
      final s = toStored(v);
      if (s is String) {
        _prefs.setString(fk, s);
      } else if (s is int) {
        _prefs.setInt(fk, s);
      }
    }));
  }

  // ── Special-case bindings ───────────────────────────────────────────

  /// `EqualizerConfig.gains` is `List<double>` — JSON-encoded as String.
  Future<void> _bindEqualizerGains(Player player) async {
    const fk = '${_keyPrefix}equalizer_gains';
    final raw = _prefs.get(fk);
    if (raw is String) {
      try {
        final decoded = (jsonDecode(raw) as List<dynamic>)
            .map((e) => (e as num).toDouble())
            .toList();
        await player
            .setEqualizer(player.state.equalizer.copyWith(gains: decoded));
      } catch (_) {
        await _prefs.remove(fk);
      }
    } else if (raw != null) {
      await _prefs.remove(fk);
    }
    _subs.add(player.stream.equalizer
        .listen((cfg) => _prefs.setString(fk, jsonEncode(cfg.gains))));
  }

  /// `CacheConfig` is a 5-field aggregate — restore each field
  /// independently (preserving the in-memory default for missing keys),
  /// then save the whole config on every emit.
  Future<void> _bindCache(Player player) async {
    final mode = _prefs.get('${_keyPrefix}cache');
    final secs = _prefs.get('${_keyPrefix}cache-secs');
    final onDisk = _prefs.get('${_keyPrefix}cache-on-disk');
    final pause = _prefs.get('${_keyPrefix}cache-pause');
    final pauseWait = _prefs.get('${_keyPrefix}cache-pause-wait');
    if (mode is String ||
        secs is double ||
        onDisk is bool ||
        pause is bool ||
        pauseWait is double) {
      final c = player.state.cache;
      await player.setCache(c.copyWith(
        mode: mode is String ? CacheMode.fromMpv(mode) : c.mode,
        secs: secs is double && secs < 1e6
            ? Duration(microseconds: (secs * 1e6).round())
            : c.secs,
        onDisk: onDisk is bool ? onDisk : c.onDisk,
        pause: pause is bool ? pause : c.pause,
        pauseWait: pauseWait is double
            ? Duration(microseconds: (pauseWait * 1e6).round())
            : c.pauseWait,
      ));
    }
    _subs.add(player.stream.cache.listen((c) {
      _prefs.setString('${_keyPrefix}cache', c.mode.mpvValue);
      _prefs.setDouble(
          '${_keyPrefix}cache-secs', c.secs.inMicroseconds / 1e6);
      _prefs.setBool('${_keyPrefix}cache-on-disk', c.onDisk);
      _prefs.setBool('${_keyPrefix}cache-pause', c.pause);
      _prefs.setDouble('${_keyPrefix}cache-pause-wait',
          c.pauseWait.inMicroseconds / 1e6);
    }));
  }

  /// `ReplayGainConfig` is a 4-field aggregate — same shape as `_bindCache`.
  Future<void> _bindReplayGain(Player player) async {
    final mode = _prefs.get('${_keyPrefix}replaygain');
    final preamp = _prefs.get('${_keyPrefix}replaygain-preamp');
    final fallback = _prefs.get('${_keyPrefix}replaygain-fallback');
    final clip = _prefs.get('${_keyPrefix}replaygain-clip');
    if (mode is String ||
        preamp is double ||
        fallback is double ||
        clip is bool) {
      final c = player.state.replayGain;
      await player.setReplayGain(c.copyWith(
        mode: mode is String ? ReplayGainMode.fromMpv(mode) : c.mode,
        preamp: preamp is double ? preamp : c.preamp,
        fallback: fallback is double ? fallback : c.fallback,
        clip: clip is bool ? clip : c.clip,
      ));
    }
    _subs.add(player.stream.replayGain.listen((c) {
      _prefs.setString('${_keyPrefix}replaygain', c.mode.mpvValue);
      _prefs.setDouble('${_keyPrefix}replaygain-preamp', c.preamp);
      _prefs.setDouble('${_keyPrefix}replaygain-fallback', c.fallback);
      _prefs.setBool('${_keyPrefix}replaygain-clip', c.clip);
    }));
  }

  /// Active audio track id — int with negative sentinel for "no track
  /// persisted; defer to mpv auto choice".
  Future<void> _bindAudioTrack(Player player) async {
    const fk = '${_keyPrefix}aid';
    final raw = _prefs.get(fk);
    if (raw is int && raw >= 0) {
      await player.setAudioTrack(AudioTrackMode.id(raw));
    } else if (raw != null && raw is! int) {
      await _prefs.remove(fk);
    }
    _subs.add(player.stream.currentAudioTrack
        .listen((t) => _prefs.setInt(fk, t?.id ?? -1)));
  }
}
