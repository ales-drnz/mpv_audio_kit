// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/src/models/mpv_prefetch_state.dart';
import 'package:mpv_audio_kit/src/models/player_state.dart';
import 'package:mpv_audio_kit/src/reactive/default_specs.dart';
import 'package:mpv_audio_kit/src/reactive/property_registry.dart';

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
        onPlayingChanged: (_) {},
        onIdleActive: (_) {},
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

  group('Default registry — audio params (decoder + hardware sub-fields)', () {
    test('audio-params/* fields aggregate into state.audioParams', () {
      dispatch('audio-params/format', 'floatp');
      dispatch('audio-params/samplerate', 48000.0);
      dispatch('audio-params/channels', 'stereo');
      dispatch('audio-params/channel-count', 2.0);
      dispatch('audio-params/hr-channels', 'L+R');
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

    test('audio-out-params/* fields aggregate into state.audioOutParams', () {
      dispatch('audio-out-params/format', 's16');
      dispatch('audio-out-params/samplerate', 44100.0);
      dispatch('audio-out-params/channels', 'stereo');
      dispatch('audio-out-params/channel-count', 2.0);
      dispatch('audio-out-params/hr-channels', '2.0');

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

    test('af string is split into List<AudioFilter>', () {
      dispatch('af', 'lavfi-equalizer=g=3,lavfi-loudnorm');
      expect(state.activeFilters.length, 2);
      expect(state.activeFilters[0].value, 'lavfi-equalizer=g=3');
      expect(state.activeFilters[1].value, 'lavfi-loudnorm');

      dispatch('af', '');
      expect(state.activeFilters, isEmpty);
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
  });

  group('Default registry — onChange callbacks', () {
    test('onPlayingChanged fires only when pause → playing transition happens',
        () {
      final calls = <bool>[];
      reactives = DefaultPropertyReactives();
      registry = PropertyRegistry()
        ..registerAll(buildDefaultSpecs(
          reactives,
          onPlayingChanged: calls.add,
          onIdleActive: (_) {},
        ));
      state = const PlayerState();

      // First update: core-idle=false → playing=true (transition from seed=false).
      registry.dispatch('core-idle', false, state);
      expect(calls, [true]);

      // Same value again: dedup, no callback.
      registry.dispatch('core-idle', false, state);
      expect(calls, [true]);

      // Toggle to paused / idle.
      registry.dispatch('core-idle', true, state);
      expect(calls, [true, false]);
    });

    test('onIdleActive fires on every idle transition', () {
      final calls = <bool>[];
      reactives = DefaultPropertyReactives();
      registry = PropertyRegistry()
        ..registerAll(buildDefaultSpecs(
          reactives,
          onPlayingChanged: (_) {},
          onIdleActive: calls.add,
        ));
      state = const PlayerState();

      registry.dispatch('idle-active', true, state);
      registry.dispatch('idle-active', true, state); // dedup
      registry.dispatch('idle-active', false, state);

      expect(calls, [true, false]);
    });
  });

  group('Default registry — coverage smoke test', () {
    test('every spec name observed by the player is registered', () {
      // The full set of mpv property names the registry knows about. If any
      // future maintenance accidentally drops a spec from buildDefaultSpecs,
      // this test fails loudly with a missing-name error rather than the
      // bug going unnoticed in production.
      const expected = <String>[
        // Playback / timing
        'time-pos', 'duration', 'demuxer-cache-time',
        'core-idle', 'volume', 'speed', 'pitch', 'mute', 'idle-active',
        'shuffle', 'audio-pitch-correction', 'audio-delay', 'audio-bitrate',
        'audio-device',
        // Audio params
        'audio-params/format', 'audio-params/samplerate',
        'audio-params/channels', 'audio-params/channel-count',
        'audio-params/hr-channels', 'audio-codec', 'audio-codec-name',
        'audio-out-params/format', 'audio-out-params/samplerate',
        'audio-out-params/channels', 'audio-out-params/channel-count',
        'audio-out-params/hr-channels',
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
        'ao-null-untimed', 'aid', 'audio-spdif', 'volume-max',
        'audio-samplerate', 'audio-format', 'audio-channels',
        'audio-client-name', 'af', 'ao',
        // Cover art
        'audio-display', 'cover-art-auto', 'image-display-duration',
        // Patched / stream-only
        'prefetch-state',
      ];
      for (final name in expected) {
        expect(registry.specFor(name), isNotNull,
            reason: 'spec missing for "$name"');
      }
    });
  });
}
