//
//  CoreTextToolsIntegrationTests.swift
//  LocalIntelligenceMCP
//
//  Created on 2025-10-08.
//

import XCTest
@testable import LocalIntelligenceMCP

final class CoreTextToolsIntegrationTests: XCTestCase {

    // MARK: - Properties

    private var logger: Logger!
    private var securityManager: SecurityManager!
    private var summarizationTool: SummarizationTool!
    private var textRewriteTool: TextRewriteTool!
    private var textNormalizeTool: TextNormalizeTool!

    // MARK: - Setup and Teardown

    override func setUp() async throws {
        try await super.setUp()

        // Initialize test components
        let config = LoggingConfiguration.default
        logger = Logger(configuration: config)
        await logger.setupFileLoggingIfNeeded()

        securityManager = SecurityManager(logger: logger)
        summarizationTool = SummarizationTool(logger: logger, securityManager: securityManager)
        textRewriteTool = TextRewriteTool(logger: logger, securityManager: securityManager)
        textNormalizeTool = TextNormalizeTool(logger: logger, securityManager: securityManager)
    }

    override func tearDown() async throws {
        logger = nil
        securityManager = nil
        summarizationTool = nil
        textRewriteTool = nil
        textNormalizeTool = nil

        try await super.tearDown()
    }

    // MARK: - Integration Workflow Tests

    func testCompleteAudioSessionNotesProcessing() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: "integration_test"
        )

        // Step 1: Start with messy session notes
        let messySessionNotes = """

        Recording session  notes:

        •  Set up microphones
           Used U87 for vocals
           SM57 for guitar amp
        •   Check levels
           Peaks at -6dB
           RMS at -18dB
        •  Record takes
           Vocal:  "This  was  good"
           Guitar: Need   more reverb

        [background noise]  Remove later

        The  vocals  sound  "excellent"  but need  EQ..  The guitar  is too quiet!!
        Applied  compression..  Added  reverb  !!

        Track: "Lead Vocal"  -  Take  3  is best.
        Track: "Electric Guitar"  |  Processed  with  distortion.

        Overall   mix   sounds   professional   and polished.
        """

        // Step 2: Normalize the messy text
        let normalizeParameters = [
            "text": messySessionNotes
        ] as [String: AnyCodable]

        let normalizeResult = try await textNormalizeTool.execute(parameters: normalizeParameters, context: context)
        XCTAssertTrue(normalizeResult.success)

        guard let normalizedData = normalizeResult.data?.value as? [String: Any],
              let normalizedText = normalizedData["text"] as? String else {
            XCTFail("Normalization should return valid text")
            return
        }

        // Verify normalization worked
        XCTAssertFalse(normalizedText.contains("  ")) // No double spaces
        XCTAssertFalse(normalizedText.contains("[background noise]")) // Artifacts removed
        XCTAssertTrue(normalizedText.contains("Track: Lead Vocal")) // Track format normalized

        // Step 3: Rewrite with technical tone for professional documentation
        let rewriteParameters = [
            "text": normalizedText,
            "tone": "technical",
            "length": "medium"
        ] as [String: AnyCodable]

        let rewriteResult = try await textRewriteTool.execute(parameters: rewriteParameters, context: context)
        XCTAssertTrue(rewriteResult.success)

        guard let rewrittenData = rewriteResult.data?.value as? [String: Any],
              let rewrittenText = rewrittenData["text"] as? String else {
            XCTFail("Rewriting should return valid text")
            return
        }

        // Verify rewriting worked
        XCTAssertTrue(rewrittenText.contains("technical") || rewrittenText.contains("precise") ||
                     rewrittenText.contains("optimize") || rewrittenText.contains("rectify"))

        // Step 4: Create executive summary for stakeholders
        let summarizeParameters = [
            "text": rewrittenText,
            "style": "executive",
            "max_points": 5
        ] as [String: AnyCodable]

        let summarizeResult = try await summarizationTool.execute(parameters: summarizeParameters, context: context)
        XCTAssertTrue(summarizeResult.success)

        guard let summaryData = summarizeResult.data?.value as? [String: Any],
              let summaryText = summaryData["text"] as? String else {
            XCTFail("Summarization should return valid text")
            return
        }

        // Verify final summary
        XCTAssertTrue(summaryText.contains("Executive Summary"))
        XCTAssertTrue(summaryText.contains("Key insights") || summaryText.contains("Summary Statistics"))
        XCTAssertLessThanOrEqual(summaryText.components(separatedBy: ".").count, 10) // Concise summary

        print("Integration test completed successfully!")
        print("Original length: \(messySessionNotes.count) characters")
        print("Normalized length: \(normalizedText.count) characters")
        print("Rewritten length: \(rewrittenText.count) characters")
        print("Summary length: \(summaryText.count) characters")
    }

    func testToolsRegistryIntegration() async throws {
        // Test that all tools can be registered and discovered
        let toolsRegistry = ToolsRegistry(logger: logger, securityManager: securityManager)

        // Register all core text tools
        try await toolsRegistry.registerTool(summarizationTool)
        try await toolsRegistry.registerTool(textRewriteTool)
        try await toolsRegistry.registerTool(textNormalizeTool)

        // Get all available tools
        let availableTools = await toolsRegistry.getAvailableTools()
        XCTAssertEqual(availableTools.count, 3)

        // Get tools by category
        let textProcessingTools = await toolsRegistry.getToolsByCategory(.textProcessing)
        XCTAssertEqual(textProcessingTools.count, 3)

        // Get audio domain tools (should include text processing tools)
        let audioDomainTools = await toolsRegistry.getAudioDomainTools()
        XCTAssertEqual(audioDomainTools.count, 3)

        // Verify tool names are present
        let toolNames = availableTools.map { $0.name }
        XCTAssertTrue(toolNames.contains("apple.summarize"))
        XCTAssertTrue(toolNames.contains("apple.text.rewrite"))
        XCTAssertTrue(toolNames.contains("apple.text.normalize"))

        // Test tool execution through registry
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: "apple.summarize"
        )

        let testText = "Audio session: Applied EQ and compression to vocals. Added reverb for space."

        let executionResult = try await toolsRegistry.executeTool(
            name: "apple.summarize",
            parameters: ["text": testText, "style": "bullet"],
            context: context
        )

        XCTAssertTrue(executionResult.success)
        XCTAssertNotNil(executionResult.data)
    }

    func testAudioWorkflowTransformation() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: "audio_workflow_test"
        )

        // Simulate real-world audio workflow transformation
        let rawTranscription = """
        [inaudible]  uh, so today we're   working on the  mix

        um, the vocals  need some  work.   I think we should   "adjust the EQ"  a little bit.
        the highs are  a bit harsh...  maybe   around 8k we could  bring that down.

        also  the bass guitar  is too  loud in the mix..  we need to   turn that down
        maybe   about 3dB or so.

        Track: "Main Vocals"  -  Take  2  sounds  good
        Track: "Bass Guitar"  |  Level  too  high

        [phone rings]  sorry about that

        let's  see...  the drums sound  pretty good though.  the kick has  nice impact
        and the snare cuts through  well.  overall  I think  the mix is  heading  in  the  right direction.
        just need to  fix those  few issues.

        applied  some compression to  the vocals..  ratio  4:1..  attack  medium..
        release  fast.  that helped  a lot.

        the  reverb  sounds  nice  but maybe  we could  make it  a bit  shorter?
        yeah, I  think  that'll  work  better.

        ok, I think  that's  it  for today.   good progress  made.
        """

        // Step 1: Clean up transcription
        let normalizeParams = ["text": rawTranscription] as [String: AnyCodable]
        let normalizeResult = try await textNormalizeTool.execute(parameters: normalizeParams, context: context)
        XCTAssertTrue(normalizeResult.success)

        guard let normalizedText = normalizeResult.data?.value as? [String: Any]?["text"] as? String else {
            XCTFail("Normalization failed")
            return
        }

        // Step 2: Make it more professional for client review
        let rewriteParams = [
            "text": normalizedText,
            "tone": "executive",
            "length": "medium"
        ] as [String: AnyCodable]

        let rewriteResult = try await textRewriteTool.execute(parameters: rewriteParams, context: context)
        XCTAssertTrue(rewriteResult.success)

        guard let rewrittenText = rewriteResult.data?.value as? [String: Any]?["text"] as? String else {
            XCTFail("Rewriting failed")
            return
        }

        // Step 3: Create summary for project manager
        let summarizeParams = [
            "text": rewrittenText,
            "style": "abstract",
            "max_points": 4
        ] as [String: AnyCodable]

        let summarizeResult = try await summarizationTool.execute(parameters: summarizeParams, context: context)
        XCTAssertTrue(summarizeResult.success)

        guard let summaryText = summarizeResult.data?.value as? [String: Any]?["text"] as? String else {
            XCTFail("Summarization failed")
            return
        }

        // Verify the transformation chain worked
        XCTAssertFalse(summaryText.isEmpty)
        XCTAssertTrue(summaryText.contains("Abstract"))
        XCTAssertFalse(summaryText.contains("[inaudible]"))
        XCTAssertFalse(summaryText.contains("[phone rings]"))

        print("Audio workflow transformation completed!")
        print("Summary generated: \(summaryText)")
    }

    func testErrorHandlingAcrossTools() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: "error_handling_test"
        )

        // Test 1: Invalid parameters at each stage
        let invalidText = ""

        // Normalization with empty text should fail
        do {
            _ = try await textNormalizeTool.execute(
                parameters: ["text": invalidText],
                context: context
            )
            XCTFail("Should fail with empty text")
        } catch {
            XCTAssertTrue(error.localizedDescription.contains("empty") ||
                        error.localizedDescription.contains("validation"))
        }

        // Test 2: Valid normalization but invalid rewrite parameters
        let validText = "This is valid audio session text."
        let normalizeResult = try await textNormalizeTool.execute(
            parameters: ["text": validText],
            context: context
        )
        XCTAssertTrue(normalizeResult.success)

        // Try rewrite with invalid tone
        do {
            _ = try await textRewriteTool.execute(
                parameters: [
                    "text": normalizeResult.data?.value as? [String: Any]?["text"] as? String ?? validText,
                    "tone": "invalid_tone"
                ],
                context: context
            )
            XCTFail("Should fail with invalid tone")
        } catch {
            XCTAssertTrue(error.localizedDescription.contains("tone") ||
                        error.localizedDescription.contains("validation"))
        }

        // Test 3: Valid rewrite but invalid summary parameters
        let rewriteResult = try await textRewriteTool.execute(
            parameters: [
                "text": validText,
                "tone": "technical",
                "length": "short"
            ],
            context: context
        )
        XCTAssertTrue(rewriteResult.success)

        // Try summary with invalid max_points
        do {
            _ = try await summarizationTool.execute(
                parameters: [
                    "text": rewriteResult.data?.value as? [String: Any]?["text"] as? String ?? validText,
                    "max_points": 20 // Exceeds maximum of 15
                ],
                context: context
            )
            XCTFail("Should fail with invalid max_points")
        } catch {
            XCTAssertTrue(error.localizedDescription.contains("max_points") ||
                        error.localizedDescription.contains("validation"))
        }
    }

    func testConcurrentToolExecution() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: "concurrent_test"
        )

        let audioTexts = [
            "Vocal recording: Applied EQ and compression. Sound is clear.",
            "Drum tracking: Multiple mics used. Phase issues resolved.",
            "Bass recording: Direct input. Added saturation plugin.",
            "Guitar overdubs: Amp simulation applied. Good tone achieved.",
            "Mixing session: Balance adjusted. Mastering chain prepared."
        ]

        // Test concurrent execution of all three tools on different inputs
        await withTaskGroup(of: Bool.self) { group in
            for (index, audioText) in audioTexts.enumerated() {
                group.addTask {
                    do {
                        // Step 1: Normalize
                        let normalizeResult = try await self.textNormalizeTool.execute(
                            parameters: ["text": audioText],
                            context: context
                        )
                        guard normalizeResult.success,
                              let normalizedText = normalizeResult.data?.value as? [String: Any]?["text"] as? String else {
                            return false
                        }

                        // Step 2: Rewrite
                        let rewriteResult = try await self.textRewriteTool.execute(
                            parameters: [
                                "text": normalizedText,
                                "tone": index % 2 == 0 ? "technical" : "executive",
                                "length": "short"
                            ],
                            context: context
                        )
                        guard rewriteResult.success,
                              let rewrittenText = rewriteResult.data?.value as? [String: Any]?["text"] as? String else {
                            return false
                        }

                        // Step 3: Summarize
                        let summarizeResult = try await self.summarizationTool.execute(
                            parameters: [
                                "text": rewrittenText,
                                "style": "bullet",
                                "max_points": 3
                            ],
                            context: context
                        )
                        return summarizeResult.success
                    } catch {
                        return false
                    }
                }
            }

            var successCount = 0
            for await success in group {
                if success {
                    successCount += 1
                }
            }

            XCTAssertEqual(successCount, audioTexts.count, "All concurrent workflows should succeed")
        }
    }

    func testAudioSpecificContentHandling() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: "audio_content_test"
        )

        let highlyTechnicalAudioText = """
        Digital Audio Workstation session: Sample rate at 96kHz, 24-bit depth.
        Used UAD plugins for EQ and compression. Set vocal compressor to 4:1 ratio,
        attack 15ms, release 100ms, threshold -18dB. Applied high-pass filter at 80Hz.
        Reverb: Lexicon PCM Native, predelay 20ms, decay 2.5s, wet/dry 30%.
        Automation: Volume automation on vocal track, pan automation on guitars.
        Mastering: Used Ozone Izotope for final polish, LUFS target -14.
        """

        // Test that all tools handle technical audio content appropriately
        let normalizeParams = ["text": highlyTechnicalAudioText] as [String: AnyCodable]
        let normalizeResult = try await textNormalizeTool.execute(parameters: normalizeParams, context: context)
        XCTAssertTrue(normalizeResult.success)

        let rewriteParams = [
            "text": normalizeResult.data?.value as? [String: Any]?["text"] as? String ?? highlyTechnicalAudioText,
            "tone": "friendly",
            "length": "medium"
        ] as [String: AnyCodable]

        let rewriteResult = try await textRewriteTool.execute(parameters: rewriteParams, context: context)
        XCTAssertTrue(rewriteResult.success)

        let summarizeParams = [
            "text": rewriteResult.data?.value as? [String: Any]?["text"] as? String ?? highlyTechnicalAudioText,
            "style": "executive",
            "max_points": 4
        ] as [String: AnyCodable]

        let summarizeResult = try await summarizationTool.execute(parameters: summarizeParams, context: context)
        XCTAssertTrue(summarizeResult.success)

        // Verify audio-specific content is preserved and enhanced appropriately
        guard let summaryText = summarizeResult.data?.value as? [String: Any]?["text"] as? String else {
            XCTFail("Summary should be available")
            return
        }

        XCTAssertTrue(summaryText.contains("Executive Summary"))
        // Should maintain some audio relevance even after all transformations
        XCTAssertTrue(summaryText.lowercased().contains("audio") ||
                     summaryText.lowercased().contains("record") ||
                     summaryText.lowercased().contains("mix"))
    }

    // MARK: - Performance and Load Tests

    func testPerformanceUnderLoad() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: "performance_test"
        )

        let testText = """
        Recording session: Applied EQ to enhance clarity. Used compression for dynamic control.
        Added reverb for spatial depth. The mix sounds professional and polished.
        """

        // Test performance with concurrent execution
        await withTaskGroup(of: TimeInterval.self) { group in
            for i in 0..<20 {
                group.addTask {
                    let startTime = Date()
                    do {
                        let result = try await self.summarizationTool.execute(
                            parameters: [
                                "text": testText,
                                "style": "bullet"
                            ],
                            context: context
                        )
                        if result.success {
                            return Date().timeIntervalSince(startTime)
                        } else {
                            return -1
                        }
                    } catch {
                        return -1
                    }
                }
            }

            var executionTimes: [TimeInterval] = []
            for await time in group {
                if time > 0 {
                    executionTimes.append(time)
                }
            }

            XCTAssertEqual(executionTimes.count, 20, "All executions should succeed")

            let averageTime = executionTimes.reduce(0, +) / Double(executionTimes.count)
            let maxTime = executionTimes.max() ?? 0

            print("Performance test results:")
            print("Average execution time: \(String(format: "%.3f", averageTime))s")
            print("Maximum execution time: \(String(format: "%.3f", maxTime))s")
            print("Total executions: \(executionTimes.count)")

            // Performance assertions
            XCTAssertLessThan(averageTime, 1.0, "Average execution time should be under 1 second")
            XCTAssertLessThan(maxTime, 2.0, "Maximum execution time should be under 2 seconds")
        }
    }
}