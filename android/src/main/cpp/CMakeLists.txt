# mpv_audio_kit — Android NDK CMakeLists
#
# Questo file compila un thin wrapper C che funge da bridge per dart:ffi.
# libmpv.so deve essere fornita esternamente e posizionata in:
#   android/src/main/jniLibs/<abi>/libmpv.so
#
# COME OTTENERE libmpv.so PER ANDROID:
#   Opzione 1 — mpv-android prebuilt:
#     https://github.com/mpv-android/mpv-android/releases
#     Scarica l'AAR e estrai le .so dalle cartelle jni/
#
#   Opzione 2 — compilare da source con mpv-android build scripts:
#     https://github.com/mpv-android/mpv-android
#     ./buildscripts/build-in-docker.sh
#
#   Opzione 3 — media_kit prebuilt (versione aggiornata se disponibile):
#     https://github.com/media-kit/media-kit-libs-android-audio

cmake_minimum_required(VERSION 3.18.1)
project("mpv_audio_kit_jni")

# ── Sorgenti del wrapper ───────────────────────────────────────────────────
add_library(mpv_audio_kit_jni SHARED
  mpv_audio_kit_jni.c
)

# ── Trova libmpv prebuilt ──────────────────────────────────────────────────
# Cerca prima nella directory jniLibs del progetto
set(MPV_LIB_DIR "${CMAKE_SOURCE_DIR}/../jniLibs/${ANDROID_ABI}")

find_library(MPV_LIBRARY mpv PATHS "${MPV_LIB_DIR}" NO_DEFAULT_PATH)

if(MPV_LIBRARY)
  message(STATUS "[mpv_audio_kit] Trovata libmpv.so: ${MPV_LIBRARY}")
  target_include_directories(mpv_audio_kit_jni PRIVATE
    "${CMAKE_SOURCE_DIR}/include"
  )
  target_link_libraries(mpv_audio_kit_jni PRIVATE
    ${MPV_LIBRARY}
    android
    log
  )
else()
  message(WARNING "[mpv_audio_kit] libmpv.so non trovata per ABI=${ANDROID_ABI}. "
                  "Posizionala in android/src/main/jniLibs/${ANDROID_ABI}/libmpv.so. "
                  "Il plugin userà dart:ffi per caricarla a runtime se presente nel APK.")
  # Compila comunque un wrapper vuoto per non bloccare il build
  target_link_libraries(mpv_audio_kit_jni PRIVATE android log)
endif()
