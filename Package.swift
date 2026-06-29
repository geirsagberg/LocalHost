// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "LocalHostMonitor",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "LocalHostMonitorCore",
            targets: ["LocalHostMonitorCore"]
        ),
        .executable(
            name: "LocalHostMonitor",
            targets: ["LocalHostMonitor"]
        )
    ],
    targets: [
        .target(name: "LocalHostMonitorCore"),
        .executableTarget(
            name: "LocalHostMonitor",
            dependencies: ["LocalHostMonitorCore"]
        ),
        .testTarget(
            name: "LocalHostMonitorCoreTests",
            dependencies: ["LocalHostMonitorCore"]
        )
    ]
)
