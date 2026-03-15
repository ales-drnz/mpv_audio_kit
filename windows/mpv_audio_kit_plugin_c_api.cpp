#include "include/mpv_audio_kit/mpv_audio_kit_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "mpv_audio_kit_plugin.h"

void MpvAudioKitPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  mpv_audio_kit::MpvAudioKitPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
