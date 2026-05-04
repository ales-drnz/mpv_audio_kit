// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../models/device.dart';
import '../models/media.dart';
import '../types/enums/cover.dart';
import '../types/enums/format.dart';
import '../types/enums/gapless.dart';
import '../types/enums/hook.dart';
import '../types/enums/loop.dart';
import '../types/enums/spdif.dart';
import '../types/sealed/channels.dart';
import '../types/sealed/track.dart';
import '../types/settings/audio_effects_settings.dart';
import '../types/settings/cache_settings.dart';
import '../types/settings/replay_gain_settings.dart';
import '../types/settings/spectrum_settings.dart';
import 'player_configuration.dart';
import 'player_state.dart';
import 'player_stream.dart';

/// Public surface of the [Player] — every method, getter, and stream a
/// consumer interacts with.
///
/// Exists so test code can mock the player cleanly:
///
/// ```dart
/// class MockPlayer extends Mock implements PlayerApi {}
/// ```
///
/// Without this interface a mock would have to extend `Player` itself,
/// which drags in the FFI handle, the event isolate, and the `_PlayerBase`
/// initialization — none of that is mockable in a unit test.
///
/// `Player implements PlayerApi`. Production code that takes a `Player`
/// argument should consider taking a `PlayerApi` instead unless it needs
/// access to extension members not on the interface (none today).
abstract interface class PlayerApi {
  /// The configuration captured at construction time.
  PlayerConfiguration get configuration;

  /// Synchronous snapshot of the player's complete state. Updated on
  /// every observed property change before the corresponding stream
  /// emits.
  PlayerState get state;

  /// Typed event streams for individual state fields and transient
  /// events.
  PlayerStream get stream;

  /// Currently-applied spectrum / PCM pipeline configuration. Mutate via
  /// [setSpectrum] / [updateSpectrum].
  SpectrumSettings get spectrumSettings;

  // ── Lifecycle ──────────────────────────────────────────────────────

  /// Tears down the player. Idempotent.
  Future<void> dispose();

  // ── Loading ────────────────────────────────────────────────────────

  Future<void> open(Media media, {bool? play});

  Future<void> openAll(List<Media> medias, {bool? play, int index = 0});

  // ── Playback ───────────────────────────────────────────────────────

  Future<void> play();
  Future<void> pause();
  Future<void> stop();
  Future<void> seek(Duration position, {bool relative = false});
  Future<void> setChapter(int index);
  Future<void> setAbLoopA(Duration? position);
  Future<void> setAbLoopB(Duration? position);
  Future<void> setAbLoopCount(int? count);

  // ── Playlist ───────────────────────────────────────────────────────

  Future<void> add(Media media);
  Future<void> remove(int index);
  Future<void> next();
  Future<void> previous();
  Future<void> jump(int index);
  Future<void> move(int from, int to);
  Future<void> replace(int index, Media media);
  Future<void> clearPlaylist();
  Future<void> setLoop(Loop mode);
  Future<void> setShuffle(bool shuffle);
  Future<void> setPrefetchPlaylist(bool enabled);

  // ── Audio output ───────────────────────────────────────────────────

  Future<void> setVolume(double volume);
  Future<void> setRate(double rate);
  Future<void> setPitch(double pitch);
  Future<void> setMute(bool mute);
  Future<void> setAudioDevice(Device device);
  Future<void> setPitchCorrection(bool enable);
  Future<void> setAudioDelay(Duration delay);
  Future<void> setGapless(Gapless mode);
  Future<void> setReplayGain(ReplayGainSettings config);
  Future<void> setVolumeGain(double gainDb);
  Future<void> setVolumeMax(double max);
  Future<void> setAudioExclusive(bool exclusive);
  Future<void> setAudioSpdif(Set<Spdif> codecs);
  Future<void> setAudioTrack(Track mode);
  Future<void> reloadAudio();
  Future<void> setAudioEffects(AudioEffects effects);
  Future<void> updateAudioEffects(AudioEffects Function(AudioEffects) mapper);
  Future<void> setCoverArtAuto(Cover mode);
  Future<void> setAudioSampleRate(int rate);
  Future<void> setAudioFormat(Format format);
  Future<void> setAudioChannels(Channels channels);
  Future<void> setAudioClientName(String name);
  Future<void> setAudioDriver(String driver);
  Future<void> setSpectrum(SpectrumSettings settings);
  Future<void> updateSpectrum(
      SpectrumSettings Function(SpectrumSettings) mapper);

  // ── Cache / network ────────────────────────────────────────────────

  Future<void> setCache(CacheSettings config);
  Future<void> setAudioBuffer(Duration size);
  Future<void> setAudioStreamSilence(bool enable);
  Future<void> setNetworkTimeout(Duration timeout);
  Future<void> setTlsVerify(bool enable);
  Future<void> setDemuxerMaxBytes(int bytes);
  Future<void> setDemuxerMaxBackBytes(int bytes);
  Future<void> setDemuxerReadaheadSecs(int seconds);
  Future<void> setAudioNullUntimed(bool enable);

  // ── Hooks ──────────────────────────────────────────────────────────

  void registerHook(Hook hook, {int priority = 0, Duration? timeout});
  void continueHook(int id);

  // ── Raw escape hatch ───────────────────────────────────────────────

  Future<String?> getRawProperty(String name);
  Future<void> setRawProperty(String name, String value);
  Future<void> sendRawCommand(List<String> args);
}
