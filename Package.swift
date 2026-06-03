// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FloatMonitor",
    platforms: [
        .macOS("26.0")
    ],
    products: [
        .executable(name: "FloatMonitor", targets: ["FloatMonitor"])
    ],
    targets: [
        .executableTarget(
            name: "FloatMonitor",
            path: "Sources/FloatMonitor",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        )
    ]
)
