// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "EventBus",
    platforms: [
        .iOS(.v10)
    ],
    products: [
        .library(
            name: "EventBus",
            targets: ["EventBus"]),
    ],
    targets: [
        .target(
            name: "EventBus",
            path: "EventBus/EventBus",
            publicHeadersPath: "ObjC",
            cSettings: [
                .headerSearchPath("ObjC"),
                .define("SPM_MODULE")
            ]
        ),
        .testTarget(
            name: "EventBusTests",
            dependencies: ["EventBus"],
            path: "Tests/EventBusTests"
        ),
    ],
    swiftLanguageVersions: [.v5]
)
