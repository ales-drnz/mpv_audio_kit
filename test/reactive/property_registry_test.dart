// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:mpv_audio_kit/src/models/player_state.dart';
import 'package:mpv_audio_kit/src/reactive/mpv_property_spec.dart';
import 'package:mpv_audio_kit/src/reactive/property_registry.dart';
import 'package:mpv_audio_kit/src/reactive/reactive_property.dart';

void main() {
  group('PropertyRegistry.dispatch', () {
    test('routes a double event to the matching spec and reduces state', () {
      final volume = ReactiveProperty<double>(100.0);
      final registry = PropertyRegistry()
        ..register(MpvPropertySpec<double>.double(
          name: 'volume',
          reactive: volume,
          parse: (raw) => raw,
          reduce: (v, s) => s.copyWith(volume: v),
        ));

      const initial = PlayerState();
      final next = registry.dispatch('volume', 75.5, initial);

      expect(next, isNotNull);
      expect(next!.volume, 75.5);
      expect(volume.value, 75.5);
    });

    test('returns null for unknown property names', () {
      final registry = PropertyRegistry();
      const initial = PlayerState();
      expect(registry.dispatch('does-not-exist', 0.0, initial), isNull);
    });

    test('returns null when the value is deduplicated', () {
      final volume = ReactiveProperty<double>(100.0);
      final registry = PropertyRegistry()
        ..register(MpvPropertySpec<double>.double(
          name: 'volume',
          reactive: volume,
          parse: (raw) => raw,
          reduce: (v, s) => s.copyWith(volume: v),
        ));

      const initial = PlayerState(volume: 75.5);
      // First call seeds the reactive at 75.5.
      registry.dispatch('volume', 75.5, initial);
      // Second call with the same value must dedup.
      expect(registry.dispatch('volume', 75.5, initial), isNull);
    });

    test('flag spec inverts pause→playing via the parser', () async {
      final playing = ReactiveProperty<bool>(false);
      final registry = PropertyRegistry()
        ..register(MpvPropertySpec<bool>.flag(
          name: 'pause',
          reactive: playing,
          parse: (raw) => !raw,
          reduce: (v, s) => s.copyWith(playing: v),
        ));

      const initial = PlayerState();

      // mpv reports `pause=true` (i.e. paused) → playing=false. Already the
      // seed, so the dispatch dedups.
      expect(registry.dispatch('pause', true, initial), isNull);

      // mpv reports `pause=false` (i.e. playing) → playing=true.
      final next = registry.dispatch('pause', false, initial);
      expect(next, isNotNull);
      expect(next!.playing, isTrue);
      expect(playing.value, isTrue);
    });

    test('flag spec accepts integer 0/1 in addition to bool', () {
      final mute = ReactiveProperty<bool>(false);
      final registry = PropertyRegistry()
        ..register(MpvPropertySpec<bool>.flag(
          name: 'mute',
          reactive: mute,
          parse: (raw) => raw,
          reduce: (v, s) => s.copyWith(mute: v),
        ));

      const initial = PlayerState();
      // Event isolate currently forwards flags as Int32; this test ensures
      // the registry doesn't choke on the int → bool path.
      final next = registry.dispatch('mute', 1, initial);
      expect(next, isNotNull);
      expect(next!.mute, isTrue);
    });

    test('parse can transform raw values (empty string → "no")', () {
      final audioFormat = ReactiveProperty<String>('auto');
      final registry = PropertyRegistry()
        ..register(MpvPropertySpec<String>.string(
          name: 'audio-format',
          reactive: audioFormat,
          parse: (raw) => raw.isEmpty ? 'no' : raw,
          reduce: (v, s) => s.copyWith(audioFormat: v),
        ));

      const initial = PlayerState();
      final next = registry.dispatch('audio-format', '', initial);
      expect(next, isNotNull);
      expect(next!.audioFormat, 'no');
    });

    test('onChange fires after reactive update + state reduce', () {
      final calls = <double>[];
      final volume = ReactiveProperty<double>(0.0);
      final registry = PropertyRegistry()
        ..register(MpvPropertySpec<double>.double(
          name: 'volume',
          reactive: volume,
          parse: (raw) => raw,
          reduce: (v, s) => s.copyWith(volume: v),
          onChange: calls.add,
        ));

      const initial = PlayerState();
      registry.dispatch('volume', 50.0, initial);
      // Dedup → onChange must NOT fire.
      registry.dispatch('volume', 50.0, initial);
      registry.dispatch('volume', 60.0, initial);

      expect(calls, [50.0, 60.0]);
    });

    test('int64 spec dispatches into reactive + state and dedups', () {
      // Pins the int64 dispatch path: a regression here is the same class
      // of bug as the 0.1.0 fix where MPV_FORMAT_INT64 events were dropped
      // by the event-isolate switch, leaving int64 specs frozen at their
      // seed value. Asserting on both `next.field` and `reactive.value`
      // catches a future divergence between state reduction and reactive
      // update.
      final readahead = ReactiveProperty<int>(1);
      final registry = PropertyRegistry()
        ..register(MpvPropertySpec<int>.int64(
          name: 'demuxer-readahead-secs',
          reactive: readahead,
          parse: (raw) => raw,
          reduce: (v, s) => s.copyWith(demuxerReadaheadSecs: v),
        ));

      const initial = PlayerState();
      final next = registry.dispatch('demuxer-readahead-secs', 5, initial);
      expect(next, isNotNull);
      expect(next!.demuxerReadaheadSecs, 5);
      expect(readahead.value, 5,
          reason:
              'reactive must update in lockstep with the state reducer');

      // Same value → dedup → no state allocation.
      expect(registry.dispatch('demuxer-readahead-secs', 5, next), isNull);
      expect(readahead.value, 5);

      // Different value → emits again.
      final last = registry.dispatch('demuxer-readahead-secs', 7, next);
      expect(last, isNotNull);
      expect(last!.demuxerReadaheadSecs, 7);
      expect(readahead.value, 7);
    });

    test('Duration-typed double spec wraps microseconds correctly', () async {
      final position = ReactiveProperty<Duration>(Duration.zero);
      final registry = PropertyRegistry()
        ..register(MpvPropertySpec<Duration>.double(
          name: 'time-pos',
          reactive: position,
          parse: (raw) => Duration(microseconds: (raw * 1e6).round()),
          reduce: (v, s) => s.copyWith(position: v),
        ));

      const initial = PlayerState();
      final next = registry.dispatch('time-pos', 1.5, initial);
      expect(next, isNotNull);
      expect(next!.position, const Duration(milliseconds: 1500));
      expect(position.value, const Duration(milliseconds: 1500));
    });
  });

  group('PropertyRegistry.closeAll', () {
    test('closes every registered reactive property', () async {
      final a = ReactiveProperty<double>(0.0);
      final b = ReactiveProperty<bool>(false);
      final registry = PropertyRegistry()
        ..register(MpvPropertySpec<double>.double(
          name: 'volume',
          reactive: a,
          parse: (raw) => raw,
          reduce: (v, s) => s.copyWith(volume: v),
        ))
        ..register(MpvPropertySpec<bool>.flag(
          name: 'mute',
          reactive: b,
          parse: (raw) => raw,
          reduce: (v, s) => s.copyWith(mute: v),
        ));

      await registry.closeAll();
      expect(a.isClosed, isTrue);
      expect(b.isClosed, isTrue);
      // Second invocation must be safe (idempotent close on each spec).
      await registry.closeAll();
    });
  });

  group('PropertyRegistry.specFor', () {
    test('returns the registered spec by name', () {
      final volume = ReactiveProperty<double>(0.0);
      final spec = MpvPropertySpec<double>.double(
        name: 'volume',
        reactive: volume,
        parse: (raw) => raw,
        reduce: (v, s) => s.copyWith(volume: v),
      );
      final registry = PropertyRegistry()..register(spec);
      expect(registry.specFor('volume'), same(spec));
      expect(registry.specFor('unknown'), isNull);
    });
  });
}
