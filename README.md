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

An audio player for Flutter apps that play from your own server. It runs mpv and FFmpeg behind a typed Dart API, on Android, iOS, macOS, Windows, Linux and the web.

**[Try it in your browser](https://ales-drnz.github.io/mpv_studio/)** with [mpv_studio](https://github.com/ales-drnz/mpv_studio), the demo app.

<table>
<tr>
<td valign="middle" width="48"><img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/protocols/jellyfin.png" width="32" alt="Jellyfin"></td>
<td valign="middle"><b>Jellyfin</b><br>Stream your library direct or transcoded. Transcoded streams arrive as HLS, and you can still seek in them.</td>
</tr>
<tr>
<td valign="middle"><img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/protocols/plex.png" width="32" alt="Plex"></td>
<td valign="middle"><b>Plex</b><br>Play tracks and playlists over HLS or DASH. Each track asks the server for its stream only when it opens, so a long queue starts at once.</td>
</tr>
<tr>
<td valign="middle"><img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/protocols/samba.png" width="32" alt="Samba"></td>
<td valign="middle"><b>Samba</b><br>Play straight from a NAS or any network share over SMB2 and SMB3.</td>
</tr>
<tr>
<td valign="middle"><img src="https://raw.githubusercontent.com/ales-drnz/svg-icons/main/png/wrench.png" width="32" alt=""></td>
<td valign="middle"><b>Total control</b><br>Tune the cache and the network, shape the sound with <a href="https://pub.dev/documentation/mpv_audio_kit/latest/topics/Effects-topic.html">a chain of FFmpeg effects</a>, and watch it with a live spectrum, waveform and loudness meter.</td>
</tr>
</table>

<p align="center">
  <img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/playback.gif" width="100%" alt="mpv_studio playing a track, with its waveform and spectrum">
</p>

---

## Getting started

```yaml
dependencies:
  mpv_audio_kit: ^0.6.0
```

The build downloads the libmpv binary for each native target and checks its SHA-256, so the first build needs network access. On the web the module ships with the package.

| Platform | Minimum | Architectures | Size |
| :--- | :--- | :--- | :---: |
| Android | 7.0 (SDK 24) | arm64-v8a, armeabi-v7a, x86_64 | 8.3 MB |
| iOS | 15.0 | arm64, x86_64 | 7.5 MB |
| macOS | 12.0 | arm64, x86_64 | 7.5 MB |
| Windows | 10 | arm64, x86_64 | 8.1 MB |
| Linux | glibc 2.31 | aarch64, x86_64 | 8.6 MB |
| Web | a cross-origin isolated page | wasm32 | 1.9 MB with brotli |

Flutter 3.41 or later, and 3.47.4 to build for iOS. Linux needs ALSA, and uses PipeWire or PulseAudio when they are installed.

### Play a file

```dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MpvAudioKit.ensureInitialized();
  runApp(const MyApp());
}

final player = Player();
await player.open(Media('https://example.com/audio.flac'));
await player.play();

player.stream.position.listen((position) => print(position));

await player.dispose(); // when you are done
```

`player.state` holds the current values, and `player.stream` sends each change.

<img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/diagrams/player_lifecycle.png" width="100%" alt="Player lifecycle: ensureInitialized once, then for each player create, open, listen and control, and dispose">

### How it works

The player lives on your main isolate and calls libmpv without blocking it. A background isolate waits for mpv's events and brings state back.

<img src="https://raw.githubusercontent.com/ales-drnz/mpv_audio_kit/main/imgs/diagrams/architecture.png" width="100%" alt="Architecture: the Player on the main isolate calls libmpv, the event isolate forwards events and state, and the platform plugin connects the media session">

---

## Working with the player

### A queue

```dart
await player.openAll([track1, track2, track3]);
await player.insert(player.state.playlist.index + 1, track4); // play next
await player.next();
await player.setLoop(Loop.playlist);
await player.setPrefetchPlaylist(true); // gapless over the network
```

More in [Playback](https://pub.dev/documentation/mpv_audio_kit/latest/topics/Playback-topic.html): sources, headers, chapters, resume points and live PCM.

### Effects

```dart
await player.setAudioEffects(const [
  EqualizerEffect(frequency: 100, width: 50, widthType: EqualizerWidthType.h, gain: 3),
  LoudnormEffect(i: -16),
  AlimiterEffect(limit: 0.9),
]);
```

Each of the 86 effects is an FFmpeg filter with typed options. More in [Effects](https://pub.dev/documentation/mpv_audio_kit/latest/topics/Effects-topic.html).

### Errors

```dart
player.stream.error.listen((error) {
  switch (error) {
    case EndFileError():
      print('The file stopped: ${error.message}');
    case LogError():
      print('mpv reported: ${error.message}');
  }
});
```

More in [Errors and logs](https://pub.dev/documentation/mpv_audio_kit/latest/topics/Errors%20and%20logs-topic.html).

### A URL that expires

A source resolver gives each entry its stream URL when it opens, so a queue of tokens never goes stale.

```dart
await player.setSourceResolver((request) async {
  final id = request.media.extras?['trackId'] as String?;
  return id == null ? null : api.streamUrl(id); // null keeps the URL
});

await player.openAll([
  Media('resolve://1', extras: {'trackId': '1'}),
  Media('resolve://2', extras: {'trackId': '2'}),
]);
```

More in [Hooks and raw access](https://pub.dev/documentation/mpv_audio_kit/latest/topics/Hooks%20and%20raw%20access-topic.html).

### Lock screen and notification

```dart
await player.setMediaSession(const MediaSession());
```

The player then shows in the system media controls on every platform. On Android this also keeps it playing in the background. More in [Media session](https://pub.dev/documentation/mpv_audio_kit/latest/topics/Media%20session-topic.html).

### Visualizer

```dart
player.stream.fft.listen((frame) => paintSpectrum(frame));
```

A live spectrum, the raw PCM, a waveform of the whole file and a loudness scan. More in [Visualizer and analysis](https://pub.dev/documentation/mpv_audio_kit/latest/topics/Visualizer%20and%20analysis-topic.html).

### The browser

The page needs two headers and a user gesture before it plays. See [Web](https://pub.dev/documentation/mpv_audio_kit/latest/topics/Web-topic.html).

---

## Permissions

### Android

Network sources need, in your app's manifest:

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

The package already declares `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_MEDIA_PLAYBACK` and `POST_NOTIFICATIONS`. You do not need to request `POST_NOTIFICATIONS` at runtime: media notifications are exempt.

**Background playback** needs the [media session](#14-os-media-session). `setMediaSession` runs a foreground service of type `mediaPlayback`, which keeps the app alive after the user leaves it. Without a session, Android may freeze or stop the app in the background.

- After 10 minutes in pause, the service leaves the foreground and Android may stop the app. A pause caused by a phone call under `pauseAndResume` does not count.
- If Android refuses the foreground service to a play started in the background, the player pauses.
- The player takes no wake lock. If a network stall pauses the output with the screen off, the device may sleep until something wakes it.
- Back from the root route, or a swipe from the recent apps, can destroy the Flutter engine and stop its players (see [1.3](#13-disposing-a-player)).

### iOS

For background playback, add the Background Modes capability in Signing & Capabilities and check `Audio, AirPlay, and Picture in Picture`. This writes to `Info.plist`:

```xml
<key>UIBackgroundModes</key>
<array>
  <string>audio</string>
</array>
```

### macOS

For network sources, add to `DebugProfile.entitlements` and `Release.entitlements`:

```xml
<key>com.apple.security.network.client</key>
<true/>
```


---

## Troubleshooting

### Building and testing in containers (WSL, Docker or Distrobox)

libmpv comes prebuilt, so building needs only the Flutter desktop tools. At runtime libmpv needs `libasound2`, and a PipeWire (0.3.57 or later) or PulseAudio client to reach the host's sound server. Desktop distributions ship them; a minimal container does not:

```bash
sudo apt update

# Flutter desktop build tools
sudo apt install clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev

# Runtime libraries to play sound through the host
sudo apt install libasound2 libpipewire-0.3-0 libpulse0
```

Inside a container the `alsa` driver cannot reach the sound card: use `pipewire` or `pulse`. On WSL only `pulse` works.

---

## Documentation

- [API reference](https://pub.dev/documentation/mpv_audio_kit/latest/), with these guides:
  - [Playback](https://pub.dev/documentation/mpv_audio_kit/latest/topics/Playback-topic.html): sources, the queue, controls and resume points
  - [Effects](https://pub.dev/documentation/mpv_audio_kit/latest/topics/Effects-topic.html): the FFmpeg effects chain, ReplayGain and gapless
  - [Output](https://pub.dev/documentation/mpv_audio_kit/latest/topics/Output-topic.html): drivers, devices, formats and exclusive mode
  - [Network and cache](https://pub.dev/documentation/mpv_audio_kit/latest/topics/Network%20and%20cache-topic.html): the cache, timeouts, TLS, proxies and reconnects
  - [Metadata](https://pub.dev/documentation/mpv_audio_kit/latest/topics/Metadata-topic.html): tags and cover art
  - [State and streams](https://pub.dev/documentation/mpv_audio_kit/latest/topics/State%20and%20streams-topic.html): reading and following the player
  - [Errors and logs](https://pub.dev/documentation/mpv_audio_kit/latest/topics/Errors%20and%20logs-topic.html): typed errors, end of file and logs
  - [Hooks and raw access](https://pub.dev/documentation/mpv_audio_kit/latest/topics/Hooks%20and%20raw%20access-topic.html): the source resolver, mpv hooks and raw properties
  - [Visualizer and analysis](https://pub.dev/documentation/mpv_audio_kit/latest/topics/Visualizer%20and%20analysis-topic.html): spectrum, PCM, waveform and loudness
  - [Media session](https://pub.dev/documentation/mpv_audio_kit/latest/topics/Media%20session-topic.html): lock screen, notification and system controls
  - [Web](https://pub.dev/documentation/mpv_audio_kit/latest/topics/Web-topic.html): serving the page, autoplay and the browser's limits
- [Example app](example/) and [mpv_studio](https://github.com/ales-drnz/mpv_studio), a full player
- [CHANGELOG](CHANGELOG.md) and [MIGRATION](MIGRATION.md)

## Licenses

The package is BSD-3-Clause. The libmpv it bundles is LGPL, version 3 or later, and your app keeps its own license. `showLicensePage` lists the libmpv texts with nothing to set up. Your users must be able to replace libmpv and get its source, which the release's `licenses.zip` names. [LICENSES.md](LICENSES.md) has the details and the GPL build with Rubber Band.

## Project background

I wrote the native bindings, the isolate code and most of the architecture with Claude Code.

Jellyfin, Plex and Samba are trademarks of their respective owners. mpv_audio_kit is not affiliated with them.

---

*Developed by Alessandro Di Ronza*
