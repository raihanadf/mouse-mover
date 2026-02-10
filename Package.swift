// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MouseJiggler",
    platforms: [
        .macOS(.v13),
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "MouseJiggler",
            dependencies: [],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency"),
            ]
        ),
        .testTarget(
            name: "MouseJigglerTests",
            dependencies: ["MouseJiggler"]
        ),
    ]
)
