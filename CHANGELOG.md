## [0.1.0]

Major Dart-side refactor. Native build pipeline is unchanged. Six structural problems reported in the 0.0.9 review have been resolved at the root, not patched at the symptom level. A second pass on the public API consolidated runtime-mutable properties as typed setters, collapsed redundant granular config setters into atomic config objects, replaced the stringly-typed track API with a typed model, and added 21 new observable mpv properties for audiobook / podcast / streaming use cases. A pre-release code review pass closed two HIGH and seven MEDIUM correctness findings.

- **Fixed**: HTTP header isolation across `open()` calls. `Media.httpHeaders` previously routed through a global option that persisted for the player lifetime, leaking auth tokens onto unrelated downstream loads. Per-file headers now route through `file-local-options/http-header-fields`, which mpv resets at file boundaries. `Player.add` / `Player.replace` / `Player.openAll` no longer auto-apply per-file headers — use an `on_load` hook for those paths.
- **Fixed**: Android `content://` FD leak. `Player.open` / `add` / `replace` / `openAll` now release the JVM-detached file descriptor when the load is aborted (e.g. dispose mid-resolution). The Kotlin plugin's `closeFileDescriptor` handler now actually closes the FD via `ParcelFileDescriptor.adoptFd(fd).close()`.
- **Fixed**: `Player.openAll` resolves URIs once per item. Previously each entry's URI was resolved twice, leaking one Android `content://` FD per track. Single-pass resolution; abort path frees pending FDs on dispose race.
- **Fixed**: Active `Device.description` no longer mirrors the name. The property now lives outside the registry and cross-references `state.audioDevices` for the human-readable description, falling back to the name on cache miss. `Player.setAudioDevice` ignores the `description` field of the [Device] argument.
- **Fixed**: `Playlist.hashCode` honours value equality. The previous implementation used `List`'s identity-based hash, so structurally-equal playlists could compare `==` but yield different hash codes. Now `Object.hashAll(medias) ^ index.hashCode`.
- **Fixed**: `setRawProperty` / `sendRawCommand` surface mpv errors. Both escape hatches used to silently no-op on rejection (typo, out-of-range, unknown command). Both now throw the new [MpvException] with `name`, `code`, and `message`.
- **Fixed**: `setCustomAudioFilters` rejects wrapper-reserved labels. A custom filter carrying `@_mak_eq:` / `@_mak_comp:` / `@_mak_loud:` / `@_mak_pt:` would silently shadow the matching typed setter; the setter now throws [ArgumentError] up-front.
- **Fixed**: `Player.dispose()` no longer pays a 2 s isolate-stop timeout. Root cause was an `addOnExitListener` registration race; the listener is now armed in `start()` before any shutdown signal can reach the isolate. Clean disposes complete in ~1 ms.
- **Fixed**: Hook continuation idempotency. `registerHook(name)` is now idempotent per name (subsequent calls update only the optional `timeout`). `continueHook(id)` is also idempotent per id — the second call (consumer double-dispatch, or manual continue racing the auto-timeout) is dropped on the wrapper side.
- **Fixed**: Demuxer max-bytes precision. `setDemuxerMaxBytes` and `setDemuxerMaxBackBytes` no longer truncate sub-MiB precision; the wrapper forwards the raw byte count exactly.

- **BREAKING**: `Playlist` migrated to Freezed. `Playlist.empty()` factory is replaced by a const static field `Playlist.empty`. Equality and `copyWith` now follow the same contract as the rest of the model layer; the positional `Playlist(medias, {index})` constructor is preserved.
- **BREAKING**: `Player.openPlaylist` → `Player.openAll`. The multi-media counterpart of `Player.open` follows the Dart-canonical naming (`addAll`, `removeAll`, `openAll`).
- **BREAKING**: Track API typed (`MpvTrack` model). `state.audioTrack: String` is replaced by `state.tracks: List<MpvTrack>` (full inventory) plus `state.currentAudioTrack: MpvTrack?` (active selection). `Player.setAudioTrack(String)` is replaced by `Player.setAudioTrack(Track)` — a sealed type with `.auto` / `.off` / `.id(int)` variants.
- **BREAKING**: Config aggregates (`ReplayGainSettings`, `CacheSettings`). The four ReplayGain setters and five Cache setters collapse into `Player.setReplayGain(ReplayGainSettings)` and `Player.setCache(CacheSettings)`. `state.replayGain` and `state.cache` expose the full aggregate; tweak a single field via `copyWith`.
- **BREAKING**: Escape hatches now async. `getRawProperty()`, `setRawProperty()`, `sendRawCommand()` are now `Future<…>` — required because both setters surface mpv errors as `MpvException`. Add `await` at every call site.
- **BREAKING**: DSP filter API redesigned. `AudioFilter` enum and `setAudioFilters` / `addAudioFilter` / `clearAudioFilters` / `setEqualizerGains` / `stageEqualizerGains` are removed. Replaced by four typed configs and setters: `EqualizerSettings` + `setEqualizer`, `CompressorSettings` + `setCompressor`, `LoudnessSettings` + `setLoudness`, `PitchTempoSettings` + `setPitchTempo`. Anything outside the typed stages goes through `setCustomAudioFilters(List<String>)`. Chain order is fixed: custom → compressor → equalizer → pitch/tempo → loudnorm.
- **BREAKING**: `Player.playOrPause` removed. Use `state.playing ? player.pause() : player.play()`.
- **BREAKING**: `Player.appendLog` removed. Wrapper-side messages now flow through `Player.stream.internalLog` instead of being injected into the engine log stream.
- **BREAKING**: `setImageDisplayDuration` typed. The setter takes `Duration?` (`null` = mpv's `inf`) instead of a free-form `String`.
- **BREAKING**: Setter / state field symmetry. `setGaplessPlayback` → `setGapless`. `setAoNullUntimed` → `setAudioNullUntimed`. `state.audioDisplay` and `state.coverArtAuto` now use the typed `Display` / `Cover` enums.
- **BREAKING**: `PlayerConfiguration` slimmed. `audioClientName` is no longer a constructor parameter; set it post-construction via `Player.setAudioClientName(...)`. `autoPlay`, `initialVolume`, `logLevel` are unchanged.
- **BREAKING**: Naming polish. `state.playlistMode` → `state.loop` (`Loop` enum). Time-based setters (`setAudioDelay`, `setNetworkTimeout`, `setAudioBuffer`) take `Duration` instead of `double seconds`.
- **BREAKING**: `setAudioFormat(String)` → `setAudioFormat(Format)`. The closed dataset of mpv's `audio-format` property becomes a typed enum (`auto`, `u8`/`u8Planar`, `s16`/`s16Planar`, `s32`/`s32Planar`, `float32`/`float32Planar`, `float64`/`float64Planar`). `state.audioFormat` and `stream.audioFormat` carry the typed value.
- **BREAKING**: `setAudioChannels(String)` → `setAudioChannels(Channels)`. Sealed union with `auto` / `autoSafe`, the 41 named layouts mirroring mpv's `std_layout_names[]` table 1-to-1 (`mono`, `stereo`, `fiveOne`, `fiveOneSide`, `sevenOneWideSide`, `quadSide`, `hexagonal`, `cube`, `surround222`, …) exposed as `static const` fields, and a `custom(String)` escape for raw speaker-tag lists. `state.audioChannels` and `stream.audioChannels` carry the typed value.
- **BREAKING**: `setAudioSpdif(String)` → `setAudioSpdif(Set<Spdif>)`. The comma-separated wire format becomes a typed `Set` over a 7-value enum (`Spdif.aac`, `ac3`, `dts`, `dtsHd`, `eac3`, `mp3`, `trueHd`) mirroring mpv's internal whitelist (`audio/decode/ad_spdif.c`). Empty set = passthrough disabled. `state.audioSpdif` and `stream.audioSpdif` carry the typed value; unknown tokens from mpv are dropped silently for forward-compat.
- **BREAKING**: Naming convention pass on the public API surface.
  - Redundant `*Mode` suffixes dropped from typed enums (`GaplessMode` → `Gapless`, `LoopMode` → `Loop`, `CacheMode` → `Cache`, `ReplayGainMode` → `ReplayGain`, `CoverArtAutoMode` → `Cover`, `AudioDisplayMode` → `Display`).
  - `MpvPrefetchState` → `MpvPrefetchState`, `PlaybackLifecycle` → `MpvPlaybackState` (consistent `*State` naming for the three observable lifecycle enums grouped under `types/state/`).
  - Setter-argument types lose the redundant `Audio` prefix when the surrounding setter name (`setAudioFormat`, `setAudioChannels`, …) already conveys the domain: `AudioFormat` → `Format`, `AudioChannels` → `Channels`, `AudioTrack` → `Track`, `AudioDisplay` → `Display`, `AudioDevice` → `Device`. Setter and state-field names for these five are unchanged (`player.setAudioFormat(Format.s16)`, `state.audioFormat`, `state.currentAudioTrack`, …). Read-only data types keep their `Audio` prefix (`AudioParams`, `AudioOutputState`) — they are not setter arguments and the prefix carries domain information.
  - Hook API typed. `Player.registerHook(String)` → `Player.registerHook(Hook)`; `MpvHookEvent.name: String` → `MpvHookEvent.hook: Hook`. The `Hook` enum is the closed set of mpv 0.41 lifecycle phases (`beforeStartFile`, `load`, `loadFail`, `preloaded`, `unload`, `afterEndFile`) — typo-proof, exhaustive in `switch`. Unknown hook names from future mpv builds auto-continue with a warning on `internalLog` so mpv never stalls.
  - All multi-field aggregates renamed to `*Settings` (`CacheSettings`, `ReplayGainSettings`, `EqualizerSettings`, `CompressorSettings`, `LoudnessSettings`, `PitchTempoSettings`).
  - `Track` and `Channels` switched from `@freezed` to native Dart 3 sealed with `static const` fields — call-site drops the `const X.foo()` parens: `setAudioChannels(Channels.stereo)` instead of `const Channels.stereo()`.
  - Internal source layout reorganised under `lib/src/` for clarity: `types/{enums,sealed,settings,state}/` for all public type entities, `models/` for data-class records observed on `state`, `events/` for transient events and errors, `internals/` for non-public implementation, `player/` for the Player core (`player.dart` + `player_state.dart` + `player_stream.dart` + `player_configuration.dart` + 5 mixin parts). No public-facing import paths change for consumers using the package-level `import 'package:mpv_audio_kit/mpv_audio_kit.dart';`.
- **BREAKING**: Cover-art API simplified. The wrapper no longer mutates `Media.extras` with PNG bytes / data URIs. Embedded cover art is exposed as raw codec bytes (PNG / JPEG / WEBP / BMP / GIF) on `Player.stream.coverArtRaw` (`CoverArtRaw(bytes, mimeType)`), one emit per file load. `CoverArtProcessor` and the synthetic video-frame extraction path are removed.

- **Added**: `MpvException` — public exception type thrown by the raw-API escape hatches. Carries `name`, mpv error `code`, and human-readable `message`.
- **Added**: `MpvPrefetchState.failed`. The prefetch lifecycle gains a fifth variant emitted when the background opener thread fails to create the demuxer (network error, unsupported codec, `on_load` hook abort). Edge-triggered like `used`.
- **Added**: A-B loop API. `state.abLoopA` / `state.abLoopB` (`Duration?`), `state.abLoopCount` (`int?`, `null` = infinite), `state.remainingAbLoops` (read-only). Setters: `Player.setAbLoopA`, `setAbLoopB`, `setAbLoopCount`.
- **Added**: Chapter navigation. `state.chapters` (`List<Chapter>`), `state.currentChapter` (`int?`), `state.chapterMetadata` (`Map<String, String>`). Setter: `Player.setChapter(int index)`.
- **Added**: `MpvPlaybackState` aggregate stream. Single mutually-exclusive `idle / loading / buffering / playing / paused / completed` enum derived from the underlying signals — ideal when the UI wants one indicator instead of three.
- **Added**: 13 new observable mpv properties — `audioPts`, `timeRemaining`, `playtimeRemaining`, `eofReached`, `seekable`, `partiallySeekable`, `mediaTitle`, `fileFormat`, `fileSize`, `bufferDuration`, `demuxerIdle`, `prefetchPlaylist`, `audioOutputState`.
- **Added**: Path / URI introspection — `state.path`, `state.filename`, `state.streamPath`, `state.streamOpenFilename`. Surfaces mpv's filename / URI properties for canonical and pre-redirect paths.
- **Added**: Tier 2 introspection — `state.seeking`, `percentPos`, `cacheSpeed`, `cacheBufferingState`, `currentDemuxer`, `currentAo`, `demuxerStartTime`, `mpvVersion`, `ffmpegVersion`. Read-only diagnostics for UI bindings and capability gating.

- **Changed**: Documented `AudioParams.codec` / `codecName` volatility. Both fields mirror mpv's raw `audio-codec` / `audio-codec-name` and may differ across mpv builds; the dartdoc now recommends a case-insensitive substring match against both fields for codec-family detection.
- **Changed**: `Player.stream.log` is now mpv-engine-only. Wrapper-side messages (JSON parse warnings, hook timeouts, resolution errors) moved to the new `Player.stream.internalLog`, disjoint by design so consumers can route engine and wrapper noise to different sinks.

- **Core**: Six structural correctness findings from the 0.0.9 review resolved at the root — HTTP header isolation, `content://` FD leak, `openAll` URI resolution, `Device.description`, `Playlist.hashCode`, dispose teardown timing.
- **Core**: Pre-release review pass closed two HIGH and seven MEDIUM correctness findings — `setCustomAudioFilters` reserved-label rejection, demuxer max-bytes precision, hook idempotency, asset-cache `existsSync` gate, DSP fixed-precision formatting, aggregate-stream initial snapshot + dedup, `content://` resolution error surface, finite-count `loop-file` derivation.
- **Core**: Internal restructuring — Player split into five mixin modules (`_PlaybackModule`, `_PlaylistModule`, `_AudioModule`, `_NetworkModule`, `_HooksModule`); reactive layer reorganised around `MpvPropertySpec` + `PropertyRegistry` so observed mpv properties are a one-line spec edit.
- **Build**: Updated libmpv binaries to `libmpv-r5` across all platforms.

## [0.0.9] - 27-04-2026

- **Fixed**: Lifecycle streams (`stream.playing` / `stream.buffering` / `stream.completed`) silently desynced from `state` on file boundaries. Compound transitions in `MpvEventStartFile` / `MpvEventFileLoaded` / `MpvEndFileEvent` / `MpvEventShutdown` and the `idle-active` property handler were mutating multiple `state` fields at once but only ever fed *at most one* of the corresponding stream controllers — `_completedCtrl` was never fed at all, and `_bufferingCtrl` was a fully dead stream that never emitted in the entire codebase. Most user-visible: `player.stream.completed.listen(...)` never fired on natural EOF, breaking custom queue-advance / "track finished" handlers; `player.stream.buffering.listen(...)` never fired at all, so loading-spinner UX bound to it was effectively broken. Replaced these sites with a single `_updateLifecycle({playing, buffering, completed})` helper that diffs prior vs. next state and emits on each underlying controller exactly when its value changed, so the three streams stay in sync with `state` across all lifecycle transitions.
- **Fixed**: `dispose()` leaked four stream controllers (`_audioDisplayCtrl`, `_coverArtAutoCtrl`, `_imageDisplayDurationCtrl`, `_prefetchStateCtrl`). They were declared and exposed via `PlayerStream` but never closed on teardown — listeners survived past Player destruction and held references to the Player's closure scope. Added all four to the dispose close-list.
- **Fixed**: Use-after-dispose hazards on the public `open()` / `openPlaylist()` paths. Both methods `await AndroidHelper.normalizeUri(...)` per item and then issued `loadfile` commands without re-checking `_disposed` after the await. If the consumer disposed the player while the URI normalisation future was still resolving, the subsequent `_command(['loadfile', ...])` ran against a destroyed mpv handle (potential SIGSEGV on Android intent-URI loads where the await is non-trivial). Added `_disposed` re-checks after every async boundary in both methods.
- **Fixed**: `_pollPosition()` (dispatched from `MpvEventFileLoaded` and `MpvEventPlaybackRestart`) and `_extractEmbeddedCover()` (dispatched from `MpvEventFileLoaded`) both run on the main isolate in response to events forwarded by the event-isolate. With `_eventSub.cancel()` awaited during dispose, in-flight events should never reach the handler — but defensive `_disposed` guards were added to both to harden against future refactors that decouple the cancel from the destroy. Same guard added to the async cover-art pipeline (`_processRawCover`) at every `await` boundary; previously a long-running PNG encode could outlive dispose and call `_updateMediaCover` on a closed `_playlistCtrl`. Dispose now also bumps `_currentCoverOpId` so any in-flight cover work bails on its next op-id check.
- **Fixed**: `setEqualizerGains()` skipped `_checkNotDisposed()`. It now matches the disposal contract of every other setter.
- **Fixed**: `setAudioFilters()` and `setEqualizerGains()` were mutating `_state` directly (`_state = _state.copyWith(...)`) and then manually calling `.add(...)` on the matching controller — functional but inconsistent with the rest of the codebase. Migrated both to `_updateState(...)` so all state mutation flows through one path.
- **Fixed**: `openPlaylist(medias, index: N)` no longer silently no-ops when `N >= medias.length`. The index is now clamped to `medias.length - 1`; raw mpv ignored out-of-range `playlist-play-index` arguments without feedback, which masked off-by-one bugs in consumer queue logic.
- **Core**: Reordered the dispose teardown sequence — `_eventSub.cancel()` is awaited before `mpvTerminateDestroy(_handle)`, and `_eventIsolate.stop()` runs *after* the destroy. mpv's blocking `mpv_wait_event` unblocks naturally with `MPV_EVENT_SHUTDOWN` once the handle is destroyed, so the isolate's run-loop exits cleanly without an attempted `mpv_wait_event` on freed memory. The previous order (stop isolate → destroy handle) had a narrow window where the isolate could re-enter `mpv_wait_event` between the `kill(beforeNextEvent)` queueing and the destroy.

## [0.0.8] - 24-04-2026

- **Core**: Added `stream.prefetchState` — observable lifecycle of mpv's background playlist-prefetch (`MpvPrefetchState`: `idle`, `loading`, `ready`, `used`). Backed by mpv's `prefetch-state` read-only property, so the signal is identical across all demuxer backends (HLS, DASH, raw HTTP, SMB, local).
- **Core**: Added `stream.seekCompleted` — an authoritative "seek finished" signal backed by `MPV_EVENT_PLAYBACK_RESTART`. Fires exactly when mpv has reinitialized playback after a seek (or initial file load).
- **Fixed**: Seek / playback-restart events no longer emit a spurious `position = 0` on `positionStream`. The previous implementation forwarded mpv's `MPV_EVENT_SEEK` and `MPV_EVENT_PLAYBACK_RESTART` as a synthetic `_seek` property with value `0`, which then flowed through `_updatePosition()` and briefly jammed the position stream to zero on every seek. The two events are now forwarded as dedicated `MpvEventPlaybackSeek` / `MpvEventPlaybackRestart` messages, and on playback-restart the main isolate polls `time-pos` synchronously so the real post-seek position is visible on `positionStream` before any throttled observer update.
- **Example**: Rewrote the seek slider in `PlaybackTab` to release its drag value via `stream.seekCompleted` instead of a fixed `Future.delayed(500ms)` — demonstrates the intended usage pattern for the new stream.
- **Core**: `on_load` hook now runs for prefetched tracks, so custom URL schemes (e.g. `plex-transcode://`) resolve uniformly whether mpv is opening the current track or pre-opening the next one in the background.
- **Core**: Fixed audible click at every segment boundary on well-formed fragmented-MP4 / DASH streams (AAC encoder priming edit lists are now respected on fMP4). Set `demuxer-lavf-o=advanced_editlist=0` if your source has malformed per-segment edit lists.
- **Core**: DASH segment downloads now reuse a single TCP connection across segment GETs (HTTP and HTTPS), matching the persistent-HTTP behaviour HLS already had.
- **Build**: Updated libmpv binaries to `libmpv-r4` across all platforms.

## [0.0.7] - 12-04-2026

- **Core**: `audio-format` (u8, s16, s32, float, etc.) accepts `"no"` and `""` for instant reset to default — previously a full player restart was required.
- **Example**: Updated deprecated APIs that prevented the app from running.
- **Build**: Updated libmpv binaries to `libmpv-r3` across all platforms.

## [0.0.6] - 08-04-2026

- **Core**: Added SMB2/3 protocol support (`smb2://`) for Samba/CIFS network shares via libsmb2.
- **Core**: Typed error stream — `Stream<MpvPlayerError>` (sealed: `MpvEndFileError`, `MpvLogError`) replaces `Stream<String>`.
- **Core**: Added `stream.endFile` (`MpvFileEndedEvent`) for all file-end events, including premature EOF detection.
- **Core**: Added `stream.pausedForCache` and `stream.demuxerViaNetwork` for network state monitoring.
- **Core**: Added optional `timeout` parameter to `registerHook` for automatic safety continuation.
- **Fixed**: Incorrect name for audio-stream-silence property.
- **Build**: Updated libmpv binaries from `libmpv-r1` to `libmpv-r2` across all platforms.

## [0.0.5+1] - 30-03-2026

- **README**: Improved documentation.

## [0.0.5] - 24-03-2026

- **Core**: Added stream hooks API (`registerHook`, `continueHook`, `player.stream.hook`) to intercept mpv's file-loading pipeline.
- **README**: Documentation fixes and consistency improvements.

## [0.0.4] - 23-03-2026

- **Core**: Added new APIs to configure embedded and external cover art handling (`setAudioDisplay`, `setCoverArtAuto`, `setImageDisplayDuration`).
- **Core**: Fast jump into playlist now automatically starts playback.
- **Example**: Refined Queue tab design and improved stability.
- **Example**: Added new sliders to DSP filters.

## [0.0.3+2] - 21-03-2026

- Minor fixes.

## [0.0.3+1] - 21-03-2026

- **GitHub Release**: New tag system for versioning libmpv binaries to avoid conflicts with the same release on GitHub. From now on every important update to libmpv (like 0.0.3 Linux fix) will have a new tag and a new release (libmpv-r1, libmpv-r2, etc.). This avoids confusion with the pub version number and ensures users with old SHAs can still use their version when downloading instead of breaking the build.

## [0.0.3] - 21-03-2026

- **Linux**: Bumped minimum supported OS version to Ubuntu 24.04 required because `mpv 0.41.0` enforced a strict dependency on `libpipewire-0.3 >= 0.3.57` for its native PipeWire backend.
- **README**: Added a detailed *Troubleshooting* section in the README explaining how to correctly satisfy Linux system dependencies when building on containers.
- **Example**: Fixed AO menu not showing the default driver automatically.

## [0.0.2+3] - 20-03-2026

- Updated Linux libmpv, ALSA, Pipewire and Pulse now all work without external dependencies.

## [0.0.2+2] - 18-03-2026

- Cleaned up files.

## [0.0.2+1] - 17-03-2026

- Minor fixes.

## [0.0.2] - 17-03-2026

- New extended documentation.
- Fixed filepicker on macOS.
- Restructured settings UI in example app by mpv property each have their own dedicated page and stream lab moved to main navigation.
- Other audio engine fixes.

## [0.0.1+9] - 16-03-2026

- Re-added audiounit driver together with avfoundation in libmpv for iOS. Audio_service now works with both.
- Added new option to choose AO driver in example app.
- Added audio_service to example app to test native controls of the OS.

## [0.0.1+8] - 16-03-2026

- Removed audiounit driver from libmpv to fix native iOS widget for audio control when using audio_service library.
- Fixed filepicker error in example app.

## [0.0.1+7] - 16-03-2026

- Fixed macOS libs build.

## [0.0.1+6] - 15-03-2026

- Fixed shuffle bug.

## [0.0.1+5] - 15-03-2026

- Minor fixes.

## [0.0.1+4] - 15-03-2026

- Minor fixes.

## [0.0.1+3] - 15-03-2026

- Minor fixes.

## [0.0.1+2] - 15-03-2026

- Minor fixes.

## [0.0.1+1] - 15-03-2026

- **Swift Package Manager**: Added support for SPM on iOS and macOS.
- **README**: Fixed broken image links on pub.dev using absolute GitHub URLs.
- **Analysis**: Enforced curly braces in flow control structures and resolved all static analysis warnings.

## [0.0.1] - 15-03-2026

- **Initial Release**: High-performance audio library for Flutter powered by `libmpv` (v0.41.0).
- **Cross-Platform Support**: Seamless playback on iOS, Android, macOS, Windows, and Linux.
- **Example App**: Included a comprehensive example app demonstrating DSP, hardware routing, and queue management.
