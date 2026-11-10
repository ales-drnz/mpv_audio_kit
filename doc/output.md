Choose the output driver and device, the output format, and the audio track of a file.

## Driver

```dart
await player.setAudioDriver('wasapi');    // Windows
await player.setAudioDriver('coreaudio'); // macOS
await player.setAudioDriver('audiounit'); // iOS
await player.setAudioDriver('aaudio');    // Android, also 'audiotrack' and 'opensles'
await player.setAudioDriver('pipewire');  // Linux, also 'pulse' and 'alsa'
await player.setAudioDriver('auto');      // the default
```

On Android `auto` picks `audiotrack`. `aaudio` needs Android 8 (API 26).

When no device opens, playback goes on silently on the `null` output. See the [Errors and logs](https://pub.dev/documentation/mpv_audio_kit/latest/topics/Errors%20and%20logs-topic.html) topic.

## Device

```dart
player.stream.audioDevices.listen((devices) {
  for (final d in devices) print('${d.name}: ${d.description}');
});

await player.setAudioDevice(player.state.output.audioDevices.first);
await player.setAudioDevice(Device.auto); // back to the system default
```

`name` is the device id, and `description` is the label to show. On Android the list holds one device per driver, such as `Default (audiotrack)`. The system routes the sound to the speaker, headphones or Bluetooth itself.

### Exclusive mode

```dart
await player.setAudioExclusive(true);
await player.setAudioExclusive(false); // back to shared mode
```

| Driver | Effect |
| :--- | :--- |
| WASAPI (Windows), CoreAudio (macOS) | The player takes the device and switches it to the track's rate when it can. The system mixer neither resamples nor sets the volume, and other apps have no sound on that device. |
| PipeWire (Linux) | Other streams stay off the sink. PipeWire's volume still applies, and it resamples to a rate the server allows. |
| `aaudio` (Android) | Exclusive only in low-latency mode, on Android 8.1 (API 27) or later with a device that supports it. Other apps keep playing. |
| iOS | No effect. The app's audio never mixes with other apps. |
| Other drivers, `audiotrack` included | Ignored. |

With WASAPI and CoreAudio the player keeps the device while paused and at the end of the queue. Call `stop()`, `setAudioExclusive(false)` or `dispose()` to give it back. In exclusive mode `setSystemVolume` moves the device's own volume on Windows and does nothing on macOS.

```dart
// An exclusive low-latency stream on Android
await player.setAudioDriver('aaudio');
await player.setRawProperty('aaudio-performance-mode', 'low-latency');
await player.setAudioExclusive(true);
```

## Output format

Force the rate, sample format or channel layout, for example to match what a DAC accepts. A change during playback reopens the output with a short gap.

```dart
await player.setAudioSampleRate(96000);            // 0 for auto
await player.setAudioFormat(Format.float32);       // also s16, s32, their planar forms
await player.setAudioChannels(Channels.stereo);    // also fiveOne, sevenOne, autoSafe
await player.setAudioChannels(const Channels.custom('fl-fr-fc-bl-br-sl-sr-lfe'));
```

`Channels.auto` keeps the source layout when the device accepts it. `Channels.autoSafe` allows a multichannel layout only when the device reports it. The API reference lists every format and layout.

To downmix without clipping, create the player with `PlayerConfiguration(normalizeDownmix: true)`.

On the web one rate serves the whole page, and a rate the browser refuses throws `StateError`.

The driver can still change what you ask for, and `state.output.audioOutParams` shows what the device gets. On Android:

- `audiotrack` plays only 8-bit, 16-bit and float samples, at most at the device's native rate. It turns other integer formats into 16-bit, so use `Format.float32` to keep a 24-bit file intact.
- `aaudio` takes 32-bit integers from Android 12 (API 31).
- `opensles` plays stereo only.

### Passthrough

`setAudioSpdif` sends AC3, E-AC3, DTS, DTS-HD and TrueHD untouched to a receiver over SPDIF or HDMI.

```dart
await player.setAudioSpdif({Spdif.ac3, Spdif.eac3, Spdif.trueHd, Spdif.dtsHd});
await player.setAudioSpdif({}); // off

// 'spdif-...' while a track passes through
final format = await player.getRawProperty('audio-out-params/format');
```

While a track passes through, the receiver decodes it:

- Effects, volume, mute, ReplayGain, pitch and the output format do not apply.
- A speed other than 1 drops or repeats parts of the stream.
- The FFT, PCM, taps and loudness meter emit nothing.

When the output refuses the format, the player decodes the track instead. A change of the list during playback causes a short gap.

On Android `MpvAudioKit.passthroughCodecs()` tells which of AC3, E-AC3 and DTS the HDMI sink takes, so a TV box asks only for those. It is empty on the other platforms. `audiotrack` sends passthrough as IEC61937 stereo, which carries neither TrueHD nor DTS-HD.

```dart
await player.setAudioSpdif(await MpvAudioKit.passthroughCodecs());
```

## Tracks

A file can hold several audio tracks, such as one per language.

```dart
for (final t in player.state.file.tracks.where((t) => t.type == 'audio')) {
  print('${t.id}: ${t.title ?? t.lang ?? 'audio'} (${t.codec})');
}

await player.setAudioTrack(const Track.id(2));
await player.setAudioTrack(Track.auto); // the file's default track
await player.setAudioTrack(Track.off);  // no audio

// An external file as a track of the current file
await player.addAudioTrack(Media('commentary.mka'), title: 'Commentary');
await player.removeAudioTrack(const Track.id(3));
```

`stream.currentAudioTrack` follows the selected track. `image` and `albumArt` let a track picker skip pictures. `rescanExternalFiles()` looks again for files next to the current one, within the auto-load options. The [Metadata](https://pub.dev/documentation/mpv_audio_kit/latest/topics/Metadata-topic.html) topic covers images in the folder.

## Other settings

```dart
await player.setAudioClientName('MyMusicApp'); // the name system mixers show
await player.setAudioMediaRole(true);          // report the stream as music
await player.setAudioBuffer(const Duration(milliseconds: 500)); // default 200 ms
await player.setAudioStreamSilence(true);      // keep the device open while paused
await player.setAudioNullUntimed(true);        // the null output runs as fast as it can
await player.reloadAudio();                    // close and reopen the output
```

- The media role changes routing and per-role volume on PulseAudio and PipeWire. On Android, `audiotrack` and `aaudio` from Android 9 only tag the content as music. Other drivers ignore it.
- A smaller buffer lowers latency. A larger one copes better with load and Bluetooth.
- Streaming silence avoids a click on resume. mpv advises against it, since it changes how underruns are handled. It is untested on iOS across an interruption such as a call.
- The untimed null output processes audio on a machine with no sound device.

In the browser the page has a single output and a single sample rate. See the [Web](https://pub.dev/documentation/mpv_audio_kit/latest/topics/Web-topic.html) topic.
