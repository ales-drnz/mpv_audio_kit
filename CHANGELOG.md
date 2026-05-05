## [0.1.0] - 5-05-2026

Major release. The Dart API has been redesigned for type safety, ergonomics, and atomic state mutations.

### Added
- A new `AudioEffects` bundle covering equalizer, compressor, loudness, pitch, tempo, bass, treble, stereo width, headphone crossfeed, silence trim, and raw lavfi effects applied atomically through one setter.
- A-B loop and chapter navigation.
- Aggregate playback-state stream (idle, loading, buffering, playing, paused, completed) for one-line UI bindings.
- 20+ new observable streams covering timing, file metadata, cache, demuxer, and version info.
- Typed `Hook` enum for the file-loading lifecycle.
- New `MpvPrefetchState.failed` variant for when background prefetch fails.
- Typed errors via the `MpvPlayerError` hierarchy and a public `MpvException` for raw-API failures.
- Real-time FFT spectrum and raw PCM streams (`Player.stream.spectrum` / `Player.stream.pcm`) captured post-DSP for visualizers.
- `setTlsCaFile(path)` with custom root-CA bundle.

### Changed
- DSP effects, ReplayGain, and cache settings now live in atomic config objects applied in one call instead of multiple granular setters.
- Track selection, format, channel layout, S/PDIF passthrough, log levels, and hooks are now typed enums and sealed classes instead of free-form strings.
- Embedded cover art is exposed as raw codec bytes through a dedicated `state.coverArt` + `stream.coverArt` pair, with Flutter conveniences (`art.image` returns an `ImageProvider`, plus `art.extension`, `art.isPng`, `art.isJpeg`, …).
- `setAudioDisplay`, `setImageDisplayDuration`, and the `Display` enum are removed - they controlled mpv's video pipeline, which the audio-only build no longer ships. Cover bytes are surfaced regardless via `state.coverArt`.
- Raw-API escape hatches (`getRawProperty`, `setRawProperty`, `sendRawCommand`) are now `Future<...>` and surface mpv-side errors as `MpvException` instead of silently no-oping. `getRawProperty` still returns `null` on failure.
- Every typed setter (`setVolume`, `setRate`, `setAudioEffects`, `setCache`, …) now throws `MpvException` when mpv rejects the write, instead of silently advancing the optimistic state.
- `Player.openPlaylist` renamed to `Player.openAll` (matches Dart's `addAll` / `removeAll` convention).
- See the [Migration](README.md#migration) section in the README for the full 0.0.9 → 0.1.0.

### Fixed
- The initial player state (volume, format, channels, params, …) is now reliably populated before the first `await`. A startup race could previously leave one or more state fields at their default until the next user-driven setter.
- Calling `dispose()` immediately after construction no longer throws.
- Player instances that get garbage-collected without an explicit `dispose()` now release their native handle automatically. Always prefer `await player.dispose()`; this is just a safety net.
- `Player.dispose()` completes in milliseconds instead of falling through a 2-second timeout.
- HTTP headers no longer leak across `open()` calls; per-file headers stay scoped to their `Media`.
- Android `content://` file descriptors are released on aborted loads, including when an `openAll([...])` fails mid-batch.
- `state.coverArt` now mirrors the latest `stream.coverArt` emit synchronously (was permanently `null` despite being documented).
- `print(state)` and `print(audioEffects)` now render the actual values instead of placeholder text.
- Hot-Restart cleanup is hardened against false positives so a long-lived dev process can't have it trip on memory belonging to other tools.
- Several correctness fixes around playlist equality, hook idempotency, cache precision, and lifecycle stream synchronisation.
- HTTPS streams now connect on Android out of the box; previously TLS verification had no trust roots and every handshake failed.

### Example
- Spectrum visualizer in the Player tab driven by `Player.stream.spectrum`, plus a Settings page exposing every `SpectrumSettings` knob (FFT size, window, band count, range, emit rate, attack, release smoothing, dB range) for live exploration.
- Filters page reorganised into category sub-pages covering every filter shipped with the build, plus a dedicated 18-band visualizer for `superequalizer`.

### Build
- Patched prefetch to also support `.failed` state.
- Patched audio output state to report AO immediately.
- Patched audio frames to extract PCM streams (visualizer).
- Fixed Android `audiotrack` driver not working.
- Bundled libmpv binaries reduced by ~55% (e.g. macOS 29 MB → 13 MB).
- Bumped minimum deployment targets to iOS 15.0 and macOS 12.0.
- iOS Simulator is now Apple Silicon only (dropped x86_64).
- Added arm64 support for Linux and Windows.
- Updated libmpv to `libmpv-r5` across all platforms.

## [0.0.9] - 27-04-2026

### Fixed
- Lifecycle streams (`stream.playing` / `stream.buffering` / `stream.completed`) silently desynced from `state` on file boundaries - `stream.completed` never fired on natural EOF and `stream.buffering` never emitted at all. All three now stay in sync with `state` across every lifecycle transition.
- `dispose()` leaked four stream controllers (audio display, cover-art auto, image display duration, prefetch state). All now closed on teardown.
- Use-after-dispose hazards on `open()` / `openPlaylist()`: disposing the player while URI normalisation was still in flight could SIGSEGV on Android `intent://` loads. Added disposed re-checks after every async boundary.
- Defensive disposal guards on the position polling and embedded-cover pipelines so in-flight work bails instead of writing to closed controllers.
- `setEqualizerGains()` now respects the disposal contract.
- `setAudioFilters()` and `setEqualizerGains()` now route state mutation through the same path as every other setter.
- `openPlaylist(medias, index: N)` no longer silently no-ops when `N >= medias.length`; the index is clamped to `medias.length - 1`.

### Changed
- Reordered the `dispose()` teardown sequence so the event loop exits cleanly without ever calling `mpv_wait_event` on a freed handle.

## [0.0.8] - 24-04-2026

### Added
- `stream.prefetchState` - observable lifecycle of mpv's background playlist-prefetch (`MpvPrefetchState`: `idle`, `loading`, `ready`, `used`).
- `stream.seekCompleted` - authoritative "seek finished" signal that fires exactly once per seek or initial file load.

### Changed
- `on_load` hook now runs for prefetched tracks, so custom URL schemes resolve uniformly whether mpv is opening the current track or pre-opening the next one.
- DASH segment downloads now reuse a single TCP connection across segment GETs (matches HLS persistent-HTTP behaviour).

### Fixed
- Spurious `position = 0` no longer emits on `stream.position` during seek / playback-restart.
- Audible click at every segment boundary on well-formed fragmented-MP4 / DASH streams (AAC encoder priming edit lists are now respected on fMP4).

### Example
- Rewrote the seek slider to release its drag value via `stream.seekCompleted` instead of a fixed delay.

### Build
- Updated libmpv binaries to `libmpv-r4` across all platforms.

## [0.0.7] - 12-04-2026

### Changed
- `audio-format` (u8, s16, s32, float, etc.) now accepts `"no"` and `""` for instant reset to default - previously a full player restart was required.

### Example
- Updated deprecated APIs that prevented the example app from running.

### Build
- Updated libmpv binaries to `libmpv-r3` across all platforms.

## [0.0.6] - 08-04-2026

### Added
- SMB2/3 protocol support (`smb2://`) for Samba (CIFS) network shares via libsmb2.
- Typed error stream - `Stream<MpvPlayerError>` (sealed: `MpvEndFileError`, `MpvLogError`) replaces `Stream<String>`.
- `stream.endFile` (`MpvFileEndedEvent`) for all file-end events, including premature EOF detection.
- `stream.pausedForCache` and `stream.demuxerViaNetwork` for network state monitoring.
- Optional `timeout` parameter on `registerHook` for automatic safety continuation.

### Fixed
- Incorrect name for the audio-stream-silence property.

### Build
- Updated libmpv binaries from `libmpv-r1` to `libmpv-r2` across all platforms.

## [0.0.5+1] - 30-03-2026

### Docs
- Improved README documentation.

## [0.0.5] - 24-03-2026

### Added
- Stream hooks API (`registerHook`, `continueHook`, `player.stream.hook`) to intercept mpv's file-loading pipeline.

### Docs
- README fixes and consistency improvements.

## [0.0.4] - 23-03-2026

### Added
- New APIs to configure embedded and external cover-art handling: `setAudioDisplay`, `setCoverArtAuto`, `setImageDisplayDuration`.

### Changed
- Fast jump into playlist now automatically starts playback.

### Example
- Refined Queue tab design and improved stability.
- Added new sliders to DSP filters.

## [0.0.3+2] - 21-03-2026

### Fixed
- Minor fixes.

## [0.0.3+1] - 21-03-2026

### Build
- New tag system for versioning libmpv binaries (`libmpv-r1`, `libmpv-r2`, …) to avoid conflicts with the pub version number on GitHub Releases.

## [0.0.3] - 21-03-2026

### Changed
- **Linux**: bumped minimum supported OS version to Ubuntu 24.04 - required because mpv 0.41.0 enforces a strict dependency on `libpipewire-0.3 >= 0.3.57` for its native PipeWire backend.

### Docs
- Added a detailed *Troubleshooting* section in the README explaining how to correctly satisfy Linux system dependencies when building on containers.

### Example
- Fixed AO menu not showing the default driver automatically.

## [0.0.2+3] - 20-03-2026

### Build
- Updated Linux libmpv: ALSA, PipeWire, and PulseAudio now all work without external dependencies.

## [0.0.2+2] - 18-03-2026

### Changed
- Cleaned up files.

## [0.0.2+1] - 17-03-2026

### Fixed
- Minor fixes.

## [0.0.2] - 17-03-2026

### Added
- Extended documentation.

### Changed
- Restructured the example app's settings UI: each mpv property has its own dedicated page; the stream lab moved to main navigation.

### Fixed
- File picker on macOS.
- Other audio-engine fixes.

## [0.0.1+9] - 16-03-2026

### Added
- New option to choose the AO driver in the example app.
- Added `audio_service` to the example app to test the native OS audio controls.

### Changed
- Re-added the `audiounit` driver alongside `avfoundation` in libmpv for iOS - `audio_service` now works with both.

## [0.0.1+8] - 16-03-2026

### Changed
- Removed the `audiounit` driver from libmpv to fix the native iOS widget for audio control when using the `audio_service` library.

### Fixed
- File picker error in the example app.

## [0.0.1+7] - 16-03-2026

### Fixed
- macOS libs build.

## [0.0.1+6] - 15-03-2026

### Fixed
- Shuffle bug.

## [0.0.1+5] - 15-03-2026

### Fixed
- Minor fixes.

## [0.0.1+4] - 15-03-2026

### Fixed
- Minor fixes.

## [0.0.1+3] - 15-03-2026

### Fixed
- Minor fixes.

## [0.0.1+2] - 15-03-2026

### Fixed
- Minor fixes.

## [0.0.1+1] - 15-03-2026

### Added
- Swift Package Manager support for iOS and macOS.

### Fixed
- Broken image links on pub.dev (now use absolute GitHub URLs).
- All static analysis warnings; enforced curly braces in flow control structures.

## [0.0.1] - 15-03-2026

### Added
- Initial release. High-performance audio library for Flutter powered by `libmpv` v0.41.0.
- Cross-platform support: iOS, Android, macOS, Windows, and Linux.
- Comprehensive example app demonstrating DSP, hardware routing, and queue management.
