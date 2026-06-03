// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "cpu_mem_tool",
    platforms: [
        .macOS("26.0")
    ],
    products: [
        .executable(name: "cpu_mem_tool", targets: ["cpu_mem_tool"])
    ],
    targets: [
        .executableTarget(
            name: "cpu_mem_tool",
            path: "Sources/cpu_mem_tool",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        )
    ]
)
