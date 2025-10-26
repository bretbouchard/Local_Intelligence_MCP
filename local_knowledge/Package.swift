// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "local_knowledge",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "local_knowledge",
            targets: ["local_knowledge"]
        ),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "local_knowledge",
            dependencies: [],
            path: ".",
            sources: [
                "LocalKnowledgeApp.swift",
                "Models/BookDocument.swift",
                "Views/DocumentListView.swift",
                "Services/DocumentIngestionService.swift"
            ]
        ),
    ]
)
