// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
import Cocoa
import FlutterMacOS

/**
 * MpvAudioKitPlugin
 * 
 * macOS implementation for mpv_audio_kit.
 */
public class MpvAudioKitPlugin: NSObject, FlutterPlugin {
  /**
   * Registers the plugin with the macOS registrar.
   */
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "mpv_audio_kit", binaryMessenger: registrar.messenger)
    let instance = MpvAudioKitPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  /**
   * Handles MethodChannel calls from Dart.
   * 
   * As with other platforms, core mpv functionality is handled via FFI.
   */
  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    // Current methods are handled directly via FFI, so this remains minimally implemented.
    result(FlutterMethodNotImplemented)
  }
}
