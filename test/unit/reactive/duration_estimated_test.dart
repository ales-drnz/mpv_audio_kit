// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

// duration and duration-estimated (libmpv-r24): a duration FFmpeg estimated
// from the bitrate gives way to the entry's waveformDurationHint, an exact
// one always wins, and durationEstimated tells an estimate with no hint.
// The two properties change separately, in either order.

import 'package:mpv_audio_kit/src/models/media.dart';
import 'package:mpv_audio_kit/src/models/playlist.dart';
import 'package:mpv_audio_kit/src/player/player_state.dart';
import 'package:mpv_audio_kit/src/player/state/playback_state.dart';
import 'package:mpv_audio_kit/src/reactive/default_reactives.dart';
import 'package:mpv_audio_kit/src/reactive/default_specs.dart';
import 'package:mpv_audio_kit/src/reactive/duration_hint.dart';
import 'package:mpv_audio_kit/src/reactive/property_registry.dart';
import 'package:test/test.dart';

const _hint = Duration(seconds: 200);

PlayerState _with(Duration? hint) => PlayerState(
  playback: PlaybackState(
    playlist: Playlist([
      Media('https://example.com/a.mp3', waveformDurationHint: hint),
    ]),
  ),
);

({PropertyRegistry registry, DefaultPropertyReactives r}) _registry() {
  final r = DefaultPropertyReactives();
  final registry = PropertyRegistry()
    ..registerAll(
      buildDefaultSpecs(r, onIdleActive: (_) {}, onAudioOutputState: (_) {}),
    );
  return (registry: registry, r: r);
}

/// Dispatches [changes] in order, keeping the state when one changes
/// nothing.
PlayerState _run(
  PropertyRegistry registry,
  PlayerState state,
  List<(String, Object?)> changes,
) {
  for (final (name, raw) in changes) {
    state =
        (raw == null
            ? registry.dispatchUnavailable(name, state)
            : registry.dispatch(name, raw, state)) ??
        state;
  }
  return state;
}

void main() {
  test('an estimated duration gives way to the hint, flag after', () {
    final (:registry, :r) = _registry();
    final s = _run(registry, _with(_hint), [
      ('duration', 1455.4),
      ('duration-estimated', 1),
    ]);
    expect(s.playback.duration, _hint);
    expect(s.playback.durationEstimated, isFalse);
    expect(r.duration.value, _hint, reason: 'the stream follows the state');
  });

  test('an estimated duration gives way to the hint, flag first', () {
    final (:registry, :r) = _registry();
    final s = _run(registry, _with(_hint), [
      ('duration-estimated', 1),
      ('duration', 1455.4),
    ]);
    expect(s.playback.duration, _hint);
    expect(s.playback.durationEstimated, isFalse);
    expect(r.duration.value, _hint);
  });

  test('without a hint the estimate stays, marked', () {
    final (:registry, :r) = _registry();
    final s = _run(registry, _with(null), [
      ('duration', 13.07),
      ('duration-estimated', 1),
    ]);
    expect(s.playback.duration, const Duration(milliseconds: 13070));
    expect(s.playback.durationEstimated, isTrue);
    expect(r.durationEstimated.value, isTrue);
  });

  test('an exact duration wins over the hint', () {
    final (:registry, :r) = _registry();
    final s = _run(registry, _with(_hint), [
      ('duration-estimated', 0),
      ('duration', 30.0),
    ]);
    expect(s.playback.duration, const Duration(seconds: 30));
    expect(s.playback.durationEstimated, isFalse);
  });

  test('the next file, exact, after an estimated one', () {
    final (:registry, :r) = _registry();
    var s = _run(registry, _with(_hint), [
      ('duration', 1455.4),
      ('duration-estimated', 1),
    ]);
    // The new duration first, the flag still yes: the hint holds until the
    // flag turns, then the exact duration.
    s = _run(registry, s, [('duration', 30.0), ('duration-estimated', 0)]);
    expect(s.playback.duration, const Duration(seconds: 30));
    expect(s.playback.durationEstimated, isFalse);
    expect(r.duration.value, const Duration(seconds: 30));
  });

  test('no file: zero and not estimated', () {
    final (:registry, :r) = _registry();
    var s = _run(registry, _with(null), [
      ('duration', 13.07),
      ('duration-estimated', 1),
    ]);
    s = _run(registry, s, [('duration', null), ('duration-estimated', null)]);
    expect(s.playback.duration, Duration.zero);
    expect(s.playback.durationEstimated, isFalse);
  });

  // The duration and its flag arrive before FILE_LOADED, the playlist with
  // the new index with it or after it: the player applies the hint again
  // at each playlist update.
  test('the hint of the entry the index moves to applies', () {
    final r = DefaultPropertyReactives();
    final hint = DurationHint(r);
    final registry = PropertyRegistry()
      ..registerAll(
        buildDefaultSpecs(
          r,
          onIdleActive: (_) {},
          onAudioOutputState: (_) {},
          durationHint: hint,
        ),
      );
    const two = Playlist([
      Media('https://example.com/a.mp3'),
      Media('https://example.com/b.mp3', waveformDurationHint: _hint),
    ]);
    var s = const PlayerState(playback: PlaybackState(playlist: two));
    s = _run(registry, s, [('duration', 1455.4), ('duration-estimated', 1)]);
    expect(s.playback.durationEstimated, isTrue, reason: 'entry 0 has none');
    s = hint.apply(s.copyWith(playlist: two.copyWith(index: 1)));
    expect(s.playback.duration, _hint);
    expect(s.playback.durationEstimated, isFalse);
    expect(r.duration.value, _hint);
    s = hint.apply(s.copyWith(playlist: two.copyWith(index: 0)));
    expect(s.playback.duration, const Duration(milliseconds: 1455400));
    expect(r.durationEstimated.value, isTrue);
  });
}
