//
//  FeedbackAnalysisToolTests.swift
//  LocalIntelligenceMCPTests
//
//  Created on 2025-10-09.
//

import XCTest
@testable import LocalIntelligenceMCP

final class FeedbackAnalysisToolTests: XCTestCase {

    var feedbackTool: FeedbackAnalysisTool!

    override func setUp() {
        super.setUp()
        feedbackTool = FeedbackAnalysisTool()
    }

    override func tearDown() {
        feedbackTool = nil
        super.tearDown()
    }

    // MARK: - Test Data Creation

    private func createPositiveFeedback() -> FeedbackAnalysisTool.FeedbackData {
        return FeedbackAnalysisTool.FeedbackData(
            feedbackText: """
            Wow, I'm absolutely thrilled with this mix! The vocal clarity is exceptional - Sarah's voice cuts through perfectly with just the right amount of warmth and presence.

            The drum sound is incredible - so much punch and impact without being harsh. I love how the kick drum has that deep sub-bass presence while still being tight and controlled. The snare crack is exactly what I was looking for.

            Bass and guitar balance is spot-on. The bass sits perfectly in the mix and the guitar tones are just heavenly. That vintage Marshall tone really comes through without overwhelming the vocals.

            The overall energy and dynamics capture the live feel we wanted. The subtle automation on the vocals in the chorus adds so much emotional impact.

            This is exactly the sound I heard in my head when we recorded this track. You've exceeded my expectations! I can't wait to hear the final mastered version.

            Minor suggestions: Maybe add a touch more reverb on the backing vocals in the bridge section? And could we try a slight boost around 80Hz to give the chorus a bit more weight?

            Overall, this is perfect. Let's move forward with this direction!
            """,
            source: "email",
            clientName: "Emily Chen",
            projectName: "Summer Vibes Pop Single",
            mixVersion: "v3",
            timestamp: "2025-10-09T14:30:00Z",
            context: FeedbackAnalysisTool.FeedbackContext(
                previousFeedback: ["Client loved the initial rough mix", "Requested more vocal presence in v2"],
                sessionType: "mix_review",
                referenceTracks: ["Blinding Lights - The Weeknd", "Levitating - Dua Lipa"],
                targetGenre: "Pop",
                deliveryFormat: "Streaming"
            ),
            metadata: [
                "reviewer_role": "primary_artist",
                "listening_environment": "studio_monitors",
                "volume_level": "-12dB",
                "priority": "high"
            ]
        )
    }

    private func createNegativeFeedback() -> FeedbackAnalysisTool.FeedbackData {
        return FeedbackAnalysisTool.FeedbackData(
            feedbackText: """
            I have to be honest - I'm really struggling with this mix. There are several issues that need to be addressed before we can move forward.

            First, the vocals are way too buried in the mix. I can barely hear Sarah's performance and that's the heart of this song. The compression seems too heavy - it's squashing all the life out of her delivery.

            The drums sound thin and lack impact. The kick has no low end and the snare sounds like a cardboard box. The cymbals are harsh and piercing, especially in the chorus sections.

            The bass is completely lost. I know we recorded a great bass performance but I can't hear it at all in this mix. The guitars are too loud and are masking everything else.

            The overall balance feels wrong - this sounds more like a rough demo than a finished mix. The stereo image is too narrow and there's no sense of space or depth.

            Technical issues I noticed: There's some digital clipping in the chorus section around 2:15. Also, the reverb on the vocals sounds cheap and unnatural.

            I'm concerned about the direction this is heading. We need to go back to basics and rebuild this mix from the ground up. Let's schedule a call to discuss the vision for this track again.

            This is not ready for mastering and definitely not ready for the client. We need significant changes to make this work.
            """,
            source: "meeting_notes",
            clientName: "Robert Johnson",
            projectName: "Rock Anthem Album",
            mixVersion: "v2",
            timestamp: "2025-10-08T16:45:00Z",
            context: FeedbackAnalysisTool.FeedbackContext(
                previousFeedback: ["Initial mix had good energy", "Client requested more aggressive guitar tones"],
                sessionType: "critical_review",
                referenceTracks: ["Back in Black - AC/DC", "Highway to Hell - AC/DC"],
                targetGenre: "Hard Rock",
                deliveryFormat: "Album"
            ),
            metadata: [
                "reviewer_role": "producer",
                "listening_environment": "car_stereo",
                "volume_level": "-8dB",
                "priority": "urgent"
            ]
        )
    }

    private func createMixedFeedback() -> FeedbackAnalysisTool.FeedbackData {
        return FeedbackAnalysisTool.FeedbackData(
            feedbackText: """
            Thanks for sending over the latest mix. There's some great work here but also a few areas that need attention.

            What's working well:
            - The vocal performance really shines through. Great job on the lead vocal processing - it's clear, present, and has just the right amount of character.
            - The bass tone is excellent and sits perfectly in the mix. Love the warmth and definition.
            - The overall energy and groove are spot-on. This has the feel we're going for.

            Areas for improvement:
            - The drums need more impact, especially the kick drum. It's getting a bit lost in the chorus sections.
            - Guitar tones are a bit harsh in the upper mids. Could we soften 2-4kHz slightly?
            - The reverb on the vocals feels a bit too much for this intimate track. Let's try a shorter decay time.
            - There's some masking happening between the rhythm guitar and keys in the second verse.

            Technical notes:
            - I noticed some clipping around 3:20 in the final chorus. Watch the levels on the master bus.
            - The stereo field could be wider. Maybe try some subtle widening on the backing vocals?

            The arrangement is great and the performance is fantastic. We just need to refine the balance and tones.

            Let's aim to have these revisions done by Friday if possible. The label is expecting the final version next week.

            Priority: Focus on the drum impact and vocal reverb first. Those are the most critical changes.
            """,
            source: "text_message",
            clientName: "Sarah Williams",
            projectName: "Indie Folk EP",
            mixVersion: "v4",
            timestamp: "2025-10-07T11:20:00Z",
            context: FeedbackAnalysisTool.FeedbackContext(
                previousFeedback: ["Client loved the arrangement and performance", "Previous versions were too bright"],
                sessionType: "revision_request",
                referenceTracks: ["Folklore - Taylor Swift", "A Seat at the Table - Solange"],
                targetGenre: "Indie Folk",
                deliveryFormat: "Streaming"
            ),
            metadata: [
                "reviewer_role": "artist_manager",
                "listening_environment": "home_studio",
                "volume_level": "-14dB",
                "priority": "medium"
            ]
        )
    }

    private func createTechnicalFeedback() -> FeedbackAnalysisTool.FeedbackData {
        return FeedbackAnalysisTool.FeedbackData(
            feedbackText: """
            Technical review of v5 mix:

            Frequency Analysis:
            - Low end (20-60Hz): Excessive build-up around 40Hz causing muddiness
            - Low mids (60-250Hz): Kick drum lacking definition, need 2-3dB boost at 80Hz
            - Mids (250-4kHz): Vocal presence region is good, but guitar has harsh peak at 2.5kHz
            - High mids (4-8kHz): Cymbals need 1-2dB reduction at 6kHz to reduce harshness
            - Highs (8-20kHz): Air is good, but could use slight boost at 12kHz for sparkle

            Dynamic Range:
            - Current DR: 8.2 (target: 9-11 for streaming)
            - Chorus sections are 3-4dB louder than verses - good dynamic contrast
            - Vocal compression: 4:1 ratio with 3-4dB GR seems appropriate

            Stereo Imaging:
            - Width: 85% at 1kHz, good separation
            - Low frequencies (<200Hz) are properly centered
            - Backing vocals could benefit from subtle widening

            Technical Issues:
            - Minor clipping detected at 2:45 in master bus (-0.2dBFS)
            - Phase correlation drops to 0.7 in heavy guitar sections
            - RMS levels: -12.3dB (verses), -9.1dB (chorus)

            Recommendations:
            1. Apply high-pass filter at 35Hz to clean up sub-bass
            2. Use dynamic EQ on guitar to tame 2.5kHz harshness
            3. Adjust vocal reverb decay from 2.8s to 2.2s
            4. Reduce master bus output by 1.5dB to eliminate clipping
            5. Consider multiband compression for more controlled dynamics

            Ready for mastering with these corrections.
            """,
            source: "technical_report",
            clientName: "Mastering Engineer",
            projectName: "Electronic Dance Album",
            mixVersion: "v5",
            timestamp: "2025-10-06T09:15:00Z",
            context: FeedbackAnalysisTool.FeedbackContext(
                previousFeedback: ["Previous version was too dynamic", "Client requested more punch"],
                sessionType: "mastering_preparation",
                referenceTracks: ["Random Access Memories - Daft Punk", "Discovery - Daft Punk"],
                targetGenre: "Electronic",
                deliveryFormat: "Mastering"
            ),
            metadata: [
                "reviewer_role": "mastering_engineer",
                "listening_environment": "professional_studio",
                "volume_level": "-10dB",
                "priority": "high"
            ]
        )
    }

    // MARK: - Sentiment Analysis Tests

    func testAnalyzePositiveSentiment() async throws {
        let feedback = createPositiveFeedback()
        let input = FeedbackAnalysisTool.FeedbackAnalysisInput(
            feedback: feedback,
            analysisDepth: "detailed",
            includeActionItems: true,
            extractTechnicalDetails: true
        )

        let result = try await feedbackTool.handle(input)

        XCTAssertNotNil(result.analysis)
        XCTAssertNotNil(result.analysis?.sentimentAnalysis)

        let sentiment = result.analysis?.sentimentAnalysis
        XCTAssertEqual(sentiment?.overall, "positive")
        XCTAssertGreaterThan(sentiment?.score.positive ?? 0, 0.7)
        XCTAssertLessThan(sentiment?.score.negative ?? 0, 0.2)
        XCTAssertLessThan(sentiment?.score.neutral ?? 0, 0.3)

        // Check sentiment indicators
        let indicators = sentiment?.indicators ?? []
        XCTAssertTrue(indicators.contains { $0.type == "positive" && $0.strength >= 0.8 })
    }

    func testAnalyzeNegativeSentiment() async throws {
        let feedback = createNegativeFeedback()
        let input = FeedbackAnalysisTool.FeedbackAnalysisInput(
            feedback: feedback,
            analysisDepth: "detailed",
            includeActionItems: true,
            extractTechnicalDetails: true
        )

        let result = try await feedbackTool.handle(input)

        XCTAssertNotNil(result.analysis)
        XCTAssertNotNil(result.analysis?.sentimentAnalysis)

        let sentiment = result.analysis?.sentimentAnalysis
        XCTAssertEqual(sentiment?.overall, "negative")
        XCTAssertGreaterThan(sentiment?.score.negative ?? 0, 0.7)
        XCTAssertLessThan(sentiment?.score.positive ?? 0, 0.2)

        // Check sentiment indicators
        let indicators = sentiment?.indicators ?? []
        XCTAssertTrue(indicators.contains { $0.type == "negative" && $0.strength >= 0.8 })
        XCTAssertTrue(indicators.contains { $0.category == "technical_criticism" })
    }

    func testAnalyzeMixedSentiment() async throws {
        let feedback = createMixedFeedback()
        let input = FeedbackAnalysisTool.FeedbackAnalysisInput(
            feedback: feedback,
            analysisDepth: "detailed",
            includeActionItems: true,
            extractTechnicalDetails: true
        )

        let result = try await feedbackTool.handle(input)

        XCTAssertNotNil(result.analysis)
        XCTAssertNotNil(result.analysis?.sentimentAnalysis)

        let sentiment = result.analysis?.sentimentAnalysis
        XCTAssertEqual(sentiment?.overall, "mixed")
        XCTAssertGreaterThan(sentiment?.score.positive ?? 0, 0.3)
        XCTAssertGreaterThan(sentiment?.score.negative ?? 0, 0.3)
        XCTAssertGreaterThan(sentiment?.score.neutral ?? 0, 0.2)

        // Check for both positive and negative indicators
        let indicators = sentiment?.indicators ?? []
        XCTAssertTrue(indicators.contains { $0.type == "positive" })
        XCTAssertTrue(indicators.contains { $0.type == "negative" })
        XCTAssertTrue(indicators.contains { $0.type == "constructive" })
    }

    func testAnalyzeNeutralSentiment() async throws {
        let feedback = createTechnicalFeedback()
        let input = FeedbackAnalysisTool.FeedbackAnalysisInput(
            feedback: feedback,
            analysisDepth: "detailed",
            includeActionItems: true,
            extractTechnicalDetails: true
        )

        let result = try await feedbackTool.handle(input)

        XCTAssertNotNil(result.analysis)
        XCTAssertNotNil(result.analysis?.sentimentAnalysis)

        let sentiment = result.analysis?.sentimentAnalysis
        XCTAssertEqual(sentiment?.overall, "neutral")
        XCTAssertGreaterThan(sentiment?.score.neutral ?? 0, 0.5)

        // Check sentiment indicators
        let indicators = sentiment?.indicators ?? []
        XCTAssertTrue(indicators.contains { $0.type == "neutral" })
        XCTAssertTrue(indicators.contains { $0.category == "technical" })
    }

    // MARK: - Action Items Extraction Tests

    func testExtractActionItemsFromPositiveFeedback() async throws {
        let feedback = createPositiveFeedback()
        let input = FeedbackAnalysisTool.FeedbackAnalysisInput(
            feedback: feedback,
            analysisDepth: "detailed",
            includeActionItems: true,
            extractTechnicalDetails: true
        )

        let result = try await feedbackTool.handle(input)

        XCTAssertNotNil(result.analysis)
        XCTAssertNotNil(result.analysis?.actionItems)

        let actionItems = result.analysis?.actionItems ?? []
        XCTAssertGreaterThan(actionItems.count, 0)

        // Should extract the minor suggestions as action items
        let hasReverbAction = actionItems.contains { item in
            item.task.lowercased().contains("reverb") && item.task.lowercased().contains("vocal")
        }
        XCTAssertTrue(hasReverbAction, "Should extract reverb adjustment as action item")

        let hasEQAction = actionItems.contains { item in
            item.task.lowercased().contains("boost") && item.task.lowercased().contains("80hz")
        }
        XCTAssertTrue(hasEQAction, "Should extract EQ boost as action item")

        // Verify action item structure
        for item in actionItems {
            XCTAssertFalse(item.task.isEmpty)
            XCTAssertFalse(item.priority.isEmpty)
            XCTAssertFalse(item.category.isEmpty)
            XCTAssertGreaterThanOrEqual(item.confidence, 0.0)
            XCTAssertLessThanOrEqual(item.confidence, 1.0)
        }
    }

    func testExtractActionItemsFromNegativeFeedback() async throws {
        let feedback = createNegativeFeedback()
        let input = FeedbackAnalysisTool.FeedbackAnalysisInput(
            feedback: feedback,
            analysisDepth: "detailed",
            includeActionItems: true,
            extractTechnicalDetails: true
        )

        let result = try await feedbackTool.handle(input)

        XCTAssertNotNil(result.analysis)
        XCTAssertNotNil(result.analysis?.actionItems)

        let actionItems = result.analysis?.actionItems ?? []
        XCTAssertGreaterThan(actionItems.count, 0)

        // Should extract multiple critical action items
        let hasVocalAction = actionItems.contains { item in
            item.task.lowercased().contains("vocal") && (item.task.lowercased().contains("bury") || item.task.lowercased().contains("compression"))
        }
        XCTAssertTrue(hasVocalAction)

        let hasDrumAction = actionItems.contains { item in
            item.task.lowercased().contains("drum") || item.task.lowercased().contains("kick") || item.task.lowercased().contains("snare")
        }
        XCTAssertTrue(hasDrumAction)

        let hasBassAction = actionItems.contains { item in
            item.task.lowercased().contains("bass")
        }
        XCTAssertTrue(hasBassAction)

        // Check for high priority items
        let highPriorityItems = actionItems.filter { $0.priority.lowercased() == "high" }
        XCTAssertGreaterThan(highPriorityItems.count, 0)
    }

    func testExtractActionItemsFromMixedFeedback() async throws {
        let feedback = createMixedFeedback()
        let input = FeedbackAnalysisTool.FeedbackAnalysisInput(
            feedback: feedback,
            analysisDepth: "detailed",
            includeActionItems: true,
            extractTechnicalDetails: true
        )

        let result = try await feedbackTool.handle(input)

        XCTAssertNotNil(result.analysis)
        XCTAssertNotNil(result.analysis?.actionItems)

        let actionItems = result.analysis?.actionItems ?? []
        XCTAssertGreaterThan(actionItems.count, 0)

        // Should extract various action items
        let hasDrumAction = actionItems.contains { item in
            item.task.lowercased().contains("drum") && item.task.lowercased().contains("impact")
        }
        XCTAssertTrue(hasDrumAction)

        let hasGuitarAction = actionItems.contains { item in
            item.task.lowercased().contains("guitar") && (item.task.lowercased().contains("harsh") || item.task.lowercased().contains("eq"))
        }
        XCTAssertTrue(hasGuitarAction)

        let hasTechnicalAction = actionItems.contains { item in
            item.task.lowercased().contains("clipping")
        }
        XCTAssertTrue(hasTechnicalAction)

        // Verify priority assignment
        let mediumPriorityItems = actionItems.filter { $0.priority.lowercased() == "medium" }
        XCTAssertGreaterThan(mediumPriorityItems.count, 0)
    }

    func testExtractActionItemsFromTechnicalFeedback() async throws {
        let feedback = createTechnicalFeedback()
        let input = FeedbackAnalysisTool.FeedbackAnalysisInput(
            feedback: feedback,
            analysisDepth: "detailed",
            includeActionItems: true,
            extractTechnicalDetails: true
        )

        let result = try await feedbackTool.handle(input)

        XCTAssertNotNil(result.analysis)
        XCTAssertNotNil(result.analysis?.actionItems)

        let actionItems = result.analysis?.actionItems ?? []
        XCTAssertGreaterThan(actionItems.count, 0)

        // Should extract specific technical recommendations
        let hasFilterAction = actionItems.contains { item in
            item.task.lowercased().contains("high-pass") || item.task.lowercased().contains("filter")
        }
        XCTAssertTrue(hasFilterAction)

        let hasEQAction = actionItems.contains { item in
            item.task.lowercased().contains("eq") && item.task.lowercased().contains("dynamic")
        }
        XCTAssertTrue(hasEQAction)

        let hasLevelAction = actionItems.contains { item in
            item.task.lowercased().contains("level") || item.task.lowercased().contains("output")
        }
        XCTAssertTrue(hasLevelAction)

        // Verify technical categorization
        let technicalItems = actionItems.filter { $0.category.lowercased().contains("technical") }
        XCTAssertGreaterThan(technicalItems.count, 0)
    }

    // MARK: - Technical Details Extraction Tests

    func testExtractTechnicalDetailsFromPositiveFeedback() async throws {
        let feedback = createPositiveFeedback()
        let input = FeedbackAnalysisTool.FeedbackAnalysisInput(
            feedback: feedback,
            analysisDepth: "detailed",
            includeActionItems: true,
            extractTechnicalDetails: true
        )

        let result = try await feedbackTool.handle(input)

        XCTAssertNotNil(result.analysis)
        XCTAssertNotNil(result.analysis?.technicalDetails)

        let technicalDetails = result.analysis?.technicalDetails
        XCTAssertNotNil(technicalDetails?.mentionedComponents)
        XCTAssertNotNil(technicalDetails?.technicalTerms)
        XCTAssertNotNil(technicalDetails?.qualityIndicators)
        XCTAssertNotNil(technicalDetails?.problemAreas)
        XCTAssertNotNil(technicalDetails?.suggestedChanges)

        // Should identify audio components
        let components = technicalDetails?.mentionedComponents ?? []
        XCTAssertTrue(components.contains { $0.lowercased().contains("vocal") })
        XCTAssertTrue(components.contains { $0.lowercased().contains("drum") })
        XCTAssertTrue(components.contains { $0.lowercased().contains("bass") })
        XCTAssertTrue(components.contains { $0.lowercased().contains("guitar") })

        // Should identify technical terms
        let terms = technicalDetails?.technicalTerms ?? []
        XCTAssertTrue(terms.contains { $0.lowercased().contains("reverb") })
        XCTAssertTrue(terms.contains { $0.lowercased().contains("eq") })
        XCTAssertTrue(terms.contains { $0.lowercased().contains("boost") })
    }

    func testExtractTechnicalDetailsFromNegativeFeedback() async throws {
        let feedback = createNegativeFeedback()
        let input = FeedbackAnalysisTool.FeedbackAnalysisInput(
            feedback: feedback,
            analysisDepth: "detailed",
            includeActionItems: true,
            extractTechnicalDetails: true
        )

        let result = try await feedbackTool.handle(input)

        XCTAssertNotNil(result.analysis)
        XCTAssertNotNil(result.analysis?.technicalDetails)

        let technicalDetails = result.analysis?.technicalDetails

        // Should identify problem areas
        let problemAreas = technicalDetails?.problemAreas ?? []
        XCTAssertTrue(problemAreas.contains { $0.lowercased().contains("vocal") })
        XCTAssertTrue(problemAreas.contains { $0.lowercased().contains("drum") })
        XCTAssertTrue(problemAreas.contains { $0.lowercased().contains("compression") })
        XCTAssertTrue(problemAreas.contains { $0.lowercased().contains("clipping") })

        // Should identify technical terms
        let terms = technicalDetails?.technicalTerms ?? []
        XCTAssertTrue(terms.contains { $0.lowercased().contains("compression") })
        XCTAssertTrue(terms.contains { $0.lowercased().contains("clipping") })
        XCTAssertTrue(terms.contains { $0.lowercased().contains("reverb") })
    }

    func testExtractTechnicalDetailsFromTechnicalFeedback() async throws {
        let feedback = createTechnicalFeedback()
        let input = FeedbackAnalysisTool.FeedbackAnalysisInput(
            feedback: feedback,
            analysisDepth: "comprehensive",
            includeActionItems: true,
            extractTechnicalDetails: true
        )

        let result = try await feedbackTool.handle(input)

        XCTAssertNotNil(result.analysis)
        XCTAssertNotNil(result.analysis?.technicalDetails)

        let technicalDetails = result.analysis?.technicalDetails

        // Should extract frequency information
        let frequencyInfo = technicalDetails?.frequencyAnalysis
        XCTAssertNotNil(frequencyInfo)
        XCTAssertNotNil(frequencyInfo?.lowEnd)
        XCTAssertNotNil(frequencyInfo?.lowMids)
        XCTAssertNotNil(frequencyInfo?.mids)
        XCTAssertNotNil(frequencyInfo?.highMids)
        XCTAssertNotNil(frequencyInfo?.highs)

        // Should extract dynamic range information
        let dynamics = technicalDetails?.dynamicRangeAnalysis
        XCTAssertNotNil(dynamics)
        XCTAssertNotNil(dynamics?.currentDR)
        XCTAssertNotNil(dynamics?.targetDR)
        XCTAssertNotNil(dynamics?.compressionSettings)

        // Should extract stereo imaging information
        let stereoInfo = technicalDetails?.stereoImagingAnalysis
        XCTAssertNotNil(stereoInfo)
        XCTAssertNotNil(stereoInfo?.width)
        XCTAssertNotNil(stereoInfo?.lowFreqCentering)
        XCTAssertNotNil(stereoInfo?.phaseCorrelation)

        // Should extract technical issues
        let issues = technicalDetails?.technicalIssues ?? []
        XCTAssertTrue(issues.contains { $0.lowercased().contains("clipping") })
        XCTAssertTrue(issues.contains { $0.lowercased().contains("phase") })
        XCTAssertTrue(issues.contains { $0.lowercased().contains("level") })
    }

    // MARK: - Template Tests

    func testAnalyzeWithClientFeedbackTemplate() async throws {
        let feedback = createMixedFeedback()
        let input = FeedbackAnalysisTool.FeedbackAnalysisInput(
            feedback: feedback,
            analysisDepth: "detailed",
            includeActionItems: true,
            extractTechnicalDetails: true,
            useTemplate: true,
            templateType: "client_feedback"
        )

        let result = try await feedbackTool.handle(input)

        XCTAssertNotNil(result.analysis)
        XCTAssertEqual(result.analysis?.templateUsed, "client_feedback")

        // Should include template-specific sections
        let analysis = result.analysis
        XCTAssertNotNil(analysis?.keyPoints)
        XCTAssertNotNil(analysis->priorityMatrix)
        XCTAssertNotNil(analysis->recommendations)
        XCTAssertNotNil(analysis->nextSteps)

        // Verify content structure
        let keyPoints = analysis?.keyPoints ?? []
        XCTAssertFalse(keyPoints.isEmpty)
        XCTAssertTrue(keyPoints.allSatisfy { !$0.text.isEmpty })
        XCTAssertTrue(keyPoints.allSatisfy { !$0.category.isEmpty })
    }

    func testAnalyzeWithInternalReviewTemplate() async throws {
        let feedback = createTechnicalFeedback()
        let input = FeedbackAnalysisTool.FeedbackAnalysisInput(
            feedback: feedback,
            analysisDepth: "comprehensive",
            includeActionItems: true,
            extractTechnicalDetails: true,
            useTemplate: true,
            templateType: "internal_review"
        )

        let result = try await feedbackTool.handle(input)

        XCTAssertNotNil(result.analysis)
        XCTAssertEqual(result.analysis?.templateUsed, "internal_review")

        // Should include template-specific sections
        let analysis = result.analysis
        XCTAssertNotNil(analysis->technicalAssessment)
        XCTAssertNotNil(analysis->creativeEvaluation)
        XCTAssertNotNil(analysis->criticalIssues)
        XCTAssertNotNil(analysis->improvements)
        XCTAssertNotNil(analysis->recommendations)

        // Verify technical assessment
        let technicalAssessment = analysis?.technicalAssessment
        XCTAssertNotNil(technicalAssessment?.clarityAndDefinition)
        XCTAssertNotNil(technicalAssessment?.balanceAndProportion)
        XCTAssertNotNil(technicalAssessment?.dynamicProcessing)
        XCTAssertNotNil(technicalAssessment->effectsAndAtmosphere)

        // Verify creative evaluation
        let creativeEval = analysis?.creativeEvaluation
        XCTAssertNotNil(creativeEval?.emotionalImpact)
        XCTAssertNotNil(creativeEval?.energyLevel)
        XCTAssertNotNil(creativeEval?.commercialViability)

        // Verify scoring
        XCTAssertNotNil(analysis->overallRating)
        XCTAssertNotNil(analysis->overallRating?.technicalScore)
        XCTAssertNotNil(analysis->overallRating?.creativeScore)
        XCTAssertNotNil(analysis->overallRating?.overallScore)
    }

    func testAnalyzeWithInvalidTemplate() async throws {
        let feedback = createMixedFeedback()
        let input = FeedbackAnalysisTool.FeedbackAnalysisInput(
            feedback: feedback,
            analysisDepth: "detailed",
            includeActionItems: true,
            extractTechnicalDetails: true,
            useTemplate: true,
            templateType: "invalid_template"
        )

        let result = try await feedbackTool.handle(input)

        XCTAssertNotNil(result.analysis)
        // Should fall back to default analysis
        XCTAssertNotNil(result.analysis?.sentimentAnalysis)
        XCTAssertNotNil(result.analysis?.actionItems)
        XCTAssertNil(result.analysis?.templateUsed)
    }

    // MARK: - Analysis Depth Tests

    func testBriefAnalysisDepth() async throws {
        let feedback = createMixedFeedback()
        let input = FeedbackAnalysisTool.FeedbackAnalysisInput(
            feedback: feedback,
            analysisDepth: "brief",
            includeActionItems: true,
            extractTechnicalDetails: false
        )

        let result = try await feedbackTool.handle(input)

        XCTAssertNotNil(result.analysis)
        XCTAssertEqual(result.analysis?.analysisDepth, "brief")

        // Should include basic sentiment and key action items
        XCTAssertNotNil(result.analysis?.sentimentAnalysis)
        XCTAssertNotNil(result.analysis?.actionItems)

        // Should not include detailed technical analysis in brief mode
        if result.analysis?.analysisDepth == "brief" {
            // Brief analysis should be more concise
            XCTAssertLessThanOrEqual(result.analysis?.actionItems?.count ?? 0, 5)
        }
    }

    func testDetailedAnalysisDepth() async throws {
        let feedback = createMixedFeedback()
        let input = FeedbackAnalysisTool.FeedbackAnalysisInput(
            feedback: feedback,
            analysisDepth: "detailed",
            includeActionItems: true,
            extractTechnicalDetails: true
        )

        let result = try await feedbackTool.handle(input)

        XCTAssertNotNil(result.analysis)
        XCTAssertEqual(result.analysis?.analysisDepth, "detailed")

        // Should include comprehensive analysis
        XCTAssertNotNil(result.analysis?.sentimentAnalysis)
        XCTAssertNotNil(result.analysis?.actionItems)
        XCTAssertNotNil(result.analysis?.technicalDetails)
        XCTAssertNotNil(result.analysis?.keyPoints)

        // Should extract more action items in detailed mode
        XCTAssertGreaterThan(result.analysis?.actionItems?.count ?? 0, 3)
    }

    func testComprehensiveAnalysisDepth() async throws {
        let feedback = createTechnicalFeedback()
        let input = FeedbackAnalysisTool.FeedbackAnalysisInput(
            feedback: feedback,
            analysisDepth: "comprehensive",
            includeActionItems: true,
            extractTechnicalDetails: true,
            useTemplate: true,
            templateType: "internal_review"
        )

        let result = try await feedbackTool.handle(input)

        XCTAssertNotNil(result.analysis)
        XCTAssertEqual(result.analysis?.analysisDepth, "comprehensive")

        // Should include all possible analysis components
        XCTAssertNotNil(result.analysis?.sentimentAnalysis)
        XCTAssertNotNil(result.analysis?.actionItems)
        XCTAssertNotNil(result.analysis?.technicalDetails)
        XCTAssertNotNil(result.analysis?.keyPoints)
        XCTAssertNotNil(result.analysis?.priorityMatrix)
        XCTAssertNotNil(result.analysis->recommendations)
        XCTAssertNotNil(result.analysis->nextSteps)
        XCTAssertNotNil(result.analysis->technicalAssessment)
        XCTAssertNotNil(result.analysis->creativeEvaluation)
        XCTAssertNotNil(analysis->overallRating)
    }

    // MARK: - Priority and Urgency Tests

    func testAnalyzeHighPriorityFeedback() async throws {
        var feedback = createNegativeFeedback()
        feedback.metadata["priority"] = "urgent"

        let input = FeedbackAnalysisTool.FeedbackAnalysisInput(
            feedback: feedback,
            analysisDepth: "detailed",
            includeActionItems: true,
            extractTechnicalDetails: true
        )

        let result = try await feedbackTool.handle(input)

        XCTAssertNotNil(result.analysis)

        // Should reflect high priority in analysis
        let actionItems = result.analysis?.actionItems ?? []
        let highPriorityItems = actionItems.filter { $0.priority.lowercased() == "high" || $0.priority.lowercased() == "urgent" }
        XCTAssertGreaterThan(highPriorityItems.count, 0)

        // Should include urgency indicators
        let urgency = result.analysis?.urgencyLevel
        XCTAssertNotNil(urgency)
        XCTAssertTrue(urgency == "high" || urgency == "urgent")
    }

    func testAnalyzeMediumPriorityFeedback() async throws {
        var feedback = createMixedFeedback()
        feedback.metadata["priority"] = "medium"

        let input = FeedbackAnalysisTool.FeedbackAnalysisInput(
            feedback: feedback,
            analysisDepth: "detailed",
            includeActionItems: true,
            extractTechnicalDetails: true
        )

        let result = try await feedbackTool.handle(input)

        XCTAssertNotNil(result.analysis)

        // Should reflect medium priority
        let urgency = result.analysis?.urgencyLevel
        XCTAssertNotNil(urgency)
        XCTAssertTrue(urgency == "medium" || urgency == "normal")
    }

    // MARK: - Edge Cases and Error Handling Tests

    func testAnalyzeEmptyFeedback() async throws {
        let emptyFeedback = FeedbackAnalysisTool.FeedbackData(
            feedbackText: "",
            source: "",
            clientName: "",
            projectName: "",
            mixVersion: "",
            timestamp: "",
            context: nil,
            metadata: [:]
        )

        let input = FeedbackAnalysisTool.FeedbackAnalysisInput(
            feedback: emptyFeedback,
            analysisDepth: "detailed",
            includeActionItems: true,
            extractTechnicalDetails: true
        )

        let result = try await feedbackTool.handle(input)

        XCTAssertNotNil(result.analysis)
        // Should handle empty feedback gracefully
        XCTAssertNotNil(result.analysis?.sentimentAnalysis)
        XCTAssertTrue(result.analysis?.actionItems?.isEmpty ?? true)
    }

    func testAnalyzeFeedbackWithSpecialCharacters() async throws {
        let specialFeedback = FeedbackAnalysisTool.FeedbackData(
            feedbackText: """
            The mix sounds great! 🎵 I love the vocal clarity and the drum punch.
            However, there are some issues: é, ü, ñ, ç, 中文, русский, العربية that need attention.

            Technical notes: 48kHz, 24-bit, -14 LUFS target.
            The reverb time (2.8s) could be reduced to 2.2s for better intimacy.

            Overall rating: ⭐⭐⭐⭐⭐ (4.5/5 stars)
            """,
            source: "email",
            clientName: "José García",
            projectName: "International Album",
            mixVersion: "v2",
            timestamp: "2025-10-09T14:30:00Z",
            context: nil,
            metadata: ["rating": "4.5", "language": "multilingual"]
        )

        let input = FeedbackAnalysisTool.FeedbackAnalysisInput(
            feedback: specialFeedback,
            analysisDepth: "detailed",
            includeActionItems: true,
            extractTechnicalDetails: true
        )

        let result = try await feedbackTool.handle(input)

        XCTAssertNotNil(result.analysis)
        // Should handle special characters and unicode properly
        XCTAssertNotNil(result.analysis?.sentimentAnalysis)
        XCTAssertFalse(result.analysis?.sentimentAnalysis?.overall.isEmpty ?? true)
    }

    func testAnalyzeExtremelyLongFeedback() async throws {
        let longFeedbackText = String(repeating: "This is detailed feedback about the mix. The vocals need to be clearer, the drums need more punch, and the bass should sit better in the mix. ", count: 100)

        let longFeedback = FeedbackAnalysisTool.FeedbackData(
            feedbackText: longFeedbackText,
            source: "document",
            clientName: "Verbose Client",
            projectName: "Long Project",
            mixVersion: "v10",
            timestamp: "2025-10-09T14:30:00Z",
            context: nil,
            metadata: ["word_count": "\(longFeedbackText.count)"]
        )

        let input = FeedbackAnalysisTool.FeedbackAnalysisInput(
            feedback: longFeedback,
            analysisDepth: "detailed",
            includeActionItems: true,
            extractTechnicalDetails: true
        )

        let result = try await feedbackTool.handle(input)

        XCTAssertNotNil(result.analysis)
        // Should handle long feedback and extract key points
        XCTAssertNotNil(result.analysis?.sentimentAnalysis)
        XCTAssertNotNil(result.analysis?.keyPoints)
    }

    func testAnalyzeFeedbackWithNilContext() async throws {
        var feedback = createPositiveFeedback()
        feedback.context = nil

        let input = FeedbackAnalysisTool.FeedbackAnalysisInput(
            feedback: feedback,
            analysisDepth: "detailed",
            includeActionItems: true,
            extractTechnicalDetails: true
        )

        let result = try await feedbackTool.handle(input)

        XCTAssertNotNil(result.analysis)
        // Should handle nil context gracefully
        XCTAssertNotNil(result.analysis?.sentimentAnalysis)
        XCTAssertNotNil(result.analysis?.actionItems)
    }

    // MARK: - Performance Tests

    func testAnalysisPerformanceWithLargeFeedback() async throws {
        let startTime = CFAbsoluteTimeGetCurrent()

        let largeFeedbackText = String(repeating: """
        This feedback contains detailed technical analysis and creative notes about the mix.
        The vocal processing needs attention - the compression is too heavy and the EQ needs adjustment.
        Drums lack impact and the bass could be more present.
        Guitar tones are good but could use some refinement in the high frequencies.
        The overall balance needs work and the stereo image could be wider.
        """, count: 50)

        let largeFeedback = FeedbackAnalysisTool.FeedbackData(
            feedbackText: largeFeedbackText,
            source: "comprehensive_review",
            clientName: "Detail-Oriented Client",
            projectName: "Large Project",
            mixVersion: "v15",
            timestamp: "2025-10-09T14:30:00Z",
            context: FeedbackAnalysisTool.FeedbackContext(
                previousFeedback: Array(repeating: "Previous feedback note", count: 20),
                sessionType: "detailed_review",
                referenceTracks: Array(repeating: "Reference Track", count: 10),
                targetGenre: "Rock",
                deliveryFormat: "Album"
            ),
            metadata: ["review_length": "comprehensive", "analysis_type": "detailed"]
        )

        let input = FeedbackAnalysisTool.FeedbackAnalysisInput(
            feedback: largeFeedback,
            analysisDepth: "comprehensive",
            includeActionItems: true,
            extractTechnicalDetails: true,
            useTemplate: true,
            templateType: "internal_review"
        )

        let result = try await feedbackTool.handle(input)
        let processingTime = CFAbsoluteTimeGetCurrent() - startTime

        XCTAssertNotNil(result.analysis)
        XCTAssertLessThan(processingTime, 5.0, "Analysis should complete within 5 seconds")
    }
}