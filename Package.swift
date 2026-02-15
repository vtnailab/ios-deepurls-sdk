// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "DeepUrlsSDK",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "DeepUrlsSDK",
            targets: ["DeepUrlsSDK"]),
    ],
    targets: [
        .target(
            name: "DeepUrlsSDK",
            path: "Sources/DeepUrlsSDK"),
    ]
)
