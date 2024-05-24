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
            name: "DDMEventBus",
            dependencies: [],
            path: "EventBus",
            sources: ["Objc", "Swift"],
            publicHeadersPath: "Objc",
            cSettings: [
                .headerSearchPath("Objc")
            ]
        ),
    ],
    swiftLanguageVersions: [.v5]
)
