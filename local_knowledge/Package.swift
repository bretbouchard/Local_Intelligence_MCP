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
    dependencies: [
        // MCP Protocol SDK
        .package(url: "https://github.com/modelcontextprotocol/swift-sdk.git", from: "0.10.0"),

        // JSON handling
        .package(url: "https://github.com/Flight-School/AnyCodable.git", from: "0.6.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "local_knowledge",
            dependencies: [
                .product(name: "MCP", package: "swift-sdk"),
                .product(name: "AnyCodable", package: "AnyCodable"),
            ],
            path: ".",
            sources: [
                "LocalKnowledgeApp.swift",
                "Models/BookDocument.swift",
                "Models/ProcessedContent.swift",
                "Models/KnowledgeModels.swift",
                "Models/CoreDataModels.swift",
                "Views/DocumentListView.swift",
                "Views/MainTabView.swift",
                "Views/SearchView.swift",
                "Views/ClaudeIntegrationView.swift",
                "Views/Components/SearchBar.swift",
                "Views/Components/DomainFilter.swift",
                "Views/Components/SearchResultsView.swift",
                "Views/Components/KnowledgeObjectRow.swift",
                "Views/Components/TypeBadge.swift",
                "Views/Components/SourceReferenceView.swift",
                "Views/Components/ConfidenceIndicator.swift",
                "Views/Components/EmptySearchView.swift",
                "Views/Components/SuggestionRow.swift",
                "Services/DocumentIngestionService.swift",
                "Services/PDFProcessingService.swift",
                "Services/MCPClientService.swift",
                "Services/KnowledgeGraphService.swift",
                "Services/SearchService.swift",
                "Services/ClaudeCodeIntegrationService.swift",
                "Persistence/CoreDataStack.swift",
                "Persistence/CoreDataModel.swift",
                "Tests/KnowledgeGraphTests.swift",
                "TestRunner.swift"
            ],
            resources: [
                .process("local_knowledge.xcdatamodeld")
            ]
        ),
    ]
)
