# Developer Guide: Architecture & Build System

This document explains the internal architecture of `mpv_audio_pro_kit` and how to maintain the build system.

## Core Architecture: The Isolate Event Loop

Unlike many Flutter plugins that run their event loops on the main thread (causing UI jank), this library uses a dedicated **Dart Isolate** (`MpvEventIsolate`) to bridge with `libmpv`.

### How it works:
1. **Host Isolate (Main):** Spawns the `Player` instance and sends the `mpv_handle` address to the background.
2. **Event Isolate:** Runs a blocking `while(true)` loop calling `mpv_wait_event`. 
3. **Communication:** Events are serialized into typed Dart objects (e.g., `MpvEventPropertyDouble`) and sent through a `ReceivePort` to the main isolate.
4. **Performance:** This ensures that even under heavy event volume (e.g., rapid position updates or log messages), the Flutter UI remains at a locked 60/120 FPS.

## API Principles

The API is designed for **modern Dart** and **Audio-first** performance:
- **Duration Everywhere:** All time-based properties (`position`, `duration`, `buffer`) use the `Duration` type.
- **Immutable State:** Current player state is accessed via an immutable `PlayerState` object with `copyWith` support, matched by individual broadcast streams in `player.stream.*`.
- **Type Safety:** Enums are used for `PlaylistMode`, `ReplayGainMode`, and `GaplessMode`.

## Building Native Libraries

The `scripts/` directory contains automation for cross-compiling `libmpv` for all supported platforms.

### Environment Setup
Ensure you have the following installed:
- Darwin (macOS/iOS): Xcode, Homebrew, `autoconf`, `libtool`, `pkg-config`.
- Linux: `gcc`, `meson`, `ninja`.
- Windows: MSVC / Clang, `meson`, `ninja`.
- Android: NDK, `meson`.

### Scripts Overview
- `build_all.sh`: (Planned) Orchestrates builds for all platforms.
- `build_libmpv_macos.sh`: Produces `libmpv.2.dylib`.
- `build_libmpv_ios.sh`: Produces `libmpv.xcframework` (Static).
- `build_libmpv_android.sh`: Produces `.so` files for all ABIs.
- `version_sync.sh`: (Planned) Ensures the plugin version matches the library versioning.

## Development Workflow
1. **Modify FFI Bindings:** Updates to `mpv_bindings.dart` should be done manually while strictly following the `libmpv` headers.
2. **Isolate Updates:** If adding new event types, update the `MpvIsolateEvent` hierarchy in `event_isolate.dart`.
3. **Public API:** Always expose features through both the `Player` methods and the `PlayerState` snapshot.

---
*Created by Antigravity AI — Optimized for Professional Audio Applications.*
