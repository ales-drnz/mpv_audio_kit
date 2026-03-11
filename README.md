# mpv_audio_kit

#### A high-performance, professional-grade audio engine for Flutter & Dart.

[![](https://img.shields.io/pub/v/mpv_audio_kit.svg)](https://pub.dev/packages/mpv_audio_kit)
[![](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![](https://img.shields.io/badge/libmpv-v0.41.0-orange.svg)]()

`mpv_audio_kit` is a specialized audio engine built on top of `libmpv`. It is designed for applications that require a robust audio-first pipeline, featuring a dedicated background event loop, extensive DSP capabilities, and fine-grained control over playback quality.

---

## Installation

Add `mpv_audio_kit` to your `pubspec.yaml`:

```yaml
dependencies:
  mpv_audio_kit: ^0.0.1
```

### Platform Requirements

*   **Android**: SDK 21 (Android 5.0) or above.
*   **iOS**: iOS 11.0 or above.
*   **macOS**: 10.15 or above.
*   **Windows**: Windows 10 (64-bit) or above.
*   **Linux**: Any modern distribution with `libmpv.so.2` installed.

---

## Platforms

| Platform  | Architecture | Device | Emulator | mpv version |
| :--- | :--- | :---: | :---: | :---: |
| **Android** | arm64, armv7, x64, x86 | ✅ | ✅ | v0.41.0 |
| **iOS** | arm64, x64 | ✅ | ✅ | v0.41.0 |
| **macOS** | arm64, x64 | ✅ | — | v0.41.0 |
| **Windows**| x64 | ✅ | — | v0.41.0 |
| **Linux** | x64 | ✅ | — | v0.41.0 |

---

## Features

- ✅ **Async Event Loop**: `libmpv` events are processed in a background Isolate, keeping the UI at 60/120 FPS.
- ✅ **Gapless Playback**: Seamless audio transitions between tracks.
- ✅ **ReplayGain**: Industry-standard track & album normalization.
- ✅ **High-Fidelity Filters**: 10-band EQ, EBU R128 Normalization, Compression.
- ✅ **Dynamic Playlist**: Add, remove, move, and replace tracks in real-time.
- ✅ **Audiophile Hardware**: Exclusive mode (WASAPI/ALSA/CoreAudio) and device switching.
- ✅ **Metadata & Extras**: Attach custom data to tracks and retrieve native audio parameters.
- ✅ **HTTP Headers**: Support for authenticated streams and custom User-Agents.
- ✅ **Caching & Buffering**: Fine-tuned control over network cache and thread-filling.

---

## TL;DR

A complete, copy-pasteable example of a simple audio player screen.

```dart
import 'package:flutter/material.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

void main() {
  runApp(const MaterialApp(home: AudioPlayerScreen()));
}

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
    // 2. Load a track
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
      appBar: AppBar(title: const Text('mpv_audio_kit')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Typed stream for position updates
            StreamBuilder<Duration>(
              stream: player.stream.position,
              builder: (context, snap) => Text(
                'Position: ${snap.data ?? Duration.zero}',
                style: const TextStyle(fontSize: 24),
              ),
            ),
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FloatingActionButton(
                  onPressed: () => player.play(),
                  child: const Icon(Icons.play_arrow),
                ),
                const SizedBox(width: 16),
                FloatingActionButton(
                  onPressed: () => player.pause(),
                  child: const Icon(Icons.pause),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## Guide

### Contents
- [Initialization](#initialization)
- [Create & Dispose](#create--dispose)
- [Managing Media](#managing-media)
- [Using Extras](#using-extras)
- [Using HTTP Headers](#using-http-headers)
- [Playback & Seek](#playback--seek)
- [Volume, Rate & Pitch](#volume-rate--pitch)
- [Playlist Control](#playlist-control)
- [Audio Quality (Gapless & ReplayGain)](#audio-quality-gapless--replaygain)
- [Audio Filters (EQ & Normalization)](#audio-filters-eq--normalization)
- [Event Subscriptions](#event-subscriptions)
- [Audio Device & Hardware Selection](#audio-device--hardware-selection)
- [Permissions](#permissions)
- [Architecture](#architecture)
- [Troubleshooting](#troubleshooting)

---

### Initialization

`mpv_audio_kit` is ready to use without global setup. However, it is recommended to manage your `Player` instances carefully within the widget lifecycle or a service.

### Create & Dispose

A `Player` instance manages its own native `libmpv` context and event isolate.

```dart
// Basic instance
final player = Player();

// Advanced configuration
final player = Player(
  configuration: PlayerConfiguration(
    logLevel: 'info',          // 'no', 'fatal', 'error', 'warn', 'info', 'v', 'debug', 'trace'
    initialVolume: 50.0,       // 0.0 to 100.0
    autoPlay: true,            // Automatically start when source is opened
    audioClientName: 'my_app', // Name used in system mixers
  ),
);
```

**Note:** It is extremely important to release the allocated resources back to the system:
```dart
await player.dispose();
```

### Managing Media

A `Playable` can be a single `Media` object or a `List<Media>`.

#### `Media`
```dart
final media = Media('https://server.com/audio.flac');
await player.open(media);
```

#### `Playlist`
```dart
final playlist = [
  Media('https://example.com/01.mp3'),
  Media('https://example.com/02.mp3'),
];
await player.openPlaylist(playlist, play: true);
```

---

### Using Extras

You can attach custom metadata to any `Media` object. This data is carried through the playlist and can be retrieved later to update your UI.

```dart
final media = Media(
  'https://cdn.example.com/podcast.mp3',
  extras: {
    'title': 'The Antigravity Podcast',
    'episode': 42,
    'art': 'https://cdn.example.com/cover.jpg',
  },
);

// Access it later from the playlist stream
player.stream.playlist.listen((playlist) {
  final current = playlist.medias[playlist.index];
  print(current.extras?['title']);
});
```

### Using HTTP Headers

Commonly required for authenticated streams or custom referrers.

```dart
final media = Media(
  'https://api.music.com/v1/stream/123',
  httpHeaders: {
    'Authorization': 'Bearer <your_token>',
    'X-Custom-Client': 'FlutterApp',
    'User-Agent': 'Mozilla/5.0',
  },
);
await player.open(media);
```

---

### Playback & Seek

Standard controls for the playback stream.

```dart
await player.play();
await player.pause();
await player.playOrPause();
await player.stop();

// Absolute Seek
await player.seek(Duration(minutes: 2, seconds: 15));

// Relative Seek (Forward 15 seconds)
await player.seek(Duration(seconds: 15), relative: true);

// Relative Seek (Backward 15 seconds)
await player.seek(Duration(seconds: -15), relative: true);
```

---

### Volume, Rate & Pitch

```dart
// Volume: 0.0 to 100.0. Values >100.0 provide software amplification.
await player.setVolume(85.0);

// Rate: Controls speed (0.5x to 2.0x).
await player.setRate(1.2);

// Pitch: Controls frequency (0.5 to 2.0). 
// Note: Requires setPitchCorrection(true) for best results.
await player.setPitch(1.1);
await player.setPitchCorrection(true);
```

---

### Playlist Control

Manage your active queue with frame-perfect precision.

```dart
// Navigation
await player.next();
await player.previous();
await player.jump(3); // Jump to index 3 (4th track)

// Modifications
await player.add(Media('path/to/new.wav'));
await player.remove(0); // Remove item at index 0
await player.move(5, 0); // Move item from pos 5 to the front
await player.replace(2, Media('path/to/replaced.mp3'));

// Loop & Shuffle
await player.setPlaylistMode(PlaylistMode.loop); // none, single, loop
await player.setShuffle(true);
```

---

### Audio Quality (Gapless & ReplayGain)

Optimized for professional listening environments.

#### Gapless Playback
Attempts to transition between tracks without any silence.
```dart
// 'weak': same format items transition seamlessly.
// 'yes': always attempt gapless transition.
await player.setGaplessPlayback(GaplessMode.weak);
```

#### ReplayGain (Normalization)
Standardizes volume across different files based on internal tags.
```dart
await player.setReplayGain(ReplayGainMode.track);
await player.setReplayGainPreamp(6.0); // Pre-gain boost in dB
await player.setReplayGainFallback(-3.0); // Fallback for tracks without tags
await player.setReplayGainClip(false); // Enable/Disable clipping protection
```

---

### Audio Filters (EQ & Normalization)

Direct access to FFmpeg's `lavfi` audio filter graph.

```dart
await player.setAudioFilters([
  // 10-Band Equalizer (dB gains for bands 31Hz to 16kHz)
  AudioFilter.equalizer([0, 0, 4, 6, 4, 0, -2, -4, -4, 0]),
  
  // EBU R128 industry-standard loudness normalization
  AudioFilter.loudnorm(),
  
  // Crossfeed (simulates speakers on headphones)
  AudioFilter.crossfeed(),
]);

// Clear all active filters
await player.clearAudioFilters();
```

---

### Event Subscriptions

The library provides a modern stream-based API for all state changes.

```dart
// BROADCAST STREAMS (player.stream.*)
player.stream.position.listen((pos) => ...);
player.stream.playing.listen((isPlaying) => ...);
player.stream.audioParams.listen((params) => print(params.sampleRate));
player.stream.log.listen((msg) => print(msg));

// SYNCHRONOUS SNAPSHOTS (player.state.*)
final currentVolume = player.state.volume;
final currentTrack = player.state.playlist.index;
```

---

### Audio Device & Hardware Selection

```dart
// Retrieve detected output devices
List<AudioDevice> devices = player.state.audioDevices;

// Select specific hardware output
await player.setAudioDevice(devices[1]);

// Enable Bit-Perfect Output (Exclusive Mode)
// Supported on Windows (WASAPI), Linux (ALSA), and macOS (CoreAudio).
await player.setAudioExclusive(true);
```

---

### Permissions

Ensure your application has the necessary permissions.

#### **Android**
Add these to `AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
```

#### **iOS**
Add `Background Modes` to your project and enabled `Audio` in `Info.plist`:
```xml
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
</array>
```

## Credits & Acknowledgements

This project owes a significant debt of gratitude to the pioneering architectural work of [media-kit](https://github.com/media-kit/media-kit). Specifically, several critical resilience implementations in `mpv_audio_kit` were inspired by or directly derived from the brilliant work of Hitesh Kumar Saini (`alexmercerind`) and `cillyvms`, including:
- **Native Memory Guardians** (`NativeReferenceHolder`) handling `libmpv` orphans during Flutter Hot-Restarts.
- **Android Content / Asset URI Resolvers** (`AndroidHelper`) bridging the Android Java scope into raw native file descriptors.

Their codebase is phenomenal, and `mpv_audio_kit` stands on the shoulders of those giants to deliver rock-solid audio production builds.

---
*Developed by Antigravity AI*
