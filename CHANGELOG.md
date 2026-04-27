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

- **Core**: Added `stream.prefetchState` — observable lifecycle of mpv's background playlist-prefetch (`MpvPrefetchState`: `idle`, `loading`, `ready`, `used`). Backed by a patched mpv `prefetch-state` read-only property, so the signal is identical across all demuxer backends (HLS, DASH, raw HTTP, SMB, local).
- **Core**: Added `stream.seekCompleted` — an authoritative "seek finished" signal backed by `MPV_EVENT_PLAYBACK_RESTART`. Fires exactly when mpv has reinitialized playback after a seek (or initial file load).
- **Fixed**: Seek / playback-restart events no longer emit a spurious `position = 0` on `positionStream`. The previous implementation forwarded mpv's `MPV_EVENT_SEEK` and `MPV_EVENT_PLAYBACK_RESTART` as a synthetic `_seek` property with value `0`, which then flowed through `_updatePosition()` and briefly jammed the position stream to zero on every seek. The two events are now forwarded as dedicated `MpvEventPlaybackSeek` / `MpvEventPlaybackRestart` messages, and on playback-restart the main isolate polls `time-pos` synchronously so the real post-seek position is visible on `positionStream` before any throttled observer update.
- **Example**: Rewrote the seek slider in `PlaybackTab` to release its drag value via `stream.seekCompleted` instead of a fixed `Future.delayed(500ms)` — demonstrates the intended usage pattern for the new stream.
- **Build**: Patched mpv's `prefetch_next()` to run the `on_load` hook before the opener thread spawns, so custom URL schemes (e.g. `plex-transcode://`) also resolve for prefetched tracks. Upstream mpv skipped hooks on the prefetch path, which hit the stream layer with unresolved URLs and failed with "No protocol handler found".
- **Build**: Patched ffmpeg's mov demuxer for the `advanced_editlist` option on fragmented MP4. Upstream silently forces it to `0` for fMP4, ignoring whatever the user sets — which drops AAC encoder priming edit lists and causes an audible click at every segment boundary on well-formed DASH streams. The patch removes the override so the user-supplied value (default `1`) is respected; set `demuxer-lavf-o=advanced_editlist=0` to restore upstream behavior for sources with malformed per-segment edit lists.
- **Build**: Patched ffmpeg's DASH demuxer to reuse a single TCP connection across segment GETs (HTTP and HTTPS), matching the `http_persistent` behaviour HLS already has.
- **Build**: Updated libmpv binaries to `libmpv-r4` across all platforms.

## [0.0.7] - 12-04-2026

- **Core**: Patched audio-format (u8, s16, s32, float, etc.) to allow instant reset to default — setting it to `"no"` (newly accepted) or `""` now resets the format immediately, while previously a full player restart was required.
- **Example**: Updated deprecated APIs that prevented the app from running.
- **Build**: Updated libmpv binaries to `libmpv-r3` across all platforms.

## [0.0.6] - 08-04-2026

- **Core**: Added SMB2/3 protocol support (`smb2://`) for Samba/CIFS network shares via patched libsmb2.
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
