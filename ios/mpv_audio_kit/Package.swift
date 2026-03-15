// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "mpv_audio_kit",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "mpv-audio-kit", targets: ["mpv_audio_kit"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "mpv_audio_kit",
            dependencies: [],
            path: "Sources/mpv_audio_kit",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
