# mpv_audio_kit

#### Audio engine for Flutter & Dart.

[![](https://img.shields.io/pub/v/mpv_audio_kit.svg)](https://pub.dev/packages/mpv_audio_kit)
[![](https://img.shields.io/badge/libmpv-v0.41.0-orange.svg)]()
[![](https://img.shields.io/badge/license-BSD--3--Clause-blue.svg)](LICENSE)
[![](https://img.shields.io/github/stars/ales-drnz/mpv_audio_kit?style=flat&logo=github)](https://github.com/ales-drnz/mpv_audio_kit)
[![](https://img.shields.io/discord/1485588004029333516?logo=discord&logoColor=white)](https://discord.gg/g2Qf4Mq9MP)

<img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/mpv_audio_kit.png" width="70" align="left" style="margin-right: 15px;" alt="logo" />`mpv_audio_kit` is an audio library built on `libmpv` v0.41.0, the engine behind the mpv media player. It provides a dedicated background event loop, a complete DSP pipeline, and direct access to every property, making it the most capable audio library available for Flutter.
<br clear="left"/>

---

## Why did I build this?

Many existing Flutter audio libraries are either built on an old version of mpv or they are simply too restrictive, hiding some cool features relative to audio processing. So I made this project to provide a more powerful and flexible audio library for Flutter and solve three main needs:

- **🪼 Jellyfin**: For audio streaming, supporting `.m3u8` (HLS) is essential. Jellyfin uses HLS for transcoding, this ensures that seeking works flawlessly during transcoded tracks.
- **🟡 Plex**: Transcoding in this case requires a `/decision` call before each stream. The `on_load` hook resolves `.m3u8` URL lazily.
- **⚙️ Total control for technical users**: This library doesn't limit features; it exposes the native engine so technical users can tune buffers, network timeouts, DSP filters and play with ffmpeg exactly how they want.

---

## Installation

Add `mpv_audio_kit` to your `pubspec.yaml`:

```yaml
dependencies:
  mpv_audio_kit: ^0.1.0
```

### ⚠️ 0.1.0 is a major breaking release

The Dart API has been rewritten from scratch: typed enums everywhere,
atomic config aggregates (`CacheSettings`, `ReplayGainSettings`), a
redesigned DSP pipeline (`EqualizerSettings`, `CompressorSettings`,
`LoudnessSettings`, `PitchTempoSettings`), and the escape hatches are
now async. Jump to the [Migration guide](#migration) for a side-by-side
cross-walk from 0.0.9, or read the full breaking-change list in the
[CHANGELOG](CHANGELOG.md#migration-from-009).

### Platform Requirements

*   **Android**: SDK 24 (Android 7.0) or above.
*   **iOS**: iOS 13.0 or above.
*   **macOS**: 10.14 or above (Apple Silicon).
*   **Windows**: Windows 10 or above.
*   **Linux**: Ubuntu 24.04 or above.

---

## Platforms

| Platform  | Architecture | Device | Emulator | mpv version |
| :--- | :--- | :---: | :---: | :---: |
| **Android** | arm64-v8a, x86_64 | ✅ | ✅ | v0.41.0 |
| **iOS** | arm64, x86_64 | ✅ | ✅ | v0.41.0 |
| **macOS** | arm64 | ✅ | — | v0.41.0 |
| **Windows**| x86_64 | ✅ | — | v0.41.0 |
| **Linux** | x86_64 | ✅ | — | v0.41.0 |

---

## Reference

*   [Visuals](#visuals)
*   [Features](#features)
*   [Quick Start](#quick-start)
*   [Guide](#guide)
    *   [1. Initialization & Lifecycle](#1-initialization--lifecycle)
        *   [1.1 Global Initialization](#11-global-initialization)
        *   [1.2 Creating a Player](#12-creating-a-player)
        *   [1.3 Disposing a Player](#13-disposing-a-player)
    *   [2. Media Sources](#2-media-sources)
        *   [2.1 Supported URI Schemes](#21-supported-uri-schemes)
        *   [2.2 HTTP Headers](#22-http-headers)
        *   [2.3 Extras](#23-extras)
    *   [3. Playlist Management](#3-playlist-management)
        *   [3.1 Opening a Single Track](#31-opening-a-single-track)
        *   [3.2 Opening Multiple Tracks](#32-opening-multiple-tracks)
        *   [3.3 Modifying the Queue at Runtime](#33-modifying-the-queue-at-runtime)
        *   [3.4 Navigation](#34-navigation)
        *   [3.5 Repeat & Shuffle](#35-repeat--shuffle)
        *   [3.6 Chapter Navigation](#36-chapter-navigation)
    *   [4. Playback Control](#4-playback-control)
        *   [4.1 Basic Controls](#41-basic-controls)
        *   [4.2 Seeking](#42-seeking)
        *   [4.3 A-B Loop](#43-a-b-loop)
        *   [4.4 Speed & Pitch](#44-speed--pitch)
        *   [4.5 Volume & Mute](#45-volume--mute)
        *   [4.6 Audio Delay](#46-audio-delay)
    *   [5. Audio Quality & DSP](#5-audio-quality--dsp)
        *   [5.1 Filter Chain](#51-filter-chain)
        *   [5.2 Equalizer](#52-equalizer)
        *   [5.3 Compressor](#53-compressor)
        *   [5.4 Loudness](#54-loudness)
        *   [5.5 Pitch / Tempo](#55-pitch--tempo)
        *   [5.6 Custom Filters](#56-custom-filters)
        *   [5.7 ReplayGain](#57-replaygain)
        *   [5.8 Gapless Playback](#58-gapless-playback)
    *   [6. Hardware & Routing](#6-hardware--routing)
        *   [6.1 Audio Output Driver](#61-audio-output-driver)
        *   [6.2 Exclusive Mode](#62-exclusive-mode)
        *   [6.3 Device Selection](#63-device-selection)
        *   [6.4 Output Format](#64-output-format)
        *   [6.5 S/PDIF Passthrough](#65-spdif-passthrough)
        *   [6.6 Audio Client Name](#66-audio-client-name)
        *   [6.7 Audio Track Selection](#67-audio-track-selection)
        *   [6.8 Reload Audio](#68-reload-audio)
    *   [7. Network & Caching](#7-network--caching)
        *   [7.1 Cache Configuration](#71-cache-configuration)
        *   [7.2 Demuxer Memory Pool](#72-demuxer-memory-pool)
        *   [7.3 Network Timeout](#73-network-timeout)
        *   [7.4 TLS/SSL Verification](#74-tlsssl-verification)
        *   [7.5 Audio Buffer](#75-audio-buffer)
        *   [7.6 Audio Stream Silence](#76-audio-stream-silence)
        *   [7.7 Untimed Null Output](#77-untimed-null-output)
        *   [7.8 Radio & Live Streams](#78-radio--live-streams)
    *   [8. Metadata & Cover Art](#8-metadata--cover-art)
        *   [8.1 Metadata Tags](#81-metadata-tags)
        *   [8.2 Cover Art](#82-cover-art)
    *   [9. State & Streams](#9-state--streams)
        *   [9.1 Core Streams](#91-core-streams)
        *   [9.2 Playlist & Track Streams](#92-playlist--track-streams)
        *   [9.3 Audio Hardware Streams](#93-audio-hardware-streams)
        *   [9.4 DSP & Filter Streams](#94-dsp--filter-streams)
        *   [9.5 Network & Cache Streams](#95-network--cache-streams)
        *   [9.6 File Metadata & Path Streams](#96-file-metadata--path-streams)
        *   [9.7 Playback Timing Streams](#97-playback-timing-streams)
        *   [9.8 A-B Loop Streams](#98-a-b-loop-streams)
        *   [9.9 Cover Art & Display Streams](#99-cover-art--display-streams)
        *   [9.10 Runtime Diagnostics](#910-runtime-diagnostics)
        *   [9.11 Prefetch Lifecycle Stream](#911-prefetch-lifecycle-stream)
        *   [9.12 Aggregate Lifecycle](#912-aggregate-lifecycle)
        *   [9.13 Complete State Snapshot](#913-complete-state-snapshot)
    *   [10. Raw API](#10-raw-api)
        *   [10.1 Read a Property](#101-read-a-property)
        *   [10.2 Write a Property](#102-write-a-property)
        *   [10.3 Send a Command](#103-send-a-command)
    *   [11. Error Handling & Logging](#11-error-handling--logging)
        *   [11.1 Typed Error Stream](#111-typed-error-stream)
        *   [11.2 End File Stream](#112-end-file-stream)
        *   [11.3 Network State](#113-network-state)
        *   [11.4 Audio Output Lifecycle](#114-audio-output-lifecycle)
        *   [11.5 Log Streams](#115-log-streams)
    *   [12. Hooks](#12-hooks)
        *   [12.1 Registering a Hook](#121-registering-a-hook)
        *   [12.2 Listening and Continuing](#122-listening-and-continuing)
        *   [12.3 HTTP Headers via Hook](#123-http-headers-via-hook)
        *   [12.4 Lazy URL Resolution](#124-lazy-url-resolution)
*   [Migration](#migration)
*   [Permissions](#permissions)
*   [Troubleshooting](#troubleshooting)
*   [Project Background](#project-background)
*   [Funding](#funding)

---

## Visuals

The following images demonstrate the example app included in the `example/` directory. This application serves as a reference music player for testing the various features and capabilities of mpv.

**Desktop**

<table width="100%">
  <tr>
    <td width="60%"><img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/desktop_player_console.png" width="100%"></td>
    <td align="left"><b>Player</b><br>Cover art, metadata, and controls alongside pinned logs.</td>
  </tr>
  <tr>
    <td width="60%"><img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/desktop_settings_grid.png" width="100%"></td>
    <td align="left"><b>Settings</b><br>Navigation for all properties such as <code>--af</code>, <code>--cache</code>, <code>--network</code>, etc.</td>
  </tr>
</table>

**Mobile**

<table width="100%">
  <tr>
    <td width="25%"><img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/mobile_player.png" width="100%"></td>
    <td width="25%" align="left"><b>Player</b><br>Cover art, metadata, and controls</td>
    <td width="25%"><img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/mobile_queue.png" width="100%"></td>
    <td width="25%" align="left"><b>Queue</b><br>Playlist with shuffle & repeat</td>
  </tr>
  <tr>
    <td width="25%"><img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/mobile_filters.png" width="100%"></td>
    <td width="25%" align="left"><b>Filters (<code>--af</code>)</b><br>10-band EQ, Loudnorm & Compressor</td>
    <td width="25%"><img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/mobile_audio_hardware.png" width="100%"></td>
    <td width="25%" align="left"><b>Hardware (<code>--audio</code>)</b><br>Output device, format & channels</td>
  </tr>
</table>

---

## Features

- ⚡ **Non-blocking** — mpv events run in a background isolate; the UI thread stays free.
- 🧬 **Type-safe API** — typed enums, sealed selectors, `*Settings` bundles. No stringly-typed setters.
- 📡 **Reactive state** — synchronous [`state`](#913-complete-state-snapshot) snapshot + [90+ observable streams](#9-state--streams) covering every mpv property.
- 🎵 **Gapless playback** — seamless track transitions with an observable [prefetch lifecycle](#911-prefetch-lifecycle-stream).
- 🎛️ **DSP pipeline** — typed [equalizer](#52-equalizer), [compressor](#53-compressor), [loudness](#54-loudness), [pitch / tempo](#55-pitch--tempo), plus any custom `--af` filter.
- ⚖️ **ReplayGain** — track & album normalization, preamp, fallback gain.
- 📜 **Dynamic playlist** — add, remove, move, replace mid-playback; [chapters](#36-chapter-navigation) and [A-B loop](#43-a-b-loop) included.
- 🎼 **Multi-track audio** — typed [track selection](#67-audio-track-selection) for multilingual containers (MKV, MP4) with codec / language / gain metadata per track.
- ⚙️ **Hardware control** — [exclusive mode](#62-exclusive-mode), [device selection](#63-device-selection), [bit-perfect sample-rate / format](#64-output-format), [S/PDIF passthrough](#65-spdif-passthrough).
- 🔍 **Metadata & cover art** — [embedded artwork bytes](#82-cover-art) and [tags](#81-metadata-tags), no re-encode round-trip.
- 🌐 **Network streams** — HLS, DASH, [SMB2/3](https://github.com/sahlberg/libsmb2), Icecast / SHOUTcast, plus any libmpv-supported HTTP/HTTPS audio format.
- 📦 **Cache control** — atomic [`CacheSettings`](#71-cache-configuration) for memory pool, disk overflow, pause-on-empty.
- 🪝 **Hooks** — intercept the file-loading pipeline (also during [prefetch](#12-hooks)) to resolve URLs, redirect, or inject headers.
- 🚨 **Typed errors** — sealed [`MpvPlayerError`](#111-typed-error-stream) hierarchy + dedicated sinks for engine errors, end-file events, AO failures, and logs.
- 🔧 **Raw access** — read / write any mpv property or command; failures surface as typed [`MpvException`](#10-raw-api).

---

## Quick Start

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

### 1. Initialization & Lifecycle

<img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/diagrams/player_lifecycle.png" width="100%">

#### 1.1 Global Initialization

Call `MpvAudioKit.ensureInitialized()` **once at startup**, before creating any `Player` instance. This registers the native backend and cleans up any handles that leaked across a Flutter Hot-Restart.

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MpvAudioKit.ensureInitialized();
  runApp(const MyApp());
}
```

On a custom library path (e.g. for testing):
```dart
MpvAudioKit.ensureInitialized(libmpv: '/usr/local/lib/libmpv.so');
```

#### 1.2 Creating a Player

```dart
final player = Player(
  configuration: const PlayerConfiguration(
    logLevel: 'info',     // mpv log verbosity
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

The audio client name (the label shown in PulseAudio / PipeWire / Audio
MIDI Setup) is set after construction:

```dart
await player.setAudioClientName('MyMusicApp');
```

#### 1.3 Disposing a Player

Always call `dispose()` to release native handles and audio device locks. On exclusive mode (WASAPI/ALSA/CoreAudio), failing to dispose can leave the audio device locked to other applications.

```dart
await player.dispose();
```

---

### 2. Media Sources

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

#### 2.1 Supported URI Schemes

##### Local & app-bundled sources

|  | Scheme | Description |
| :---: | :--- | :--- |
| <img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/protocols/file.png" width="20" alt="File"> | `file://` | Local files with absolute path |
| <img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/protocols/flutter.png" width="20" alt="Flutter"> | `asset:///` | Flutter assets bundled in the app |
| <img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/protocols/android.png" width="20" alt="Android"> | `content://` | Android content provider URIs (file picker, media store) |

##### Streaming sources

|  | Scheme | Description |
| :---: | :--- | :--- |
| <img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/protocols/https.png" width="20" alt="HTTPS"> | `https://` / `http://` | Network streams, CDN audio, radio |
| <img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/protocols/jellyfin.png" width="20" alt="Jellyfin"> | `https://…/*.m3u8` | HTTP Live Streaming (HLS) manifest, as used by Jellyfin transcoding |
| <img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/protocols/plex.png" width="20" alt="Plex"> | `https://…/*.mpd` | Dynamic Adaptive Streaming over HTTP (DASH) manifest, as used by Plex transcoding |
| <img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/protocols/samba.png" width="20" alt="Samba"> | `smb2://` | SMB2/3 network shares (Samba/CIFS via libsmb2) |

#### 2.2 HTTP Headers

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
playlist so your UI can access it without a separate lookup. Keys are
opaque to the wrapper — pick whatever fits your app:

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

Access later via `player.state.playlist.medias[index].extras`.

---

### 3. Playlist Management

#### 3.1 Opening a Single Track

```dart
// Respects PlayerConfiguration.autoPlay
await player.open(media);

// Override auto-play for this call
await player.open(media, play: true);
await player.open(media, play: false); // Load but do not start
```

#### 3.2 Opening Multiple Tracks

```dart
await player.openAll([track1, track2, track3]);

// Start at a specific index
await player.openAll([track1, track2, track3], index: 1);

// Override auto-play
await player.openAll([track1, track2], play: false);
```

> Per-track HTTP headers from `Media.httpHeaders` are applied
> automatically only to the first item — for the rest, register an
> `on_load` hook (see [§12](#12-hooks)). This is a deliberate choice:
> the wrapper has no synchronous moment to attach per-file options
> for entries that will be loaded later by mpv on its own schedule.

#### 3.3 Modifying the Queue at Runtime

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

#### 3.5 Repeat & Shuffle

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

#### 3.6 Chapter Navigation

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

`Chapter` exposes `time` (`Duration`) and an optional `title`
(`String?`). Use `state.demuxerStartTime` if you need the source-side
offset (chapter-edited or stream-trimmed files).

---

### 4. Playback Control

#### 4.1 Basic Controls

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

// Seek forward/backward relative to current position
await player.seek(const Duration(seconds: 10), relative: true);
await player.seek(const Duration(seconds: -5), relative: true);
```

mpv uses the `absolute` seek mode by default, which works correctly on
all formats including HLS, providing precise seeking even during
transcoded streams.

#### 4.3 A-B Loop

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

#### 4.4 Speed & Pitch

```dart
await player.setRate(1.5);              // 1.5× speed (0.01 – 100.0)
await player.setPitch(0.9);             // Lower pitch without affecting speed
await player.setPitchCorrection(true);  // Pitch correction when changing rate
```

`setPitchCorrection` enables mpv's `scaletempo` algorithm, which
adjusts playback speed while preserving the original pitch. Set it to
`false` for "vinyl-speed" effects where pitch follows rate.

For high-quality time-stretching that decouples pitch and tempo, see
the [Pitch / Tempo DSP stage](#55-pitch--tempo) (rubberband).

#### 4.5 Volume & Mute

```dart
await player.setVolume(80.0);     // 0–100 (values above 100 amplify)
await player.setMute(true);
await player.setMute(false);

await player.setVolumeMax(150.0); // Raise the software volume ceiling
await player.setVolumeGain(6.0);  // Pre-amplify by +6 dB
```

#### 4.6 Audio Delay

```dart
// Shift audio forward by 50 ms (useful for Bluetooth A2DP sync)
await player.setAudioDelay(const Duration(milliseconds: 50));

// Shift backward by 200 ms
await player.setAudioDelay(const Duration(milliseconds: -200));
```

---

### 5. Audio Quality & DSP

All processing in this section runs in libmpv's `libavfilter` pipeline
and works on **every platform**.

#### 5.1 Filter Chain

The wrapper exposes four typed DSP stages, each with its own atomic
setter. Stages are inserted into mpv's `--af` chain in a fixed order
and can be toggled independently — disabling a stage strips it from
the chain at zero CPU cost while preserving its parameters.

```
custom… → compressor → equalizer → pitch/tempo → loudnorm
```

<img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/diagrams/dsp_chain.png" width="100%">

For anything the four stages don't cover (echo, crossfeed, stereo
widening, crystalizer, format conversion), use
[Custom Filters](#56-custom-filters) — a list of raw mpv `--af`
strings that runs at the head of the chain.

Each typed stage carries an `enabled` flag (default `false`). When
`true` the stage is inserted into the chain; when `false` it's stripped
out at zero CPU cost while its parameters stay in `PlayerState` for
the next toggle.

```dart
// Read the live aggregate config back through the stream:
player.stream.equalizer.listen((cfg) => print('eq: ${cfg.gains}'));

// Or peek synchronously:
final eq = player.state.equalizer;
print('${eq.enabled} / ${eq.gains}');
```

#### 5.2 Equalizer

10-band graphic EQ on the ISO centre frequencies
`31.25 Hz`, `62.5 Hz`, `125 Hz`, `250 Hz`, `500 Hz`, `1 kHz`, `2 kHz`,
`4 kHz`, `8 kHz`, `16 kHz`. Gains are in dB — positive = boost,
negative = cut.

```dart
// Bass boost preset
await player.setEqualizer(const EqualizerSettings(
  enabled: true,
  gains: [4.0, 3.0, 2.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
));

// Tweak a single band (most useful with a slider UI on top of state)
await player.setEqualizer(
  player.state.equalizer.copyWith(
    gains: [...player.state.equalizer.gains]..[5] = 2.5,
  ),
);

// Reset to the flat curve
await player.setEqualizer(EqualizerSettings.flat);

// Disable the stage; the gains are preserved for re-enable
await player.setEqualizer(player.state.equalizer.copyWith(enabled: false));
```

The list must contain exactly **10** values; the setter throws
`ArgumentError` otherwise.

#### 5.3 Compressor

Dynamic-range compressor (libavfilter `acompressor`). Reduces the gap
between loud and quiet passages. Defaults match a transparent music
preset.

```dart
await player.setCompressor(const CompressorSettings(
  enabled: true,
  threshold: -20.0,                     // dB; -60 to 0
  ratio: 4.0,                           // 1.0 (off) to 20.0 (limiter)
  attack: Duration(milliseconds: 20),   // 0.01–2000 ms
  release: Duration(milliseconds: 250), // 0.01–9000 ms
));
```

#### 5.4 Loudness

EBU R128 loudness normalization (libavfilter `loudnorm`). Targets a
consistent perceived loudness across mixed content (broadcast,
podcasts, mixed-album streams).

```dart
await player.setLoudness(const LoudnessSettings(
  enabled: true,
  integratedLoudness: -16.0, // LUFS; -23 broadcast, -16 streaming, -14 loud
  truePeak: -1.5,            // dBTP; -9 to 0
  lra: 11.0,                 // Loudness range; 1 to 50 LU
));
```

#### 5.5 Pitch / Tempo

High-quality independent pitch / tempo shifting via librubberband
(`rubberband` filter). CPU cost is non-trivial vs. mpv's built-in
`scaletempo` engine — enable only when the consumer needs the extra
quality. Independent of [`setRate`](#44-speed--pitch).

```dart
// Raise pitch by one semitone, keep speed
await player.setPitchTempo(const PitchTempoSettings(
  enabled: true,
  pitch: 1.0594,
  tempo: 1.0,
));

// Slow down to 75% without changing pitch
await player.setPitchTempo(const PitchTempoSettings(
  enabled: true,
  pitch: 1.0,
  tempo: 0.75,
));
```

#### 5.6 Custom Filters

Raw mpv `--af` strings inserted at the head of the chain, before any
wrapper-managed DSP stage. Use this for anything the four typed
stages don't cover (echo, crossfeed, format conversion, custom
lavfi):

```dart
await player.setCustomAudioFilters([
  // Crossfeed for headphone listening
  'lavfi-bs2b',
  // Echo: 300 ms decay, 30% falloff
  'lavfi-aecho=0.8:0.5:60:0.4',
  // Resample everything to 48 kHz
  'lavfi-aresample=48000',
]);

// Clear all custom filters; typed stages stay in place
await player.setCustomAudioFilters(const []);
```

The setter rejects entries carrying the wrapper-reserved labels
(`@_mak_eq:`, `@_mak_comp:`, `@_mak_loud:`, `@_mak_pt:`) with an
`ArgumentError` — those slots belong to the typed setters above.

#### 5.7 ReplayGain

ReplayGain reads per-track or per-album gain tags embedded by tools
like `mp3gain`, `metaflac`, or any modern music tagger. The full
configuration is set atomically via `setReplayGain(ReplayGainSettings)`:

```dart
await player.setReplayGain(const ReplayGainSettings(
  mode: ReplayGain.track, // .no, .track, .album
  preamp: 2.0,                // +2 dB on top of the RG value
  fallback: -6.0,             // -6 dB on files without RG tags
  clip: false,                // false = peak-limit; true = allow clipping
));

// Tweak a single field via copyWith
await player.setReplayGain(
  player.state.replayGain.copyWith(mode: ReplayGain.album),
);
```

#### 5.8 Gapless Playback

```dart
await player.setGapless(Gapless.yes);   // Full gapless — re-uses the decoder
await player.setGapless(Gapless.weak);  // Gapless only on compatible formats (default)
await player.setGapless(Gapless.no);    // Close and re-open the AO between tracks
```

`weak` is the safest default: it delivers gapless transitions between
tracks of the same format (e.g. consecutive FLAC or MP3) without the
risk of breaking when the format changes mid-playlist.

For seamless transitions between tracks of any format, combine
`Gapless.yes` with `setPrefetchPlaylist(true)` and observe the
[prefetch lifecycle](#911-prefetch-lifecycle-stream).

```dart
// Pre-open the next playlist entry in the background — first audio
// frame ready before the current track ends.
await player.setPrefetchPlaylist(true);
```

Disabled by default (mpv's own default) because background prefetch
opens an extra demuxer + cache for the next track, which costs memory.
Enable it for music players where seamless transitions matter; leave
it off for radio / single-track sessions.

---

### 6. Hardware & Routing

#### 6.1 Audio Output Driver

Select the native backend used for audio output:

```dart
await player.setAudioDriver('wasapi');    // Windows
await player.setAudioDriver('coreaudio'); // macOS
await player.setAudioDriver('pulse');     // Linux
await player.setAudioDriver('alsa');      // Linux
await player.setAudioDriver('pipewire');  // Linux
await player.setAudioDriver('auto');      // Let mpv choose (default)
```

#### 6.2 Exclusive Mode

Bypasses the OS audio mixer and writes directly to the hardware. Eliminates software resampling and volume processing for bit-perfect output. Only available on WASAPI (Windows), ALSA (Linux) and CoreAudio (macOS):

```dart
await player.setAudioExclusive(true);   // Request exclusive access
await player.setAudioExclusive(false);  // Release, return to shared mode
```

> Exclusive mode locks the audio device. Always call `player.dispose()` when done, or other apps will have no sound.

#### 6.3 Device Selection

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

#### 6.4 Output Format

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

// Bit depth / sample format — typed Format enum
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

// Channel layout — sealed Channels with named static constants
// (mirror of mpv's std_layout_names[] table 1-to-1).

// Special modes
await player.setAudioChannels(Channels.auto);            // mpv picks
await player.setAudioChannels(Channels.autoSafe);        // mpv picks, reject multichannel unless verified

// 1 channel
await player.setAudioChannels(Channels.mono);            // mono
await player.setAudioChannels(Channels.oneZero);         // 1.0 (alias of mono)

// 2 channels
await player.setAudioChannels(Channels.stereo);          // stereo
await player.setAudioChannels(Channels.twoZero);         // 2.0 (alias of stereo)
await player.setAudioChannels(Channels.downmix);         // downmix (semantic alias of stereo)

// 3 channels
await player.setAudioChannels(Channels.twoOne);          // 2.1
await player.setAudioChannels(Channels.threeZero);       // 3.0
await player.setAudioChannels(Channels.threeZeroBack);   // 3.0(back)

// 4 channels
await player.setAudioChannels(Channels.fourZero);        // 4.0
await player.setAudioChannels(Channels.quad);            // quad
await player.setAudioChannels(Channels.quadSide);        // quad(side)
await player.setAudioChannels(Channels.threeOne);        // 3.1
await player.setAudioChannels(Channels.threeOneBack);    // 3.1(back)

// 5 channels
await player.setAudioChannels(Channels.fiveZero);        // 5.0
await player.setAudioChannels(Channels.fiveZeroAlsa);    // 5.0(alsa)
await player.setAudioChannels(Channels.fiveZeroSide);    // 5.0(side)
await player.setAudioChannels(Channels.fourOne);         // 4.1
await player.setAudioChannels(Channels.fourOneAlsa);     // 4.1(alsa)

// 6 channels
await player.setAudioChannels(Channels.fiveOne);         // 5.1 (back surround)
await player.setAudioChannels(Channels.fiveOneAlsa);     // 5.1(alsa)
await player.setAudioChannels(Channels.fiveOneSide);     // 5.1 (side surround)
await player.setAudioChannels(Channels.sixZero);         // 6.0
await player.setAudioChannels(Channels.sixZeroFront);    // 6.0(front)
await player.setAudioChannels(Channels.hexagonal);       // hexagonal

// 7 channels
await player.setAudioChannels(Channels.sixOne);          // 6.1
await player.setAudioChannels(Channels.sixOneBack);      // 6.1(back)
await player.setAudioChannels(Channels.sixOneTop);       // 6.1(top)
await player.setAudioChannels(Channels.sixOneFront);     // 6.1(front)
await player.setAudioChannels(Channels.sevenZero);       // 7.0
await player.setAudioChannels(Channels.sevenZeroFront);  // 7.0(front)
await player.setAudioChannels(Channels.sevenZeroRear);   // 7.0(rear)

// 8 channels
await player.setAudioChannels(Channels.sevenOne);        // 7.1 canonical
await player.setAudioChannels(Channels.sevenOneAlsa);    // 7.1(alsa)
await player.setAudioChannels(Channels.sevenOneWide);    // 7.1(wide)
await player.setAudioChannels(Channels.sevenOneWideSide); // 7.1(wide-side)
await player.setAudioChannels(Channels.sevenOneTop);     // 7.1(top)
await player.setAudioChannels(Channels.sevenOneRear);    // 7.1(rear)
await player.setAudioChannels(Channels.octagonal);       // octagonal
await player.setAudioChannels(Channels.cube);            // cube

// Cinema / immersive
await player.setAudioChannels(Channels.hexadecagonal);   // hexadecagonal (16ch)
await player.setAudioChannels(Channels.surround222);     // 22.2 (NHK / ITU-R BS.775)

// Custom escape — anything mpv recognises but isn't in the named set
// (comma-separated lists, raw speaker-tag arrays).
await player.setAudioChannels(
  const Channels.custom('fl-fr-fc-bl-br-sl-sr-lfe'),
);
```

Every named constant maps 1-to-1 to mpv's `audio-channels` parser
output — the variant qualifier in parentheses (`(side)`, `(back)`,
`(alsa)`, `(top)`, `(front)`, `(rear)`, `(wide-side)`, `(wide)`) is
preserved in the Dart identifier.

#### 6.5 S/PDIF Passthrough

Send compressed audio (AC3, DTS, TrueHD, …) directly to an AV receiver
over S/PDIF or HDMI. Pass a typed `Set<Spdif>` (7 codecs from mpv's
internal whitelist):

```dart
// Home-theater Dolby + DTS-HD passthrough
await player.setAudioSpdif({Spdif.ac3, Spdif.eac3, Spdif.trueHd, Spdif.dtsHd});

// Dolby only
await player.setAudioSpdif({Spdif.ac3, Spdif.eac3, Spdif.trueHd});

// Disable passthrough
await player.setAudioSpdif({});
```

Available codecs: `Spdif.aac`, `Spdif.ac3`, `Spdif.dts`, `Spdif.dtsHd`,
`Spdif.eac3`, `Spdif.mp3`, `Spdif.trueHd`. `dtsHd` implicitly enables
the standard DTS path on top of DTS-HD MA — specifying both `dts` and
`dtsHd` is equivalent to `dtsHd` alone.

#### 6.6 Audio Client Name

The name shown in system audio mixers (PulseAudio, PipeWire, macOS Audio MIDI Setup):

```dart
await player.setAudioClientName('MyMusicApp');
```

#### 6.7 Audio Track Selection

For containers with multiple audio tracks (e.g. MKV, MP4 with language
variants), the wrapper exposes both the **inventory** of tracks the
demuxer surfaced and the **active** track — plus a typed setter.

```dart
// Walk the audio inventory:
for (final t in player.state.tracks.where((tr) => tr.type == 'audio')) {
  print('${t.id}: ${t.title ?? t.lang ?? "audio"} '
        '(${t.codec} ${t.samplerate} Hz ${t.channelCount}ch)');
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

`MpvTrack` ships rich per-track introspection — codec, decoder, sample
rate, channel count, ReplayGain tags, language, default / forced
flags, and `image` / `albumart` flags so you can skip embedded picture
streams when populating a track-switcher UI.

#### 6.8 Reload Audio

Force the audio output to reinitialize. Useful after changing hardware parameters like sample rate or format while playback is active:

```dart
await player.reloadAudio();
```

---

### 7. Network & Caching

#### 7.1 Cache Configuration

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

#### 7.2 Demuxer Memory Pool

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

#### 7.3 Network Timeout

```dart
await player.setNetworkTimeout(const Duration(seconds: 10)); // Fail after 10 seconds of no data
```

#### 7.4 TLS/SSL Verification

```dart
await player.setTlsVerify(false); // Disable for self-signed certificates
```

#### 7.5 Audio Buffer

The hardware audio buffer — lower values reduce latency, higher values improve stability under load:

```dart
await player.setAudioBuffer(const Duration(milliseconds: 100));  // 100 ms (low latency)
await player.setAudioBuffer(const Duration(milliseconds: 500));  // 500 ms (stable on slow hardware)
```

#### 7.6 Audio Stream Silence

Keep audio hardware active even when playback is paused, to eliminate click/pop on resume:

```dart
await player.setAudioStreamSilence(true);
```

> **Note on iOS:** the audio driver in this case is never released, so after an iOS interruption (phone call, other app audio) it stays suspended and playback can't continue.

#### 7.7 Untimed Null Output

When using the `null` audio driver (e.g. for server-side processing or testing without a sound device), this makes the null output run as fast as possible instead of at real time:

```dart
await player.setAudioNullUntimed(true);
```

#### 7.8 Radio & Live Streams

For Icecast/SHOUTcast radio, disable caching and cache-pause to minimize latency:

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

### 8. Metadata & Cover Art

#### 8.1 Metadata Tags

```dart
player.stream.metadata.listen((tags) {
  final title = tags['title'];
  final artist = tags['artist'];
  final album = tags['album'];
  final date = tags['date'];
  final trackNumber = tags['track'];
  print('Now playing: $title — $artist');
});

// Synchronous access
final meta = player.state.metadata;
```

Common tag keys (case as returned by mpv): `title`, `artist`, `album`, `album_artist`, `date`, `track`, `disc`, `genre`, `comment`, `composer`.

#### 8.2 Cover Art

The wrapper extracts the **raw codec bytes** of the embedded picture
the moment a file finishes loading and emits them on
`player.stream.coverArtRaw` as a `CoverArtRaw(bytes, mimeType)`. The
bytes are the original PNG / JPEG / WEBP / BMP / GIF as embedded by
the tagger.

```dart
Uint8List? _cover;

@override
void initState() {
  super.initState();
  player.stream.coverArtRaw.listen((raw) {
    setState(() => _cover = raw?.bytes);
  });
}

// Hand straight to Image.memory — no helper needed.
@override
Widget build(BuildContext context) {
  return _cover != null ? Image.memory(_cover!) : const SizedBox.shrink();
}
```

The stream emits **exactly once per file load** — a `CoverArtRaw` when
the new file has embedded artwork, `null` otherwise. Listen for the
`null` to clear stale artwork on track changes.

Three mpv-level options control how mpv treats cover-art metadata.
Each has a typed setter and an observable getter.

##### `audio-display`

Which image source mpv decodes into its video pipeline.

```dart
await player.setAudioDisplay(Display.embeddedFirst); // default
await player.setAudioDisplay(Display.externalFirst);
await player.setAudioDisplay(Display.no);            // skip cover art entirely
```

| Value | Behaviour |
|-------|-----------|
| `embeddedFirst` | Prefer embedded images; fall back to external files. (mpv default.) |
| `externalFirst` | Prefer external files; fall back to embedded. |
| `no` | Skip cover-art display entirely — useful when you read artwork via a tag library. |

##### `cover-art-auto`

Whether mpv scans for an external cover-art file next to the audio
file (`cover.jpg`, `folder.jpg`, …).

```dart
await player.setCoverArtAuto(Cover.no); // library default
await player.setCoverArtAuto(Cover.exact);
await player.setCoverArtAuto(Cover.fuzzy);
await player.setCoverArtAuto(Cover.all);
```

The library defaults to `no` (mpv's own default is `exact`) so
unrelated images can't sneak in. Switch to `exact` or `fuzzy` for a
local-file player that wants disk-side artwork.

##### `image-display-duration`

How long the cover frame is held as a displayable video frame after
the file loads.

```dart
await player.setImageDisplayDuration(null);                            // mpv's `inf` (default)
await player.setImageDisplayDuration(Duration.zero);                   // drop immediately
await player.setImageDisplayDuration(const Duration(seconds: 5));      // explicit hold
```

> **Tip — disabling the video pipeline entirely:** if your app reads
> artwork via a tag library and never uses `coverArtRaw`, you can
> turn the whole video pipeline off:
>
> ```dart
> await player.setAudioDisplay(Display.no);
> await player.setCoverArtAuto(Cover.no);
> await player.setImageDisplayDuration(Duration.zero);
> ```

---

### 9. State & Streams

`mpv_audio_kit` exposes all player state in two complementary ways:

- **`player.state`** — a synchronous, immutable snapshot of the current state. Safe to read from anywhere.
- **`player.stream`** — reactive streams that emit on every change. Use with `StreamBuilder` or `.listen()`.

> Every entry below has a synchronous mirror on `player.state` (same
> field name, same type) for snapshot-style reads. Subscribing to the
> stream is the right tool when the UI must react to changes;
> reading from `state` is the right tool inside event handlers and
> one-shot logic.

#### 9.1 Core Streams

Transport, lifecycle, volume, and the playback metric trio.

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

#### 9.2 Playlist & Track Streams

Playlist / chapters / available tracks. Detailed usage in
[§3](#3-playlist-management), [§3.6](#36-chapter-navigation), and
[§6.7](#67-audio-track-selection).

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

#### 9.3 Audio Hardware Streams

Decoder side, hardware side, and every audio-output knob. Setters live
in [§4.5](#45-volume--mute), [§6](#6-hardware--routing), and
[§7.5–7.7](#75-audio-buffer).

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
`channelCount`, `hrChannels`, `codec`, `codecName`. `codec` /
`codecName` mirror mpv's two raw codec properties — both vary by mpv
build, so do a case-insensitive substring match against **both** for
codec-family detection.

#### 9.4 DSP & Filter Streams

Every typed DSP stage emits its full aggregate settings — peek at
`.value` synchronously through `state` for one-shot reads. Detailed
usage in [§5](#5-audio-quality--dsp).

| Stream | Type | Setter |
| :--- | :--- | :--- |
| `equalizer` | `EqualizerSettings` | `setEqualizer` |
| `compressor` | `CompressorSettings` | `setCompressor` |
| `loudness` | `LoudnessSettings` | `setLoudness` |
| `pitchTempo` | `PitchTempoSettings` | `setPitchTempo` |
| `customAudioFilters` | `List<String>` | `setCustomAudioFilters` |
| `replayGain` | `ReplayGainSettings` | `setReplayGain` |
| `gapless` | `Gapless` | `setGapless` |

#### 9.5 Network & Cache Streams

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

`pausedForCache` is the authoritative network-stall signal — prefer
it over interpreting error events. See also [§11.3](#113-network-state).

#### 9.6 File Metadata & Path Streams

Display name, container info, and the four path / URI fields.

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

#### 9.7 Playback Timing Streams

Fine-grained playhead diagnostics for sync calculations.

| Stream | Type | Notes |
| :--- | :--- | :--- |
| `audioPts` | `Duration` | mpv's `audio-pts`; per-frame timestamp including AO latency. More granular than [`position`](#91-core-streams). |
| `timeRemaining` | `Duration` | Wall-clock time to EOF, **ignoring** playback rate. |
| `playtimeRemaining` | `Duration` | Time to EOF **adjusted** for playback rate. |

#### 9.8 A-B Loop Streams

Mirrors of the [§4.3](#43-a-b-loop) setters plus a read-only counter.

| Stream | Type | Setter |
| :--- | :--- | :--- |
| `abLoopA` | `Duration?` (`null` = disabled) | `setAbLoopA` |
| `abLoopB` | `Duration?` (`null` = disabled) | `setAbLoopB` |
| `abLoopCount` | `int?` (`null` = infinite) | `setAbLoopCount` |
| `remainingAbLoops` | `int?` (`null` when no loop / infinite) | _(observed; counts down)_ |

#### 9.9 Cover Art & Display Streams

Cover-art capture and the three display-related options. See
[§8.2](#82-cover-art) for the consumer-facing usage.

| Stream | Type | Setter |
| :--- | :--- | :--- |
| `coverArtRaw` | `CoverArtRaw?` (one emit per file load) | _(observed; from embedded picture)_ |
| `audioDisplay` | `Display` | `setAudioDisplay` |
| `coverArtAuto` | `Cover` | `setCoverArtAuto` |
| `imageDisplayDuration` | `Duration?` (`null` = mpv's `inf`) | `setImageDisplayDuration` |

#### 9.10 Runtime Diagnostics

Tier-2 introspection — useful for diagnostic overlays and capability
gating. All read-only.

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

#### 9.11 Prefetch Lifecycle Stream

mpv pre-opens the next playlist entry in the background to make the
transition between tracks gapless. The wrapper exposes a typed stream
so consumers can drive a "Prefetching…" UI, verify gapless, or log
warnings when a prefetch is dropped — without parsing log lines.

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

State machine:

| State | When it fires | Notes |
| :--- | :--- | :--- |
| `idle` | Default; after every cancel / drop | Also fires right after `used` and `failed` so they read as one-shot transients |
| `loading` | Opener thread running | Persists until the demuxer is open and the reader goes idle |
| `ready` | Secondary demuxer open + reader idle | Gapless is armed |
| `used` | Track transitioned via the prefetched stream | Edge-triggered; pairs with the subsequent `idle` |
| `failed` | Opener thread error | Edge-triggered; pairs with the subsequent `idle` |

Typical happy-path sequence for a gapless transition:

```
idle → loading → ready → used → idle
```

For a dropped or failed prefetch:

```
idle → loading → idle
idle → loading → failed → idle
```

#### 9.12 Aggregate Lifecycle

`player.stream.playbackState` collapses the four underlying flags
(`playing` / `buffering` / `completed` / `pausedForCache`) plus
`duration` into a single mutually-exclusive `MpvPlaybackState` enum
— ideal when the UI wants one indicator instead of three.

```dart
player.stream.playbackState.listen((phase) {
  switch (phase) {
    case MpvPlaybackState.idle:       // No file loaded
    case MpvPlaybackState.loading:    // File is opening (demuxer/decoder init)
    case MpvPlaybackState.buffering:  // Mid-playback network stall
    case MpvPlaybackState.playing:    // Producing audio
    case MpvPlaybackState.paused:     // File loaded, audio paused
    case MpvPlaybackState.completed:  // Reached natural EOF
  }
});
```

Subscriptions are lazy: the upstream sources are only listened to
while a consumer is attached, and the aggregate is deduped before
emission so consecutive equal values don't refire.

#### 9.13 Complete State Snapshot

`player.state` mirrors every stream above — use it for one-shot reads
inside event handlers and `build()` methods. A small sample:

```dart
final s = player.state;
print(s.playing);                                // bool
print(s.position);                               // Duration
print(s.duration);                               // Duration
print(s.volume);                                 // double
print(s.buffer);                                 // Duration
print(s.playlist.medias[s.playlist.index].uri);  // String
print(s.metadata['title']);                      // String?
print(s.audioParams.codec);                      // String?
print(s.equalizer.gains);                        // List<double>
print(s.cache.secs);                             // Duration
print(s.replayGain.preamp);                      // double
print(s.tracks.where((t) => t.type == 'audio')); // Iterable<MpvTrack>
print(s.chapters);                               // List<Chapter>
print(s.audioOutputState);                       // AudioOutputState
print(s.mpvVersion);                             // e.g. '0.41.0'
print(s.ffmpegVersion);                          // e.g. '7.1.1'
```

---

### 10. Raw API

For anything not covered by the typed API, you can access mpv directly.

#### 10.1 Read a Property

Returns `null` if the property does not exist or the FFI call fails.

```dart
final String? value = await player.getRawProperty('audio-codec');
final String? samplerate = await player.getRawProperty('audio-params/samplerate');
```

#### 10.2 Write a Property

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

#### 10.3 Send a Command

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
> `setReplayGain`, …) when they cover your use case — they update
> `state` synchronously instead of waiting for the property observer
> round-trip.

---

### 11. Error Handling & Logging

<img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/diagrams/error_streams.png" width="100%">

#### 11.1 Typed Error Stream

The error stream emits `MpvPlayerError` — a sealed class with two subtypes that let you distinguish between playback failures and informational engine errors:

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
      // An mpv subsystem logged at error/fatal level (e.g. codec issue).
      // Does NOT necessarily mean playback has stopped.
      print('Log error [${error.prefix}] ${error.level}: ${error.message}');
  }
});
```

**`MpvEndFileError`** — emitted when `MPV_EVENT_END_FILE` fires with a non-zero error code:
- `reason` — a `MpvEndFileReason` enum (`eof`, `stop`, `quit`, `error`, `redirect`)
- `code` — the raw mpv error code (e.g. `-13` for `MPV_ERROR_LOADING_FAILED`)
- `isLoadingError` — `true` for network/file loading failures
- `isAudioOutputError` — `true` when the audio output driver failed to initialize
- `isFormatError` — `true` when the file format is unrecognizable or has no audio

**`MpvLogError`** — emitted when mpv logs at `error` or `fatal` level:
- `prefix` — the mpv subsystem (e.g. `'ffmpeg'`, `'ao'`, `'demux'`)
- `level` — `'error'` or `'fatal'`

> **Network note:** per the mpv documentation, a network disconnection mid-stream
> may report as `MpvEndFileReason.eof` rather than `MpvEndFileReason.error`.
> Use `player.stream.endFile` and compare position vs duration for reliable detection (see §11.2).

#### 11.2 End File Stream

`player.stream.endFile` emits an `MpvFileEndedEvent` for **every** file-end — not just errors. This is the only way to detect premature EOFs caused by network disconnections, which mpv reports as `reason: eof` with no error code:

```dart
player.stream.endFile.listen((event) {
  if (event.reason == MpvEndFileReason.eof) {
    final pos = player.state.position;
    final dur = player.state.duration;
    if (dur > Duration.zero && (dur - pos).inSeconds > 5) {
      print('Premature EOF — likely a network drop');
    }
  }
});
```

`MpvFileEndedEvent` fields:
- `reason` — a `MpvEndFileReason` enum value
- `error` — the raw mpv error code (non-zero only when `reason == MpvEndFileReason.error`)

#### 11.3 Network State

Two dedicated streams for monitoring network conditions:

```dart
// True when playback is paused because the cache ran empty (network stall).
// This is the authoritative signal — prefer it over interpreting error events.
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

#### 11.4 Audio Output Lifecycle

mpv exposes the audio output's lifecycle as a typed stream — read it
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

The wrapper also surfaces a typed `MpvLogError` on `stream.error` the
moment the AO transitions to `failed`, so you don't need a separate
listener for the "no sound" case.

#### 11.5 Log Streams

Two streams keep engine and wrapper messages disjoint — route them to
different sinks (e.g. show only `log` in a debug overlay while
forwarding `internalLog` to crash reporting).

```dart
// mpv engine messages: ffmpeg, demux, ao, cplayer, …
player.stream.log.listen((entry) {
  // MpvLogEntry has: prefix (String), level (String), text (String)
  print('[${entry.level}] ${entry.prefix}: ${entry.text}');
});

// Wrapper-side diagnostics: JSON parse warnings, hook timeouts,
// resolution errors. Always carries prefix: 'mpv_audio_kit'.
player.stream.internalLog.listen((entry) {
  print('[wrapper:${entry.level}] ${entry.text}');
});
```

Set `logLevel` in `PlayerConfiguration` to control engine-side
verbosity. `'warn'` is appropriate for production; `'debug'` or `'v'`
for development.

---

### 12. Hooks

Hooks intercept mpv's file-loading pipeline before a stream is opened. Use them to lazily resolve URLs, inject per-file HTTP headers, or redirect to a different source — without a local proxy server.

<img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/diagrams/on_load_hook_sequence.png" width="100%">

#### 12.1 Registering a Hook

Call `registerHook` **once** after creating the player (before any `open` call). Pass a typed [`Hook`](#) value — typo-proof and exhaustive in `switch`:

```dart
player.registerHook(Hook.load);
```

You can add a safety timeout — if `continueHook` isn't called within the given duration, the library auto-continues to prevent mpv from stalling indefinitely (e.g. due to an unhandled exception):

```dart
player.registerHook(Hook.load, timeout: const Duration(seconds: 10));
```

The full set of mpv lifecycle hooks (mpv 0.41 — `process_hooks` calls in `player/loadfile.c`):

| Hook | When it fires |
| :--- | :--- |
| `Hook.beforeStartFile` | Before any per-file work begins (drains stale property changes) |
| `Hook.load` | Before a stream is opened — redirect the URL or attach per-file headers |
| `Hook.loadFail` | After a stream failed to open — useful for fallback URLs |
| `Hook.preloaded` | File open, demuxer ready, before track selection / decoder init |
| `Hook.unload` | Before a file is closed — cleanup hook tied to the current file |
| `Hook.afterEndFile` | After a file finished and was fully unloaded |

> **Hooks fire during prefetch too.** When mpv pre-opens the next playlist entry to enable gapless transitions, `on_load` is invoked for that track too — so custom URL schemes (e.g. `plex-transcode://` → resolved HLS URL) are resolved for **every** track, including the one being prefetched in the background. Your listener is called once per track regardless of whether playback is active or prefetching, and `setRawProperty('stream-open-filename', …)` accepts hook-driven rewrites in either context.

#### 12.2 Listening and Continuing

Subscribe to `player.stream.hook` and call `continueHook` when processing is done. **You must always call `continueHook`**, even on error — otherwise mpv stalls indefinitely:

```dart
player.stream.hook.listen((event) async {
  if (event.hook == Hook.load) {
    final url = await player.getRawProperty('stream-open-filename') ?? '';

    try {
      if (url.startsWith('my-scheme://')) {
        // Redirect to a real URL
        final resolved = await myResolver(url);
        await player.setRawProperty('stream-open-filename', resolved.url);

        // Inject per-file HTTP headers (direct HTTP only — for HLS use URL query params)
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

#### 12.3 HTTP Headers via Hook

`file-local-options/http-header-fields` sets headers only for the current file. They are applied at the mpv/libmpv layer and work correctly for direct HTTP streams.

**Important — HLS streams**: when mpv opens an HLS playlist, the actual segment downloads are handled directly by ffmpeg/lavf, which does **not** inherit `http-header-fields` set via the hook. If your server requires authentication on the HLS segments, embed the credentials in the URL as query parameters instead:

```dart
// ✅ Correct for HLS — auth in the URL, visible to ffmpeg/lavf
player.setRawProperty(
  'stream-open-filename',
  'https://server/stream/playlist.m3u8?token=abc123',
);

// ⚠️ Works for direct HTTP streams only — ignored by ffmpeg/lavf for HLS sub-requests
player.setRawProperty('file-local-options/http-header-fields', 'Authorization: Bearer abc123');
```

#### 12.4 Lazy URL Resolution

When building a playlist with `Future.wait`, all `getStreamUrl` calls run in parallel. If your server rejects concurrent session creation (as Plex does for transcoding), store the session parameters and return a placeholder URL (e.g. `my-scheme://session-id`). The `on_load` hook fires **sequentially** as mpv opens each track, so resolution calls never overlap:

```dart
// Building the queue — no real API calls yet
final medias = await Future.wait(tracks.map((t) async {
  final url = await service.getStreamUrl(t.id); // returns "my-scheme://abc"
  return Media(url);
}));
await player.openAll(medias);

// When mpv reaches each track, the hook resolves it on demand:
// on_load → myResolver("my-scheme://abc") → /decision + start.m3u8 URL
```

---


## Migration

0.1.0 is a **major breaking release**. The Dart-side surface was
rewritten from scratch: every setter is typed, every observable is
either a typed enum or a Freezed config aggregate, and the escape
hatches now propagate mpv errors instead of swallowing them. This
section is a side-by-side cross-walk against 0.0.9 — for the
exhaustive change log (with rationale per breaking change), see
[CHANGELOG.md → Migration from 0.0.9](CHANGELOG.md#migration-from-009).

### Renames at a glance

#### Setters & methods

| 0.0.9 | 0.1.0 |
| :--- | :--- |
| `Player.openPlaylist(...)` | `Player.openAll(...)` |
| `Player.playOrPause()` | _Removed_ — use `state.playing ? pause() : play()` |
| `Player.appendLog(text)` | _Removed_ — use `Player.stream.internalLog` for wrapper messages |
| `Player.setGaplessPlayback(Gapless)` | `Player.setGapless(Gapless)` |
| `Player.setAudioTrack('1')` | `Player.setAudioTrack(Track.id(1))` |
| `Player.setAoNullUntimed(...)` | `Player.setAudioNullUntimed(...)` |
| `Player.setCoverArtAuto('exact')` | `Player.setCoverArtAuto(Cover.exact)` |
| `Player.registerHook('on_load')` | `Player.registerHook(Hook.load)` |
| `event.name == 'on_load'` (on `MpvHookEvent`) | `event.hook == Hook.load` |
| `setAudioFilters([AudioFilter.equalizer(...)])` | `setEqualizer(EqualizerSettings(...))` (and three peers) |
| `setReplayGainPreamp` / `setReplayGainFallback` / `setReplayGainClip` | `setReplayGain(ReplayGainSettings(...))` |
| `setCacheSecs` / `setCachePause` / `setCachePauseWait` / `setCacheOnDisk` | `setCache(CacheSettings(...))` |

#### State fields & types

| 0.0.9 | 0.1.0 |
| :--- | :--- |
| `state.audioDisplay: String` | `state.audioDisplay: Display` |
| `state.coverArtAuto: String` | `state.coverArtAuto: Cover` |
| `state.audioFormat: String` | `state.audioFormat: Format` |
| `state.audioChannels: String` | `state.audioChannels: Channels` |
| `state.audioSpdif: String` | `state.audioSpdif: Set<Spdif>` |
| `state.activeFilters` / `state.equalizerGains` | `state.equalizer` / `state.compressor` / `state.loudness` / `state.pitchTempo` / `state.customAudioFilters` |
| `state.playlistMode` | `state.loop` |
| `Playlist.empty()` (factory) | `Playlist.empty` (const static field) |

#### Type renames

| 0.0.9 | 0.1.0 |
| :--- | :--- |
| `GaplessMode`, `LoopMode`, `CacheMode`, `ReplayGainMode`, `CoverArtAutoMode`, `AudioDisplayMode`, `AudioTrackMode`, `AudioChannelsMode` | `Gapless`, `Loop`, `Cache`, `ReplayGain`, `Cover`, `Display`, `Track`, `Channels` (drop redundant `*Mode` suffix) |
| `AudioFormat`, `AudioChannels`, `AudioTrack`, `AudioDisplay`, `AudioDevice` | `Format`, `Channels`, `Track`, `Display`, `Device` (drop redundant `Audio` prefix on setter-argument types; setter and state-field names keep it) |
| `CacheConfig`, `ReplayGainConfig`, `EqualizerConfig`, `CompressorConfig`, `LoudnessConfig`, `PitchTempoConfig` | `CacheSettings`, `ReplayGainSettings`, `EqualizerSettings`, `CompressorSettings`, `LoudnessSettings`, `PitchTempoSettings` (multi-field bundles end in `*Settings`) |
| `PlaybackLifecycle` | `MpvPlaybackState` (the `Mpv` prefix avoids a name clash with `audio_service.PlaybackState`) |

### Async escape hatches

```dart
// 0.0.9
final v = player.getRawProperty('audio-codec');
player.setRawProperty('audio-samplerate', '96000');
player.sendRawCommand(['ao-reload']);

// 0.1.0 — all three are Future<...>; failures throw MpvException
final v = await player.getRawProperty('audio-codec');
await player.setRawProperty('audio-samplerate', '96000');
await player.sendRawCommand(['ao-reload']);
```

### DSP filters

```dart
// 0.0.9
await player.setAudioFilters([
  AudioFilter.equalizer([0, 0, 2, 4, 2, 0, -2, -4, -4, 0]),
  AudioFilter.loudnorm(),
  AudioFilter.compressor(threshold: -18, ratio: 3),
]);

// 0.1.0 — typed configs, one setter per stage; chain composed atomically
await player.setEqualizer(const EqualizerSettings(
  enabled: true,
  gains: [0, 0, 2, 4, 2, 0, -2, -4, -4, 0],
));
await player.setLoudness(const LoudnessSettings(enabled: true));
await player.setCompressor(const CompressorSettings(
  enabled: true, threshold: -18, ratio: 3,
));

// Anything outside the four typed stages goes through setCustomAudioFilters
await player.setCustomAudioFilters(['lavfi-bs2b', 'lavfi-aecho=0.8:0.5:60:0.4']);
```

The 0.0.9 factories that aren't typed setters in 0.1.0
(`AudioFilter.crossfeed`, `.echo`, `.extraStereo`, `.crystalizer`,
`.scaleTempo`) move into `setCustomAudioFilters` as raw mpv `--af`
strings. `scaleTempo` is also superseded by the new typed
[Pitch / Tempo stage](#55-pitch--tempo) (rubberband).

### Time-based setters now take `Duration`

| 0.0.9 | 0.1.0 |
| :--- | :--- |
| `setAudioDelay(0.05)` | `setAudioDelay(const Duration(milliseconds: 50))` |
| `setNetworkTimeout(60)` | `setNetworkTimeout(const Duration(seconds: 60))` |
| `setAudioBuffer(0.2)` | `setAudioBuffer(const Duration(milliseconds: 200))` |
| `setCacheSecs(30)` | _Folded into_ `setCache(CacheSettings(secs: ...))` |
| `setCachePauseWait(1)` | _Folded into_ `setCache(CacheSettings(pauseWait: ...))` |

### Cover art

```dart
// 0.0.9 — wrapper mutated Media.extras with PNG bytes
final art = playlist.medias[playlist.index].extras?['artBytes'] as Uint8List?;

// 0.1.0 — dedicated stream emits raw codec bytes per file load
player.stream.coverArtRaw.listen((raw) {
  if (raw == null) return;          // current file has no embedded art
  Image.memory(raw.bytes);          // PNG / JPEG / WEBP / BMP / GIF as embedded
  print('mime: ${raw.mimeType}');
});
```

### `PlayerConfiguration` slimmed

`audioClientName` is no longer a constructor parameter — set it
post-construction via `Player.setAudioClientName(...)`. The other
three fields (`autoPlay`, `initialVolume`, `logLevel`) are unchanged.

### What you gain in addition

- **Track inventory** (`state.tracks`, `state.currentAudioTrack`).
- **A-B loop** (`setAbLoopA` / `setAbLoopB` / `setAbLoopCount`).
- **Chapter navigation** (`state.chapters`, `state.currentChapter`,
  `setChapter`).
- **`MpvPlaybackState` aggregate stream**.
- **`MpvException`** for raw-API failures.
- **Path / URI introspection** (`state.path`, `filename`,
  `streamPath`, `streamOpenFilename`).
- **Tier 2 introspection** (`seeking`, `percentPos`, `cacheSpeed`,
  `cacheBufferingState`, `currentDemuxer`, `currentAo`,
  `demuxerStartTime`, `chapterMetadata`, `mpvVersion`,
  `ffmpegVersion`).

---


## Permissions

### Android

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
```

### iOS

Enable `Audio, AirPlay, and Picture in Picture` in **Signing & Capabilities**.

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

#### Building & Testing on Containers (WSL/Docker/Distrobox)
If you are developing or testing your Flutter app inside a headless Linux container, you will need to install both the core Flutter desktop build tools and the native audio server runtimes. Standard Linux desktops (like Ubuntu or Fedora) already have the audio backends pre-installed, but minimal containers require them to route sound to your host machine:

```bash
sudo apt update

# 1. Flutter desktop build essentials:
sudo apt install clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev

# 2. Audio backend runtimes & host routing (required to hear sound inside containers):
sudo apt install pipewire pipewire-pulse libasound2-dev libpulse-dev libpipewire-0.3-dev
```

> **Note on ALSA:** be aware that low-level hardware drivers like ALSA don't work inside containers. Use the PulseAudio or PipeWire backend for container testing.
> 
> **Note on WSL:** PipeWire and ALSA do not work on Windows Subsystem for Linux. You must use the PulseAudio backend to hear sound during development.
---

## Project Background

All the native bindings, isolate logic, and architectural patterns were implemented through the use of **Claude Code** and **Antigravity**, **Gemini** models were usedfor the UI. The goal was to build a low-level audio engine through organization and orchestration without necessarily being an expert.

---

## Funding

If you find this library useful and want to support its development, consider becoming a supporter on **Patreon**:

[![](https://img.shields.io/badge/Patreon-F96854?style=for-the-badge&logo=patreon&logoColor=white)](https://www.patreon.com/cw/ales_drnz)

---

*Developed by Alessandro Di Ronza*
