// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ImageForge",
    platforms: [.macOS(.v15)],
    products: [
        .executable(name: "ImageForge", targets: ["ImageForge"])
    ],
    targets: [
        .executableTarget(
            name: "ImageForge",
            path: "Sources/ImageForge"
        ),
        .testTarget(
            name: "ImageForgeTests",
            dependencies: ["ImageForge"],
            path: "Tests/ImageForgeTests"
        )
    ]
)
