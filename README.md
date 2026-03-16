# mpv_audio_kit

#### Audio engine for Flutter & Dart.

[![](https://img.shields.io/pub/v/mpv_audio_kit.svg)](https://pub.dev/packages/mpv_audio_kit)
[![](https://img.shields.io/badge/license-BSD--3--Clause-blue.svg)](LICENSE)
[![](https://img.shields.io/badge/libmpv-v0.41.0-orange.svg)]()

`mpv_audio_kit` is an audio library built on the latest version of `libmpv` (v0.41.0). It provides a dedicated background event loop, extensive DSP capabilities, and granular control over the audio pipeline, making it ideal for audio applications.

---

## Why did I build this?

Many existing Flutter audio libraries are either outdated or too restrictive, often hiding the native engine's power behind oversimplified abstractions.

This project was born out of two main needs:
1. **Unlocking Jellyfin's full potential**: For audio streaming, supporting `.m3u8` (HLS) is essential. Jellyfin uses HLS for transcoding, and having a modern `libmpv` core (v0.41.0+) ensures that **precise seeking** works flawlessly during transcoded streams.
2. **Total control for technical users**: This library doesn't gatekeep features; it exposes the native engine so technical users can tune buffers, network timeouts, and DSP filters exactly how they need, without any limitations.

---

## Installation

Add `mpv_audio_kit` to your `pubspec.yaml`:

```yaml
dependencies:
  mpv_audio_kit: ^0.0.1+8
```

### Platform Requirements

*   **Android**: SDK 24 (Android 7.0) or above.
*   **iOS**: iOS 13.0 or above.
*   **macOS**: 10.14 or above (Apple Silicon).
*   **Windows**: Windows 10 or above.
*   **Linux**: Ubuntu 22.04 or above.

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
    *   [2. Media & Playlists](#2-media--playlists)
    *   [3. Advanced Playback Control](#3-advanced-playback-control)
    *   [4. Audio Quality & DSP](#4-audio-quality--dsp)
    *   [5. Network & Caching](#5-network--caching)
    *   [6. Primitive API & Raw Access](#6-primitive-api--raw-access)
    *   [7. States & Streams](#7-states--streams)
*   [Permissions & Background Playback](#permissions--background-playback)
*   [Project Background](#project-background)
*   [Credits](#credits)

---

## Visuals

The following images demonstrate the example app included in the `example/` directory. This application serves as a reference music player for testing the various features and capabilities of mpv.

| Screen | Description |
| :--- | :--- |
| ![Playback Interface](https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/playback_interface.png) | **Playback Interface**<br>UI with real-time metadata extraction and cover art processing. |
| ![Queue Management](https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/queue_management.png) | **Queue Management**<br>Live playlist control with support for adding, removing tracks. |
| ![Audio Engine](https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/audio_engine.png) | **Audio Engine (DSP & Filters)**<br>Feature-rich 10-band graphic equalizer, EBU R128 industry-standard loudness normalization, and real-time audio compression. |
| ![Routing & Hardware Tuning](https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/routing_tuning.png) | **Routing & Hardware Tuning**<br>Audio mode selection (WASAPI/ALSA/CoreAudio), device selection, and output format configuration. |
| ![Stream Lab](https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/stream_lab.png) | **Stream Lab**<br>Specialized testing environment for network streams, radio protocols, and custom HTTP headers. |
| ![Demuxer & Cache Control](https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/cache_control.png) | **Demuxer & Cache Control**<br>Granular control over network buffering, demuxer thread filling, and memory pool management. |
| ![System Infrastructure](https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/infrastructure.png) | **System Infrastructure**<br>Exclusive audio, Low-level timing adjustments, audio buffer sizes, and native engine configuration. |

---

## Features

- ⚡ **Async Event Loop**: `libmpv` events are processed in a background isolate.
- 🎵 **Gapless Playback**: Seamless audio transitions between tracks.
- ⚖️ **ReplayGain**: Industry-standard track & album normalization.
- 🎛️ **High-Fidelity Filters**: 10-band EQ, EBU R128 Normalization, Compression, Crossfeed.
- 📜 **Dynamic Playlist**: Add, remove, move, and replace tracks in real-time.
- ⚙️ **Audiophile Hardware**: Exclusive mode (WASAPI/ALSA/CoreAudio) and device switching.
- 🔍 **Metadata & Cover Art**: Native extraction of embedded covers and metadata tags.
- 🌐 **HTTP Headers**: Support for authenticated streams and custom User-Agents.
- 📦 **Caching & Buffering**: Fine-tuned control over network cache and thread-filling.

---

## Quick Start

```dart
import 'package:flutter/material.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

void main() => runApp(const MaterialApp(home: AudioPlayerScreen()));

class AudioPlayerScreen extends StatefulWidget {
  const AudioPlayerScreen({super.key});
  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  // 1. Initialize the Player
  late final Player player = Player();

  @override
  void initState() {
    super.initState();
    // 2. Load a track immediately
    player.open(Media('https://example.com/audio.mp3'));
  }

  @override
  void dispose() {
    // 3. Clean up native resources
    player.dispose();
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
The `Player` class coordinates with `libmpv` through a dedicated background isolate.

```dart
final player = Player(
  configuration: PlayerConfiguration(
    logLevel: 'info',          // Debugging log level
    initialVolume: 100.0,      // Pre-set startup volume
    autoPlay: true,            // Automatically start playing on 'open'
    audioClientName: 'my_app', // Identifier for the system mixer
  ),
);

// Always dispose to avoid native memory leaks
await player.dispose();
```

### 2. Media & Playlists
A `Media` object represents an audio source (URL, Local Path, Asset, or Content URI).

```dart
final media = Media(
  'https://cdn.example.com/stream.mp3',
  httpHeaders: { 'Authorization': 'token' }, // For restricted streams
  extras: { 'title': 'my_track', 'artist': 'my_artist' },   // Store custom metadata for the UI
);

await player.open(media); // Single track
await player.openPlaylist([media1, media2]); // Multiple tracks
```

#### Playlist Management
```dart
await player.next();              // Move to the next track
await player.previous();          // Move to the previous track
await player.jump(2);             // Jump to the 3rd track (0-indexed)
await player.remove(0);           // Remove the 1st track
await player.move(5, 0);          // Move track at index 5 to index 0
await player.setShuffle(true);    // Enable random playback order
await player.setPlaylistMode(PlaylistMode.loop); // Modes: single, loop, none
```

### 3. Advanced Playback Control
Beyond play/pause, `mpv_audio_kit` offers precise control over the audio pipeline.

```dart
await player.seek(Duration(seconds: 30));                 // Seek to absolute position
await player.seek(Duration(seconds: 10), relative: true); // Seek forward by 10s

await player.setRate(1.2);              // Set playback speed (e.g., 1.2x)
await player.setPitch(1.1);             // Change pitch without affecting speed
await player.setPitchCorrection(true);  // Maintain pitch during speed changes
await player.setAudioDelay(0.05);       // Offset audio by 50ms (e.g., for BT sync)
```

### 4. Audio Quality & DSP
Leverage built-in high-fidelity audio processing.

#### ReplayGain & Gapless
```dart
await player.setGaplessPlayback('yes'); // Enable seamless track transitions
await player.setReplayGain('track');    // Use track-based volume normalization
await player.setAudioExclusive(true);   // Direct hardware access (WASAPI/ALSA)
```

#### Audio Filters (FFmpeg/lavfi)
Replace or append to the filter chain at runtime.
```dart
await player.setAudioFilters([
  AudioFilter.equalizer([0, 0, 2, 4, 2, 0, -2, -4, -4, 0]), // Custom 10-band EQ
  AudioFilter.loudnorm(),   // Professional loudness normalization
  AudioFilter.crossfeed(),  // Reduced listening fatigue for headphones
  AudioFilter.compressor(threshold: -20, ratio: 4), // Dynamic range compression
]);
```

### 5. Network & Caching
Critical for radio apps and high-latency mobile networks.

```dart
await player.setCache('yes');         // Enable network caching
await player.setCacheSecs(60.0);      // Buffer 60 seconds of audio data
await player.setCachePause(true);     // Automatically pause on buffer depletion
await player.setCacheOnDisk(true);    // Allow overflow cache to spill to disk
await player.setNetworkTimeout(15.0); // Set TCP connection timeout limit
```

### 6. Primitive API & Raw Access
Direct control over the native engine via primitive values.

```dart
await player.setAudioSampleRate(192000);             // Set specific sample rate
player.setRawProperty('audio-samplerate', '96000');  // Direct property injection
print(player.state.audioSampleRate);                 // Read current engine value
```

### 7. States & Streams
Reactive property observation and synchronous state access.

```dart
player.stream.position.listen((pos) => print(pos));    // Observe real-time updates
player.stream.metadata.listen((meta) => print(meta));  // Track metadata changes
print(player.state.volume);                            // Synchronous property access
```

---

## Permissions & Background Playback

### **Android**
Update `AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
```

### **iOS**
Enable `Audio, AirPlay, and Picture in Picture` in **Signing & Capabilities**. 
Add to `Info.plist`:
```xml
<key>UIBackgroundModes</key>
<array>
  <string>audio</string>
</array>
```

---

## Project Background

All the native bindings, isolate logic, and architectural patterns were implemented through the use of **Claude Opus 4.6** and **Antigravity** in general, with **Gemini** models for the UI part. 

The goal was to build a low-level audio engine through organization and orchestration, without necessarily being a low-level bindings specialist.

---

## Credits
This project architecture is inspired by and includes native bridging logic from **media-kit** (by `alexmercerind` and `cillyvms`), specifically:
-   **NativeReferenceHolder**: Native memory management.
-   **AndroidHelper**: URI to file-descriptor mapping.

---

## Funding

If you find this library useful and want to support its development, consider becoming a supporter on **Patreon**:

[![](https://img.shields.io/badge/Patreon-F96854?style=for-the-badge&logo=patreon&logoColor=white)](https://www.patreon.com/cw/ales_drnz)

---
*Developed by Alessandro Di Ronza*
