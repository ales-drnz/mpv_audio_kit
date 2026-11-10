// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:mpv_audio_kit/src/internals/duration_seconds.dart';
import 'package:mpv_audio_kit/src/models/audio_params.dart';
import 'package:mpv_audio_kit/src/player/player_state.dart';
import 'package:mpv_audio_kit/src/reactive/default_reactives.dart';
import 'package:mpv_audio_kit/src/reactive/default_specs.dart';
import 'package:mpv_audio_kit/src/reactive/property_registry.dart';
import 'package:mpv_audio_kit/src/types/enums/cache.dart';
import 'package:mpv_audio_kit/src/types/enums/format.dart';
import 'package:mpv_audio_kit/src/types/enums/replay_gain.dart';
import 'package:mpv_audio_kit/src/types/sealed/channels.dart';
import 'package:mpv_audio_kit/src/types/settings/cache_settings.dart';
import 'package:mpv_audio_kit/src/types/settings/demuxer_settings.dart';
import 'package:mpv_audio_kit/src/types/settings/replay_gain_settings.dart';
import 'package:mpv_audio_kit/src/types/state/audio_output_state.dart';
import 'package:mpv_audio_kit/src/types/state/prefetch_state.dart';
import 'package:test/test.dart';

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
      ..registerAll(
        buildDefaultSpecs(
          reactives,
          onIdleActive: (_) {},
          onAudioOutputState: (_) {},
        ),
      );
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

      expect(state.settings.volume, 50.0);
      expect(state.settings.rate, 1.25);
      expect(state.settings.pitch, 1.5);
      expect(state.settings.mute, isTrue);
      expect(state.playback.shuffle, isTrue);

      expect(reactives.volume.value, 50.0);
      expect(reactives.shuffle.value, isTrue);
    });

    test('core-idle is inverted into state.playing (actual-output axis)', () {
      // `core-idle=false` means mpv is actually producing audio. This is
      // the actual-output axis; it flips transiently on every seek.
      dispatch('core-idle', false);
      expect(state.playback.playing, isTrue);
      expect(reactives.playing.value, isTrue);

      dispatch('core-idle', true);
      expect(state.playback.playing, isFalse);
      expect(reactives.playing.value, isFalse);
    });

    test('time-pos / duration / demuxer-cache-time map to Duration fields', () {
      dispatch('time-pos', 1.5); // 1.5 seconds
      dispatch('duration', 90.0); // 1m30
      dispatch('demuxer-cache-time', 30.0);

      expect(state.playback.position, const Duration(milliseconds: 1500));
      expect(state.playback.duration, const Duration(seconds: 90));
      expect(state.network.buffer, const Duration(seconds: 30));
    });
  });

  group('Default registry — audio params (decoder + hardware node maps)', () {
    test('`audio-params` node + `audio-codec` + `audio-codec-name` populate '
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

      expect(state.file.audioParams.format, Format.float32Planar);
      expect(state.file.audioParams.sampleRate, 48000);
      expect(state.file.audioParams.channels, Channels.stereo);
      expect(state.file.audioParams.channelCount, 2);
      expect(state.file.audioParams.hrChannels, 'L+R');
      expect(state.file.audioParams.codec, 'flac');
      expect(state.file.audioParams.codecName, 'FLAC');
    });

    test('`audio-params` node merges into existing audioParams without '
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
      expect(state.file.audioParams.format, Format.float32Planar);
      expect(state.file.audioParams.sampleRate, 48000);
      expect(
        state.file.audioParams.codec,
        'flac',
        reason:
            'audio-params node reduce must not reset the codec fields '
            'populated by audio-codec / audio-codec-name siblings',
      );
      expect(state.file.audioParams.codecName, 'FLAC');
    });

    test('a group of audio-params, codec and codec name emits once', () async {
      final seen = <AudioParams>[];
      final sub = reactives.audioParams.changes.listen(seen.add);
      const node = <String, dynamic>{
        'format': 'floatp',
        'samplerate': 48000,
        'channels': 'stereo',
        'channel-count': 2,
        'hr-channels': 'L+R',
      };

      state = registry.dispatchGroup([
        ('audio-codec', 'flac'),
        ('audio-codec-name', 'FLAC'),
        ('audio-params', node),
      ], state)!;
      expect(state.file.audioParams.codec, 'flac');
      expect(state.file.audioParams.codecName, 'FLAC');
      expect(state.file.audioParams.sampleRate, 48000);

      // The same values again: nothing changes, nothing emits.
      expect(registry.dispatchGroup([('audio-codec', 'flac')], state), isNull);

      state = registry.dispatchGroup([
        ('audio-params', null),
        ('audio-codec', null),
        ('audio-codec-name', null),
      ], state)!;
      expect(state.file.audioParams, const AudioParams());

      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      expect(seen, hasLength(2));
      expect(seen.first.codec, 'flac');
      expect(seen.first.sampleRate, 48000);
      expect(seen.last, const AudioParams());
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

      expect(state.output.audioOutParams.format, Format.s16);
      expect(state.output.audioOutParams.sampleRate, 44100);
      expect(state.output.audioOutParams.channels, Channels.stereo);
      expect(state.output.audioOutParams.channelCount, 2);
      expect(state.output.audioOutParams.hrChannels, '2.0');
    });
  });

  group('Default registry — special parsers', () {
    test('audio-format empty string maps to Format.auto', () {
      dispatch('audio-format', '');
      expect(state.settings.audioFormat, Format.auto);
    });

    test('audio-format known values round-trip via fromMpv', () {
      dispatch('audio-format', 's16');
      expect(state.settings.audioFormat, Format.s16);
      dispatch('audio-format', 'floatp');
      expect(state.settings.audioFormat, Format.float32Planar);
      dispatch('audio-format', 'doublep');
      expect(state.settings.audioFormat, Format.float64Planar);
    });

    test('audio-channels named layouts and custom round-trip', () {
      dispatch('audio-channels', 'stereo');
      expect(state.settings.audioChannels, Channels.stereo);
      dispatch('audio-channels', '5.1');
      expect(state.settings.audioChannels, Channels.fiveOne);
      dispatch('audio-channels', 'auto-safe');
      expect(state.settings.audioChannels, Channels.autoSafe);
      // Variant qualifier preserved.
      dispatch('audio-channels', '5.1(side)');
      expect(state.settings.audioChannels, Channels.fiveOneSide);
      dispatch('audio-channels', '7.1(wide-side)');
      expect(state.settings.audioChannels, Channels.sevenOneWideSide);
      // Raw speaker-tag list — falls through to .custom().
      dispatch('audio-channels', 'fl-fr-fc-bl-br-sl-sr-lfe');
      expect(
        state.settings.audioChannels,
        const Channels.custom('fl-fr-fc-bl-br-sl-sr-lfe'),
      );
    });

    test('audio-bitrate <= 0 becomes null', () {
      // Seed at the default (null) so the first non-zero update fires.
      expect(reactives.audioBitrate.value, isNull);

      dispatch('audio-bitrate', 320000.0);
      expect(state.file.audioBitrate, 320000.0);

      dispatch('audio-bitrate', 0.0);
      expect(state.file.audioBitrate, isNull);
    });

    // The `af` property has NO observer — the typed bundle is the
    // single writer of mpv's `af` and we do not reverse-parse external
    // raw writes back into state.audioEffects. Documented in
    // `default_specs.dart` next to the property block.
  });

  group('Default registry — stream-only properties', () {
    test(
      'prefetch-state updates the reactive without touching PlayerState',
      () {
        // PlayerState has no field for prefetch state by design.
        final initialFingerprint = state;

        dispatch('prefetch-state', 'loading');
        expect(reactives.prefetchState.value, PrefetchState.loading);
        expect(
          state,
          equals(initialFingerprint),
          reason: 'state must not mutate for stream-only properties',
        );

        dispatch('prefetch-state', 'ready');
        expect(reactives.prefetchState.value, PrefetchState.ready);
      },
    );

    test('unknown prefetch values fall back to idle', () {
      dispatch('prefetch-state', 'totally-bogus');
      expect(reactives.prefetchState.value, PrefetchState.idle);
    });

    test('prefetch-playlist flag round-trips into state.prefetchPlaylist', () {
      // Default mirrors mpv 0.41 (off). Toggle via setPrefetchPlaylist
      // (or any property write) drives the observed flag.
      expect(state.settings.prefetchPlaylist, isFalse);

      dispatch('prefetch-playlist', true);
      expect(state.settings.prefetchPlaylist, isTrue);
      expect(reactives.prefetchPlaylist.value, isTrue);

      dispatch('prefetch-playlist', false);
      expect(state.settings.prefetchPlaylist, isFalse);
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
      ('audio-pts', 1.5, (s) => s.playback.audioPts),
      ('time-remaining', 30.0, (s) => s.playback.timeRemaining),
      ('playtime-remaining', 15.0, (s) => s.playback.playtimeRemaining),
      ('eof-reached', true, (s) => s.playback.eofReached),
      ('seekable', true, (s) => s.playback.seekable),
      ('partially-seekable', true, (s) => s.playback.partiallySeekable),
      ('media-title', 'My Song - Artist', (s) => s.file.mediaTitle),
      ('file-format', 'mp4,m4a,3gp', (s) => s.file.fileFormat),
      ('file-size', 1234567890, (s) => s.file.fileSize),
      ('demuxer-cache-idle', false, (s) => s.network.demuxerIdle),
      ('path', '/audio/track.flac', (s) => s.file.path),
      ('filename', 'track.flac', (s) => s.file.filename),
      (
        'stream-path',
        'https://cdn.example/track.flac',
        (s) => s.file.streamPath,
      ),
      (
        'stream-open-filename',
        'https://cdn.example/redirected.flac',
        (s) => s.file.streamOpenFilename,
      ),
      ('playlist-path', '/music/radio.m3u', (s) => s.file.playlistPath),
      ('seeking', true, (s) => s.playback.seeking),
      ('percent-pos', 42.5, (s) => s.playback.percentPos),
      ('cache-speed', 65536.0, (s) => s.network.cacheSpeed),
      ('cache-buffering-state', 87, (s) => s.network.cacheBufferingState),
      ('current-demuxer', 'mkv', (s) => s.file.currentDemuxer),
      ('current-ao', 'coreaudio', (s) => s.output.currentAo),
      ('mpv-version', '0.41.0', (s) => s.versions.mpvVersion),
      ('ffmpeg-version', '7.1.1', (s) => s.versions.ffmpegVersion),
    ];
    for (final (name, payload, getter) in xsProperties) {
      test('$name round-trip into state', () {
        dispatch(name, payload);
        // Duration / Map fields surface as-is for non-Duration payloads;
        // Duration parsers are exercised by the dedicated test below.
        if (payload is double &&
            (name.endsWith('-pts') || name.endsWith('-remaining'))) {
          expect(getter(state), secondsToDuration(payload));
        } else {
          expect(getter(state), payload);
        }
      });
    }

    test('demuxer-cache-duration (double → Duration) → bufferDuration', () {
      dispatch('demuxer-cache-duration', 12.5);
      expect(state.network.bufferDuration, const Duration(milliseconds: 12500));
    });

    test('chapter (int64 → int?, -1 maps to null)', () {
      dispatch('chapter', 2);
      expect(state.playback.currentChapter, 2);

      dispatch('chapter', -1);
      expect(
        state.playback.currentChapter,
        isNull,
        reason:
            'mpv emits chapter=-1 when no chapter is active; the '
            'parser must surface that as `null`',
      );
    });

    test('ab-loop-a / ab-loop-b ("no" → null, numeric → Duration)', () {
      dispatch('ab-loop-a', '12.5');
      dispatch('ab-loop-b', '20.0');
      expect(state.playback.abLoopA, const Duration(milliseconds: 12500));
      expect(state.playback.abLoopB, const Duration(seconds: 20));

      dispatch('ab-loop-a', 'no');
      expect(state.playback.abLoopA, isNull);
    });

    test('ab-loop-count ("inf" → null, numeric → int)', () {
      dispatch('ab-loop-count', '5');
      expect(state.playback.abLoopCount, 5);

      dispatch('ab-loop-count', 'inf');
      expect(state.playback.abLoopCount, isNull);
    });

    test('remaining-ab-loops (int64 → int?, -1 maps to null)', () {
      dispatch('remaining-ab-loops', 3);
      expect(state.playback.remainingAbLoops, 3);

      dispatch('remaining-ab-loops', -1);
      expect(state.playback.remainingAbLoops, isNull);
    });

    test('demuxer-start-time (double → Duration)', () {
      dispatch('demuxer-start-time', 12.5);
      expect(state.file.demuxerStartTime, const Duration(milliseconds: 12500));
    });

    test('chapter-metadata (NODE_MAP → Map<String,String>)', () {
      dispatch('chapter-metadata', <String, dynamic>{
        'title': 'Chapter One',
        'lang': 'eng',
      });
      expect(state.file.chapterMetadata, {
        'title': 'Chapter One',
        'lang': 'eng',
      });

      dispatch('chapter-metadata', <String, dynamic>{});
      expect(state.file.chapterMetadata, isEmpty);
    });

    test('chapter-list (NODE_ARRAY → List<Chapter>)', () {
      dispatch('chapter-list', [
        {'time': 0.0, 'title': 'A'},
        {'time': 60.0, 'title': 'B'},
      ]);
      expect(state.file.chapters, hasLength(2));
      expect(state.file.chapters[0].title, 'A');
      expect(state.file.chapters[1].time, const Duration(seconds: 60));
    });
  });

  group('Default registry — config aggregate copyWith preserves siblings', () {
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
        state.settings.replayGain,
        const ReplayGainSettings(
          mode: ReplayGain.album,
          preamp: -3.0,
          clip: true,
          fallback: 1.5,
        ),
      );

      // Change just preamp; assert the other 3 fields are untouched.
      dispatch('replaygain-preamp', -10.0);
      expect(state.settings.replayGain.preamp, -10.0);
      expect(
        state.settings.replayGain.mode,
        ReplayGain.album,
        reason: 'mode must survive a preamp-only dispatch',
      );
      expect(state.settings.replayGain.clip, isTrue);
      expect(state.settings.replayGain.fallback, 1.5);

      // Change just clip.
      dispatch('replaygain-clip', false);
      expect(state.settings.replayGain.clip, isFalse);
      expect(state.settings.replayGain.mode, ReplayGain.album);
      expect(
        state.settings.replayGain.preamp,
        -10.0,
        reason: 'preamp from the previous dispatch must survive',
      );
    });

    test('cache: dispatching one property preserves the other 5', () {
      // Seed all 6 fields via dispatch (see replayGain test for rationale).
      dispatch('cache', 'yes');
      dispatch('cache-secs', 30.0);
      dispatch('cache-on-disk', true);
      dispatch('cache-pause', false);
      dispatch('cache-pause-wait', 5.0);
      dispatch('cache-pause-initial', true);
      expect(
        state.settings.cache,
        const CacheSettings(
          mode: Cache.yes,
          secs: Duration(seconds: 30),
          onDisk: true,
          pause: false,
          pauseWait: Duration(seconds: 5),
          pauseInitial: true,
        ),
      );

      dispatch('cache-secs', 60.0);
      expect(state.settings.cache.secs, const Duration(seconds: 60));
      expect(state.settings.cache.mode, Cache.yes);
      expect(state.settings.cache.onDisk, isTrue);
      expect(state.settings.cache.pause, isFalse);
      expect(state.settings.cache.pauseWait, const Duration(seconds: 5));
      expect(state.settings.cache.pauseInitial, isTrue);

      dispatch('cache-pause', true);
      expect(state.settings.cache.pause, isTrue);
      expect(state.settings.cache.secs, const Duration(seconds: 60));

      dispatch('cache', 'no');
      expect(state.settings.cache.mode, Cache.no);
      expect(state.settings.cache.secs, const Duration(seconds: 60));
      expect(state.settings.cache.onDisk, isTrue);
    });

    test('demuxer: dispatching one property preserves the other 2', () {
      // Seed all 3 fields via dispatch (see cache test for rationale).
      dispatch('demuxer-max-bytes', 200 * 1024 * 1024);
      dispatch('demuxer-max-back-bytes', 10 * 1024 * 1024);
      dispatch('demuxer-readahead-secs', 5.0);
      expect(
        state.settings.demuxer,
        const DemuxerSettings(
          maxBytes: 200 * 1024 * 1024,
          maxBackBytes: 10 * 1024 * 1024,
          readahead: Duration(seconds: 5),
        ),
      );

      dispatch('demuxer-readahead-secs', 2.5);
      expect(
        state.settings.demuxer.readahead,
        const Duration(milliseconds: 2500),
      );
      expect(state.settings.demuxer.maxBytes, 200 * 1024 * 1024);
      expect(state.settings.demuxer.maxBackBytes, 10 * 1024 * 1024);

      dispatch('demuxer-max-back-bytes', 0);
      expect(state.settings.demuxer.maxBackBytes, 0);
      expect(state.settings.demuxer.maxBytes, 200 * 1024 * 1024);
      expect(
        state.settings.demuxer.readahead,
        const Duration(milliseconds: 2500),
      );
    });

    test('replayGain: dispatch on initial PlayerState (default) is safe', () {
      // Edge case: dispatching the first property after a fresh state
      // must not throw on the `s.replayGain.copyWith(...)` chain.
      expect(state.settings.replayGain, const ReplayGainSettings());
      dispatch('replaygain-preamp', 1.0);
      expect(state.settings.replayGain.preamp, 1.0);
      expect(
        state.settings.replayGain.mode,
        ReplayGain.no,
        reason: 'default ReplayGainSettings.mode must survive',
      );
    });
  });

  group('Default registry — onChange callbacks', () {
    test('onAudioOutputState fires on every state transition', () {
      final calls = <AudioOutputState>[];
      reactives = DefaultPropertyReactives();
      registry = PropertyRegistry()
        ..registerAll(
          buildDefaultSpecs(
            reactives,
            onIdleActive: (_) {},
            onAudioOutputState: calls.add,
          ),
        );
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
        ..registerAll(
          buildDefaultSpecs(
            reactives,
            onIdleActive: calls.add,
            onAudioOutputState: (_) {},
          ),
        );
      state = const PlayerState();

      registry.dispatch('idle-active', true, state);
      registry.dispatch('idle-active', true, state); // dedup
      registry.dispatch('idle-active', false, state);

      expect(calls, [true, false]);
    });
  });

  group('Default registry — coverage contract', () {
    test('registry holds exactly the documented set of mpv property names', () {
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
        'time-pos', 'duration', 'duration-estimated', 'demuxer-cache-time',
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
        'volume-gain-min', 'volume-gain-max',
        // Cache / network
        'cache', 'cache-secs', 'cache-on-disk', 'cache-pause',
        'cache-pause-wait', 'cache-pause-initial',
        'demuxer-max-bytes', 'demuxer-readahead-secs',
        'demuxer-max-back-bytes', 'network-timeout', 'tls-verify',
        'hls-bitrate', 'cookies', 'http-proxy',
        'paused-for-cache', 'demuxer-via-network',
        // Audio output / driver
        'audio-buffer', 'audio-exclusive', 'audio-set-media-role',
        'audio-stream-silence',
        'ao-null-untimed', 'track-list', 'current-tracks/audio',
        'audio-spdif', 'volume-max', 'ao-volume', 'ao-mute',
        'audio-samplerate', 'audio-format', 'audio-channels',
        'audio-client-name', 'ao',
        // NOTE: `af` is NOT observed — the typed [AudioEffects] bundle
        // is the single writer of mpv's `af` property, so external raw
        // writes are not reverse-parsed back into state.audioEffects.
        // Cover art
        'cover-art-auto',
        // Patched / stream-only
        'prefetch-state', 'prefetch-cache-duration', 'audio-output-state',
        'prefetch-playlist',
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
        'playlist-path',
        // A-B loop
        'ab-loop-a', 'ab-loop-b', 'ab-loop-count', 'remaining-ab-loops',
        // Tier 2 introspection
        'seeking', 'percent-pos', 'cache-speed', 'cache-buffering-state',
        'current-demuxer', 'current-ao', 'demuxer-start-time',
        'chapter-metadata', 'mpv-version', 'ffmpeg-version',
      };

      expect(
        actual,
        equals(documented),
        reason:
            'Default registry drifted from the documented contract. '
            'Missing: ${documented.difference(actual)}. '
            'Extra: ${actual.difference(documented)}. '
            'Update the `documented` set in this test if the change is '
            'deliberate.',
      );
    });
  });
}
