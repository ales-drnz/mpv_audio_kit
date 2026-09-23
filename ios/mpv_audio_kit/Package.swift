// swift-tools-version: 5.9
// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
//
// libmpv is not part of this package: the build hook (hook/build.dart)
// downloads it and Flutter bundles it with the app as a code asset.

import PackageDescription

let package = Package(
    name: "mpv_audio_kit",
    platforms: [
        .iOS("15.0")
    ],
    products: [
        .library(name: "mpv-audio-kit", targets: ["mpv_audio_kit"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
    ],
    targets: [
        .target(
            name: "mpv_audio_kit",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
            ],
            // The Swift here is real-file copies, intentionally NOT
            // symlinks: `dart pub publish` flattens symlinks into regular
            // files whose body is the link-target path, which then fails to
            // compile in the consumer's Xcode. (SwiftPM also rejects a
            // `path:` that escapes the package root, ruling out one shared
            // dir.)
            path: "Sources/mpv_audio_kit",
            // Apple privacy manifest, embedded into the built bundle —
            // required for App Store submission. A real per-platform file;
            // keep the iOS/macOS copies in sync by hand. .process places it
            // at the bundle root.
            resources: [
                .process("PrivacyInfo.xcprivacy"),
            ],
            linkerSettings: [
                // MediaPlayer hosts MPNowPlayingInfoCenter +
                // MPRemoteCommandCenter (lockscreen / Control Center
                // Now Playing entry). AVFoundation is needed for
                // AVAudioSession (interruption handling).
                .linkedFramework("MediaPlayer"),
                .linkedFramework("AVFoundation"),
            ]
        ),
    ]
)
