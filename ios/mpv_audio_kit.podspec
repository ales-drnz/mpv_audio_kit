#
# mpv_audio_kit iOS podspec
#
# libmpv on iOS is distributed as a static XCFramework downloaded from GitHub
# Releases. Each slice ships as a `libmpv.framework/` static-library wrapper
# (the layout CocoaPods needs for `vendored_frameworks` linking to work).
# The xcframework includes:
#   ios-arm64           – device (arm64)
#   ios-arm64-simulator – simulator (arm64 only, Apple Silicon Macs)
# Apple removed Rosetta for the iOS 26 simulator, so x86_64 sim is no longer
# supported. EXCLUDED_ARCHS below propagates this constraint to the consumer.
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
  s.dependency 'Flutter'
  s.platform         = :ios, '15.0'

  # Required frameworks for Audio Session and Core functions
  s.frameworks = 'AVFoundation', 'AudioToolbox', 'Security', 'CoreFoundation'

  # ── Static libmpv XCFramework ─────────────────────────────────────────────
  # Automatically downloaded from GitHub Releases if missing or invalid.
  # Run `scripts/generate_checksums.sh` to get the SHA-256 for your new release.
  s.prepare_command = <<-CMD
    MPV_RELEASE_VERSION="libmpv-r5"
    EXPECTED_SHA256="9f9a47b133f1ec5ac5bde03d807f1280518251b7785ce42a515f26ae0f2933d3"
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
    # The XCFramework ships only ios-arm64-simulator (no x86_64). Exclude
    # x86_64 from simulator builds so CocoaPods' slice picker matches.
    # Apple removed Rosetta for the iOS 26 simulator; on Apple Silicon
    # x86_64 sim is no longer reachable anyway.
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386 x86_64',
    'ENABLE_BITCODE'                      => 'NO',
    'OTHER_LDFLAGS'                       => '-liconv',
  }
  # Propagate the architecture exclusion to the consuming app target so the
  # Flutter Runner doesn't ask for a x86_64-simulator slice we don't ship.
  s.user_target_xcconfig = {
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386 x86_64',
  }
  s.swift_version = '5.0'
end
