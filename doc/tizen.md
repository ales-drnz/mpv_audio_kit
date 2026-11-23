Experimental: tested on the Tizen emulator, not yet on a TV.

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

The define holds for every build of the app: with it `flutter build linux` on x64 bundles the Tizen library too, which a desktop cannot load. Take it off for a desktop build of the same app.

## Audio

The library plays through `ao_tizen`, an output on Tizen's `audio_out` with the media stream type. The playback focus is the app's to take with Tizen's sound manager. The media session has no Tizen side. `setMediaSession` keeps its value in the player's state and does nothing else there: no entry in the TV's interface, no command from the remote, no artwork URL loaded, and no error.

## Building without network

The first build downloads the library of the release the package pins. To build without network, save its `libmpv_tizen-armv7l.so` and `libmpv_tizen-x86_64.so` in a directory and point the `libmpv` user define of the build hook at it, as on the other platforms.

## What was checked

An app built with flutter-tizen plays an asset through `ao_tizen` on the generic Tizen 10.0 emulator. The Samsung TV image of the emulator takes only apps signed with a Samsung certificate.
