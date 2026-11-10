// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

void main() {
  group('PlayerState defaults — coherence with mpv defaults', () {
    test('lifecycle flags start false', () {
      const s = PlayerState();
      expect(s.playback.playing, isFalse);
      expect(s.playback.completed, isFalse);
      expect(s.network.buffering, isFalse);
      expect(s.playback.shuffle, isFalse);
      expect(s.settings.mute, isFalse);
    });

    test('volume / rate / pitch start at neutral', () {
      const s = PlayerState();
      expect(s.settings.volume, 100.0);
      expect(s.settings.rate, 1.0);
      expect(s.settings.pitch, 1.0);
      expect(s.settings.pitchCorrection, isTrue);
    });

    test('playlist starts empty', () {
      const s = PlayerState();
      expect(s.playback.playlist, Playlist.empty);
      expect(s.playback.loop, Loop.off);
    });

    test('Duration fields default to mpv-aligned values', () {
      const s = PlayerState();
      expect(s.playback.position, Duration.zero);
      expect(s.playback.duration, Duration.zero);
      expect(s.network.buffer, Duration.zero);
      expect(s.settings.audioDelay, Duration.zero);
      expect(
        s.settings.cache.secs,
        const Duration(hours: 1000),
        reason: 'matches mpv `--cache-secs` default (~1000h)',
      );
      expect(
        s.settings.cache.pauseWait,
        const Duration(seconds: 1),
        reason: 'matches mpv `--cache-pause-wait=1.0`',
      );
      expect(
        s.settings.networkTimeout,
        const Duration(seconds: 60),
        reason: 'matches mpv `--network-timeout=60`',
      );
      expect(
        s.settings.audioBuffer,
        const Duration(milliseconds: 200),
        reason: 'matches mpv `--audio-buffer=0.2`',
      );
    });

    test('typed enums start at the documented default variant', () {
      // Regression test for 0.1.0: the enum migration must preserve
      // the previous string defaults' semantics.
      const s = PlayerState();
      expect(
        s.settings.gapless,
        Gapless.weak,
        reason: 'matches mpv default `gapless-audio=weak`',
      );
      expect(s.settings.replayGain.mode, ReplayGain.no);
      expect(s.settings.cache.mode, Cache.auto);
      expect(
        s.settings.coverArtAuto,
        Cover.no,
        reason:
            'library default is `no` (mpv default would be `exact`); '
            'we disable to avoid implicit file scanning',
      );
    });

    test(
      'replayGain + cache config defaults aggregate the granular fields',
      () {
        const s = PlayerState();
        expect(s.settings.replayGain, const ReplayGainSettings());
        expect(s.settings.replayGain.mode, ReplayGain.no);
        expect(s.settings.replayGain.preamp, 0.0);
        expect(s.settings.replayGain.clip, isFalse);
        expect(s.settings.replayGain.fallback, 0.0);

        expect(s.settings.cache, const CacheSettings());
        expect(s.settings.cache.mode, Cache.auto);
        expect(s.settings.cache.secs, const Duration(hours: 1000));
        expect(s.settings.cache.onDisk, isFalse);
        expect(s.settings.cache.pause, isTrue);
        expect(s.settings.cache.pauseWait, const Duration(seconds: 1));

        expect(s.settings.demuxer, const DemuxerSettings());
        expect(
          s.settings.demuxer.maxBytes,
          150 * 1024 * 1024,
          reason: 'matches mpv `--demuxer-max-bytes=150MiB`',
        );
        expect(
          s.settings.demuxer.maxBackBytes,
          50 * 1024 * 1024,
          reason: 'matches mpv `--demuxer-max-back-bytes=50MiB`',
        );
        expect(
          s.settings.demuxer.readahead,
          const Duration(seconds: 1),
          reason: 'matches mpv `--demuxer-readahead-secs=1`',
        );
      },
    );

    test('audioBitrate is null by default (unavailable, NOT zero)', () {
      // Regression test: 0.1.0 keeps `audioBitrate` as `double?` with
      // null = "unavailable". A consumer comparing `>0` for "playing
      // a stream" would silently misbehave if this default were 0.0.
      const s = PlayerState();
      expect(s.file.audioBitrate, isNull);
    });

    test('the effects chain starts empty', () {
      const s = PlayerState();
      expect(s.settings.audioEffects, isEmpty);
    });

    test('states with equal effect lists are equal', () {
      // Lists compare by identity in Dart; PlayerState compares the
      // effects element by element.
      const a = PlayerState(
        settings: PlayerSettings(audioEffects: [BassEffect(gain: 3)]),
      );
      const b = PlayerState(
        settings: PlayerSettings(audioEffects: [BassEffect(gain: 3)]),
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('audioParams + audioOutParams default to all-null AudioParams', () {
      const s = PlayerState();
      expect(s.file.audioParams, const AudioParams());
      expect(s.output.audioOutParams, const AudioParams());
    });

    test('audioDevices default contains a single Auto entry', () {
      const s = PlayerState();
      expect(s.output.audioDevices.length, 1);
      expect(s.output.audioDevices.first.name, 'auto');
    });

    test('prefetchPlaylist defaults to false (mpv 0.41 default)', () {
      const s = PlayerState();
      expect(s.settings.prefetchPlaylist, isFalse);
    });
  });

  group('PlayerState equality (Freezed-generated)', () {
    test('two default-constructed instances are ==', () {
      // The whole point of moving to Freezed: PlayerState now has
      // structural equality. `StreamBuilder.distinct()` and any
      // `if (newState != oldState)` comparison across the consumer
      // codebase depends on this contract.
      const a = PlayerState();
      const b = PlayerState();
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('one field change → not equal', () {
      const a = PlayerState();
      final b = a.copyWith(volume: 50.0);
      expect(a, isNot(b));
    });

    test('copyWith no-op returns equal instance', () {
      const a = PlayerState(settings: PlayerSettings(volume: 75.0, mute: true));
      final b = a.copyWith();
      expect(a, b);
    });

    test('copyWith preserves other fields', () {
      const a = PlayerState(settings: PlayerSettings(volume: 50.0, mute: true));
      final b = a.copyWith(volume: 75.0);
      expect(b.settings.volume, 75.0);
      expect(
        b.settings.mute,
        isTrue,
        reason: 'unrelated fields must survive a partial copyWith',
      );
    });

    test('Duration fields participate in equality', () {
      const a = PlayerState();
      final b = a.copyWith(audioDelay: const Duration(milliseconds: 50));
      expect(a, isNot(b));
    });

    test('enum fields participate in equality', () {
      const a = PlayerState();
      final b = a.copyWith(gapless: Gapless.yes);
      expect(a, isNot(b));
    });
  });
}
