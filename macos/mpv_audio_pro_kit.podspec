#
# mpv_audio_pro_kit macOS podspec
#
# La dylib libmpv viene copiata in Runner.app/Contents/Frameworks/ tramite
# uno script_phase, che è il metodo più affidabile per i plugin Flutter/FFI.
# (Usato anche da media_kit_libs_macos_video)
#
# Esegui scripts/setup_libs.sh per preparare macos/libs/libmpv.dylib.
# Se non esiste, il build cerca libmpv in Homebrew (sviluppo locale).
#

Pod::Spec.new do |s|
  s.name             = 'mpv_audio_pro_kit'
  s.version          = '0.0.1'
  s.summary          = 'Flutter audio player powered by libmpv.'
  s.description      = <<-DESC
    High-quality audio player for Flutter, based on libmpv.
    Supports audio filters (equalizer, compressor, loudnorm, pitch/tempo),
    all media formats supported by mpv, and streaming protocols.
  DESC
  s.homepage         = 'https://github.com/your-org/mpv_audio_pro_kit'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'mpv_audio_pro_kit' => 'dev@example.com' }

  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'

  s.dependency 'FlutterMacOS'

  s.platform    = :osx, '10.14'
  s.swift_version = '5.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }

  # ── Download libmpv.dylib from github releases ────────────────────────────
  # Automatically downloaded if missing or invalid.
  # Run `scripts/generate_checksums.sh` to get the SHA-256 for your new release.
  s.prepare_command = <<-CMD
    MPV_RELEASE_VERSION="v0.0.1"
    EXPECTED_SHA256="PUT_MACOS_DYLIB_SHA256_HERE"
    URL="https://github.com/my-org/mpv_audio_kit/releases/download/${MPV_RELEASE_VERSION}/libmpv_macos-universal.dylib"
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
      echo "Downloading libmpv_macos-universal.dylib from $URL..."
      curl -L -o "$FILE_DEST" "$URL"
      
      ACTUAL_SHA256=$(shasum -a 256 "$FILE_DEST" | awk '{ print $1 }')
      if [ "$ACTUAL_SHA256" != "$EXPECTED_SHA256" ]; then
        echo "ERROR: SHA-256 verification failed for downloaded file!"
        rm -f "$FILE_DEST"
        exit 1
      fi
    fi
  CMD

  # ── Copia libmpv.dylib nel bundle dell'app ────────────────────────────────
  # Cerca prima macos/libs/libmpv.dylib (bundlato), poi Homebrew (sviluppo).
  # La dylib finisce in Runner.app/Contents/Frameworks/ e viene trovata da
  # DynamicLibrary.open('libmpv.dylib') grazie all'rpath dell'app.
  s.script_phases = [
    {
      :name               => 'Copy libmpv into Frameworks',
      :execution_position => :after_compile,
      # Output file dichiarato → Xcode salta lo script se è già aggiornato.
      :output_files       => [
        '${TARGET_BUILD_DIR}/${WRAPPER_NAME}/Versions/A/libmpv.dylib',
      ],
      :script             => <<~SHELL,
        set -e
        DEST="${TARGET_BUILD_DIR}/${WRAPPER_NAME}/Versions/A"
        mkdir -p "$DEST"

        # 1) Dylib bundlata nel plugin
        BUNDLED="${PODS_ROOT}/../../../macos/libs/libmpv.dylib"

        # 2) Homebrew (fallback sviluppo locale)
        BREW_ARM="/opt/homebrew/opt/mpv/lib/libmpv.dylib"
        BREW_INTEL="/usr/local/opt/mpv/lib/libmpv.dylib"

        if [ -f "$BUNDLED" ]; then
          SRC="$BUNDLED"
        elif [ -f "$BREW_ARM" ]; then
          SRC="$BREW_ARM"
        elif [ -f "$BREW_INTEL" ]; then
          SRC="$BREW_INTEL"
        else
          echo "error: libmpv.dylib non trovata. Esegui scripts/setup_libs.sh oppure: brew install mpv"
          exit 1
        fi

        cp "$SRC" "$DEST/libmpv.dylib"
        chmod +w "$DEST/libmpv.dylib"
        # Ridirezione stderr per silenziare il warning di invalidazione firma
        install_name_tool -id "@rpath/libmpv.dylib" "$DEST/libmpv.dylib" 2>/dev/null
        codesign --force --sign "${EXPANDED_CODE_SIGN_IDENTITY:-}" \
          "$DEST/libmpv.dylib" 2>/dev/null || \
        codesign --force --sign - "$DEST/libmpv.dylib"

        # Copy libmpv_inner.dylib if present (provides cfstr_* symbols via wrapper)
        if [ -f "$BUNDLED_INNER" ]; then
          cp "$BUNDLED_INNER" "$DEST/libmpv_inner.dylib"
          chmod +w "$DEST/libmpv_inner.dylib"
          codesign --force --sign "${EXPANDED_CODE_SIGN_IDENTITY:-}" \
            "$DEST/libmpv_inner.dylib" 2>/dev/null || \
          codesign --force --sign - "$DEST/libmpv_inner.dylib"
        fi
      SHELL
    }
  ]
end
