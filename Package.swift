// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DDMEventBus",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "DDMEventBus",
            targets: ["DDMEventBus"]
        ),
    ],
    targets: [
        .target(
            name: "DDMEventBusObjc",
            dependencies: [],
            path: "DDMEventBus/Objc",
            publicHeadersPath: ".",
            cSettings: [
                .headerSearchPath(".")
            ]
        ),
        .target(
            name: "DDMEventBus",
            dependencies: ["DDMEventBusObjc"],
            path: "DDMEventBus/Swift",
            swiftSettings: [
                .define("SPM")
            ]
        ),
    ],
    swiftLanguageVersions: [.v5]
)
