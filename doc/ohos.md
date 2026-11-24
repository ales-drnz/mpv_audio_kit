OpenHarmony and HarmonyOS (OHOS) run the package through [Flutter-OH](https://gitcode.com/CPF-Flutter/flutter_flutter), from its 3.41.9 release on. Flutter-OH runs the build hook, which bundles, as `libmpv_audio_kit.so` in the HAP:

| Target | Library | Runs on |
| :--- | :--- | :--- |
| `ohos-arm64` | `libmpv_ohos-arm64-v8a.so` | the devices |
| `ohos-x64` | `libmpv_ohos-x86_64.so` | the emulators |

The libraries are built with the public OpenHarmony SDK against its musl, with libc++ linked in. They need only `libc.so` and `libohaudio.so` of the system, and only the calls of API 12 (HarmonyOS 5.0): the build checks their OHAudio calls and their libc imports against API 12. The app itself needs what Flutter-OH needs.

## Build

Flutter-OH tells the hook it builds for Linux. The hook recognizes OHOS by the clang of the OpenHarmony SDK that Flutter-OH passes it, and takes the OHOS library. A user define says it outright, for a toolchain the hook does not recognize:

```yaml
hooks:
  user_defines:
    mpv_audio_kit:
      ohos: true
```

`ohos: false` builds for Linux whatever the compiler. The define counts only for a Linux or OHOS target: an app that sets it still builds for Android, iOS, macOS and Windows, but `flutter build linux` then bundles the OHOS library too, which a desktop cannot load. Take the define off for a desktop Linux build of the same app. A build cannot be for Tizen and OHOS at once.

## Output

The output is `ohaudio`, a stream of OHAudio of the music usage: the system routes it, and there is no device to choose. It plays 16 or 32 bit integer samples, mono or stereo, at the rates OHAudio takes from 8 to 192 kHz. Another rate plays at the next one up, 37800 Hz at 44100 Hz, and mpv converts the rest.

- A forced pause of the system, such as a call, freezes the output, and its end resumes it.
- A forced stop with no resume after it leaves the player playing with its position frozen, until the app pauses and plays again.
- A shared interruption and an output that goes away, such as headphones unplugged, are written to `stream.log` and change nothing: the audio goes on through the output the system picks. An app that pauses there listens for them with the audio APIs of ArkTS.

## Media session and the background

`setMediaSession` publishes an AVSession of type `audio`: the System UI shows the title, the artist and the cover, and its controls reach `stream.mediaSessionCommands` and the player as on the other platforms. The actions of `MediaSession` decide which controls the system shows. The repeat and the shuffle are one loop mode on OHOS: its shuffle arrives as `setShuffle`, the others as `setRepeatMode`.

While the player plays, the package also runs the continuous task of audio playback, which keeps the app playing in the background. Without the AVSession and that task, the system mutes and freezes the audio of an app in the background. The task stops on a pause, a stop or the end, and starts again on the next play. The app declares what the system asks for it, in its `module.json5`:

```json5
{
  "module": {
    "requestPermissions": [
      { "name": "ohos.permission.KEEP_BACKGROUND_RUNNING" }
    ],
    "abilities": [
      {
        "name": "EntryAbility",
        "backgroundModes": ["audioPlayback"]
      }
    ]
  }
}
```

Without them the system refuses the task, which the app's hilog reports under the `mpv_audio_kit` tag, and the session works in the foreground only.

## Tests

The CI of libmpv-scripts plays the libraries on the Oniro emulator, OpenHarmony 7.0, x86_64 with KVM and arm64-v8a under emulation, on each release branch whose OHOS driver or build changes, and checks the tone the emulated sound card records. The CI of the package builds an x86_64 Flutter-OH app with the package, signed with the OpenHarmony debug keys, and plays a file in it on that emulator. It then turns the media session on and checks the AVSession the system holds, its title in the System UI and a command of the system that reaches the player. Playback in the background does not run there: the continuous task service of that image refuses every task. No HarmonyOS device runs these tests.
