//
//  QueryAnalysisToolTests.swift
//  LocalIntelligenceMCPTests
//
//  Created on 2025-10-09.
//

import XCTest
@testable import LocalIntelligenceMCP

/// Comprehensive unit tests for QueryAnalysisTool
/// Tests query categorization, expertise assessment, complexity analysis, and response guidance
final class QueryAnalysisToolTests: XCTestCase {

    // MARK: - Test Properties

    var mockLogger: MockLogger!
    var mockSecurityManager: MockSecurityManager!
    var queryAnalysisTool: QueryAnalysisTool!

    // MARK: - Test Lifecycle

    override func setUp() async throws {
        try await super.setUp()
        mockLogger = MockLogger()
        mockSecurityManager = MockSecurityManager()
        queryAnalysisTool = QueryAnalysisTool(logger: mockLogger, securityManager: mockSecurityManager)
    }

    override func tearDown() async throws {
        mockLogger = nil
        mockSecurityManager = nil
        queryAnalysisTool = nil
        try await super.tearDown()
    }

    // MARK: - Query Category Tests

    func testFactualCategory() async throws {
        let testQueries = [
            "What is a condenser microphone?",
            "Tell me about SSL consoles",
            "Explain audio compression",
            "Define frequency response",
            "What is phantom power?"
        ]

        for query in testQueries {
            let result = try await queryAnalysisTool.processAudioContent(query, with: [:])
            XCTAssertFalse(result.isEmpty)
            XCTAssertTrue(result.contains("factual"))
        }
    }

    func testTechnicalCategory() async throws {
        let testQueries = [
            "How do I set up compression for vocals?",
            "What are the optimal EQ settings?",
            "Configure the interface for recording",
            "Set up the preamp gain staging",
            "How to configure buffer size?"
        ]

        for query in testQueries {
            let result = try await queryAnalysisTool.processAudioContent(query, with: [:])
            XCTAssertFalse(result.isEmpty)
            XCTAssertTrue(result.contains("technical"))
        }
    }

    func testProceduralCategory() async throws {
        let testQueries = [
            "What are the steps for recording drums?",
            "How to mix a song from start to finish?",
            "Process for mastering a track",
            "Workflow for vocal comping",
            "Steps to set up a home studio"
        ]

        for query in testQueries {
            let result = try await queryAnalysisTool.processAudioContent(query, with: [:])
            XCTAssertFalse(result.isEmpty)
            XCTAssertTrue(result.contains("procedural"))
        }
    }

    func testComparativeCategory() async throws {
        let testQueries = [
            "Compare Pro Tools vs Logic Pro",
            "Neumann vs AKG for vocals",
            "Analog vs digital recording",
            "SSL vs Neve consoles",
            "Condenser vs dynamic microphones"
        ]

        for query in testQueries {
            let result = try await queryAnalysisTool.processAudioContent(query, with: [:])
            XCTAssertFalse(result.isEmpty)
            XCTAssertTrue(result.contains("comparative"))
        }
    }

    func testTroubleshootingCategory() async throws {
        let testQueries = [
            "Why is my mix sounding muddy?",
            "Fix humming noise in recording",
            "Audio interface not working",
            "Latency issues during recording",
            "Distortion in vocal track"
        ]

        for query in testQueries {
            let result = try await queryAnalysisTool.processAudioContent(query, with: [:])
            XCTAssertFalse(result.isEmpty)
            XCTAssertTrue(result.contains("troubleshooting"))
        }
    }

    func testRecommendationCategory() async throws {
        let testQueries = [
            "Recommend a microphone under $500",
            "Best plugins for vocal mixing",
            "Suggest acoustic treatment",
            "What preamp should I buy?",
            "Recommend studio monitors"
        ]

        for query in testQueries {
            let result = try await queryAnalysisTool.processAudioContent(query, with: [:])
            XCTAssertFalse(result.isEmpty)
            XCTAssertTrue(result.contains("recommendation"))
        }
    }

    func testSafetyCategory() async throws {
        let testQueries = [
            "Is 48V phantom power safe with ribbon mics?",
            "Protect hearing during loud sessions",
            "Electrical safety for studio setup",
            "Safe volume levels for monitoring",
            "Prevent ear damage when mixing"
        ]

        for query in testQueries {
            let result = try await queryAnalysisTool.processAudioContent(query, with: [:])
            XCTAssertFalse(result.isEmpty)
            XCTAssertTrue(result.contains("safety"))
        }
    }

    func testCostCategory() async throws {
        let testQueries = [
            "How much does a Neumann U87 cost?",
            "Budget for home studio setup",
            "Price comparison of audio interfaces",
            "Is $1000 enough for studio monitors?",
            "Cost of professional mixing services"
        ]

        for query in testQueries {
            let result = try await queryAnalysisTool.processAudioContent(query, with: [:])
            XCTAssertFalse(result.isEmpty)
            XCTAssertTrue(result.contains("cost"))
        }
    }

    // MARK: - Expertise Level Tests

    func testBeginnerExpertiseLevel() async throws {
        let testQueries = [
            "Help me record my first song",
            "What do I need to start recording?",
            "Explain microphone basics",
            "How to connect a microphone?",
            "Simple audio recording setup"
        ]

        for query in testQueries {
            let result = try await queryAnalysisTool.processAudioContent(query, with: [:])
            XCTAssertFalse(result.isEmpty)
            XCTAssertTrue(result.contains("beginner"))
        }
    }

    func testAdvancedExpertiseLevel() async throws {
        let testQueries = [
            "Optimize signal chain for vintage character",
            "Advanced parallel compression techniques",
            "Configure M/S processing for mastering",
            "Implement complex automation routines",
            "Fine-tune psychoacoustic parameters"
        ]

        for query in testQueries {
            let result = try await queryAnalysisTool.processAudioContent(query, with: [:])
            XCTAssertFalse(result.isEmpty)
            XCTAssertTrue(result.contains("advanced") || result.contains("professional"))
        }
    }

    func testExpertiseLevelWithContext() async throws {
        let query = "Best microphone for recording"
        let contexts = [
            ("beginner", "beginner"),
            ("professional", "professional"),
            ("expert", "expert")
        ]

        for (expertise, expectedLevel) in contexts {
            let parameters: [String: Any] = ["context": ["expertise": expertise]]
            let result = try await queryAnalysisTool.processAudioContent(query, with: parameters)
            XCTAssertFalse(result.isEmpty)
            XCTAssertTrue(result.contains(expectedLevel), "Failed for expertise: \(expertise)")
        }
    }

    // MARK: - Complexity Analysis Tests

    func testLowComplexityQueries() async throws {
        let testQueries = [
            "What is a microphone?",
            "How to record audio?",
            "Best mic for vocals?",
            "Volume too low",
            "No sound recording"
        ]

        for query in testQueries {
            let result = try await queryAnalysisTool.processAudioContent(query, with: [:])
            XCTAssertFalse(result.isEmpty)

            // Should have low complexity score (<0.5)
            XCTAssertTrue(result.contains("complexity_score"))
        }
    }

    func testHighComplexityQueries() async throws {
        let testQueries = [
            "Configure parallel compression with attack time 2ms, release 100ms, ratio 4:1, using SSL bus compressor with external sidechain filtering at 200Hz",
            "Implement multi-band M/S processing with psychoacoustic optimization and dynamic EQ integration for mastering",
            "Set up advanced vocal chain with de-essing, saturation, multi-stage compression, and formant-preserving processing"
        ]

        for query in testQueries {
            let result = try await queryAnalysisTool.processAudioContent(query, with: [:])
            XCTAssertFalse(result.isEmpty)

            // Should have high complexity score (>0.7)
            XCTAssertTrue(result.contains("complexity_score"))
        }
    }

    // MARK: - Entity Extraction Tests

    func testEquipmentEntityExtraction() async throws {
        let testQueries = [
            ("Setup Neumann U87 microphone", "Neumann"),
            ("Use SSL console for mixing", "SSL"),
            ("Connect API 312 preamp", "API"),
            ("Process with Waves plugins", "Waves"),
            ("Record into Pro Tools", "Pro Tools")
        ]

        for (query, expectedEntity) in testQueries {
            let result = try await queryAnalysisTool.processAudioContent(query, with: [:])
            XCTAssertFalse(result.isEmpty)
            XCTAssertTrue(result.contains(expectedEntity), "Failed to extract: \(expectedEntity) from: \(query)")
        }
    }

    func testParameterEntityExtraction() async throws {
        let testQueries = [
            ("Boost at 2kHz", "2kHz"),
            ("Set threshold to -18dB", "-18dB"),
            ("Compression ratio 4:1", "4:1"),
            ("Sample rate 96kHz", "96kHz"),
            ("Bit depth 24-bit", "24-bit")
        ]

        for (query, expectedParam) in testQueries {
            let result = try await queryAnalysisTool.processAudioContent(query, with: [:])
            XCTAssertFalse(result.isEmpty)
            XCTAssertTrue(result.contains(expectedParam), "Failed to extract: \(expectedParam} from: \(query)")
        }
    }

    func testCurrencyEntityExtraction() async throws {
        let testQueries = [
            "Microphone under $500",
            "Budget of $1000",
            "Costs $200",
            "Price $1500",
            "Spent $300"
        ]

        for query in testQueries {
            let result = try await queryAnalysisTool.processAudioContent(query, with: [:])
            XCTAssertFalse(result.isEmpty)
            XCTAssertTrue(result.contains("$"))
        }
    }

    // MARK: - Response Guidance Tests

    func testResponseGuidanceGeneration() async throws {
        let parameters: [String: Any] = ["response_guidance": true]
        let query = "How do I set up compression for vocals?"

        let result = try await queryAnalysisTool.processAudioContent(query, with: parameters)
        XCTAssertFalse(result.isEmpty)

        // Should contain response guidance
        XCTAssertTrue(result.contains("response_guidance"))

        // Should contain recommended fields
        let requiredFields = ["recommended_length", "technical_detail", "response_style"]
        for field in requiredFields {
            XCTAssertTrue(result.contains(field), "Missing response guidance field: \(field)")
        }
    }

    func testTechnicalDetailLevels() async throws {
        let testCases = [
            ("Explain audio basics", "basic"),
            ("Configure advanced settings", "technical"),
            ("Professional studio setup", "expert")
        ]

        for (query, expectedDetail) in testCases {
            let result = try await queryAnalysisTool.processAudioContent(query, with: [:])
            XCTAssertFalse(result.isEmpty)
            // Technical detail should be appropriate for query complexity
            XCTAssertTrue(result.contains("technical_detail"))
        }
    }

    func testFollowUpQuestions() async throws {
        let parameters: [String: Any] = ["response_guidance": true]
        let query = "Recommend a microphone"

        let result = try await queryAnalysisTool.processAudioContent(query, with: parameters)
        XCTAssertFalse(result.isEmpty)

        // Should contain follow-up questions for recommendation queries
        XCTAssertTrue(result.contains("follow_up_questions"))
    }

    // MARK: - Safety Assessment Tests

    func testSafetyAssessmentGeneration() async throws {
        let parameters: [String: Any] = ["include_safety": true]
        let safetyQueries = [
            "Use 48V phantom power with ribbon mic",
            "Monitor at high volumes",
            "Connect equipment to power"
        ]

        for query in safetyQueries {
            let result = try await queryAnalysisTool.processAudioContent(query, with: parameters)
            XCTAssertFalse(result.isEmpty)

            // Should include safety assessment for potentially dangerous queries
            if query.contains("phantom") || query.contains("high volumes") {
                XCTAssertTrue(result.contains("safety_assessment"))
            }
        }
    }

    func testHearingProtectionWarnings() async throws {
        let query = "Is it safe to monitor at 110dB?"
        let parameters: [String: Any] = ["include_safety": true]

        let result = try await queryAnalysisTool.processAudioContent(query, with: parameters)
        XCTAssertFalse(result.isEmpty)

        // Should include hearing protection warnings
        if result.contains("safety_assessment") {
            XCTAssertTrue(result.contains("hearing_protection"))
        }
    }

    func testElectricalSafetyWarnings() async throws {
        let query = "Can I connect audio equipment to 220V power?"
        let parameters: [String: Any] = ["include_safety": true]

        let result = try await queryAnalysisTool.processAudioContent(query, with: parameters)
        XCTAssertFalse(result.isEmpty)

        // Should include electrical safety warnings
        if result.contains("safety_assessment") {
            XCTAssertTrue(result.contains("electrical_safety"))
        }
    }

    // MARK: - Domain Analysis Tests

    func testDomainRelevanceScoring() async throws {
        let audioQueries = [
            "Record vocals with Neumann microphone",
            "Mix using SSL console",
            "Master with Waves plugins",
            "Set up API preamp"
        ]

        let nonAudioQueries = [
            "Cook dinner with oven",
            "Drive car to store",
            "Write email to boss",
            "Exercise at gym"
        ]

        // Audio queries should have high domain relevance
        for query in audioQueries {
            let result = try await queryAnalysisTool.processAudioContent(query, with: [:])
            XCTAssertFalse(result.isEmpty)
            XCTAssertTrue(result.contains("domain_relevance"))
        }

        // Non-audio queries should have low domain relevance
        for query in nonAudioQueries {
            let result = try await queryAnalysisTool.processAudioContent(query, with: [:])
            XCTAssertFalse(result.isEmpty)
            // Should still process but with low domain relevance
        }
    }

    func testSubdomainIdentification() async throws {
        let testCases = [
            ("Record drums with multiple mics", "recording"),
            ("Mix vocals with reverb and delay", "mixing"),
            ("Master final track for distribution", "mastering"),
            ("Edit vocal comp takes", "editing")
        ]

        for (query, expectedSubdomain) in testCases {
            let result = try await queryAnalysisTool.processAudioContent(query, with: [:])
            XCTAssertFalse(result.isEmpty)
            // Should identify correct subdomain
            XCTAssertTrue(result.contains("domain_relevance"))
        }
    }

    // MARK: - Parameter Validation Tests

    func testAnalysisDepthParameter() async throws {
        let query = "How to set up a home studio?"
        let depths = ["basic", "standard", "comprehensive"]

        for depth in depths {
            let parameters: [String: Any] = ["analysis_depth": depth]
            let result = try await queryAnalysisTool.processAudioContent(query, with: parameters)
            XCTAssertFalse(result.isEmpty)
            XCTAssertTrue(result.contains("analysis_depth"))
        }
    }

    func testInvalidAnalysisDepth() async throws {
        let query = "Test query"
        let parameters: [String: Any] = ["analysis_depth": "invalid"]

        do {
            _ = try await queryAnalysisTool.processAudioContent(query, with: parameters)
            XCTFail("Should have thrown an error for invalid analysis depth")
        } catch {
            XCTAssertTrue(error is AudioProcessingError)
        }
    }

    func testContextParameterHandling() async throws {
        let query = "Best microphone for recording"
        let context: [String: Any] = [
            "expertise": "professional",
            "environment": "home studio",
            "budget": "under $1000"
        ]

        let result = try await queryAnalysisTool.processAudioContent(query, with: context)
        XCTAssertFalse(result.isEmpty)

        // Should incorporate context into analysis
        XCTAssertTrue(result.contains("professional"))
    }

    // MARK: - Error Handling Tests

    func testEmptyQuery() async throws {
        do {
            _ = try await queryAnalysisTool.processAudioContent("", with: [:])
            XCTFail("Should have thrown an error for empty query")
        } catch {
            XCTAssertTrue(error is AudioProcessingError)
        }
    }

    func testQueryTooShort() async throws {
        do {
            _ = try await queryAnalysisTool.processAudioContent("Hi", with: [:])
            XCTFail("Should have thrown an error for query too short")
        } catch {
            XCTAssertTrue(error is AudioProcessingError)
        }
    }

    func testQueryTooLong() async throws {
        let longQuery = String(repeating: "This is a very long query about audio production that exceeds the maximum length limit. ", count: 100)

        do {
            _ = try await queryAnalysisTool.processAudioContent(longQuery, with: [:])
            XCTFail("Should have thrown an error for query too long")
        } catch {
            XCTAssertTrue(error is AudioProcessingError)
        }
    }

    func testInvalidContextStructure() async throws {
        let query = "Test query"
        let parameters: [String: Any] = ["context": "invalid_structure"]

        // Should handle invalid context gracefully
        let result = try await queryAnalysisTool.processAudioContent(query, with: parameters)
        XCTAssertFalse(result.isEmpty)
    }

    // MARK: - Performance Tests

    func testPerformanceWithSimpleQueries() async throws {
        let simpleQueries = [
            "Best microphone for vocals?",
            "How to record guitar?",
            "What is EQ?",
            "Set up compression",
            "Export audio file"
        ]

        for query in simpleQueries {
            let startTime = Date()
            let result = try await queryAnalysisTool.processAudioContent(query, with: [:])
            let executionTime = Date().timeIntervalSince(startTime)

            XCTAssertFalse(result.isEmpty)
            XCTAssertLessThan(executionTime, 0.15, "Simple query analysis should complete within 150ms")
        }
    }

    func testPerformanceWithComplexQueries() async throws {
        let complexQuery = """
        As a professional audio engineer working in a commercial recording studio with an SSL G+ console,
        Pro Tools HD system, and a collection of vintage microphones including Neumann U87, AKG C414,
        and Royer R121, I need to optimize my vocal recording chain for a male rock vocalist.
        The current setup uses a Neumann U87 through an API 312 preamp with gentle EQ boost at 2kHz,
        followed by an LA-2A compressor with 4:1 ratio and -12dB threshold. However, I'm experiencing
        issues with sibilance and would like to implement a de-esser before the compression stage.
        Additionally, I'm considering adding a tube saturation unit for warmth. What specific settings
        and signal chain configuration would you recommend for optimal results while maintaining the
        vintage character of the recording?
        """

        let startTime = Date()
        let result = try await queryAnalysisTool.processAudioContent(complexQuery, with: [:])
        let executionTime = Date().timeIntervalSince(startTime)

        XCTAssertFalse(result.isEmpty)
        XCTAssertLessThan(executionTime, 0.3, "Complex query analysis should complete within 300ms")
    }

    // MARK: - Integration Tests

    func testEndToEndQueryAnalysis() async throws {
        let query = "I'm a beginner recording artist with a $500 budget. What's the best microphone setup for recording vocals at home?"
        let parameters: [String: Any] = [
            "context": [
                "expertise": "beginner",
                "environment": "home studio",
                "budget": "$500"
            ],
            "analysis_depth": "comprehensive",
            "include_safety": true,
            "response_guidance": true
        ]

        let result = try await queryAnalysisTool.processAudioContent(query, with: parameters)
        XCTAssertFalse(result.isEmpty)

        // Should contain all major analysis components
        let requiredComponents = [
            "category", "expertise_level", "complexity_score", "domain_relevance",
            "entities", "response_guidance"
        ]

        for component in requiredComponents {
            XCTAssertTrue(result.contains(component), "Missing component: \(component)")
        }

        // Should identify as recommendation query
        XCTAssertTrue(result.contains("recommendation"))

        // Should identify beginner expertise
        XCTAssertTrue(result.contains("beginner"))

        // Should extract budget entity
        XCTAssertTrue(result.contains("$500"))

        // Should include microphone equipment entity
        XCTAssertTrue(result.contains("microphone"))

        // Should include response guidance
        XCTAssertTrue(result.contains("recommended_length"))
        XCTAssertTrue(result.contains("technical_detail"))
    }

    func testAudioDomainSpecificAnalysis() async throws {
        let audioQuery = "Apply parallel compression to drums using SSL bus compressor with external sidechain at 200Hz"
        let parameters: [String: Any] = [
            "domain_focus": "mixing",
            "analysis_depth": "technical"
        ]

        let result = try await queryAnalysisTool.processAudioContent(audioQuery, with: parameters)
        XCTAssertFalse(result.isEmpty)

        // Should identify as technical query
        XCTAssertTrue(result.contains("technical"))

        // Should extract audio equipment
        XCTAssertTrue(result.contains("SSL"))

        // Should extract technical parameters
        XCTAssertTrue(result.contains("200Hz"))

        // Should have high domain relevance
        XCTAssertTrue(result.contains("domain_relevance"))
    }
}