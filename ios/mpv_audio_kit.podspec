#
# mpv_audio_kit iOS podspec
#
# libmpv su iOS deve essere distribuita come XCFramework statica.
# Usa il progetto mpv-build oppure scarica un binario precompilato.
# Metti il file in ios/Frameworks/libmpv.xcframework
#
# Alternativa: compilare da source con:
#   https://github.com/mpv-player/mpv/blob/master/DOCS/compile-howto.rst
#
Pod::Spec.new do |s|
  s.name             = 'mpv_audio_kit'
  s.version          = '0.0.1'
  s.summary          = 'Flutter audio player powered by libmpv.'
  s.description      = <<-DESC
    High-quality audio player for Flutter, based on libmpv.
    Supports audio filters, all media formats, and streaming protocols.
  DESC
  s.homepage         = 'https://github.com/your-org/mpv_audio_kit'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'mpv_audio_kit' => 'dev@example.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform         = :ios, '13.0'

  # Necessario per gestire la Audio Session
  s.frameworks = 'AVFoundation', 'AudioToolbox', 'Security', 'CoreFoundation'

  # ── Static libmpv XCFramework ─────────────────────────────────────────────
  # Automatically downloaded from GitHub releases if missing or invalid.
  # Run `scripts/generate_checksums.sh` to get the SHA-256 for your new release.
  s.prepare_command = <<-CMD
    MPV_RELEASE_VERSION="v0.0.1"
    EXPECTED_SHA256="PUT_IOS_ZIP_SHA256_HERE"
    URL="https://github.com/my-org/mpv_audio_kit/releases/download/${MPV_RELEASE_VERSION}/libmpv_ios.xcframework.zip"
    
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
      # If the folder exists but no zip exists, we assume it's manually placed by dev. 
      DOWNLOAD_NEEDED=0
    fi

    if [ $DOWNLOAD_NEEDED -eq 1 ]; then
      echo "Downloading libmpv_ios.xcframework.zip from $URL..."
      curl -L -o "$ZIP_FILE" "$URL"
      
      ACTUAL_SHA256=$(shasum -a 256 "$ZIP_FILE" | awk '{ print $1 }')
      if [ "$ACTUAL_SHA256" != "$EXPECTED_SHA256" ]; then
        echo "ERROR: SHA-256 verification failed for downloaded file!"
        rm -f "$ZIP_FILE"
        exit 1
      fi
      
      unzip -o "$ZIP_FILE" -d Frameworks/
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
