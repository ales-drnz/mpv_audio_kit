# Migrating to 0.5.0

0.5.0 changes how audio effects are described and how libmpv reaches your
app. Most apps only need the first section.

## Audio effects are an ordered list

The `AudioEffects` bundle, one field per filter applied in a fixed order,
is gone. The effects chain is now a `List<AudioEffect>`, applied in list
order, where the same filter can appear more than once.

| 0.4 | 0.5 |
|---|---|
| `AudioEffects(...)` | `[...]`, a `List<AudioEffect>` |
| `EqualizerSettings`, `AcompressorSettings`, … | `EqualizerEffect`, `AcompressorEffect`, … |
| `level_in`, `balance_in`, `start_periods` | `levelIn`, `balanceIn`, `startPeriods` |
| `enabled: true` on every effect | `enabled` defaults to `true` |
| `AudioEffects(custom: ['lavfi-...'])` | `RawAudioEffect('lavfi-...')` anywhere in the list |
| `e.updateBass((b) => ...)` | map the list (see below) |
| `state.audioEffects.bass` | `state.audioEffects.whereType<BassEffect>()` |
| `AudioEffect.equalizer` (filter id) | `AudioFilter.equalizer` |
| `LoudnormSettings(I: -16, TP: -1, LRA: 11)` | `LoudnormEffect(i: -16, tp: -1, lra: 11)` |
| enum members like `lr_to_ms`, `LUFS` | `lrToMs`, `lufs` |

Setting a chain:

```dart
// 0.4
await player.setAudioEffects(const AudioEffects(
  bass: BassSettings(enabled: true, g: 3),
  acompressor: AcompressorSettings(enabled: true, threshold: 0.1),
));

// 0.5: list order is chain order
await player.setAudioEffects(const [
  BassEffect(g: 3),
  AcompressorEffect(threshold: 0.1),
]);
```

Changing one stage, for example from a slider:

```dart
// 0.4
await player.updateAudioEffects(
  (e) => e.updateBass((b) => b.copyWith(g: gain)),
);

// 0.5
await player.updateAudioEffects((fx) => [
  for (final e in fx) e is BassEffect ? e.copyWith(g: gain) : e,
]);
```

When you keep several stages of one filter, address them by position:

```dart
await player.updateAudioEffects((fx) => [
  for (final (i, e) in fx.indexed)
    i == index ? (e as EqualizerEffect).copyWith(gain: gain) : e,
]);
```

A change that only touches runtime-tunable parameters and keeps the list's
shape still updates the running filter graph live. Adding, removing,
reordering or toggling a stage rebuilds the chain, as enabling or
disabling a slot did before.

Disabling keeps the stage and its settings, as before:

```dart
await player.updateAudioEffects((fx) => [
  for (final e in fx) e is BassEffect ? e.copyWith(enabled: false) : e,
]);
```

Clearing the chain: `setAudioEffects(const [])` instead of
`setAudioEffects(const AudioEffects())`.

### Taps and the loudness meter

`stream.tap` takes the filter as an `AudioFilter` and, when the filter
appears more than once, which occurrence (0 for the first):

```dart
player.stream.tap(AudioFilter.equalizer, instance: 1, side: TapSide.post);
```

The live loudness meter reads the first `Ebur128Effect` of the chain:

```dart
await player.updateAudioEffects(
  (fx) => [...fx, const Ebur128Effect(metadata: true)],
);
```

`AudioEffectsX.active` is gone: every stage has a `filter` (its
`AudioFilter`, `null` for a `RawAudioEffect`) and an `enabled` flag.

## One family of exceptions

Every exception a call throws is now a sealed `MpvPlayerException`:

| 0.4.x | 0.5.0 |
| --- | --- |
| `MpvException` | `MpvCommandException`, same `name`, `code` and `message` |
| `StateError` on a disposed player | `PlayerDisposedException` |
| `StateError` or `MpvLibraryException` when libmpv fails to start | `PlayerInitException` |
| `StateError` on an unreadable `content://` | `SourceException` |
| a missing `asset://` passed on to mpv | `SourceException` |

Other changes to handle:

- `next()`, `previous()`, `nextPlaylist()` and `previousPlaylist()` return
  `Future<bool>`: `false` when there is no track to go to.
- `jump()`, `remove()`, `move()` and `replace()` throw `RangeError` for an
  index out of range. `jump()` used to do nothing.
- `setVolume()` throws `RangeError` for a negative volume, `setRate()` and
  `setPitch()` outside `[0.01, 100]`. Invalid arguments are checked before
  the player finishes starting.
- `stop()`, `setShuffle()`, `reloadAudio()`, `rescanExternalFiles()` and
  `writeResumeConfig()` throw `MpvCommandException` when mpv rejects them,
  like the other methods.

## libmpv comes from a build hook

The package now fetches libmpv through a Dart build hook instead of
Gradle, CocoaPods, SwiftPM and CMake. Nothing changes in a normal app, but:

- The minimum is Dart 3.10 and Flutter 3.38.
- The bundled file is `libmpv_audio_kit.so`, `mpv_audio_kit.dll` or
  `mpv_audio_kit.framework`, so it no longer collides with media_kit's
  `libmpv`. Scripts or build steps that looked for `libmpv.so` in your
  app need the new name.
- To bundle your own libmpv build (offline builds, custom filters), set it
  in your app's `pubspec.yaml`:

  ```yaml
  hooks:
    user_defines:
      mpv_audio_kit:
        libmpv: path/to/your/libmpv
  ```

  `MpvAudioKit.ensureInitialized(libmpv: path)` still loads a library by
  path at run time.
- On Linux the package no longer falls back to a system `libmpv.so`.
- The player logs a warning when the loaded libmpv is not the release the
  package expects.
