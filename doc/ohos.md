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

`ohos: false` builds for Linux whatever the compiler. The define counts only for a Linux or OHOS target, so an app that sets it still builds for Android, iOS or the desktop. A build cannot be for Tizen and OHOS at once.

## Output

The output is `ohaudio`, a stream of OHAudio of the music usage: the system routes it, and there is no device to choose. It plays 16 or 32 bit integer samples, mono or stereo, at the rates OHAudio takes from 8 to 192 kHz. Another rate plays at the next one up, 37800 Hz at 44100 Hz, and mpv converts the rest.

- A forced pause of the system, such as a call, freezes the output, and its end resumes it.
- A forced stop with no resume after it leaves the player playing with its position frozen, until the app pauses and plays again.
- A shared interruption and an output that goes away, such as headphones unplugged, are written to `stream.log` and change nothing: the audio goes on through the output the system picks. An app that pauses there listens for them with the audio APIs of ArkTS.

## Media session and the background

The package has no media session on OHOS: `setMediaSession` keeps its value in the player's state and does nothing else, and the package starts no background task. To play in the background, OpenHarmony and HarmonyOS want two things of the app, in ArkTS:

- An AVSession of type `audio`, created when playback starts and kept alive, with its metadata and the play and pause commands registered. Without it the system mutes and freezes the audio when the app goes to the background.
- A continuous task of type `audioPlayback`: the `ohos.permission.KEEP_BACKGROUND_RUNNING` permission, `backgroundModes: ["audioPlayback"]` on the ability, and `backgroundTaskManager.startBackgroundRunning`. The system stops the task when an interruption stops the audio. The app cancels it on a pause and asks for it again when playback resumes.

## Tests

The CI of libmpv-scripts plays the libraries on the Oniro emulator, OpenHarmony 7.0, x86_64 with KVM and arm64-v8a under emulation, on each release branch whose OHOS driver or build changes, and checks the tone the emulated sound card records. The CI of the package builds an x86_64 Flutter-OH app with the package, signed with the OpenHarmony debug keys, and plays a file in it on that emulator. No HarmonyOS device runs these tests.
