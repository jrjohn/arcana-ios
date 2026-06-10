// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ArcanaIOS",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "ArcanaIOS",
            targets: ["ArcanaIOS"]
        ),
    ],
    dependencies: [
        // Swift Dependencies - Modern dependency injection framework
        .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.13.1"),
    ],
    targets: [
        // Main target
        .target(
            name: "ArcanaIOS",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
            ],
            path: "arcana-ios"
        ),
    ]
)
