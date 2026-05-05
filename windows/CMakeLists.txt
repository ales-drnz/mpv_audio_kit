# The Flutter tooling requires that developers have a version of Visual Studio
# installed that includes CMake 3.14 or later. You should not increase this
# version, as doing so will cause the plugin to fail to compile for some
# customers of the plugin.
cmake_minimum_required(VERSION 3.14)

# Project-level configuration.
set(PROJECT_NAME "mpv_audio_kit")
project(${PROJECT_NAME} LANGUAGES CXX)

# Explicitly opt in to modern CMake behaviors to avoid warnings with recent
# versions of CMake.
cmake_policy(VERSION 3.14...3.25)

if(POLICY CMP0135)
  cmake_policy(SET CMP0135 NEW)
endif()

# This value is used when generating builds using this plugin, so it must
# not be changed
set(PLUGIN_NAME "mpv_audio_kit_plugin")

# Any new source files that you add to the plugin should be added here.
list(APPEND PLUGIN_SOURCES
  "mpv_audio_kit_plugin.cpp"
  "mpv_audio_kit_plugin.h"
)

# Define the plugin library target. Its name must not be changed (see comment
# on PLUGIN_NAME above).
add_library(${PLUGIN_NAME} SHARED
  "include/mpv_audio_kit/mpv_audio_kit_plugin_c_api.h"
  "mpv_audio_kit_plugin_c_api.cpp"
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
  # libmpv headers (optional; populate windows/libs/include/ if needed).
  PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/libs/include"
)
target_link_libraries(${PLUGIN_NAME} PRIVATE flutter flutter_wrapper_plugin)

# ── libmpv Bundling ──────────────────────────────────────────────────────────
# libmpv.dll is auto-downloaded from GitHub Releases per target arch. Two
# arches are supported (x86_64, arm64) and the binaries live in arch-scoped
# subdirectories: windows/libs/<arch>/libmpv.dll. The CMake config detects
# the build's target arch and picks the matching subdir.
set(MPV_RELEASE_VERSION "libmpv-r5")
set(EXPECTED_SHA256_X86_64  "14e0eeaa3d29d6ba11969443de5a6a31c25bc9d4db04e66b5b4cad58188e7368")
set(EXPECTED_SHA256_ARM64  "140a3fc6ebed13e83cbcad5d4abfeac23ec8d688604ebcdb63abcf62e18234a7")

if(CMAKE_SYSTEM_PROCESSOR MATCHES "^(ARM64|arm64|aarch64)$")
  set(_MPV_ARCH "arm64")
  set(_MPV_RELEASE_NAME "libmpv_windows-arm64.dll")
  set(_MPV_EXPECTED_SHA "${EXPECTED_SHA256_ARM64}")
elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "^(AMD64|x86_64|amd64)$")
  set(_MPV_ARCH "x86_64")
  set(_MPV_RELEASE_NAME "libmpv_windows-x86_64.dll")
  set(_MPV_EXPECTED_SHA "${EXPECTED_SHA256_X86_64}")
else()
  message(FATAL_ERROR "[mpv_audio_kit] Unsupported Windows arch: ${CMAKE_SYSTEM_PROCESSOR}. Supported: x86_64 (AMD64), arm64 (ARM64).")
endif()

set(_MPV_LIB_DIR "${CMAKE_CURRENT_SOURCE_DIR}/libs/${_MPV_ARCH}")
set(_MPV_DLL "${_MPV_LIB_DIR}/libmpv.dll")

# Optional import library (only used when statically linking against the DLL).
if(EXISTS "${_MPV_LIB_DIR}/libmpv.lib")
  target_link_libraries(${PLUGIN_NAME} PRIVATE "${_MPV_LIB_DIR}/libmpv.lib")
endif()

set(DOWNLOAD_NEEDED TRUE)
if(EXISTS "${_MPV_DLL}")
  file(SHA256 "${_MPV_DLL}" ACTUAL_SHA256)
  if(ACTUAL_SHA256 STREQUAL _MPV_EXPECTED_SHA)
    set(DOWNLOAD_NEEDED FALSE)
  else()
    message(STATUS "[mpv_audio_kit] SHA-256 mismatch for ${_MPV_ARCH}: expected ${_MPV_EXPECTED_SHA} but got ${ACTUAL_SHA256}. Redownloading...")
    file(REMOVE "${_MPV_DLL}")
  endif()
endif()

if(DOWNLOAD_NEEDED)
  message(STATUS "[mpv_audio_kit] Downloading ${_MPV_RELEASE_NAME} from GitHub Releases...")
  file(MAKE_DIRECTORY "${_MPV_LIB_DIR}")
  file(DOWNLOAD
    "https://github.com/ales-drnz/mpv_audio_kit/releases/download/${MPV_RELEASE_VERSION}/${_MPV_RELEASE_NAME}"
    "${_MPV_DLL}"
    SHOW_PROGRESS
    EXPECTED_HASH SHA256=${_MPV_EXPECTED_SHA}
    STATUS DOWNLOAD_STATUS
  )
  list(GET DOWNLOAD_STATUS 0 STATUS_CODE)
  if(NOT STATUS_CODE EQUAL 0)
    list(GET DOWNLOAD_STATUS 1 ERROR_MSG)
    message(FATAL_ERROR "[mpv_audio_kit] Failed to download ${_MPV_RELEASE_NAME}: ${ERROR_MSG}. Place it manually at ${_MPV_DLL}")
  endif()
endif()

# Bundle the DLL with the application output.
if(EXISTS "${_MPV_DLL}")
  set(mpv_audio_kit_bundled_libraries
    "${_MPV_DLL}"
    PARENT_SCOPE
  )
else()
  message(FATAL_ERROR "[mpv_audio_kit] libmpv.dll not found. It must be present at ${_MPV_DLL}")
endif()
