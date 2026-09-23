// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

void main() {
  group('PlayerState defaults — coherence with mpv defaults', () {
    test('lifecycle flags start false', () {
      const s = PlayerState();
      expect(s.playing, isFalse);
      expect(s.completed, isFalse);
      expect(s.buffering, isFalse);
      expect(s.shuffle, isFalse);
      expect(s.mute, isFalse);
    });

    test('volume / rate / pitch start at neutral', () {
      const s = PlayerState();
      expect(s.volume, 100.0);
      expect(s.rate, 1.0);
      expect(s.pitch, 1.0);
      expect(s.pitchCorrection, isTrue);
    });

    test('playlist starts empty', () {
      const s = PlayerState();
      expect(s.playlist, Playlist.empty);
      expect(s.loop, Loop.off);
    });

    test('Duration fields default to mpv-aligned values', () {
      const s = PlayerState();
      expect(s.position, Duration.zero);
      expect(s.duration, Duration.zero);
      expect(s.buffer, Duration.zero);
      expect(s.audioDelay, Duration.zero);
      expect(
        s.cache.secs,
        const Duration(hours: 1000),
        reason: 'matches mpv `--cache-secs` default (~1000h)',
      );
      expect(
        s.cache.pauseWait,
        const Duration(seconds: 1),
        reason: 'matches mpv `--cache-pause-wait=1.0`',
      );
      expect(
        s.networkTimeout,
        const Duration(seconds: 60),
        reason: 'matches mpv `--network-timeout=60`',
      );
      expect(
        s.audioBuffer,
        const Duration(milliseconds: 200),
        reason: 'matches mpv `--audio-buffer=0.2`',
      );
    });

    test('typed enums start at the documented default variant', () {
      // Regression test for 0.1.0: the enum migration must preserve
      // the previous string defaults' semantics.
      const s = PlayerState();
      expect(
        s.gapless,
        Gapless.weak,
        reason: 'matches mpv default `gapless-audio=weak`',
      );
      expect(s.replayGain.mode, ReplayGain.no);
      expect(s.cache.mode, Cache.auto);
      expect(
        s.coverArtAuto,
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
        expect(s.replayGain, const ReplayGainSettings());
        expect(s.replayGain.mode, ReplayGain.no);
        expect(s.replayGain.preamp, 0.0);
        expect(s.replayGain.clip, isFalse);
        expect(s.replayGain.fallback, 0.0);

        expect(s.cache, const CacheSettings());
        expect(s.cache.mode, Cache.auto);
        expect(s.cache.secs, const Duration(hours: 1000));
        expect(s.cache.onDisk, isFalse);
        expect(s.cache.pause, isTrue);
        expect(s.cache.pauseWait, const Duration(seconds: 1));

        expect(s.demuxer, const DemuxerSettings());
        expect(
          s.demuxer.maxBytes,
          150 * 1024 * 1024,
          reason: 'matches mpv `--demuxer-max-bytes=150MiB`',
        );
        expect(
          s.demuxer.maxBackBytes,
          50 * 1024 * 1024,
          reason: 'matches mpv `--demuxer-max-back-bytes=50MiB`',
        );
        expect(
          s.demuxer.readahead,
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
      expect(s.audioBitrate, isNull);
    });

    test('superequalizer absent by default (null slot = not in chain)', () {
      // Bundle slots default to null so unused *Settings classes
      // tree-shake out of consumer binaries; a null slot and a disabled
      // instance are identical on the wire.
      const s = PlayerState();
      expect(s.audioEffects.superequalizer, isNull);
    });

    test('acompressor / loudnorm / rubberband all start absent', () {
      const s = PlayerState();
      expect(s.audioEffects.acompressor, isNull);
      expect(s.audioEffects.loudnorm, isNull);
      expect(s.audioEffects.rubberband, isNull);
    });

    test('default-constructed AudioEffects emits an empty af chain', () {
      // Every libavfilter audio filter is a typed Settings on the bundle;
      // the bundle is the source of truth for mpv's `af` property and
      // `toAfChain()` returns '' when nothing is enabled.
      const s = PlayerState();
      expect(s.audioEffects.toAfChain(), '');
    });

    test('audioParams + audioOutParams default to all-null AudioParams', () {
      const s = PlayerState();
      expect(s.audioParams, const AudioParams());
      expect(s.audioOutParams, const AudioParams());
    });

    test('audioDevices default contains a single Auto entry', () {
      const s = PlayerState();
      expect(s.audioDevices.length, 1);
      expect(s.audioDevices.first.name, 'auto');
    });

    test('prefetchPlaylist defaults to false (mpv 0.41 default)', () {
      const s = PlayerState();
      expect(s.prefetchPlaylist, isFalse);
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
      const a = PlayerState(volume: 75.0, mute: true);
      final b = a.copyWith();
      expect(a, b);
    });

    test('copyWith preserves other fields', () {
      const a = PlayerState(volume: 50.0, mute: true);
      final b = a.copyWith(volume: 75.0);
      expect(b.volume, 75.0);
      expect(
        b.mute,
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
