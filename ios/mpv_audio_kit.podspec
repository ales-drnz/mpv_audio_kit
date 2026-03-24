#
# mpv_audio_kit iOS podspec
#
# libmpv on iOS is distributed as a static XCFramework downloaded from GitHub Releases.
# The xcframework includes:
#   ios-arm64                  – device (arm64)
#   ios-arm64_x86_64-simulator – simulator fat binary (arm64 + x86_64)
#
Pod::Spec.new do |s|
  s.name             = 'mpv_audio_kit'
  s.version          = '0.0.5'
  s.summary          = 'Flutter audio player powered by libmpv.'
  s.description      = <<-DESC
    High-quality audio player for Flutter, based on libmpv.
    Supports audio filters, all media formats, and streaming protocols.
  DESC
  s.homepage         = 'https://github.com/ales-drnz/mpv_audio_kit'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'mpv_audio_kit' => 'ales-drnz.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'mpv_audio_kit/Sources/mpv_audio_kit/**/*'
  s.dependency 'Flutter'
  s.platform         = :ios, '13.0'

  # Required frameworks for Audio Session and Core functions
  s.frameworks = 'AVFoundation', 'AudioToolbox', 'Security', 'CoreFoundation'

  # ── Static libmpv XCFramework ─────────────────────────────────────────────
  # Automatically downloaded from GitHub Releases if missing or invalid.
  # Run `scripts/generate_checksums.sh` to get the SHA-256 for your new release.
  s.prepare_command = <<-CMD
    MPV_RELEASE_VERSION="libmpv-r1"
    EXPECTED_SHA256="b6d0b3d9114e811d3955596c9219acedba31069973e5154411a0787772de1890"
    URL="https://github.com/ales-drnz/mpv_audio_kit/releases/download/${MPV_RELEASE_VERSION}/libmpv_ios-arm64.xcframework.zip"

    mkdir -p Frameworks
    ZIP_FILE="Frameworks/libmpv_xcframework.zip"
    DOWNLOAD_NEEDED=1

    if [ -f "Frameworks/libmpv.xcframework/Info.plist" ] && [ -f "$ZIP_FILE" ]; then
      ACTUAL_SHA256=$(shasum -a 256 "$ZIP_FILE" | awk '{ print $1 }')
      if [ "$ACTUAL_SHA256" = "$EXPECTED_SHA256" ]; then
        DOWNLOAD_NEEDED=0
      else
        echo "SHA-256 mismatch! Expected $EXPECTED_SHA256 but got $ACTUAL_SHA256. Redownloading..."
        rm -rf "Frameworks/libmpv.xcframework"
        rm -f "$ZIP_FILE"
      fi
    elif [ -d "Frameworks/libmpv.xcframework" ] && [ ! -f "$ZIP_FILE" ]; then
      DOWNLOAD_NEEDED=0
    fi

    if [ $DOWNLOAD_NEEDED -eq 1 ]; then
      echo "Downloading libmpv_ios-arm64.xcframework.zip from $URL..."
      curl -L -o "$ZIP_FILE" "$URL"

      ACTUAL_SHA256=$(shasum -a 256 "$ZIP_FILE" | awk '{ print $1 }')
      if [ "$ACTUAL_SHA256" != "$EXPECTED_SHA256" ]; then
        echo "ERROR: SHA-256 verification failed for downloaded file!"
        rm -f "$ZIP_FILE"
        exit 1
      fi

      unzip -o "$ZIP_FILE" -d Frameworks/
      rm -f "$ZIP_FILE"
    fi
  CMD

  s.vendored_frameworks = 'Frameworks/libmpv.xcframework'

  s.pod_target_xcconfig = {
    'DEFINES_MODULE'                      => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'ENABLE_BITCODE'                      => 'NO',
    'OTHER_LDFLAGS'                       => '-liconv',
  }
  s.swift_version = '5.0'
end
