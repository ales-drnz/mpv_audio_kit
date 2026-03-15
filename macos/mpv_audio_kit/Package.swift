// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "mpv_audio_kit",
    platforms: [
        .macOS("10.14")
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
