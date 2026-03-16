// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
import Flutter
import UIKit
import AVFoundation

public class MpvAudioKitPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "mpv_audio_kit", binaryMessenger: registrar.messenger())
    let instance = MpvAudioKitPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public override init() {
    super.init()
    do {
      let audioSession = AVAudioSession.sharedInstance()
      try audioSession.setCategory(.playback, mode: .default, options: [])
      try audioSession.setActive(true)
    } catch {
      print("Failed to set audio session category: \(error)")
    }
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
