// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "EventBus",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "EventBus",
            targets: ["EventBusSwift", "EventBusObjC"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "EventBusSwift",
            dependencies: ["EventBusObjC"],
            path: "Sources/EventBus/Swift"
        ),
        .target(
            name: "EventBusObjC",
            path: "Sources/EventBus/ObjC",
            publicHeadersPath: "."
        ),
        .testTarget(
            name: "EventBusTests",
            dependencies: ["EventBusSwift", "EventBusObjC"]),
    ],
    swiftLanguageVersions: [.v5]
)
