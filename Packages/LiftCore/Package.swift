// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "LiftCore",
    platforms: [.iOS(.v17), .watchOS(.v10), .macOS(.v14)],
    products: [
        .library(name: "LiftCore", targets: ["LiftCore"]),
    ],
    targets: [
        .target(name: "LiftCore"),
        .testTarget(name: "LiftCoreTests", dependencies: ["LiftCore"]),
    ]
)
