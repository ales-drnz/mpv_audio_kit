LG webOS TVs, webOS 26 on, run the package through [flutter-webos](https://github.com/lg-flutter-webos/flutter-webos), LG's Flutter 3.38.10 for webOS. flutter-webos runs no build hook, so the package is an FFI plugin there: its `webos/CMakeLists.txt` downloads `libmpv_webos-armv7l.so` of the release the package pins, checks its SHA-256 and bundles it in the app's `lib/` as `libmpv_audio_kit_webos.so`. `MpvAudioKit.ensureInitialized` opens that file when no `libmpv` is given.

## Build

Set up flutter-webos and LG's webOS NDK as LG's guide says, then build as usual:

```sh
flutter-webos build webos --release
```

The first build downloads the library, so it needs network access. The library is 32-bit ARM, the TVs' arch: a build with `--target-arch arm64` fails, as there is no libmpv for it.

## A libmpv of your own

The `libmpv` user define of the build hook does not reach webOS. Set `MPV_AUDIO_KIT_LIBMPV` in the environment of the build instead: a file, or a directory with `libmpv_webos-armv7l.so`. It must be a build of libmpv-scripts at the release the package pins.

```sh
MPV_AUDIO_KIT_LIBMPV=/path/to/libmpv_webos-armv7l.so flutter-webos build webos --release
```

## Audio

The library plays through ALSA, the sound API of the webOS NDK. The media session has no webOS side: turning it on does nothing there.

## What was checked

LG has no emulator for native apps. A workflow of the package builds an app with flutter-webos and runs it under qemu-arm on the system libraries of the webOS NDK, the TVs' glibc and ALSA, with ALSA writing to a file: the app plays an asset past 2 seconds through ALSA, and its 440 Hz tone is in what ALSA wrote. What only a TV shows, its sandbox and its sound server, is not checked yet.
