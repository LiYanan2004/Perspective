// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Perspective",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
        .tvOS(.v17),
        .macCatalyst(.v17),
    ],
    products: [
        .library(
            name: "Perspective",
            targets: ["Perspective"]
        ),
    ],
    targets: [
        .target(name: "Perspective"),
    ]
)
