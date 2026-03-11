# libmpv Release and Versioning Workflow

This directory contains standalone scripts for cross-compiling the `libmpv` library across all supported platforms of the `mpv_audio_kit` Flutter plugin.

As a maintainer of this plugin, downloading pre-built binaries instead of compiling them on the end user's machine significantly reduces build time, eliminates complex system requirements, and provides a stable, reproducible experience across all platforms. 

The `mpv_audio_kit` workflow uses **GitHub Releases** to distribute these pre-compiled libraries. To avoid corrupted downloads, the plugin natively implements **SHA-256 Checksums validation**.

## Step-by-Step Workflow

Whenever `mpv` requires an update or you make changes to these build scripts:

### 1. Build the Libraries
Run the individual build scripts for each platform. 

```bash
cd scripts/
./build_libmpv_android.sh
./build_libmpv_ios.sh
./build_libmpv_macos.sh
./build_libmpv_windows.sh
./build_libmpv_linux.sh
```

These scripts will compile everything to static lengths and automatically export the resulting architectures (e.g., `libmpv_android-x86_64.so`, `libmpv_macos-universal.dylib`) into the `release_builds/` directory at the project root.

### 2. Generate Checksums
Before uploading the newly compiled artifacts, you must generate their unique cryptographic fingerprint to protect end users against corrupted packets or partial downloads.

Run the checksum utility:

**On Linux/macOS:**
```bash
cd scripts/
./generate_checksums.sh
```

**On Windows:**
```powershell
cd scripts
.\generate_checksums.ps1
```

This script reads all files in `release_builds/` and outputs a `release_builds/checksums.txt` file alongside them, presenting exactly what you need to integrate into the plugin code.

### 3. Commit the Release on GitHub
1. Go to your repository on GitHub.
2. Draft a new Release. Choose a version tag (e.g., `v1.0.0`).
3. Drag and drop all the files generated within the `release_builds/` directory into the assets attached to the Release.
4. Publish the Release.

### 4. Update Plugin Scripts
Now that your new assets are hosted on GitHub, you must tell the `mpv_audio_kit` plugin to point to them instead of the older versions and provide the new checksum values to validate.

You will need to update the following plugin files manually. In every file listed below, you will find a variable at the top (e.g., `MPV_RELEASE_VERSION = "v1.0.0"`) and an array containing the hashes matching the new files.

- **Android:** `android/build.gradle.kts`
- **iOS:** `ios/mpv_audio_kit.podspec`
- **macOS:** `macos/mpv_audio_kit.podspec`
- **Windows:** `windows/CMakeLists.txt`
- **Linux:** `linux/CMakeLists.txt`

Replace the previous URLs and SHA-256 strings with the ones you generated in step 2.

### 5. Publish to Pub.dev
Update the Dart plugin version in your `pubspec.yaml` (e.g. from `1.0.0` to `1.0.1`) and run `flutter pub publish`.

When end users fetch the new plugin version, their build system (Gradle/CocoaPods/CMake) will detect the new GitHub URL, download the respective library, confirm the checksum matches the hardcoded one, and embed the binary directly inside the Flutter app.
