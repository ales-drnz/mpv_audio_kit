## [0.0.6] - 08-04-2026

- **Core**: Added SMB2/3 protocol support (`smb2://`) for Samba/CIFS network shares via patched libsmb2.
- **Core**: Typed error stream — `Stream<MpvPlayerError>` (sealed: `MpvEndFileError`, `MpvLogError`) replaces `Stream<String>`.
- **Core**: Added `stream.endFile` (`MpvFileEndedEvent`) for all file-end events, including premature EOF detection.
- **Core**: Added `stream.pausedForCache` and `stream.demuxerViaNetwork` for network state monitoring.
- **Core**: Added optional `timeout` parameter to `registerHook` for automatic safety continuation.
- **Fixed**: Incorrect name for audio-stream-silence property.
- **Build**: Updated libmpv binaries from `libmpv-r1` to `libmpv-r2` across all platforms.

## [0.0.5+1] - 30-03-2026

- **README**: Improved documentation.

## [0.0.5] - 24-03-2026

- **Core**: Added stream hooks API (`registerHook`, `continueHook`, `player.stream.hook`) to intercept mpv's file-loading pipeline.
- **README**: Documentation fixes and consistency improvements.

## [0.0.4] - 23-03-2026

- **Core**: Added new APIs to configure embedded and external cover art handling (`setAudioDisplay`, `setCoverArtAuto`, `setImageDisplayDuration`).
- **Core**: Fast jump into playlist now automatically starts playback.
- **Example**: Refined Queue tab design and improved stability.
- **Example**: Added new sliders to DSP filters.

## [0.0.3+2] - 21-03-2026

- Minor fixes.

## [0.0.3+1] - 21-03-2026

- **GitHub Release**: New tag system for versioning libmpv binaries to avoid conflicts with the same release on GitHub. From now on every important update to libmpv (like 0.0.3 Linux fix) will have a new tag and a new release (libmpv-r1, libmpv-r2, etc.). This avoids confusion with the pub version number and ensures users with old SHAs can still use their version when downloading instead of breaking the build.

## [0.0.3] - 21-03-2026

- **Linux**: Bumped minimum supported OS version to Ubuntu 24.04 required because `mpv 0.41.0` enforced a strict dependency on `libpipewire-0.3 >= 0.3.57` for its native PipeWire backend.
- **README**: Added a detailed *Troubleshooting* section in the README explaining how to correctly satisfy Linux system dependencies when building on containers.
- **Example**: Fixed AO menu not showing the default driver automatically.

## [0.0.2+3] - 20-03-2026

- Updated Linux libmpv, ALSA, Pipewire and Pulse now all work without external dependencies.

## [0.0.2+2] - 18-03-2026

- Cleaned up files.

## [0.0.2+1] - 17-03-2026

- Minor fixes.

## [0.0.2] - 17-03-2026

- New extended documentation.
- Fixed filepicker on macOS.
- Restructured settings UI in example app by mpv property each have their own dedicated page and stream lab moved to main navigation.
- Other audio engine fixes.

## [0.0.1+9] - 16-03-2026

- Re-added audiounit driver together with avfoundation in libmpv for iOS. Audio_service now works with both.
- Added new option to choose AO driver in example app.
- Added audio_service to example app to test native controls of the OS.

## [0.0.1+8] - 16-03-2026

- Removed audiounit driver from libmpv to fix native iOS widget for audio control when using audio_service library.
- Fixed filepicker error in example app.

## [0.0.1+7] - 16-03-2026

- Fixed macOS libs build.

## [0.0.1+6] - 15-03-2026

- Fixed shuffle bug.

## [0.0.1+5] - 15-03-2026

- Minor fixes.

## [0.0.1+4] - 15-03-2026

- Minor fixes.

## [0.0.1+3] - 15-03-2026

- Minor fixes.

## [0.0.1+2] - 15-03-2026

- Minor fixes.

## [0.0.1+1] - 15-03-2026

- **Swift Package Manager**: Added support for SPM on iOS and macOS.
- **README**: Fixed broken image links on pub.dev using absolute GitHub URLs.
- **Analysis**: Enforced curly braces in flow control structures and resolved all static analysis warnings.

## [0.0.1] - 15-03-2026

- **Initial Release**: High-performance audio library for Flutter powered by `libmpv` (v0.41.0).
- **Cross-Platform Support**: Seamless playback on iOS, Android, macOS, Windows, and Linux.
- **Example App**: Included a comprehensive example app demonstrating DSP, hardware routing, and queue management.
