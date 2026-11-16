What each platform has. Android TV runs the Android build, and tvOS a build of the same sources as iOS, so their rows match those platforms except where they say otherwise.

## Output

| Platform | Drivers | Devices to choose | Passthrough |
| :--- | :--- | :--- | :--- |
| Android | `audiotrack`, `aaudio`, `opensles` | None, the system routes | `audiotrack`, and `aaudio` from Android 14 |
| iOS | `audiounit`, `avfoundation` | None, the system routes | Not checked |
| macOS | `coreaudio`, `avfoundation` | CoreAudio's outputs | `coreaudio` |
| Windows | `wasapi` | WASAPI's outputs | `wasapi` |
| Linux | `pipewire`, `pulse`, `alsa` | Those of each driver | All three |
| Web | `webaudio` | None, the page's output | No |
| Android TV | As Android | As Android | As Android, over HDMI |
| tvOS | As iOS | As iOS | Not checked |
| Tizen | `tizen` | None | No |
| webOS | `alsa` | ALSA's devices | Not checked |

- Each build also has the `null` output, which plays on when no device opens.
- `auto`, the default, takes the first driver that opens, in the order of the table.
- Passthrough sends the codecs of `setAudioSpdif` as IEC61937, and the receiver must take them too. Where the driver refuses the format, the player decodes the track.
- On Android `audiotrack` carries neither TrueHD nor DTS-HD, and `MpvAudioKit.passthroughCodecs()` tells what the HDMI sink takes. It is empty elsewhere.
- No platform has audio offload. See [Output](https://pub.dev/documentation/mpv_audio_kit/latest/topics/Output-topic.html).

## Features

| Platform | Media session | `smb2://` | Analysis | Live PCM | Embedded cover |
| :--- | :--- | :--: | :--: | :--: | :--: |
| Android | Media notification | Yes | Yes | Yes | Yes |
| iOS | Now Playing, Control Center, lock screen | Yes | Yes | Yes | Yes |
| macOS | Now Playing, Control Center | Yes | Yes | Yes | Yes |
| Windows | SMTC | Yes | Yes | Yes | Yes |
| Linux | MPRIS | Yes | Yes | Yes | Yes |
| Web | `navigator.mediaSession` | No | Yes | Yes | Yes |
| Android TV | As Android, for the remote's keys | Yes | Yes | Yes | Yes |
| tvOS | Now Playing | Yes | Yes | Yes | Yes |
| Tizen | None | Yes | Yes | Yes | Yes |
| webOS | None | Yes | Yes | Yes | Yes |

- Analysis is the spectrum, the PCM stream, the taps, the waveform and the loudness scan and meter. While a track passes through, the spectrum, the PCM stream, the taps and the meter emit nothing.
- Live PCM is `Player.openPcmStream`.
- Embedded cover is `stream.coverArt`. The OS media session shows it where there is one.
- On Tizen and webOS, `setMediaSession` keeps its value in the player's state and does nothing else.

## Sources

| Source | Where |
| :--- | :--- |
| `file://` | Every platform except the web |
| `asset:///` | Every platform |
| `content://` | Android and Android TV |
| `http://`, `https://`, HLS, DASH | Every platform. On the web the browser fetches them, under its own rules. |
| `blob:`, `Media.fromBlob` | The web only |

## Web only

- `MpvAudioKit.unsupportedReason` tells why a page cannot run libmpv.
- `MpvAudioKit.needsUserGesture` and `needsUserGestureStream` tell when the browser holds the sound.
- One output and one sample rate serve the whole page.

See the [Web](https://pub.dev/documentation/mpv_audio_kit/latest/topics/Web-topic.html) topic.

## Where this comes from

- The drivers and `smb2://` are those the libmpv build of each target enables. The web build has no SMB client.
- A device list comes from the driver. A driver without one leaves the choice to the system.
- The media session rows follow [Media session](https://pub.dev/documentation/mpv_audio_kit/latest/topics/Media%20session-topic.html), [Tizen](https://pub.dev/documentation/mpv_audio_kit/latest/topics/Tizen-topic.html) and [webOS](https://pub.dev/documentation/mpv_audio_kit/latest/topics/webOS-topic.html).
- "Not checked" means the driver's code does not settle it and no test plays it.
