//
//  BookIntelligenceTool.swift
//  LocalIntelligenceMCP
//
//  Created on 2025-10-26.
//

import Foundation

/// Book Intelligence Analyzer Tool for domain-specific document analysis

// MARK: - Shared Types

/// Processed content from PDF documents (simplified version for MCP tool)
struct ProcessedContent: Codable {
    let sourceURL: URL
    let pages: [PageContent]
    let extractedAt: Date
}

struct PageContent: Codable {
    let pageIndex: Int
    let text: String
    let width: Double
    let height: Double
    let structuredContent: [StructuredContent]
}

struct StructuredContent: Codable {
    let type: ContentType
    let text: String
    let x: Double
    let y: Double
    let width: Double
    let height: Double
    let pageIndex: Int

    enum ContentType: String, Codable {
        case heading = "heading"
        case paragraph = "paragraph"
        case figure = "figure"
        case table = "table"
        case equation = "equation"
    }
}

/// MCP Error types
enum MCPError: Error {
    case invalidParameters
    case decodingFailed
}
/// Implements bookIntelligence/analyze specification for processing PDF content and extracting knowledge
public final class BookIntelligenceAnalyzerTool: BaseMCPTool, @unchecked Sendable {

    // MARK: - Initialization

    public convenience init(
        logger: Logger,
        securityManager: SecurityManager
    ) {
        self.init(
            name: "book.analyze",
            description: "Analyze book content and extract knowledge objects, relationships, and concepts for domain-specific learning",
            inputSchema: nil,
            logger: logger,
            securityManager: securityManager
        )
    }

    public init(
        name: String,
        description: String,
        inputSchema: [String: Any]? = nil,
        logger: Logger,
        securityManager: SecurityManager,
        requiresPermission: [PermissionType] = [.systemInfo],
        offlineCapable: Bool = true
    ) {
        let defaultInputSchema: [String: AnyCodable] = [
            "type": AnyCodable("object"),
            "properties": AnyCodable([
                "content": AnyCodable([
                    "type": AnyCodable("object"),
                    "description": AnyCodable("Processed content from PDF documents including pages and structured text"),
                    "properties": AnyCodable([
                        "sourceURL": AnyCodable(["type": AnyCodable("string")]),
                        "pages": AnyCodable(["type": AnyCodable("array")]),
                        "extractedAt": AnyCodable(["type": AnyCodable("string")])
                    ]),
                    "required": AnyCodable(["sourceURL", "pages", "extractedAt"])
                ]),
                "domain": AnyCodable([
                    "type": AnyCodable("string"),
                    "enum": AnyCodable(["electronics", "programming", "general"]),
                    "description": AnyCodable("Document domain for specialized analysis")
                ]),
                "extractionTypes": AnyCodable([
                    "type": AnyCodable("array"),
                    "items": AnyCodable([
                        "type": AnyCodable("string"),
                        "enum": AnyCodable(["concepts", "relationships", "examples", "guidelines"])
                    ]),
                    "description": AnyCodable("Types of knowledge to extract from the content")
                ])
            ]),
            "required": AnyCodable(["content", "domain", "extractionTypes"])
        ]

        super.init(
            name: name,
            description: description,
            inputSchema: inputSchema ?? (defaultInputSchema.compactMapValues { $0.value }),
            category: .general,
            requiresPermission: requiresPermission,
            offlineCapable: offlineCapable,
            logger: logger,
            securityManager: securityManager
        )
    }

    // MARK: - Core Execution

    override func performExecution(parameters: [String: AnyCodable], context: MCPExecutionContext) async throws -> MCPResponse {
        let startTime = Date()

        guard let contentData = parameters["content"]?.value as? [String: Any],
              let domain = parameters["domain"]?.value as? String,
              let extractionTypesData = parameters["extractionTypes"]?.value as? [Any] else {
            throw MCPError.invalidParameters
        }

        // Decode the processed content. Dates arrive as ISO8601 strings on the
        // MCP wire. Both guards use isValidJSONObject first: JSONSerialization
        // traps (crashing the whole server) on invalid top-level objects.
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard JSONSerialization.isValidJSONObject(contentData),
              let contentJson = try? JSONSerialization.data(withJSONObject: contentData),
              let processedContent = try? decoder.decode(ProcessedContent.self, from: contentJson) else {
            throw MCPError.decodingFailed
        }

        // Decode extraction types
        guard JSONSerialization.isValidJSONObject(extractionTypesData),
              let extractionTypesJson = try? JSONSerialization.data(withJSONObject: extractionTypesData),
              let extractionTypes = try? JSONDecoder().decode([BookExtractionType].self, from: extractionTypesJson) else {
            throw MCPError.decodingFailed
        }

        await logger.info("Processing book content for domain: \(domain)", category: .mcp, metadata: [
            "extraction_types": extractionTypes.map(\.rawValue).joined(separator: ","),
            "pages": processedContent.pages.count,
            "source_url": processedContent.sourceURL.lastPathComponent
        ])

        // Process content using existing Local Intelligence MCP tools
        let result = try await analyzeBookContent(processedContent, domain: domain, extractionTypes: extractionTypes)

        let processingTime = Date().timeIntervalSince(startTime)

        await logger.info("Book content analysis completed", category: .mcp, metadata: [
            "knowledge_objects": result.knowledgeObjects.count,
            "relationships": result.relationships.count,
            "processing_time": processingTime,
            "confidence": result.confidence
        ])

        // Return the result
        return MCPResponse(
            success: true,
            data: AnyCodable(result),
            executionTime: processingTime
        )
    }

    // MARK: - Private Methods

    private func analyzeBookContent(
        _ content: ProcessedContent,
        domain: String,
        extractionTypes: [BookExtractionType]
    ) async throws -> BookKnowledgeExtractionResult {
        var knowledgeObjects: [BookKnowledgeObject] = []
        var relationships: [BookKnowledgeRelationship] = []

        let fullText = content.pages.map { $0.text }.joined(separator: "\n")

        // Use existing text processing tools
        let chunks = try await chunkTextForAnalysis(fullText)

        for (chunkIndex, chunk) in chunks.enumerated() {
            // Extract entities based on domain
            let entities = try await extractEntities(from: chunk, domain: domain, chunkIndex: chunkIndex)

            // Convert entities to knowledge objects
            for entity in entities {
                let knowledgeObject = BookKnowledgeObject(
                    id: UUID().uuidString,
                    type: mapEntityTypeToKnowledgeType(entity.type),
                    title: entity.name,
                    content: entity.description,
                    sourceReference: BookSourceReference(
                        documentTitle: content.sourceURL.lastPathComponent,
                        pageNumber: entity.pageNumber,
                        section: entity.section,
                        figureReference: entity.figureReference
                    ),
                    confidence: entity.confidence,
                    metadata: entity.metadata
                )

                knowledgeObjects.append(knowledgeObject)
            }

            // Extract relationships if requested
            if extractionTypes.contains(.relationships) {
                let chunkRelationships = try await extractRelationships(from: chunk, domain: domain, chunkIndex: chunkIndex)
                relationships.append(contentsOf: chunkRelationships)
            }
        }

        return BookKnowledgeExtractionResult(
            knowledgeObjects: knowledgeObjects,
            relationships: relationships,
            confidence: calculateOverallConfidence(knowledgeObjects),
            processingTime: 0.0  // Will be set by caller
        )
    }

    private func chunkTextForAnalysis(_ text: String) async throws -> [String] {
        // Simple chunking strategy - split into manageable pieces
        let maxChunkLength = 4000
        var chunks: [String] = []

        let words = text.components(separatedBy: .whitespacesAndNewlines)
        var currentChunk: [String] = []
        var currentLength = 0

        for word in words {
            if currentLength + word.count + 1 > maxChunkLength && !currentChunk.isEmpty {
                chunks.append(currentChunk.joined(separator: " "))
                currentChunk = [word]
                currentLength = word.count
            } else {
                currentChunk.append(word)
                currentLength += word.count + 1
            }
        }

        if !currentChunk.isEmpty {
            chunks.append(currentChunk.joined(separator: " "))
        }

        return chunks
    }

    private func extractEntities(from text: String, domain: String, chunkIndex: Int) async throws -> [ExtractedEntity] {
        var entities: [ExtractedEntity] = []

        // Domain-specific entity extraction
        switch domain {
        case "electronics":
            entities = extractElectronicsEntities(from: text)
        case "programming":
            entities = extractProgrammingEntities(from: text)
        default:
            entities = extractGeneralEntities(from: text)
        }

        return entities
    }

    private func extractElectronicsEntities(from text: String) -> [ExtractedEntity] {
        var entities: [ExtractedEntity] = []

        // Common electronics terms and patterns
        let componentPatterns = [
            "resistor": "\\b([0-9.]+)\\s*([kMΩ]?Ω)\\b",
            "capacitor": "\\b([0-9.]+)\\s*([μµnp]?F)\\b",
            "inductor": "\\b([0-9.]+)\\s*([µnmH]?H)\\b",
            "transistor": "\\b(2N[0-9A-Z]+|BC[0-9]+)\\b",
            "op-amp": "\\b(LM[0-9]+|TL[0-9]+|UA[0-9]+)\\b"
        ]

        // Extract components
        for (componentType, pattern) in componentPatterns {
            let regex = try? NSRegularExpression(pattern: pattern, options: [])
            let matches = regex?.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)) ?? []

            for match in matches {
                if let range = Range(match.range, in: text) {
                    entities.append(ExtractedEntity(
                        type: BookEntityType.component,
                        name: String(text[range]),
                        description: "\(componentType) found in text",
                        confidence: 0.8,
                        pageNumber: nil as Int?,
                        section: nil as String?,
                        figureReference: nil as String?,
                        metadata: ["component_type": componentType]
                    ))
                }
            }
        }

        return entities
    }

    private func extractProgrammingEntities(from text: String) -> [ExtractedEntity] {
        var entities: [ExtractedEntity] = []

        // Programming patterns
        let functionPattern = "\\b(function|def|func|public|private)\\s+([a-zA-Z_][a-zA-Z0-9_]*)\\s*\\("
        let classPattern = "\\b(class|struct|interface)\\s+([a-zA-Z_][a-zA-Z0-9_]*)"

        // Extract functions
        if let functionRegex = try? NSRegularExpression(pattern: functionPattern, options: []) {
            let matches = functionRegex.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))

            for match in matches {
                if match.numberOfRanges > 2,
                   let nameRange = Range(match.range(at: 2), in: text) {
                    entities.append(ExtractedEntity(
                        type: BookEntityType.function,
                        name: String(text[nameRange]),
                        description: "Function or method definition",
                        confidence: 0.9,
                        pageNumber: nil as Int?,
                        section: nil as String?,
                        figureReference: nil as String?,
                        metadata: ["entity_type": "function"]
                    ))
                }
            }
        }

        // Extract classes
        if let classRegex = try? NSRegularExpression(pattern: classPattern, options: []) {
            let matches = classRegex.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))

            for match in matches {
                if match.numberOfRanges > 2,
                   let nameRange = Range(match.range(at: 2), in: text) {
                    entities.append(ExtractedEntity(
                        type: BookEntityType.classType,
                        name: String(text[nameRange]),
                        description: "Class or struct definition",
                        confidence: 0.9,
                        pageNumber: nil as Int?,
                        section: nil as String?,
                        figureReference: nil as String?,
                        metadata: ["entity_type": "class"]
                    ))
                }
            }
        }

        return entities
    }

    private func extractGeneralEntities(from text: String) -> [ExtractedEntity] {
        var entities: [ExtractedEntity] = []

        // Extract key concepts (simplified)
        let sentences = text.components(separatedBy: ". ")
        for sentence in sentences {
            if sentence.contains("definition") || sentence.contains("is defined as") {
                let words = sentence.components(separatedBy: .whitespacesAndNewlines)
                if let conceptIndex = words.firstIndex(where: { $0.lowercased().contains("definition") }),
                   conceptIndex > 0 {
                    entities.append(ExtractedEntity(
                        type: BookEntityType.concept,
                        name: words[conceptIndex - 1],
                        description: sentence.trimmingCharacters(in: .whitespacesAndNewlines),
                        confidence: 0.7,
                        pageNumber: nil as Int?,
                        section: nil as String?,
                        figureReference: nil as String?,
                        metadata: ["extraction_method": "keyword_based"]
                    ))
                }
            }
        }

        return entities
    }

    private func extractRelationships(from text: String, domain: String, chunkIndex: Int) async throws -> [BookKnowledgeRelationship] {
        // Simple relationship extraction based on patterns
        var relationships: [BookKnowledgeRelationship] = []

        // Example patterns for relationships
        let relationshipPatterns = [
            ("is", "is_a", "describes classification"),
            ("has", "has_property", "describes attributes"),
            ("uses", "uses_component", "describes dependencies"),
            ("connects", "connects_to", "describes connections")
        ]

        for (pattern, predicate, _) in relationshipPatterns {
            let regexPattern = "\\b(\\w+)\\s+\(pattern)\\s+(\\w+)\\b"
            if let regex = try? NSRegularExpression(pattern: regexPattern, options: []) {
                let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))

                for match in matches {
                    if match.numberOfRanges > 2,
                       let subjectRange = Range(match.range(at: 1), in: text),
                       let objectRange = Range(match.range(at: 2), in: text) {

                        relationships.append(BookKnowledgeRelationship(
                            id: UUID().uuidString,
                            subject: String(text[subjectRange]),
                            predicate: predicate,
                            object: String(text[objectRange]),
                            confidence: 0.6,
                            sourceReference: BookSourceReference(
                                documentTitle: "unknown",
                                pageNumber: nil,
                                section: nil,
                                figureReference: nil
                            )
                        ))
                    }
                }
            }
        }

        return relationships
    }

    private func mapEntityTypeToKnowledgeType(_ entityType: BookEntityType) -> BookKnowledgeType {
        switch entityType {
        case .component: return .component
        case .function, .classType: return .procedure
        case .concept: return .concept
        default: return .concept
        }
    }

    private func calculateOverallConfidence(_ objects: [BookKnowledgeObject]) -> Double {
        guard !objects.isEmpty else { return 0.0 }
        let totalConfidence = objects.reduce(0.0) { $0 + $1.confidence }
        return totalConfidence / Double(objects.count)
    }
}

// MARK: - Supporting Types

enum BookExtractionType: String, Codable {
    case concepts = "concepts"
    case relationships = "relationships"
    case examples = "examples"
    case guidelines = "guidelines"
}

enum BookEntityType {
    case component
    case function
    case classType
    case concept
    case example
    case principle
}

struct ExtractedEntity {
    let type: BookEntityType
    let name: String
    let description: String
    let confidence: Double
    let pageNumber: Int?
    let section: String?
    let figureReference: String?
    let metadata: [String: String]
}

enum BookKnowledgeType: String, Codable {
    case concept = "concept"
    case procedure = "procedure"
    case example = "example"
    case principle = "principle"
    case component = "component"
    case circuit = "circuit"
}

struct BookKnowledgeExtractionResult: Codable {
    let knowledgeObjects: [BookKnowledgeObject]
    let relationships: [BookKnowledgeRelationship]
    let confidence: Double
    let processingTime: TimeInterval
}

struct BookKnowledgeObject: Codable, Identifiable {
    let id: String
    let type: BookKnowledgeType
    let title: String
    let content: String
    let sourceReference: BookSourceReference
    let confidence: Double
    let metadata: [String: String]
}

struct BookKnowledgeRelationship: Codable {
    let id: String
    let subject: String
    let predicate: String
    let object: String
    let confidence: Double
    let sourceReference: BookSourceReference
}

struct BookSourceReference: Codable {
    let documentTitle: String
    let pageNumber: Int?
    let section: String?
    let figureReference: String?
}

// Note: ProcessedContent is defined in the local_knowledge project and should be shared