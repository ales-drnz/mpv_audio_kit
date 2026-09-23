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
  "media_session_smtc.cpp"
  "media_session_smtc.h"
  "media_session_channel_win.cpp"
  "media_session_channel_win.h"
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

# C++/WinRT needs C++20 coroutines. Under the app template's C++17 it falls
# back to <experimental/coroutine>, which MSVC 14.51 (Visual Studio 2026)
# rejects with STL1011. The highest requested standard wins, so this lifts
# only the plugin target.
target_compile_features(${PLUGIN_NAME} PRIVATE cxx_std_20)

# Source include directories and library dependencies. Add any plugin-specific
# dependencies here.
target_include_directories(${PLUGIN_NAME}
  INTERFACE "${CMAKE_CURRENT_SOURCE_DIR}/include"
)
target_link_libraries(${PLUGIN_NAME} PRIVATE flutter flutter_wrapper_plugin)

# C++/WinRT consumes SystemMediaTransportControls; link the WinRT umbrella
# import library for RoActivateInstance / WindowsCreateString etc. The
# C++/WinRT headers (winrt/Windows.Media.*) are header-only and ship with the
# Windows SDK already on the MSVC include path — no NuGet, no extra toolchain.
target_link_libraries(${PLUGIN_NAME} PRIVATE windowsapp)

# shell32 provides SetCurrentProcessExplicitAppUserModelID, used to give the
# process a stable AppUserModelID so the SystemMediaTransportControls card shows
# a consistent source identity on unpackaged .exe builds.
target_link_libraries(${PLUGIN_NAME} PRIVATE shell32)

# libmpv is not built or bundled here: the package's build hook
# (hook/build.dart) downloads it and Flutter bundles it as a code asset.
