#
# mpv_audio_kit macOS podspec
#
# libmpv is bundled as a .dylib and copied into the app's Frameworks folder
# during the build phase. This ensures a portable zero-install experience.
#

Pod::Spec.new do |s|
  s.name             = 'mpv_audio_kit'
  s.version          = '0.1.0'
  s.summary          = 'Flutter audio player powered by libmpv.'
  s.description      = <<-DESC
    Supports audio filters, pitch control, equalizer, and all mpv audio features.
  DESC
  s.homepage         = 'https://github.com/ales-drnz/mpv_audio_kit'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'mpv_audio_kit' => 'ales-drnz.com' }

  s.source           = { :path => '.' }
  s.source_files     = 'mpv_audio_kit/Sources/mpv_audio_kit/**/*'

  s.dependency 'FlutterMacOS'

  s.platform    = :osx, '12.0'
  s.swift_version = '5.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }

  # ── Download libmpv.dylib from github releases ────────────────────────────
  # Automatically downloaded if missing or invalid.
  # Run `scripts/generate_checksums.sh` to get the SHA-256 for your new release.
  s.prepare_command = <<-CMD
    MPV_RELEASE_VERSION="libmpv-r5"
    EXPECTED_SHA256="daa06716ba6ed2de1542713fa11848801faae83b14548c26de9348f123ff69a5"
    URL="https://github.com/ales-drnz/mpv_audio_kit/releases/download/${MPV_RELEASE_VERSION}/libmpv_macos-arm64.dylib"
    FILE_DEST="libs/libmpv.dylib"
    
    mkdir -p libs
    DOWNLOAD_NEEDED=1
    
    if [ -f "$FILE_DEST" ]; then
      ACTUAL_SHA256=$(shasum -a 256 "$FILE_DEST" | awk '{ print $1 }')
      if [ "$ACTUAL_SHA256" = "$EXPECTED_SHA256" ]; then
        DOWNLOAD_NEEDED=0
      else
        echo "SHA-256 mismatch! Expected $EXPECTED_SHA256 but got $ACTUAL_SHA256. Redownloading..."
        rm -f "$FILE_DEST"
      fi
    fi

    if [ $DOWNLOAD_NEEDED -eq 1 ]; then
      echo "Downloading libmpv_macos-arm64.dylib from $URL..."
      curl -L -o "$FILE_DEST" "$URL"
      
      ACTUAL_SHA256=$(shasum -a 256 "$FILE_DEST" | awk '{ print $1 }')
      if [ "$ACTUAL_SHA256" != "$EXPECTED_SHA256" ]; then
        echo "ERROR: SHA-256 verification failed for downloaded file!"
        rm -f "$FILE_DEST"
        exit 1
      fi
    fi
  CMD

  # ── Copy libmpv.dylib into App Bundle ─────────────────────────────────────
  # The dylib is copied to Runner.app/Contents/Frameworks/ and found by
  # DynamicLibrary.open('libmpv.dylib') via the app's rpath.
  s.script_phases = [
    {
      :name               => 'Copy libmpv into Frameworks',
      :execution_position => :after_compile,
      # Declare output file so Xcode can skip the script if already up to date.
      :output_files       => [
        '${TARGET_BUILD_DIR}/${WRAPPER_NAME}/Versions/A/libmpv.dylib',
      ],
      :script             => <<~SHELL,
        set -e
        DEST="${TARGET_BUILD_DIR}/${WRAPPER_NAME}/Versions/A"
        mkdir -p "$DEST"

        # Official bundled libmpv.dylib
        SRC="${PODS_TARGET_SRCROOT}/libs/libmpv.dylib"

        if [ ! -f "$SRC" ]; then
          echo "error: libmpv.dylib not found. Download it from GitHub or place it in macos/libs/libmpv.dylib"
          exit 1
        fi

        cp "$SRC" "$DEST/libmpv.dylib"
        chmod +w "$DEST/libmpv.dylib"
        
        # Update install name and sign the library
        install_name_tool -id "@rpath/libmpv.dylib" "$DEST/libmpv.dylib" 2>/dev/null
        codesign --force --sign "${EXPANDED_CODE_SIGN_IDENTITY:-}" \
          "$DEST/libmpv.dylib" 2>/dev/null || \
        codesign --force --sign - "$DEST/libmpv.dylib"
      SHELL
    }
  ]
end
