// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.
// Swift Package: PdSdk
import PackageDescription;

let package = Package(
    name: "PdSdk",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "PdSdk",
            targets: ["PdSdk"]
        )
    ],
    dependencies: [ ],
    targets: [
        .binaryTarget(name: "PdSdkFramework", path: "PdSdkFramework.xcframework"),
        .target(
            name: "PdSdk",
            dependencies: [
                .target(name: "PdSdkFramework")
            ]
        ),
        .testTarget(
            name: "PdSdkTests",
            dependencies: ["PdSdk"]
        )
    ]   
)
