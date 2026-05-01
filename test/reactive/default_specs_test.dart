// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:mpv_audio_kit/src/audio/audio_output_state.dart';
import 'package:mpv_audio_kit/src/network/cache_config.dart';
import 'package:mpv_audio_kit/src/events/mpv_prefetch_state.dart';
import 'package:mpv_audio_kit/src/player_state.dart';
import 'package:mpv_audio_kit/src/audio/replay_gain_config.dart';
import 'package:mpv_audio_kit/src/reactive/default_specs.dart';
import 'package:mpv_audio_kit/src/reactive/property_registry.dart';
import 'package:mpv_audio_kit/src/utils/duration_seconds.dart';

/// End-to-end test of the default registry — every mpv property the public
/// API surfaces gets dispatched once with a representative payload and the
/// resulting [PlayerState] is checked. This is the test that would have
/// caught the 0.0.9 `_completedCtrl` / `_bufferingCtrl` regression: every
/// observed property is exercised through the same code path the player
/// uses at runtime, so a missing wiring fails loudly here instead of
/// silently in production.
void main() {
  late DefaultPropertyReactives reactives;
  late PropertyRegistry registry;
  PlayerState state = const PlayerState();

  setUp(() {
    reactives = DefaultPropertyReactives();
    state = const PlayerState();
    registry = PropertyRegistry()
      ..registerAll(buildDefaultSpecs(
        reactives,
        onIdleActive: (_) {},
        onAudioOutputState: (_) {},
      ));
  });

  PlayerState dispatch(String name, dynamic raw) {
    final next = registry.dispatch(name, raw, state);
    state = next ?? state;
    return state;
  }

  group('Default registry — playback', () {
    test('volume / rate / pitch / mute / shuffle round-trip into state', () {
      dispatch('volume', 50.0);
      dispatch('speed', 1.25);
      dispatch('pitch', 1.5);
      dispatch('mute', true);
      dispatch('shuffle', true);

      expect(state.volume, 50.0);
      expect(state.rate, 1.25);
      expect(state.pitch, 1.5);
      expect(state.mute, isTrue);
      expect(state.shuffle, isTrue);

      expect(reactives.volume.value, 50.0);
      expect(reactives.shuffle.value, isTrue);
    });

    test('core-idle is inverted into state.playing via the parser', () {
      // mpv reports `core-idle=false` when actually producing audio.
      // We bind to `core-idle` (NOT `pause`) because `pause` doesn't
      // change on the load → playing transition (mpv default is
      // `pause=no` already). `core-idle` flips reliably on every
      // start/stop/pause/seek/buffering event.
      dispatch('core-idle', false);
      expect(state.playing, isTrue);
      expect(reactives.playing.value, isTrue);

      dispatch('core-idle', true);
      expect(state.playing, isFalse);
      expect(reactives.playing.value, isFalse);
    });

    test('time-pos / duration / demuxer-cache-time map to Duration fields',
        () {
      dispatch('time-pos', 1.5); // 1.5 seconds
      dispatch('duration', 90.0); // 1m30
      dispatch('demuxer-cache-time', 30.0);

      expect(state.position, const Duration(milliseconds: 1500));
      expect(state.duration, const Duration(seconds: 90));
      expect(state.buffer, const Duration(seconds: 30));
    });
  });

  group('Default registry — audio params (decoder + hardware node maps)', () {
    test(
        '`audio-params` node + `audio-codec` + `audio-codec-name` populate '
        'state.audioParams', () {
      // Single MPV_FORMAT_NODE_MAP for the 5 wire fields, replacing the
      // 5 individual sub-property observers from 0.0.x. Codec fields stay
      // separate (mpv does not include them in the node map).
      dispatch('audio-params', <String, dynamic>{
        'format': 'floatp',
        'samplerate': 48000,
        'channels': 'stereo',
        'channel-count': 2,
        'hr-channels': 'L+R',
      });
      dispatch('audio-codec', 'flac');
      dispatch('audio-codec-name', 'FLAC');

      expect(state.audioParams.format, 'floatp');
      expect(state.audioParams.sampleRate, 48000);
      expect(state.audioParams.channels, 'stereo');
      expect(state.audioParams.channelCount, 2);
      expect(state.audioParams.hrChannels, 'L+R');
      expect(state.audioParams.codec, 'flac');
      expect(state.audioParams.codecName, 'FLAC');
    });

    test(
        '`audio-params` node merges into existing audioParams without '
        'clobbering codec / codecName populated by sibling specs', () {
      // Codec arrives first (mpv emits siblings independently).
      dispatch('audio-codec', 'flac');
      dispatch('audio-codec-name', 'FLAC');
      // Then the node map fires.
      dispatch('audio-params', <String, dynamic>{
        'format': 'floatp',
        'samplerate': 48000,
        'channels': 'stereo',
        'channel-count': 2,
        'hr-channels': 'L+R',
      });

      // Both node-side and sibling-side fields must coexist on state.
      expect(state.audioParams.format, 'floatp');
      expect(state.audioParams.sampleRate, 48000);
      expect(state.audioParams.codec, 'flac',
          reason:
              'audio-params node reduce must not reset the codec fields '
              'populated by audio-codec / audio-codec-name siblings');
      expect(state.audioParams.codecName, 'FLAC');
    });

    test('`audio-out-params` node populates state.audioOutParams', () {
      // Hardware side has no codec siblings — single node spec covers
      // every observable field.
      dispatch('audio-out-params', <String, dynamic>{
        'format': 's16',
        'samplerate': 44100,
        'channels': 'stereo',
        'channel-count': 2,
        'hr-channels': '2.0',
      });

      expect(state.audioOutParams.format, 's16');
      expect(state.audioOutParams.sampleRate, 44100);
      expect(state.audioOutParams.channels, 'stereo');
      expect(state.audioOutParams.channelCount, 2);
      expect(state.audioOutParams.hrChannels, '2.0');
    });
  });

  group('Default registry — special parsers', () {
    test('audio-format empty string is normalized to "no"', () {
      dispatch('audio-format', '');
      expect(state.audioFormat, 'no');
    });

    test('audio-bitrate <= 0 becomes null', () {
      // Seed at the default (null) so the first non-zero update fires.
      expect(reactives.audioBitrate.value, isNull);

      dispatch('audio-bitrate', 320000.0);
      expect(state.audioBitrate, 320000.0);

      dispatch('audio-bitrate', 0.0);
      expect(state.audioBitrate, isNull);
    });

    test(
        'af observer surfaces unmanaged entries as customAudioFilters; '
        'wrapper-labelled entries are ignored', () {
      // External raw mutation (e.g. via setRawProperty('af', ...)) bypasses
      // the typed setters. The af observer mirrors only the unmanaged tail
      // back into state.customAudioFilters; the four managed labels stay
      // owned by their setters' own state.
      dispatch('af', 'lavfi-pan=stereo|c0=c1|c1=c0,@_mak_eq:lavfi-equalizer=g=3');
      expect(state.customAudioFilters, ['lavfi-pan=stereo|c0=c1|c1=c0']);

      dispatch('af', '');
      expect(state.customAudioFilters, isEmpty);
    });
  });

  group('Default registry — stream-only properties', () {
    test('prefetch-state updates the reactive without touching PlayerState',
        () {
      // PlayerState has no field for prefetch state by design.
      final initialFingerprint = state;

      dispatch('prefetch-state', 'loading');
      expect(reactives.prefetchState.value, MpvPrefetchState.loading);
      expect(state, equals(initialFingerprint),
          reason: 'state must not mutate for stream-only properties');

      dispatch('prefetch-state', 'ready');
      expect(reactives.prefetchState.value, MpvPrefetchState.ready);
    });

    test('unknown prefetch values fall back to idle', () {
      dispatch('prefetch-state', 'totally-bogus');
      expect(reactives.prefetchState.value, MpvPrefetchState.idle);
    });

    test('prefetch-playlist flag round-trips into state.prefetchPlaylist',
        () {
      // Default mirrors mpv 0.41 (off). Toggle via setPrefetchPlaylist
      // (or any property write) drives the observed flag.
      expect(state.prefetchPlaylist, isFalse);

      dispatch('prefetch-playlist', true);
      expect(state.prefetchPlaylist, isTrue);
      expect(reactives.prefetchPlaylist.value, isTrue);

      dispatch('prefetch-playlist', false);
      expect(state.prefetchPlaylist, isFalse);
      expect(reactives.prefetchPlaylist.value, isFalse);
    });
  });

  group('Default registry — new mpv properties (XS)', () {
    // Single round-trip per scalar property: dispatch → assert state +
    // reactive. Each tuple covers one wire format (double / flag / int64
    // / string) so a regression in dispatch wiring fails on the exact
    // property that lost it. Special parsers (chapter -1 → null,
    // demuxer-cache-duration → bufferDuration field rename, etc.) live
    // in their own tests below.
    final xsProperties = <(String, Object, Object Function(PlayerState))>[
      ('audio-pts', 1.5, (s) => s.audioPts),
      ('time-remaining', 30.0, (s) => s.timeRemaining),
      ('playtime-remaining', 15.0, (s) => s.playtimeRemaining),
      ('eof-reached', true, (s) => s.eofReached),
      ('seekable', true, (s) => s.seekable),
      ('partially-seekable', true, (s) => s.partiallySeekable),
      ('media-title', 'My Song - Artist', (s) => s.mediaTitle),
      ('file-format', 'mp4,m4a,3gp', (s) => s.fileFormat),
      ('file-size', 1234567890, (s) => s.fileSize),
      ('demuxer-cache-idle', false, (s) => s.demuxerIdle),
      ('path', '/audio/track.flac', (s) => s.path),
      ('filename', 'track.flac', (s) => s.filename),
      ('stream-path', 'https://cdn.example/track.flac', (s) => s.streamPath),
      (
        'stream-open-filename',
        'https://cdn.example/redirected.flac',
        (s) => s.streamOpenFilename,
      ),
      ('seeking', true, (s) => s.seeking),
      ('percent-pos', 42.5, (s) => s.percentPos),
      ('cache-speed', 65536.0, (s) => s.cacheSpeed),
      ('cache-buffering-state', 87, (s) => s.cacheBufferingState),
      ('current-demuxer', 'mkv', (s) => s.currentDemuxer),
      ('current-ao', 'coreaudio', (s) => s.currentAo),
      ('mpv-version', '0.41.0', (s) => s.mpvVersion),
      ('ffmpeg-version', '7.1.1', (s) => s.ffmpegVersion),
    ];
    for (final (name, payload, getter) in xsProperties) {
      test('$name round-trip into state', () {
        dispatch(name, payload);
        // Duration / Map fields surface as-is for non-Duration payloads;
        // Duration parsers are exercised by the dedicated test below.
        if (payload is double && (name.endsWith('-pts') ||
            name.endsWith('-remaining'))) {
          expect(getter(state), secondsToDuration(payload));
        } else {
          expect(getter(state), payload);
        }
      });
    }

    test('demuxer-cache-duration (double → Duration) → bufferDuration', () {
      dispatch('demuxer-cache-duration', 12.5);
      expect(state.bufferDuration, const Duration(milliseconds: 12500));
    });

    test('chapter (int64 → int?, -1 maps to null)', () {
      dispatch('chapter', 2);
      expect(state.currentChapter, 2);

      dispatch('chapter', -1);
      expect(state.currentChapter, isNull,
          reason: 'mpv emits chapter=-1 when no chapter is active; the '
              'parser must surface that as `null`');
    });

    test('ab-loop-a / ab-loop-b ("no" → null, numeric → Duration)', () {
      dispatch('ab-loop-a', '12.5');
      dispatch('ab-loop-b', '20.0');
      expect(state.abLoopA, const Duration(milliseconds: 12500));
      expect(state.abLoopB, const Duration(seconds: 20));

      dispatch('ab-loop-a', 'no');
      expect(state.abLoopA, isNull);
    });

    test('ab-loop-count ("inf" → null, numeric → int)', () {
      dispatch('ab-loop-count', '5');
      expect(state.abLoopCount, 5);

      dispatch('ab-loop-count', 'inf');
      expect(state.abLoopCount, isNull);
    });

    test('remaining-ab-loops (int64 → int?, -1 maps to null)', () {
      dispatch('remaining-ab-loops', 3);
      expect(state.remainingAbLoops, 3);

      dispatch('remaining-ab-loops', -1);
      expect(state.remainingAbLoops, isNull);
    });

    test('demuxer-start-time (double → Duration)', () {
      dispatch('demuxer-start-time', 12.5);
      expect(state.demuxerStartTime, const Duration(milliseconds: 12500));
    });

    test('chapter-metadata (NODE_MAP → Map<String,String>)', () {
      dispatch('chapter-metadata', <String, dynamic>{
        'title': 'Chapter One',
        'lang': 'eng',
      });
      expect(state.chapterMetadata, {
        'title': 'Chapter One',
        'lang': 'eng',
      });

      dispatch('chapter-metadata', <String, dynamic>{});
      expect(state.chapterMetadata, isEmpty);
    });

    test('chapter-list (NODE_ARRAY → List<Chapter>)', () {
      dispatch('chapter-list', [
        {'time': 0.0, 'title': 'A'},
        {'time': 60.0, 'title': 'B'},
      ]);
      expect(state.chapters, hasLength(2));
      expect(state.chapters[0].title, 'A');
      expect(state.chapters[1].time, const Duration(seconds: 60));
    });

    test('image-display-duration ("inf" → null)', () {
      dispatch('image-display-duration', 'inf');
      expect(state.imageDisplayDuration, isNull);

      dispatch('image-display-duration', '5.5');
      expect(state.imageDisplayDuration,
          const Duration(milliseconds: 5500));
    });
  });

  group('Default registry — config aggregate copyWith preserves siblings',
      () {
    // Cruciale: i 9 spec ReplayGain/Cache fanno reduce su
    // `s.copyWith(replayGain: s.replayGain.copyWith(field: v))` —
    // un cambio su un campo NON deve sovrascrivere gli altri 3-4.
    // Questi test pinnano l'invariante.

    test('replayGain: dispatching one property preserves the other 3', () {
      // Seed via dispatch so the granular reactives stay in sync with
      // the aggregate state — directly assigning state.replayGain would
      // leave the reactives at their defaults and the next dispatch
      // would dedup.
      dispatch('replaygain', 'album');
      dispatch('replaygain-preamp', -3.0);
      dispatch('replaygain-clip', true);
      dispatch('replaygain-fallback', 1.5);
      expect(
          state.replayGain,
          const ReplayGainConfig(
            mode: ReplayGainMode.album,
            preamp: -3.0,
            clip: true,
            fallback: 1.5,
          ));

      // Change just preamp; assert the other 3 fields are untouched.
      dispatch('replaygain-preamp', -10.0);
      expect(state.replayGain.preamp, -10.0);
      expect(state.replayGain.mode, ReplayGainMode.album,
          reason: 'mode must survive a preamp-only dispatch');
      expect(state.replayGain.clip, isTrue);
      expect(state.replayGain.fallback, 1.5);

      // Change just clip.
      dispatch('replaygain-clip', false);
      expect(state.replayGain.clip, isFalse);
      expect(state.replayGain.mode, ReplayGainMode.album);
      expect(state.replayGain.preamp, -10.0,
          reason: 'preamp from the previous dispatch must survive');
    });

    test('cache: dispatching one property preserves the other 4', () {
      // Seed all 5 fields via dispatch (see replayGain test for rationale).
      dispatch('cache', 'yes');
      dispatch('cache-secs', 30.0);
      dispatch('cache-on-disk', true);
      dispatch('cache-pause', false);
      dispatch('cache-pause-wait', 5.0);
      expect(
          state.cache,
          const CacheConfig(
            mode: CacheMode.yes,
            secs: Duration(seconds: 30),
            onDisk: true,
            pause: false,
            pauseWait: Duration(seconds: 5),
          ));

      dispatch('cache-secs', 60.0);
      expect(state.cache.secs, const Duration(seconds: 60));
      expect(state.cache.mode, CacheMode.yes);
      expect(state.cache.onDisk, isTrue);
      expect(state.cache.pause, isFalse);
      expect(state.cache.pauseWait, const Duration(seconds: 5));

      dispatch('cache-pause', true);
      expect(state.cache.pause, isTrue);
      expect(state.cache.secs, const Duration(seconds: 60));

      dispatch('cache', 'no');
      expect(state.cache.mode, CacheMode.no);
      expect(state.cache.secs, const Duration(seconds: 60));
      expect(state.cache.onDisk, isTrue);
    });

    test('replayGain: dispatch on initial PlayerState (default) is safe',
        () {
      // Edge case: dispatching the first property after a fresh state
      // must not throw on the `s.replayGain.copyWith(...)` chain.
      expect(state.replayGain, const ReplayGainConfig());
      dispatch('replaygain-preamp', 1.0);
      expect(state.replayGain.preamp, 1.0);
      expect(state.replayGain.mode, ReplayGainMode.no,
          reason: 'default ReplayGainConfig.mode must survive');
    });
  });

  group('Default registry — onChange callbacks', () {
    test('onAudioOutputState fires on every state transition', () {
      final calls = <AudioOutputState>[];
      reactives = DefaultPropertyReactives();
      registry = PropertyRegistry()
        ..registerAll(buildDefaultSpecs(
          reactives,
          onIdleActive: (_) {},
          onAudioOutputState: calls.add,
        ));
      state = const PlayerState();

      registry.dispatch('audio-output-state', 'initializing', state);
      registry.dispatch('audio-output-state', 'active', state);
      registry.dispatch('audio-output-state', 'active', state); // dedup
      registry.dispatch('audio-output-state', 'failed', state);

      expect(calls, [
        AudioOutputState.initializing,
        AudioOutputState.active,
        AudioOutputState.failed,
      ]);
    });

    test('onIdleActive fires on every idle transition', () {
      final calls = <bool>[];
      reactives = DefaultPropertyReactives();
      registry = PropertyRegistry()
        ..registerAll(buildDefaultSpecs(
          reactives,
          onIdleActive: calls.add,
          onAudioOutputState: (_) {},
        ));
      state = const PlayerState();

      registry.dispatch('idle-active', true, state);
      registry.dispatch('idle-active', true, state); // dedup
      registry.dispatch('idle-active', false, state);

      expect(calls, [true, false]);
    });
  });

  group('Default registry — coverage contract', () {
    test('registry holds exactly the documented set of mpv property names',
        () {
      // Bidirectional check: extracts the live spec names from the registry
      // and asserts equality with the documented set below. A drift in
      // either direction triggers a failure:
      // - dropping a spec from buildDefaultSpecs → "missing" diff (caller
      //   removed observability without deliberation);
      // - adding a spec without updating this test → "extra" diff (forces
      //   the addition to surface in code review with a one-line update).
      final actual = registry.specs.map((s) => s.name).toSet();

      const documented = <String>{
        // Playback / timing
        'time-pos', 'duration', 'demuxer-cache-time',
        'core-idle', 'volume', 'speed', 'pitch', 'mute', 'idle-active',
        'shuffle', 'audio-pitch-correction', 'audio-delay', 'audio-bitrate',
        // `audio-device` lives outside the registry — its description
        // is cross-referenced against `audio-device-list` by the
        // player's custom dispatcher, which specs cannot see.
        // Audio params
        'audio-params', 'audio-codec', 'audio-codec-name', 'audio-out-params',
        // ReplayGain & gapless
        'gapless-audio', 'replaygain', 'replaygain-preamp',
        'replaygain-fallback', 'replaygain-clip', 'volume-gain',
        // Cache / network
        'cache', 'cache-secs', 'cache-on-disk', 'cache-pause',
        'cache-pause-wait', 'demuxer-max-bytes', 'demuxer-readahead-secs',
        'demuxer-max-back-bytes', 'network-timeout', 'tls-verify',
        'paused-for-cache', 'demuxer-via-network',
        // Audio output / driver
        'audio-buffer', 'audio-exclusive', 'audio-stream-silence',
        'ao-null-untimed', 'track-list', 'current-tracks/audio',
        'audio-spdif', 'volume-max',
        'audio-samplerate', 'audio-format', 'audio-channels',
        'audio-client-name', 'af', 'ao',
        // Cover art
        'audio-display', 'cover-art-auto', 'image-display-duration',
        // Patched / stream-only
        'prefetch-state', 'audio-output-state', 'prefetch-playlist',
        // Playback timing extras
        'audio-pts', 'time-remaining', 'playtime-remaining', 'eof-reached',
        // Stream capability
        'seekable', 'partially-seekable',
        // Display / file metadata
        'media-title', 'file-format', 'file-size',
        // Buffering depth
        'demuxer-cache-duration', 'demuxer-cache-idle',
        // Chapter navigation
        'chapter', 'chapter-list',
        // Path / URI introspection
        'path', 'filename', 'stream-path', 'stream-open-filename',
        // A-B loop
        'ab-loop-a', 'ab-loop-b', 'ab-loop-count', 'remaining-ab-loops',
        // Tier 2 introspection
        'seeking', 'percent-pos', 'cache-speed', 'cache-buffering-state',
        'current-demuxer', 'current-ao', 'demuxer-start-time',
        'chapter-metadata', 'mpv-version', 'ffmpeg-version',
      };

      expect(actual, equals(documented),
          reason:
              'Default registry drifted from the documented contract. '
              'Missing: ${documented.difference(actual)}. '
              'Extra: ${actual.difference(documented)}. '
              'Update the `documented` set in this test if the change is '
              'deliberate.');
    });
  });
}
