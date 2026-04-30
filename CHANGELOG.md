## [0.1.0] - WIP

Major Dart-side refactor. Native build pipeline is unchanged. Six
structural problems reported in the 0.0.9 review have been resolved
at the root, not patched at the symptom level. A second pass on the
public API consolidated runtime-mutable properties as typed setters,
collapsed redundant granular config setters into atomic config
objects, replaced the stringly-typed track API with a typed model,
and added 13 new observable mpv properties for audiobook / podcast /
streaming use cases.

### BREAKING — `Player.openPlaylist` → `Player.openAll`

Multi-media counterpart of [Player.open] now follows the Dart-canonical
`addAll`/`openAll` pattern (mirrors `Iterable.add` ↔ `addAll`).
Migration: `player.openPlaylist(medias) → player.openAll(medias)`.
Signature is otherwise identical (`{bool? play, int index = 0}`).

### BREAKING — track API typed (`MpvTrack` model)

The single stringly-typed `state.audioTrack: String` (`'auto'` /
`'no'` / a number) is replaced by a typed track inventory:

- **`state.tracks: List<MpvTrack>`** + `Player.stream.tracks` — every
  track mpv reports for the current file (audio + embedded picture +
  any other type the demuxer surfaced). Each [MpvTrack] carries
  `id`, `type`, `title`, `lang`, `selected`, `defaultTrack`,
  `forced`, `image`/`albumart` flags, `codec`, `codecDesc`,
  `samplerate`, `channels`, `channelCount`. UI track switchers
  filter by `type == 'audio' && !image && !albumart` to skip the
  embedded `attached_pic` pseudo-tracks.
- **`state.currentAudioTrack: MpvTrack?`** + `Player.stream.currentAudioTrack`
  — the active audio track, `null` when none is selected. Backed by
  mpv's `current-tracks/audio`.
- **`Player.setAudioTrack(int trackId)`** — switches to the track
  with that id. Replaces the old `setAudioTrack(String)` that
  accepted `'auto'` / `'no'` / a numeric string.
- **`Player.setAudioTrackAuto()`** — defers to mpv's automatic
  choice (the container's default-flagged track, or the first audio
  track if none is flagged).
- **`Player.setAudioTrackOff()`** — disables audio output entirely
  (`aid=no`).

Migration:
```dart
// 0.0.x
player.setAudioTrack('1');
player.setAudioTrack('auto');
player.setAudioTrack('no');

// 0.1.0
await player.setAudioTrack(1);
await player.setAudioTrackAuto();
await player.setAudioTrackOff();
```

### BREAKING — config aggregates (`ReplayGainConfig`, `CacheConfig`)

The 4 ReplayGain setters (`setReplayGainMode` / `setReplayGainPreamp`
/ `setReplayGainClip` / `setReplayGainFallback`) and the 5 cache
setters (`setCacheMode` / `setCacheSecs` / `setCacheOnDisk` /
`setCachePause` / `setCachePauseWait`) collapse into two atomic
setters that take a typed config object:

- **`Player.setReplayGain(ReplayGainConfig config)`** — writes the 4
  backing mpv properties in one shot.
- **`Player.setCache(CacheConfig config)`** — writes the 5 backing
  cache properties in one shot.

The matching state / stream surface follows the same shape:

- `state.replayGainMode` / `replayGainPreamp` / `replayGainClip` /
  `replayGainFallback` → **`state.replayGain: ReplayGainConfig`**.
- `state.cacheMode` / `cacheSecs` / `cacheOnDisk` / `cachePause` /
  `cachePauseWait` → **`state.cache: CacheConfig`**.
- 9 individual `Stream<X>` getters → **`Stream<ReplayGainConfig>
  Player.stream.replayGain`** + **`Stream<CacheConfig>
  Player.stream.cache`** (lazy aggregators — source streams are
  only subscribed once a listener attaches, same pattern as
  `audioParams`).

Modify a single field idiomatically with `copyWith`:

```dart
// One-off tweak:
await player.setReplayGain(state.replayGain.copyWith(preamp: -3));
await player.setCache(state.cache.copyWith(
    secs: const Duration(seconds: 30)));

// Restore a saved preset:
await player.setReplayGain(savedRgConfig);
await player.setCache(savedCacheConfig);
```

### BREAKING — `Player.appendLog` removed

The "inject into the wrapper internal-log stream" method was
test/demo scaffolding rather than a load-bearing API. Consumers that
want to tag custom events into a unified log feed maintain their own
`StreamController<MpvLogEntry>` and merge with
`Player.stream.internalLog`. The example app demonstrates the
pattern in `example/lib/screens/player/logs_tab.dart` and
`example/lib/screens/player_page.dart`.

### BREAKING — `setImageDisplayDuration` typed

The setter and the matching state / stream now use `Duration?`
instead of an mpv-wire string:

- `null` keeps the frame alive indefinitely (mpv's `inf`).
- `Duration.zero` drops the frame as soon as audio playback starts.
- A finite `Duration` holds the frame for that long.

Migration: `setImageDisplayDuration('inf')` → `setImageDisplayDuration(null)`,
`setImageDisplayDuration('0')` → `setImageDisplayDuration(Duration.zero)`,
otherwise pass a `Duration`. Matches the `Duration` migration of the
five time-based setters already documented above.

### BREAKING — escape hatches now async

`Player.getRawProperty`, `Player.setRawProperty`, and
`Player.sendRawCommand` are now `Future<X>` instead of synchronous —
matches the 40+ typed setters that have always been
`Future<void>`. Calls without `await` continue to work
fire-and-forget; reading `getRawProperty` requires `await`.

### BREAKING — `Player.playOrPause` removed

One-line convenience that issued a `cycle pause` mpv command. Almost
every UI that needs a play/pause toggle already binds to
`Player.stream.playing` / `state.playing` and decides between
`play()` and `pause()` based on that bool — the toggle method added
no value over the explicit branch. Migration:

```dart
final isPlaying = player.state.playing;
isPlaying ? player.pause() : player.play();
```

### CORE — new observable mpv properties (13 additions)

Public API additions that round out the audio / streaming /
audiobook surface. All thirteen flow through the standard
`Player.stream.X` and `Player.state.X` pairing.

- **`audioPts`** (`Duration`) — `audio-pts`. Audio frame timestamp
  at the playhead; advances per audio frame, includes driver
  latency. More granular than `time-pos` for audio-only sync.
- **`timeRemaining`** (`Duration`) — `time-remaining`. Time until
  EOF, ignoring playback speed.
- **`playtimeRemaining`** (`Duration`) — `playtime-remaining`.
  Speed-adjusted: at 2.0x on a 60 s remaining file this reads 30 s.
- **`eofReached`** (`bool`) — `eof-reached`. Disambiguates a
  natural EOF from a user pause (the existing lifecycle `completed`
  flag fires once per file boundary; `eofReached` mirrors mpv's own
  property continuously).
- **`seekable`** + **`partiallySeekable`** (`bool`) — `seekable` /
  `partially-seekable`. Lets a UI enable/disable the seek bar
  without heuristics (live streams set `seekable=false`; HLS / DASH
  sliding windows set `partiallySeekable=true`).
- **`mediaTitle`** (`String`) — `media-title`. Display name with
  automatic fallback to the file name when no `title` tag is
  present.
- **`fileFormat`** (`String`) — `file-format`. Container format
  (`mp4`, `m4a`, `flac`, `mp3`, …); comma-separated list when the
  demuxer matched multiple formats.
- **`fileSize`** (`int`, bytes) — `file-size`. Zero when unknown.
- **`bufferDuration`** (`Duration`) — `demuxer-cache-duration`.
  Headroom ahead of the playhead. Complements `buffer` (which is
  `demuxer-cache-time`, an absolute timestamp): `buffer` shows
  position, `bufferDuration` shows lookahead.
- **`demuxerIdle`** (`bool`) — `demuxer-cache-idle`. `true` when
  the demuxer thread has nothing to fetch (cache full or EOF);
  `false` while pulling. Combined with `pausedForCache` it
  disambiguates "starved network" from "fully cached, sitting idle".
- **`prefetchPlaylist`** (`bool`) — `prefetch-playlist`, set via
  **`Player.setPrefetchPlaylist(bool)`**. When enabled, mpv opens
  the demuxer for the next track before the current one finishes,
  eliminating the file-boundary stall. Pairs with the existing
  `Player.stream.prefetchState` for end-to-end visibility.
- **`currentChapter`** (`int?`, null when none active) +
  **`chapters`** (`List<Chapter>`) — `chapter` and `chapter-list`,
  jump via **`Player.setChapter(int index)`**. Audiobook / podcast
  chapter navigation. New [Chapter] model carries `time: Duration`
  and `title: String?`.

### CORE — `PlaybackLifecycle` aggregate stream (additive)

New `Player.stream.playbackLifecycle: Stream<PlaybackLifecycle>`
emits a single mutually-exclusive enum (`idle` / `loading` /
`buffering` / `playing` / `paused` / `completed`) derived from the
existing `playing` / `buffering` / `completed` / `pausedForCache` /
`duration` signals. Useful when a UI wants one indicator instead of
three booleans. The underlying booleans remain available for
granular use cases. Lazy aggregator — source streams are only
subscribed once a listener attaches, so the aggregate costs nothing
when unused. Named `PlaybackLifecycle` (not `PlaybackState`) to
avoid an import collision with `audio_service`'s own
`PlaybackState`.

### Fixed (P0)

- **Use-after-dispose hazards on `Player.add()` and
  `Player.replace()`.** Same pattern of bug fixed for
  `Player.open()` / `Player.openPlaylist()` in 0.0.9, but the two
  playlist-mutation methods were missed: each `await
  AndroidHelper.normalizeUri(...)` was followed by `_command(['loadfile',
  ...])` without a `_disposed` re-check, so disposing the player
  while an Android intent-URI normalisation was in flight could
  fire a `loadfile` against a destroyed mpv handle. Both methods
  now re-check `_disposed` after every async boundary.

### CORE — internal restructuring (this release)

- **`audio-output-state` failure → `MpvLogError` extracted** to a
  pure `buildAudioOutputError(AudioOutputState)` helper in
  `lib/src/internal/audio_output_error.dart`. The wrapper
  constructor now invokes the helper directly. Same pattern as
  `lib/src/internal/lifecycle_transitions.dart` and
  `lib/src/internal/playback_lifecycle.dart` — pure helpers tested
  in isolation.
- **`derivePlaybackLifecycle(...)` pure helper** added in
  `lib/src/internal/playback_lifecycle.dart`. Folds the 5 underlying
  signals into the `PlaybackLifecycle` enum without a real player.
- **Single defensive guard for `_handleEvent`.** The 3 redundant
  per-controller `isClosed` guards (`_errorCtrl`,
  `_seekCompletedCtrl`, `_coverArtRawCtrl`) have been removed in
  favour of the single `if (_disposed) return;` fence at the head
  of `_handleEvent`. The dispose ordering (`_disposed = true` →
  `await _eventSub?.cancel()` → controller close) means once the
  fence passes, every controller add() in the switch is guaranteed
  to land on an open controller. The fence comment now documents
  this contract explicitly.

### Build / repo plumbing (this release)

- **Test suite at 260+ tests** across `test/internal/`,
  `test/reactive/`, `test/models/`, `test/utils/`,
  `test/event_isolate/`, `test/cover/`, `test/runtime/`, plus the
  new `test/runtime_extended/` tier (19 files, one Player per file
  to leverage flutter_test's per-file isolate split). Net delta
  vs. 0.0.9 baseline: +68 (new helpers + new mpv-property dispatch
  tests + end-to-end runtime coverage of every public setter on
  the Player surface; consolidation of 17 Freezed-mechanic tests
  into the parametric enum suite). Coverage exercises every
  public setter against real libmpv 0.41 with deterministic
  fixtures, plus error-path / edge-case / dispose-contract /
  sustained-playback observers. See `CLAUDE.md` for the
  cosmetic `tearDownAll` flake on dispose-contract files.
- **Default registry coverage smoke test is bidirectional.** The
  set of registered spec names is asserted equal to the documented
  set: removing a spec from `buildDefaultSpecs` fails with a
  "missing" diff, adding a spec without updating the test fails
  with an "extra" diff. Forces every spec change to surface in code
  review.
- **`enums_test.dart` consolidated** to a single parametric block
  iterating over every (`values`, `fromMpv`, fallback) tuple,
  including `AudioOutputState` (which was missing from the
  per-enum-block layout).
- **Per-setter dispatch tests for the 13 new mpv properties** in
  `default_specs_test.dart`: every observable property added in
  this release (`audio-pts`, `time-remaining`, `playtime-remaining`,
  `eof-reached`, `seekable`, `partially-seekable`, `media-title`,
  `file-format`, `file-size`, `demuxer-cache-duration`,
  `demuxer-cache-idle`, `chapter`, `chapter-list`) round-trips
  through the registry with a typed payload assertion.
- **Aggregate `copyWith` invariant tests** for `ReplayGainConfig`
  and `CacheConfig`: dispatching a single backing mpv property
  must preserve the other 3 (or 4) sibling fields. Pins the
  `s.copyWith(replayGain: s.replayGain.copyWith(...))` reduce
  pattern that the 9 aggregate specs share.
- **`test/runtime_extended/` tier — runtime setter coverage.** A
  new test directory groups end-to-end setter tests (one file per
  concern, every public setter on the Player surface covered) plus
  error / edge / dispose-contract suites:
  - **Setter end-to-end** (14 files): `setters_replaygain_test.dart`,
    `setters_cache_test.dart`, `setters_chapter_test.dart`,
    `setters_tracks_test.dart`, `setters_image_display_test.dart`,
    `setters_open_prefetch_test.dart`,
    `setters_async_escape_test.dart`,
    `setters_audio_basic_test.dart`,
    `setters_audio_output_test.dart`, `setters_dsp_test.dart`,
    `setters_network_test.dart`, `setters_playback_test.dart`,
    `setters_playlist_test.dart`, `setters_hooks_test.dart`.
  - **Error paths** (`error_paths_test.dart`): non-existent file,
    malformed URL, both surface `MpvFileEndedEvent.error` +
    `MpvEndFileError` on the typed error stream;
    `MpvEndFileReason.fromValue` exhaustive mapping for all 5 raw
    codes.
  - **Edge cases** (`edge_cases_test.dart`): 50 ms tiny fixture,
    88.2 kHz exotic sample rate, `openAll([])` no-op, `openAll`
    out-of-range index clamp, 50× rapid sequential `setVolume`.
  - **Dispose contract** (`dispose_safety_test.dart`,
    `dispose_setters_state_error_test.dart`,
    `dispose_escape_hatches_test.dart`): idempotency,
    `StateError` on every typed setter post-dispose,
    `StateError` on every escape hatch post-dispose. Three files
    so each gets its own per-isolate Player budget.
  - **Sustained-playback observers**
    (`runtime_state_test.dart`): `mediaTitle`, `fileFormat`,
    `fileSize`, `seekable`, `partiallySeekable`, `audioBitrate`,
    `bufferDuration`, `audioPts`, `eofReached` all verified live
    on a 5-second fixture.
  - **`isolation_guard_test.dart`** — a permanent guard
    verifying the flutter_test per-file isolate split keeps
    holding.

  Each file spins up its own [Player] in its own isolate group,
  sidestepping the documented SIGSEGV-on-3rd-Player quirk in
  `flutter_test` (see `CLAUDE.md`). Fixtures: 5 new files
  generated via ffmpeg — `test/fixtures/multitrack_two_audio.mka`
  (2-track FLAC-in-Matroska for track-list testing),
  `test/fixtures/with_chapters.mka` (3-chapter FLAC-in-Matroska),
  `test/fixtures/sine_50ms.wav` (boundary tiny duration),
  `test/fixtures/sine_88200hz.flac` (exotic sample rate),
  `test/fixtures/sine_5s.flac` (sustained-playback observer
  testing).

### BREAKING — setter / state field symmetry

The setter and the corresponding [PlayerState] / [PlayerStream] field
now share the exact same name. Six call-sites were inconsistent:

- `setCache(CacheMode)` → `setCacheMode(CacheMode)` (matches
  `state.cacheMode`).
- `setGaplessPlayback(GaplessMode)` → `setGaplessMode(GaplessMode)`
  (matches `state.gaplessMode`).
- `setReplayGain(ReplayGainMode)` → `setReplayGainMode(ReplayGainMode)`
  (matches `state.replayGainMode`).
- `setAudioFilters(List<AudioFilter>)` →
  `setActiveFilters(List<AudioFilter>)` (matches `state.activeFilters`).
- `state.audioDisplay` → `state.audioDisplayMode` (matches the
  `setAudioDisplayMode` setter and the `AudioDisplayMode` enum
  parameter type).
- `state.coverArtAuto` → `state.coverArtAutoMode` (matches the
  `setCoverArtAutoMode` setter and the `CoverArtAutoMode` enum
  parameter type).

The streams on `PlayerStream` follow the field rename
(`stream.audioDisplayMode`, `stream.coverArtAutoMode`).

### BREAKING — `PlayerConfiguration` slimmed

- **`PlayerConfiguration.audioClientName` removed.** The audio client
  name is a runtime-mutable mpv property, so duplicating it in the
  init-time configuration was redundant. Set it via
  `await player.setAudioClientName('YourApp')` after construction.

### BREAKING — naming polish

- **`AudioDisplay` → `AudioDisplayMode`** and **`CoverArtAuto` →
  `CoverArtAutoMode`**. The other three enums (`GaplessMode`,
  `ReplayGainMode`, `CacheMode`) already used the `-Mode` suffix; these
  two were the only outliers. Public API surface — affects setter
  signatures, `PlayerState` field types, `PlayerStream` getter types.
  Migration: rename type references; values (`.no`, `.embeddedFirst`,
  `.fuzzy`, …) are unchanged.
- **`aoNullUntimed` → `audioNullUntimed`** on `setAoNullUntimed` (now
  `setAudioNullUntimed`), `PlayerState.audioNullUntimed`, and
  `PlayerStream.audioNullUntimed`. The `ao` abbreviation was the only
  one in the entire public API — the rest spells "audio" out
  (`setAudioDriver`, `setAudioExclusive`, …). Mpv option name on the
  wire is still `ao-null-untimed`.
- **`Player.log()` → `Player.appendLog()`**. The old `log()` method
  *injected* a message into the wrapper-side stream while
  `Player.stream.log` *subscribes* to the engine-side stream — same
  verb, opposite role. Renamed for disambiguation. Behaviour unchanged.
- **`setEqualizerGains(List<double>)` is now `Future<void> async`**
  (was `void`). Lets call-sites use the same `await player.setX(...)`
  pattern as every other setter. Calls without `await` continue to
  work — the future resolves immediately because no async work is
  performed. Behaviour unchanged.

### BREAKING — public API

- **Typed enums replace stringly-typed setters** for the four properties
  that had a closed value set:
  - `setGaplessPlayback(String)` → `setGaplessPlayback(GaplessMode)`
  - `setReplayGain(String)` → `setReplayGain(ReplayGainMode)`
  - `setAudioDisplay(String)` → `setAudioDisplay(AudioDisplay)`
  - `setCoverArtAuto(String)` → `setCoverArtAuto(CoverArtAuto)`
  - `setCache(String)` → `setCache(CacheMode)`

  The corresponding `PlayerState` fields and `PlayerStream` getters now
  emit the enum types. Each enum exposes `mpvValue` (wire-level string)
  and a `fromMpv(String)` factory for migrating persisted prefs values.
  Unknown values fall back to a documented default rather than throwing.

- **`Duration` replaces `double seconds` on every time-based setter**:
  - `setAudioDelay(double)` → `setAudioDelay(Duration)`
  - `setNetworkTimeout(double)` → `setNetworkTimeout(Duration)`
  - `setCacheSecs(double)` → `setCacheSecs(Duration)`
  - `setCachePauseWait(double)` → `setCachePauseWait(Duration)`
  - `setAudioBuffer(double)` → `setAudioBuffer(Duration)`

  The matching `PlayerState` fields and `PlayerStream` streams emit
  `Duration` too, so `setNetworkTimeout(state.networkTimeout)` round-trips
  cleanly.

- **`PlayerState` now has structural `==` / `hashCode` / `toString`**
  (previously default `Object` identity). Two `PlayerState` instances with
  identical field values are now equal — fixes silent
  `StreamBuilder.distinct()` regressions and lets consumers diff snapshots.
  Same for `AudioParams`, `Media`, `MpvPlayerError` (sealed union),
  `MpvFileEndedEvent`. Generated by Freezed 3.2.5.

- **`Media` equality now considers all fields** (`uri`, `extras`,
  `httpHeaders`), not just `uri`. This is intentional: when `extras`
  changes (cover art attached after load), the containing `Playlist`
  should be observably different.

- **Wrapper-side log split from engine log.** `Player.stream.log` now
  carries only mpv engine messages (`ffmpeg`, `demux`, `ao`, …). Wrapper
  messages (parse warnings, hook timeouts, manual `Player.log()` calls)
  go to a new `Player.stream.internalLog`. Migration: if you used
  `stream.log` to capture *everything*, listen on both streams and merge.

- **`PlayerConfiguration.processCoverArt: bool = true`** added. Set to
  `false` to skip the default 800px BGRA → PNG pipeline entirely; the raw
  BGRA buffer is still emitted on `Player.stream.coverArtRaw` regardless,
  for consumers that want to run their own image processing.

- **`Player.stream.coverArtRaw`** added (`Stream<CoverArtRaw>`). Always
  emits — opt-out only affects the default `extras['artBytes']` PNG.

### CORE — internal symmetry fixes

- **`setShuffle` setter order swap**: was `_updateField` → `_prop` →
  `_command`, now matches every other setter with `_prop` → `_command`
  → `_updateField` (optimistic update *after* the FFI side-effects).
  No observable change for callers; brings consistency to the 40+
  setter contract.
- **`setPlaylistMode` now does an optimistic `_updateField`** so
  `state.playlistMode` reflects the requested mode immediately,
  instead of waiting one or two `loop-file` / `loop-playlist` observer
  events to round-trip from mpv. Same pattern as every other setter.

### Internal layout

- **`PlayerStream` moved** from `lib/src/models/player_stream.dart` to
  `lib/src/player_stream.dart`. The model layer is now pure data; the
  `PlayerStream` facade lives next to `Player` because it depends on
  the reactive layer. Public re-export from
  `package:mpv_audio_kit/mpv_audio_kit.dart` is unchanged.
- Tests reorganised into `test/reactive/` and `test/models/` to mirror
  `lib/src/`.

### CORE — internal restructuring (no behavioural change beyond above)

- **`ReactiveProperty<T>` + `PropertyRegistry`** replace the previous
  pattern where adding an observed mpv property required edits in *six*
  disconnected sites (controller declaration, `PlayerStream` constructor,
  `PlayerState` field + default + copyWith, `_observe` call, dispatcher
  switch case, dispose close-list). The new system reduces this to a
  single `MpvPropertySpec` declaration in `lib/src/reactive/default_specs.dart`.
  Root-cause fix for the class of bugs that produced the silent
  `_completedCtrl` and `_bufferingCtrl` regressions in 0.0.9.

- **Cover-art pipeline reduced to a single FFI helper**
  ([CoverArtExtractor]) that reads the file's embedded picture bytes
  via the `embedded-cover-art-data` mpv property. The wrapper does no
  decoding, no resize, no re-encoding, no filesystem I/O — the bytes
  are forwarded as-is on `Player.stream.coverArtRaw`.

- **`_pendingPlay` race fixed at the root.** The shared field that caused
  rapid `open(A, play:true)` + `open(B, play:false)` calls to race on
  `MPV_EVENT_FILE_LOADED` has been removed. Each `loadfile` call now
  carries a per-file `pause=` option, and the `pause` property observer
  is the sole source of truth for `state.playing` once the file is loaded.
  `jump()` unpauses synchronously before issuing `playlist-play-index`.

- **File rename:** `lib/src/mpv_audio_kit.dart` → `lib/src/library_loader.dart`
  to disambiguate from the public entry point at `lib/mpv_audio_kit.dart`.

### CORE — runtime correctness

- **Fixed (P0): `MPV_FORMAT_INT64` property-change events were silently
  dropped by the event isolate's dispatch switch.** Only `Double` /
  `Flag` / `String` had branches; `Int64` events fell through to the
  unhandled tail and never reached the registry. Symptom: the four
  `MpvIntSpec` properties (`demuxer-max-bytes`,
  `demuxer-readahead-secs`, `demuxer-max-back-bytes`,
  `audio-samplerate`) only ever showed their initial-default value on
  `Player.stream` because the optimistic state update covered the
  setter path but observer-driven changes never arrived. Most visible
  on `state.audioSampleRate`, which is RW but mpv emits autonomously
  after every audio reconfig — the field stayed at `0` for the
  lifetime of the player. `event_isolate.dart` now handles all four
  scalar formats; an integration test in
  `test/runtime/player_runtime_test.dart` is the regression guard.

- **Refactor: `MPV_FORMAT_NODE` now used for natively-structured
  properties** (`playlist`, `metadata`, `audio-device-list`,
  `demuxer-cache-state`, `audio-params`, `audio-out-params`). Previously
  observed as `MPV_FORMAT_STRING` and parsed via `jsonDecode` in Dart.
  Switching to NODE removes one string allocation + one parse per
  property change and preserves int64 sample-rate precision (was
  round-tripping through string conversion). The wire-side pipeline
  inside `event_isolate.dart` decodes the recursive `mpv_node` tree
  into native Dart `Map<String, dynamic>` / `List<dynamic>` / scalar /
  `Uint8List` once at the isolate boundary.

- **Refactor: `audio-params` and `audio-out-params` collapsed from
  5 + 5 sub-property observers to 1 + 1 NODE_MAP observers.** The
  `_bindAggregate` aggregator on `audio-out-params` is gone (the
  spec emits the full snapshot already); the `audio-params` aggregator
  shrunk from 7 to 3 source streams (NODE + the two `audio-codec*`
  siblings mpv keeps separate).

- **Refactor: `MpvDoubleSpec` / `MpvFlagSpec` / `MpvIntSpec` /
  `MpvStringSpec` quartet collapsed into a single `MpvPropertySpec<T>`
  with named factory constructors (`.double`, `.flag`, `.int64`,
  `.string`, `.node`).** The four classes had ~80% identical code, and
  the duplication was exactly the shape that let the Int64 dispatch
  bug above slip through. One class with one `parseAndDispatch`
  pipeline removes that bug class by construction. Internal API only —
  the call sites in `default_specs.dart` and the test suite were the
  only consumers.

- **Refactor: removed `lib/src/internal/json_parsers.dart`** (which
  parsed JSON-string variants of the four properties listed above).
  Replaced by `lib/src/internal/node_parsers.dart` with the same
  function names but Map / List inputs.

- **Polish**: extracted `_kTimePosThrottleMs = 33` named constant in
  `event_isolate.dart` (was a bare `33` literal).
  `PropertyRegistry.registryReplyIdMax = 10000` documents the
  reply-id boundary between registry and out-of-registry observers.
  `_updateField` short-circuits when the reactive dedups the write,
  saving one `PlayerState` allocation per redundant setter call.

- **Polish: `MpvEventIsolate.events` listener now guards against the
  shutdown race** — closing the broadcast controller in `stop()` could
  collide with an in-flight `MpvEventShutdown` add when several
  players are created and disposed in quick succession (showed up
  only under the test suite). The listener now skips the add when
  `_events.isClosed` is true.

### Build / repo plumbing

- Added `freezed_annotation: ^3.1.0` (runtime dep) and
  `freezed: ^3.2.5` + `build_runner: ^2.4.13` (dev deps).
- `build.yaml` constrains codegen to `lib/**` + `test/**` (avoids walking
  symlinked plugins under `example/.../ephemeral/.plugin_symlinks/`).
- `*.freezed.dart` / `*.g.dart` are gitignored; `.pubignore` retains them
  so they ship inside the published tarball. Run `dart run build_runner build`
  before `dart pub publish` (or use `scripts/publish.sh` which chains both).
- **Test suite expanded to ~198 tests** across `test/reactive/`,
  `test/internal/`, `test/models/`, `test/utils/`, `test/event_isolate/`
  (new — `decodeMpvNode` synthetic tree decoder), `test/cover/` (new —
  BGRA → PNG round-trip with stride padding + cancellation),
  `test/runtime/` (new — real-libmpv smoke tests gated on macOS / Linux
  with a 44 KB sine WAV fixture in `test/fixtures/`).
### CORE — new observable mpv properties

- **`audio-output-state`** — exposes mpv's audio-output lifecycle as
  a typed `closed | initializing | active | failed` enum on
  `Player.stream.audioOutputState` and `state.audioOutputState`. The
  wrapper surfaces a typed `MpvLogError` on `Player.stream.error` the
  moment the state reaches `failed`, replacing the previous 1-second
  delayed sanity check on `audio-out-params/format` (which had race
  conditions on slow-init audio backends and on rapid file
  unload/reload).

- **`embedded-cover-art-data`** + **`embedded-cover-art-mime`** —
  return the original codec bytes (PNG / JPEG / WEBP / BMP / GIF) of
  the file's attached_pic stream, with the matching MIME type.
  Replaces the previous BGRA-via-`screenshot-raw video` capture
  pipeline: no decode, no pixel format conversion, no alpha
  correction, no re-encode. The change events fire on every file
  load, so observers see new artwork without polling.

### BREAKING — cover-art API simplified

The wrapper no longer processes cover art, no longer mutates the
[Playlist]/[Media] graph after a file load, and no longer touches the
filesystem for cover output. The full pipeline is now: mpv emits the
embedded codec bytes → wrapper reads them → wrapper emits a
[CoverArtRaw] on `Player.stream.coverArtRaw`. That's it.

- **`CoverArtRaw`** is now a simple data class with `bytes`
  (`Uint8List` of the original codec bytes — PNG / JPEG / WEBP / BMP /
  GIF) and `mimeType`. No width / height / stride / isContiguous, no
  BGRA pixel buffer.
- **`Player.stream.coverArtRaw`** emits codec bytes straight from the
  source file. Hand them to `Image.memory(raw.bytes)` for in-app
  rendering — Flutter dispatches on magic bytes, no decode helper
  needed.
- **`PlayerConfiguration.processCoverArt` is removed.** The wrapper no
  longer does opt-in/opt-out resize-to-PNG; it just emits the bytes.
  Apps that want a downscaled PNG run their own
  `dart:ui.instantiateImageCodec` pipeline.
- **`playlist.medias[i].extras` is no longer mutated by the wrapper.**
  The previous side-effect that injected `'artBytes'`, `'artUri'`, and
  `'cover'` keys on every file load is gone — `Media` instances are
  now stable across track transitions, exactly as the consumer
  constructed them. Apps that relied on those keys must migrate to the
  cover stream:
  ```dart
  player.stream.coverArtRaw.listen((raw) {
    setState(() => _cover = raw);
  });
  // …
  if (_cover != null) Image.memory(_cover!.bytes);
  ```
- **`CoverArtProcessor` is removed.** Was an opinionated 800px PNG
  re-encoder used internally by the previous `processCoverArt` path.
  Apps that want resize / re-encode now do it directly with `dart:ui`
  (≈30 lines, mirrors what the helper used to do).
- **Video-frame cover extraction is no longer supported.** The
  package is audio-only: only the file's embedded attached_pic is
  surfaced as cover art. Files without an embedded cover yield no
  emission on `coverArtRaw`.

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
