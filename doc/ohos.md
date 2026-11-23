OpenHarmony and HarmonyOS (OHOS) run the package through [Flutter-OH](https://gitcode.com/CPF-Flutter/flutter_flutter), from its 3.41.9 release on. Flutter-OH runs the build hook, which bundles, as `libmpv_audio_kit.so` in the HAP:

| Target | Library | Runs on |
| :--- | :--- | :--- |
| `ohos-arm64` | `libmpv_ohos-arm64-v8a.so` | phones, tablets, TVs |
| `ohos-x64` | `libmpv_ohos-x86_64.so` | the emulators |

The libraries are built with the public OpenHarmony SDK against its musl, with libc++ linked in: they need only `libc.so` and `libohaudio.so` of the system, and the OHAudio calls of API 12 (HarmonyOS 5.0) or older.

## Build

Flutter-OH tells the hook it builds for Linux. The hook recognizes OHOS by the clang of the OpenHarmony SDK that Flutter-OH passes it, and takes the OHOS library. A user define says it outright, for a toolchain the hook does not recognize:

```yaml
hooks:
  user_defines:
    mpv_audio_kit:
      ohos: true
```

`ohos: false` builds for Linux whatever the compiler. A build cannot be for Tizen and OHOS at once.

## Output

The output is `ohaudio`, a stream of OHAudio: the system routes it, and there is no device to choose. It plays 16 or 32 bit integer samples, mono or stereo, from 8 to 192 kHz, and mpv converts the rest. A forced pause of the system (a call) freezes it and its end resumes it. A shared interruption and an output that goes away are logged, and left to the app.

## Media session

The package has no media session on OHOS: `setMediaSession` keeps its value in the player's state and does nothing else, and the package starts no background task. An app that plays in the background asks for `ohos.permission.KEEP_BACKGROUND_RUNNING`, declares `backgroundModes: ["audioPlayback"]` on its ability and starts the task with `backgroundTaskManager.startBackgroundRunning`.

## Tests

The CI of libmpv-scripts plays the libraries on the Oniro emulator, OpenHarmony 7.0, x86_64 with KVM and arm64-v8a under emulation, and checks the tone the emulated sound card records. The CI of the package builds a Flutter-OH app with the package, signed with the OpenHarmony debug keys, and plays a file in it on that emulator.
