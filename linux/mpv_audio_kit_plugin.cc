// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
#include "include/mpv_audio_kit/mpv_audio_kit_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>

#include <cstring>

/**
 * @file mpv_audio_kit_plugin.cc
 * @brief Implementation of the Linux side of the mpv_audio_kit plugin.
 */

// Macros to simplify GObject casting.
#define MPV_AUDIO_KIT_PLUGIN(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), mpv_audio_kit_plugin_get_type(), \
                               MpvAudioKitPlugin))

// Private struct for the plugin instance.
struct _MpvAudioKitPlugin {
  GObject parent_instance;
};

// Define the GType for the plugin.
G_DEFINE_TYPE(MpvAudioKitPlugin, mpv_audio_kit_plugin, g_object_get_type())

/**
 * @brief Handles method calls from Dart via the MethodChannel.
 * 
 * Currently, this plugin primarily works through direct FFI/C bindings to libmpv,
 * so the MethodChannel is used only for platform-specific interactions if needed.
 * 
 * @param self The plugin instance.
 * @param method_call The method call details.
 */
static void mpv_audio_kit_plugin_handle_method_call(
    MpvAudioKitPlugin* self,
    FlMethodCall* method_call) {
  g_autoptr(FlMethodResponse) response = nullptr;

  // Platform-specific methods are not yet implemented on Linux.
  response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());

  fl_method_call_respond(method_call, response, nullptr);
}

/**
 * @brief Cleans up the plugin instance resources.
 */
static void mpv_audio_kit_plugin_dispose(GObject* object) {
  G_OBJECT_CLASS(mpv_audio_kit_plugin_parent_class)->dispose(object);
}

/**
 * @brief Initializes the plugin class.
 */
static void mpv_audio_kit_plugin_class_init(MpvAudioKitPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = mpv_audio_kit_plugin_dispose;
}

/**
 * @brief Initializes the plugin instance.
 */
static void mpv_audio_kit_plugin_init(MpvAudioKitPlugin* self) {}

/**
 * @brief Callback for method channel calls, delegating to handle_method_call.
 */
static void method_call_cb(FlMethodChannel* channel, FlMethodCall* method_call,
                           gpointer user_data) {
  MpvAudioKitPlugin* plugin = MPV_AUDIO_KIT_PLUGIN(user_data);
  mpv_audio_kit_plugin_handle_method_call(plugin, method_call);
}

/**
 * @brief Public entry point for registering the plugin with the Flutter engine.
 */
void mpv_audio_kit_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  MpvAudioKitPlugin* plugin = MPV_AUDIO_KIT_PLUGIN(
      g_object_new(mpv_audio_kit_plugin_get_type(), nullptr));

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) channel =
      fl_method_channel_new(fl_plugin_registrar_get_messenger(registrar),
                            "mpv_audio_kit",
                            FL_METHOD_CODEC(codec));
                            
  fl_method_channel_set_method_call_handler(channel, method_call_cb,
                                            g_object_ref(plugin),
                                            g_object_unref);

  g_object_unref(plugin);
}
