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
            targets: ["DDMEventBusSwift", "DDMEventBusObjc"]
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
            name: "DDMEventBusSwift",
            dependencies: ["DDMEventBusObjc"],
            path: "DDMEventBus/Swift"
        ),
    ],
    swiftLanguageVersions: [.v5]
)
