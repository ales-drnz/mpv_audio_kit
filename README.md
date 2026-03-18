# mpv_audio_kit

#### Audio engine for Flutter & Dart.

[![](https://img.shields.io/pub/v/mpv_audio_kit.svg)](https://pub.dev/packages/mpv_audio_kit)
[![](https://img.shields.io/badge/license-BSD--3--Clause-blue.svg)](LICENSE)
[![](https://img.shields.io/badge/libmpv-v0.41.0-orange.svg)]()

`mpv_audio_kit` is an audio library built on `libmpv` v0.41.0 — the engine behind the mpv media player. It provides a dedicated background event loop, a complete DSP pipeline, and direct access to every mpv property, making it the most capable audio library available for Flutter.

---

## Why did I build this?

Many existing Flutter audio libraries are either built on an old version of mpv or they are simply too restrictive, hiding some cool features relative to audio processing. So I made this project to provide a more powerful and flexible audio library for Flutter and solve two main needs:

- **Unlocking Jellyfin's full potential**: For audio streaming, supporting `.m3u8` (HLS) is essential. Jellyfin uses HLS for transcoding, this ensures that seeking works flawlessly during transcoded tracks.
- **Total control for technical users**: This library doesn't limit features; it exposes the native engine so technical users can tune buffers, network timeouts, and DSP filters exactly how they want.

---

## Installation

Add `mpv_audio_kit` to your `pubspec.yaml`:

```yaml
dependencies:
  mpv_audio_kit: ^0.0.2+2
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
    *   [2. Media Sources](#2-media-sources)
    *   [3. Playlist Management](#3-playlist-management)
    *   [4. Playback Control](#4-playback-control)
    *   [5. Audio Quality & DSP](#5-audio-quality--dsp)
    *   [6. Hardware & Routing](#6-hardware--routing)
    *   [7. Network & Caching](#7-network--caching)
    *   [8. Metadata & Cover Art](#8-metadata--cover-art)
    *   [9. State & Streams](#9-state--streams)
    *   [10. Raw API](#10-raw-api)
    *   [11. Error Handling & Logging](#11-error-handling--logging)
*   [Permissions](#permissions)
*   [Credits](#credits)

---

## Visuals

The following images demonstrate the example app included in the `example/` directory. This application serves as a reference music player for testing the various features and capabilities of mpv.

**Desktop**

<table width="100%">
  <tr>
    <td width="60%"><img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/desktop_player_console.png" width="100%"></td>
    <td align="left"><b>Player</b><br>Playback UI with cover art, metadata, and progress alongside pinned logs.</td>
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
    <td width="25%" align="left"><b>Player</b><br>Large cover art, metadata, and controls</td>
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
- 🌐 **Network Streams**: HLS, RTSP, RTMP, SHOUTcast/Icecast, and any format libmpv supports — with native HTTP headers.
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

#### Global Initialization

Call `MpvAudioKit.ensureInitialized()` **once at startup**, before creating any `Player` instance. This registers the native backend and cleans up any handles that leaked across a Flutter Hot-Restart (a common problem with FFI libraries on desktop).

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

#### Creating a Player

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

#### Disposing a Player

Always call `dispose()` to release native handles and audio device locks. On exclusive mode (WASAPI/ALSA), failing to dispose can leave the audio device locked to other applications.

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

#### Supported URI Schemes

| Scheme | Description |
| :--- | :--- |
| `https://` / `http://` | Network streams, CDN audio, radio |
| `file://` | Local files with absolute path |
| `asset:///` | Flutter assets bundled in the app |
| `content://` | Android content provider URIs (file picker, media store) |
| `rtsp://` | Real-Time Streaming Protocol |
| `rtmp://` | Real-Time Messaging Protocol (live streaming) |
| `hls://` / `m3u8` | HTTP Live Streaming (HLS), as used by Jellyfin transcoding |
| Any URL | libmpv accepts any scheme it has a protocol handler for |

#### HTTP Headers

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

#### Extras

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

#### Opening a Single Track

```dart
// Respects PlayerConfiguration.autoPlay
await player.open(media);

// Override auto-play for this call
await player.open(media, play: true);
await player.open(media, play: false); // Load but do not start
```

#### Opening Multiple Tracks

```dart
await player.openPlaylist([track1, track2, track3]);

// Start at a specific index
await player.openPlaylist([track1, track2, track3], index: 1);

// Override auto-play
await player.openPlaylist([track1, track2], play: false);
```

#### Modifying the Queue at Runtime

```dart
await player.add(newTrack);          // Append to end
await player.remove(0);              // Remove track at index 0
await player.move(5, 0);             // Move track from index 5 to index 0
await player.replace(2, newTrack);   // Replace track at index 2

await player.clearPlaylist();        // Remove all tracks
```

#### Navigation

```dart
await player.next();       // Skip to the next track
await player.previous();   // Skip to the previous track
await player.jump(2);      // Jump to track at index 2 (0-indexed)
```

#### Repeat & Shuffle

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

#### Basic Controls

```dart
await player.play();         // Start or resume
await player.pause();        // Pause
await player.playOrPause();  // Toggle
await player.stop();         // Stop and unload current file
```

#### Seeking

```dart
// Seek to an absolute position
await player.seek(Duration(seconds: 30));

// Seek forward/backward relative to current position
await player.seek(Duration(seconds: 10), relative: true);
await player.seek(Duration(seconds: -5), relative: true);
```

mpv uses the `absolute` seek mode by default, which works correctly on all formats including HLS, providing precise seeking even during transcoded streams.

#### Speed & Pitch

```dart
await player.setRate(1.5);             // 1.5× speed (0.01 – 100.0)
await player.setPitch(0.9);            // Lower pitch without affecting speed
await player.setPitchCorrection(true); // Pitch correction when changing rate
```

`setPitchCorrection` enables mpv's `scaletempo` algorithm, which adjusts playback speed while preserving the original pitch. Set it to `false` for "vinyl-speed" effects where pitch follows rate.

#### Volume & Mute

```dart
await player.setVolume(80.0);   // 0–100 (values above 100 amplify)
await player.setMute(true);
await player.setMute(false);

await player.setVolumeMax(150.0);      // Raise the software volume ceiling
await player.setVolumeGain(6.0);       // Pre-amplify by +6 dB
```

#### Audio Delay

```dart
// Shift audio forward by 50 ms (useful for Bluetooth A2DP sync)
await player.setAudioDelay(0.05);

// Shift backward by 200 ms
await player.setAudioDelay(-0.2);
```

---

### 5. Audio Quality & DSP

All filters in this section run in libmpv's `libavfilter` pipeline and work on **every platform** — including iOS and macOS where most Flutter libraries provide no DSP support.

#### Applying Filters

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

#### Equalizer

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

For real-time slider interaction (e.g. dragging an EQ band), use `setEqualizerGains` instead. It updates only the gain values without rebuilding the entire filter chain, and is synchronous:

```dart
player.setEqualizerGains([0.0, 0.0, 3.0, 5.0, 3.0, 0.0, 0.0, 0.0, 0.0, 0.0]);
```

#### EBU R128 Loudness Normalization

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

#### Dynamic Range Compression

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

#### Crossfeed

Simulates speaker placement for headphone listening, reducing the artificial hard left/right stereo separation that causes listening fatigue on long sessions:

```dart
AudioFilter.crossfeed()
```

#### Pitch & Tempo Shift (Rubberband)

Independent pitch and tempo control using the Rubberband library. Requires a Rubberband-enabled libmpv build:

```dart
AudioFilter.scaleTempo(pitch: 1.0594, tempo: 1.0)  // Raise pitch by one semitone
AudioFilter.scaleTempo(pitch: 1.0, tempo: 0.75)    // Slow down to 75% without changing pitch
```

#### Echo / Delay

```dart
AudioFilter.echo(delay: 300, falloff: 0.3)  // 300 ms echo, 30% falloff
```

#### Stereo Widening

```dart
AudioFilter.extraStereo(m: 2.5)  // 2.5× stereo expansion (1.0 = no change, 0.0 = mono)
```

#### Crystalizer

Emphasizes harmonic details and transients:

```dart
AudioFilter.crystalizer(intensity: 2.0)
```

#### Custom Filter

Any valid mpv `--af` string:

```dart
AudioFilter.custom('lavfi-aresample=48000')
AudioFilter.custom('lavfi-agate=threshold=0.1:ratio=2')
```

#### ReplayGain

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

#### Gapless Playback

```dart
await player.setGaplessPlayback('yes');   // Full gapless — decode next track before current ends
await player.setGaplessPlayback('weak');  // Gapless only between compatible formats (default)
await player.setGaplessPlayback('no');    // Gap between all tracks
```

`'weak'` is the safest default: it provides gapless transitions between tracks of the same format (e.g. consecutive FLAC or MP3 files) without the risk of breaking on format changes.

---

### 6. Hardware & Routing

#### Audio Output Driver

Select the native backend used for audio output:

```dart
await player.setAudioDriver('wasapi');    // Windows: exclusive/shared WASAPI
await player.setAudioDriver('coreaudio'); // macOS / iOS: CoreAudio
await player.setAudioDriver('pulse');     // Linux: PulseAudio
await player.setAudioDriver('alsa');      // Linux: ALSA (lower latency)
await player.setAudioDriver('pipewire');  // Linux: PipeWire
await player.setAudioDriver('auto');      // Let mpv choose (default)
```

#### Exclusive Mode

Bypasses the OS audio mixer and writes directly to the hardware. Eliminates software resampling and volume processing for bit-perfect output. Only available on WASAPI (Windows) and ALSA (Linux):

```dart
await player.setAudioExclusive(true);   // Request exclusive access
await player.setAudioExclusive(false);  // Release, return to shared mode
```

> Exclusive mode locks the audio device. Always call `player.dispose()` when done, or other apps will have no sound.

#### Device Selection

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

#### Output Format

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
await player.setAudioFormat('float');  // 32-bit float
await player.setAudioFormat('auto');   // Auto (default)

// Channel layout
await player.setAudioChannels('stereo');       // Force stereo downmix
await player.setAudioChannels('5.1');          // 5.1 surround
await player.setAudioChannels('auto');         // Pass-through (default)
```

#### S/PDIF Passthrough

Send compressed audio (AC3, DTS) directly to an AV receiver over S/PDIF or HDMI:

```dart
await player.setAudioSpdif('ac3,dts'); // Passthrough AC3 and DTS
await player.setAudioSpdif('');        // Disable passthrough
```

#### Audio Client Name

The name shown in system audio mixers (PulseAudio, PipeWire, macOS Audio MIDI Setup):

```dart
await player.setAudioClientName('MyMusicApp');
```

#### Audio Track Selection

For containers with multiple audio tracks (e.g. MKV, MP4 with language tracks), select which one to decode:

```dart
await player.setAudioTrack('1');   // First audio track
await player.setAudioTrack('2');   // Second audio track
await player.setAudioTrack('auto'); // Let mpv choose (default)
```

#### Reload Audio

Force the audio output to reinitialize. Useful after changing hardware parameters like sample rate or format while playback is active:

```dart
await player.reloadAudio();
```

---

### 7. Network & Caching

#### Cache Control

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

#### Demuxer Memory Pool

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

#### Network Timeout

```dart
await player.setNetworkTimeout(10.0); // Fail after 10 seconds of no data
```

#### TLS/SSL Verification

```dart
await player.setTlsVerify(false); // Disable for self-signed certificates
```

#### Audio Buffer

The hardware audio buffer — lower values reduce latency, higher values improve stability under load:

```dart
await player.setAudioBuffer(0.1);  // 100 ms (low latency)
await player.setAudioBuffer(0.5);  // 500 ms (stable on slow hardware)
```

#### Stream Silence

Keep audio hardware active even when playback is paused, to eliminate click/pop on resume:

```dart
await player.setStreamSilence(true);
```

#### Untimed Null Output

When using the `null` audio driver (e.g. for server-side processing or testing without a sound device), this makes the null output run as fast as possible instead of at real time:

```dart
await player.setAoNullUntimed(true);
```

#### Radio & Live Streams

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

#### Metadata Tags

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

#### Cover Art

mpv_audio_kit extracts embedded cover art from audio files automatically. When a track loads, the cover is extracted via the `screenshot-raw` command, converted to PNG, and attached to the `Media` object in `player.state.playlist`.

```dart
player.stream.playlist.listen((playlist) {
  final current = playlist.medias[playlist.index];
  final artBytes = current.extras?['artBytes'] as Uint8List?;  // PNG bytes
  final artUri   = current.extras?['artUri']   as String?;     // data:image/png;base64,...
  // 'cover' is an alias for artUri, provided for compatibility
});
```

The extracted image is resized to a maximum of 800 px on the longest side before being delivered to the stream, to avoid excessive memory usage.

---

### 9. State & Streams

`mpv_audio_kit` exposes all player state in two complementary ways:

- **`player.state`** — a synchronous, immutable snapshot of the current state. Safe to read from anywhere.
- **`player.stream`** — reactive streams that emit on every change. Use with `StreamBuilder` or `.listen()`.

#### Core Streams

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

#### Playlist Streams

```dart
player.stream.playlist.listen((pl) {
  print('${pl.medias.length} tracks, current index: ${pl.index}');
});
player.stream.playlistMode.listen((mode) { ... }); // PlaylistMode enum
player.stream.shuffle.listen((isShuffled) { ... }); // bool
```

#### Audio Hardware Streams

```dart
player.stream.audioDevice.listen((device) { ... });    // AudioDevice (current)
player.stream.audioDevices.listen((list) { ... });     // List<AudioDevice> (all available)
player.stream.audioParams.listen((p) { ... });         // AudioParams (decoder output)
player.stream.audioOutParams.listen((p) { ... });      // AudioParams (hardware output)
player.stream.audioBitrate.listen((bps) { ... });      // double? (current bitrate)
```

`AudioParams` contains: `format`, `sampleRate`, `channels`, `channelCount`, `hrChannels`, `codec`, `codecName`.

#### DSP & Filter Streams

```dart
player.stream.activeFilters.listen((filters) { ... });   // List<AudioFilter>
player.stream.equalizerGains.listen((gains) { ... });    // List<double> (10 bands)
player.stream.replayGainMode.listen((mode) { ... });     // String
player.stream.gaplessMode.listen((mode) { ... });        // String
```

#### Network Streams

```dart
player.stream.cacheMode.listen((mode) { ... });          // String
player.stream.cacheSecs.listen((secs) { ... });          // double
player.stream.networkTimeout.listen((t) { ... });        // double
```

#### Complete State Snapshot

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

#### Read a Property

```dart
final String? value = player.getRawProperty('audio-codec');
final String? samplerate = player.getRawProperty('audio-params/samplerate');
```

#### Write a Property

```dart
player.setRawProperty('audio-samplerate', '96000');
player.setRawProperty('audio-channels', 'stereo');
```

#### Send a Command

```dart
player.sendRawCommand(['af', 'add', 'lavfi-aresample=48000']);
player.sendRawCommand(['playlist-shuffle']);
player.sendRawCommand(['ao-reload']);
```

Any command or property from the [mpv documentation](https://mpv.io/manual/master/) is accessible through these methods.

#### Log Injection

You can inject your own messages into the player's log stream:

```dart
player.log('Loaded user playlist', level: 'info');
player.log('Cache miss — refetching segment', level: 'warn');
```

---

### 11. Error Handling & Logging

#### Error Stream

```dart
player.stream.error.listen((message) {
  print('Engine error: $message');
});
```

Errors are also automatically generated from mpv log messages at the `error` or `fatal` level.

#### Log Stream

```dart
player.stream.log.listen((entry) {
  // MpvLogEntry has: prefix (String), level (String), text (String)
  print('[${entry.level}] ${entry.prefix}: ${entry.text}');
});
```

Set `logLevel` in `PlayerConfiguration` to control verbosity. `'warn'` is appropriate for production; `'debug'` or `'v'` for development.

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

## Project Background

All the native bindings, isolate logic, and architectural patterns were implemented through the use of **Claude Opus 4.6** and **Antigravity** in general, with **Gemini** models for the UI part. The goal was to build a low-level audio engine through organization and orchestration, without necessarily being a low-level bindings specialist.

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
