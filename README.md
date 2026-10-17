<p align="center">
<img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/header/banner.png" width="100%" alt="mpv_audio_kit, audio engine for Flutter built on mpv and ffmpeg, shown in the mpv_studio player">
</p>

# mpv_audio_kit

#### Audio engine for Flutter and Dart.

[![](https://img.shields.io/pub/v/mpv_audio_kit.svg?style=for-the-badge&logo=dart&logoColor=white)](https://pub.dev/packages/mpv_audio_kit)
[![](https://img.shields.io/badge/libmpv-v0.41.0-orange.svg?style=for-the-badge)]()
[![](https://img.shields.io/badge/license-BSD--3--Clause-blue.svg?style=for-the-badge)](LICENSE)
[![](https://img.shields.io/github/stars/ales-drnz/mpv_audio_kit?style=for-the-badge&logo=github&logoColor=white)](https://github.com/ales-drnz/mpv_audio_kit)
[![](https://img.shields.io/discord/1485588004029333516?style=for-the-badge&logo=discord&logoColor=white)](https://discord.gg/g2Qf4Mq9MP)
[![](https://img.shields.io/badge/Patreon-F96854?style=for-the-badge&logo=patreon&logoColor=white)](https://www.patreon.com/cw/ales_drnz)
[![](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-FFDD00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black)](https://www.buymeacoffee.com/ales.drnz)

---

## Made for your media library

mpv_audio_kit is the audio engine for Flutter apps that play from your own server. It talks to Jellyfin, Plex and Samba, and puts everything mpv and ffmpeg can do behind a typed Dart API.

<table>
<tr>
<td valign="middle" width="48"><img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/protocols/jellyfin.png" width="32" alt="Jellyfin"></td>
<td valign="middle"><b>Jellyfin</b><br>Stream your library direct or transcoded. Transcoded streams (<a href="#21-supported-uri-schemes">HLS</a>) stay seekable, so the seek bar works while the server converts the file.</td>
</tr>
<tr>
<td valign="middle"><img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/protocols/plex.png" width="32" alt="Plex"></td>
<td valign="middle"><b>Plex</b><br>Play tracks and playlists from Plex. Each track asks the server for its stream (<a href="#21-supported-uri-schemes">HLS</a> or <a href="#21-supported-uri-schemes">DASH</a>) only when it loads, through the <a href="#124-the-source-resolver">source resolver</a>, so a long queue starts at once and the server is never flooded with requests.</td>
</tr>
<tr>
<td valign="middle"><img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/protocols/samba.png" width="32" alt="Samba"></td>
<td valign="middle"><b>Samba</b><br>Play straight from a NAS or any network share over <a href="#21-supported-uri-schemes">SMB2 and SMB3</a>, as if the files were on the device.</td>
</tr>
<tr>
<td valign="middle"><img src="https://raw.githubusercontent.com/ales-drnz/svg-icons/main/png/wrench.png" width="32" alt=""></td>
<td valign="middle"><b>Total control</b><br>Tune <a href="#7-network-and-caching">the cache and the network</a>, shape the sound with <a href="#5-audio-effects">a chain of ffmpeg effects</a>, and watch it with <a href="#13-visualizer-waveform-and-loudness">a live spectrum, waveform and loudness meter</a>.</td>
</tr>
</table>

---

## Installation

Add `mpv_audio_kit` to your `pubspec.yaml`:

```yaml
dependencies:
  mpv_audio_kit: ^0.5.1
```

## Platform requirements

| Platform  | Minimum | Architecture | Size | Device | Emulator |
| :--- | :--- | :--- | :---: | :---: | :---:
| Android | 7.0 (SDK 24) | arm64-v8a, armeabi-v7a, x86_64 | 8.3, 8.2, 8.9 MB | Yes | Yes |
| iOS | 15.0 | arm64, x86_64 | 7.5, 8.0 MB | Yes | Yes |
| macOS | 12.0 | arm64, x86_64 | 7.5, 8.0 MB | Yes | - |
| Windows | 10 | arm64, x86_64 | 8.1, 9.1 MB | Yes | - |
| Linux | glibc 2.31 (Ubuntu 20.04, Debian 11) | aarch64, x86_64 | 8.8, 8.6 MB | Yes | - |

The package needs Dart 3.10 and Flutter 3.38, and Flutter 3.47.4 or later to build for iOS: older releases mark the bundled framework for an iOS version below the library's 15.0, which App Store validation rejects. On Linux, libmpv needs ALSA (`libasound.so.2`) and uses PipeWire (0.3.57 or later) or PulseAudio when installed.

---

## Contents

*   [Visuals](#visuals)
*   [Features](#features)
*   [Quick start](#quick-start)
*   [Guide](#guide)
    <details>
    <summary><a href="#1-initialization-and-lifecycle"><b>1. Initialization and lifecycle</b></a></summary>

    * [1.1 Global initialization](#11-global-initialization)
    * [1.2 Creating a player](#12-creating-a-player)
    * [1.3 Disposing a player](#13-disposing-a-player)

    </details>

    <details>
    <summary><a href="#2-media-sources"><b>2. Media sources</b></a></summary>

    * [2.1 Supported URI schemes](#21-supported-uri-schemes)
    * [2.2 HTTP headers](#22-http-headers)
    * [2.3 Extras](#23-extras)
    * [2.4 Demuxer options](#24-demuxer-options)
    * [2.5 Live PCM input](#25-live-pcm-input)

    </details>

    <details>
    <summary><a href="#3-playlist-management"><b>3. Playlist management</b></a></summary>

    * [3.1 Opening a single track](#31-opening-a-single-track)
    * [3.2 Opening multiple tracks](#32-opening-multiple-tracks)
    * [3.3 Modifying the queue at runtime](#33-modifying-the-queue-at-runtime)
    * [3.4 Navigation](#34-navigation)
    * [3.5 Repeat and shuffle](#35-repeat-and-shuffle)
    * [3.6 Chapter navigation](#36-chapter-navigation)

    </details>

    <details>
    <summary><a href="#4-playback-control"><b>4. Playback control</b></a></summary>

    * [4.1 Basic controls](#41-basic-controls)
    * [4.2 Seeking](#42-seeking)
    * [4.3 A-B loop](#43-a-b-loop)
    * [4.4 Speed and pitch](#44-speed-and-pitch)
    * [4.5 Volume and mute](#45-volume-and-mute)
    * [4.6 Audio delay](#46-audio-delay)
    * [4.7 Resume playback (watch later)](#47-resume-playback-watch-later)

    </details>

    <details>
    <summary><a href="#5-audio-effects"><b>5. Audio effects</b></a></summary>

    * [5.1 The effects chain](#51-the-effects-chain)
    * [5.2 Common effects: quick examples](#52-common-effects-quick-examples)
    * [5.3 Available effects](#53-available-effects)
    * [5.4 ReplayGain](#54-replaygain)
    * [5.5 Gapless playback](#55-gapless-playback)

    </details>

    <details>
    <summary><a href="#6-hardware-and-routing"><b>6. Hardware and routing</b></a></summary>

    * [6.1 Audio output driver](#61-audio-output-driver)
    * [6.2 Exclusive mode](#62-exclusive-mode)
    * [6.3 Device selection](#63-device-selection)
    * [6.4 Output format](#64-output-format)
    * [6.5 SPDIF passthrough](#65-spdif-passthrough)
    * [6.6 Audio client name](#66-audio-client-name)
    * [6.7 Audio track selection](#67-audio-track-selection)
    * [6.8 Reload audio](#68-reload-audio)
    * [6.9 Media role](#69-media-role)
    * [6.10 Audio buffer](#610-audio-buffer)
    * [6.11 Audio stream silence](#611-audio-stream-silence)
    * [6.12 Untimed null output](#612-untimed-null-output)

    </details>

    <details>
    <summary><a href="#7-network-and-caching"><b>7. Network and caching</b></a></summary>

    * [7.1 Cache configuration](#71-cache-configuration)
    * [7.2 Demuxer memory pool](#72-demuxer-memory-pool)
    * [7.3 Network timeout](#73-network-timeout)
    * [7.4 TLS and SSL verification](#74-tls-and-ssl-verification)
    * [7.5 Proxy and cookies](#75-proxy-and-cookies)
    * [7.6 Radio and live streams](#76-radio-and-live-streams)
    * [7.7 Throttling CDNs and chunked requests](#77-throttling-cdns-and-chunked-requests)
    * [7.8 Monitoring the cache and the network](#78-monitoring-the-cache-and-the-network)

    </details>

    <details>
    <summary><a href="#8-metadata-and-cover-art"><b>8. Metadata and cover art</b></a></summary>

    * [8.1 Metadata tags](#81-metadata-tags)
    * [8.2 Cover art](#82-cover-art)

    </details>

    <details>
    <summary><a href="#9-state-and-streams"><b>9. State and streams</b></a></summary>

    * [9.1 Playback state](#91-playback-state)
    * [9.2 State snapshot](#92-state-snapshot)
    * [9.3 Core streams](#93-core-streams)
    * [9.4 Playlist and track streams](#94-playlist-and-track-streams)
    * [9.5 Audio hardware streams](#95-audio-hardware-streams)
    * [9.6 Effects streams](#96-effects-streams)
    * [9.7 Network and cache streams](#97-network-and-cache-streams)
    * [9.8 File metadata and path streams](#98-file-metadata-and-path-streams)
    * [9.9 Playback timing streams](#99-playback-timing-streams)
    * [9.10 A-B loop streams](#910-a-b-loop-streams)
    * [9.11 Cover art streams](#911-cover-art-streams)
    * [9.12 Runtime diagnostics](#912-runtime-diagnostics)
    * [9.13 Prefetch lifecycle stream](#913-prefetch-lifecycle-stream)
    * [9.14 Visualizer and analysis streams](#914-visualizer-and-analysis-streams)
    * [9.15 Media session streams](#915-media-session-streams)
    * [9.16 Event streams](#916-event-streams)

    </details>

    <details>
    <summary><a href="#10-raw-api"><b>10. Raw API</b></a></summary>

    * [10.1 Read a property](#101-read-a-property)
    * [10.2 Write a property](#102-write-a-property)
    * [10.3 Send a command](#103-send-a-command)

    </details>

    <details>
    <summary><a href="#11-error-handling-and-logging"><b>11. Error handling and logging</b></a></summary>

    * [11.1 Typed error stream](#111-typed-error-stream)
    * [11.2 End file stream](#112-end-file-stream)
    * [11.3 Audio output lifecycle](#113-audio-output-lifecycle)
    * [11.4 Log streams](#114-log-streams)
    * [11.5 Exceptions](#115-exceptions)

    </details>

    <details>
    <summary><a href="#12-hooks"><b>12. Hooks</b></a></summary>

    * [12.1 Registering a hook](#121-registering-a-hook)
    * [12.2 Listening and continuing](#122-listening-and-continuing)
    * [12.3 HTTP headers via hook](#123-http-headers-via-hook)
    * [12.4 The source resolver](#124-the-source-resolver)
    * [12.5 Lazy URL resolution](#125-lazy-url-resolution)

    </details>

    <details>
    <summary><a href="#13-visualizer-waveform-and-loudness"><b>13. Visualizer, waveform and loudness</b></a></summary>

    * [13.1 Subscribing to the spectrum stream](#131-subscribing-to-the-spectrum-stream)
    * [13.2 Configuring the pipeline](#132-configuring-the-pipeline)
    * [13.3 Raw PCM stream](#133-raw-pcm-stream)
    * [13.4 Per-filter PCM taps](#134-per-filter-pcm-taps)
    * [13.5 Waveform](#135-waveform)
    * [13.6 Loudness](#136-loudness)
    * [13.7 Live loudness meter](#137-live-loudness-meter)

    </details>

    <details>
    <summary><a href="#14-os-media-session"><b>14. OS media session</b></a></summary>

    * [14.1 Enabling the session](#141-enabling-the-session)
    * [14.2 Overriding metadata](#142-overriding-metadata)
    * [14.3 Artwork and privacy](#143-artwork-and-privacy)
    * [14.4 Reacting to OS commands](#144-reacting-to-os-commands)
    * [14.5 Capabilities, intervals and speeds](#145-capabilities-intervals-and-speeds)
    * [14.6 Audio interruptions](#146-audio-interruptions)
    * [14.7 App identity (desktop)](#147-app-identity-desktop)

    </details>
*   [Permissions](#permissions)
*   [Troubleshooting](#troubleshooting)
*   [Project background](#project-background)

---

## Visuals

<table>
<tr>
<td valign="middle" width="90"><img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/mpv_studio.png" width="70" alt="MPV Studio"></td>
<td valign="middle">The screenshots below come from <a href="https://github.com/ales-drnz/mpv_studio">MPV Studio</a>, a separate app built on <code>mpv_audio_kit</code>. The <code>example/</code> folder in this repository is a single-file demo.</td>
</tr>
</table>

#### Playback

<p align="center">
  <img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/playback.gif" width="100%">
</p>

#### Queue

<p align="center">
  <img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/queue.gif" width="100%">
</p>

#### Stream

<p align="center">
  <img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/stream.gif" width="100%">
</p>

#### Effects

<p align="center">
  <img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/effects.gif" width="100%">
</p>

#### Settings

<p align="center">
  <img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/settings.gif" width="100%">
</p>

#### Console

<p align="center">
  <img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/console.gif" width="100%">
</p>

---

## Features

<table>
<tr>
<td valign="middle" width="48"><img src="https://raw.githubusercontent.com/ales-drnz/svg-icons/main/png/zap.png" width="32"></td>
<td valign="middle" width="45%"><b>Non-blocking</b><br>mpv events run in a background isolate, so the UI thread stays free.</td>
<td valign="middle" width="48"><img src="https://raw.githubusercontent.com/ales-drnz/svg-icons/main/png/shield-check.png" width="32"></td>
<td valign="middle" width="45%"><b>Type-safe API</b><br>typed enums, sealed selectors and <code>*Effect</code> stages.</td>
</tr>
<tr>
<td valign="middle"><img src="https://raw.githubusercontent.com/ales-drnz/svg-icons/main/png/activity.png" width="32"></td>
<td valign="middle"><b>Reactive state</b><br>a synchronous <a href="#92-state-snapshot"><code>state</code></a> snapshot and <a href="#9-state-and-streams">more than 100 streams</a>.</td>
<td valign="middle"><img src="https://raw.githubusercontent.com/ales-drnz/svg-icons/main/png/music.png" width="32"></td>
<td valign="middle"><b>Gapless playback</b><br>track changes without a gap, with an observable <a href="#913-prefetch-lifecycle-stream">prefetch lifecycle</a>.</td>
</tr>
<tr>
<td valign="middle"><img src="https://raw.githubusercontent.com/ales-drnz/svg-icons/main/png/sliders-horizontal.png" width="32"></td>
<td valign="middle"><b>Effects chain</b><br>an ordered <a href="#5-audio-effects">list of typed effects</a>: 18-band graphic EQ, compressor, loudness, pitch and tempo, bass and treble, stereo width, headphone crossfeed, silence trim, and any lavfi filter as a raw stage.</td>
<td valign="middle"><img src="https://raw.githubusercontent.com/ales-drnz/svg-icons/main/png/audio-lines.png" width="32"></td>
<td valign="middle"><b>Visualizer</b><br>real-time <a href="#13-visualizer-waveform-and-loudness">FFT spectrum and PCM streams</a>, a waveform overview and loudness measurement.</td>
</tr>
<tr>
<td valign="middle"><img src="https://raw.githubusercontent.com/ales-drnz/svg-icons/main/png/scale.png" width="32"></td>
<td valign="middle"><b>ReplayGain</b><br>track and album gain, preamp and fallback gain.</td>
<td valign="middle"><img src="https://raw.githubusercontent.com/ales-drnz/svg-icons/main/png/list-plus.png" width="32"></td>
<td valign="middle"><b>Dynamic playlist</b><br>add, remove, move and replace entries during playback, plus <a href="#36-chapter-navigation">chapters</a> and <a href="#43-a-b-loop">A-B loop</a>.</td>
</tr>
<tr>
<td valign="middle"><img src="https://raw.githubusercontent.com/ales-drnz/svg-icons/main/png/layers.png" width="32"></td>
<td valign="middle"><b>Multi-track audio</b><br>typed <a href="#67-audio-track-selection">track selection</a> in containers with several audio tracks (MKV, MP4), with codec, language and gain for each track.</td>
<td valign="middle"><img src="https://raw.githubusercontent.com/ales-drnz/svg-icons/main/png/cpu.png" width="32"></td>
<td valign="middle"><b>Hardware control</b><br><a href="#62-exclusive-mode">exclusive mode</a>, <a href="#63-device-selection">device selection</a>, <a href="#65-spdif-passthrough">SPDIF passthrough</a>, <a href="#64-output-format">output sample rate and format</a>.</td>
</tr>
<tr>
<td valign="middle"><img src="https://raw.githubusercontent.com/ales-drnz/svg-icons/main/png/tag.png" width="32"></td>
<td valign="middle"><b>Metadata and cover art</b><br><a href="#81-metadata-tags">tags</a>, and <a href="#82-cover-art">embedded artwork</a> as raw bytes with a Flutter <code>ImageProvider</code>.</td>
<td valign="middle"><img src="https://raw.githubusercontent.com/ales-drnz/svg-icons/main/png/globe.png" width="32"></td>
<td valign="middle"><b>Network streams</b><br>HLS, DASH, SMB, HTTP and HTTPS.</td>
</tr>
<tr>
<td valign="middle"><img src="https://raw.githubusercontent.com/ales-drnz/svg-icons/main/png/package.png" width="32"></td>
<td valign="middle"><b>Cache control</b><br><a href="#71-cache-configuration"><code>CacheSettings</code></a> sets the cache size, where it is kept and the pause on an empty cache in one call.</td>
<td valign="middle"><img src="https://raw.githubusercontent.com/ales-drnz/svg-icons/main/png/webhook.png" width="32"></td>
<td valign="middle"><b>Hooks</b><br>run your code while a file loads, <a href="#12-hooks">prefetch</a> included, to resolve URLs, redirect or add headers.</td>
</tr>
<tr>
<td valign="middle"><img src="https://raw.githubusercontent.com/ales-drnz/svg-icons/main/png/triangle-alert.png" width="32"></td>
<td valign="middle"><b>Typed errors</b><br>a sealed <a href="#111-typed-error-stream"><code>PlayerError</code></a> type, plus streams for end-of-file events, audio output failures and logs.</td>
<td valign="middle"><img src="https://raw.githubusercontent.com/ales-drnz/svg-icons/main/png/terminal.png" width="32"></td>
<td valign="middle"><b>Raw access</b><br>read and write mpv properties and send commands, except writes to <code>af</code> and <code>pause</code>; a rejection throws <a href="#115-exceptions"><code>MpvCommandException</code></a>.</td>
</tr>
<tr>
<td valign="middle"><img src="https://raw.githubusercontent.com/ales-drnz/svg-icons/main/png/media-session.png" width="32"></td>
<td valign="middle"><b>OS media session</b><br>publish the player to the <a href="#14-os-media-session">system media controls</a>: Now Playing, Control Center and the lock screen on Apple, MPRIS on Linux, SMTC on Windows and the Android media notification.</td>
<td valign="middle"></td>
<td valign="middle"></td>
</tr>
</table>

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
        // `playing` flips during seeks and buffering, `playWhenReady` does not.
        onPressed: () =>
            player.state.playWhenReady ? player.pause() : player.play(),
        child: const Icon(Icons.play_arrow),
      ),
    );
  }
}
```

---

## Guide

The player lives on your main isolate and talks to libmpv without blocking it: commands go out asynchronously, and a background isolate brings events and state back.

<img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/diagrams/architecture.png" width="100%" alt="Architecture in four lanes: the Player on the main isolate calls libmpv directly with async calls, the event isolate blocks on mpv_wait_event and forwards events and state, and the platform plugin connects the media session to the OS media controls">

### 1. Initialization and lifecycle

<img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/diagrams/player_lifecycle.png" width="100%" alt="Player lifecycle: ensureInitialized once per app, then for each player Player, open, listen and control, dispose; open can be called again at any time">

#### 1.1 Global initialization

Call `MpvAudioKit.ensureInitialized()` once at startup, before you create a `Player`. It sets up the native side and releases the handles a hot restart left behind.

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
    logLevel: LogLevel.info,
    initialVolume: 100.0, // 0 to 100
    autoPlay: true,
  ),
);
```

All `PlayerConfiguration` fields are optional. Their defaults:

<details>
<summary><b>9 configuration fields</b> (click to expand)</summary>

| Field | Default | Description |
| :--- | :--- | :--- |
| `autoPlay` | `false` | Whether `open()` starts playback |
| `initialVolume` | `100.0` | Volume at startup |
| `logLevel` | `LogLevel.warn` | Lowest level that reaches `player.stream.log`: `off`, `fatal`, `error`, `warn`, `info`, `v`, `debug` or `trace` |
| `resumePlayback` | `true` | Restore the saved position when a file is opened again. Nothing is saved on its own: call `writeResumeConfig()` (see [4.7](#47-resume-playback-watch-later)) |
| `watchLaterDir` | `null` | Directory for resume points. mpv's default is often not writable on mobile |
| `forceSeekable` | `false` | Allow seeking within the cache on streams mpv reports as not seekable (direct HTTP or HLS audio) |
| `hlsBitrate` | `HlsBitrate.max` | Which variant mpv selects from an adaptive HLS playlist (`HlsBitrate.no`, `.min`, or `.max`). Use `.min` to save bandwidth on metered links. Change it later with `setHlsBitrate` |
| `normalizeDownmix` | `false` | Scale down surround audio downmixed to fewer channels so it cannot clip, at the cost of a quieter result |
| `demuxerCacheDir` | `null` | Directory for the disk cache of `CacheSettings.onDisk`. mpv's default is often not writable on mobile |

</details>

#### 1.3 Disposing a player

`dispose()` releases libmpv and the media session. Call it when you are done with the player.

```dart
await player.dispose();
```

---

### 2. Media sources

`Media` holds a URI plus optional data and HTTP options for that track.

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
| <img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/protocols/file.png" width="32" style="vertical-align: middle" alt="File"> | `file://` | Local files, by absolute path |
| <img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/protocols/flutter.png" width="32" style="vertical-align: middle" alt="Flutter"> | `asset:///` | Flutter assets bundled in the app |
| <img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/protocols/android.png" width="32" style="vertical-align: middle" alt="Android"> | `content://` | Android content provider URIs (file picker, media store) |

##### Streaming sources

|  | Scheme | Description |
| :---: | :--- | :--- |
| <img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/protocols/https.png" width="32" style="vertical-align: middle" alt="HTTPS"> | `https://`, `http://` | Files and live streams over HTTP |
| <img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/protocols/jellyfin.png" width="32" style="vertical-align: middle" alt="Jellyfin"> | `https://…/*.m3u8` | HTTP Live Streaming (HLS) manifest, as used by Jellyfin transcoding |
| <img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/protocols/plex.png" width="32" style="vertical-align: middle" alt="Plex"> | `https://…/*.mpd` | Dynamic Adaptive Streaming over HTTP (DASH) manifest, as used by Plex transcoding |
| <img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/protocols/samba.png" width="32" style="vertical-align: middle" alt="Samba"> | `smb2://` | SMB2 and SMB3 network shares |

#### 2.2 HTTP headers

`Media.httpHeaders` sends headers with every request for that entry, HLS segments included, with no local proxy. mpv gets them as options of that playlist entry, so they never reach other entries:

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

For a URL that has to be resolved or refreshed when the track opens, use
the [source resolver](#124-the-source-resolver).

#### 2.3 Extras

`extras` attaches your own data to a track. It stays with the entry in
the playlist, so the UI can read it back without a separate lookup.
Playback ignores it. The OS media session reads `title`, `artist`,
`album` and `art` (a cover URL) as a fallback for files without tags, see
[14.2](#142-overriding-metadata):

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

```dart
final extras = player.state.playlist.items[index].extras;
```

#### 2.4 Demuxer options

`Media.demuxerLavfOptions` passes options to ffmpeg's demuxer for that
entry only (mpv's `demuxer-lavf-o`). For example, the HLS demuxer forwards
`seg_format_options` to the demuxer of each segment:

```dart
final media = Media(
  'https://server/Audio/123/main.m3u8?…',
  demuxerLavfOptions: {
    'seg_format_options': 'advanced_editlist=0',
  },
);
```

Keys must not be empty, and values must not contain a comma.

#### 2.5 Live PCM input

A `PcmSource` plays raw PCM chunks while they arrive, such as speech
generated piece by piece or samples sent over a socket. There is no file,
no local server and no header: the chunks go straight to mpv.

```dart
final socket = await WebSocket.connect('wss://example.com/speech');
final source = await player.openPcmStream(
  const PcmFormat(sampleRate: 24000, channels: 1), // s16le by default
);
await source.addStream(
  socket.where((m) => m is List<int>).map(
    (m) => m is Uint8List ? m : Uint8List.fromList(m as List<int>),
  ),
);
await source.close();
```

- Playback starts up to about 0.2 s after the first chunk, or about 0.1 s
  with `lowLatency: true`, which halves the output buffer of that entry. It
  starts sooner when the input arrives faster than real time. A gap in the
  input adds up to one buffer of delay, which stays.
- `add` never blocks. `addStream` pauses its stream while more than
  `maxBuffered` (30 s by default) waits, and `ready` does the same for a
  loop of `add` calls.
- A chunk may end in the middle of a frame: the rest is joined to the next
  chunk.
- `close` plays out what is buffered, then the entry ends after its last
  sample (`completed`). `abort` cuts it at once: the player moves to the
  next entry, or stops at the last one. A source still queued leaves the
  playlist.
- `done` completes once the player has read everything, or when the
  source is aborted, or stopped: `stop`, `next`, another `open`, a removal
  from the playlist or a dispose.
- Encodings: `u8`, `s16le`, `s24le`, `s32le` and `f32le`, 1 to 8 channels.

A source plays once and cannot seek, and `state.duration` follows the
audio received so far. To queue several sources, create them with
`PcmSource.create` and pass `source.toMedia()` to `openAll` or `add`: each
starts when the previous one ends. The player keeps each queued source
while its entry is in the playlist, so the app need not. Prefetch skips
live entries: a queued source opens when its entry starts.

---

### 3. Playlist management

#### 3.1 Opening a single track

```dart
// Respects PlayerConfiguration.autoPlay
await player.open(media);

// Override auto-play for this call
await player.open(media, play: true);
await player.open(media, play: false); // Load but do not start

// Start 12 minutes in, e.g. where the app saved the position
await player.open(Media(path, start: const Duration(minutes: 12)));

// A 30 second preview from 1:00: the entry ends at 1:30
await player.open(Media(
  url,
  start: const Duration(minutes: 1),
  end: const Duration(minutes: 1, seconds: 30),
));
```

`Media.start` and `Media.end` work the same way with `openAll`, `add` and
`replace`, and hold each time the entry loads. An entry with an end
finishes there as at the end of the file, while `duration` stays the
length of the whole file.

#### 3.2 Opening multiple tracks

```dart
await player.openAll([track1, track2, track3]);

// Start at a specific index
await player.openAll([track1, track2, track3], index: 1);

// Override auto-play
await player.openAll([track1, track2], play: false);

// A playlist file or URL (.m3u, .m3u8, .pls, .cue), such as a list of
// radio stations: its entries fill player.stream.playlist. open() would
// keep it as a single entry.
await player.openPlaylistFile(Media('https://example.com/stations.m3u'));
```

#### 3.3 Modifying the queue at runtime

```dart
await player.add(newTrack);          // Append to end
await player.remove(0);              // Remove track at index 0
await player.move(5, 0);             // Move track from index 5 to index 0
await player.replace(2, newTrack);   // Replace track at index 2

// An index out of range throws RangeError.

await player.clearPlaylist();        // Remove all tracks (stops playback)
```

#### 3.4 Navigation

```dart
await player.next();              // Skip to the next track
await player.previous();          // Skip to the previous track

// Both return false when there is nowhere to go.
final moved = await player.next();
await player.jump(2);             // Jump to track at index 2 (0-indexed)

await player.next(force: true);   // Past the last entry: stop playback (returns true)
await player.nextPlaylist();      // Jump to the next source playlist
await player.previousPlaylist();  // Back to the previous source playlist
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

`Loop` sets mpv's `loop-file` and `loop-playlist` as one choice.
`player.stream.loop` follows it.

#### 3.6 Chapter navigation

For files with chapter markers, such as audiobooks and podcasts:

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

`Chapter` exposes `time` and an optional `title`. Chapter times count from the start of playback; add `state.demuxerStartTime` to get the source's own timestamps.

---

### 4. Playback control

#### 4.1 Basic controls

```dart
await player.play();    // Start or resume
await player.pause();   // Pause
await player.stop();    // Stop and unload current file

// Toggle on playWhenReady: playing flips during seeks and buffering.
player.state.playWhenReady ? await player.pause() : await player.play();
```

<img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/diagrams/play_when_ready.png" width="100%" alt="playWhenReady stays true through the load, a seek and a network stall, while playing waits; at the end of content playWhenReady drops and completed rises until a new track or a seek back">

#### 4.2 Seeking

```dart
// Seek to an absolute position
await player.seek(const Duration(seconds: 30));

// Seek forward or backward relative to current position
await player.seek(const Duration(seconds: 10), relative: true);
await player.seek(const Duration(seconds: -5), relative: true);

// Sample-accurate instead of keyframe seeking, slower on some formats
await player.seek(const Duration(seconds: 30), exact: true);

// Percentage-based seeking (for progress-bar scrubbing)
await player.seekToPercent(50); // jump to the half-way point (0 to 100)

// Back to where the last jump started (a seek, a chapter, an A-B loop)
await player.revertSeek();
```

#### 4.3 A-B loop

Loop between two points of the current track, for example to practice
a passage or replay a sentence. The points belong to that track: when it
ends or another one loads, they go back to `null`. The count stays.

```dart
// Set the A and B markers (null disables the marker)
await player.setAbLoopA(const Duration(seconds: 30));
await player.setAbLoopB(const Duration(seconds: 45));

// Jumps back to A after the first pass: 3 plays the section 4 times.
// null = infinite, 0 = off.
await player.setAbLoopCount(3);

// Jumps back to A still to come (null = infinite)
player.stream.remainingAbLoops.listen((n) => print('left: $n'));

// Disable
await player.setAbLoopA(null);
await player.setAbLoopB(null);
```

#### 4.4 Speed and pitch

```dart
await player.setRate(1.5);              // 0.01 to 100
await player.setPitch(0.9);             // Lower pitch, same speed
await player.setPitchCorrection(true);  // On by default
```

Pitch correction is on by default: at a rate other than 1.0, mpv adds
`scaletempo2` to keep the original pitch. With `setPitchCorrection(false)`
the pitch follows the speed.

`RubberbandEffect` in the effects chain changes pitch and tempo
separately (see [5.2](#52-common-effects-quick-examples)).

#### 4.5 Volume and mute

There are two volume controls: the soft volume, mpv's own gain, and the
system volume, the OS per-app mixer.

```dart
// Soft volume and mute, always available
await player.setVolume(80.0);     // 0 to 100 (values above 100 amplify)
await player.setMute(true);
await player.setMute(false);

await player.setVolumeMax(150.0); // Raise the software volume ceiling
await player.setVolumeGain(6.0);  // Decoder-side pre-amp, in dB

// Clamp the dB range setVolumeGain accepts (defaults -96 and +12)
await player.setVolumeGainMin(-60.0);
await player.setVolumeGainMax(6.0);
```

`setSystemVolume` and `setSystemMute` drive the OS per-app mixer (mpv's
`ao-volume` and `ao-mute`). When the driver has no such mixer the calls do
nothing, without throwing, and `state.systemVolume` and `state.systemMute`
stay `null`.

```dart
if (player.state.systemVolume != null) {        // the driver has a per-app mixer
  await player.setSystemVolume(70.0);
  await player.setSystemMute(false);
}
```

#### 4.6 Audio delay

```dart
// Shift audio forward by 50 ms (useful for Bluetooth A2DP sync)
await player.setAudioDelay(const Duration(milliseconds: 50));

// Shift backward by 200 ms
await player.setAudioDelay(const Duration(milliseconds: -200));
```

#### 4.7 Resume playback (watch later)

For audiobooks and podcasts, the player can save a resume point for the
current file and restore it the next time that file is opened. Only
audio-relevant properties are persisted (position, speed, pitch, volume,
mute, audio delay and the selected track). The effects chain is not: it
belongs to the app, which can keep one per file if it wants.

`PlayerConfiguration.resumePlayback` (default `true`), set when you
create the player, restores a saved point when the file is opened again.
The player never saves one on its own: call `writeResumeConfig()`, for
example when the app goes to the background or the user pauses. Point
`watchLaterDir` at an app-writable directory on mobile; the platform
default is often not writable.

When the app keeps the position itself, `Media.start` is enough, with no
watch later at all:

```dart
await player.open(Media(path, start: savedPosition));
```

Watch later is for when mpv saves the point. When both apply, `start`
wins over the saved position, and the other saved values (speed, volume
and so on) still apply. mpv deletes a resume point once a load used it.

```dart
final player = Player(
  configuration: const PlayerConfiguration(
    resumePlayback: true,                 // restore on reopen (default)
    watchLaterDir: '/path/to/app/support/watch_later',
  ),
);

// Save a resume point for the current file, e.g. on pause
await player.writeResumeConfig();

// Clear it: for the current file, or a specific one by filename
await player.deleteResumeConfig();
await player.deleteResumeConfig(filename: '/music/audiobook.m4b');
```

mpv keys a resume point by the name of the file. Give `deleteResumeConfig`
the URI you gave `open`: a `file://` or `asset://` URI stands for the path
the load passes to mpv. A URL whose token changes, such as an API key after
a new login, gets a new key each time; with a source resolver
([12.4](#124-the-source-resolver)) the key is the URI of the `Media`, which
stays the same. On Android a `content://` source has no resume point: it
plays from a file descriptor, whose number the system gives to other files
later. `writeResumeConfig()` writes nothing for it, and a point saved under
that number by an older version is deleted before the load.

---

### 5. Audio effects

Everything in this section runs as ffmpeg filters, the same on every
platform.

<img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/diagrams/effects_chain.png" width="100%" alt="Effects chain: the same waveform probed before and after the equalizer, after the compressor and after the volume, with the tap names that read each point">

#### 5.1 The effects chain

The effects chain is an ordered list of stages. Each filter has an
`XxxEffect` class (`EqualizerEffect`, `AcompressorEffect` and so on), all
subclasses of `AudioEffect`. Stages run in list order, a filter can appear
more than once, and one call applies the whole list:

```dart
// Replace the whole chain (presets, factory defaults, JSON restore):
Future<void> setAudioEffects(List<AudioEffect> effects);

// Change it through a mapper from the current list to the new one:
Future<void> updateAudioEffects(
  List<AudioEffect> Function(List<AudioEffect>) f,
);
```

```dart
await player.setAudioEffects([
  // +3 dB around 100 Hz, 50 Hz wide
  EqualizerEffect(frequency: 100, width: 50, widthType: EqualizerWidthType.h, gain: 3),
  // -2 dB around 8 kHz, 1 kHz wide
  EqualizerEffect(frequency: 8000, width: 1000, widthType: EqualizerWidthType.h, gain: -2),
  AcompressorEffect(threshold: 0.1, ratio: 4), // then compress
  AlimiterEffect(limit: 0.9),                  // and limit last
]);
```

Each effect carries an `enabled` flag, `true` by default. Setting it to
`false` keeps the stage in the list, with its settings, but leaves it
out of the chain until you turn it back on:

```dart
// Bypass every compressor without losing its settings
await player.updateAudioEffects((fx) => [
  for (final e in fx)
    e is AcompressorEffect ? e.copyWith(enabled: false) : e,
]);
```

Read the live chain synchronously, or follow it as a stream:

```dart
final fx = player.state.audioEffects;
final comp = fx.whereType<AcompressorEffect>().firstOrNull;
print('compressor: ${comp?.threshold}');

player.stream.audioEffects.listen((fx) => print('${fx.length} stages'));
```

A slider drag that only changes the parameters of a stage, keeping the
list's shape, is applied to the running filter graph in place, with no
audible rebuild. Adding, removing, reordering or toggling a stage
rebuilds the chain. Reset everything with:

```dart
await player.setAudioEffects(const []);
```

The chain owns mpv's `af` property, so `setRawProperty('af', ...)`
throws. For a filter or option form the typed effects do not cover, put a
`RawAudioEffect` in the list. It runs in order like any other stage:

```dart
await player.setAudioEffects(const [
  RawAudioEffect('lavfi-aeval=val(0)*0.5|val(1)*0.5'),
  AcompressorEffect(threshold: 0.1),
]);
```

#### 5.2 Common effects: quick examples

Some effects with typical settings. Every effect works the same way: a
class with a const constructor and `copyWith`, whose parameters are
ffmpeg's options in camelCase (`level_in` is `levelIn`).

```dart
await player.setAudioEffects(const [
  // Dynamic-range compressor
  AcompressorEffect(
    threshold: 0.1,    // linear, 0 to 1
    ratio: 4.0,
    attack: 20.0,      // ms
    release: 250.0,    // ms
  ),

  // EBU R128 loudness normalization
  LoudnormEffect(i: -16, tp: -1.5, lra: 11),

  // Pitch and tempo (librubberband)
  RubberbandEffect(
    pitch: 1.0594, tempo: 1.0,
    pitchq: RubberbandPitch.quality,
  ),

  // 18-band graphic EQ, bands keyed `1b` to `18b`
  SuperequalizerEffect(
    params: {'4b': 1.5, '5b': 2.0, '8b': 0.5, '13b': 1.0},
  ),

  // Bass and treble shelves
  BassEffect(gain: 4, frequency: 100),
  TrebleEffect(gain: -2, frequency: 3000),
]);
```

Parameters with a fixed set of choices, such as rubberband's pitch
quality or the equalizer's width type, are Dart enums. Every numeric
parameter has `static const` bounds and a default on its class
(`AcompressorEffect.thresholdMin`, `thresholdMax`, `thresholdDefault`)
for building sliders.

#### 5.3 Available effects

The library has 87 typed effects. Each row below is one class, named
after the filter with an `Effect` suffix (`acompressor` is
`AcompressorEffect`). For other `lavfi-*` filters, or to experiment, use
`RawAudioEffect`.

<details>
<summary><b>All effects</b> (click to expand)</summary>

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
| `loudnorm` | EBU R128 loudness normalization |
| `mcompand` | Multiband compander |
| `speechnorm` | Adaptive speech-loudness normalizer |

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
| `asetrate` | Change the sample rate tag, shifting pitch and speed together (varispeed) |
| `rubberband` | High-quality independent pitch and tempo |

##### Stereo, channels and spatial

| Effect | Description |
|---|---|
| `crossfeed` | Headphone crossfeed |
| `dialoguenhance` | Center-channel dialogue enhancement |
| `earwax` | Headphone listening enhancement |
| `extrastereo` | Increase the left-right difference signal |
| `haas` | Haas effect (precedence-based stereo widening) |
| `stereotools` | Stereo image tools |
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
| `aintegral` | Compute the integral of the signal |
| `afftdn` | FFT-based broadband noise reduction |
| `afwtdn` | Wavelet-based broadband noise reduction |
| `anlmdn` | Non-local-means denoiser |
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
| `aformat` | Constrain output format |

##### Advanced (mandatory parameter)

These five need a free-form value with no sensible default, so their constructors make it required. Without a valid value the filter fails to start.

| Effect | Description | Required |
|---|---|---|
| `chorus` | Chorus | `delays`, `decays`, `speeds`, `depths` |
| `pan` | Mix channels with explicit per-channel gains | `args` |
| `channelmap` | Remap input channels to new positions | `map` |
| `aeval` | Per-channel expression-based filter | `exprs` |
| `arnndn` | RNN-based speech denoiser | `model` (a `.rnnn` file) |

</details>

#### 5.4 ReplayGain

```dart
await player.setReplayGain(const ReplayGainSettings(
  mode: ReplayGain.track,     // .no, .track, .album
  preamp: 2.0,                // +2 dB on top of the RG value
  fallback: -6.0,             // -6 dB on files without RG tags
  clip: false,                // false = peak-limit; true = allow clipping
));

// Change one field
await player.setReplayGain(
  player.state.replayGain.copyWith(mode: ReplayGain.album),
);
```

#### 5.5 Gapless playback

```dart
await player.setGapless(Gapless.yes);   // Keep the output open, resample to the first track's format
await player.setGapless(Gapless.weak);  // Gapless only on compatible formats (default)
await player.setGapless(Gapless.no);    // Off
```

On network playlists, `setPrefetchPlaylist(true)` makes mpv open the next
entry before the current one ends, so the track change does not wait for
the network. The [prefetch lifecycle](#913-prefetch-lifecycle-stream)
shows its progress.

```dart
await player.setPrefetchPlaylist(true);
```

---

### 6. Hardware and routing

#### 6.1 Audio output driver

`setAudioDriver` picks the driver mpv uses for audio output:

```dart
await player.setAudioDriver('wasapi');    // Windows
await player.setAudioDriver('coreaudio'); // macOS
await player.setAudioDriver('audiounit'); // iOS
await player.setAudioDriver('aaudio');    // Android, also 'audiotrack' and 'opensles'
await player.setAudioDriver('pipewire');  // Linux, also 'pulse' and 'alsa'
await player.setAudioDriver('auto');      // mpv picks (default)
```

#### 6.2 Exclusive mode

Asks the driver for exclusive use of the device, so the system mixer does not resample the audio or apply its volume. WASAPI (Windows), CoreAudio (macOS), AAudio (Android) and PipeWire (Linux) honor it; other drivers ignore it. On iOS (AudioUnit) it only stops your audio from mixing with other apps:

```dart
await player.setAudioExclusive(true);
await player.setAudioExclusive(false);  // back to shared mode
```

While the player holds the device, other apps have no sound. Turn exclusive mode off or call `dispose()` when you are done.

#### 6.3 Device selection

```dart
// Available devices
player.stream.audioDevices.listen((devices) {
  for (final d in devices) {
    print('${d.name}: ${d.description}');
  }
});

// Switch to a specific device
final devices = player.state.audioDevices;
await player.setAudioDevice(devices.first);
```

mpv fills the list when the player starts. `name` is mpv's device id and `description` the label to show.

#### 6.4 Output format

Force the output sample rate, sample format or channel layout, for example to match what a DAC accepts:

```dart
// Sample rate
await player.setAudioSampleRate(0);       // Auto
await player.setAudioSampleRate(44100);   // 44.1 kHz (CD)
await player.setAudioSampleRate(48000);   // 48 kHz (DVD, broadcast)
await player.setAudioSampleRate(88200);   // 88.2 kHz (hi-res)
await player.setAudioSampleRate(96000);   // 96 kHz (hi-res)
await player.setAudioSampleRate(192000);  // 192 kHz (studio)
await player.setAudioSampleRate(384000);  // 384 kHz (DXD)

// Sample format
await player.setAudioFormat(Format.auto);          // mpv picks (default)
await player.setAudioFormat(Format.u8);            // 8-bit unsigned, interleaved
await player.setAudioFormat(Format.u8Planar);      // 8-bit unsigned, planar
await player.setAudioFormat(Format.s16);           // 16-bit signed, interleaved
await player.setAudioFormat(Format.s16Planar);     // 16-bit signed, planar
await player.setAudioFormat(Format.s32);           // 32-bit signed, interleaved
await player.setAudioFormat(Format.s32Planar);     // 32-bit signed, planar
await player.setAudioFormat(Format.s64);           // 64-bit signed, interleaved
await player.setAudioFormat(Format.s64Planar);     // 64-bit signed, planar
await player.setAudioFormat(Format.float32);       // 32-bit float, interleaved
await player.setAudioFormat(Format.float32Planar); // 32-bit float, planar
await player.setAudioFormat(Format.float64);       // 64-bit float, interleaved
await player.setAudioFormat(Format.float64Planar); // 64-bit float, planar

// Channel layout
await player.setAudioChannels(Channels.auto);             // whatever the device accepts, keeping the source layout when it can
await player.setAudioChannels(Channels.autoSafe);         // the system's preferred layout, or stereo when there is none

// 1 channel
await player.setAudioChannels(Channels.mono);             // mono
await player.setAudioChannels(Channels.oneZero);          // 1.0 (alias of mono)

// 2 channels
await player.setAudioChannels(Channels.stereo);           // stereo
await player.setAudioChannels(Channels.twoZero);          // 2.0 (alias of stereo)
await player.setAudioChannels(Channels.downmix);          // stereo, named for a downmix

// ...                                                    // ...

// 8 channels
await player.setAudioChannels(Channels.sevenOne);         // 7.1
await player.setAudioChannels(Channels.sevenOneAlsa);     // 7.1(alsa)
await player.setAudioChannels(Channels.sevenOneWide);     // 7.1(wide)
await player.setAudioChannels(Channels.sevenOneWideSide); // 7.1(wide-side)
await player.setAudioChannels(Channels.sevenOneTop);      // 7.1(top)
await player.setAudioChannels(Channels.sevenOneRear);     // 7.1(rear)
await player.setAudioChannels(Channels.octagonal);        // octagonal
await player.setAudioChannels(Channels.cube);             // cube

// Immersive
await player.setAudioChannels(Channels.hexadecagonal);    // hexadecagonal (16ch)
await player.setAudioChannels(Channels.surround222);      // 22.2 (NHK, ITU-R BS.2051 System H)

// Any other layout mpv accepts
await player.setAudioChannels(
  const Channels.custom('fl-fr-fc-bl-br-sl-sr-lfe'),
);
```

When you force a downmix, for example 5.1 to stereo, set
`PlayerConfiguration.normalizeDownmix: true` when you create the player,
so the result is scaled down and cannot clip.

#### 6.5 SPDIF passthrough

`setAudioSpdif` passes compressed audio (AC3, DTS, TrueHD and others)
through to an AV receiver over SPDIF or HDMI:

```dart
// Dolby and DTS-HD
await player.setAudioSpdif({Spdif.ac3, Spdif.eac3, Spdif.trueHd, Spdif.dtsHd});

// Dolby only
await player.setAudioSpdif({Spdif.ac3, Spdif.eac3, Spdif.trueHd});

// Off
await player.setAudioSpdif({});
```

#### 6.6 Audio client name

`setAudioClientName` sets the name system mixers show for the app:

```dart
await player.setAudioClientName('MyMusicApp');
```

#### 6.7 Audio track selection

For files with several audio tracks, such as an MKV or MP4 with one track
per language, `state.tracks` lists them and `stream.currentAudioTrack`
follows the selected one:

```dart
// List the audio tracks
for (final t in player.state.tracks.where((tr) => tr.type == 'audio')) {
  print('${t.id}: ${t.title ?? t.lang ?? "audio"} '
        '(${t.codec} ${t.sampleRate} Hz ${t.channelCount}ch)');
}

// Selected track
player.stream.currentAudioTrack.listen((track) {
  if (track == null) return;
  print('Now decoding track #${track.id}: ${track.title}');
});

// Switch by id
await player.setAudioTrack(const Track.id(2));

// Let mpv choose: the file's default or the first audio track
await player.setAudioTrack(Track.auto);

// No audio track
await player.setAudioTrack(Track.off);

// Add an external audio file as a track of the current file, then remove it
await player.addAudioTrack(Media('commentary.mka'), title: 'Commentary');
await player.removeAudioTrack(const Track.id(3));

// Look again for audio and cover files next to the current file
await player.rescanExternalFiles();
```

`MpvTrack` carries the codec, codec profile, decoder, sample rate,
channel count, ReplayGain tags, language, and the default and forced
flags. `external` and `externalFilename` mark a track loaded from a
separate file, and `image` and `albumArt` let a track picker skip
picture tracks.

#### 6.8 Reload audio

`reloadAudio` closes and reopens the audio output (mpv's `ao-reload`):

```dart
await player.reloadAudio();
```

#### 6.9 Media role

`setAudioMediaRole(true)` reports the stream as music. PulseAudio and
PipeWire use the role for routing and per-role volume, and so do the
`aaudio` and `audiotrack` drivers on Android. Other drivers ignore it.

```dart
await player.setAudioMediaRole(true);
```

#### 6.10 Audio buffer

`setAudioBuffer` sets the size of the audio output buffer. A smaller buffer lowers latency; a larger one copes better with load:

```dart
await player.setAudioBuffer(const Duration(milliseconds: 100));  // low latency
await player.setAudioBuffer(const Duration(milliseconds: 500));  // for slow hardware
```

#### 6.11 Audio stream silence

`setAudioStreamSilence(true)` keeps the device open while paused, sending silence, so resuming does not click or pop:

```dart
await player.setAudioStreamSilence(true);
```

On iOS the driver then never lets go of the device: after an interruption, such as a phone call or another app's audio, it stays suspended and playback cannot continue.

#### 6.12 Untimed null output

With the `null` driver, for example to process audio on a machine with no sound device, `setAudioNullUntimed(true)` makes it run as fast as possible instead of at real time. It also applies when mpv falls back to `null` because the device failed to open:

```dart
await player.setAudioNullUntimed(true);
```

---

### 7. Network and caching

#### 7.1 Cache configuration

`setCache` sets mpv's six cache options (`cache`, `cache-secs`,
`cache-on-disk`, `cache-pause`, `cache-pause-wait`, `cache-pause-initial`)
in one call:

```dart
await player.setCache(const CacheSettings(
  mode: Cache.yes,                     // .auto (default), .yes, .no
  secs: Duration(seconds: 30),         // how much to cache ahead of the playhead
  onDisk: true,                        // keep the cache in a file instead of memory
  pause: true,                         // pause when the cache runs dry
  pauseWait: Duration(seconds: 3),     // cached time needed to resume
  pauseInitial: true,                  // also wait before starting and after a seek
));

// Change one field
await player.setCache(
  player.state.cache.copyWith(secs: const Duration(seconds: 60)),
);

player.stream.cache.listen((cfg) => print('cache: ${cfg.mode} ${cfg.secs}'));
```

`pauseInitial` gives network sources a smoother start. With `onDisk`,
set `PlayerConfiguration.demuxerCacheDir` when you create the player:
mpv's default location is often not writable on mobile.

#### 7.2 Demuxer memory pool

The demuxer reads the container (MP4, MKV, Ogg) and hands its packets to the decoder. `setDemuxer` sets its three buffer options (`demuxer-max-bytes`, `demuxer-max-back-bytes`, `demuxer-readahead-secs`) in one call:

```dart
await player.setDemuxer(const DemuxerSettings(
  maxBytes: 50 * 1024 * 1024,          // ahead of the playhead, default 150 MiB
  maxBackBytes: 20 * 1024 * 1024,      // behind the playhead, default 50 MiB
  readahead: Duration(seconds: 5),     // default 1 s
));

// Change one field
await player.setDemuxer(
  player.state.demuxer.copyWith(maxBytes: 100 * 1024 * 1024),
);

player.stream.demuxer.listen((d) => print('demuxer: ${d.maxBytes} bytes'));
```

<img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/diagrams/demuxer_cache.png" width="100%" alt="The demuxer cache around the playhead: maxBackBytes behind it, maxBytes and CacheSettings.secs ahead of it, and CacheSettings.pause waiting until pauseWait is cached again">

For live radio, where you do not seek back, set the back buffer to zero to save memory:

```dart
await player.setDemuxer(player.state.demuxer.copyWith(maxBackBytes: 0));
```

#### 7.3 Network timeout

```dart
await player.setNetworkTimeout(const Duration(seconds: 10)); // give up after 10 s without data
```

#### 7.4 TLS and SSL verification

Certificate verification is off by default, as in mpv. Turn it on for
playback with `setTlsVerify`:

```dart
await player.setTlsVerify(true); // uses the CA roots built into libmpv

// Replace the built-in roots with your own bundle, e.g. a company CA
await player.setTlsCaFile('/path/to/corporate-ca.pem');
```

#### 7.5 Proxy and cookies

Both take effect from the next load:

```dart
await player.setHttpProxy('http://proxy.example:8080');  // empty string clears it
await player.setCookies(true);                           // mpv's cookie jar, off by default
```

#### 7.6 Radio and live streams

For live radio, turn off the cache and the cache pause to keep latency low:

```dart
await player.open(Media('https://stream.radio.example.com/live.mp3'));
await player.setCache(const CacheSettings(mode: Cache.no, pause: false));
await player.setNetworkTimeout(const Duration(seconds: 10));
```

HLS streams, such as Jellyfin's transcoded ones, work with the default cache settings:

```dart
await player.open(Media(
  'https://jellyfin.example.com/audio/stream.m3u8',
  httpHeaders: {'Authorization': 'MediaBrowser Token="..."'},
));
```

Two `PlayerConfiguration` fields, set when you create the player, affect streams:

```dart
final player = Player(
  configuration: const PlayerConfiguration(
    // Seek within the cache on streams mpv reports as not seekable
    forceSeekable: true,
    // Lowest-bitrate HLS variant, to save data (default .max)
    hlsBitrate: HlsBitrate.min,
  ),
);

// The HLS policy can change later too, from the next load.
await player.setHlsBitrate(HlsBitrate.max);
```

#### 7.7 Throttling CDNs and chunked requests

Some CDNs, YouTube's `googlevideo` audio among them, slow a single open-ended HTTP range request (the rest of the file) to a crawl. Playback starts fine but stalls after a seek, once the buffered audio runs out and the slow connection cannot refill it.

`Media.httpChunkSize` splits the download into bounded range requests, as yt-dlp's `--http-chunk-size` does. Each request stays under the CDN's limit and is served at full speed:

```dart
await player.open(Media(
  googlevideoUrl,
  httpChunkSize: 8 * 1024 * 1024, // 8 MiB
));
```

It applies to that track only. Leave it `null` (the default) for servers that do not throttle, such as Plex, Jellyfin or your own: one large request buffers fastest there. When set, it must be a positive byte count.

#### 7.8 Monitoring the cache and the network

`player.stream.demuxerCacheState` emits a `DemuxerCacheState` for
streaming sources: the buffered time ranges, the download rate, and the
eof-cached, bof-cached and underrun flags. It is empty for local files.
Draw `seekableRanges` as the buffered parts of a seek bar:

```dart
player.stream.demuxerCacheState.listen((cache) {
  for (final r in cache.seekableRanges) {
    print('buffered ${r.start} to ${r.end}');
  }
  if (cache.underrun) {
    // The cache ran dry: show a spinner
  }
});
```

`player.stream.pausedForCache` is `true` while playback waits for an empty cache to refill, the clearest sign of a network stall. `player.stream.demuxerViaNetwork` tells whether the current file comes over the network, which helps decide whether an error is likely a network one:

```dart
player.stream.pausedForCache.listen((paused) {
  if (paused) showBufferingIndicator();
});

player.stream.demuxerViaNetwork.listen((isNetwork) {
  print('Network stream: $isNetwork');
});
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
  print('Now playing: $title, $artist');
});

// Synchronous access
final meta = player.state.metadata;
```

mpv returns the keys in lowercase, whatever the tag format. Common keys: `title`, `artist`, `album`, `album_artist`, `date`, `track`, `disc`, `genre`, `comment`, `composer`.

#### 8.2 Cover art

<img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/diagrams/cover_art_flow.png" width="100%" alt="A picture embedded in the audio file reaches stream.coverArt on every load; cover.jpg in the folder, with setCoverArtAuto, only appears in state.tracks">

`player.state.coverArt` and `player.stream.coverArt` carry the embedded
cover as the original image bytes, with a few Flutter helpers:

```dart
// Current track's cover
final art = player.state.coverArt;
if (art != null) {
  print('Format: ${art.extension}, ${art.bytes.length} bytes');
}

// Emits on every file load, null when no cover is embedded
player.stream.coverArt.listen((art) {
  if (art != null) updateUi(art.image);
});
```

`CoverArt` has these members:

<details>
<summary><b>5 members</b> (click to expand)</summary>

| Member | Kind | Description |
| :--- | :--- | :--- |
| `bytes` | `final Uint8List` | Raw codec bytes |
| `mimeType` | `final String` | `'image/png'`, `'image/jpeg'`, `'image/webp'`, `'image/bmp'`, `'image/gif'` |
| `image` | getter `ImageProvider` | Ready to drop into Flutter `Image(image: …)` |
| `extension` | getter `String` | `'png'`, `'jpg'`, `'webp'`, `'bmp'`, `'gif'` |
| `isPng`, `isJpeg`, `isWebp`, `isBmp`, `isGif` | getter `bool` | MIME-type predicates |

</details>

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
      image: art.image,         // a MemoryImage of the bytes
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

- `stream.coverArt` emits on every file load, before playback starts:
  each playlist entry, and again when mpv reloads the same file.
- It emits `null` for a file without an embedded picture, so a UI bound
  to it clears the previous cover.
- `state.coverArt` holds the last value emitted.
- The bytes are the image as stored in the file, with no re-encoding.

##### External cover files

`setCoverArtAuto` makes mpv load an image sitting next to the audio
file as an extra track:

```dart
await player.setCoverArtAuto(Cover.no);     // library default (disabled)
await player.setCoverArtAuto(Cover.exact);  // same base name as the audio file, or cover.jpg, folder.jpg and the like
await player.setCoverArtAuto(Cover.fuzzy);  // also any image whose name contains the audio file's base name
await player.setCoverArtAuto(Cover.all);    // every image in the folder
```

The image does not reach `stream.coverArt`, which carries only embedded
pictures. Find it among the tracks and read the file yourself:

```dart
final path = player.state.tracks
    .where((t) => t.external && t.albumArt)
    .firstOrNull
    ?.externalFilename;
```

The library defaults to `no` (mpv's own default is `exact`) so
unrelated images can't sneak in.

---

### 9. State and streams

The player exposes its state in two ways:

- `player.state`: an immutable snapshot of the current state, read synchronously.
- `player.stream`: streams for `StreamBuilder` or `listen()`.

A state stream (`volume`, `position`, `playlist`, `playbackState`, `coverArt`, …) gives each new subscriber the current value first, then every change, so a `StreamBuilder` needs no `initialData`. To wait for the next change, skip the current value: `player.stream.volume.skip(1).first`. Event streams (`seekCompleted`, `endFile`, `error`, `log`, `internalLog`, `hook`, `mediaSessionCommands`, `fft`, `pcm`, `loudnessMeter`, taps) only deliver what happens after `listen()`.

In the stream tables below, a dash under Set with marks a read-only stream.

#### 9.1 Playback state

`player.stream.playbackState` combines `playing`, `buffering`,
`completed`, `pausedForCache` and `duration` into one `MpvPlaybackState`,
for a UI that shows a single indicator.

```dart
player.stream.playbackState.listen((phase) {
  switch (phase) {
    case MpvPlaybackState.idle:       // No file loaded
    case MpvPlaybackState.loading:    // File opening
    case MpvPlaybackState.buffering:  // Waiting for the network during playback
    case MpvPlaybackState.playing:    // Producing audio
    case MpvPlaybackState.paused:     // File loaded, audio paused
    case MpvPlaybackState.completed:  // Reached the end of the last track
  }
});
```

#### 9.2 State snapshot

`player.state` holds the current value of the state streams below, for
one-shot reads inside event handlers and `build()` methods. `playbackState`,
`prefetchState`, `prefetchCacheDuration`, `waveform` and `loudnessScan`
exist only as streams, and `state.tlsCaFile` has no stream.

```dart
final s = player.state;
print(s.playing);                                // bool
print(s.position);                               // Duration
print(s.duration);                               // Duration
print(s.volume);                                 // double
print(s.buffer);                                 // Duration
print(s.metadata['title']);                      // String?
print(s.audioParams.codec);                      // String?
print(s.audioEffects.whereType<AcompressorEffect>().firstOrNull?.threshold); // double?
print(s.cache.secs);                             // Duration
print(s.replayGain.preamp);                      // double
print(s.tracks.where((t) => t.type == 'audio')); // Iterable<MpvTrack>
print(s.chapters);                               // List<Chapter>
print(s.audioOutputState);                       // AudioOutputState
print(s.mpvVersion);                             // e.g. 'mpv v0.41.0+r17'
print(s.ffmpegVersion);                          // e.g. '8.1.1'

// index is -1 while openAll is still building the queue.
final i = s.playlist.index;
if (i >= 0 && i < s.playlist.items.length) {
  print(s.playlist.items[i].uri);                // String
}
```

#### 9.3 Core streams

| Stream | Type | Set with | Notes |
| :--- | :--- | :--- | :--- |
| `playWhenReady` | `bool` | `play`, `pause`, `open`, `stop` | Whether the user wants playback. Unchanged by seeks and buffering: bind the play-pause button to it, as the OS media controls do. |
| `playing` | `bool` | - | `true` only while audio is produced (mpv's `core-idle`, inverted). It flips during seeks and buffering: use it for a spinner. Audio is playing when `playWhenReady && playing`. |
| `completed` | `bool` | - | `true` once playback reaches the end of the last track in the queue, or of the only one. Stays `false` between tracks and while a loop is on; goes back to `false` when a new track starts or you seek back. |
| `eofReached` | `bool` | - | mpv's `eof-reached`; `true` while paused at the end of a file with `keep-open=yes`. |
| `position` | `Duration` | `seek` | Current position, updated about 30 times a second. |
| `duration` | `Duration` | - | Total duration of the current file; `Duration.zero` for live streams. |
| `seekCompleted` | `void` | - | Fires after each load or seek, once mpv is ready to play. Use it as the signal that the file is ready. |
| `buffering` | `bool` | - | `true` between `start-file` and `file-loaded`. |
| `buffer` | `Duration` | - | Absolute timestamp the demuxer has buffered up to. |
| `bufferDuration` | `Duration` | - | Headroom ahead of the playhead (`demuxer-cache-duration`). |
| `bufferingPercentage` | `double` (0-100) | - | Cache fill as a percentage of `state.cache.secs`, computed by the player. Near 0 with mpv's default `cache-secs` of 1000 hours: for a buffering indicator use `cacheBufferingState`, or `bufferDuration` against your own target. |
| `volume` | `double` | `setVolume` | 0-100; values above 100 amplify. |
| `mute` | `bool` | `setMute` |  |
| `rate` | `double` | `setRate` | Playback speed multiplier. |
| `pitch` | `double` | `setPitch` | Pitch multiplier. |
| `pitchCorrection` | `bool` | `setPitchCorrection` | Whether mpv keeps the pitch with `scaletempo2` when the rate changes. Default `true`. |
| `audioDelay` | `Duration` | `setAudioDelay` | Audio offset, rounded to the millisecond. |

#### 9.4 Playlist and track streams

| Stream | Type | Set with | Notes |
| :--- | :--- | :--- | :--- |
| `playlist` | `Playlist` | `open`, `openAll`, `add`, `remove`, `move`, `replace`, `clearPlaylist` |  |
| `loop` | `Loop` | `setLoop` |  |
| `shuffle` | `bool` | `setShuffle` |  |
| `prefetchPlaylist` | `bool` | `setPrefetchPlaylist` |  |
| `tracks` | `List<MpvTrack>` | - | Filled by the demuxer |
| `currentAudioTrack` | `MpvTrack?` | `setAudioTrack` |  |
| `chapters` | `List<Chapter>` | - | Filled by the demuxer |
| `currentChapter` | `int?` | `setChapter` |  |

#### 9.5 Audio hardware streams

| Stream | Type | Set with | Notes |
| :--- | :--- | :--- | :--- |
| `audioDevice` | `Device` | `setAudioDevice` |  |
| `audioDevices` | `List<Device>` | - |  |
| `audioParams` | `AudioParams` | - | From the decoder |
| `audioOutParams` | `AudioParams` | - | Sent to the output |
| `audioBitrate` | `double?` | - |  |
| `audioOutputState` | `AudioOutputState` | - | See [11.3](#113-audio-output-lifecycle) |
| `audioDriver` | `String` | `setAudioDriver` | Empty for the automatic choice |
| `audioExclusive` | `bool` | `setAudioExclusive` |  |
| `audioBuffer` | `Duration` | `setAudioBuffer` |  |
| `audioStreamSilence` | `bool` | `setAudioStreamSilence` |  |
| `audioNullUntimed` | `bool` | `setAudioNullUntimed` |  |
| `audioSpdif` | `Set<Spdif>` | `setAudioSpdif` |  |
| `volumeMax` | `double` | `setVolumeMax` |  |
| `volumeGain` | `double` | `setVolumeGain` |  |
| `volumeGainMin` | `double` | `setVolumeGainMin` |  |
| `volumeGainMax` | `double` | `setVolumeGainMax` |  |
| `systemVolume` | `double?` | `setSystemVolume` | `null` when the driver has no per-app mixer |
| `systemMute` | `bool?` | `setSystemMute` | `null` when the driver has no per-app mixer |
| `audioSampleRate` | `int` | `setAudioSampleRate` |  |
| `audioFormat` | `Format` | `setAudioFormat` |  |
| `audioChannels` | `Channels` | `setAudioChannels` |  |
| `audioClientName` | `String` | `setAudioClientName` |  |
| `audioMediaRole` | `bool` | `setAudioMediaRole` | Reports a "music" role to PulseAudio and PipeWire |

`AudioParams` carries: `format`, `sampleRate`, `channels`,
`channelCount`, `hrChannels`, `codec`, `codecName`.

#### 9.6 Effects streams

| Stream | Type | Set with | Notes |
| :--- | :--- | :--- | :--- |
| `audioEffects` | `List<AudioEffect>` | `setAudioEffects`, `updateAudioEffects` |  |
| `replayGain` | `ReplayGainSettings` | `setReplayGain` |  |
| `gapless` | `Gapless` | `setGapless` |  |

#### 9.7 Network and cache streams

| Stream | Type | Set with | Notes |
| :--- | :--- | :--- | :--- |
| `cache` | `CacheSettings` | `setCache` |  |
| `networkTimeout` | `Duration` | `setNetworkTimeout` |  |
| `tlsVerify` | `bool` | `setTlsVerify` |  |
| `hlsBitrate` | `HlsBitrate` | `setHlsBitrate` |  |
| `cookies` | `bool` | `setCookies` |  |
| `httpProxy` | `String` | `setHttpProxy` |  |
| `pausedForCache` | `bool` | - | `true` while paused for an empty cache |
| `demuxerViaNetwork` | `bool` | - |  |
| `demuxerCacheState` | `DemuxerCacheState` | - | See [7.8](#78-monitoring-the-cache-and-the-network) |
| `cacheSpeed` | `double` (bytes per second) | - |  |
| `cacheBufferingState` | `int` (0-100) | - |  |
| `demuxer` | `DemuxerSettings` | `setDemuxer` |  |

#### 9.8 File metadata and path streams

| Stream | Type | Set with | Notes |
| :--- | :--- | :--- | :--- |
| `metadata` | `Map<String, String>` | - | mpv's `metadata` |
| `mediaTitle` | `String` | - | mpv's `media-title`, falls back to filename when no `title` tag |
| `fileFormat` | `String` | - | mpv's `file-format` |
| `fileSize` | `int` | - | mpv's `file-size` |
| `path` | `String` | - | mpv's `path`, after redirects |
| `filename` | `String` | - | mpv's `filename`, no directory |
| `streamPath` | `String` | - | mpv's `stream-path`, URI as originally requested |
| `streamOpenFilename` | `String` | - | mpv's `stream-open-filename`, URI as opened, after redirects |
| `playlistPath` | `String` | - | mpv's `playlist-path`, source `.m3u` or `.pls`; empty when not loaded via a playlist |
| `seekable` | `bool` | - | mpv's `seekable` |
| `partiallySeekable` | `bool` | - | mpv's `partially-seekable`, HLS or DASH window |
| `demuxerIdle` | `bool` | - | mpv's `demuxer-cache-idle` |

#### 9.9 Playback timing streams

| Stream | Type | Set with | Notes |
| :--- | :--- | :--- | :--- |
| `audioPts` | `Duration` | - | mpv's `audio-pts`: position of the audio being heard, counting the output latency. Updates more often than [`position`](#93-core-streams). |
| `timeRemaining` | `Duration` | - | Time left in the file, ignoring the playback rate. |
| `playtimeRemaining` | `Duration` | - | Time left at the current rate: 60 s of file at 2.0x is 30 s. |

#### 9.10 A-B loop streams

| Stream | Type | Set with | Notes |
| :--- | :--- | :--- | :--- |
| `abLoopA` | `Duration?` (`null` = disabled) | `setAbLoopA` | Back to `null` when the file ends |
| `abLoopB` | `Duration?` (`null` = disabled) | `setAbLoopB` | Back to `null` when the file ends |
| `abLoopCount` | `int?` (`null` = infinite, `0` = off) | `setAbLoopCount` |  |
| `remainingAbLoops` | `int?` (`null` when infinite) | - | Counts down, from `abLoopCount` at each load |

#### 9.11 Cover art streams

| Stream | Type | Set with | Notes |
| :--- | :--- | :--- | :--- |
| `coverArt` | `CoverArt?` | - | Embedded pictures only |
| `coverArtAuto` | `Cover` | `setCoverArtAuto` |  |

#### 9.12 Runtime diagnostics

| Stream | Type | Set with | Notes |
| :--- | :--- | :--- | :--- |
| `seeking` | `bool` | - | mpv's `seeking`, `true` while a seek runs |
| `percentPos` | `double` (0-100) | - | mpv's `percent-pos` |
| `currentDemuxer` | `String` | - | mpv's `current-demuxer` |
| `currentAo` | `String` | - | mpv's `current-ao` |
| `demuxerStartTime` | `Duration` | - | mpv's `demuxer-start-time`, timestamp of the file's start |
| `chapterMetadata` | `Map<String, String>` | - | mpv's `chapter-metadata`, per-chapter tags |
| `mpvVersion` | `String` | - | mpv's `mpv-version` |
| `ffmpegVersion` | `String` | - | mpv's `ffmpeg-version` |

#### 9.13 Prefetch lifecycle stream

With `setPrefetchPlaylist(true)`, mpv opens the next playlist entry in
the background before the current one ends. `player.stream.prefetchState`
follows that work, so you can show progress or log a failed prefetch
without parsing log lines.

<img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/diagrams/mpv_prefetch_state.png" width="100%" alt="Prefetch timeline: while track A plays, track B opens in the background through loading and ready, plays from the prefetch as used, and a failed prefetch stays failed until the next loading">

```dart
player.stream.prefetchState.listen((state) {
  switch (state) {
    case PrefetchState.idle:
      // No background prefetch in progress.
    case PrefetchState.loading:
      // Opening the next entry and filling its cache
      showIndicator('Prefetching…');
    case PrefetchState.ready:
      // The next entry is open and cached up to cache-secs
      showIndicator('Ready');
    case PrefetchState.used:
      // The track just started from the prefetched stream.
      // Stays until the next `loading` or a cancel.
      showIndicator('Using prefetched');
    case PrefetchState.failed:
      // Opening the next entry failed (network error, unsupported
      // codec, on_load hook abort). Stays until the next `loading`.
      showIndicator('Prefetch failed');
  }
});
```

| State | When it fires | Notes |
| :--- | :--- | :--- |
| `idle` | Default; after a cancel or a dropped prefetch | |
| `loading` | Opening the next entry | Until the entry is open and cached |
| `ready` | Next entry open and cached | The track change will use it |
| `used` | Track transitioned via the prefetched stream | Stays until the next `loading` or a cancel |
| `failed` | Opening the next entry failed | Stays until the next `loading` |

For a progress bar, use `player.stream.prefetchCacheDuration`: how much
of the next entry is cached, as a `Duration`. Divide it by your cache
target; it is `Duration.zero` while nothing is being prefetched.

```dart
player.stream.prefetchCacheDuration.listen((buffered) {
  const target = Duration(seconds: 30); // your cache target
  final pct = (buffered.inMilliseconds / target.inMilliseconds)
      .clamp(0.0, 1.0);
  showPrefetchProgress(pct); // 0 to 1
});
```

#### 9.14 Visualizer and analysis streams

[Section 13](#13-visualizer-waveform-and-loudness) covers their settings
and examples.

| Stream | Type | Set with | Notes |
| :--- | :--- | :--- | :--- |
| `fft` | `FftFrame` | - | Smoothed FFT bands and raw bins, for a bar visualizer. |
| `pcm` | `PcmFrame` | - | Samples after the effects chain, for a waveform or a level meter. |
| `spectrum` | `SpectrumSettings` | `setSpectrum`, `updateSpectrum` | The FFT and smoothing settings. |
| `waveform` | `WaveformData?` | - | Envelope of the loaded track, `null` at each file load until the first bins. |
| `loudnessScan` | `LoudnessScan?` | - | Integrated loudness, range, sample and true peak of the loaded track, with its progress. |
| `loudnessMeter` | `Loudness` | - | Live momentary, short-term, integrated and range readings from an `Ebur128Effect`. |

#### 9.15 Media session streams

Two streams follow the OS media session, covered in
[section 14](#14-os-media-session).

| Stream | Type | Set with | Notes |
| :--- | :--- | :--- | :--- |
| `mediaSession` | `MediaSession?` | `setMediaSession` | The published session, or `null`. Same as `state.mediaSession`. |
| `mediaSessionCommands` | `MediaSessionCommand` | - | Commands from the OS (play, pause, next, seek and so on). The player applies them itself; the stream is for logging or extra handling. |

#### 9.16 Event streams

These deliver only what happens after `listen()`.

| Stream | Type | Notes |
| :--- | :--- | :--- |
| `seekCompleted` | `void` | After each load or seek, once mpv is ready to play. |
| `endFile` | `MpvFileEndedEvent` | Every file end, with its reason. See [11.2](#112-end-file-stream). |
| `error` | `PlayerError` | Load failures and mpv errors. See [11.1](#111-typed-error-stream). |
| `log`, `internalLog` | `MpvLogEntry` | mpv's log and the library's. See [11.4](#114-log-streams). |
| `hook` | `MpvHookEvent` | Hooks you registered. See [12.2](#122-listening-and-continuing). |

---

### 10. Raw API

For what the typed API does not cover, the raw API talks to mpv directly.

#### 10.1 Read a property

`getRawProperty` returns `null` when the property does not exist or the read fails.

```dart
final String? value = await player.getRawProperty('audio-codec');
final String? samplerate = await player.getRawProperty('audio-params/samplerate');
```

`getRawPropertyNode` returns the property as decoded maps, lists and
scalars instead of a string:

```dart
final tracks = await player.getRawPropertyNode('track-list') as List?;
```

#### 10.2 Write a property

`setRawProperty` throws `MpvCommandException` when mpv rejects the
write, for a typo or an out-of-range value. The exception carries
`name`, mpv's `code` and its `message`. Writes to `af` and
`pause`, also through `options/` and `file-local-options/`, throw
`ArgumentError`: use the effects chain and `play()` or `pause()` instead.

```dart
try {
  await player.setRawProperty('audio-samplerate', '96000');
  await player.setRawProperty('audio-channels', 'stereo');
} on MpvCommandException catch (e) {
  print('mpv rejected ${e.name}: ${e.message} (code=${e.code})');
}
```

#### 10.3 Send a command

`sendRawCommand` throws `MpvCommandException` the same way. `af` and
`af-command` throw `ArgumentError`, because the effects chain owns them.
So do the commands that write `af` or `pause` (`set`, `add`, `multiply`,
`cycle`, `cycle-values`, `change-list`, also through `options/` and
`file-local-options/`), and `loadfile` with `af` or `pause` in its
per-file options (`af-add`, `no-pause` and the like included). The check
guards against mistakes: it covers these commands, not every way mpv
offers to change a property.

```dart
await player.sendRawCommand(['playlist-shuffle']);
await player.sendRawCommand(['ao-reload']);
```

Other commands and properties from the
[mpv documentation](https://mpv.io/manual/master/) go through these
methods, except the writes to `af` and `pause` listed above.

Prefer the typed setters when they cover what you need: they update
`state` right away, while a raw write shows up only once mpv reports the
change.

---

### 11. Error handling and logging

#### 11.1 Typed error stream

`player.stream.error` emits `PlayerError`, a sealed class with two subtypes: `EndFileError` when a file stops because of an error, and `LogError` when mpv logs an error that may not stop playback:

<img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/diagrams/error_streams.png" width="100%" alt="Every end of file, log message and audio output change reaches its own stream; errors among them also reach stream.error as EndFileError or LogError, and library messages go to internalLog">

```dart
player.stream.error.listen((error) {
  switch (error) {
    case EndFileError():
      // The file stopped: network timeout, file not found and so on
      print('End-file error: reason=${error.reason}, code=${error.code}');
      print('  isLoadingError: ${error.isLoadingError}');
      print('  isAudioOutputError: ${error.isAudioOutputError}');
      print('  isFormatError: ${error.isFormatError}');
    case LogError():
      // mpv logged at error or fatal level; playback may go on
      print('Log error [${error.prefix}] ${error.level}: ${error.message}');
  }
});
```

`EndFileError` fields:
- `reason`: a `MpvEndFileReason` enum (`eof`, `stop`, `quit`, `error`, `redirect`)
- `code`: the raw mpv error code (e.g. `-13` for `MPV_ERROR_LOADING_FAILED`)
- `isLoadingError`: `true` for network or file loading failures
- `isAudioOutputError`: `true` when the audio output driver failed to initialize
- `isFormatError`: `true` when the file format is unrecognizable or has no audio

`LogError` fields:
- `prefix`: the mpv subsystem (e.g. `'ffmpeg'`, `'ao'`, `'demux'`)
- `level`: `LogLevel` (`LogLevel.error` or `LogLevel.fatal`)
- `text`: the raw log line from the mpv subsystem
- `message`: `'[prefix] level: text'`, with the level as mpv names it (`error`, `fatal`)

#### 11.2 End file stream

`player.stream.endFile` emits an `MpvFileEndedEvent` every time a file ends, not only on errors. mpv can report a dropped network connection as a normal end of file (`reason: eof`, no error code), so compare the position with the duration to tell them apart:

```dart
player.stream.endFile.listen((event) {
  if (event.reason == MpvEndFileReason.eof) {
    final pos = player.state.position;
    final dur = player.state.duration;
    if (dur > Duration.zero && (dur - pos).inSeconds > 5) {
      print('Ended early, probably a network drop');
    }
  }
});
```

`MpvFileEndedEvent` fields:
- `reason`: a `MpvEndFileReason` enum value
- `error`: mpv's error code, non-zero only when `reason` is `MpvEndFileReason.error`

#### 11.3 Audio output lifecycle

`player.stream.audioOutputState` follows the audio output as it opens,
plays and fails, for a "Connecting" indicator on slow devices or to
notice a silent player.

```dart
player.stream.audioOutputState.listen((state) {
  switch (state) {
    case AudioOutputState.closed:        // no audio output open
    case AudioOutputState.initializing:  // opening the device
    case AudioOutputState.active:        // open and playing
    case AudioOutputState.failed:        // the device could not be opened
  }
});
```

When no device can be opened, mpv usually falls back to the null output
instead: the state turns `active`, the position runs and nothing is heard.
`player.stream.error` emits a `LogError` once for each such opening, and
also when the state turns `failed`, so one error listener covers the
silent cases. A null output the app chose with `setAudioDriver('null')`
is no error.

#### 11.4 Log streams

`player.stream.log` carries mpv's messages and `player.stream.internalLog`
the library's own, so you can route them apart, for example `log` to a
debug overlay and `internalLog` to crash reporting.

```dart
// mpv: ffmpeg, demux, ao, cplayer and so on
player.stream.log.listen((entry) {
  if (entry.level == LogLevel.error || entry.level == LogLevel.fatal) {
    print('[${entry.level.mpvValue}] ${entry.prefix}: ${entry.text}');
  }
});

// The library: hook timeouts, resolver errors and so on, with the
// prefix 'mpv_audio_kit'
player.stream.internalLog.listen((entry) {
  print('[mpv_audio_kit:${entry.level.mpvValue}] ${entry.text}');
});
```

`PlayerConfiguration.logLevel` sets the starting level: `LogLevel.warn`
for release builds, `debug` or `v` while developing, `off` to silence mpv.
`setLogLevel` changes it later:

```dart
player.setLogLevel(LogLevel.debug);
player.setLogLevel(LogLevel.off);
```

#### 11.5 Exceptions

The streams above report what happens during playback. A call that
fails throws a `PlayerException`, a sealed class:

- `PlayerDisposedException`: the player was disposed.
- `PlayerInitException`: libmpv could not load or start. Every call on
  that player throws it, with the reason in `message`.
- `MpvCommandException`: libmpv rejected the request, for example a seek
  with no file loaded. Carries `name`, `code` and `message`.
- `SourceException`: a source could not be prepared before reaching
  libmpv, such as a missing `asset://` or an unreadable `content://`.

```dart
try {
  await player.seek(position);
} on PlayerException catch (e) {
  switch (e) {
    case PlayerDisposedException():
      break;
    case PlayerInitException(:final message):
      print('libmpv did not start: $message');
    case MpvCommandException(:final name, :final message):
      print('$name rejected: $message');
    case SourceException(:final uri):
      print('cannot open $uri');
  }
}
```

Invalid arguments are programming errors: they throw `ArgumentError` or
`RangeError` before anything is written to libmpv (a negative volume, a
playlist index out of range, checked against mpv's own playlist count).
`next()` and `previous()` return `false` when there is no track to go to,
without throwing.

---

### 12. Hooks

A hook pauses mpv at a step of loading a file, such as right before the stream opens, until your code says to go on. Use it to resolve a URL at the last moment, add headers for one file or switch to another source, with no local proxy:

<img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/diagrams/on_load_hook_sequence.png" width="100%" alt="on_load hook sequence in eight numbered steps between your code, the player and mpv, with mpv paused on the file until continueHook">

Headers alone need no hook: pass them in [`Media.httpHeaders`](#22-http-headers). To resolve URLs, [`setSourceResolver`](#124-the-source-resolver) does the hook wiring for you.

#### 12.1 Registering a hook

Call `registerHook` after creating the player, before the first `open`:

```dart
player.registerHook(Hook.load);
```

With a `timeout`, the library continues the hook itself if your code has not done so in time, for example after an unhandled exception:

```dart
player.registerHook(Hook.load, timeout: const Duration(seconds: 10));
```

The hooks mpv offers:

<details>
<summary><b>6 hooks</b> (click to expand)</summary>

| Hook | When it fires |
| :--- | :--- |
| `Hook.beforeStartFile` | Before any work on the file begins |
| `Hook.load` | Before the stream opens. Change the URL or add headers for this file |
| `Hook.loadFail` | After the stream failed to open. Try a fallback URL |
| `Hook.preloaded` | File open, before tracks are selected and the decoder starts |
| `Hook.unload` | Before the file closes. Clean up what belongs to it |
| `Hook.afterEndFile` | After the file ended and was unloaded |

</details>

Hooks fire during prefetch too: when mpv opens the next entry in advance, `on_load` runs for it, so a custom scheme such as `plex-transcode://` gets resolved for every track. Your listener runs once per track either way, and `setRawProperty('stream-open-filename', ...)` works in both cases.

#### 12.2 Listening and continuing

Listen to `player.stream.hook` and call `continueHook` when you are done. Call it on every path, errors included: until you do, mpv waits.

```dart
player.stream.hook.listen((event) async {
  if (event.hook == Hook.load) {
    try {
      final url = await player.getRawProperty('stream-open-filename') ?? '';
      if (url.startsWith('my-scheme://')) {
        final resolved = await myResolver(url);
        await player.setRawProperty('stream-open-filename', resolved.url);

        // Per-file HTTP headers, sent for HLS segments too
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
      player.continueHook(event.id);
    }
  } else {
    player.continueHook(event.id);
  }
});
```

#### 12.3 HTTP headers via hook

`file-local-options/http-header-fields` sets headers for the current file only. For an HLS stream they reach the playlist and every segment, the same as `Media.httpHeaders`:

```dart
await player.setRawProperty(
  'file-local-options/http-header-fields',
  'Authorization: Bearer abc123',
);
```

#### 12.4 The source resolver

`setSourceResolver` resolves the URL of each entry right before it opens, in one callback, with no `registerHook`, `continueHook` or placeholder scheme. [12.5](#125-lazy-url-resolution) shows the same idea done by hand with a hook. The resolver gets the entry's original `Media`, with its `extras` and `httpHeaders`, so it can read your own data (a track id, which login to use) and return the URL to play:

```dart
player.setSourceResolver((request) async {
  final id = request.media.extras?['trackId'] as String?;
  if (id == null) return null;         // not ours, keep the URL as-is
  return service.getPlaybackUrl(id);   // temporary CDN or token URL
});

// Queue by id, with no network calls until each track actually opens:
await player.openAll([
  Media('resolve://1', extras: {'trackId': '1'}),
  Media('resolve://2', extras: {'trackId': '2'}),
]);
```

The player calls the resolver:

* before every stream opens (`on_load`), prefetch included;
* once more after a failed open (`on_load_fail`), with `request.isRetry` set: return a fresh URL, for example with a new token, and mpv tries again. This happens at most once per load, and only when the new URL differs from the one that failed.

<img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/diagrams/source_resolver.png" width="100%" alt="The resolver returns a URL with a short-lived token; when the open fails, on_load_fail asks it again with isRetry true and a fresh token plays, at most once per load">

Returning `null` (or the incoming `request.uri` unchanged) keeps the current URL, so a resolver that only handles some entries leaves the rest untouched. A thrown error goes to `internalLog` and keeps the current URL.

The resolver works alongside your own hooks. If you also registered `Hook.load`, the resolver runs first; your listener then gets the event with `stream-open-filename` already changed, and still calls `continueHook`. A resolver that hangs is cut off by `timeout` (default 15 s), after which the library continues the hook. Pass `null` to remove the resolver.

#### 12.5 Lazy URL resolution

Building a playlist with `Future.wait` runs all the `getStreamUrl` calls at once. If the server refuses parallel sessions, as Plex does for transcoding, keep the session parameters and return a placeholder URL such as `my-scheme://session-id`. `on_load` fires for one track at a time as mpv opens them, so the real calls never overlap:

```dart
// No real API calls yet
final medias = await Future.wait(tracks.map((t) async {
  final url = await service.getStreamUrl(t.id); // returns "my-scheme://abc"
  return Media(url);
}));
await player.openAll(medias);

// When mpv reaches each track, on_load calls myResolver("my-scheme://abc"),
// which makes the /decision call and returns the start.m3u8 URL
```
---

### 13. Visualizer, waveform and loudness

`player.stream.fft` and `player.stream.pcm` carry the audio going to the
output, after the effects chain and the volume: what you hear. Paint
`bands` in a `CustomPainter`, drive a level meter with `samples`, or run
your own analysis:

<img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/diagrams/spectrum_pipeline.png" width="100%" alt="Spectrum pipeline: a block of output samples, the window, the linear FFT bins, the log bands and the smoothing, feeding stream.pcm and stream.fft">

Every stream in this section does its work only while it has a
listener: `fft`, `pcm`, the taps, `waveform`, `loudnessScan` and
`loudnessMeter` start on the first `listen()` and stop on the last
cancel. There is nothing to turn on.

#### 13.1 Subscribing to the spectrum stream

`player.stream.fft` emits an `FftFrame` at a fixed interval, 30 times a
second by default.

<details>
<summary><b>6 fields per frame</b> (click to expand)</summary>

| Field         | Type                | What it is |
|---------------|---------------------|------------|
| `bins`        | `Float32List`       | FFT magnitude per linear-frequency bin, from 0 to 1. Length `fftSize / 2`. |
| `bands`       | `Float32List`       | Smoothed, log-spaced bands for a bar visualizer. Length `bandCount`. |
| `timestamp`   | `Duration`          | libmpv's engine clock when the samples were captured, counted from engine start. It is not the position in the track: use `position` for that. |
| `sampleRate`  | `int`               | Sample rate of the output, in Hz. |
| `bandLowHz`   | `double`            | Lower edge of the band axis. |
| `bandHighHz`  | `double`            | Upper edge of the band axis (clamped to Nyquist). |

</details>

```dart
player.stream.fft.listen((frame) {
  for (var i = 0; i < frame.bands.length; i++) {
    final h = frame.bands[i] * canvasHeight;
    // draw bar i with height h …
  }
});
```

Paint `bands` as they come: they rise fast and fall slowly, so the bars
move smoothly without animation code. Use `bins` for your own mapping
(mel, Bark, constant-Q, peak detection).

#### 13.2 Configuring the pipeline

`SpectrumSettings` holds the FFT and smoothing settings. `setSpectrum`
applies them in one call, and `updateSpectrum` changes one field.

```dart
// 60 frames a second, 128 bands, a narrower dB window
player.setSpectrum(const SpectrumSettings(
  fftSize: 2048,
  bandCount: 128,
  emitInterval: Duration(milliseconds: 16),
  minDb: -90,
  maxDb: -20,
));

// Change one field, e.g. from a slider
player.updateSpectrum((s) => s.copyWith(attackSmoothing: 0.7));
```

<details>
<summary><b>10 fields</b> (click to expand)</summary>

| Field             | Default        | Range or choice |
|-------------------|----------------|----------------|
| `fftSize`         | 2048           | Power of 2: 256, 512, 1024, 2048, 4096 |
| `bandCount`       | 64             | Typical 32-128 |
| `bandLowHz`       | 20.0           | Lowest band edge, in Hz |
| `bandHighHz`      | 20000.0        | Clamped to Nyquist (`sampleRate / 2`) |
| `window`          | `WindowFunction.hann` | Hann, Blackman-Harris, Rectangular |
| `emitInterval`    | 33 ms          | 8 to 67 ms (about 120 to 15 frames a second) |
| `attackSmoothing` | 0.5            | Smoothing while a band rises; higher reacts faster |
| `releaseSmoothing`| 0.1            | Smoothing while a band falls; lower decays slower |
| `minDb`, `maxDb`  | -100, -30      | dB range mapped to 0 to 1, the Web Audio `AnalyserNode` defaults |
| `overlapFactor`   | 4              | Power of 2: 1 (no overlap), 2, 4 (75 %), 8, 16 |

</details>

The FFT memory is reallocated only when a setting requires it, so
changing settings from a slider is cheap.

While playback is paused no frames arrive, and the last one stays on
screen. To fade the bars to zero on pause, animate them yourself.

#### 13.3 Raw PCM stream

`player.stream.pcm` emits `PcmFrame`s at the same rate as `fft`, with the
samples themselves instead of the spectrum. Use it for an oscilloscope,
a level or peak meter, or any analysis that needs amplitude.

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

`samples` is a `Float32List` with the channels interleaved (`L, R, L, R`).
`frame.samplesPerChannel` is the number of samples in each channel.

#### 13.4 Per-filter PCM taps

`player.stream.tap(filter, side: ...)` captures the samples on either
side of one stage of the effects chain. The stage is named by its
filter, through the `AudioFilter` enum, and by `instance` when the
filter appears more than once (0, the default, is the first): with two
`EqualizerEffect`s in the list, `instance: 1` taps the second. Disabled
stages count too, and emit nothing. The tap follows the occurrence, not a
particular stage: moving other filters around keeps it where it is, while
swapping the two equalizers swaps what `instance: 0` taps. libmpv captures
up to eight stages at a time, counted across all players of the process,
and two players tapping the same stage read one mixed feed. The players of
one isolate keep the list of tapped stages together; a player in another
isolate replaces it with its own. `TapSide.pre` captures before the filter
and `TapSide.post` after it.

```dart
// Input and output of one filter
player.stream
    .tap(AudioFilter.equalizer, side: TapSide.pre)
    .listen((pcm) => paintInputWaveform(pcm.samples));
player.stream
    .tap(AudioFilter.equalizer, side: TapSide.post)
    .listen((pcm) => paintOutputWaveform(pcm.samples));
```

For bands, run the samples through `BandProcessor`. It uses the same FFT,
window and smoothing as `stream.fft`, so a stage's curve moves like the
main one:

```dart
final processor = BandProcessor(player.state.spectrum);
// Follow the spectrum settings
final cfgSub = player.stream.spectrum.listen(processor.setSettings);
final tapSub = player.stream
    .tap(AudioFilter.equalizer, side: TapSide.post)
    .listen((pcm) {
      final fft = processor.process(pcm);
      if (fft != null) painter.bands = fft.bands;
    });
```

Every typed stage exposes its `filter`, so you can tap the whole chain
stage by stage:

```dart
final seen = <AudioFilter, int>{};
for (final e in player.state.audioEffects) {
  final f = e.filter;
  if (f == null) continue;  // raw stage
  // Disabled stages count toward the instance too.
  final instance = seen.update(f, (n) => n + 1, ifAbsent: () => 0);
  if (!e.enabled) continue;  // disabled: nothing to tap
  player.stream.tap(f, instance: instance, side: TapSide.post).listen(_paint);
}
```

#### 13.5 Waveform

`player.stream.waveform` emits a mono envelope of the loaded track,
computed on a worker thread: about 2000 bins, each with its min, max and
RMS, enough to paint a waveform
overview or a waveform-style seekbar. There is one waveform per process:
with several players, the last `open()` wins. It stays on while a player
of the same isolate listens: another player's cancel or dispose does not
turn it off.

Local files are decoded ahead of time: partial envelopes arrive while
the decode runs (`wave.decoding`), then the final one. An HTTP file that
plays from its start, such as a direct-play file, is decoded from mpv's
own cache as it downloads, so the envelope fills at the pace of the
download. Streams that cannot be decoded
ahead of time (adaptive, non-seekable or transcoded network sources)
fill in as playback advances, and a live stream of unknown length keeps
a rolling window (`wave.live`). `wave.filled` has one byte per bin, `1`
once the bin holds data, so you can draw the rest as a flat baseline.

On loud, heavily limited masters the peaks sit near full scale for most
of the track. Drawing `wave.rms` as the body of the waveform, with the
min and max as a lighter outline, keeps verses, choruses and drops
readable. `wave.rms` is `null` with a libmpv older than `libmpv-r14`.

Such a file is downloaded once: the analysis reads the packets mpv
already cached. When one pass from the start to the end is not possible
(playback starting further in, a seek past the cache, a track switch, a
cut download, the cache off or on disk, a file larger than the cache),
the analysis opens the source a second time, with the same network
options as playback (`tls-verify`, `tls-ca-file`, headers, user agent,
cookies). Either way the result is the same. The loudness scan below
uses the same decode.

<img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/diagrams/analysis_cache_feed.png" width="100%" alt="A network file downloaded once: playback and the analysis read the same mpv cache, the waveform fills as it decodes, and the analysis opens the source a second time only when one pass from the start to the end is not possible">

```dart
player.stream.waveform.listen((wave) {
  if (wave == null) return; // null at each file load, until the first bins land
  // wave.min and wave.max: Float32List, range [-1, +1], wave.bins long.
  // wave.rms: Float32List?, range [0, 1], same length.
  // Bin i covers wave.duration * i / wave.bins to wave.duration * (i + 1) / wave.bins
  for (var i = 0; i < wave.bins; i++) {
    if (wave.filled[i] == 0) continue; // no data yet: draw a baseline
    // draw a light bar from wave.min[i] to wave.max[i]
    // and a solid one from -wave.rms![i] to wave.rms![i]
  }
});
```

#### 13.6 Loudness

`player.stream.loudnessScan` measures the EBU R128 loudness of the loaded
track the same way as the waveform: the whole file is decoded apart from
playback, right after it loads, many times faster than real time. While
the scan runs the stream emits `scanning` snapshots with
`progress`, then one final `LoudnessScan` per track with integrated LUFS,
loudness range, sample peak and true peak, often before the audio has
started playing.

Use it to level the volume of files without ReplayGain tags:

```dart
player.stream.loudnessScan.listen((scan) {
  if (scan?.state == LoudnessScanState.ready) {
    // ReplayGain 2.0 reference is -18 LUFS.
    player.setVolumeGain((-18.0 - scan!.integrated!).clamp(-24.0, 24.0));
  }
});
```

The stream emits `null` each time a file loads, so old results clear.
Sources that can only be decoded as they play (adaptive or live network
streams) report `LoudnessScanState.unavailable`: use the live meter below
for those. Like the waveform, the scan stays on while a player of the same
isolate listens.

#### 13.7 Live loudness meter

`player.stream.loudnessMeter` emits momentary, short-term, integrated
and loudness-range readings of the audio as it plays, for a level meter
or a broadcast loudness display. The meter reads the
first enabled `Ebur128Effect` of the chain with its `metadata` option on,
so add one at the point of the chain you want to measure:

```dart
await player.updateAudioEffects(
  (fx) => [...fx, const Ebur128Effect(metadata: true)],
);
player.stream.loudnessMeter.listen((l) => meter.paint(l.momentary));
```

Without the meter in the chain the stream emits nothing.

---

### 14. OS media session

`setMediaSession` publishes the player to the system media controls
(Now Playing, Control Center and the lock screen on iOS and macOS, MPRIS
on Linux, SMTC on Windows, the media notification on Android) and
receives the commands the OS sends back. Pass `null` to remove the entry. Only one `Player` per process may own the
session at a time (enabling a second throws `StateError`); `dispose()`
releases it automatically.

<img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/diagrams/media_session_flow.png" width="100%" alt="The media session publishes the player to the iOS lock screen, the macOS Control Center, the Android notification, the Windows flyout and the Linux MPRIS applet, and sends their commands back">

#### 14.1 Enabling the session

Title, artist, album, artwork and duration come from the playing file,
with nothing to push:

```dart
await player.setMediaSession(const MediaSession());  // enable
await player.setMediaSession(null);                  // remove
```

#### 14.2 Overriding metadata

Each metadata field overrides the file: `null` keeps mpv's value, a
string replaces it, and an empty string leaves it blank. `copyWith`
changes one field:

```dart
await player.setMediaSession(
  (player.state.mediaSession ?? const MediaSession())
      .copyWith(title: 'Custom title', artist: 'Custom artist'),
);
```

For a file without tags, such as a transcoded stream, each field falls
back to the entry's `Media.extras`: `title`, `artist` and `album` as
strings, and `art` as an `http(s)://` or `file://` cover URL when the
artwork is `embedded` and the file has none. A stream with no title tag
and no `extras['title']` falls back to mpv's `media-title`, taken from the
URL with the query removed. Setting `MediaSession.title` is still better.

#### 14.3 Artwork and privacy

`MediaSession.artwork` picks the image:

```dart
MediaSessionArtwork.embedded            // default, the file's embedded cover
MediaSessionArtwork.custom(myCoverArt)  // your own image, ignoring the file cover
MediaSessionArtwork.uri(myArtUrl)       // a remote image, downloaded before it reaches the OS
MediaSessionArtwork.none                // no artwork
```

Network URLs never reach the OS media session as text, since they often
carry credentials in the query (Subsonic, Jellyfin, Plex). MPRIS on Linux
gets `xesam:url` only for local files. A remote cover reaches the OS as an
image. On Linux, Android and Windows the package downloads it in Dart: the
download always verifies the server certificate, even when `tls-verify` is
off for playback, trusts `tls-ca-file` on top of the system roots, refuses
a redirect from `https` to plain `http`, and is tried at most 3 times. On iOS and macOS the system downloads it, with the
system roots only.

#### 14.4 Reacting to OS commands

The player applies OS commands itself (play from the lock screen calls
`play()`, scrubbing calls `seek()`, and so on) and also emits them on
`player.stream.mediaSessionCommands`:

```dart
player.stream.mediaSessionCommands.listen((command) {
  switch (command) {
    case MediaSessionCommandSeekTo(:final position):
      log('scrubbed to $position');
    case MediaSessionCommandNext():
      // next and previous drive mpv's playlist when one is loaded; with a
      // single track they only emit here, so advance your own queue.
      myQueue.next();
    case _:
      break;
  }
});
```

#### 14.5 Capabilities, intervals and speeds

`actions` lists the controls the OS may show. Each platform draws only
some of them, and a lock screen usually shows 3 or 4. An action a
platform does not draw is simply left out. The
default set is `play`, `pause`, `playPause`, `next`, `previous` and `seek`; the
enum also has `stop`, `fastForward`, `rewind`, `setRepeatMode`, `setShuffle`,
`setPlaybackRate` and `like` (a favorite or star). The skip intervals and the
speed list apply only when their action is in the set.

```dart
const MediaSession(
  actions: {
    MediaAction.play, MediaAction.pause, MediaAction.playPause,
    MediaAction.next, MediaAction.previous, MediaAction.seek,
    MediaAction.fastForward, MediaAction.rewind, MediaAction.setPlaybackRate,
    MediaAction.setRepeatMode, MediaAction.setShuffle,
  },
  fastForwardInterval: Duration(seconds: 30),
  rewindInterval: Duration(seconds: 15),
  supportedPlaybackRates: [1.0, 1.25, 1.5, 2.0],
  autoApplyPlaylistNavigation: false,
);
```

With `autoApplyPlaylistNavigation: false` the next and previous buttons no
longer change track, and you handle them yourself, for example as a 30 s
skip in an audiobook split into files. The command still arrives on
[`stream.mediaSessionCommands`](#915-media-session-streams).

The actions each platform's media controls draw:

| Action | iOS | macOS | Android | Windows | Linux¹ |
|---|:--:|:--:|:--:|:--:|:--:|
| `play`, `pause`, `playPause` | Yes | Yes | Yes | Yes | Yes |
| `next`, `previous` | Yes | Yes | Yes | Yes | Yes |
| `seek` (scrubber) | Yes | Yes | Yes | Yes | KDE |
| `fastForward`, `rewind` | Yes | Yes | Yes | Yes | No |
| `stop` | No | No | No | Yes | No |
| `setRepeatMode`, `setShuffle` | No | No | Yes | No² | KDE |
| `setPlaybackRate` | No | No | No | No² | KDE |
| `like` | Yes | No | Yes | No | No |

¹ On Linux it depends on the desktop: KDE Plasma draws seek, repeat,
shuffle and rate, while GNOME's popup shows only previous, play-pause and
next.
² Windows SMTC stores repeat, shuffle and rate, but its flyout has no
button for them.

#### 14.6 Audio interruptions

`interruptionPolicy` decides what happens on a phone call, Siri, or
another app taking the audio focus:

```dart
InterruptionPolicy.pauseAndResume // default: pause, resume when the OS allows
InterruptionPolicy.pauseOnly      // pause, never resume on its own
InterruptionPolicy.keepPlaying    // keep playing at full volume
```

`keepPlaying` has limits the OS sets: on iOS an accepted phone or
FaceTime call, or Siri, still takes the audio, and on Android 12 and
later the system may fade the app out when another app gains focus.
Unplugging headphones always pauses, even with `keepPlaying`, as Apple's
guidelines require. macOS, Linux and Windows have no per-app audio
session, so the policy does nothing there.

Background playback on iOS also needs the setup in [Permissions](#ios).

#### 14.7 App identity (desktop)

On Linux (MPRIS) and Windows (SMTC) the OS labels the controls with your
app's name. macOS, iOS and Android take it from the app bundle and ignore
these fields.

```dart
const MediaSession(
  appName: 'My Player',               // name shown by MPRIS and SMTC
  desktopEntry: 'com.example.myapp',  // Linux only, see below
);
```

`desktopEntry` is the name, without `.desktop`, of the file you install
in `/usr/share/applications/`. The Linux desktop uses it to find the icon
shown beside the controls; with `null` it shows a generic icon. On Windows the icon comes from
the executable, so only `appName` applies there.

---

## Permissions

### Android

Network sources need:

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

The package's own manifest declares `FOREGROUND_SERVICE`,
`FOREGROUND_SERVICE_MEDIA_PLAYBACK` and `POST_NOTIFICATIONS` for the
[media session](#14-os-media-session). The app does not need to request
`POST_NOTIFICATIONS` at runtime: Android 13 and later exempt media session
notifications, so the media controls show without it.

### iOS

In Signing & Capabilities, add the Background Modes capability and check
`Audio, AirPlay, and Picture in Picture`. That writes this to `Info.plist`:

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

#### Building and testing in containers (WSL, Docker or Distrobox)
libmpv comes prebuilt, so building the app needs only the Flutter desktop tools, no audio `-dev` packages. At runtime libmpv needs `libasound2`, and a PipeWire client (0.3.57 or later) or PulseAudio to reach the host's sound server. Desktop distributions ship them; a minimal container does not:

```bash
sudo apt update

# Flutter desktop build tools
sudo apt install clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev

# Runtime libraries to play sound through the host
sudo apt install libasound2 libpipewire-0.3-0 libpulse0
```

The `alsa` driver cannot reach the sound card from inside a container: use `pipewire` or `pulse`. On WSL only `pulse` works.

---

## Project background

I wrote the native bindings, the isolate code and most of the architecture with Claude Code.

Jellyfin, Plex and Samba are trademarks of their respective owners. mpv_audio_kit is not affiliated with them.

---

*Developed by Alessandro Di Ronza*
