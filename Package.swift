// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "MoveWindows",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "MoveWindowsCore"),
        .executableTarget(
            name: "MoveWindows",
            dependencies: ["MoveWindowsCore"]
        ),
        .testTarget(
            name: "MoveWindowsCoreTests",
            dependencies: ["MoveWindowsCore"]
        ),
    ]
)
