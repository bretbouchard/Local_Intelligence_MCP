//
//  BookIntelligenceTests.swift
//  LocalIntelligenceMCPTests
//
//  Created on 2025-10-26.
//

import XCTest
@testable import LocalIntelligenceMCP

final class BookIntelligenceTests: XCTestCase {

    var bookIntelligenceTool: BookIntelligenceAnalyzerTool!
    var logger: Logger!
    var securityManager: SecurityManager!

    override func setUp() async throws {
        try await super.setUp()

        // Set up test dependencies
        logger = Logger()
        securityManager = SecurityManager()

        bookIntelligenceTool = BookIntelligenceAnalyzerTool(
            logger: logger,
            securityManager: securityManager
        )
    }

    override func tearDown() async throws {
        bookIntelligenceTool = nil
        logger = nil
        securityManager = nil
        try await super.tearDown()
    }

    // MARK: - Test Data Creation

    private func createTestProcessedContent() -> ProcessedContent {
        let pages = [
            PageContent(
                pageIndex: 0,
                text: "Chapter 1: Introduction to Operational Amplifiers. An operational amplifier (op-amp) is a high-gain electronic voltage amplifier with differential inputs and a single output.",
                width: 612.0,
                height: 792.0,
                structuredContent: [
                    StructuredContent(
                        type: .heading,
                        text: "Chapter 1: Introduction to Operational Amplifiers",
                        x: 50.0,
                        y: 100.0,
                        width: 500.0,
                        height: 30.0,
                        pageIndex: 0
                    )
                ]
            ),
            PageContent(
                pageIndex: 1,
                text: "The LM741 is a popular op-amp integrated circuit. It requires dual power supply voltages, typically +15V and -15V. The gain-bandwidth product is 1MHz.",
                width: 612.0,
                height: 792.0,
                structuredContent: [
                    StructuredContent(
                        type: .paragraph,
                        text: "The LM741 is a popular op-amp integrated circuit.",
                        x: 50.0,
                        y: 200.0,
                        width: 400.0,
                        height: 20.0,
                        pageIndex: 1
                    )
                ]
            ),
            PageContent(
                pageIndex: 2,
                text: "Function calculateGain(resistor1: Double, resistor2: Double) -> Double { return -resistor2 / resistor1 }",
                width: 612.0,
                height: 792.0,
                structuredContent: []
            )
        ]

        return ProcessedContent(
            sourceURL: URL(fileURLWithPath: "/test/electronics_handbook.pdf"),
            pages: pages,
            extractedAt: Date()
        )
    }

    private func createTestProcessedContentProgramming() -> ProcessedContent {
        let pages = [
            PageContent(
                pageIndex: 0,
                text: "class DataProcessor { func processData(data: [String]) -> [String] { return data.filter { !$0.isEmpty } } }",
                width: 612.0,
                height: 792.0,
                structuredContent: [
                    StructuredContent(
                        type: .heading,
                        text: "Data Processing Class",
                        x: 50.0,
                        y: 100.0,
                        width: 300.0,
                        height: 25.0,
                        pageIndex: 0
                    )
                ]
            ),
            PageContent(
                pageIndex: 1,
                text: "function optimizePerformance(callback: () -> Void) { let startTime = Date() // Execute operation callback() let endTime = Date() print(\"Operation took: \\(endTime.timeIntervalSince(startTime)) seconds\") }",
                width: 612.0,
                height: 792.0,
                structuredContent: []
            )
        ]

        return ProcessedContent(
            sourceURL: URL(fileURLWithPath: "/test/programming_guide.pdf"),
            pages: pages,
            extractedAt: Date()
        )
    }

    private func createTestProcessedContentGeneral() -> ProcessedContent {
        let pages = [
            PageContent(
                pageIndex: 0,
                text: "A system is defined as a set of interacting components working together to achieve a common goal. This definition applies to all fields of engineering.",
                width: 612.0,
                height: 792.0,
                structuredContent: [
                    StructuredContent(
                        type: .heading,
                        text: "Systems Definition",
                        x: 50.0,
                        y: 100.0,
                        width: 200.0,
                        height: 25.0,
                        pageIndex: 0
                    )
                ]
            )
        ]

        return ProcessedContent(
            sourceURL: URL(fileURLWithPath: "/test/general_engineering.pdf"),
            pages: pages,
            extractedAt: Date()
        )
    }

    // MARK: - Electronics Domain Tests

    func testElectronicsDomainEntityExtraction() async throws {
        let processedContent = createTestProcessedContent()

        let parameters: [String: AnyCodable] = [
            "content": AnyCodable([
                "sourceURL": processedContent.sourceURL.absoluteString,
                "pages": processedContent.pages.map { page in
                    [
                        "pageIndex": page.pageIndex,
                        "text": page.text,
                        "width": page.width,
                        "height": page.height,
                        "structuredContent": page.structuredContent.map { content in
                            [
                                "type": content.type.rawValue,
                                "text": content.text,
                                "x": content.x,
                                "y": content.y,
                                "width": content.width,
                                "height": content.height,
                                "pageIndex": content.pageIndex
                            ]
                        }
                    ]
                },
                "extractedAt": ISO8601DateFormatter().string(from: processedContent.extractedAt)
            ]),
            "domain": AnyCodable("electronics"),
            "extractionTypes": AnyCodable(["concepts", "relationships", "examples", "guidelines"])
        ]

        let context = MCPExecutionContext(
            requestId: UUID().uuidString,
            clientId: "test-client",
            timestamp: Date(),
            permissions: [.systemInfo]
        )

        let result = try await bookIntelligenceTool.performExecution(parameters: parameters, context: context)

        XCTAssertTrue(result.success)
        XCTAssertNotNil(result.data)
        XCTAssertLessThan(result.executionTime, 10.0) // Should complete within 10 seconds

        // Verify the result structure
        if let dataValue = result.data?.value,
           let jsonData = try? JSONSerialization.data(withJSONObject: dataValue),
           let extractionResult = try? JSONDecoder().decode(BookKnowledgeExtractionResult.self, from: jsonData) {

            XCTAssertGreaterThan(extractionResult.knowledgeObjects.count, 0)
            XCTAssertGreaterThanOrEqual(extractionResult.confidence, 0.0)
            XCTAssertLessThanOrEqual(extractionResult.confidence, 1.0)

            // Check that electronics-specific entities were extracted
            let componentObjects = extractionResult.knowledgeObjects.filter { $0.type == .component }
            XCTAssertGreaterThan(componentObjects.count, 0, "Should extract electronic components")

            // Check for op-amp related content
            let opAmpContent = extractionResult.knowledgeObjects.first { object in
                object.title.contains("op-amp") || object.title.contains("LM741") || object.content.contains("op-amp")
            }
            XCTAssertNotNil(opAmpContent, "Should extract op-amp related content")
        }
    }

    func testElectronicsComponentPatternMatching() async throws {
        let processedContent = createTestProcessedContent()

        // Test that component patterns are correctly identified
        let componentText = "Use a 10kΩ resistor and a 100μF capacitor in series with the 2N3904 transistor."

        // Access the private method through the public interface
        let parameters: [String: AnyCodable] = [
            "content": AnyCodable([
                "sourceURL": processedContent.sourceURL.absoluteString,
                "pages": [[
                    "pageIndex": 0,
                    "text": componentText,
                    "width": 612.0,
                    "height": 792.0,
                    "structuredContent": []
                ]],
                "extractedAt": ISO8601DateFormatter().string(from: processedContent.extractedAt)
            ]),
            "domain": AnyCodable("electronics"),
            "extractionTypes": AnyCodable(["concepts"])
        ]

        let context = MCPExecutionContext(
            requestId: UUID().uuidString,
            clientId: "test-client",
            timestamp: Date(),
            permissions: [.systemInfo]
        )

        let result = try await bookIntelligenceTool.performExecution(parameters: parameters, context: context)

        XCTAssertTrue(result.success)

        if let dataValue = result.data?.value,
           let jsonData = try? JSONSerialization.data(withJSONObject: dataValue),
           let extractionResult = try? JSONDecoder().decode(BookKnowledgeExtractionResult.self, from: jsonData) {

            // Should extract resistor, capacitor, and transistor
            let componentTitles = extractionResult.knowledgeObjects.map { $0.title }
            XCTAssertTrue(componentTitles.contains { $0.contains("10k") || $0.contains("resistor") })
            XCTAssertTrue(componentTitles.contains { $0.contains("100μF") || $0.contains("capacitor") })
            XCTAssertTrue(componentTitles.contains { $0.contains("2N3904") || $0.contains("transistor") })
        }
    }

    // MARK: - Programming Domain Tests

    func testProgrammingDomainEntityExtraction() async throws {
        let processedContent = createTestProcessedContentProgramming()

        let parameters: [String: AnyCodable] = [
            "content": AnyCodable([
                "sourceURL": processedContent.sourceURL.absoluteString,
                "pages": processedContent.pages.map { page in
                    [
                        "pageIndex": page.pageIndex,
                        "text": page.text,
                        "width": page.width,
                        "height": page.height,
                        "structuredContent": page.structuredContent.map { content in
                            [
                                "type": content.type.rawValue,
                                "text": content.text,
                                "x": content.x,
                                "y": content.y,
                                "width": content.width,
                                "height": content.height,
                                "pageIndex": content.pageIndex
                            ]
                        }
                    ]
                },
                "extractedAt": ISO8601DateFormatter().string(from: processedContent.extractedAt)
            ]),
            "domain": AnyCodable("programming"),
            "extractionTypes": AnyCodable(["concepts", "procedures", "examples"])
        ]

        let context = MCPExecutionContext(
            requestId: UUID().uuidString,
            clientId: "test-client",
            timestamp: Date(),
            permissions: [.systemInfo]
        )

        let result = try await bookIntelligenceTool.performExecution(parameters: parameters, context: context)

        XCTAssertTrue(result.success)

        if let dataValue = result.data?.value,
           let jsonData = try? JSONSerialization.data(withJSONObject: dataValue),
           let extractionResult = try? JSONDecoder().decode(BookKnowledgeExtractionResult.self, from: jsonData) {

            XCTAssertGreaterThan(extractionResult.knowledgeObjects.count, 0)

            // Check that programming-specific entities were extracted
            let procedureObjects = extractionResult.knowledgeObjects.filter { $0.type == .procedure }
            XCTAssertGreaterThan(procedureObjects.count, 0, "Should extract programming procedures")

            // Check for class and function extraction
            let classObjects = extractionResult.knowledgeObjects.filter { object in
                object.title.contains("DataProcessor") || object.content.contains("class")
            }
            XCTAssertGreaterThan(classObjects.count, 0, "Should extract class definitions")

            let functionObjects = extractionResult.knowledgeObjects.filter { object in
                object.title.contains("processData") || object.title.contains("optimizePerformance") ||
                object.content.contains("func") || object.content.contains("function")
            }
            XCTAssertGreaterThan(functionObjects.count, 0, "Should extract function definitions")
        }
    }

    func testProgrammingPatternMatching() async throws {
        let processedContent = createTestProcessedContentProgramming()

        let parameters: [String: AnyCodable] = [
            "content": AnyCodable([
                "sourceURL": processedContent.sourceURL.absoluteString,
                "pages": [[
                    "pageIndex": 0,
                    "text": "public class NetworkManager { private func authenticate(username: String, password: String) -> Bool { return true } }",
                    "width": 612.0,
                    "height": 792.0,
                    "structuredContent": []
                ]],
                "extractedAt": ISO8601DateFormatter().string(from: processedContent.extractedAt)
            ]),
            "domain": AnyCodable("programming"),
            "extractionTypes": AnyCodable(["concepts"])
        ]

        let context = MCPExecutionContext(
            requestId: UUID().uuidString,
            clientId: "test-client",
            timestamp: Date(),
            permissions: [.systemInfo]
        )

        let result = try await bookIntelligenceTool.performExecution(parameters: parameters, context: context)

        XCTAssertTrue(result.success)

        if let dataValue = result.data?.value,
           let jsonData = try? JSONSerialization.data(withJSONObject: dataValue),
           let extractionResult = try? JSONDecoder().decode(BookKnowledgeExtractionResult.self, from: jsonData) {

            // Should extract class and function
            let objectTitles = extractionResult.knowledgeObjects.map { $0.title }
            XCTAssertTrue(objectTitles.contains { $0.contains("NetworkManager") || $0.contains("class") })
            XCTAssertTrue(objectTitles.contains { $0.contains("authenticate") || $0.contains("func") })
        }
    }

    // MARK: - General Domain Tests

    func testGeneralDomainEntityExtraction() async throws {
        let processedContent = createTestProcessedContentGeneral()

        let parameters: [String: AnyCodable] = [
            "content": AnyCodable([
                "sourceURL": processedContent.sourceURL.absoluteString,
                "pages": processedContent.pages.map { page in
                    [
                        "pageIndex": page.pageIndex,
                        "text": page.text,
                        "width": page.width,
                        "height": page.height,
                        "structuredContent": page.structuredContent.map { content in
                            [
                                "type": content.type.rawValue,
                                "text": content.text,
                                "x": content.x,
                                "y": content.y,
                                "width": content.width,
                                "height": content.height,
                                "pageIndex": content.pageIndex
                            ]
                        }
                    ]
                },
                "extractedAt": ISO8601DateFormatter().string(from: processedContent.extractedAt)
            ]),
            "domain": AnyCodable("general"),
            "extractionTypes": AnyCodable(["concepts"])
        ]

        let context = MCPExecutionContext(
            requestId: UUID().uuidString,
            clientId: "test-client",
            timestamp: Date(),
            permissions: [.systemInfo]
        )

        let result = try await bookIntelligenceTool.performExecution(parameters: parameters, context: context)

        XCTAssertTrue(result.success)

        if let dataValue = result.data?.value,
           let jsonData = try? JSONSerialization.data(withJSONObject: dataValue),
           let extractionResult = try? JSONDecoder().decode(BookKnowledgeExtractionResult.self, from: jsonData) {

            XCTAssertGreaterThan(extractionResult.knowledgeObjects.count, 0)

            // Should extract concepts from general text
            let conceptObjects = extractionResult.knowledgeObjects.filter { $0.type == .concept }
            XCTAssertGreaterThan(conceptObjects.count, 0, "Should extract general concepts")

            // Check for system definition extraction
            let systemConcepts = extractionResult.knowledgeObjects.filter { object in
                object.title.contains("system") || object.content.contains("system") ||
                object.content.contains("definition")
            }
            XCTAssertGreaterThan(systemConcepts.count, 0, "Should extract system definitions")
        }
    }

    // MARK: - Relationship Extraction Tests

    func testRelationshipExtraction() async throws {
        let processedContent = createTestProcessedContent()

        let parameters: [String: AnyCodable] = [
            "content": AnyCodable([
                "sourceURL": processedContent.sourceURL.absoluteString,
                "pages": [[
                    "pageIndex": 0,
                    "text": "The op-amp uses a feedback resistor. The transistor has a base terminal. The capacitor connects to the ground.",
                    "width": 612.0,
                    "height": 792.0,
                    "structuredContent": []
                ]],
                "extractedAt": ISO8601DateFormatter().string(from: processedContent.extractedAt)
            ]),
            "domain": AnyCodable("electronics"),
            "extractionTypes": AnyCodable(["concepts", "relationships"])
        ]

        let context = MCPExecutionContext(
            requestId: UUID().uuidString,
            clientId: "test-client",
            timestamp: Date(),
            permissions: [.systemInfo]
        )

        let result = try await bookIntelligenceTool.performExecution(parameters: parameters, context: context)

        XCTAssertTrue(result.success)

        if let dataValue = result.data?.value,
           let jsonData = try? JSONSerialization.data(withJSONObject: dataValue),
           let extractionResult = try? JSONDecoder().decode(BookKnowledgeExtractionResult.self, from: jsonData) {

            XCTAssertGreaterThan(extractionResult.relationships.count, 0, "Should extract relationships")

            // Verify relationship structure
            for relationship in extractionResult.relationships {
                XCTAssertFalse(relationship.subject.isEmpty)
                XCTAssertFalse(relationship.predicate.isEmpty)
                XCTAssertFalse(relationship.object.isEmpty)
                XCTAssertGreaterThanOrEqual(relationship.confidence, 0.0)
                XCTAssertLessThanOrEqual(relationship.confidence, 1.0)
            }
        }
    }

    // MARK: - Performance Tests

    func testPerformanceWithLargeDocument() async throws {
        // Create a large document for performance testing
        var largePages: [PageContent] = []
        let baseText = "This document contains technical information about operational amplifiers, resistors, capacitors, and transistors. "

        for pageIndex in 0..<100 {
            let pageText = baseText + "Page \(pageIndex) content: " + String(repeating: "Technical data ", count: 50)
            largePages.append(PageContent(
                pageIndex: pageIndex,
                text: pageText,
                width: 612.0,
                height: 792.0,
                structuredContent: []
            ))
        }

        let largeContent = ProcessedContent(
            sourceURL: URL(fileURLWithPath: "/test/large_document.pdf"),
            pages: largePages,
            extractedAt: Date()
        )

        let parameters: [String: AnyCodable] = [
            "content": AnyCodable([
                "sourceURL": largeContent.sourceURL.absoluteString,
                "pages": largeContent.pages.map { page in
                    [
                        "pageIndex": page.pageIndex,
                        "text": page.text,
                        "width": page.width,
                        "height": page.height,
                        "structuredContent": page.structuredContent.map { content in
                            [
                                "type": content.type.rawValue,
                                "text": content.text,
                                "x": content.x,
                                "y": content.y,
                                "width": content.width,
                                "height": content.height,
                                "pageIndex": content.pageIndex
                            ]
                        }
                    ]
                },
                "extractedAt": ISO8601DateFormatter().string(from: largeContent.extractedAt)
            ]),
            "domain": AnyCodable("electronics"),
            "extractionTypes": AnyCodable(["concepts"])
        ]

        let context = MCPExecutionContext(
            requestId: UUID().uuidString,
            clientId: "test-client",
            timestamp: Date(),
            permissions: [.systemInfo]
        )

        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try await bookIntelligenceTool.performExecution(parameters: parameters, context: context)
        let processingTime = CFAbsoluteTimeGetCurrent() - startTime

        XCTAssertTrue(result.success)
        XCTAssertLessThan(processingTime, 30.0, "Large document processing should complete within 30 seconds")
        XCTAssertLessThan(result.executionTime, 30.0)
    }

    // MARK: - Error Handling Tests

    func testInvalidParametersError() async throws {
        let parameters: [String: AnyCodable] = [
            "invalid_param": AnyCodable("test")
        ]

        let context = MCPExecutionContext(
            requestId: UUID().uuidString,
            clientId: "test-client",
            timestamp: Date(),
            permissions: [.systemInfo]
        )

        do {
            _ = try await bookIntelligenceTool.performExecution(parameters: parameters, context: context)
            XCTFail("Should throw an error for invalid parameters")
        } catch {
            XCTAssertTrue(error is MCPError)
            XCTAssertEqual(error as? MCPError, .invalidParameters)
        }
    }

    func testMalformedContentDataError() async throws {
        let parameters: [String: AnyCodable] = [
            "content": AnyCodable("invalid_content_structure"),
            "domain": AnyCodable("electronics"),
            "extractionTypes": AnyCodable(["concepts"])
        ]

        let context = MCPExecutionContext(
            requestId: UUID().uuidString,
            clientId: "test-client",
            timestamp: Date(),
            permissions: [.systemInfo]
        )

        do {
            _ = try await bookIntelligenceTool.performExecution(parameters: parameters, context: context)
            XCTFail("Should throw an error for malformed content data")
        } catch {
            XCTAssertTrue(error is MCPError)
            XCTAssertEqual(error as? MCPError, .decodingFailed)
        }
    }

    func testInvalidDomainHandling() async throws {
        let processedContent = createTestProcessedContent()

        let parameters: [String: AnyCodable] = [
            "content": AnyCodable([
                "sourceURL": processedContent.sourceURL.absoluteString,
                "pages": processedContent.pages.map { page in
                    [
                        "pageIndex": page.pageIndex,
                        "text": page.text,
                        "width": page.width,
                        "height": page.height,
                        "structuredContent": page.structuredContent.map { content in
                            [
                                "type": content.type.rawValue,
                                "text": content.text,
                                "x": content.x,
                                "y": content.y,
                                "width": content.width,
                                "height": content.height,
                                "pageIndex": content.pageIndex
                            ]
                        }
                    ]
                },
                "extractedAt": ISO8601DateFormatter().string(from: processedContent.extractedAt)
            ]),
            "domain": AnyCodable("invalid_domain"),
            "extractionTypes": AnyCodable(["concepts"])
        ]

        let context = MCPExecutionContext(
            requestId: UUID().uuidString,
            clientId: "test-client",
            timestamp: Date(),
            permissions: [.systemInfo]
        )

        // Should handle invalid domain gracefully (default to general)
        let result = try await bookIntelligenceTool.performExecution(parameters: parameters, context: context)
        XCTAssertTrue(result.success)
    }

    func testEmptyDocumentHandling() async throws {
        let emptyContent = ProcessedContent(
            sourceURL: URL(fileURLWithPath: "/test/empty_document.pdf"),
            pages: [],
            extractedAt: Date()
        )

        let parameters: [String: AnyCodable] = [
            "content": AnyCodable([
                "sourceURL": emptyContent.sourceURL.absoluteString,
                "pages": [],
                "extractedAt": ISO8601DateFormatter().string(from: emptyContent.extractedAt)
            ]),
            "domain": AnyCodable("general"),
            "extractionTypes": AnyCodable(["concepts"])
        ]

        let context = MCPExecutionContext(
            requestId: UUID().uuidString,
            clientId: "test-client",
            timestamp: Date(),
            permissions: [.systemInfo]
        )

        let result = try await bookIntelligenceTool.performExecution(parameters: parameters, context: context)

        XCTAssertTrue(result.success)

        if let dataValue = result.data?.value,
           let jsonData = try? JSONSerialization.data(withJSONObject: dataValue),
           let extractionResult = try? JSONDecoder().decode(BookKnowledgeExtractionResult.self, from: jsonData) {

            XCTAssertEqual(extractionResult.knowledgeObjects.count, 0)
            XCTAssertEqual(extractionResult.relationships.count, 0)
            XCTAssertEqual(extractionResult.confidence, 0.0)
        }
    }

    // MARK: - Extraction Type Tests

    func testDifferentExtractionTypes() async throws {
        let processedContent = createTestProcessedContent()
        let extractionTypes = ["concepts", "relationships", "examples", "guidelines"]

        for extractionType in extractionTypes {
            let parameters: [String: AnyCodable] = [
                "content": AnyCodable([
                    "sourceURL": processedContent.sourceURL.absoluteString,
                    "pages": processedContent.pages.map { page in
                        [
                            "pageIndex": page.pageIndex,
                            "text": page.text,
                            "width": page.width,
                            "height": page.height,
                            "structuredContent": page.structuredContent.map { content in
                                [
                                    "type": content.type.rawValue,
                                    "text": content.text,
                                    "x": content.x,
                                    "y": content.y,
                                    "width": content.width,
                                    "height": content.height,
                                    "pageIndex": content.pageIndex
                                ]
                            }
                        ]
                    },
                    "extractedAt": ISO8601DateFormatter().string(from: processedContent.extractedAt)
                ]),
                "domain": AnyCodable("electronics"),
                "extractionTypes": AnyCodable([extractionType])
            ]

            let context = MCPExecutionContext(
                requestId: UUID().uuidString,
                clientId: "test-client",
                timestamp: Date(),
                permissions: [.systemInfo]
            )

            let result = try await bookIntelligenceTool.performExecution(parameters: parameters, context: context)

            XCTAssertTrue(result.success, "Should succeed with extraction type: \(extractionType)")

            if let dataValue = result.data?.value,
               let jsonData = try? JSONSerialization.data(withJSONObject: dataValue),
               let extractionResult = try? JSONDecoder().decode(BookKnowledgeExtractionResult.self, from: jsonData) {

                XCTAssertGreaterThanOrEqual(extractionResult.knowledgeObjects.count, 0)
                XCTAssertGreaterThanOrEqual(extractionResult.confidence, 0.0)
                XCTAssertLessThanOrEqual(extractionResult.confidence, 1.0)
            }
        }
    }

    // MARK: - Integration Tests

    func testFullWorkflowIntegration() async throws {
        let processedContent = createTestProcessedContent()

        let parameters: [String: AnyCodable] = [
            "content": AnyCodable([
                "sourceURL": processedContent.sourceURL.absoluteString,
                "pages": processedContent.pages.map { page in
                    [
                        "pageIndex": page.pageIndex,
                        "text": page.text,
                        "width": page.width,
                        "height": page.height,
                        "structuredContent": page.structuredContent.map { content in
                            [
                                "type": content.type.rawValue,
                                "text": content.text,
                                "x": content.x,
                                "y": content.y,
                                "width": content.width,
                                "height": content.height,
                                "pageIndex": content.pageIndex
                            ]
                        }
                    ]
                },
                "extractedAt": ISO8601DateFormatter().string(from: processedContent.extractedAt)
            ]),
            "domain": AnyCodable("electronics"),
            "extractionTypes": AnyCodable(["concepts", "relationships", "examples", "guidelines"])
        ]

        let context = MCPExecutionContext(
            requestId: UUID().uuidString,
            clientId: "test-client",
            timestamp: Date(),
            permissions: [.systemInfo]
        )

        let result = try await bookIntelligenceTool.performExecution(parameters: parameters, context: context)

        XCTAssertTrue(result.success)
        XCTAssertNotNil(result.data)
        XCTAssertLessThan(result.executionTime, 10.0)

        // Verify full result structure
        if let dataValue = result.data?.value,
           let jsonData = try? JSONSerialization.data(withJSONObject: dataValue),
           let extractionResult = try? JSONDecoder().decode(BookKnowledgeExtractionResult.self, from: jsonData) {

            // Verify knowledge objects
            XCTAssertGreaterThan(extractionResult.knowledgeObjects.count, 0)
            for knowledgeObject in extractionResult.knowledgeObjects {
                XCTAssertFalse(knowledgeObject.id.isEmpty)
                XCTAssertFalse(knowledgeObject.title.isEmpty)
                XCTAssertFalse(knowledgeObject.content.isEmpty)
                XCTAssertGreaterThanOrEqual(knowledgeObject.confidence, 0.0)
                XCTAssertLessThanOrEqual(knowledgeObject.confidence, 1.0)

                // Verify source reference
                XCTAssertEqual(knowledgeObject.sourceReference.documentTitle, "electronics_handbook.pdf")
            }

            // Verify relationships
            for relationship in extractionResult.relationships {
                XCTAssertFalse(relationship.id.isEmpty)
                XCTAssertFalse(relationship.subject.isEmpty)
                XCTAssertFalse(relationship.predicate.isEmpty)
                XCTAssertFalse(relationship.object.isEmpty)
                XCTAssertGreaterThanOrEqual(relationship.confidence, 0.0)
                XCTAssertLessThanOrEqual(relationship.confidence, 1.0)
            }

            // Verify overall metrics
            XCTAssertGreaterThanOrEqual(extractionResult.confidence, 0.0)
            XCTAssertLessThanOrEqual(extractionResult.confidence, 1.0)
            XCTAssertGreaterThanOrEqual(extractionResult.processingTime, 0.0)
        }
    }

    // MARK: - Claude Code Integration Tests

    func testClaudeCodeIntegrationContextExtraction() async throws {
        // This test simulates the Claude Code integration workflow
        let processedContent = createTestProcessedContent()

        let parameters: [String: AnyCodable] = [
            "content": AnyCodable([
                "sourceURL": processedContent.sourceURL.absoluteString,
                "pages": processedContent.pages.map { page in
                    [
                        "pageIndex": page.pageIndex,
                        "text": page.text,
                        "width": page.width,
                        "height": page.height,
                        "structuredContent": page.structuredContent.map { content in
                            [
                                "type": content.type.rawValue,
                                "text": content.text,
                                "x": content.x,
                                "y": content.y,
                                "width": content.width,
                                "height": content.height,
                                "pageIndex": content.pageIndex
                            ]
                        }
                    ]
                },
                "extractedAt": ISO8601DateFormatter().string(from: processedContent.extractedAt)
            ]),
            "domain": AnyCodable("electronics"),
            "extractionTypes": AnyCodable(["concepts", "examples"])
        ]

        let context = MCPExecutionContext(
            requestId: UUID().uuidString,
            clientId: "claude-code-integration",
            timestamp: Date(),
            permissions: [.systemInfo]
        )

        let result = try await bookIntelligenceTool.performExecution(parameters: parameters, context: context)

        XCTAssertTrue(result.success)

        if let dataValue = result.data?.value,
           let jsonData = try? JSONSerialization.data(withJSONObject: dataValue),
           let extractionResult = try? JSONDecoder().decode(BookKnowledgeExtractionResult.self, from: jsonData) {

            // Verify that high-confidence objects are extracted for Claude Code context
            let highConfidenceObjects = extractionResult.knowledgeObjects.filter { $0.confidence > 0.7 }
            XCTAssertGreaterThan(highConfidenceObjects.count, 0, "Should provide high-confidence context for Claude Code")

            // Verify that source references are properly formatted for Claude Code
            for object in highConfidenceObjects {
                XCTAssertFalse(object.sourceReference.documentTitle.isEmpty)
                XCTAssertNotNil(object.sourceReference.pageNumber)
            }
        }
    }

    // MARK: - Edge Cases Tests

    func testSpecialCharacterHandling() async throws {
        let specialCharContent = ProcessedContent(
            sourceURL: URL(fileURLWithPath: "/test/special_chars.pdf"),
            pages: [
                PageContent(
                    pageIndex: 0,
                    text: "Special characters: α, β, γ, Ω, μ, ±, °, ∞, ∑, ∆, ≈, ≠, ≥, ≤. These are common in engineering formulas.",
                    width: 612.0,
                    height: 792.0,
                    structuredContent: []
                )
            ],
            extractedAt: Date()
        )

        let parameters: [String: AnyCodable] = [
            "content": AnyCodable([
                "sourceURL": specialCharContent.sourceURL.absoluteString,
                "pages": specialCharContent.pages.map { page in
                    [
                        "pageIndex": page.pageIndex,
                        "text": page.text,
                        "width": page.width,
                        "height": page.height,
                        "structuredContent": page.structuredContent.map { content in
                            [
                                "type": content.type.rawValue,
                                "text": content.text,
                                "x": content.x,
                                "y": content.y,
                                "width": content.width,
                                "height": content.height,
                                "pageIndex": content.pageIndex
                            ]
                        }
                    ]
                },
                "extractedAt": ISO8601DateFormatter().string(from: specialCharContent.extractedAt)
            ]),
            "domain": AnyCodable("general"),
            "extractionTypes": AnyCodable(["concepts"])
        ]

        let context = MCPExecutionContext(
            requestId: UUID().uuidString,
            clientId: "test-client",
            timestamp: Date(),
            permissions: [.systemInfo]
        )

        let result = try await bookIntelligenceTool.performExecution(parameters: parameters, context: context)

        XCTAssertTrue(result.success, "Should handle special characters properly")
    }

    func testMinimalContentHandling() async throws {
        let minimalContent = ProcessedContent(
            sourceURL: URL(fileURLWithPath: "/test/minimal.pdf"),
            pages: [
                PageContent(
                    pageIndex: 0,
                    text: "A",
                    width: 612.0,
                    height: 792.0,
                    structuredContent: []
                )
            ],
            extractedAt: Date()
        )

        let parameters: [String: AnyCodable] = [
            "content": AnyCodable([
                "sourceURL": minimalContent.sourceURL.absoluteString,
                "pages": minimalContent.pages.map { page in
                    [
                        "pageIndex": page.pageIndex,
                        "text": page.text,
                        "width": page.width,
                        "height": page.height,
                        "structuredContent": page.structuredContent.map { content in
                            [
                                "type": content.type.rawValue,
                                "text": content.text,
                                "x": content.x,
                                "y": content.y,
                                "width": content.width,
                                "height": content.height,
                                "pageIndex": content.pageIndex
                            ]
                        }
                    ]
                },
                "extractedAt": ISO8601DateFormatter().string(from: minimalContent.extractedAt)
            ]),
            "domain": AnyCodable("general"),
            "extractionTypes": AnyCodable(["concepts"])
        ]

        let context = MCPExecutionContext(
            requestId: UUID().uuidString,
            clientId: "test-client",
            timestamp: Date(),
            permissions: [.systemInfo]
        )

        let result = try await bookIntelligenceTool.performExecution(parameters: parameters, context: context)

        XCTAssertTrue(result.success, "Should handle minimal content gracefully")
    }

    // MARK: - Multi-Document Tests

    func testMultipleDocumentTypes() async throws {
        let documentTypes = [
            ("electronics", createTestProcessedContent()),
            ("programming", createTestProcessedContentProgramming()),
            ("general", createTestProcessedContentGeneral())
        ]

        for (domain, content) in documentTypes {
            let parameters: [String: AnyCodable] = [
                "content": AnyCodable([
                    "sourceURL": content.sourceURL.absoluteString,
                    "pages": content.pages.map { page in
                        [
                            "pageIndex": page.pageIndex,
                            "text": page.text,
                            "width": page.width,
                            "height": page.height,
                            "structuredContent": page.structuredContent.map { content in
                                [
                                    "type": content.type.rawValue,
                                    "text": content.text,
                                    "x": content.x,
                                    "y": content.y,
                                    "width": content.width,
                                    "height": content.height,
                                    "pageIndex": content.pageIndex
                                ]
                            }
                        ]
                    },
                    "extractedAt": ISO8601DateFormatter().string(from: content.extractedAt)
                ]),
                "domain": AnyCodable(domain),
                "extractionTypes": AnyCodable(["concepts"])
            ]

            let context = MCPExecutionContext(
                requestId: UUID().uuidString,
                clientId: "test-client",
                timestamp: Date(),
                permissions: [.systemInfo]
            )

            let result = try await bookIntelligenceTool.performExecution(parameters: parameters, context: context)

            XCTAssertTrue(result.success, "Should successfully process \(domain) document type")

            if let dataValue = result.data?.value,
               let jsonData = try? JSONSerialization.data(withJSONObject: dataValue),
               let extractionResult = try? JSONDecoder().decode(BookKnowledgeExtractionResult.self, from: jsonData) {

                XCTAssertGreaterThan(extractionResult.knowledgeObjects.count, 0, "Should extract knowledge from \(domain) document")
            }
        }
    }
}