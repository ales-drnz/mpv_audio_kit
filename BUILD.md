# Building libmpv from source

This document covers building the native `libmpv` shared libraries for each
platform. Pre-built binaries are **not** included in the repository due to
size constraints — run the relevant script before first use.

All scripts live in `scripts/` and download mpv + all dependencies
automatically. A working internet connection is required.

---

## macOS

Prerequisites: Xcode Command Line Tools, Homebrew.

```bash
rm -rf /tmp/mpv_audio_kit_build/
bash scripts/build_libmpv_macos.sh
```

Output: `macos/libs/libmpv.dylib` (arm64).  
Build time: ~60–90 min on Apple Silicon.

### After a clean rebuild

If `cfstr_patch/` is present (legacy workaround — see `cfstr_patch/README.md`),
remove it and revert the podspec to a single-dylib setup:

1. Delete `cfstr_patch/`
2. In `macos/mpv_audio_kit.podspec` remove the `BUNDLED_INNER` block and the
   second `output_files` entry.

---

## iOS

Prerequisites: Xcode, CocoaPods.

```bash
bash scripts/build_libmpv_ios.sh
```

Output: `ios/libs/libmpv.xcframework` (arm64 device + arm64 simulator).

---

## Android

Prerequisites: Android NDK (set `ANDROID_NDK_HOME`), CMake.

```bash
bash scripts/build_libmpv_android.sh
```

Output: `android/src/main/jniLibs/{arm64-v8a,armeabi-v7a,x86_64}/libmpv.so`.

---

## Linux

Prerequisites: `apt install build-essential python3-pip meson ninja-build`.

```bash
bash scripts/build_libmpv_linux.sh
```

Output: `linux/libs/libmpv.so`.

---

## Windows

Prerequisites: MSYS2 with MinGW-w64, Python 3.

```bash
bash scripts/build_libmpv_windows.sh
```

Output: `windows/libs/libmpv-2.dll`.

---

## Running the example app

After building the native library for your target platform:

```bash
cd example
flutter pub get
flutter run -d macos       # or: linux / windows / <device-id>
```

To run on a connected iOS device:

```bash
cd example/ios
pod install
cd ..
flutter run -d <ios-device-id>
```
