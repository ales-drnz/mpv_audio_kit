#
# mpv_audio_kit macOS podspec.
#
# Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
# All rights reserved.
# Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
#
# libmpv is not part of this pod: the package's build hook
# (hook/build.dart) downloads it and Flutter bundles it with the app as
# libmpv_audio_kit.framework, a code asset the Dart side binds with @Native.
#
# A Flutter plugin ships both dependency-manager manifests — this podspec
# (CocoaPods) and Package.swift (Swift Package Manager) — and the consuming
# app's setup decides which one Flutter uses.
#

Pod::Spec.new do |s|
  s.name             = 'mpv_audio_kit'
  s.version          = '0.4.8'
  s.summary          = 'Flutter audio player powered by libmpv.'
  s.description      = <<-DESC
    Supports audio filters, pitch control, equalizer, and all mpv audio features.
  DESC
  s.homepage         = 'https://github.com/ales-drnz/mpv_audio_kit'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'mpv_audio_kit' => 'ales.drnz@gmail.com' }

  s.source           = { :path => '.' }
  # These Swift files are real copies, intentionally NOT symlinks:
  # `dart pub publish` flattens symlinks into regular files whose body is
  # the link-target path, which then fails to compile in the consumer's
  # Xcode. (SwiftPM, this plugin's other build channel, also rejects a
  # `path:` that escapes the package root, ruling out one shared dir.)
  s.source_files     = 'mpv_audio_kit/Sources/mpv_audio_kit/**/*.swift'
  # Apple privacy manifest. Shipped as a CocoaPods resource bundle so it is
  # embedded (and codesigned) into the built framework — required for App
  # Store submission. Kept out of `source_files` (which is `*.swift`) so it
  # isn't double-referenced.
  s.resource_bundles = {
    'mpv_audio_kit_privacy' => ['mpv_audio_kit/Sources/mpv_audio_kit/PrivacyInfo.xcprivacy'],
  }

  s.dependency 'FlutterMacOS'

  # MediaPlayer is the system framework that hosts MPNowPlayingInfoCenter
  # and MPRemoteCommandCenter — the macOS lockscreen / Control Center /
  # menu-bar Now Playing entry and the play/pause/seek targets that
  # respond to Bluetooth headsets, the keyboard media keys, and Siri.
  s.frameworks = 'MediaPlayer'

  s.platform              = :osx, '12.0'
  s.swift_version         = '5.0'
  s.pod_target_xcconfig   = { 'DEFINES_MODULE' => 'YES' }
end
