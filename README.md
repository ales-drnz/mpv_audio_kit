# mpv_audio_kit

A Flutter audio player plugin powered by [libmpv](https://mpv.io). Supports local files, HTTP(S) streams, and internet radio. Exposes the full mpv audio pipeline including equalizer, dynamic compression, loudness normalization, and pitch/tempo control.

## Platform support

| Platform | Status |
|---|---|
| macOS | ✅ |
| iOS | ✅ |
| Android | ✅ |
| Linux | ✅ |
| Windows | ✅ |

## Installation

```yaml
dependencies:
  mpv_audio_kit: ^0.0.1
```

## Quick start

```dart
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

// Create the player
final player = MpvPlayer(
  config: const PlayerConfig(autoPlay: true),
);

// Listen to state changes
player.stateStream.listen((state) {
  print('State: $state');
});

// Load and play
await player.open('https://example.com/audio.mp3', play: true);

// Dispose when done
player.dispose();
```

## MpvPlayer

### Constructor

```dart
MpvPlayer({PlayerConfig config = const PlayerConfig()})
```

### Playback

| Method | Description |
|---|---|
| `open(String url, {bool? play})` | Load a URL. Starts playback if `play: true` or `autoPlay` is set. |
| `play()` | Resume playback. |
| `pause()` | Pause playback. |
| `playOrPause()` | Toggle play/pause. |
| `stop()` | Stop and unload the current file. |
| `seek(double seconds, {bool relative})` | Seek to an absolute or relative position. |

### Audio

| Method | Description |
|---|---|
| `setVolume(double vol)` | Set volume (0–100; values above 100 amplify). |
| `setSpeed(double speed)` | Set playback speed (1.0 = normal). |
| `setPitch(double pitch)` | Set audio pitch. |
| `setAudioDelay(double delay)` | Set sync offset in seconds (e.g., -0.2). |
| `setAudioFilters(List<AudioFilter>)` | Replace the entire audio filter chain. |
| `addAudioFilter(AudioFilter)` | Append a filter to the current chain. |
| `clearAudioFilters()` | Remove all active audio filters. |
 
### Network & Cache
 
| Method | Description |
|---|---|
| `setCache(String mode)` | Set cache behavior ("yes", "no", "auto"). |
| `setCacheSecs(double secs)` | Pre-fetch buffer duration for network streams. |
| `setCacheOnDisk(bool)` | Save cache to temporary files instead of RAM. |
| `setCachePause(bool)` | Enable automatic pausing for network buffering. |
| `setYtdl(bool)` | Enable/disable YouTube-DL integration. |
| `setNetworkTimeout(double)` | Network connection timeout limit in seconds. |

### Streams

| Stream | Type | Description |
|---|---|---|
| `stateStream` | `PlayerState` | Playback state changes. |
| `positionStream` | `double` | Current position in seconds (updates every ~10 ms). |
| `durationStream` | `double?` | Total duration in seconds (`null` for live streams). |
| `volumeStream` | `double` | Volume changes. |
| `mediaInfoStream` | `MediaInfo` | File metadata after load (or ICY tag updates). |
| `cacheStream` | `double` | Current buffered seconds duration. |
| `bitrateStream` | `int?` | Real-time audio bitrate in bps. |
| `logStream` | `String` | Raw mpv log lines. |

### Properties

| Property | Type | Description |
|---|---|---|
| `state` | `PlayerState` | Current state. |
| `position` | `double` | Current position in seconds. |
| `duration` | `double?` | Duration in seconds. |
| `volume` | `double` | Current volume. |
| `mediaInfo` | `MediaInfo?` | Metadata of the loaded file. |
| `isPlaying` | `bool` | Shorthand for `state == PlayerState.playing`. |
| `isPaused` | `bool` | Shorthand for `state == PlayerState.paused`. |

### Raw mpv access

For features not covered by the high-level API, you can access mpv directly:

```dart
player.setRawProperty('loop-file', 'inf');          // loop current file
player.setRawProperty('audio-delay', '-0.2');        // sync offset
final title = player.getRawProperty('media-title');  // read any property
player.sendRawCommand(['playlist-next', 'force']);    // any mpv command
```

## PlayerConfig

```dart
const PlayerConfig({
  bool autoPlay = false,       // start playback immediately after open()
  double initialVolume = 100,  // 0–100
  String logLevel = 'warn',    // 'no' | 'fatal' | 'error' | 'warn' | 'info' | 'v' | 'debug'
  String? audioOutput,         // force a specific mpv --ao driver (null = auto)
})
```

## PlayerState

```dart
enum PlayerState { idle, buffering, playing, paused, ended, error }
```

## MediaInfo

Emitted once via `mediaInfoStream` when a file finishes loading:

```dart
class MediaInfo {
  final double?  duration;    // seconds; null for live streams
  final String?  title;
  final String?  artist;
  final String?  album;
  final String?  year;
  final int?     bitrate;     // bps
  final int?     sampleRate;  // Hz
  final int?     channels;
  final String?  codec;
}
```

## AudioFilter

### Built-in factories

```dart
// 10-band equalizer (ISO centers: 31–16k Hz)
AudioFilter.equalizer([0, 0, 6, 0, -3, 0, 0, 0, 3, 0])
 
// Real-time effects

AudioFilter.echo(delay: 200, falloff: 0.4)  // Echo/Reverb
AudioFilter.extraStereo(m: 2.0)             // Stereo expander
AudioFilter.crystalizer(intensity: 2.0)     // Harmonic enhancer
 
// Dynamic compressor
AudioFilter.compressor(threshold: -20, ratio: 4, attack: 20, release: 250)
 
// EBU R128 loudness normalization
AudioFilter.loudnorm(integratedLoudness: -16, truePeak: -1.5, lra: 11)
 
// Pitch / tempo shift (requires rubberband in the mpv build)
AudioFilter.scaleTempo(pitch: 1.0, tempo: 1.25)
 
// Any raw lavfi filter string
AudioFilter.custom('aecho=0.8:0.9:1000:0.3')
```

### Stacking filters

```dart
await player.setAudioFilters([
  AudioFilter.loudnorm(),
  AudioFilter.equalizer([0, 0, 3, 0, 0, 0, 0, 0, 2, 0]),
]);
```

## Full example

```dart
final player = MpvPlayer(
  config: const PlayerConfig(
    autoPlay: true,
    initialVolume: 80,
    logLevel: 'warn',
  ),
);

// Metadata
player.mediaInfoStream.listen((info) {
  print('${info.title} — ${info.artist}');
  print('Duration: ${info.duration?.toStringAsFixed(0)}s');
});

// Position slider
player.positionStream.listen((pos) => setState(() => _position = pos));
player.durationStream.listen((dur) => setState(() => _duration = dur));

// Load an internet radio stream
await player.open('https://ice1.somafm.com/groovesalad-256-mp3');

// Apply an equalizer after a few seconds
await Future.delayed(const Duration(seconds: 3));
await player.setAudioFilters([
  AudioFilter.equalizer([0, 0, 4, 2, 0, 0, 0, 0, 2, 3]),
]);

// Seek 30 seconds forward
await player.seek(30, relative: true);

// Cleanup
player.dispose();
```

## Supported formats

All formats supported by the bundled FFmpeg build, including:
MP3, AAC, FLAC, Opus, Vorbis, WAV, AIFF, M4A, OGG, WMA, ALAC, and more.

Protocols: `http://`, `https://`, `file://`, HLS (`m3u8`), and all other protocols supported by mpv/FFmpeg.

## License

MPL-2.0. See [LICENSE](LICENSE).
