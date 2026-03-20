# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

if(POLICY CMP0135)
  cmake_policy(SET CMP0135 NEW)
endif()

# Project-level configuration.
set(PROJECT_NAME "mpv_audio_kit")
project(${PROJECT_NAME} LANGUAGES CXX)

# This value is used when generating builds using this plugin, so it must
# not be changed.
set(PLUGIN_NAME "mpv_audio_kit_plugin")

# ── libmpv Bundling ──────────────────────────────────────────────────────────
# The official libmpv.so.2 is automatically downloaded from GitHub Releases.
# This ensures consistency and proper audio backend support.
set(_BUNDLED_MPV "${CMAKE_CURRENT_SOURCE_DIR}/libs/libmpv.so.2")
set(MPV_RELEASE_VERSION "v0.0.1")
set(EXPECTED_SHA256 "befdb708ec8ba253ea190c5149fdbe43aa3b621bec14786d33abfaba1a9d8eaf")

set(DOWNLOAD_NEEDED TRUE)

if(EXISTS "${_BUNDLED_MPV}")
  file(SHA256 "${_BUNDLED_MPV}" ACTUAL_SHA256)
  if(ACTUAL_SHA256 STREQUAL EXPECTED_SHA256)
    set(DOWNLOAD_NEEDED FALSE)
  else()
    message(STATUS "[mpv_audio_kit] SHA-256 mismatch! Expected ${EXPECTED_SHA256} but got ${ACTUAL_SHA256}. Redownloading...")
    file(REMOVE "${_BUNDLED_MPV}")
  endif()
endif()

if(DOWNLOAD_NEEDED)
  message(STATUS "[mpv_audio_kit] Downloading libmpv_linux-x86_64.so from Github Releases...")
  file(MAKE_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/libs")
  file(DOWNLOAD 
    "https://github.com/ales-drnz/mpv_audio_kit/releases/download/${MPV_RELEASE_VERSION}/libmpv_linux-x86_64.so"
    "${_BUNDLED_MPV}"
    SHOW_PROGRESS
    EXPECTED_HASH SHA256=${EXPECTED_SHA256}
    STATUS DOWNLOAD_STATUS
  )
  list(GET DOWNLOAD_STATUS 0 STATUS_CODE)
  if(NOT STATUS_CODE EQUAL 0)
    list(GET DOWNLOAD_STATUS 1 ERROR_MSG)
    message(FATAL_ERROR "[mpv_audio_kit] Failed to download libmpv.so: ${ERROR_MSG}. Please download manually to linux/libs/libmpv.so.2")
  endif()
endif()

if(EXISTS "${_BUNDLED_MPV}")
  message(STATUS "[mpv_audio_kit] Using bundled libmpv: ${_BUNDLED_MPV}")
  add_library(mpv_bundled SHARED IMPORTED GLOBAL)
  set_target_properties(mpv_bundled PROPERTIES IMPORTED_LOCATION "${_BUNDLED_MPV}")
  set(mpv_audio_kit_bundled_libraries "${_BUNDLED_MPV}" PARENT_SCOPE)
else()
  message(FATAL_ERROR "[mpv_audio_kit] libmpv not found. It must be present in linux/libs/libmpv.so.2")
endif()

# Any new source files that you add to the plugin should be added here.
list(APPEND PLUGIN_SOURCES
  "mpv_audio_kit_plugin.cc"
)

# Define the plugin library target. Its name must not be changed (see comment
# on PLUGIN_NAME above).
add_library(${PLUGIN_NAME} SHARED
  ${PLUGIN_SOURCES}
)

# Apply a standard set of build settings that are configured in the
# application-level CMakeLists.txt. This can be removed for plugins that want
# full control over build settings.
apply_standard_settings(${PLUGIN_NAME})

# Symbols are hidden by default to reduce the chance of accidental conflicts
# between plugins. This should not be removed; any symbols that should be
# exported should be explicitly exported with the FLUTTER_PLUGIN_EXPORT macro.
set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)

# Source include directories and library dependencies. Add any plugin-specific
# dependencies here.
target_include_directories(${PLUGIN_NAME}
  INTERFACE "${CMAKE_CURRENT_SOURCE_DIR}/include"
)
target_link_libraries(${PLUGIN_NAME} PRIVATE flutter)
target_link_libraries(${PLUGIN_NAME} PRIVATE PkgConfig::GTK)