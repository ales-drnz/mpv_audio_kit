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
  mpv_audio_kit: ^0.0.7
```

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
    *   [4. Playback Control](#4-playback-control)
        *   [4.1 Basic Controls](#41-basic-controls)
        *   [4.2 Seeking](#42-seeking)
        *   [4.3 Speed & Pitch](#43-speed--pitch)
        *   [4.4 Volume & Mute](#44-volume--mute)
        *   [4.5 Audio Delay](#45-audio-delay)
    *   [5. Audio Quality & DSP](#5-audio-quality--dsp)
        *   [5.1 Applying Filters](#51-applying-filters)
        *   [5.2 Equalizer](#52-equalizer)
        *   [5.3 EBU R128 Loudness Normalization](#53-ebu-r128-loudness-normalization)
        *   [5.4 Dynamic Range Compression](#54-dynamic-range-compression)
        *   [5.5 Crossfeed](#55-crossfeed)
        *   [5.6 Pitch & Tempo Shift](#56-pitch--tempo-shift)
        *   [5.7 Echo / Delay](#57-echo--delay)
        *   [5.8 Stereo Widening](#58-stereo-widening)
        *   [5.9 Crystalizer](#59-crystalizer)
        *   [5.10 Custom Filter](#510-custom-filter)
        *   [5.11 ReplayGain](#511-replaygain)
        *   [5.12 Gapless Playback](#512-gapless-playback)
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
        *   [7.1 Cache Control](#71-cache-control)
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
        *   [9.2 Playlist Streams](#92-playlist-streams)
        *   [9.3 Audio Hardware Streams](#93-audio-hardware-streams)
        *   [9.4 DSP & Filter Streams](#94-dsp--filter-streams)
        *   [9.5 Network Streams](#95-network-streams)
        *   [9.6 Complete State Snapshot](#96-complete-state-snapshot)
    *   [10. Raw API](#10-raw-api)
        *   [10.1 Read a Property](#101-read-a-property)
        *   [10.2 Write a Property](#102-write-a-property)
        *   [10.3 Send a Command](#103-send-a-command)
        *   [10.4 Log Injection](#104-log-injection)
    *   [11. Error Handling & Logging](#11-error-handling--logging)
        *   [11.1 Typed Error Stream](#111-typed-error-stream)
        *   [11.2 End File Stream](#112-end-file-stream)
        *   [11.3 Network State](#113-network-state)
        *   [11.4 Log Stream](#114-log-stream)
    *   [12. Hooks](#12-hooks)
        *   [12.1 Registering a Hook](#121-registering-a-hook)
        *   [12.2 Listening and Continuing](#122-listening-and-continuing)
        *   [12.3 HTTP Headers via Hook](#123-http-headers-via-hook)
        *   [12.4 Lazy URL Resolution](#124-lazy-url-resolution)
*   [Permissions](#permissions)
*   [Troubleshooting](#troubleshooting)
*   [Project Background](#project-background)
*   [Credits](#credits)
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

- ⚡ **Async Event Loop**: `libmpv` events are processed in a background isolate — the UI thread is never blocked.
- 🎵 **Gapless Playback**: Seamless audio transitions between tracks using mpv's native gapless pipeline.
- ⚖️ **ReplayGain**: Industry-standard track & album normalization, pre-amplification, and fallback gain.
- 🎛️ **High-Fidelity Filters**: 10-band EQ (ISO centers), EBU R128 loudness normalization, dynamic range compression, crossfeed, pitch/tempo shift, echo, stereo widening.
- 📜 **Dynamic Playlist**: Add, remove, move, and replace tracks at runtime without stopping playback.
- ⚙️ **Audiophile Hardware**: Exclusive mode (WASAPI/ALSA/CoreAudio), output device selection, sample rate and format forcing.
- 🔍 **Metadata & Cover Art**: Native extraction of embedded cover images and metadata tags.
- 🌐 **Network Streams**: HLS, RTSP, RTMP, SMB, SHOUTcast/Icecast, and any format libmpv supports — with native HTTP headers.
- 🪝 **Stream Hooks**: Intercept mpv's file-loading pipeline via `on_load` to lazily resolve URLs, redirect streams, or inject per-file headers.
- 📦 **Granular Caching**: Fine-tuned control over demuxer memory pool, disk overflow cache, and cache-pause behavior.
- 🔧 **Raw Access**: Read and write any mpv property directly, or send any mpv command.

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
        onPressed: () => player.playOrPause(),
        child: const Icon(Icons.play_arrow),
      ),
    );
  }
}
```

---

## Guide

### 1. Initialization & Lifecycle

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
  configuration: PlayerConfiguration(
    logLevel: 'info',       // mpv log verbosity: 'trace','debug','v','info','warn','error','fatal','no'
    initialVolume: 100.0,   // Volume at startup (0–100)
    autoPlay: true,         // Start playing automatically on open()
    audioClientName: 'my_app', // Name shown in system mixers (PulseAudio, PipeWire, etc.)
  ),
);
```

All `PlayerConfiguration` fields are optional. Their defaults are:

| Field | Default | Description |
| :--- | :--- | :--- |
| `autoPlay` | `false` | Whether `open()` starts playback immediately |
| `initialVolume` | `100.0` | Volume at startup |
| `logLevel` | `'warn'` | mpv log level forwarded to `player.stream.log` |
| `audioClientName` | `null` | Audio client name (falls back to `'mpv_audio_kit'`) |

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

| Scheme | Description |
| :--- | :--- |
| `https://` / `http://` | Network streams, CDN audio, radio |
| `file://` | Local files with absolute path |
| `asset:///` | Flutter assets bundled in the app |
| `content://` | Android content provider URIs (file picker, media store) |
| `rtsp://` | Real-Time Streaming Protocol |
| `rtmp://` | Real-Time Messaging Protocol (live streaming) |
| `smb2://` | SMB2/3 network shares (Samba/CIFS via libsmb2) |
| `hls://` / `m3u8` | HTTP Live Streaming (HLS), as used by Jellyfin transcoding |
| Any URL | libmpv accepts any scheme it has a protocol handler for |

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

Attach arbitrary data to a track. The player carries it through the playlist so your UI can access it without a separate lookup:

```dart
final media = Media(
  'https://cdn.example.com/track.mp3',
  extras: {
    'title': 'Track Title',
    'artist': 'Artist Name',
    'album': 'Album Name',
    'artUri': 'https://cdn.example.com/cover.jpg',
    'duration': Duration(minutes: 4, seconds: 12),
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
await player.openPlaylist([track1, track2, track3]);

// Start at a specific index
await player.openPlaylist([track1, track2, track3], index: 1);

// Override auto-play
await player.openPlaylist([track1, track2], play: false);
```

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
await player.setPlaylistMode(PlaylistMode.none);    // No repeat
await player.setPlaylistMode(PlaylistMode.single);  // Loop current track
await player.setPlaylistMode(PlaylistMode.loop);    // Loop entire playlist

// Shuffle
await player.setShuffle(true);   // Shuffle the queue
await player.setShuffle(false);  // Restore original order
```

---

### 4. Playback Control

#### 4.1 Basic Controls

```dart
await player.play();         // Start or resume
await player.pause();        // Pause
await player.playOrPause();  // Toggle
await player.stop();         // Stop and unload current file
```

#### 4.2 Seeking

```dart
// Seek to an absolute position
await player.seek(Duration(seconds: 30));

// Seek forward/backward relative to current position
await player.seek(Duration(seconds: 10), relative: true);
await player.seek(Duration(seconds: -5), relative: true);
```

mpv uses the `absolute` seek mode by default, which works correctly on all formats including HLS, providing precise seeking even during transcoded streams.

#### 4.3 Speed & Pitch

```dart
await player.setRate(1.5);             // 1.5× speed (0.01 – 100.0)
await player.setPitch(0.9);            // Lower pitch without affecting speed
await player.setPitchCorrection(true); // Pitch correction when changing rate
```

`setPitchCorrection` enables mpv's `scaletempo` algorithm, which adjusts playback speed while preserving the original pitch. Set it to `false` for "vinyl-speed" effects where pitch follows rate.

#### 4.4 Volume & Mute

```dart
await player.setVolume(80.0);   // 0–100 (values above 100 amplify)
await player.setMute(true);
await player.setMute(false);

await player.setVolumeMax(150.0);      // Raise the software volume ceiling
await player.setVolumeGain(6.0);       // Pre-amplify by +6 dB
```

#### 4.5 Audio Delay

```dart
// Shift audio forward by 50 ms (useful for Bluetooth A2DP sync)
await player.setAudioDelay(0.05);

// Shift backward by 200 ms
await player.setAudioDelay(-0.2);
```

---

### 5. Audio Quality & DSP

All filters in this section run in libmpv's `libavfilter` pipeline and work on **every platform**.

#### 5.1 Applying Filters

Pass a list of `AudioFilter` objects. The list **replaces** the entire filter chain atomically:

```dart
await player.setAudioFilters([
  AudioFilter.equalizer([0.0, 0.0, 2.0, 4.0, 2.0, 0.0, -2.0, -4.0, -4.0, 0.0]),
  AudioFilter.loudnorm(),
]);
```

Remove all filters:
```dart
await player.clearAudioFilters();
```

Append a single filter to the current chain without replacing it:
```dart
await player.addAudioFilter(AudioFilter.crossfeed());
```

#### 5.2 Equalizer

10-band graphic EQ using ISO standard center frequencies:
`31 Hz`, `63 Hz`, `125 Hz`, `250 Hz`, `500 Hz`, `1 kHz`, `2 kHz`, `4 kHz`, `8 kHz`, `16 kHz`.

Values are in **dB** — positive = boost, negative = cut.

```dart
// Flat (no processing)
AudioFilter.equalizer([0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0])

// Bass boost
AudioFilter.equalizer([4.0, 3.0, 2.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0])

// Vocal presence
AudioFilter.equalizer([0.0, 0.0, 0.0, -2.0, -2.0, 2.0, 3.0, 3.0, 1.0, 0.0])
```

> **Note:** `AudioFilter.equalizer` requires a `List<double>` of exactly 10 elements. Passing integer literals without the `.0` suffix will cause a compile error.

To track gain values in Dart state without touching mpv (e.g. while a slider is still being dragged), use `setEqualizerGains`. It only updates `player.state.equalizerGains` and emits on `player.stream.equalizerGains` — it does **not** apply anything to the engine. Call `setAudioFilters` to commit:

```dart
// Called on every slider drag — updates state, no mpv call
player.setEqualizerGains([0.0, 0.0, 3.0, 5.0, 3.0, 0.0, 0.0, 0.0, 0.0, 0.0]);

// Called on slider release — actually applies to mpv
await player.setAudioFilters([
  AudioFilter.equalizer(player.state.equalizerGains),
]);
```

#### 5.3 EBU R128 Loudness Normalization

Normalizes perceived loudness to a broadcast-standard target. Essential for consistent volume across mixed content (podcasts, radio streams, music libraries):

```dart
AudioFilter.loudnorm()  // Default: -16 LUFS target, -1.5 dBTP true-peak limit

// Custom targets
AudioFilter.loudnorm(
  integratedLoudness: -23.0,  // EBU R128 broadcast standard
  truePeak: -1.0,
  lra: 7.0,                   // Loudness range in LU
)
```

#### 5.4 Dynamic Range Compression

Reduces the difference between loud and quiet passages — useful for listening in noisy environments:

```dart
AudioFilter.compressor()  // Defaults: threshold -20 dB, ratio 4:1

AudioFilter.compressor(
  threshold: -18.0,  // Onset level in dB
  ratio: 3.0,        // Compression ratio (3:1)
  attack: 10.0,      // Attack time in ms
  release: 200.0,    // Release time in ms
)
```

#### 5.5 Crossfeed

Simulates speaker placement for headphone listening, reducing the artificial hard left/right stereo separation that causes listening fatigue on long sessions:

```dart
AudioFilter.crossfeed()
```

#### 5.6 Pitch & Tempo Shift

Independent pitch and tempo control.

```dart
AudioFilter.scaleTempo(pitch: 1.0594, tempo: 1.0)  // Raise pitch by one semitone
AudioFilter.scaleTempo(pitch: 1.0, tempo: 0.75)    // Slow down to 75% without changing pitch
```

#### 5.7 Echo / Delay

```dart
AudioFilter.echo(delay: 300, falloff: 0.3)  // 300 ms echo, 30% falloff
```

#### 5.8 Stereo Widening

```dart
AudioFilter.extraStereo(m: 2.5)  // 2.5× stereo expansion (1.0 = no change, 0.0 = mono)
```

#### 5.9 Crystalizer

Emphasizes harmonic details and transients:

```dart
AudioFilter.crystalizer(intensity: 2.0)
```

#### 5.10 Custom Filter

Any valid mpv `--af` string:

```dart
AudioFilter.custom('lavfi-aresample=48000')
AudioFilter.custom('lavfi-agate=threshold=0.1:ratio=2')
```

#### 5.11 ReplayGain

ReplayGain reads per-track or per-album gain tags embedded by tools like `mp3gain`, `metaflac`, or any modern music tagger:

```dart
await player.setReplayGain('track');   // Use track-level gain (most common)
await player.setReplayGain('album');   // Use album-level gain (preserves relative track levels)
await player.setReplayGain('no');      // Disable

// Pre-amplification applied on top of the ReplayGain value
await player.setReplayGainPreamp(2.0);    // +2 dB pre-amp

// Gain applied to files that have no ReplayGain tags
await player.setReplayGainFallback(-6.0); // -6 dB fallback

// Allow the engine to clip (not recommended)
await player.setReplayGainClip(false);
```

#### 5.12 Gapless Playback

```dart
await player.setGaplessPlayback('yes');   // Full gapless — decode next track before current ends
await player.setGaplessPlayback('weak');  // Gapless only between compatible formats (default)
await player.setGaplessPlayback('no');    // Gap between all tracks
```

`'weak'` is the safest default: it provides gapless transitions between tracks of the same format (e.g. consecutive FLAC or MP3 files) without the risk of breaking on format changes.

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
await player.setAudioSampleRate(96000);   // 96 kHz
await player.setAudioSampleRate(192000);  // 192 kHz
await player.setAudioSampleRate(0);       // Auto (pass-through)

// Bit depth / sample format
await player.setAudioFormat('u8');     // 8-bit unsigned integer
await player.setAudioFormat('s16');    // 16-bit signed integer
await player.setAudioFormat('s32');    // 32-bit signed integer
await player.setAudioFormat('floatp');  // 32-bit floatp
await player.setAudioFormat('no');     // Reset to auto

// Channel layout
await player.setAudioChannels('stereo');       // Force stereo downmix
await player.setAudioChannels('5.1');          // 5.1 surround
await player.setAudioChannels('no');           // Reset to auto (default)
```

#### 6.5 S/PDIF Passthrough

Send compressed audio (AC3, DTS) directly to an AV receiver over S/PDIF or HDMI:

```dart
await player.setAudioSpdif('ac3,dts'); // Passthrough AC3 and DTS
await player.setAudioSpdif('');        // Disable passthrough
```

#### 6.6 Audio Client Name

The name shown in system audio mixers (PulseAudio, PipeWire, macOS Audio MIDI Setup):

```dart
await player.setAudioClientName('MyMusicApp');
```

#### 6.7 Audio Track Selection

For containers with multiple audio tracks (e.g. MKV, MP4 with language tracks), select which one to decode:

```dart
await player.setAudioTrack('1');   // First audio track
await player.setAudioTrack('2');   // Second audio track
await player.setAudioTrack('auto'); // Let mpv choose (default)
```

#### 6.8 Reload Audio

Force the audio output to reinitialize. Useful after changing hardware parameters like sample rate or format while playback is active:

```dart
await player.reloadAudio();
```

---

### 7. Network & Caching

#### 7.1 Cache Control

```dart
await player.setCache('yes');    // Always cache network streams
await player.setCache('no');     // Never cache (live streams, minimize latency)
await player.setCache('auto');   // Cache only seekable streams (default)

// How many seconds ahead to buffer
await player.setCacheSecs(30.0);

// Pause automatically when the cache runs dry, resume when refilled
await player.setCachePause(true);

// How many seconds must be buffered before auto-resuming after a stall
await player.setCachePauseWait(3.0);

// Spill overflow cache to temporary disk files
await player.setCacheOnDisk(true);
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
await player.setNetworkTimeout(10.0); // Fail after 10 seconds of no data
```

#### 7.4 TLS/SSL Verification

```dart
await player.setTlsVerify(false); // Disable for self-signed certificates
```

#### 7.5 Audio Buffer

The hardware audio buffer — lower values reduce latency, higher values improve stability under load:

```dart
await player.setAudioBuffer(0.1);  // 100 ms (low latency)
await player.setAudioBuffer(0.5);  // 500 ms (stable on slow hardware)
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
await player.setAoNullUntimed(true);
```

#### 7.8 Radio & Live Streams

For Icecast/SHOUTcast radio, disable caching and cache-pause to minimize latency:

```dart
await player.open(Media('https://stream.radio.example.com/live.mp3'));
await player.setCache('no');
await player.setCachePause(false);
await player.setNetworkTimeout(10.0);
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

When a track loads, mpv decodes its embedded cover art into a video frame (`audio-display = 'embedded-first'`). The library captures that frame with `screenshot-raw`, converts it to PNG (resized to a maximum of 800 px on the longest side), and attaches it to the `Media` extras as `artBytes` / `artUri`. This happens automatically — no extra calls needed.

```dart
player.stream.playlist.listen((playlist) {
  final current = playlist.medias[playlist.index];
  final artBytes = current.extras?['artBytes'] as Uint8List?;  // PNG bytes
  final artUri   = current.extras?['artUri']   as String?;     // data:image/png;base64,...
});
```

Three properties control when and how cover art is processed. All are fully observable via `player.state` and `player.stream`.

##### `audio-display`

Controls which image source mpv decodes into the video pipeline.

| Value | Behaviour |
|-------|-----------|
| `'embedded-first'` | Display cover art, preferring embedded images over external files. **Required for automatic cover extraction.** mpv default. |
| `'external-first'` | Display cover art, preferring external files over embedded images. |
| `'no'` | Disable video/cover-art display entirely — no video pipeline overhead. Use this when your app reads artwork out-of-band (e.g. via `metadata_god` or a tag library). |

```dart
// Default — embedded art decoded and extracted automatically on load
await player.setAudioDisplay('embedded-first');

// Disable when you read artwork from file tags directly
await player.setAudioDisplay('no');

// React to changes
player.stream.audioDisplay.listen((mode) => print('audio-display: $mode'));
```

##### `cover-art-auto`

Controls whether mpv scans for an external cover art file next to the audio file (e.g. `cover.jpg`, `folder.jpg`).

| Value | Behaviour |
|-------|-----------|
| `'no'` | Disabled. Recommended for apps that manage artwork themselves. The library sets this by default; mpv's own default is `'exact'`. |
| `'exact'` | Load a file whose base name matches the audio file with an image extension (e.g. `song.flac` → `song.jpg`), plus names from `--cover-art-whitelist` (`cover`, `folder`, `album`, …). mpv default. |
| `'fuzzy'` | Load any file whose name *contains* the audio file's base name. |
| `'all'` | Load all image files in the same directory as the audio file. |

```dart
// Disabled by default — prevents unrelated images from loading
await player.setCoverArtAuto('no');

// Enable fuzzy scanning (e.g. for a local file player)
await player.setCoverArtAuto('fuzzy');

player.stream.coverArtAuto.listen((mode) => print('cover-art-auto: $mode'));
```

##### `image-display-duration`

How long (in seconds) the decoded cover frame is held as a displayable video frame after the file loads.

```dart
// 'inf' (default) — frame lives forever; required for automatic cover extraction
await player.setImageDisplayDuration('inf');

// '0' — frame is discarded immediately; saves memory when cover art is not needed
await player.setImageDisplayDuration('0');

// Any number of seconds
await player.setImageDisplayDuration('5');

player.stream.imageDisplayDuration.listen((d) => print('image-display-duration: $d'));
```

> **Tip — disabling the video pipeline entirely:** if your app reads artwork via a tag library (e.g. `metadata_god`) rather than through mpv, set both `audio-display = 'no'` and `cover-art-auto = 'no'`. mpv will skip video decoding altogether, reducing CPU and memory usage:
>
> ```dart
> await player.setAudioDisplay('no');
> await player.setCoverArtAuto('no');
> await player.setImageDisplayDuration('0');
> ```

---

### 9. State & Streams

`mpv_audio_kit` exposes all player state in two complementary ways:

- **`player.state`** — a synchronous, immutable snapshot of the current state. Safe to read from anywhere.
- **`player.stream`** — reactive streams that emit on every change. Use with `StreamBuilder` or `.listen()`.

#### 9.1 Core Streams

```dart
player.stream.playing.listen((isPlaying) { ... });   // bool
player.stream.position.listen((pos) { ... });         // Duration
player.stream.duration.listen((dur) { ... });         // Duration
player.stream.buffering.listen((isBuffering) { ... }); // bool
player.stream.buffer.listen((pos) { ... });           // Duration (absolute buffered position)
player.stream.bufferingPercentage.listen((pct) { ... }); // double (0.0–100.0)
player.stream.completed.listen((done) { ... });       // bool (true when track ends)
player.stream.volume.listen((vol) { ... });           // double
player.stream.mute.listen((isMuted) { ... });         // bool
player.stream.rate.listen((speed) { ... });              // double
player.stream.pitch.listen((p) { ... });                 // double
player.stream.pitchCorrection.listen((on) { ... });      // bool
player.stream.audioDelay.listen((secs) { ... });         // double
```

#### 9.2 Playlist Streams

```dart
player.stream.playlist.listen((pl) {
  print('${pl.medias.length} tracks, current index: ${pl.index}');
});
player.stream.playlistMode.listen((mode) { ... }); // PlaylistMode enum
player.stream.shuffle.listen((isShuffled) { ... }); // bool
```

#### 9.3 Audio Hardware Streams

```dart
player.stream.audioDevice.listen((device) { ... });    // AudioDevice (current)
player.stream.audioDevices.listen((list) { ... });     // List<AudioDevice> (all available)
player.stream.audioParams.listen((p) { ... });         // AudioParams (decoder output)
player.stream.audioOutParams.listen((p) { ... });      // AudioParams (hardware output)
player.stream.audioBitrate.listen((bps) { ... });      // double? (current bitrate)
```

`AudioParams` contains: `format`, `sampleRate`, `channels`, `channelCount`, `hrChannels`, `codec`, `codecName`.

#### 9.4 DSP & Filter Streams

```dart
player.stream.activeFilters.listen((filters) { ... });   // List<AudioFilter>
player.stream.equalizerGains.listen((gains) { ... });    // List<double> (10 bands)
player.stream.replayGainMode.listen((mode) { ... });     // String
player.stream.gaplessMode.listen((mode) { ... });        // String
```

#### 9.5 Network Streams

```dart
player.stream.cacheMode.listen((mode) { ... });          // String
player.stream.cacheSecs.listen((secs) { ... });          // double
player.stream.networkTimeout.listen((t) { ... });        // double
```

#### 9.6 Complete State Snapshot

```dart
final s = player.state;
print(s.playing);
print(s.position);
print(s.duration);
print(s.volume);
print(s.buffering);
print(s.buffer);
print(s.playlist.medias[s.playlist.index].uri);
print(s.metadata['title']);
print(s.audioSampleRate);
print(s.audioFormat);
print(s.audioChannels);
```

---

### 10. Raw API

For anything not covered by the typed API, you can access mpv directly.

#### 10.1 Read a Property

```dart
final String? value = player.getRawProperty('audio-codec');
final String? samplerate = player.getRawProperty('audio-params/samplerate');
```

#### 10.2 Write a Property

```dart
player.setRawProperty('audio-samplerate', '96000');
player.setRawProperty('audio-channels', 'stereo');
```

#### 10.3 Send a Command

```dart
player.sendRawCommand(['af', 'add', 'lavfi-aresample=48000']);
player.sendRawCommand(['playlist-shuffle']);
player.sendRawCommand(['ao-reload']);
```

Any command or property from the [mpv documentation](https://mpv.io/manual/master/) is accessible through these methods.

#### 10.4 Log Injection

You can inject your own messages into the player's log stream:

```dart
player.log('Loaded user playlist', level: 'info');
player.log('Cache miss — refetching segment', level: 'warn');
```

---

### 11. Error Handling & Logging

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

#### 11.4 Log Stream

```dart
player.stream.log.listen((entry) {
  // MpvLogEntry has: prefix (String), level (String), text (String)
  print('[${entry.level}] ${entry.prefix}: ${entry.text}');
});
```

Set `logLevel` in `PlayerConfiguration` to control verbosity. `'warn'` is appropriate for production; `'debug'` or `'v'` for development.

---

### 12. Hooks

Hooks intercept mpv's file-loading pipeline before a stream is opened. Use them to lazily resolve URLs, inject per-file HTTP headers, or redirect to a different source — without a local proxy server.

#### 12.1 Registering a Hook

Call `registerHook` **once** after creating the player (before any `open` call):

```dart
player.registerHook('on_load');
```

You can add a safety timeout — if `continueHook` isn't called within the given duration, the library auto-continues to prevent mpv from stalling indefinitely (e.g. due to an unhandled exception):

```dart
player.registerHook('on_load', timeout: const Duration(seconds: 10));
```

Common hook names:

| Name | When it fires |
| :--- | :--- |
| `on_load` | Before a stream is opened — can redirect the URL |
| `on_load_fail` | After a stream fails to open |
| `on_preloaded` | After the file is pre-loaded but before playback starts |

#### 12.2 Listening and Continuing

Subscribe to `player.stream.hook` and call `continueHook` when processing is done. **You must always call `continueHook`**, even on error — otherwise mpv stalls indefinitely:

```dart
player.stream.hook.listen((event) async {
  if (event.name == 'on_load') {
    final url = player.getRawProperty('stream-open-filename') ?? '';

    try {
      if (url.startsWith('my-scheme://')) {
        // Redirect to a real URL
        final resolved = await myResolver(url);
        player.setRawProperty('stream-open-filename', resolved.url);

        // Inject per-file HTTP headers (direct HTTP only — for HLS use URL query params)
        if (resolved.headers.isNotEmpty) {
          final headerString = resolved.headers.entries
              .map((e) => '${e.key}: ${e.value}')
              .join(',');
          player.setRawProperty(
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
await player.openPlaylist(medias);

// When mpv reaches each track, the hook resolves it on demand:
// on_load → myResolver("my-scheme://abc") → /decision + start.m3u8 URL
```

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

## Credits

This project architecture is inspired by and includes native bridging logic from **media-kit** (by `alexmercerind` and `cillyvms`), specifically:
- **NativeReferenceHolder**: Native memory management for Hot-Restart cleanup.
- **AndroidHelper**: URI to file-descriptor mapping for Android `content://` URIs.

---

## Funding

If you find this library useful and want to support its development, consider becoming a supporter on **Patreon**:

[![](https://img.shields.io/badge/Patreon-F96854?style=for-the-badge&logo=patreon&logoColor=white)](https://www.patreon.com/cw/ales_drnz)

---

*Developed by Alessandro Di Ronza*
