//
//  CapabilitiesListToolTests.swift
//  LocalIntelligenceMCPTests
//
//  Created on 2025-10-09.
//

import XCTest
@testable import LocalIntelligenceMCP

final class CapabilitiesListToolTests: XCTestCase {

    var capabilitiesListTool: CapabilitiesListTool!

    override func setUp() async throws {
        try await super.setUp()
        capabilitiesListTool = CapabilitiesListTool()
    }

    override func tearDown() async throws {
        capabilitiesListTool = nil
        try await super.tearDown()
    }

    // MARK: - Tool Initialization Tests

    func testToolInitialization() throws {
        XCTAssertEqual(capabilitiesListTool.name, "capabilities_list")
        XCTAssertFalse(capabilitiesListTool.description.isEmpty)

        // Verify input schema structure
        let schema = capabilitiesListTool.inputSchema
        XCTAssertEqual(schema["type"] as? String, "object")

        let properties = schema["properties"] as? [String: Any]
        XCTAssertNotNil(properties)

        // Check required properties
        let requiredProperties = schema["required"] as? [String]
        XCTAssertTrue(requiredProperties?.isEmpty ?? false) // No required properties

        // Check optional properties
        XCTAssertNotNil(properties?["category"])
        XCTAssertNotNil(properties?["includeDetails"])
        XCTAssertNotNil(properties?["includeExamples"])
        XCTAssertNotNil(properties?["format"])
        XCTAssertNotNil(properties?["sortBy"])
    }

    func testInputSchemaDefaults() throws {
        let schema = capabilitiesListTool.inputSchema
        let properties = schema["properties"] as? [String: Any]

        // Test default values
        XCTAssertEqual(properties?["includeDetails"] as? [String: Any]?["default"] as? Bool, true)
        XCTAssertEqual(properties?["includeExamples"] as? [String: Any]?["default"] as? Bool, false)
        XCTAssertEqual(properties?["format"] as? [String: Any]?["default"] as? String, "json")
        XCTAssertEqual(properties?["sortBy"] as? [String: Any]?["default"] as? String, "category")
    }

    func testCategoryEnumValues() throws {
        let schema = capabilitiesListTool.inputSchema
        let properties = schema["properties"] as? [String: Any]

        let categoryProperty = properties?["category"] as? [String: Any]
        let enumValues = categoryProperty?["enum"] as? [String]

        let expectedCategories = [
            "text_processing",
            "intent_analysis",
            "extraction_classification",
            "catalog_tools",
            "system_tools"
        ]

        XCTAssertEqual(enumValues, expectedCategories)
    }

    func testFormatEnumValues() throws {
        let schema = capabilitiesListTool.inputSchema
        let properties = schema["properties"] as? [String: Any]

        let formatProperty = properties?["format"] as? [String: Any]
        let enumValues = formatProperty?["enum"] as? [String]

        let expectedFormats = ["json", "text", "markdown"]
        XCTAssertEqual(enumValues, expectedFormats)
    }

    func testSortByEnumValues() throws {
        let schema = capabilitiesListTool.inputSchema
        let properties = schema["properties"] as? [String: Any]

        let sortByProperty = properties?["sortBy"] as? [String: Any]
        let enumValues = sortByProperty?["enum"] as? [String]

        let expectedSortOptions = ["name", "category", "usage", "performance"]
        XCTAssertEqual(enumValues, expectedSortOptions)
    }

    // MARK: - Basic Execution Tests

    func testBasicCapabilitiesListExecution() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )
        let parameters = [:] as [String: AnyCodable]

        do {
            let result = try await capabilitiesListTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)
            XCTAssertNotNil(result.data)
            XCTAssertNil(result.error)
        } catch {
            XCTFail("Basic capabilities list execution should succeed: \(error.localizedDescription)")
        }
    }

    func testCapabilitiesListWithDefaultParameters() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        // Test with default parameters (empty)
        let parameters = [:] as [String: AnyCodable]

        do {
            let result = try await capabilitiesListTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)
            XCTAssertNotNil(result.data)

            // Verify response structure
            let data = result.data?.value as? [String: Any]
            XCTAssertNotNil(data)
            XCTAssertNotNil(data?["systemInfo"])
            XCTAssertNotNil(data?["availableTools"])
            XCTAssertNotNil(data?["categories"])
            XCTAssertNotNil(data?["workflows"])
            XCTAssertNotNil(data?["integrations"])
            XCTAssertNotNil(data?["format"])
            XCTAssertNotNil(data?["generatedAt"])
        } catch {
            XCTFail("Capabilities list with default parameters should succeed: \(error.localizedDescription)")
        }
    }

    // MARK: - Input Parameter Tests

    func testCapabilitiesInputParsing() throws {
        let parameters = [
            "category": AnyCodable("text_processing"),
            "includeDetails": AnyCodable(false),
            "includeExamples": AnyCodable(true),
            "format": AnyCodable("markdown"),
            "sortBy": AnyCodable("name")
        ] as [String: AnyCodable]

        let input = try CapabilitiesListTool.CapabilitiesInput(from: parameters)

        XCTAssertEqual(input.category, "text_processing")
        XCTAssertFalse(input.includeDetails)
        XCTAssertTrue(input.includeExamples)
        XCTAssertEqual(input.format, "markdown")
        XCTAssertEqual(input.sortBy, "name")
    }

    func testCapabilitiesInputWithDefaults() throws {
        let parameters = [:] as [String: AnyCodable]

        let input = try CapabilitiesListTool.CapabilitiesInput(from: parameters)

        XCTAssertNil(input.category)
        XCTAssertTrue(input.includeDetails) // Default: true
        XCTAssertFalse(input.includeExamples) // Default: false
        XCTAssertNil(input.format) // Default: nil
        XCTAssertNil(input.sortBy) // Default: nil
    }

    // MARK: - Category Filter Tests

    func testCategoryFilteringTextProcessing() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "category": AnyCodable("text_processing")
        ] as [String: AnyCodable]

        do {
            let result = try await capabilitiesListTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            let data = result.data?.value as? [String: Any]
            let availableTools = data?["availableTools"] as? [[String: Any]]

            // Verify all tools are in text_processing category
            for tool in availableTools ?? [] {
                let category = tool["category"] as? String
                XCTAssertEqual(category, "text_processing")
            }

            XCTAssertGreaterThan(availableTools?.count ?? 0, 0)
        } catch {
            XCTFail("Category filtering should succeed: \(error.localizedDescription)")
        }
    }

    func testCategoryFilteringCatalogTools() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "category": AnyCodable("catalog_tools")
        ] as [String: AnyCodable]

        do {
            let result = try await capabilitiesListTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            let data = result.data?.value as? [String: Any]
            let availableTools = data?["availableTools"] as? [[String: Any]]

            // Verify all tools are in catalog_tools category
            for tool in availableTools ?? [] {
                let category = tool["category"] as? String
                XCTAssertEqual(category, "catalog_tools")
            }

            // Should have 3 catalog tools
            XCTAssertEqual(availableTools?.count, 3)
        } catch {
            XCTFail("Category filtering should succeed: \(error.localizedDescription)")
        }
    }

    func testCategoryFilteringIntentAnalysis() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "category": AnyCodable("intent_analysis")
        ] as [String: AnyCodable]

        do {
            let result = try await capabilitiesListTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            let data = result.data?.value as? [String: Any]
            let availableTools = data?["availableTools"] as? [[String: Any]]

            // Verify all tools are in intent_analysis category
            for tool in availableTools ?? [] {
                let category = tool["category"] as? String
                XCTAssertEqual(category, "intent_analysis")
            }

            XCTAssertGreaterThan(availableTools?.count ?? 0, 0)
        } catch {
            XCTFail("Category filtering should succeed: \(error.localizedDescription)")
        }
    }

    // MARK: - Details and Examples Tests

    func testIncludeDetailsTrue() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "includeDetails": AnyCodable(true)
        ] as [String: AnyCodable]

        do {
            let result = try await capabilitiesListTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            let data = result.data?.value as? [String: Any]
            let availableTools = data?["availableTools"] as? [[String: Any]]

            // Verify tools have performance details
            for tool in availableTools ?? [] {
                let performance = tool["performance"] as? [String: Any]
                XCTAssertNotNil(performance)

                if let performance = performance {
                    XCTAssertNotNil(performance["averageResponseTime"])
                    XCTAssertNotNil(performance["throughput"])
                    XCTAssertNotNil(performance["memoryUsage"])
                    XCTAssertNotNil(performance["reliability"])
                }
            }
        } catch {
            XCTFail("Include details should succeed: \(error.localizedDescription)")
        }
    }

    func testIncludeDetailsFalse() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "includeDetails": AnyCodable(false)
        ] as [String: AnyCodable]

        do {
            let result = try await capabilitiesListTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            let data = result.data?.value as? [String: Any]
            let availableTools = data?["availableTools"] as? [[String: Any]]

            // Verify tools don't have performance details
            for tool in availableTools ?? [] {
                let performance = tool["performance"]
                XCTAssertNil(performance)
            }
        } catch {
            XCTFail("Exclude details should succeed: \(error.localizedDescription)")
        }
    }

    func testIncludeExamplesTrue() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "includeExamples": AnyCodable(true)
        ] as [String: AnyCodable]

        do {
            let result = try await capabilitiesListTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            let data = result.data?.value as? [String: Any]
            let availableTools = data?["availableTools"] as? [[String: Any]]

            // Verify tools have examples
            for tool in availableTools ?? [] {
                let examples = tool["examples"] as? [[String: Any]]
                XCTAssertNotNil(examples)
                XCTAssertGreaterThan(examples?.count ?? 0, 0)

                if let examples = examples, let firstExample = examples.first {
                    XCTAssertNotNil(firstExample["name"])
                    XCTAssertNotNil(firstExample["description"])
                    XCTAssertNotNil(firstExample["input"])
                    XCTAssertNotNil(firstExample["expectedOutput"])
                }
            }
        } catch {
            XCTFail("Include examples should succeed: \(error.localizedDescription)")
        }
    }

    func testIncludeExamplesFalse() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "includeExamples": AnyCodable(false)
        ] as [String: AnyCodable]

        do {
            let result = try await capabilitiesListTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            let data = result.data?.value as? [String: Any]
            let availableTools = data?["availableTools"] as? [[String: Any]]

            // Verify tools don't have examples
            for tool in availableTools ?? [] {
                let examples = tool["examples"]
                XCTAssertNil(examples)
            }
        } catch {
            XCTFail("Exclude examples should succeed: \(error.localizedDescription)")
        }
    }

    // MARK: - Sorting Tests

    func testSortByName() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "sortBy": AnyCodable("name")
        ] as [String: AnyCodable]

        do {
            let result = try await capabilitiesListTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            let data = result.data?.value as? [String: Any]
            let availableTools = data?["availableTools"] as? [[String: Any]]

            // Verify tools are sorted by name
            var previousName = ""
            for tool in availableTools ?? [] {
                let currentName = tool["name"] as? String ?? ""
                if !previousName.isEmpty {
                    XCTAssertLessThanOrEqual(previousName, currentName)
                }
                previousName = currentName
            }
        } catch {
            XCTFail("Sort by name should succeed: \(error.localizedDescription)")
        }
    }

    func testSortByCategory() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "sortBy": AnyCodable("category")
        ] as [String: AnyCodable]

        do {
            let result = try await capabilitiesListTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            let data = result.data?.value as? [String: Any]
            let availableTools = data?["availableTools"] as? [[String: Any]]

            // Verify tools are sorted by category
            var previousCategory = ""
            for tool in availableTools ?? [] {
                let currentCategory = tool["category"] as? String ?? ""
                if !previousCategory.isEmpty {
                    XCTAssertLessThanOrEqual(previousCategory, currentCategory)
                }
                previousCategory = currentCategory
            }
        } catch {
            XCTFail("Sort by category should succeed: \(error.localizedDescription)")
        }
    }

    func testSortByUsage() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "sortBy": AnyCodable("usage")
        ] as [String: AnyCodable]

        do {
            let result = try await capabilitiesListTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            let data = result.data?.value as? [String: Any]
            let availableTools = data?["availableTools"] as? [[String: Any]]

            // Verify tools are sorted by usage (number of use cases)
            var previousUsageCount = Int.max
            for tool in availableTools ?? [] {
                let useCases = tool["useCases"] as? [String] ?? []
                let currentUsageCount = useCases.count
                XCTAssertLessThanOrEqual(currentUsageCount, previousUsageCount)
                previousUsageCount = currentUsageCount
            }
        } catch {
            XCTFail("Sort by usage should succeed: \(error.localizedDescription)")
        }
    }

    func testSortByPerformance() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "sortBy": AnyCodable("performance"),
            "includeDetails": AnyCodable(true)
        ] as [String: AnyCodable]

        do {
            let result = try await capabilitiesListTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            let data = result.data?.value as? [String: Any]
            let availableTools = data?["availableTools"] as? [[String: Any]]

            // Verify tools are sorted by performance (response time, faster first)
            var previousResponseTime = 0
            for tool in availableTools ?? [] {
                let performance = tool["performance"] as? [String: Any]
                let responseTimeString = performance?["averageResponseTime"] as? String ?? "999ms"
                let currentTime = Int(responseTimeString.replacingOccurrences(of: "ms", with: "")) ?? 999

                if previousResponseTime > 0 {
                    XCTAssertLessThanOrEqual(previousResponseTime, currentTime)
                }
                previousResponseTime = currentTime
            }
        } catch {
            XCTFail("Sort by performance should succeed: \(error.localizedDescription)")
        }
    }

    // MARK: - System Information Tests

    func testSystemInfoStructure() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [:] as [String: AnyCodable]

        do {
            let result = try await capabilitiesListTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            let data = result.data?.value as? [String: Any]
            let systemInfo = data?["systemInfo"] as? [String: Any]

            // Verify required system info fields
            XCTAssertNotNil(systemInfo?["name"])
            XCTAssertNotNil(systemInfo?["version"])
            XCTAssertNotNil(systemInfo?["domain"])
            XCTAssertNotNil(systemInfo?["totalTools"])
            XCTAssertNotNil(systemInfo?["supportedFormats"])
            XCTAssertNotNil(systemInfo?["supportedLanguages"])
            XCTAssertNotNil(systemInfo?["maxConcurrency"])
            XCTAssertNotNil(systemInfo?["features"])
            XCTAssertNotNil(systemInfo?["limitations"])

            // Verify specific values
            XCTAssertEqual(systemInfo?["name"] as? String, "Local Intelligence MCP Tools")
            XCTAssertEqual(systemInfo?["version"] as? String, "1.0.0")
            XCTAssertEqual(systemInfo?["domain"] as? String, "audio")
            XCTAssertEqual(systemInfo?["totalTools"] as? Int, 16)

            // Verify arrays are not empty
            let features = systemInfo?["features"] as? [String]
            let limitations = systemInfo?["limitations"] as? [String]
            XCTAssertGreaterThan(features?.count ?? 0, 0)
            XCTAssertGreaterThan(limitations?.count ?? 0, 0)
        } catch {
            XCTFail("System info structure should be valid: \(error.localizedDescription)")
        }
    }

    // MARK: - Categories Tests

    func testCategoriesStructure() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [:] as [String: AnyCodable]

        do {
            let result = try await capabilitiesListTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            let data = result.data?.value as? [String: Any]
            let categories = data?["categories"] as? [[String: Any]]

            XCTAssertNotNil(categories)
            XCTAssertGreaterThan(categories?.count ?? 0, 0)

            // Verify category structure
            for category in categories ?? [] {
                XCTAssertNotNil(category["name"])
                XCTAssertNotNil(category["displayName"])
                XCTAssertNotNil(category["description"])
                XCTAssertNotNil(category["toolCount"])
                XCTAssertNotNil(category["tools"])
                XCTAssertNotNil(category["typicalUseCases"])

                // Verify tools is an array
                let tools = category["tools"] as? [String]
                XCTAssertNotNil(tools)
                XCTAssertGreaterThan(tools?.count ?? 0, 0)

                // Verify use cases is an array
                let useCases = category["typicalUseCases"] as? [String]
                XCTAssertNotNil(useCases)
                XCTAssertGreaterThan(useCases?.count ?? 0, 0)
            }
        } catch {
            XCTFail("Categories structure should be valid: \(error.localizedDescription)")
        }
    }

    // MARK: - Workflows Tests

    func testWorkflowsStructure() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [:] as [String: AnyCodable]

        do {
            let result = try await capabilitiesListTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            let data = result.data?.value as? [String: Any]
            let workflows = data?["workflows"] as? [[String: Any]]

            XCTAssertNotNil(workflows)
            XCTAssertGreaterThan(workflows?.count ?? 0, 0)

            // Verify workflow structure
            for workflow in workflows ?? [] {
                XCTAssertNotNil(workflow["name"])
                XCTAssertNotNil(workflow["displayName"])
                XCTAssertNotNil(workflow["description"])
                XCTAssertNotNil(workflow["phases"])
                XCTAssertNotNil(workflow["typicalDuration"])
                XCTAssertNotNil(workflow["requiredTools"])
                XCTAssertNotNil(workflow["exampleInput"])

                // Verify phases structure
                let phases = workflow["phases"] as? [[String: Any]]
                XCTAssertNotNil(phases)
                XCTAssertGreaterThan(phases?.count ?? 0, 0)

                for phase in phases ?? [] {
                    XCTAssertNotNil(phase["name"])
                    XCTAssertNotNil(phase["description"])
                    XCTAssertNotNil(phase["tools"])
                    XCTAssertNotNil(phase["estimatedTime"])

                    let phaseTools = phase["tools"] as? [String]
                    XCTAssertNotNil(phaseTools)
                }
            }
        } catch {
            XCTFail("Workflows structure should be valid: \(error.localizedDescription)")
        }
    }

    // MARK: - Integrations Tests

    func testIntegrationsStructure() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [:] as [String: AnyCodable]

        do {
            let result = try await capabilitiesListTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            let data = result.data?.value as? [String: Any]
            let integrations = data?["integrations"] as? [[String: Any]]

            XCTAssertNotNil(integrations)
            XCTAssertGreaterThan(integrations?.count ?? 0, 0)

            // Verify integration structure
            for integration in integrations ?? [] {
                XCTAssertNotNil(integration["platform"])
                XCTAssertNotNil(integration["status"])
                XCTAssertNotNil(integration["setupInstructions"])
                XCTAssertNotNil(integration["configuration"])
                XCTAssertNotNil(integration["limitations"])
                XCTAssertNotNil(integration["features"])

                // Verify arrays
                let limitations = integration["limitations"] as? [String]
                let features = integration["features"] as? [String]
                XCTAssertNotNil(limitations)
                XCTAssertNotNil(features)
            }
        } catch {
            XCTFail("Integrations structure should be valid: \(error.localizedDescription)")
        }
    }

    // MARK: - Format Tests

    func testFormatJSON() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "format": AnyCodable("json")
        ] as [String: AnyCodable]

        do {
            let result = try await capabilitiesListTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            let data = result.data?.value as? [String: Any]
            let format = data?["format"] as? String
            XCTAssertEqual(format, "json")
        } catch {
            XCTFail("JSON format should succeed: \(error.localizedDescription)")
        }
    }

    func testFormatMarkdown() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "format": AnyCodable("markdown")
        ] as [String: AnyCodable]

        do {
            let result = try await capabilitiesListTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            let data = result.data?.value as? [String: Any]
            let format = data?["format"] as? String
            XCTAssertEqual(format, "markdown")
        } catch {
            XCTFail("Markdown format should succeed: \(error.localizedDescription)")
        }
    }

    func testFormatText() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "format": AnyCodable("text")
        ] as [String: AnyCodable]

        do {
            let result = try await capabilitiesListTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            let data = result.data?.value as? [String: Any]
            let format = data?["format"] as? String
            XCTAssertEqual(format, "text")
        } catch {
            XCTFail("Text format should succeed: \(error.localizedDescription)")
        }
    }

    // MARK: - Tool Capability Structure Tests

    func testToolCapabilityStructure() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "includeDetails": AnyCodable(true),
            "includeExamples": AnyCodable(true)
        ] as [String: AnyCodable]

        do {
            let result = try await capabilitiesListTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            let data = result.data?.value as? [String: Any]
            let availableTools = data?["availableTools"] as? [[String: Any]]

            XCTAssertGreaterThan(availableTools?.count ?? 0, 0)

            // Verify tool capability structure
            for tool in availableTools ?? [] {
                // Required fields
                XCTAssertNotNil(tool["name"])
                XCTAssertNotNil(tool["displayName"])
                XCTAssertNotNil(tool["description"])
                XCTAssertNotNil(tool["category"])
                XCTAssertNotNil(tool["inputSchema"])
                XCTAssertNotNil(tool["outputFormat"])
                XCTAssertNotNil(tool["useCases"])
                XCTAssertNotNil(tool["dependencies"])
                XCTAssertNotNil(tool["tags"])
                XCTAssertNotNil(tool["version"])

                // Optional fields (should be present with current parameters)
                XCTAssertNotNil(tool["examples"])
                XCTAssertNotNil(tool["performance"])

                // Verify input schema structure
                let inputSchema = tool["inputSchema"] as? [String: Any]
                XCTAssertNotNil(inputSchema?["type"])
                XCTAssertNotNil(inputSchema?["properties"])
                XCTAssertNotNil(inputSchema?["required"])

                // Verify use cases is array
                let useCases = tool["useCases"] as? [String]
                XCTAssertNotNil(useCases)
                XCTAssertGreaterThan(useCases?.count ?? 0, 0)
            }
        } catch {
            XCTFail("Tool capability structure should be valid: \(error.localizedDescription)")
        }
    }

    // MARK: - Timestamp Tests

    func testGeneratedAtTimestamp() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [:] as [String: AnyCodable]

        do {
            let result = try await capabilitiesListTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            let data = result.data?.value as? [String: Any]
            let generatedAt = data?["generatedAt"] as? String

            XCTAssertNotNil(generatedAt)
            XCTAssertFalse(generatedAt?.isEmpty ?? true)

            // Verify ISO8601 format
            let formatter = ISO8601DateFormatter()
            let parsedDate = formatter.date(from: generatedAt ?? "")
            XCTAssertNotNil(parsedDate)

            // Verify timestamp is recent (within 1 minute)
            if let date = parsedDate {
                let timeDifference = Date().timeIntervalSince(date)
                XCTAssertLessThan(timeDifference, 60)
            }
        } catch {
            XCTFail("Generated timestamp should be valid: \(error.localizedDescription)")
        }
    }

    // MARK: - Edge Cases Tests

    func testCapabilitiesListWithContextMetadata() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [
                "requestSource": "unit_test",
                "testType": "edge_case",
                "timestamp": ISO8601DateFormatter().string(from: Date())
            ]
        )

        let parameters = [:] as [String: AnyCodable]

        do {
            let result = try await capabilitiesListTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)
            XCTAssertNotNil(result.data)
        } catch {
            XCTFail("Capabilities list with context metadata should succeed: \(error.localizedDescription)")
        }
    }

    func testCapabilitiesListWithAllOptionsEnabled() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [
            "category": AnyCodable("catalog_tools"),
            "includeDetails": AnyCodable(true),
            "includeExamples": AnyCodable(true),
            "format": AnyCodable("markdown"),
            "sortBy": AnyCodable("performance")
        ] as [String: AnyCodable]

        do {
            let result = try await capabilitiesListTool.performExecution(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            let data = result.data?.value as? [String: Any]
            XCTAssertEqual(data?["format"] as? String, "markdown")

            let availableTools = data?["availableTools"] as? [[String: Any]]
            XCTAssertEqual(availableTools?.count, 3) // 3 catalog tools

            // Verify filtering worked
            for tool in availableTools ?? [] {
                XCTAssertEqual(tool["category"] as? String, "catalog_tools")
                XCTAssertNotNil(tool["performance"]) // Details included
                XCTAssertNotNil(tool["examples"]) // Examples included
            }
        } catch {
            XCTFail("All options enabled should succeed: \(error.localizedDescription)")
        }
    }

    // MARK: - Performance Tests

    func testCapabilitiesListPerformance() {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [:] as [String: AnyCodable]

        measure {
            let expectation = XCTestExpectation(description: "Capabilities list performance")
            Task {
                do {
                    let result = try await capabilitiesListTool.performExecution(parameters: parameters, context: context)
                    XCTAssertTrue(result.success)
                } catch {
                    XCTFail("Performance test should not fail: \(error.localizedDescription)")
                }
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 10.0)
        }
    }

    func testConcurrentCapabilitiesList() {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            sessionId: UUID().uuidString,
            userId: UUID().uuidString,
            timestamp: Date(),
            metadata: [:]
        )

        let parameters = [:] as [String: AnyCodable]
        let concurrentRequests = 5

        measure {
            let expectation = XCTestExpectation(description: "Concurrent capabilities list")
            expectation.expectedFulfillmentCount = concurrentRequests

            for i in 0..<concurrentRequests {
                Task {
                    do {
                        let result = try await capabilitiesListTool.performExecution(parameters: parameters, context: context)
                        XCTAssertTrue(result.success, "Request \(i) should succeed")
                    } catch {
                        XCTFail("Concurrent request \(i) should not fail: \(error.localizedDescription)")
                    }
                    expectation.fulfill()
                }
            }

            wait(for: [expectation], timeout: 15.0)
        }
    }
}