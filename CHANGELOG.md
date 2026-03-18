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

### Added
- **Swift Package Manager**: Added support for SPM on iOS and macOS.

### Fixed
- **README**: Fixed broken image links on pub.dev using absolute GitHub URLs.
- **Analysis**: Enforced curly braces in flow control structures and resolved all static analysis warnings.

## [0.0.1] - 15-03-2026

### Added
- **Initial Release**: High-performance audio library for Flutter powered by `libmpv` (v0.41.0).
- **Cross-Platform Support**: Seamless playback on iOS, Android, macOS, Windows, and Linux.
- **Example App**: Included a comprehensive example app demonstrating DSP, hardware routing, and queue management.
