// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:async';

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

/// Verifies that every public setter on [Player] is reachable through
/// [PlayerApi]. The interface exists precisely so consumers can mock the
/// player (`class MockPlayer extends Mock implements PlayerApi {}`) — a
/// missing setter is an accidental API hole that breaks mockability.
class _ApiProbe implements PlayerApi {
  final List<String> calls = [];

  Future<void> _record(String name) async {
    calls.add(name);
  }

  @override
  PlayerConfiguration get configuration => const PlayerConfiguration();

  @override
  PlayerState get state => const PlayerState();

  @override
  PlayerStream get stream => throw UnimplementedError();

  @override
  SpectrumSettings get spectrumSettings => const SpectrumSettings();

  @override
  Future<void> dispose() => _record('dispose');

  @override
  Future<void> open(Media media, {bool? play}) => _record('open');

  @override
  Future<void> openAll(List<Media> medias, {bool? play, int index = 0}) =>
      _record('openAll');

  @override
  Future<void> openPlaylistFile(Media playlist, {bool? play}) =>
      _record('openPlaylistFile');

  @override
  Future<void> play() => _record('play');

  @override
  Future<void> pause() => _record('pause');

  @override
  Future<void> stop() => _record('stop');

  @override
  Future<void> seekToPercent(double percent,
          {bool relative = false, bool exact = false,}) =>
      _record('seekToPercent');

  @override
  Future<void> revertSeek() => _record('revertSeek');

  @override
  Future<void> seek(Duration position,
          {bool relative = false, bool exact = false,}) =>
      _record('seek');

  @override
  Future<void> setChapter(int index) => _record('setChapter');

  @override
  Future<void> setChapters(List<Chapter> chapters) => _record('setChapters');

  @override
  Future<void> setAbLoopA(Duration? position) => _record('setAbLoopA');

  @override
  Future<void> setAbLoopB(Duration? position) => _record('setAbLoopB');

  @override
  Future<void> setAbLoopCount(int? count) => _record('setAbLoopCount');

  @override
  Future<void> writeResumeConfig() => _record('writeResumeConfig');

  @override
  Future<void> deleteResumeConfig({String? filename}) =>
      _record('deleteResumeConfig');

  @override
  Future<void> add(Media media) => _record('add');

  @override
  Future<void> remove(int index) => _record('remove');

  @override
  Future<void> next({bool force = false}) => _record('next');

  @override
  Future<void> previous({bool force = false}) => _record('previous');

  @override
  Future<void> nextPlaylist() => _record('nextPlaylist');

  @override
  Future<void> previousPlaylist() => _record('previousPlaylist');

  @override
  Future<void> jump(int index) => _record('jump');

  @override
  Future<void> move(int from, int to) => _record('move');

  @override
  Future<void> replace(int index, Media media) => _record('replace');

  @override
  Future<void> clearPlaylist() => _record('clearPlaylist');

  @override
  Future<void> setLoop(Loop loop) => _record('setLoop');

  @override
  Future<void> setShuffle(bool shuffle) => _record('setShuffle');

  @override
  Future<void> setPrefetchPlaylist(bool enabled) =>
      _record('setPrefetchPlaylist');

  @override
  Future<void> setVolume(double volume) => _record('setVolume');

  @override
  Future<void> setRate(double rate) => _record('setRate');

  @override
  Future<void> setPitch(double pitch) => _record('setPitch');

  @override
  Future<void> setMute(bool mute) => _record('setMute');

  @override
  Future<void> setAudioDevice(Device device) => _record('setAudioDevice');

  @override
  Future<void> setPitchCorrection(bool enable) => _record('setPitchCorrection');

  @override
  Future<void> setAudioDelay(Duration delay) => _record('setAudioDelay');

  @override
  Future<void> setGapless(Gapless gapless) => _record('setGapless');

  @override
  Future<void> setReplayGain(ReplayGainSettings settings) =>
      _record('setReplayGain');

  @override
  Future<void> setVolumeGain(double gainDb) => _record('setVolumeGain');

  @override
  Future<void> setVolumeGainMin(double gainDb) => _record('setVolumeGainMin');

  @override
  Future<void> setVolumeGainMax(double gainDb) => _record('setVolumeGainMax');

  @override
  Future<void> setVolumeMax(double limit) => _record('setVolumeMax');

  @override
  Future<void> setSystemVolume(double volume) => _record('setSystemVolume');

  @override
  Future<void> setSystemMute(bool mute) => _record('setSystemMute');

  @override
  Future<void> setAudioExclusive(bool exclusive) =>
      _record('setAudioExclusive');

  @override
  Future<void> setAudioMediaRole(bool enable) => _record('setAudioMediaRole');

  @override
  Future<void> setAudioSpdif(Set<Spdif> codecs) => _record('setAudioSpdif');

  @override
  Future<void> setAudioTrack(Track track) => _record('setAudioTrack');

  @override
  Future<void> addAudioTrack(Media file,
          {bool select = true, String? title, String? lang,}) =>
      _record('addAudioTrack');

  @override
  Future<void> removeAudioTrack(Track track) => _record('removeAudioTrack');

  @override
  Future<void> reloadAudio() => _record('reloadAudio');

  @override
  Future<void> rescanExternalFiles({bool keepSelection = false}) =>
      _record('rescanExternalFiles');

  @override
  Future<void> setAudioEffects(AudioEffects effects) =>
      _record('setAudioEffects');

  @override
  Future<void> updateAudioEffects(AudioEffects Function(AudioEffects) mapper) =>
      _record('updateAudioEffects');

  @override
  Future<void> setCoverArtAuto(Cover cover) => _record('setCoverArtAuto');

  @override
  Future<void> setAudioSampleRate(int rate) => _record('setAudioSampleRate');

  @override
  Future<void> setAudioFormat(Format format) => _record('setAudioFormat');

  @override
  Future<void> setAudioChannels(Channels channels) =>
      _record('setAudioChannels');

  @override
  Future<void> setAudioClientName(String name) => _record('setAudioClientName');

  @override
  Future<void> setAudioDriver(String driver) => _record('setAudioDriver');

  @override
  Future<void> setSpectrum(SpectrumSettings settings) => _record('setSpectrum');

  @override
  Future<void> updateSpectrum(
          SpectrumSettings Function(SpectrumSettings) mapper,) =>
      _record('updateSpectrum');

  @override
  Future<void> setCache(CacheSettings settings) => _record('setCache');

  @override
  Future<void> setAudioBuffer(Duration size) => _record('setAudioBuffer');

  @override
  Future<void> setAudioStreamSilence(bool enable) =>
      _record('setAudioStreamSilence');

  @override
  Future<void> setNetworkTimeout(Duration timeout) =>
      _record('setNetworkTimeout');

  @override
  Future<void> setTlsVerify(bool enable) => _record('setTlsVerify');

  @override
  Future<void> setTlsCaFile(String path) => _record('setTlsCaFile');

  @override
  Future<void> setHlsBitrate(HlsBitrate hlsBitrate) =>
      _record('setHlsBitrate');

  @override
  Future<void> setCookies(bool enable) => _record('setCookies');

  @override
  Future<void> setHttpProxy(String url) => _record('setHttpProxy');

  @override
  Future<void> setDemuxer(DemuxerSettings settings) => _record('setDemuxer');

  @override
  Future<void> setAudioNullUntimed(bool enable) =>
      _record('setAudioNullUntimed');

  @override
  Future<void> setMediaSession(MediaSession? session) =>
      _record('setMediaSession');

  @override
  Future<void> registerHook(Hook hook, {int priority = 0, Duration? timeout}) =>
      _record('registerHook');

  @override
  Future<void> continueHook(int id) => _record('continueHook');

  @override
  Future<void> setSourceResolver(SourceResolver? resolver,
          {Duration? timeout = const Duration(seconds: 15),}) =>
      _record('setSourceResolver');

  @override
  Future<String?> getRawProperty(String name) async {
    calls.add('getRawProperty');
    return null;
  }

  @override
  Future<Object?> getRawPropertyNode(String name) async {
    calls.add('getRawPropertyNode');
    return null;
  }

  @override
  Future<void> setRawProperty(String name, String value) =>
      _record('setRawProperty');

  @override
  Future<void> sendRawCommand(List<String> args) => _record('sendRawCommand');

  @override
  Future<void> setLogLevel(LogLevel level) => _record('setLogLevel');
}

void main() {
  group('PlayerApi surface', () {
    test('exposes setTlsCaFile (accidental omission regression)', () async {
      final PlayerApi api = _ApiProbe();
      await api.setTlsCaFile('/etc/ssl/cert.pem');
      expect((api as _ApiProbe).calls, contains('setTlsCaFile'));
    });

    test('exposes setLogLevel through the interface', () async {
      final api = _ApiProbe();
      final PlayerApi typed = api;
      await typed.setLogLevel(LogLevel.debug);
      expect(api.calls, contains('setLogLevel'));
    });

    test('Tls / network setters all reachable through the interface', () async {
      final api = _ApiProbe();
      final PlayerApi typed = api;
      await typed.setTlsVerify(true);
      await typed.setTlsCaFile('/path');
      await typed.setNetworkTimeout(const Duration(seconds: 5));
      await typed.setHlsBitrate(HlsBitrate.min);
      await typed.setCookies(true);
      await typed.setHttpProxy('http://proxy:3128');
      await typed.setCache(const CacheSettings());
      await typed.setDemuxer(const DemuxerSettings());
      await typed.setAudioBuffer(const Duration(milliseconds: 200));
      await typed.setAudioStreamSilence(false);
      await typed.setAudioNullUntimed(false);
      expect(api.calls, [
        'setTlsVerify',
        'setTlsCaFile',
        'setNetworkTimeout',
        'setHlsBitrate',
        'setCookies',
        'setHttpProxy',
        'setCache',
        'setDemuxer',
        'setAudioBuffer',
        'setAudioStreamSilence',
        'setAudioNullUntimed',
      ]);
    });

    test('raw escape hatches all reachable through the interface', () async {
      final api = _ApiProbe();
      final PlayerApi typed = api;
      // Pins getRawPropertyNode onto the interface alongside getRawProperty —
      // both are advertised public escape hatches and must be callable
      // through the documented PlayerApi abstraction (mocking seam).
      await typed.getRawProperty('x');
      await typed.getRawPropertyNode('x');
      await typed.setRawProperty('x', 'y');
      await typed.sendRawCommand(['x']);
      expect(api.calls, [
        'getRawProperty',
        'getRawPropertyNode',
        'setRawProperty',
        'sendRawCommand',
      ]);
    });
  });
}
