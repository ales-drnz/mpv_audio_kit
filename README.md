# mpv_audio_kit

#### Audio engine for Flutter and Dart.

[![](https://img.shields.io/pub/v/mpv_audio_kit.svg?style=for-the-badge&logo=dart&logoColor=white)](https://pub.dev/packages/mpv_audio_kit)
[![](https://img.shields.io/badge/libmpv-v0.41.0-orange.svg?style=for-the-badge)]()
[![](https://img.shields.io/badge/license-BSD--3--Clause-blue.svg?style=for-the-badge)](LICENSE)
[![](https://img.shields.io/github/stars/ales-drnz/mpv_audio_kit?style=for-the-badge&logo=github&logoColor=white)](https://github.com/ales-drnz/mpv_audio_kit)
[![](https://img.shields.io/discord/1485588004029333516?style=for-the-badge&logo=discord&logoColor=white)](https://discord.gg/g2Qf4Mq9MP)
[![](https://img.shields.io/badge/Patreon-F96854?style=for-the-badge&logo=patreon&logoColor=white)](https://www.patreon.com/cw/ales_drnz)
[![](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-FFDD00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black)](https://www.buymeacoffee.com/ales.drnz)

<img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/mpv_audio_kit.png" width="70" align="left" style="margin-right: 15px;" alt="logo" />`mpv_audio_kit` is an audio library built on `libmpv` v0.41.0, the engine behind the mpv media player. It provides a dedicated background event loop, a complete DSP pipeline, and direct access to every property, making it the most capable audio library available for Flutter.
<br clear="left"/>

---

## Why did I build this?

Many existing Flutter audio libraries are either built on an old version of mpv or they are simply too restrictive, hiding some cool features relative to audio processing. So I made this project to provide the most powerful and flexible audio library for Flutter and solve 3 main needs:

- <img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/protocols/jellyfin.png" width="20" alt="Jellyfin"> **Jellyfin**: for song streaming, supporting `.m3u8` (HLS) is essential when using transcoding. This is particulary handy because it enables seeking on the mpv player instead of blocking it when using `.stream`.
- <img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/protocols/plex.png" width="20" alt="Plex"> **Plex**: transcoding in this case requires a `/decision` call before each stream. Plex rejects multiple parallel requests when creating queue, so instead of relying to a local proxy server, the `on_load` hook method resolves `.m3u8` or `.mpd` URLs lazily.
- ⚙️ **Total control:** this library doesn't limit features; it exposes the native engine so you can tune buffers, network timeouts, DSP filters and play with ffmpeg exactly how you want.

---

## Installation

Add `mpv_audio_kit` to your `pubspec.yaml`:

```yaml
dependencies:
  mpv_audio_kit: ^0.1.0
```

### ⚠️ 0.1.0 is a big release!

The Dart API has been rewritten from scratch: typed enums everywhere,
atomic config aggregates (`CacheSettings`, `ReplayGainSettings`), a
redesigned DSP pipeline unified under a single [`AudioEffects`] bundle,
and the escape hatches are now async. Go to the
[Migration guide](#migration) to see more.

### Platform requirements

*   **Android**: SDK 24 (Android 7.0) or above.
*   **iOS**: iOS 15.0 or above.
*   **macOS**: 12.0 or above (Apple Silicon).
*   **Windows**: Windows 10 or above.
*   **Linux**: Ubuntu 24.04 or above.

---

## Platforms

| Platform  | Architecture | Device | Emulator | mpv version |
| :--- | :--- | :---: | :---: | :---: |
| **Android** | arm64-v8a, x86_64 | ✅ | ✅ | v0.41.0 |
| **iOS** | arm64 | ✅ | ✅ | v0.41.0 |
| **macOS** | arm64 | ✅ | - | v0.41.0 |
| **Windows**| arm64, x86_64 | ✅ | - | v0.41.0 |
| **Linux** | arm64, x86_64 | ✅ | - | v0.41.0 |

---

## Reference

*   [Visuals](#visuals)
*   [Features](#features)
*   [Quick start](#quick-start)
*   [Guide](#guide)
    *   [1. Initialization and lifecycle](#1-initialization-and-lifecycle)
        *   [1.1 Global initialization](#11-global-initialization)
        *   [1.2 Creating a player](#12-creating-a-player)
        *   [1.3 Disposing a player](#13-disposing-a-player)
    *   [2. Media sources](#2-media-sources)
        *   [2.1 Supported URI schemes](#21-supported-uri-schemes)
        *   [2.2 HTTP headers](#22-http-headers)
        *   [2.3 Extras](#23-extras)
    *   [3. Playlist management](#3-playlist-management)
        *   [3.1 Opening a single track](#31-opening-a-single-track)
        *   [3.2 Opening multiple tracks](#32-opening-multiple-tracks)
        *   [3.3 Modifying the queue at runtime](#33-modifying-the-queue-at-runtime)
        *   [3.4 Navigation](#34-navigation)
        *   [3.5 Repeat and shuffle](#35-repeat-and-shuffle)
        *   [3.6 Chapter navigation](#36-chapter-navigation)
    *   [4. Playback control](#4-playback-control)
        *   [4.1 Basic controls](#41-basic-controls)
        *   [4.2 Seeking](#42-seeking)
        *   [4.3 A-B loop](#43-a-b-loop)
        *   [4.4 Speed and pitch](#44-speed-and-pitch)
        *   [4.5 Volume and mute](#45-volume-and-mute)
        *   [4.6 Audio delay](#46-audio-delay)
    *   [5. Audio quality and DSP](#5-audio-quality-and-dsp)
        *   [5.1 The AudioEffects bundle](#51-the-audioeffects-bundle)
        *   [5.2 Common effects - quick examples](#52-common-effects--quick-examples)
        *   [5.3 Available effects](#53-available-effects)
        *   [5.4 ReplayGain](#54-replaygain)
        *   [5.5 Gapless playback](#55-gapless-playback)
    *   [6. Hardware and routing](#6-hardware-and-routing)
        *   [6.1 Audio output driver](#61-audio-output-driver)
        *   [6.2 Exclusive mode](#62-exclusive-mode)
        *   [6.3 Device selection](#63-device-selection)
        *   [6.4 Output format](#64-output-format)
        *   [6.5 S/PDIF passthrough](#65-spdif-passthrough)
        *   [6.6 Audio client name](#66-audio-client-name)
        *   [6.7 Audio track selection](#67-audio-track-selection)
        *   [6.8 Reload audio](#68-reload-audio)
    *   [7. Network and caching](#7-network-and-caching)
        *   [7.1 Cache configuration](#71-cache-configuration)
        *   [7.2 Demuxer memory pool](#72-demuxer-memory-pool)
        *   [7.3 Network timeout](#73-network-timeout)
        *   [7.4 TLS/SSL verification](#74-tlsssl-verification)
        *   [7.5 Audio buffer](#75-audio-buffer)
        *   [7.6 Audio stream silence](#76-audio-stream-silence)
        *   [7.7 Untimed null output](#77-untimed-null-output)
        *   [7.8 Radio and live streams](#78-radio-and-live-streams)
    *   [8. Metadata and cover art](#8-metadata-and-cover-art)
        *   [8.1 Metadata tags](#81-metadata-tags)
        *   [8.2 Cover art](#82-cover-art)
    *   [9. State and streams](#9-state-and-streams)
        *   [9.1 Core streams](#91-core-streams)
        *   [9.2 Playlist and track streams](#92-playlist-and-track-streams)
        *   [9.3 Audio hardware streams](#93-audio-hardware-streams)
        *   [9.4 DSP and filter streams](#94-dsp-and-filter-streams)
        *   [9.5 Network and cache streams](#95-network-and-cache-streams)
        *   [9.6 File metadata and path streams](#96-file-metadata-and-path-streams)
        *   [9.7 Playback timing streams](#97-playback-timing-streams)
        *   [9.8 A-B loop streams](#98-a-b-loop-streams)
        *   [9.9 Cover art streams](#99-cover-art-streams)
        *   [9.10 Runtime diagnostics](#910-runtime-diagnostics)
        *   [9.11 Prefetch lifecycle stream](#911-prefetch-lifecycle-stream)
        *   [9.12 Aggregate lifecycle](#912-aggregate-lifecycle)
        *   [9.13 Complete state snapshot](#913-complete-state-snapshot)
        *   [9.14 Spectrum and PCM streams](#914-spectrum-and-pcm-streams)
    *   [10. Raw API](#10-raw-api)
        *   [10.1 Read a property](#101-read-a-property)
        *   [10.2 Write a property](#102-write-a-property)
        *   [10.3 Send a command](#103-send-a-command)
    *   [11. Error handling and logging](#11-error-handling-and-logging)
        *   [11.1 Typed error stream](#111-typed-error-stream)
        *   [11.2 End file stream](#112-end-file-stream)
        *   [11.3 Network state](#113-network-state)
        *   [11.4 Audio output lifecycle](#114-audio-output-lifecycle)
        *   [11.5 Log streams](#115-log-streams)
    *   [12. Hooks](#12-hooks)
        *   [12.1 Registering a hook](#121-registering-a-hook)
        *   [12.2 Listening and continuing](#122-listening-and-continuing)
        *   [12.3 HTTP headers via hook](#123-http-headers-via-hook)
        *   [12.4 Lazy URL resolution](#124-lazy-url-resolution)
    *   [13. Visualizer and spectrum analyzer](#13-visualizer-and-spectrum-analyzer)
        *   [13.1 Subscribing to the spectrum stream](#131-subscribing-to-the-spectrum-stream)
        *   [13.2 Configuring the pipeline](#132-configuring-the-pipeline)
        *   [13.3 Raw PCM stream](#133-raw-pcm-stream)
*   [Migration](#migration)
*   [Permissions](#permissions)
*   [Troubleshooting](#troubleshooting)
*   [Project background](#project-background)

---

## Visuals

The following images demonstrate the example app included in the `example/` directory. This application serves as a reference music player for testing the various features and capabilities of mpv.

#### Desktop

<table width="100%">
  <tr>
    <td width="60%"><img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/desktop_player_console.gif" width="100%"></td>
    <td align="left"><b>Player</b><br>Cover art, metadata, and controls alongside pinned logs.</td>
  </tr>
  <tr>
    <td width="60%"><img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/desktop_settings_grid.png" width="100%"></td>
    <td align="left"><b>Settings</b><br>Navigation for all properties such as <code>--af</code>, <code>--cache</code>, <code>--network</code>, etc.</td>
  </tr>
</table>

#### Mobile

<table width="100%">
  <tr>
    <td width="25%"><img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/mobile_player.png" width="100%"></td>
    <td width="25%" align="left"><b>Player</b><br>Cover art, metadata, and controls</td>
    <td width="25%"><img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/mobile_queue.png" width="100%"></td>
    <td width="25%" align="left"><b>Queue</b><br>Playlist with shuffle & repeat</td>
  </tr>
  <tr>
    <td width="25%"><img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/mobile_filters.png" width="100%"></td>
    <td width="25%" align="left"><b>Filters (<code>--af</code>)</b><br>18-band EQ, Loudnorm & Compressor</td>
    <td width="25%"><img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/mobile_audio_hardware.png" width="100%"></td>
    <td width="25%" align="left"><b>Hardware (<code>--audio</code>)</b><br>Output device, format & channels</td>
  </tr>
</table>

---

## Features

- ⚡ **Non-blocking** - mpv events run in a background isolate; the UI thread stays free.
- 🧬 **Type-safe API** - typed enums, sealed selectors, `*Settings` bundles. No stringly-typed setters.
- 📡 **Reactive state** - synchronous [`state`](#913-complete-state-snapshot) snapshot, [90+ observable streams](#9-state-and-streams) covering every mpv property.
- 🎵 **Gapless playback** - seamless track transitions with an observable [prefetch lifecycle](#911-prefetch-lifecycle-stream).
- 🎛️ **DSP pipeline** - single atomic [`AudioEffects`](#5-audio-quality-and-dsp) bundle: 18-band graphic EQ, compressor, loudness, pitch / tempo, bass / treble, stereo width, headphone crossfeed, silence trim, plus any custom `--af` filter.
- 🎨 **Visualizer** - real-time [FFT spectrum + raw PCM streams](#13-visualizer-and-spectrum-analyzer) with log-spaced bands and asymmetric smoothing.
- ⚖️ **ReplayGain** - track & album normalization, preamp, fallback gain.
- 📜 **Dynamic playlist** - add, remove, move, replace mid-playback; [chapters](#36-chapter-navigation) and [A-B loop](#43-a-b-loop).
- 🎼 **Multi-track audio** - typed [track selection](#67-audio-track-selection) for multilingual containers (MKV, MP4) with codec / language / gain metadata per track.
- ⚙️ **Hardware control** - [exclusive mode](#62-exclusive-mode), [device selection](#63-device-selection), [bit-perfect sample-rate / format](#64-output-format), [S/PDIF passthrough](#65-spdif-passthrough).
- 🔍 **Metadata & cover art** - [embedded artwork](#82-cover-art) as raw bytes plus a Flutter [`ImageProvider`](#82-cover-art) helper, and [tags](#81-metadata-tags).
- 🌐 **Network streams** - HLS, DASH, SMB and HTTP/HTTPS.
- 📦 **Cache control** - atomic [`CacheSettings`](#71-cache-configuration) for memory pool, disk overflow, pause-on-empty.
- 🪝 **Hooks** - intercept the file-loading pipeline (also during [prefetch](#12-hooks)) to resolve URLs, redirect, or inject headers.
- 🚨 **Typed errors** - sealed [`MpvPlayerError`](#111-typed-error-stream) hierarchy + dedicated sinks for engine errors, end-file events, AO failures, and logs.
- 🔧 **Raw access** - read / write any mpv property or command; failures surface as typed [`MpvException`](#10-raw-api).

---

## Quick start

```dart
import 'package:flutter/material.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MpvAudioKit.ensureInitialized();
  runApp(const MaterialApp(home: AudioPlayerScreen()));
}

class AudioPlayerScreen extends StatefulWidget {
  const AudioPlayerScreen({super.key});
  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  late final Player player = Player();

  @override
  void initState() {
    super.initState();
    player.open(Media('https://example.com/audio.mp3'));
  }

  @override
  void dispose() {
    player.dispose(); // fire and forget is fine inside Flutter's synchronous dispose()
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: StreamBuilder<Duration>(
          stream: player.stream.position,
          builder: (context, snap) => Text('Position: ${snap.data}'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            player.state.playing ? player.pause() : player.play(),
        child: const Icon(Icons.play_arrow),
      ),
    );
  }
}
```

---

## Guide

### 1. Initialization and lifecycle

<img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/diagrams/player_lifecycle.png" width="100%">

#### 1.1 Global initialization

Call `MpvAudioKit.ensureInitialized()` once at startup, before creating any `Player` instance. This registers the native backend and cleans up any handles that leaked across a Flutter Hot-Restart.

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MpvAudioKit.ensureInitialized();
  runApp(const MyApp());
}
```

#### 1.2 Creating a player

```dart
final player = Player(
  configuration: const PlayerConfiguration(
    logLevel: LogLevel.info, // mpv log verbosity
    initialVolume: 100.0, // Volume at startup (0–100)
    autoPlay: true,       // Start playing automatically on open()
  ),
);
```

All `PlayerConfiguration` fields are optional. Their defaults:

| Field | Default | Description |
| :--- | :--- | :--- |
| `autoPlay` | `false` | Whether `open()` starts playback immediately |
| `initialVolume` | `100.0` | Volume at startup |
| `logLevel` | `'warn'` | mpv log level (`'trace'`, `'debug'`, `'v'`, `'info'`, `'warn'`, `'error'`, `'fatal'`, `'no'`) forwarded to `player.stream.log` |

The audio client name is set after construction:

```dart
await player.setAudioClientName('MyMusicApp');
```

#### 1.3 Disposing a player

Always call `dispose()` to release native handles.

```dart
await player.dispose();
```

---

### 2. Media sources

A `Media` object wraps a URI with optional per-track metadata and HTTP configuration.

```dart
// HTTPS stream
final track = Media('https://cdn.example.com/audio.flac');

// Local file
final local = Media('file:///home/user/music/song.flac');

// Flutter asset
final asset = Media('asset:///assets/audio/sample.mp3');

// Android content URI (e.g. from file picker)
final content = Media('content://com.android.externalstorage.documents/...');
```

#### 2.1 Supported URI schemes

##### Local and app-bundled sources

|  | Scheme | Description |
| :---: | :--- | :--- |
| <img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/protocols/file.png" width="20" alt="File"> | `file://` | Local files with absolute path |
| <img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/protocols/flutter.png" width="20" alt="Flutter"> | `asset:///` | Flutter assets bundled in the app |
| <img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/protocols/android.png" width="20" alt="Android"> | `content://` | Android content provider URIs (file picker, media store) |

##### Streaming sources

|  | Scheme | Description |
| :---: | :--- | :--- |
| <img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/protocols/https.png" width="20" alt="HTTPS"> | `https://` / `http://` | Network streams, live radio, etc... |
| <img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/protocols/jellyfin.png" width="20" alt="Jellyfin"> | `https://…/*.m3u8` | HTTP Live Streaming (HLS) manifest, as used by Jellyfin transcoding |
| <img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/protocols/plex.png" width="20" alt="Plex"> | `https://…/*.mpd` | Dynamic Adaptive Streaming over HTTP (DASH) manifest, as used by Plex transcoding |
| <img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/protocols/samba.png" width="20" alt="Samba"> | `smb2://` | SMB2/3 network shares |

#### 2.2 HTTP headers

Headers are applied natively to the libmpv HTTP layer, without a local proxy:

```dart
final media = Media(
  'https://api.example.com/stream/episode-42.mp3',
  httpHeaders: {
    'Authorization': 'Bearer my_token',
    'User-Agent': 'MyApp/1.0',
    'X-Custom-Header': 'value',
  },
);
await player.open(media);
```

#### 2.3 Extras

Attach arbitrary data to a track. The player carries it through the
playlist so your UI can access it without a separate lookup.

```dart
final media = Media(
  'https://cdn.example.com/track.mp3',
  extras: {
    'title': 'Track Title',
    'artist': 'Artist Name',
    'album': 'Album Name',
    'duration': const Duration(minutes: 4, seconds: 12),
    'isPodcast': true,
  },
);
```

Access later via `player.state.playlist.items[index].extras`.

---

### 3. Playlist management

#### 3.1 Opening a single track

```dart
// Respects PlayerConfiguration.autoPlay
await player.open(media);

// Override auto-play for this call
await player.open(media, play: true);
await player.open(media, play: false); // Load but do not start
```

#### 3.2 Opening multiple tracks

```dart
await player.openAll([track1, track2, track3]);

// Start at a specific index
await player.openAll([track1, track2, track3], index: 1);

// Override auto-play
await player.openAll([track1, track2], play: false);
```

> Per-track HTTP headers from `Media.httpHeaders` are applied
> automatically only to the first item - for the rest, register an
> `on_load` hook (see [§12](#12-hooks)).

#### 3.3 Modifying the queue at runtime

```dart
await player.add(newTrack);          // Append to end
await player.remove(0);              // Remove track at index 0
await player.move(5, 0);             // Move track from index 5 to index 0
await player.replace(2, newTrack);   // Replace track at index 2

await player.clearPlaylist();        // Remove all tracks
```

#### 3.4 Navigation

```dart
await player.next();       // Skip to the next track
await player.previous();   // Skip to the previous track
await player.jump(2);      // Jump to track at index 2 (0-indexed)
```

#### 3.5 Repeat and shuffle

```dart
// Repeat modes
await player.setLoop(Loop.off);       // No repeat (default)
await player.setLoop(Loop.file);      // Loop the current track
await player.setLoop(Loop.playlist);  // Loop the entire playlist

// Shuffle
await player.setShuffle(true);   // Shuffle the queue
await player.setShuffle(false);  // Restore original order
```

`Loop` aggregates mpv's two underlying loop properties (`loop-file`
and `loop-playlist`) into a single mutually-exclusive choice. Subscribe
via `player.stream.loop` for live updates.

#### 3.6 Chapter navigation

For audiobooks, podcasts, and any container that ships chapter markers:

```dart
// Subscribe to the chapter list (populated after each load)
player.stream.chapters.listen((chapters) {
  for (var i = 0; i < chapters.length; i++) {
    print('${i}. ${chapters[i].title} @ ${chapters[i].time}');
  }
});

// Active chapter index (0-based; null when no chapter is active)
player.stream.currentChapter.listen((idx) => print('chapter: $idx'));

// Per-chapter metadata (mpv `chapter-metadata`)
player.stream.chapterMetadata.listen((tags) => print(tags));

// Jump to a chapter by index
await player.setChapter(2);
```

`Chapter` exposes `time` and an optional `title`. Use `state.demuxerStartTime` if you need the source-side.

---

### 4. Playback control

#### 4.1 Basic controls

```dart
await player.play();    // Start or resume
await player.pause();   // Pause
await player.stop();    // Stop and unload current file

// Toggle pattern
player.state.playing ? await player.pause() : await player.play();
```

#### 4.2 Seeking

```dart
// Seek to an absolute position
await player.seek(const Duration(seconds: 30));

// Seek forward or backward relative to current position
await player.seek(const Duration(seconds: 10), relative: true);
await player.seek(const Duration(seconds: -5), relative: true);
```

mpv uses the `absolute` seek mode by default, which works correctly on
all formats including HLS, providing precise seeking even during
transcoded streams.

#### 4.3 A-B loop

Define a sub-region of the current track and loop between two
timestamps. Useful for language-learning apps, transcript review, or
practising a passage on repeat.

```dart
// Set the A and B markers (null disables the marker)
await player.setAbLoopA(const Duration(seconds: 30));
await player.setAbLoopB(const Duration(seconds: 45));

// Limit the number of repetitions; null = infinite
await player.setAbLoopCount(3);

// Read remaining iterations (null = no loop or infinite)
player.stream.remainingAbLoops.listen((n) => print('left: $n'));

// Disable
await player.setAbLoopA(null);
await player.setAbLoopB(null);
```

#### 4.4 Speed and pitch

```dart
await player.setRate(1.5);              // 1.5× speed (0.01 – 100.0)
await player.setPitch(0.9);             // Lower pitch without affecting speed
await player.setPitchCorrection(true);  // Pitch correction when changing rate
```

`setPitchCorrection` enables mpv's `scaletempo` algorithm, which
adjusts playback speed while preserving the original pitch.

For high-quality time-stretching that decouples pitch and tempo, use
the [`rubberband`](#52-common-effects--quick-examples) effect on the
DSP bundle.

#### 4.5 Volume and mute

```dart
await player.setVolume(80.0);     // 0–100 (values above 100 amplify)
await player.setMute(true);
await player.setMute(false);

await player.setVolumeMax(150.0); // Raise the software volume ceiling
await player.setVolumeGain(6.0);  // Pre-amplify by +6 dB
```

#### 4.6 Audio delay

```dart
// Shift audio forward by 50 ms (useful for Bluetooth A2DP sync)
await player.setAudioDelay(const Duration(milliseconds: 50));

// Shift backward by 200 ms
await player.setAudioDelay(const Duration(milliseconds: -200));
```

---

### 5. Audio quality and DSP

All processing in this section runs through ffmpeg filter pipeline and
works on every platform.

#### 5.1 The AudioEffects bundle

The DSP rack lives on a single immutable [`AudioEffects`] value. Every
audio effect has its own typed `*Settings` field on the bundle, and
the whole rack is applied atomically via two setters on `Player`:

```dart
// Replace the whole bundle (presets, factory defaults, JSON restore):
Future<void> setAudioEffects(AudioEffects effects);

// Mutate one or more fields with a copyWith mapper:
Future<void> updateAudioEffects(AudioEffects Function(AudioEffects) f);
```

Each effect carries an `enabled` flag (default off). When on, it joins
the audio chain; when off, it leaves the chain but keeps its parameters
intact for the next toggle.

```dart
// Read the live bundle synchronously
final fx = player.state.audioEffects;
print('compressor on: ${fx.acompressor.enabled} '
      'threshold=${fx.acompressor.threshold}');

// Or via stream - sub-stream a single effect with .map().distinct()
player.stream.audioEffects
  .map((e) => e.acompressor)
  .distinct()
  .listen((c) => print('compressor: $c'));
```

Apply a multi-effect preset atomically (one `af` write):

```dart
await player.setAudioEffects(const AudioEffects(
  acompressor: AcompressorSettings(
    enabled: true, threshold: 0.1, ratio: 4,        // linear ratio threshold
  ),
  loudnorm: LoudnormSettings(enabled: true, I: -16),
  bass: BassSettings(enabled: true, g: 3),          // bass shelf, +3 dB
  treble: TrebleSettings(enabled: true, g: -2),     // treble shelf, -2 dB
  rubberband: RubberbandSettings(
    enabled: true, pitch: 1.0, tempo: 0.95,         // -5% tempo, no pitch shift
  ),
));
```

Toggle a single stage:

```dart
await player.updateAudioEffects((e) => e.copyWith(
  acompressor: e.acompressor.copyWith(enabled: !e.acompressor.enabled),
));
```

Reset everything:

```dart
await player.setAudioEffects(const AudioEffects());
```

> Mixing `setAudioEffects` with raw `setRawProperty('af', ...)` writes
> is not supported - the typed bundle owns the chain, and raw writes
> are rejected. Filters without a typed equivalent go through
> `effects.custom` (a `List<String>` of raw entries emitted at the head
> of the chain, before any typed stage).
>
> ```dart
> // mix typed effects with a raw filter you want to inject
> await player.updateAudioEffects((e) => e.copyWith(
>   custom: ['lavfi-aeval=val(0)|val(1)'],
>   acompressor: const AcompressorSettings(enabled: true, threshold: 0.1),
> ));
> ```

#### 5.2 Common effects - quick examples

Below are some audio effects with representative settings. Every
other effect works the same way: a typed
field on the bundle, configured via `copyWith`.

```dart
// Dynamic-range compressor
await player.updateAudioEffects((e) => e.copyWith(
  acompressor: const AcompressorSettings(
    enabled: true,
    threshold: 0.1,    // 0..1 linear scale
    ratio: 4.0,
    attack: 20.0,      // ms
    release: 250.0,    // ms
  ),
));

// EBU R128 loudness normalisation
await player.updateAudioEffects((e) => e.copyWith(
  loudnorm: const LoudnormSettings(
    enabled: true, I: -16, TP: -1.5, LRA: 11,
  ),
));

// Pitch / tempo shifting (librubberband). Enums for quality presets.
await player.updateAudioEffects((e) => e.copyWith(
  rubberband: const RubberbandSettings(
    enabled: true, pitch: 1.0594, tempo: 1.0,
    pitchq: RubberbandPitch.quality,
  ),
));

// 18-band ISO graphic EQ - bands keyed by their original `1b`..`18b` names.
await player.updateAudioEffects((e) => e.copyWith(
  superequalizer: const SuperequalizerSettings(
    enabled: true,
    params: {'4b': 1.5, '5b': 2.0, '8b': 0.5, '13b': 1.0},
  ),
));

// Bass + treble shelves (two independent shelving effects).
await player.updateAudioEffects((e) => e.copyWith(
  bass: const BassSettings(enabled: true, g: 4, f: 100),
  treble: const TrebleSettings(enabled: true, g: -2, f: 3000),
));
```

Effects with multiple-choice parameters, rubberband's pitch quality,
aemphasis curve, equalizer filter type, expose them as Dart enums for
IDE autocomplete and compile-time safety.

#### 5.3 Available effects

The bundle ships with 86 audio effects covering compression, EQ,
denoising, spatialisation, modulation, and more. Each row below maps to a
`<Name>Settings` field on `AudioEffects` (e.g. `acompressor` →
`AudioEffects.acompressor` of type `AcompressorSettings`). For
filters without a typed wrapper (`pan`, `aeval`, …) use `AudioEffects.custom: List<String>` to push raw
`lavfi-*` strings through the chain.

<details>
<summary><b>Browse the full catalogue</b> (click to expand)</summary>

##### Dynamics and loudness

| Effect | Description |
|---|---|
| `acompressor` | Dynamic-range compressor |
| `acontrast` | Simple dynamic-range compression |
| `adrc` | Spectral dynamic-range controller |
| `adynamicequalizer` | Signal-driven dynamic equalization |
| `adynamicsmooth` | Dynamic smoothing of audio levels |
| `agate` | Noise gate; silences signal below a threshold |
| `alimiter` | Brick-wall limiter; caps the output level |
| `apsyclip` | Psychoacoustic clipper |
| `asoftclip` | Smooth soft-knee clipping |
| `compand` | Compander (compress on input, expand on output) |
| `deesser` | De-essing for sibilance reduction |
| `drmeter` | Dynamic-range meter |
| `dynaudnorm` | Adaptive loudness normalization |
| `ebur128` | EBU R128 loudness scanner |
| `loudnorm` | EBU R128 loudness normalisation |
| `mcompand` | Multiband compander |
| `speechnorm` | Adaptive speech-loudness normaliser |

##### Equalization and tone

| Effect | Description |
|---|---|
| `anequalizer` | High-order parametric multiband equalizer |
| `asubboost` | Subwoofer-frequency boost |
| `atilt` | Spectral tilt across the frequency range |
| `bass` | Low-shelf filter (boost, cut bass) |
| `biquad` | Generic biquad IIR filter |
| `equalizer` | Two-pole peaking EQ band |
| `firequalizer` | FIR equalizer with arbitrary frequency response |
| `highshelf` | High-shelf filter |
| `lowshelf` | Low-shelf filter |
| `superequalizer` | 18-band ISO graphic EQ |
| `tiltshelf` | Tilt shelf (combined low plus high shelf) |
| `treble` | High-shelf filter (boost, cut treble) |

##### Filters

| Effect | Description |
|---|---|
| `allpass` | Two-pole all-pass filter |
| `asubcut` | Subwoofer-frequency cut |
| `asupercut` | High-frequency Butterworth cut |
| `asuperpass` | High-order Butterworth band-pass |
| `asuperstop` | High-order Butterworth band-stop |
| `bandpass` | Two-pole Butterworth band-pass |
| `bandreject` | Two-pole Butterworth band-reject |
| `highpass` | High-pass at a given frequency |
| `lowpass` | Low-pass at a given frequency |

##### Pitch, tempo and time

| Effect | Description |
|---|---|
| `afreqshift` | Shift the spectrum by a fixed offset |
| `aphaseshift` | Shift the phase of every spectral bin |
| `aresample` | Resample to a target sample rate and format |
| `atempo` | Adjust tempo without changing pitch |
| `rubberband` | High-quality independent pitch and tempo |

##### Stereo, channels and spatial

| Effect | Description |
|---|---|
| `channelmap` | Remap input channels to new positions |
| `crossfeed` | Headphone crossfeed |
| `dialoguenhance` | Centre-channel dialogue enhancement |
| `earwax` | Headphone listening enhancement |
| `extrastereo` | Increase the L/R difference signal |
| `haas` | Haas effect (precedence-based stereo widening) |
| `headphone` | HRTF-based binaural headphone rendering |
| `pan` | Mix channels with explicit per-channel gains |
| `stereotools` | Comprehensive stereo image manipulation |
| `stereowiden` | Stereo widening by reducing common signal |
| `surround` | Stereo-to-surround upmix |
| `virtualbass` | Psychoacoustic bass enhancement |

##### Modulation and creative

| Effect | Description |
|---|---|
| `acrusher` | Bit-crusher (resolution and rate reduction) |
| `aecho` | Single-tap echo and multi-tap delay |
| `aemphasis` | RIAA, FM, disc emphasis curves |
| `aexciter` | Harmonic exciter |
| `aphaser` | Phaser |
| `apulsator` | Auto-panner, tremolo hybrid |
| `chorus` | Chorus |
| `crystalizer` | Audio sharpening and brightener |
| `dcshift` | DC offset shift |
| `flanger` | Flanger |
| `hdcd` | HDCD decoder |
| `tremolo` | Sinusoidal amplitude modulation |
| `vibrato` | Sinusoidal pitch modulation |

##### Denoise and restoration

| Effect | Description |
|---|---|
| `adeclick` | Click and impulse-noise removal |
| `adeclip` | Clip-restoration |
| `adecorrelate` | Channel decorrelation |
| `adelay` | Per-channel delay |
| `adenorm` | Add low-level dither to fix denormals |
| `aderivative` | Compute the derivative of the signal |
| `afftdn` | FFT-based broadband noise reduction |
| `afwtdn` | Wavelet-based broadband noise reduction |
| `anlmdn` | Non-local-means denoiser |
| `arnndn` | RNN-based speech denoiser |
| `compensationdelay` | Speaker and microphone delay compensation |

##### Spectral, fade and routing

**Spectral**

| Effect | Description |
|---|---|
| `afftfilt` | Apply expressions in the frequency domain |
| `aiir` | Apply an arbitrary IIR filter |

**Fade, silence and padding**

| Effect | Description |
|---|---|
| `afade` | Fade in and out |
| `apad` | Pad with trailing silence |
| `silenceremove` | Trim leading, trailing, inline silence |

**Routing**

| Effect | Description |
|---|---|
| `aeval` | Per-channel expression-based filter |
| `aformat` | Constrain output format |

</details>

#### 5.4 ReplayGain

```dart
await player.setReplayGain(const ReplayGainSettings(
  mode: ReplayGain.track,     // .no, .track, .album
  preamp: 2.0,                // +2 dB on top of the RG value
  fallback: -6.0,             // -6 dB on files without RG tags
  clip: false,                // false = peak-limit; true = allow clipping
));

// Tweak a single field via copyWith
await player.setReplayGain(
  player.state.replayGain.copyWith(mode: ReplayGain.album),
);
```

#### 5.5 Gapless playback

```dart
await player.setGapless(Gapless.yes);   // Full gapless - re-uses the decoder
await player.setGapless(Gapless.weak);  // Gapless only on compatible formats (default)
await player.setGapless(Gapless.no);    // Close and re-open the AO between tracks
```

For seamless transitions between tracks of any format, combine
`Gapless.yes` with `setPrefetchPlaylist(true)` and observe the
[prefetch lifecycle](#911-prefetch-lifecycle-stream).

```dart
// Pre-open the next playlist entry in the background - first audio
// frame ready before the current track ends.
await player.setPrefetchPlaylist(true);
```
---

### 6. Hardware and routing

#### 6.1 Audio output driver

Select the native backend used for audio output:

```dart
await player.setAudioDriver('wasapi');    // Windows
await player.setAudioDriver('coreaudio'); // macOS
await player.setAudioDriver('pulse');     // Linux
await player.setAudioDriver('alsa');      // Linux
await player.setAudioDriver('pipewire');  // Linux
await player.setAudioDriver('auto');      // Let mpv choose (default)
```

#### 6.2 Exclusive mode

Bypasses the OS audio mixer and writes directly to the hardware. Eliminates software resampling and volume processing for bit-perfect output. Only available on WASAPI (Windows), ALSA (Linux) and CoreAudio (macOS):

```dart
await player.setAudioExclusive(true);   // Request exclusive access
await player.setAudioExclusive(false);  // Release, return to shared mode
```

> Exclusive mode locks the audio device. Always call `player.dispose()` when done, or other apps will have no sound.

#### 6.3 Device selection

```dart
// Listen to available devices
player.stream.audioDevices.listen((devices) {
  for (final d in devices) {
    print('${d.name}: ${d.description}');
  }
});

// Switch to a specific device
final devices = player.state.audioDevices;
await player.setAudioDevice(devices.first);
```

Devices are populated automatically by mpv when the player initializes. The `name` field is the mpv device identifier; `description` is the human-readable label.

#### 6.4 Output format

Force a specific output format for bit-perfect playback or DAC compatibility:

```dart
// Sample rate
await player.setAudioSampleRate(0);       // Auto
await player.setAudioSampleRate(44100);   // 44.1 kHz (CD)
await player.setAudioSampleRate(48000);   // 48 kHz (DVD / broadcast)
await player.setAudioSampleRate(88200);   // 88.2 kHz (hi-res)
await player.setAudioSampleRate(96000);   // 96 kHz (hi-res)
await player.setAudioSampleRate(192000);  // 192 kHz (studio)
await player.setAudioSampleRate(384000);  // 384 kHz (DXD)

// Bit depth format
await player.setAudioFormat(Format.auto);          // mpv picks (default)
await player.setAudioFormat(Format.u8);            // 8-bit unsigned, interleaved
await player.setAudioFormat(Format.u8Planar);      // 8-bit unsigned, planar
await player.setAudioFormat(Format.s16);           // 16-bit signed, interleaved
await player.setAudioFormat(Format.s16Planar);     // 16-bit signed, planar
await player.setAudioFormat(Format.s32);           // 32-bit signed, interleaved
await player.setAudioFormat(Format.s32Planar);     // 32-bit signed, planar
await player.setAudioFormat(Format.float32);       // 32-bit float, interleaved
await player.setAudioFormat(Format.float32Planar); // 32-bit float, planar
await player.setAudioFormat(Format.float64);       // 64-bit float, interleaved
await player.setAudioFormat(Format.float64Planar); // 64-bit float, planar

// Channel layout 
await player.setAudioChannels(Channels.auto);             // mpv picks
await player.setAudioChannels(Channels.autoSafe);         // mpv picks, reject multichannel unless verified

// 1 channel
await player.setAudioChannels(Channels.mono);             // mono
await player.setAudioChannels(Channels.oneZero);          // 1.0 (alias of mono)

// 2 channels
await player.setAudioChannels(Channels.stereo);           // stereo
await player.setAudioChannels(Channels.twoZero);          // 2.0 (alias of stereo)
await player.setAudioChannels(Channels.downmix);          // downmix (semantic alias of stereo)

// ...                                                    // ...

// 8 channels
await player.setAudioChannels(Channels.sevenOne);         // 7.1 canonical
await player.setAudioChannels(Channels.sevenOneAlsa);     // 7.1(alsa)
await player.setAudioChannels(Channels.sevenOneWide);     // 7.1(wide)
await player.setAudioChannels(Channels.sevenOneWideSide); // 7.1(wide-side)
await player.setAudioChannels(Channels.sevenOneTop);      // 7.1(top)
await player.setAudioChannels(Channels.sevenOneRear);     // 7.1(rear)
await player.setAudioChannels(Channels.octagonal);        // octagonal
await player.setAudioChannels(Channels.cube);             // cube

// Cinema, immersive
await player.setAudioChannels(Channels.hexadecagonal);    // hexadecagonal (16ch)
await player.setAudioChannels(Channels.surround222);      // 22.2 (NHK / ITU-R BS.775)

// Custom escape, anything mpv recognises but isn't in the named set
await player.setAudioChannels(
  const Channels.custom('fl-fr-fc-bl-br-sl-sr-lfe'),
);
```

#### 6.5 S/PDIF passthrough

Send compressed audio (AC3, DTS, TrueHD, …) directly to an AV receiver
over S/PDIF or HDMI:

```dart
// Home-theater Dolby + DTS-HD passthrough
await player.setAudioSpdif({Spdif.ac3, Spdif.eac3, Spdif.trueHd, Spdif.dtsHd});

// Dolby only
await player.setAudioSpdif({Spdif.ac3, Spdif.eac3, Spdif.trueHd});

// Disable passthrough
await player.setAudioSpdif({});
```

#### 6.6 Audio client name

The name shown in system audio mixers:

```dart
await player.setAudioClientName('MyMusicApp');
```

#### 6.7 Audio track selection

For containers with multiple audio tracks (e.g. MKV, MP4 with language
variants), the library exposes both the inventory of tracks the
demuxer surfaced and the active track:

```dart
// Walk the audio inventory:
for (final t in player.state.tracks.where((tr) => tr.type == 'audio')) {
  print('${t.id}: ${t.title ?? t.lang ?? "audio"} '
        '(${t.codec} ${t.sampleRate} Hz ${t.channelCount}ch)');
}

// Currently selected track
player.stream.currentAudioTrack.listen((track) {
  if (track == null) return;
  print('Now decoding track #${track.id}: ${track.title}');
});

// Switch by id
await player.setAudioTrack(const Track.id(2));

// Defer to mpv's automatic choice (container default or first audio)
await player.setAudioTrack(Track.auto);

// Disable audio output entirely (e.g. show only metadata + cover art)
await player.setAudioTrack(Track.off);
```

`MpvTrack` ships rich per-track introspection - codec, decoder, sample
rate, channel count, ReplayGain tags, language, default and forced
flags, and `image` and `albumart` flags so you can skip embedded picture
streams when populating a track-switcher UI.

#### 6.8 Reload audio

Force the audio output to reinitialize:

```dart
await player.reloadAudio();
```

---

### 7. Network and caching

#### 7.1 Cache configuration

The five backing mpv cache properties (`cache`, `cache-secs`,
`cache-on-disk`, `cache-pause`, `cache-pause-wait`) are written
atomically through `setCache(CacheSettings)`:

```dart
await player.setCache(const CacheSettings(
  mode: Cache.yes,                 // .auto (default), .yes, .no
  secs: Duration(seconds: 30),         // target cache duration ahead of the playhead
  onDisk: true,                        // spill overflow cache to disk
  pause: true,                         // auto-pause when cache runs dry
  pauseWait: Duration(seconds: 3),     // pre-buffer required before resume
));

// Tweak a single field via copyWith
await player.setCache(
  player.state.cache.copyWith(secs: const Duration(seconds: 60)),
);

// Subscribe to live changes
player.stream.cache.listen((cfg) => print('cache: ${cfg.mode} ${cfg.secs}'));
```

#### 7.2 Demuxer memory pool

The demuxer is the component that reads and parses the media container (MP4, MKV, OGG, etc.) before the audio decoder processes it:

```dart
// Maximum bytes the demuxer is allowed to cache ahead (default: 150 MiB)
await player.setDemuxerMaxBytes(50 * 1024 * 1024); // 50 MiB

// Maximum bytes for the seekback buffer (default: 50 MiB)
await player.setDemuxerMaxBackBytes(20 * 1024 * 1024);

// How many seconds ahead the demuxer should read (default: 1)
await player.setDemuxerReadaheadSecs(5);
```

For radio streams or live content where seeking is not needed, reduce the back buffer to zero to save memory:

```dart
await player.setDemuxerMaxBackBytes(0);
```

#### 7.3 Network timeout

```dart
await player.setNetworkTimeout(const Duration(seconds: 10)); // Fail after 10 seconds of no data
```

#### 7.4 TLS/SSL verification

```dart
await player.setTlsVerify(false); // Disable for self-signed certificates
```

#### 7.5 Audio buffer

The hardware audio buffer - lower values reduce latency, higher values improve stability under load:

```dart
await player.setAudioBuffer(const Duration(milliseconds: 100));  // 100 ms (low latency)
await player.setAudioBuffer(const Duration(milliseconds: 500));  // 500 ms (stable on slow hardware)
```

#### 7.6 Audio stream silence

Keep audio hardware active even when playback is paused, to eliminate click or pop on resume:

```dart
await player.setAudioStreamSilence(true);
```

> Note on iOS: the audio driver in this case is never released, so after an iOS interruption (phone call, other app audio) it stays suspended and playback can't continue.

#### 7.7 Untimed null output

When using the `null` audio driver (e.g. for server-side processing or testing without a sound device), this makes the null output run as fast as possible instead of at real time:

```dart
await player.setAudioNullUntimed(true);
```

#### 7.8 Radio and live streams

For radio, disable caching and cache-pause to minimize latency:

```dart
await player.open(Media('https://stream.radio.example.com/live.mp3'));
await player.setCache(const CacheSettings(mode: Cache.no, pause: false));
await player.setNetworkTimeout(const Duration(seconds: 10));
```

For HLS streams (like Jellyfin transcoding), the default cache settings work well. Mpv handles HLS natively and provides precise seeking even on transcoded streams:

```dart
await player.open(Media(
  'https://jellyfin.example.com/audio/stream.m3u8',
  httpHeaders: {'Authorization': 'MediaBrowser Token="..."'},
));
```

---

### 8. Metadata and cover art

#### 8.1 Metadata tags

```dart
player.stream.metadata.listen((tags) {
  final title = tags['title'];
  final artist = tags['artist'];
  final album = tags['album'];
  final date = tags['date'];
  final trackNumber = tags['track'];
  print('Now playing: $title - $artist');
});

// Synchronous access
final meta = player.state.metadata;
```

Common tag keys (case as returned by mpv): `title`, `artist`, `album`, `album_artist`, `date`, `track`, `disc`, `genre`, `comment`, `composer`.

#### 8.2 Cover art

<img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/diagrams/cover_art_flow.png" width="100%">

Embedded cover art is exposed as **raw codec bytes** plus a few
Flutter conveniences, on a synchronous-state + reactive-stream pair:

```dart
// Synchronous read - peek at the current track's cover
final art = player.state.coverArt;
if (art != null) {
  print('Format: ${art.extension}, ${art.bytes.length} bytes');
}

// Reactive - emits on every file load, null when no cover is embedded
player.stream.coverArt.listen((art) {
  if (art != null) updateUi(art.image);
});
```

The [`CoverArt`] type carries the bytes plus a few helpers:

| Member | Kind | Description |
| :--- | :--- | :--- |
| `bytes` | `final Uint8List` | Raw codec bytes |
| `mimeType` | `final String` | `'image/png'` / `'image/jpeg'` / `'image/webp'` / `'image/bmp'` / `'image/gif'` |
| `image` | getter `ImageProvider` | Ready to drop into Flutter `Image(image: …)` |
| `extension` | getter `String` | `'png'` / `'jpg'` / `'webp'` / `'bmp'` / `'gif'` |
| `isPng` / `isJpeg` / `isWebp` / `isBmp` / `isGif` | getter `bool` | MIME-type predicates |

##### In a Flutter widget

```dart
StreamBuilder<CoverArt?>(
  stream: player.stream.coverArt,
  builder: (ctx, snap) {
    final art = snap.data;
    if (art == null) {
      return const Icon(Icons.music_note, size: 96);
    }
    return Image(
      image: art.image,         // MemoryImage backed by the raw bytes
      fit: BoxFit.cover,
    );
  },
)
```

##### Saving the cover to disk

```dart
final art = player.state.coverArt;
if (art != null) {
  await File('${dir.path}/cover.${art.extension}').writeAsBytes(art.bytes);
}
```

##### Lifecycle

- `stream.coverArt` emits **once per `open()` call** - on file load,
  before playback starts.
- The emitted value is `null` when the file has no embedded picture.
  The stream emits the `null` (rather than skipping the file) so a UI
  bound to it clears the previous cover on every track change.
- `state.coverArt` mirrors the latest stream emit synchronously.
- No re-encoding, no thumbnail generation - the bytes are exactly what
  the demuxer pulled out of the file.

##### External cover files

If you want mpv to *also* look for a `cover.jpg` sitting
next to the audio file on disk:

```dart
await player.setCoverArtAuto(Cover.no);     // library default - disabled
await player.setCoverArtAuto(Cover.exact);  // match the audio filename
await player.setCoverArtAuto(Cover.fuzzy);  // any image in the same folder
await player.setCoverArtAuto(Cover.all);    // any image, even loosely matched
```

The library defaults to `no` (mpv's own default is `exact`) so
unrelated images can't sneak in. Switch to `exact` or `fuzzy` for a
local-file player that wants disk-side artwork.

---

### 9. State and streams

`mpv_audio_kit` exposes all player state in two complementary ways:

- **`player.state`** - a synchronous, immutable snapshot of the current state. Safe to read from anywhere.
- **`player.stream`** - reactive streams that emit on every change. Use with `StreamBuilder` or `.listen()`.

#### 9.1 Core streams

| Stream | Type | Notes |
| :--- | :--- | :--- |
| `playing` | `bool` | `true` when audio is being produced; tracks mpv's `core-idle` (inverted). |
| `completed` | `bool` | `true` once the current track reaches natural EOF. |
| `eofReached` | `bool` | mpv's `eof-reached`; `true` while paused at the end of a file with `keep-open=yes`. |
| `position` | `Duration` | Current playhead, throttled to ~30 Hz. |
| `duration` | `Duration` | Total duration of the current file; `Duration.zero` for live streams. |
| `seekCompleted` | `void` | Fires once per `loadfile` / seek when mpv re-initialises (PLAYBACK_RESTART). Use as the authoritative "file ready" signal. |
| `buffering` | `bool` | `true` between `start-file` and `file-loaded`. |
| `buffer` | `Duration` | Absolute timestamp the demuxer has buffered up to. |
| `bufferDuration` | `Duration` | Headroom ahead of the playhead (`demuxer-cache-duration`). |
| `bufferingPercentage` | `double` (0–100) | Wrapper-computed cache fill against `state.cache.secs`. |
| `volume` | `double` | 0–100; values above 100 amplify. |
| `mute` | `bool` | |
| `rate` | `double` | Playback speed multiplier. |
| `pitch` | `double` | Pitch multiplier. |
| `pitchCorrection` | `bool` | Whether `scaletempo` is engaged. |
| `audioDelay` | `Duration` | Audio offset relative to video (sub-millisecond precision is rounded). |

#### 9.2 Playlist and track streams

| Stream | Type | Setter |
| :--- | :--- | :--- |
| `playlist` | `Playlist` | `open` / `openAll` / `add` / `remove` / `move` / `replace` / `clearPlaylist` |
| `loop` | `Loop` | `setLoop` |
| `shuffle` | `bool` | `setShuffle` |
| `prefetchPlaylist` | `bool` | `setPrefetchPlaylist` |
| `tracks` | `List<MpvTrack>` | _(observed; populated by demuxer)_ |
| `currentAudioTrack` | `MpvTrack?` | `setAudioTrack` |
| `chapters` | `List<Chapter>` | _(observed; populated by demuxer)_ |
| `currentChapter` | `int?` | `setChapter` |

#### 9.3 Audio hardware streams

| Stream | Type | Setter |
| :--- | :--- | :--- |
| `audioDevice` | `Device` | `setAudioDevice` |
| `audioDevices` | `List<Device>` | _(read-only)_ |
| `audioParams` | `AudioParams` | _(decoder; observed)_ |
| `audioOutParams` | `AudioParams` | _(hardware; observed)_ |
| `audioBitrate` | `double?` | _(observed)_ |
| `audioOutputState` | `AudioOutputState` | _(see [§11.4](#114-audio-output-lifecycle))_ |
| `audioDriver` | `String` | `setAudioDriver` |
| `audioExclusive` | `bool` | `setAudioExclusive` |
| `audioBuffer` | `Duration` | `setAudioBuffer` |
| `audioStreamSilence` | `bool` | `setAudioStreamSilence` |
| `audioNullUntimed` | `bool` | `setAudioNullUntimed` |
| `audioSpdif` | `Set<Spdif>` | `setAudioSpdif` |
| `volumeMax` | `double` | `setVolumeMax` |
| `volumeGain` | `double` | `setVolumeGain` |
| `audioSampleRate` | `int` | `setAudioSampleRate` |
| `audioFormat` | `Format` | `setAudioFormat` |
| `audioChannels` | `Channels` | `setAudioChannels` |
| `audioClientName` | `String` | `setAudioClientName` |

`AudioParams` carries: `format`, `sampleRate`, `channels`,
`channelCount`, `hrChannels`, `codec`, `codecName`, `codec` and `codecName`.

#### 9.4 DSP and filter streams

| Stream | Type | Setter |
| :--- | :--- | :--- |
| `audioEffects` | `AudioEffects` | `setAudioEffects` / `updateAudioEffects` |
| `replayGain` | `ReplayGainSettings` | `setReplayGain` |
| `gapless` | `Gapless` | `setGapless` |

#### 9.5 Network and cache streams

| Stream | Type | Setter |
| :--- | :--- | :--- |
| `cache` | `CacheSettings` | `setCache` |
| `networkTimeout` | `Duration` | `setNetworkTimeout` |
| `tlsVerify` | `bool` | `setTlsVerify` |
| `pausedForCache` | `bool` | _(observed; auto-pause signal)_ |
| `demuxerViaNetwork` | `bool` | _(observed)_ |
| `cacheSpeed` | `double` (bytes/s) | _(observed)_ |
| `cacheBufferingState` | `int` (0–100) | _(observed)_ |
| `demuxerMaxBytes` | `int` | `setDemuxerMaxBytes` |
| `demuxerMaxBackBytes` | `int` | `setDemuxerMaxBackBytes` |
| `demuxerReadaheadSecs` | `int` | `setDemuxerReadaheadSecs` |

#### 9.6 File metadata and path streams

| Stream | Type | mpv property |
| :--- | :--- | :--- |
| `metadata` | `Map<String, String>` | `metadata` |
| `mediaTitle` | `String` | `media-title` (falls back to filename when no `title` tag) |
| `fileFormat` | `String` | `file-format` |
| `fileSize` | `int` | `file-size` |
| `path` | `String` | `path` (canonicalised, post-redirect) |
| `filename` | `String` | `filename` (no directory) |
| `streamPath` | `String` | `stream-path` (URI as originally requested) |
| `streamOpenFilename` | `String` | `stream-open-filename` (URI as opened post-redirect) |
| `seekable` | `bool` | `seekable` |
| `partiallySeekable` | `bool` | `partially-seekable` (HLS / DASH window) |
| `demuxerIdle` | `bool` | `demuxer-cache-idle` |

#### 9.7 Playback timing streams

| Stream | Type | Notes |
| :--- | :--- | :--- |
| `audioPts` | `Duration` | mpv's `audio-pts`; per-frame timestamp including AO latency. More granular than [`position`](#91-core-streams). |
| `timeRemaining` | `Duration` | Wall-clock time to EOF, **ignoring** playback rate. |
| `playtimeRemaining` | `Duration` | Time to EOF **adjusted** for playback rate. |

#### 9.8 A-B loop streams

| Stream | Type | Setter |
| :--- | :--- | :--- |
| `abLoopA` | `Duration?` (`null` = disabled) | `setAbLoopA` |
| `abLoopB` | `Duration?` (`null` = disabled) | `setAbLoopB` |
| `abLoopCount` | `int?` (`null` = infinite) | `setAbLoopCount` |
| `remainingAbLoops` | `int?` (`null` when no loop / infinite) | _(observed; counts down)_ |

#### 9.9 Cover art streams

| Stream | Type | Setter |
| :--- | :--- | :--- |
| `coverArt` | `CoverArt?` (one emit per file load) | _(observed; from embedded picture)_ |
| `coverArtAuto` | `Cover` | `setCoverArtAuto` |

#### 9.10 Runtime diagnostics

| Stream | Type | mpv property |
| :--- | :--- | :--- |
| `seeking` | `bool` | `seeking` (UI gate against concurrent seeks) |
| `percentPos` | `double` (0–100) | `percent-pos` |
| `currentDemuxer` | `String` | `current-demuxer` |
| `currentAo` | `String` | `current-ao` |
| `demuxerStartTime` | `Duration` | `demuxer-start-time` (initial timestamp offset) |
| `chapterMetadata` | `Map<String, String>` | `chapter-metadata` (per-chapter tags) |
| `mpvVersion` | `String` | `mpv-version` |
| `ffmpegVersion` | `String` | `ffmpeg-version` |

#### 9.11 Prefetch lifecycle stream

mpv pre-opens the next playlist entry in the background to make the
transition between tracks gapless. The wrapper exposes a typed stream
so you can drive a "Prefetching…" UI, verify gapless, or log
warnings when a prefetch is dropped without parsing log lines.

<img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/diagrams/mpv_prefetch_state.png" width="100%">

```dart
player.stream.prefetchState.listen((state) {
  switch (state) {
    case MpvPrefetchState.idle:
      // No background prefetch in progress.
    case MpvPrefetchState.loading:
      // The opener thread is creating the demuxer for the next item
      // and the secondary cache is filling.
      showIndicator('Prefetching…');
    case MpvPrefetchState.ready:
      // Secondary demuxer is open AND idle (cache-secs reached,
      // no segment fetches outstanding). Gapless is armed.
      showIndicator('Ready');
    case MpvPrefetchState.used:
      // Edge-trigger: the track just transitioned gaplessly.
      // Fires once and then drops back to `idle`.
      showIndicator('Using prefetched');
    case MpvPrefetchState.failed:
      // Edge-trigger: the opener thread failed (network error,
      // unsupported codec, on_load hook abort).
      showIndicator('Prefetch failed');
  }
});
```

| State | When it fires | Notes |
| :--- | :--- | :--- |
| `idle` | Default; after every cancel / drop | Also fires right after `used` and `failed` so they read as one-shot transients |
| `loading` | Opener thread running | Persists until the demuxer is open and the reader goes idle |
| `ready` | Secondary demuxer open + reader idle | Gapless is armed |
| `used` | Track transitioned via the prefetched stream | Edge-triggered; pairs with the subsequent `idle` |
| `failed` | Opener thread error | Edge-triggered; pairs with the subsequent `idle` |

#### 9.12 Aggregate lifecycle

`player.stream.playbackState` collapses the four underlying flags
(`playing` / `buffering` / `completed` / `pausedForCache`) plus
`duration` into a single mutually-exclusive `MpvPlaybackState` enum
- ideal when the UI wants one indicator instead of three.

```dart
player.stream.playbackState.listen((phase) {
  switch (phase) {
    case MpvPlaybackState.idle:       // No file loaded
    case MpvPlaybackState.loading:    // File is opening (demuxer and decoder init)
    case MpvPlaybackState.buffering:  // Mid-playback network stall
    case MpvPlaybackState.playing:    // Producing audio
    case MpvPlaybackState.paused:     // File loaded, audio paused
    case MpvPlaybackState.completed:  // Reached natural EOF
  }
});
```

#### 9.13 Complete state snapshot

`player.state` mirrors every stream above - use it for one-shot reads
inside event handlers and `build()` methods:

```dart
final s = player.state;
print(s.playing);                                // bool
print(s.position);                               // Duration
print(s.duration);                               // Duration
print(s.volume);                                 // double
print(s.buffer);                                 // Duration
print(s.playlist.items[s.playlist.index].uri);   // String
print(s.metadata['title']);                      // String?
print(s.audioParams.codec);                      // String?
print(s.audioEffects.acompressor.threshold);     // double (linear ratio)
print(s.cache.secs);                             // Duration
print(s.replayGain.preamp);                      // double
print(s.tracks.where((t) => t.type == 'audio')); // Iterable<MpvTrack>
print(s.chapters);                               // List<Chapter>
print(s.audioOutputState);                       // AudioOutputState
print(s.mpvVersion);                             // e.g. '0.41.0'
print(s.ffmpegVersion);                          // e.g. '7.1.1'
```

#### 9.14 Spectrum and PCM streams

Two real-time streams expose the audio currently flowing through the
output. See [§13](#13-visualizer-and-spectrum-analyzer) for the full
configuration surface, the math behind the pipeline, and a reference
visualizer.

| Stream                | Type                | What it carries |
|-----------------------|---------------------|-----------------|
| `stream.spectrum`     | `Stream<FftFrame>`  | Smoothed FFT bands plus raw bins, ready for a bar visualizer. |
| `stream.pcm`          | `Stream<PcmFrame>`  | Raw post-DSP samples, ready for a waveform and VU. |

Both streams are lazy (poll loop runs only while subscribed) and
share the same upstream tap, so subscribing to both costs only the
duplicate FFT computation.

```dart
player.stream.spectrum.listen((frame) {
  // 64 bands, each in [0, 1] - paint directly:
  for (var i = 0; i < frame.bands.length; i++) {
    paintBar(i, frame.bands[i]);
  }
});
```

---

### 10. Raw API

For anything not covered by the typed API, you can access mpv directly.

#### 10.1 Read a property

Returns `null` if the property does not exist or the FFI call fails.

```dart
final String? value = await player.getRawProperty('audio-codec');
final String? samplerate = await player.getRawProperty('audio-params/samplerate');
```

#### 10.2 Write a property

Throws `MpvException` if libmpv rejects the write (typo, out-of-range
value, …). Carries `name`, mpv `code`, and the human-readable
`message` from `mpv_error_string`.

```dart
try {
  await player.setRawProperty('audio-samplerate', '96000');
  await player.setRawProperty('audio-channels', 'stereo');
} on MpvException catch (e) {
  print('mpv rejected ${e.name}: ${e.message} (code=${e.code})');
}
```

#### 10.3 Send a command

Same `MpvException` contract on rejection.

```dart
await player.sendRawCommand(['af', 'add', 'lavfi-aresample=48000']);
await player.sendRawCommand(['playlist-shuffle']);
await player.sendRawCommand(['ao-reload']);
```

Any command or property from the
[mpv documentation](https://mpv.io/manual/master/) is accessible
through these methods.

> Prefer the typed setters (`setVolume`, `setCache`,
> `setReplayGain`, …) when they cover your use case - they update
> `state` synchronously instead of waiting for the property observer
> round-trip.

---

### 11. Error handling and logging

#### 11.1 Typed error stream

The error stream emits `MpvPlayerError` - a sealed class with two subtypes that let you distinguish between playback failures and informational engine errors:

<img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/diagrams/error_streams.png" width="100%">

```dart
player.stream.error.listen((error) {
  switch (error) {
    case MpvEndFileError():
      // Playback ended due to an error (e.g. network timeout, file not found).
      print('End-file error: reason=${error.reason}, code=${error.code}');
      print('  isLoadingError: ${error.isLoadingError}');
      print('  isAudioOutputError: ${error.isAudioOutputError}');
      print('  isFormatError: ${error.isFormatError}');
    case MpvLogError():
      // An mpv subsystem logged at error or fatal level (e.g. codec issue).
      // Does NOT necessarily mean playback has stopped.
      print('Log error [${error.prefix}] ${error.level}: ${error.message}');
  }
});
```

`MpvEndFileError` - emitted when `MPV_EVENT_END_FILE` fires with a non-zero error code:
- `reason` - a `MpvEndFileReason` enum (`eof`, `stop`, `quit`, `error`, `redirect`)
- `code` - the raw mpv error code (e.g. `-13` for `MPV_ERROR_LOADING_FAILED`)
- `isLoadingError` - `true` for network or file loading failures
- `isAudioOutputError` - `true` when the audio output driver failed to initialize
- `isFormatError` - `true` when the file format is unrecognizable or has no audio

`MpvLogError` - emitted when mpv logs at `error` or `fatal` level:
- `prefix` - the mpv subsystem (e.g. `'ffmpeg'`, `'ao'`, `'demux'`)
- `level` - `'error'` or `'fatal'`
- `text` - the raw log line from the mpv subsystem

> Network note: per the mpv documentation, a network disconnection mid-stream
> may report as `MpvEndFileReason.eof` rather than `MpvEndFileReason.error`.
> Use `player.stream.endFile` and compare position vs duration for reliable detection (see §11.2).

#### 11.2 End file stream

`player.stream.endFile` emits an `MpvFileEndedEvent` for **every** file-end - not just errors. This is the only way to detect premature EOFs caused by network disconnections, which mpv reports as `reason: eof` with no error code:

```dart
player.stream.endFile.listen((event) {
  if (event.reason == MpvEndFileReason.eof) {
    final pos = player.state.position;
    final dur = player.state.duration;
    if (dur > Duration.zero && (dur - pos).inSeconds > 5) {
      print('Premature EOF - likely a network drop');
    }
  }
});
```

`MpvFileEndedEvent` fields:
- `reason` - a `MpvEndFileReason` enum value
- `error` - the raw mpv error code (non-zero only when `reason == MpvEndFileReason.error`)

#### 11.3 Network state

Two dedicated streams for monitoring network conditions:

```dart
// True when playback is paused because the cache ran empty (network stall).
// This is the authoritative signal - prefer it over interpreting error events.
player.stream.pausedForCache.listen((paused) {
  if (paused) showBufferingIndicator();
});

// True when the current stream is being read via a network protocol.
// Useful for deciding whether an error is likely network-related.
player.stream.demuxerViaNetwork.listen((isNetwork) {
  print('Network stream: $isNetwork');
});
```

Both are also available synchronously via `player.state.pausedForCache` and `player.state.demuxerViaNetwork`.

#### 11.4 Audio output lifecycle

mpv exposes the audio output's lifecycle as a typed stream - read it
to drive a "Connecting…" UI on slow backends, or to detect a silent
player without polling format params.

```dart
player.stream.audioOutputState.listen((state) {
  switch (state) {
    case AudioOutputState.closed:        // No AO active
    case AudioOutputState.initializing:  // ao_init_best in flight
    case AudioOutputState.active:        // AO open, producing samples
    case AudioOutputState.failed:        // ao_init_best returned NULL
  }
});
```

The library also surfaces a typed `MpvLogError` on `stream.error` the
moment the AO transitions to `failed`, so you don't need a separate
listener for the "no sound" case.

#### 11.5 Log streams

Two streams keep engine and library messages disjoint - route them to
different sinks (e.g. show only `log` in a debug overlay while
forwarding `internalLog` to crash reporting).

```dart
// mpv engine messages: ffmpeg, demux, ao, cplayer, …
player.stream.log.listen((entry) {
  // MpvLogEntry has: prefix (String), level (LogLevel), text (String)
  if (entry.level == LogLevel.error || entry.level == LogLevel.fatal) {
    print('[${entry.level.mpvValue}] ${entry.prefix}: ${entry.text}');
  }
});

// library-side diagnostics: JSON parse warnings, hook timeouts,
// resolution errors. Always carries prefix: 'mpv_audio_kit'.
player.stream.internalLog.listen((entry) {
  print('[wrapper:${entry.level.mpvValue}] ${entry.text}');
});
```

Set `logLevel` in `PlayerConfiguration` to control engine-side
verbosity. `LogLevel.warn` is appropriate for production;
`LogLevel.debug` or `LogLevel.v` for development; `LogLevel.off`
to disable engine-side logging entirely.

---

### 12. Hooks

Hooks intercept mpv's file-loading pipeline before a stream is opened. Use them to lazily resolve URLs, inject per-file HTTP headers, or redirect to a different source without a local proxy server:

<img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/diagrams/on_load_hook_sequence.png" width="100%">

#### 12.1 Registering a hook

Call `registerHook` **once** after creating the player (before any `open` call).

```dart
player.registerHook(Hook.load);
```

You can add a safety timeout - if `continueHook` isn't called within the given duration, the library auto-continues to prevent mpv from stalling indefinitely (e.g. due to an unhandled exception):

```dart
player.registerHook(Hook.load, timeout: const Duration(seconds: 10));
```

The full set of mpv lifecycle hooks:

| Hook | When it fires |
| :--- | :--- |
| `Hook.beforeStartFile` | Before any per-file work begins (drains stale property changes) |
| `Hook.load` | Before a stream is opened - redirect the URL or attach per-file headers |
| `Hook.loadFail` | After a stream failed to open - useful for fallback URLs |
| `Hook.preloaded` | File open, demuxer ready, before track selection / decoder init |
| `Hook.unload` | Before a file is closed - cleanup hook tied to the current file |
| `Hook.afterEndFile` | After a file finished and was fully unloaded |

> Hooks fire during prefetch too. When mpv pre-opens the next playlist entry to enable gapless transitions, `on_load` is invoked for that track too - so custom URL schemes (e.g. `plex-transcode://` → resolved HLS URL) are resolved for every track, including the one being prefetched in the background. Your listener is called once per track regardless of whether playback is active or prefetching, and `setRawProperty('stream-open-filename', …)` accepts hook-driven rewrites in either context.

#### 12.2 Listening and continuing

Subscribe to `player.stream.hook` and call `continueHook` when processing is done. You must always call `continueHook`, even on error - otherwise mpv stalls indefinitely:

```dart
player.stream.hook.listen((event) async {
  if (event.hook == Hook.load) {
    final url = await player.getRawProperty('stream-open-filename') ?? '';

    try {
      if (url.startsWith('my-scheme://')) {
        // Redirect to a real URL
        final resolved = await myResolver(url);
        await player.setRawProperty('stream-open-filename', resolved.url);

        // Inject per-file HTTP headers (direct HTTP only - for HLS use URL query params)
        if (resolved.headers.isNotEmpty) {
          final headerString = resolved.headers.entries
              .map((e) => '${e.key}: ${e.value}')
              .join(',');
          await player.setRawProperty(
            'file-local-options/http-header-fields',
            headerString,
          );
        }
      }
    } finally {
      player.continueHook(event.id); // always call
    }
  } else {
    player.continueHook(event.id);
  }
});
```

#### 12.3 HTTP headers via hook

`file-local-options/http-header-fields` sets headers only for the current file. They are applied at the mpv/libmpv layer and work correctly for direct HTTP streams.

Important - HLS streams: when mpv opens an HLS playlist, the actual segment downloads are handled directly by ffmpeg's lavf, which does not inherit `http-header-fields` set via the hook. If your server requires authentication on the HLS segments, embed the credentials in the URL as query parameters instead:

```dart
// ✅ Correct for HLS - auth in the URL, visible to ffmpeg's lavf
player.setRawProperty(
  'stream-open-filename',
  'https://server/stream/playlist.m3u8?token=abc123',
);

// ⚠️ Works for direct HTTP streams only - ignored by ffmpeg's lavf for HLS sub-requests
player.setRawProperty('file-local-options/http-header-fields', 'Authorization: Bearer abc123');
```

#### 12.4 Lazy URL resolution

When building a playlist with `Future.wait`, all `getStreamUrl` calls run in parallel. If your server rejects concurrent session creation (as Plex does for transcoding), store the session parameters and return a placeholder URL (e.g. `my-scheme://session-id`). The `on_load` hook fires **sequentially** as mpv opens each track, so resolution calls never overlap:

```dart
// Building the queue - no real API calls yet
final medias = await Future.wait(tracks.map((t) async {
  final url = await service.getStreamUrl(t.id); // returns "my-scheme://abc"
  return Media(url);
}));
await player.openAll(medias);

// When mpv reaches each track, the hook resolves it on demand:
// on_load → myResolver("my-scheme://abc") → /decision + start.m3u8 URL
```

---

### 13. Visualizer and spectrum analyzer

A real-time FFT spectrum and a raw PCM stream are exposed straight
off the audio output, captured *post-DSP* (after volume, EQ,
compressor - what you actually hear). Drive a `CustomPainter`
visualizer with `bands`, build a VU meter with `samples`, or run any
custom feature extraction on top:

<img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/diagrams/spectrum_pipeline.png" width="100%">

The pipeline is lazy: the FFT runs only while
`Player.stream.spectrum` (or `Player.stream.pcm`) has at least one
listener. On the last cancel the timer stops and the FFT memory is
freed.

#### 13.1 Subscribing to the spectrum stream

`Player.stream.spectrum` emits an [FftFrame] on a fixed interval
(default 30 fps). Each frame carries:

| Field         | Type                | What it is |
|---------------|---------------------|------------|
| `bins`        | `Float32List`       | Raw FFT magnitude per linear-frequency bin, normalised `[0, 1]`. Length = `fftSize / 2`. |
| `bands`       | `Float32List`       | Smoothed log-spaced perceptual bands ready for a bar visualizer. Length = `bandCount`. |
| `timestamp`   | `Duration`          | Playback position the samples correspond to. |
| `sampleRate`  | `int`               | Hz of the AO output. |
| `bandLowHz`   | `double`            | Lower edge of the band axis. |
| `bandHighHz`  | `double`            | Upper edge of the band axis (clamped to Nyquist). |

```dart
player.stream.spectrum.listen((frame) {
  // 64 bands ready to paint:
  for (var i = 0; i < frame.bands.length; i++) {
    final h = frame.bands[i] * canvasHeight;
    // draw bar i with height h …
  }
});
```

Use `bands` for visualizers, the band-level asymmetric EMA (fast
attack, slow release) makes painting them directly produce the
"bouncy" feel without any client-side animation logic. Use `bins`
for custom remappings (mel, Bark, constant-Q, peak detection).

#### 13.2 Configuring the pipeline

Tune the FFT and the visual smoothing through `SpectrumSettings` -
applied atomically via `Player.setSpectrum`, or mutated incrementally
with `Player.updateSpectrum` (copyWith mapper).

```dart
// 60 fps with 128 bands and a tighter dB window:
await player.setSpectrum(const SpectrumSettings(
  fftSize: 2048,
  bandCount: 128,
  emitInterval: Duration(milliseconds: 16),
  minDb: -65,
  maxDb: -5,
));

// Mutate one field - e.g. UI slider on attack smoothing:
await player.updateSpectrum((s) => s.copyWith(attackSmoothing: 0.7));
```

| Field             | Default        | Range / Choice |
|-------------------|----------------|----------------|
| `fftSize`         | 2048           | Power of 2: 256 / 512 / 1024 / 2048 / 4096 |
| `bandCount`       | 64             | Typical 32–128 |
| `bandLowHz`       | 20.0           | Bottom of human hearing |
| `bandHighHz`      | 20000.0        | Clamped to Nyquist (`sampleRate / 2`) |
| `window`          | `WindowFunction.hann` | Hann / Blackman-Harris / Rectangular |
| `emitInterval`    | 33 ms (~30 fps)| 8–67 ms (~120–15 fps) |
| `attackSmoothing` | 0.5            | EMA when band rises - higher = snappier |
| `releaseSmoothing`| 0.1            | EMA when band falls - lower = slower decay |
| `minDb`, `maxDb`  | -70, -10       | dB clip range mapped to `[0, 1]` |

The pipeline reallocates FFT memory only on changes that require it,
so flipping settings on every UI tick is cheap.

Pause behaviour. When playback pauses, the AO ring stops
receiving samples and the pipeline stops emitting. The last
[FftFrame] is "frozen" - the consumer holds the displayed state
until playback resumes. To fade the visualizer to zero on pause,
animate the held frame client-side.

#### 13.3 Raw PCM stream

`Player.stream.pcm` emits [PcmFrame]s on the same cadence as
`spectrum`, carrying the raw post-DSP samples instead of the
frequency-domain transform. Use it for time-domain visualisations:
oscilloscope-style waveforms, accurate VU/peak meters, custom feature
extractors that need amplitude.

```dart
double peak = 0;
player.stream.pcm.listen((frame) {
  for (final s in frame.samples) {
    if (s.abs() > peak) peak = s.abs();
  }
  peak *= 0.92; // decay
  vuController.value = peak;
});
```

`samples` is a `Float32List` of interleaved channels (`L, R, L, R…`).
Use `frame.samplesPerChannel` to compute the per-channel sample
count.

---

## Migration

0.1.0 is a major breaking release. The Dart-side surface was rewritten
from scratch: every setter takes a typed argument, every multi-field
configuration lives in an atomic immutable bundle, and the escape hatches
now propagate mpv errors instead of swallowing them. This section is a
side-by-side cross-walk against 0.0.9.

### Renames at a glance

#### Setters & methods

| 0.0.9 | 0.1.0 |
| :--- | :--- |
| `Player.openPlaylist(...)` | `Player.openAll(...)` |
| `Player.setGaplessPlayback('weak')` | `Player.setGapless(Gapless.weak)` |
| `Player.setReplayGain('track')` + `setReplayGainPreamp` / `setReplayGainFallback` / `setReplayGainClip` | `Player.setReplayGain(ReplayGainSettings(mode: ReplayGain.track, ...))` |
| `Player.setCacheSecs` / `setCachePause` / `setCachePauseWait` / `setCacheOnDisk` (plus mpv's `cache` mode toggle) | `Player.setCache(CacheSettings(...))` |
| `Player.setAudioTrack('1')` | `Player.setAudioTrack(Track.id(1))` |
| `Player.setAudioFormat('s16')` | `Player.setAudioFormat(Format.s16)` |
| `Player.setAudioChannels('stereo')` | `Player.setAudioChannels(Channels.stereo)` |
| `Player.setAudioSpdif('ac3,dts')` | `Player.setAudioSpdif({Spdif.ac3, Spdif.dts})` |
| `Player.setCoverArtAuto('exact')` | `Player.setCoverArtAuto(Cover.exact)` |
| `Player.setAudioFilters([AudioFilter.equalizer(...), ...])` | `Player.setAudioEffects(AudioEffects(superequalizer: ..., ...))` / `updateAudioEffects((e) => ...)` |
| `Player.clearAudioFilters()` / `addAudioFilter(...)` | `setAudioEffects(const AudioEffects())` / `updateAudioEffects((e) => e.copyWith(...))` |
| `Player.setEqualizerGains([...])` (10-band ISO) | `updateAudioEffects((e) => e.copyWith(superequalizer: SuperequalizerSettings(enabled: true, params: {...})))` (18 bands keyed `'1b'..'18b'`) |
| `Player.registerHook('on_load')` | `Player.registerHook(Hook.load)` |
| `event.name == 'on_load'` (on `MpvHookEvent`) | `event.hook == Hook.load` |
| `Player.registerHook(...)` returned `void` | now returns `Future<void>` (symmetric with every other setter) |
| `Player.continueHook(id)` returned `void` | now returns `Future<void>` |
| `Player.setLoop(Loop mode)` (param named `mode`) | `Player.setLoop(Loop loop)` (param uses the type's domain noun - same for `setGapless(Gapless gapless)`, `setAudioTrack(Track track)`, `setCoverArtAuto(Cover cover)`) |
| `Player.setReplayGain(ReplayGainSettings config)` (param named `config`) | `Player.setReplayGain(ReplayGainSettings settings)` - same rename on `setCache(... settings)`. `setAudioEffects(AudioEffects effects)` keeps `effects` because the type does not carry a `Settings` suffix. |
| `Player.setVolumeMax(double max)` | `Player.setVolumeMax(double limit)` (`max` shadowed `dart:math.max`) |
| `MpvPrefetchState.parse(rawString)` | `MpvPrefetchState.fromMpv(rawString)` (every mpv-mirror enum exposes the same `fromMpv` + `mpvValue` pair) |
| `Hook.mpvName` | `Hook.mpvValue` (renamed for symmetry with other enums) |
| `Playlist.medias` | `Playlist.items` (and `Playlist(medias)` is now `Playlist(items)`) |
| `Device('hw:0', 'Built-in')` (positional) | `Device(name: 'hw:0', description: 'Built-in')` (named) |
| `Device.auto()` (factory) | `Device.auto` (static const) |

#### State fields & types

| 0.0.9 | 0.1.0 |
| :--- | :--- |
| `state.gaplessMode: String` | `state.gapless: Gapless` |
| `state.replayGainMode: String` + `replayGainPreamp` + `replayGainFallback` + `replayGainClip` | `state.replayGain: ReplayGainSettings` |
| `state.cacheMode: String` + `cacheSecs` + `cachePause` + `cachePauseWait` + `cacheOnDisk` | `state.cache: CacheSettings` |
| `state.audioFormat: String` | `state.audioFormat: Format` |
| `state.audioChannels: String` | `state.audioChannels: Channels` |
| `state.audioSpdif: String` | `state.audioSpdif: Set<Spdif>` |
| `state.audioTrack: String` (just the active ID) | `state.currentAudioTrack: MpvTrack?` (full track metadata) |
| `state.coverArtAuto: String` | `state.coverArtAuto: Cover` |
| `state.playlistMode: PlaylistMode` | `state.loop: Loop` |
| `state.activeFilters: List<AudioFilter>` + `state.equalizerGains: List<double>` | `state.audioEffects: AudioEffects` (one typed `*Settings` per audio effect, plus a raw `custom: List<String>` slot for filters without a typed shape) |
| `state.audioDisplay: String` + `state.imageDisplayDuration: String` | _Removed_ - these controlled mpv's video-output stages, which the audio-only build no longer ships. Cover-art bytes are surfaced via `state.coverArt: CoverArt?` and `stream.coverArt: Stream<CoverArt?>` instead |
| `state.audioParams.format: String?` / `audioOutParams.format: String?` | `AudioParams.format: Format?` (typed, symmetric with the setter side) |
| `state.audioParams.channels: String?` / `audioOutParams.channels: String?` | `AudioParams.channels: Channels?` (typed) |
| `MpvLogEntry.level: String` | `MpvLogEntry.level: LogLevel` (typed enum - `LogLevel.error`, `.warn`, `.info`, `.v`, `.debug`, `.trace`, `.fatal`, `.off`) |
| `MpvLogError.level: String` | `MpvLogError.level: LogLevel` |
| `PlayerConfiguration.logLevel: String` (`'warn'`, `'no'`, …) | `PlayerConfiguration.logLevel: LogLevel` (e.g. `LogLevel.warn`, `LogLevel.off`) |
| `Media.extras: Map<String, dynamic>?` | `Media.extras: Map<String, Object?>?` (typesafe at call sites; `extras['key'] as String?` still works) |
| `MpvTrack.samplerate` / `albumart` / `replaygainTrackGain` / `replaygainTrackPeak` / `replaygainAlbumGain` / `replaygainAlbumPeak` | `MpvTrack.sampleRate` / `albumArt` / `replayGainTrackGain` / `replayGainTrackPeak` / `replayGainAlbumGain` / `replayGainAlbumPeak` (camelCase normalisation, aligns with `state.replayGain`) |

#### Type renames

| 0.0.9 | 0.1.0 |
| :--- | :--- |
| `AudioDevice` | `Device` (drop the `Audio` prefix on the type; setter and state-field names keep it: `setAudioDevice(Device)`, `state.audioDevice`) |
| `PlaylistMode` | `Loop` (better matches what it controls - track / playlist looping) |
| `AudioFilter` (sealed list of named factories) | _Replaced_ by `AudioEffects` - a single immutable bundle with one typed `*Settings` field per audio effect. Filters without a typed shape (`pan`, `aeval`, …) go through `AudioEffects.custom: List<String>` |

### Newly typed surfaces

These were free-form `String` fields or absent entirely in 0.0.9, and are
now typed in 0.1.0. There is no rename - the column on the right shows
the new shape.

| Concept | 0.1.0 type |
| :--- | :--- |
| Gapless mode | `Gapless` enum |
| Cache mode | `Cache` enum |
| ReplayGain mode | `ReplayGain` enum |
| Cover-art auto policy | `Cover` enum |
| Audio format | `Format` enum |
| Audio channels | `Channels` (sealed; payload-bearing variants like `Channels.custom('5.1')`) |
| Audio track selection (setter arg) | `Track` (sealed; payload-bearing variants like `Track.id(2)`) |
| S/PDIF passthrough codecs | `Set<Spdif>` |
| FFT window | `WindowFunction` enum |
| Lifecycle hooks | `Hook` enum |
| Aggregate playback lifecycle | `MpvPlaybackState` enum (new - no 0.0.9 equivalent) |
| Embedded cover-art bytes | `CoverArt` data class via `state.coverArt` / `stream.coverArt` (new - 0.0.9 mutated `Media.extras['artBytes']` instead) |
| Track inventory | `MpvTrack` data class via `state.tracks` / `state.currentAudioTrack` |

### Async escape hatches

```dart
// 0.0.9 - synchronous; getRawProperty returned String?, setters were void
final v = player.getRawProperty('audio-codec');
player.setRawProperty('audio-samplerate', '96000');
player.sendRawCommand(['ao-reload']);

// 0.1.0 - all three are Future<...>. getRawProperty still returns null
// on failure, but setRawProperty / sendRawCommand throw MpvException
// on mpv-side errors instead of silently no-oping.
final v = await player.getRawProperty('audio-codec');
await player.setRawProperty('audio-samplerate', '96000');
await player.sendRawCommand(['ao-reload']);
```

`setRawProperty('af', ...)` AND `sendRawCommand(['af', ...])` /
`sendRawCommand(['af-command', ...])` are now symmetrically rejected
with `ArgumentError`: the `AudioEffects` bundle is the single writer of
the `af` chain. Pass experimental or expression-based filters via
[`AudioEffects.custom`](#dsp-effects).

### Typed setters now surface mpv errors

Every typed setter (`setVolume`, `setRate`, `setAudioEffects`, `setCache`,
`setVolumeMax`, …) used to drop the rc from `mpv_set_property_string`
silently - the optimistic state desynced from libmpv with no signal to
the caller. In 0.1.0 they all throw `MpvException` on rejection, so
out-of-range writes (e.g. `setVolumeMax(50)` - mpv requires ≥100) and
malformed `af` chains surface immediately. The optimistic state stays
at the last good value when an exception fires.

```dart
try {
  await player.setVolumeMax(50); // mpv rejects values < 100
} on MpvException catch (e) {
  // e.name == 'volume-max', e.code < 0
}
```

Numeric setters (`setVolume`, `setRate`, `setPitch`, `setVolumeGain`,
`setVolumeMax`) also reject `NaN` / `±Infinity` at the wrapper boundary
with `ArgumentError` instead of forwarding the literal `"NaN"` /
`"Infinity"` to mpv.

### DSP effects

```dart
// 0.0.9 - list of named AudioFilter factories;
// mpv `--af` rewritten on every setAudioFilters call.
await player.setAudioFilters([
  AudioFilter.equalizer([0, 0, 2, 4, 2, 0, -2, -4, -4, 0]),
  AudioFilter.loudnorm(),
  AudioFilter.compressor(threshold: -18, ratio: 3),
]);

// 0.1.0 - every audio effect is a typed Settings on a single
// AudioEffects bundle. One atomic write applies the whole rack.
await player.setAudioEffects(const AudioEffects(
  // 18-band ISO graphic EQ - band gains keyed by `1b`..`18b`
  // (the old 10-band preset roughly maps to bands 4..13).
  superequalizer: SuperequalizerSettings(
    enabled: true,
    params: {'4b': 1.5, '5b': 2.0, '8b': 0.5, '13b': 1.0},
  ),
  loudnorm: LoudnormSettings(enabled: true),
  // ffmpeg-native acompressor: threshold is a 0..1 linear ratio.
  acompressor: AcompressorSettings(
    enabled: true, threshold: 0.1, ratio: 3,
  ),
));

// Single-effect update - copyWith mapper
await player.updateAudioEffects((e) => e.copyWith(
  acompressor: e.acompressor.copyWith(enabled: !e.acompressor.enabled),
));
```

Every audio effect - `aphaser`, `aecho`, `flanger`, `crystalizer`,
`vibrato`, `firequalizer`, and dozens more - has a typed Settings on
the bundle. Filters without a typed shape (expression-based ones like
`pan` or `aeval`) go through `AudioEffects.custom`.

> **Whitelist tightened in 0.1.0.** The bundled lavfi build now ships
> 86 filters (was 114). 28 entries that were debug-only
> (`abench`, `astats`, `aspectralstats`, `silencedetect`,
> `volumedetect`, `ashowinfo`, `alatency`), pure timeline / utility
> manipulation (`acopy`, `acue`, `aintegral`, `aloop`, `ametadata`,
> `anull`, `aperms`, `arealtime`, `areverse`, `asegment`, `aselect`,
> `asendcmd`, `asetnsamples`, `asetpts`, `asetrate`, `asettb`,
> `asidedata`, `astreamselect`, `atrim`), or a naming clash with the
> typed API (`replaygain` lavfi vs `ReplayGainSettings`; `volume`
> lavfi vs `setVolume`) were dropped. If you need any of them, the
> `AudioEffects.custom: List<String>` slot still routes the raw
> string through the chain:
>
> ```dart
> await player.setAudioEffects(
>   AudioEffects(custom: ['lavfi-atrim=start=0:end=10']),
> );
> ```

### Time-based setters now take `Duration`

| 0.0.9 (seconds, double) | 0.1.0 (`Duration`) |
| :--- | :--- |
| `setAudioDelay(0.05)` | `setAudioDelay(const Duration(milliseconds: 50))` |
| `setNetworkTimeout(60)` | `setNetworkTimeout(const Duration(seconds: 60))` |
| `setAudioBuffer(0.2)` | `setAudioBuffer(const Duration(milliseconds: 200))` |

### Cover art

```dart
// 0.0.9 - cover bytes were side-mutated into Media.extras at file load
final art = playlist.medias[playlist.index].extras?['artBytes'] as Uint8List?;

// 0.1.0 - Media is immutable; cover bytes flow through a dedicated
// stream-and-state pair, with Flutter conveniences on the model.
player.stream.coverArt.listen((art) {
  if (art != null) imageController.update(art.image);
});

// Or peek synchronously
final art = player.state.coverArt;
if (art != null) {
  Image(image: art.image, fit: BoxFit.cover);
  await File('cover.${art.extension}').writeAsBytes(art.bytes);
}
```

### Removed methods

These existed in 0.0.9 and have no replacement in 0.1.0:

- `Player.playOrPause()` - use `state.playing ? player.pause() : player.play()`.
- `Player.log(...)` - the runtime no longer surfaces a writeable log stream; subscribe to `Player.stream.log` for mpv-side log entries instead.
- `Player.setAudioDisplay(...)` / `Player.setImageDisplayDuration(...)` - controlled mpv's video-output policy; the audio-only build no longer ships those stages.

### `PlayerConfiguration` slimmed

`audioClientName` is no longer a constructor parameter - set it
post-construction via `Player.setAudioClientName(...)`. `autoPlay`
and `initialVolume` are unchanged. `logLevel` is now typed:

```dart
// 0.0.9
PlayerConfiguration(logLevel: 'warn');

// 0.1.0
PlayerConfiguration(logLevel: LogLevel.warn); // or LogLevel.off
```

### What you gain in addition

- Track inventory (`state.tracks`, `state.currentAudioTrack`).
- A-B loop (`setAbLoopA` / `setAbLoopB` / `setAbLoopCount`).
- Chapter navigation (`state.chapters`, `state.currentChapter`, `setChapter`).
- `MpvPlaybackState` aggregate stream.
- `MpvException` for raw-API failures.
- `PlayerApi` interface for `Mock implements PlayerApi` test doubles.
- Path / URI introspection (`state.path`, `filename`, `streamPath`, `streamOpenFilename`).
- Tier-2 introspection (`seeking`, `percentPos`, `cacheSpeed`, `cacheBufferingState`, `currentDemuxer`, `currentAo`, `demuxerStartTime`, `chapterMetadata`, `mpvVersion`, `ffmpegVersion`).

---

## Permissions

### Android

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
```

### iOS

Enable `Audio, AirPlay, and Picture in Picture` in Signing & Capabilities.

Add to `Info.plist`:

```xml
<key>UIBackgroundModes</key>
<array>
  <string>audio</string>
</array>
```

### macOS

Add to `DebugProfile.entitlements` and `Release.entitlements`:

```xml
<key>com.apple.security.network.client</key>
<true/>
```

---

## Troubleshooting

#### Building and testing on containers (WSL, Docker, or Distrobox)
If you are developing or testing your Flutter app inside a headless Linux container, you will need to install both the core Flutter desktop build tools and the native audio server runtimes. Standard Linux desktops (like Ubuntu or Fedora) already have the audio backends pre-installed, but minimal containers require them to route sound to your host machine:

```bash
sudo apt update

# 1. Flutter desktop build essentials:
sudo apt install clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev

# 2. Audio backend runtimes & host routing (required to hear sound inside containers):
sudo apt install pipewire pipewire-pulse libasound2-dev libpulse-dev libpipewire-0.3-dev
```

> Note on ALSA: be aware that low-level hardware drivers like ALSA don't work inside containers. Use the PulseAudio or PipeWire backend for container testing.
> 
> Note on WSL: PipeWire and ALSA do not work on Windows Subsystem for Linux. You must use the PulseAudio backend to hear sound during development.
---

## Project background

All the native bindings, isolate logic, and architectural patterns were implemented through the use of Claude Code.

---

*Developed by Alessandro Di Ronza*
