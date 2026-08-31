// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LocalIntelligenceMCP",
    platforms: [
        .macOS(.v13),
        .iOS(.v16)
    ],
    products: [
        .executable(
            name: "LocalIntelligenceMCP",
            targets: ["LocalIntelligenceMCP"]
        ),
    ],
    dependencies: [
        // MCP Protocol SDK
        .package(url: "https://github.com/modelcontextprotocol/swift-sdk.git", from: "0.12.0"),

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
        // Main executable target
        .executableTarget(
            name: "LocalIntelligenceMCP",
            dependencies: [
                .product(name: "MCP", package: "swift-sdk"),
                .product(name: "AnyCodable", package: "AnyCodable"),
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOPosix", package: "swift-nio"),
                .product(name: "NIOHTTP1", package: "swift-nio"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            path: "Sources/LocalIntelligenceMCP"
        ),

        // Test targets
        //
        // NOTE: the former legacy test corpus (Tools/, Integration/) was
        // written against long-gone APIs and never compiled; it has been
        // replaced by consolidated modern suites (CapabilityKernelTests,
        // AudioTextToolsTests). Deleted files remain recoverable in git history.
        .testTarget(
            name: "LocalIntelligenceMCPTests",
            dependencies: [
                "LocalIntelligenceMCP",
                .product(name: "Quick", package: "Quick"),
                .product(name: "Nimble", package: "Nimble"),
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOEmbedded", package: "swift-nio"),
            ],
            path: "Tests/LocalIntelligenceMCPTests",
            sources: [
                "BookIntelligenceTests.swift",
                "EngineeringTemplatesTests.swift",
                "CapabilityKernelTests.swift",
                "AudioTextToolsTests.swift",
                "AdvancedCapabilityTests.swift",
                "WireLevelTests.swift",
            ]
        ),

        // BDS feature tests (behavioral scenarios, e.g. RuntimeCapabilities)
        .testTarget(
            name: "BDSTests",
            dependencies: [
                "LocalIntelligenceMCP"
            ],
            path: "Tests/BDSTests"
        ),
    ]
)