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
  # Add libmpv headers path if available in windows/libs/include
  PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/libs/include"
)
target_link_libraries(${PLUGIN_NAME} PRIVATE flutter flutter_wrapper_plugin)

# ── libmpv Bundling ──────────────────────────────────────────────────────────
# The dynamic library is automatically downloaded from GitHub Releases if 
# missing or if the checksum does not match the expected value.
if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/libs/libmpv.lib")
  target_link_libraries(${PLUGIN_NAME} PRIVATE
    "${CMAKE_CURRENT_SOURCE_DIR}/libs/libmpv.lib"
  )
endif()

set(_MPV_DLL "${CMAKE_CURRENT_SOURCE_DIR}/libs/libmpv-2.dll")
set(MPV_RELEASE_VERSION "libmpv-r1")
set(EXPECTED_SHA256 "daa14d2a58cfcd955801d80f5fb9168d64bc78732541432d3e5118551919bfa8")

set(DOWNLOAD_NEEDED TRUE)

if(EXISTS "${_MPV_DLL}")
  file(SHA256 "${_MPV_DLL}" ACTUAL_SHA256)
  if(ACTUAL_SHA256 STREQUAL EXPECTED_SHA256)
    set(DOWNLOAD_NEEDED FALSE)
  else()
    message(STATUS "[mpv_audio_kit] SHA-256 mismatch! Expected ${EXPECTED_SHA256} but got ${ACTUAL_SHA256}. Redownloading...")
    file(REMOVE "${_MPV_DLL}")
  endif()
endif()

if(DOWNLOAD_NEEDED)
  message(STATUS "[mpv_audio_kit] Downloading libmpv_windows-x86_64.dll from Github Releases...")
  file(MAKE_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/libs")
  file(DOWNLOAD 
    "https://github.com/ales-drnz/mpv_audio_kit/releases/download/${MPV_RELEASE_VERSION}/libmpv_windows-x86_64.dll"
    "${_MPV_DLL}"
    SHOW_PROGRESS
    EXPECTED_HASH SHA256=${EXPECTED_SHA256}
    STATUS DOWNLOAD_STATUS
  )
  list(GET DOWNLOAD_STATUS 0 STATUS_CODE)
  if(NOT STATUS_CODE EQUAL 0)
    list(GET DOWNLOAD_STATUS 1 ERROR_MSG)
    message(FATAL_ERROR "[mpv_audio_kit] Failed to download libmpv.dll: ${ERROR_MSG}")
  endif()
endif()

# Collect all DLLs from the libs directory to bundle them with the application.
file(GLOB _MPV_DLLS "${CMAKE_CURRENT_SOURCE_DIR}/libs/*.dll")

if(_MPV_DLLS)
  set(mpv_audio_kit_bundled_libraries
    ${_MPV_DLLS}
    PARENT_SCOPE
  )
else()
  # DLL not found in libs folder.
  message(FATAL_ERROR "[mpv_audio_kit] libmpv-2.dll not found. It must be present in windows/libs/libmpv-2.dll")
endif()

