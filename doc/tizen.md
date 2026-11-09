Samsung Tizen TVs run the package through [flutter-tizen](https://github.com/flutter-tizen/flutter-tizen), which runs the build hook as a Linux build of the arch of the Tizen target. The hook bundles, as `libmpv_audio_kit.so`:

| Target | Library | Runs on |
| :--- | :--- | :--- |
| arm | `libmpv_tizen-armv7l.so` | the TVs, Tizen 6.0 on (2021 and later), ARM EABI with softfp floats |
| x64, with `tizen: true` | `libmpv_tizen-x86_64.so` | the Tizen TV emulator |

## The emulator

The emulator is x64, the arch of Linux desktop too, so the app says Tizen with a user define in its `pubspec.yaml`:

```yaml
hooks:
  user_defines:
    mpv_audio_kit:
      tizen: true
```

Without it an x64 build takes the Linux desktop library. The define is `true` or `false`: any other value fails the build. A TV build, on arm, needs none.

## Audio

The library plays through `ao_tizen`, an output on Tizen's `audio_out` with the media stream type. The playback focus is the app's to take with Tizen's sound manager. The media session has no Tizen side: turning it on does nothing there.

## A libmpv of your own

The `libmpv` user define works as on the other platforms: a file, bundled for every target, or a directory with `libmpv_tizen-armv7l.so` and `libmpv_tizen-x86_64.so`. It must be a build of libmpv-scripts at the release the package pins.

## What was checked

An app built with flutter-tizen plays an asset through `ao_tizen` on the generic Tizen 10.0 emulator. The Samsung TV image of the emulator takes only apps signed with a Samsung certificate.
