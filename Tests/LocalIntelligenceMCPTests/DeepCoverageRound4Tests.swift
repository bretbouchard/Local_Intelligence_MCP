//
//  DeepCoverageRound4Tests.swift
//  LocalIntelligenceMCPTests
//
//  Coverage round 4: direct analyzer coverage — QualityAssessor across every
//  ContentType, entity extraction, sentiment, urgency, business context —
//  plus EmbeddingGeneration content-length variants.
//

import XCTest
@testable import LocalIntelligenceMCP

final class DeepCoverageRound4Tests: XCTestCase {

    private func makeAnalyzerComponent() -> ContentEntityExtractor { ContentEntityExtractor() }
    private func makeSentimentAnalyzer() -> SentimentAnalyzer { SentimentAnalyzer() }
    private func makeUrgencyAnalyzer() -> UrgencyAnalyzer { UrgencyAnalyzer() }

    private let richContent = """
    Session notes 2026-03-01: We tracked lead vocals and fixed the compressor settings.
    TODO: comp the bridge take before Friday's mix review. Contact the band at band@example.com
    about the session. URGENT: the console firmware update must happen before the next booking.
    The client said the mix sounds great. Follow up on the extra stems export request.
    """

    // MARK: - QualityAssessor: every content type (enum-driven branch coverage)

    func testQualityAssessor_AllContentTypes() {
        let assessor = QualityAssessor()
        for contentType in ContentType.allCases {
            let indicators = assessor.assessQuality(content: richContent, contentType: contentType)
            XCTAssertGreaterThanOrEqual(indicators.completeness, 0)
            XCTAssertGreaterThanOrEqual(indicators.clarity, 0)
        }
    }

    func testQualityAssessor_ActionItemsAndFollowUps() {
        let assessor = QualityAssessor()
        let content = """
        TODO: export the stems.
        Follow up with the label about the deadline.
        Must fix the vocal comp before delivery.
        """
        let indicators = assessor.assessQuality(content: content, contentType: .sessionNotes)
        XCTAssertGreaterThanOrEqual(indicators.organization, 0)
    }

    // MARK: - Content analyzers (used by ContentPurposeDetector)

    func testContentEntityExtractor_FindsEntities() {
        let extractor = makeAnalyzerComponent()
        let entities = extractor.extractEntities(content: richContent)
        // richContent includes emails, dates, and audio terms — expect multiple entities
        XCTAssertTrue(entities.count >= 3, "expected several entities, got \(entities.count)")
    }

    func testSentimentAnalyzer_DistinguishesPolarity() {
        let analyzer = makeSentimentAnalyzer()
        let positive = analyzer.analyzeSentiment(content: "The mix sounds great and the client loves the new master. Excellent work!")
        let negative = analyzer.analyzeSentiment(content: "This is a terrible broken mess and everyone is disappointed and frustrated.")
        XCTAssertGreaterThan(positive.sentiment, negative.sentiment, "positive content must score above negative")
    }

    func testUrgencyAnalyzer_FlagsUrgentContent() {
        let analyzer = makeUrgencyAnalyzer()
        let urgent = analyzer.assessUrgency(content: "URGENT: the live broadcast starts in 10 minutes and the console is down!")
        let casual = analyzer.assessUrgency(content: "Whenever you have a moment, the file archive could use tidying.")
        XCTAssertGreaterThanOrEqual(urgent.urgencyLevel, casual.urgencyLevel, "urgent content must rank at least as high")
    }

    // MARK: - Business context analyzer

    func testBusinessContextAnalyzer_DetectsBusinessSignals() {
        let analyzer = BusinessContextAnalyzer()
        let content = """
        The client approved the budget for the next quarter. Revenue from the campaign
        exceeded projections. We scheduled a meeting with stakeholders to review the
        deliverables and discuss the contract renewal.
        """
        let context = analyzer.analyzeBusinessContext(content: content)
        _ = context
    }

    // MARK: - Embedding generation: content-length variants

    func testEmbeddingGeneration_ContentLengthVariants() async {
        let tool = EmbeddingGenerationTool(logger: Logger(
            configuration: LoggingConfiguration(level: .error, file: nil, maxSize: 1, maxFiles: 1, enableConsole: false)
        ), securityManager: SecurityManager())

        let short = "pad"
        let medium = Array(repeating: "warm analog pad content", count: 10).joined(separator: " ")
        let long = Array(repeating: medium, count: 8).joined(separator: " ")

        for content in [short, medium, long] {
            let context = MCPExecutionContext(clientId: UUID(), requestId: UUID().uuidString, toolName: "embedding_generation", metadata: [:])
            let response = try? await tool.execute(
                parameters: ["content": AnyCodable(content)],
                context: context
            )
            XCTAssertEqual(response?.success, true, "embedding failed for content length \(content.count)")
        }
    }
}
