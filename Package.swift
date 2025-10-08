// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AppleMCPServer",
    platforms: [
        .macOS(.v13),
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "AppleMCPServer",
            targets: ["AppleMCPServer"]
        ),
    ],
    dependencies: [
        // MCP Protocol SDK
        .package(url: "https://github.com/modelcontextprotocol/swift-sdk.git", from: "0.10.0"),

        // Networking
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.40.0"),

        // JSON handling
        .package(url: "https://github.com/Flight-School/AnyCodable.git", from: "0.6.0"),

        // Command line argument parsing
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.0.0"),

        // Testing dependencies
        .package(url: "https://github.com/Quick/Quick.git", from: "7.0.0"),
        .package(url: "https://github.com/Quick/Nimble.git", from: "12.0.0"),
    ],
    targets: [
        // Main library target
        .target(
            name: "AppleMCPServer",
            dependencies: [
                .product(name: "MCP", package: "swift-sdk"),
                .product(name: "AnyCodable", package: "AnyCodable"),
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOPosix", package: "swift-nio"),
                .product(name: "NIOHTTP1", package: "swift-nio"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            path: "Sources/AppleMCPServer"
        ),

        // Test targets
        .testTarget(
            name: "AppleMCPServerTests",
            dependencies: [
                "AppleMCPServer",
                .product(name: "Quick", package: "Quick"),
                .product(name: "Nimble", package: "Nimble"),
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOEmbedded", package: "swift-nio"),
            ],
            path: "Tests"
        ),
    ]
)