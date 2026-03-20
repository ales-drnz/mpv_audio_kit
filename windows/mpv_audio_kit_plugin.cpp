// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
#include "mpv_audio_kit_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>

namespace mpv_audio_kit {

/**
 * @brief Static method to register the plugin with the Windows registrar.
 * 
 * Sets up the MethodChannel and the plugin instance.
 * 
 * @param registrar The Windows plugin registrar.
 */
void MpvAudioKitPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "mpv_audio_kit",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<MpvAudioKitPlugin>();

  // Set the method call handler for the channel.
  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  // Add the plugin instance to the registrar.
  registrar->AddPlugin(std::move(plugin));
}

MpvAudioKitPlugin::MpvAudioKitPlugin() {}

MpvAudioKitPlugin::~MpvAudioKitPlugin() {}

/**
 * @brief Handles method calls from Dart via the MethodChannel.
 * 
 * Like other platforms, this plugin primarily uses direct FFI/C bindings to libmpv,
 * so this handler remains minimal for now.
 * 
 * @param method_call The incoming method call from Dart.
 * @param result The result object to send a response back.
 */
void MpvAudioKitPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  // Platform-specific methods are not yet implemented on Windows.
  result->NotImplemented();
}

}  // namespace mpv_audio_kit
