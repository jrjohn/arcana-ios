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
        .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.17.1"),
        // The app target in arcana-ios.xcodeproj also links Alamofire and LRUCache. Renovate only
        // reads Package.swift (not project.pbxproj), so they are listed here too — otherwise they are
        // never updated (both sat at their 2025 versions). Keep these in sync with the Xcode project.
        .package(url: "https://github.com/Alamofire/Alamofire", from: "5.10.2"),
        .package(url: "https://github.com/nicklockwood/LRUCache", from: "1.2.0"),
    ],
    targets: [
        // Main target
        .target(
            name: "ArcanaIOS",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "Alamofire", package: "Alamofire"),
                .product(name: "LRUCache", package: "LRUCache"),
            ],
            path: "arcana-ios"
        ),
    ]
)
