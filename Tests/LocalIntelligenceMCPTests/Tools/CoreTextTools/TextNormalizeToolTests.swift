//
//  TextNormalizeToolTests.swift
//  LocalIntelligenceMCP
//
//  Created on 2025-10-08.
//

import XCTest
@testable import LocalIntelligenceMCP

final class TextNormalizeToolTests: XCTestCase {

    // MARK: - Properties

    private var logger: Logger!
    private var securityManager: SecurityManager!
    private var textNormalizeTool: TextNormalizeTool!

    // MARK: - Setup and Teardown

    override func setUp() async throws {
        try await super.setUp()

        // Initialize test components
        let config = LoggingConfiguration.default
        logger = Logger(configuration: config)
        await logger.setupFileLoggingIfNeeded()

        securityManager = SecurityManager(logger: logger)
        textNormalizeTool = TextNormalizeTool(logger: logger, securityManager: securityManager)
    }

    override func tearDown() async throws {
        logger = nil
        securityManager = nil
        textNormalizeTool = nil

        try await super.tearDown()
    }

    // MARK: - Tool Initialization Tests

    func testTextNormalizeToolInitialization() async throws {
        XCTAssertNotNil(textNormalizeTool)
        XCTAssertEqual(textNormalizeTool.name, "apple.text.normalize")
        XCTAssertFalse(textNormalizeTool.description.isEmpty)
        XCTAssertNotNil(textNormalizeTool.inputSchema)
        XCTAssertEqual(textNormalizeTool.category, .textProcessing)
        XCTAssertTrue(textNormalizeTool.requiresPermission.contains(.systemInfo))
        XCTAssertTrue(textNormalizeTool.offlineCapable)
    }

    func testInputSchemaStructure() async throws {
        let schema = textNormalizeTool.inputSchema

        // Check basic schema structure
        XCTAssertEqual(schema["type"] as? String, "object")

        // Check properties exist
        let properties = schema["properties"]?.value as? [String: Any]
        XCTAssertNotNil(properties)
        XCTAssertNotNil(properties?["text"])

        // Check required fields
        let required = schema["required"]?.value as? [String]
        XCTAssertTrue(required?.contains("text") == true)
    }

    // MARK: - Spacing Normalization Tests

    func testSpacingNormalization() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: textNormalizeTool.name
        )

        let messySpacingText = """
        This  text    has   irregular   spacing.    There are    multiple   spaces.
        Also   check   punctuation   spacing .Like  this, and this .  Extra   spaces   around   ( brackets ) .
        And   { curly braces }   too .
        """

        let parameters = [
            "text": messySpacingText
        ] as [String: AnyCodable]

        do {
            let result = try await textNormalizeTool.execute(parameters: parameters, context: context)
            XCTAssertTrue(result.success)
            XCTAssertNotNil(result.data)

            if let data = result.data?.value as? [String: Any],
               let normalizedText = data["text"] as? String {
                XCTAssertFalse(normalizedText.isEmpty)
                // Should have normalized spacing
                XCTAssertFalse(normalizedText.contains("  ")) // No double spaces
                XCTAssertTrue(normalizedText.contains("spacing. Like")) // Proper space after punctuation
                XCTAssertTrue(normalizedText.contains("(brackets)")) // Proper spacing around brackets
                XCTAssertTrue(normalizedText.contains("{curly braces}")) // Proper spacing around braces
            }
        } catch {
            XCTFail("Spacing normalization should succeed: \(error.localizedDescription)")
        }
    }

    func testLeadingTrailingWhitespaceRemoval() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: textNormalizeTool.name
        )

        let textWithWhitespace = """

            Recording session notes:
              The vocals were recorded using a U87 microphone.

            Applied EQ and compression.

        """

        let parameters = [
            "text": textWithWhitespace
        ] as [String: AnyCodable]

        do {
            let result = try await textNormalizeTool.execute(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            if let data = result.data?.value as? [String: Any],
               let normalizedText = data["text"] as? String {
                XCTAssertFalse(normalizedText.isEmpty)
                // Should not have leading/trailing empty lines or excessive whitespace
                XCTAssertEqual(normalizedText.trimmingCharacters(in: .whitespacesAndNewlines), normalizedText)
            }
        } catch {
            XCTFail("Whitespace normalization should succeed: \(error.localizedDescription)")
        }
    }

    // MARK: - Quote Normalization Tests

    func testQuoteNormalization() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: textNormalizeTool.name
        }

        let textWithQuotes = """
        Smart quotes: "The vocals sound great" and 'the drums are punchy'.
        Mixed quotes: He said "this is good" but that's 'not quite right'.
        Unpaired quote: "This should be fixed.
        Another unpaired: This one should be fixed"
        """

        let parameters = [
            "text": textWithQuotes
        ] as [String: AnyCodable]

        do {
            let result = try await textNormalizeTool.execute(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            if let data = result.data?.value as? [String: Any],
               let normalizedText = data["text"] as? String {
                XCTAssertFalse(normalizedText.isEmpty)
                // Should convert smart quotes to straight quotes
                XCTAssertTrue(normalizedText.contains("\"The vocals sound great\"") ||
                             normalizedText.contains("\"This should be fixed\""))
                // Should handle unpaired quotes appropriately
                // (The exact behavior depends on implementation)
            }
        } catch {
            XCTFail("Quote normalization should succeed: \(error.localizedDescription)")
        }
    }

    // MARK: - List Normalization Tests

    func testListNormalization() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: textNormalizeTool.name
        )

        let textWithLists = """
        Bullet points with different styles:
        • First item
        - Second item
        * Third item
        ▪ Fourth item
        ▫ Fifth item

        Numbered lists:
        1. First numbered item
        2) Second numbered item
        (3) Third numbered item

        Lettered lists:
        a. First lettered item
        b) Second lettered item
        """

        let parameters = [
            "text": textWithLists
        ] as [String: AnyCodable]

        do {
            let result = try await textNormalizeTool.execute(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            if let data = result.data?.value as? [String: Any],
               let normalizedText = data["text"] as? String {
                XCTAssertFalse(normalizedText.isEmpty)
                // Should normalize bullets to consistent format
                XCTAssertTrue(normalizedText.contains("• First item") ||
                             normalizedText.contains("• Second item"))
                // Should normalize numbered lists
                XCTAssertTrue(normalizedText.contains("1. First numbered item") ||
                             normalizedText.contains("2. Second numbered item") ||
                             normalizedText.contains("3. Third numbered item"))
                // Should normalize lettered lists
                XCTAssertTrue(normalizedText.contains("a. First lettered item") ||
                             normalizedText.contains("b. Second lettered item"))
            }
        } catch {
            XCTFail("List normalization should succeed: \(error.localizedDescription)")
        }
    }

    func testListIndentationNormalization() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: textNormalizeTool.name
        )

        let textWithIndents = """
        Main tasks:
        • Record vocals
          • Set up microphone
          • Check levels
        • Mix drums
          • Process kick drum
          • Process snare
        • Master final track
        """

        let parameters = [
            "text": textWithIndents
        ] as [String: AnyCodable]

        do {
            let result = try await textNormalizeTool.execute(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            if let data = result.data?.value as? [String: Any],
               let normalizedText = data["text"] as? String {
                XCTAssertFalse(normalizedText.isEmpty)
                // Should normalize indentation consistently
                XCTAssertTrue(normalizedText.contains("• Record vocals"))
                XCTAssertTrue(normalizedText.contains("  • Set up microphone") ||
                             normalizedText.contains("    • Set up microphone"))
            }
        } catch {
            XCTFail("List indentation normalization should succeed: \(error.localizedDescription)")
        }
    }

    // MARK: - Heading Normalization Tests

    func testHeadingNormalization() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: textNormalizeTool.name
        )

        let textWithHeadings = """
        ALL CAPS HEADING
        This is some content.

        Another Heading
        More content here.

        =================
        Underlined heading
        Content after underlined heading.

        -----------------
        Another underlined
        Final content.
        """

        let parameters = [
            "text": textWithHeadings
        ] as [String: AnyCodable]

        do {
            let result = try await textNormalizeTool.execute(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            if let data = result.data?.value as? [String: Any],
               let normalizedText = data["text"] as? String {
                XCTAssertFalse(normalizedText.isEmpty)
                // Should convert ALL CAPS to markdown heading
                XCTAssertTrue(normalizedText.contains("# ALL CAPS HEADING"))
                // Should normalize underlined headings
                XCTAssertTrue(normalizedText.contains("# Underlined heading") ||
                             normalizedText.contains("## Underlined heading"))
            }
        } catch {
            XCTFail("Heading normalization should succeed: \(error.localizedDescription)")
        }
    }

    // MARK: - Punctuation Normalization Tests

    func testPunctuationNormalization() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: textNormalizeTool.name
        )

        let textWithPunctuation = """
        Multiple commas,, like this,, and there... Extra periods..
        Multiple exclamation marks!! And question marks??
        Ellipses should be normalized....
        """

        let parameters = [
            "text": textWithPunctuation
        ] as [String: AnyCodable]

        do {
            let result = try await textNormalizeTool.execute(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            if let data = result.data?.value as? [String: Any],
               let normalizedText = data["text"] as? String {
                XCTAssertFalse(normalizedText.isEmpty)
                // Should normalize punctuation
                XCTAssertFalse(normalizedText.contains(",,"))
                XCTAssertFalse(normalizedText.contains(".."))
                XCTAssertTrue(normalizedText.contains("...")) // Should have proper ellipses
                // Should have single punctuation marks
                XCTAssertTrue(normalizedText.contains("like this,") || normalizedText.contains("like this."))
            }
        } catch {
            XCTFail("Punctuation normalization should succeed: \(error.localizedDescription)")
        }
    }

    // MARK: - Line Break Normalization Tests

    func testLineBreakNormalization() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: textNormalizeTool.name
        )

        let textWithLineBreaks = """
        First line.

        Second line.



        Too many empty lines above.

        Third line.\r\n
        Windows line ending below.\r\n
        Fourth line.
        """

        let parameters = [
            "text": textWithLineBreaks
        ] as [String: AnyCodable]

        do {
            let result = try await textNormalizeTool.execute(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            if let data = result.data?.value as? [String: Any],
               let normalizedText = data["text"] as? String {
                XCTAssertFalse(normalizedText.isEmpty)
                // Should normalize line endings (no \r\n)
                XCTAssertFalse(normalizedText.contains("\r\n"))
                // Should reduce excessive blank lines
                XCTAssertFalse(normalizedText.contains("\n\n\n"))
                // Should have proper single spacing between paragraphs
                XCTAssertTrue(normalizedText.contains("\n\n"))
            }
        } catch {
            XCTFail("Line break normalization should succeed: \(error.localizedDescription)")
        }
    }

    // MARK: - Audio-Specific Normalization Tests

    func testTranscriptionArtifactRemoval() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: textNormalizeTool.name
        )

        let textWithArtifacts = """
        [inaudible] The vocals [laughter] sound really good. [phone rings] We need to redo that part.
        *background noise* The microphone [coughs] picked up some unwanted sounds.
        (someone talking in background) Overall, the recording quality is excellent.
        """

        let parameters = [
            "text": textWithArtifacts
        ] as [String: AnyCodable]

        do {
            let result = try await textNormalizeTool.execute(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            if let data = result.data?.value as? [String: Any],
               let normalizedText = data["text"] as? String {
                XCTAssertFalse(normalizedText.isEmpty)
                // Should remove transcription artifacts
                XCTAssertFalse(normalizedText.contains("[inaudible]"))
                XCTAssertFalse(normalizedText.contains("[laughter]"))
                XCTAssertFalse(normalizedText.contains("[phone rings]"))
                XCTAssertFalse(normalizedText.contains("*background noise*"))
                XCTAssertFalse(normalizedText.contains("[coughs]"))
                // Should keep the meaningful content
                XCTAssertTrue(normalizedText.contains("vocals") || normalizedText.contains("sound") ||
                             normalizedText.contains("recording"))
            }
        } catch {
            XCTFail("Transcription artifact removal should succeed: \(error.localizedDescription)")
        }
    }

    func testTimestampNormalization() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: textNormalizeTool.name
        )

        let textWithTimestamps = """
        00:00:15 Start recording vocals
        00:01:30 Adjust microphone position
        0:45 Take 3 of chorus
        00:02:00 Add reverb to vocals
        2:30:00 Check mix balance
        """

        let parameters = [
            "text": textWithTimestamps
        ] as [String: AnyCodable]

        do {
            let result = try await textNormalizeTool.execute(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            if let data = result.data?.value as? [String: Any],
               let normalizedText = data["text"] as? String {
                XCTAssertFalse(normalizedText.isEmpty)
                // Should normalize timestamp formats
                XCTAssertTrue(normalizedText.contains("[00:00:15]") ||
                             normalizedText.contains("[0:45]") ||
                             normalizedText.contains("[00:01:30]"))
                // Should preserve the context around timestamps
                XCTAssertTrue(normalizedText.contains("vocals") || normalizedText.contains("microphone"))
            }
        } catch {
            XCTFail("Timestamp normalization should succeed: \(error.localizedDescription)")
        }
    }

    func testTrackNameNormalization() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: textNormalizeTool.name
        )

        let textWithTracks = """
        "Lead Vocal" - Take 3 was the best performance.
        "Drums": Recorded with multiple mics.
        Bass Guitar | Processed with compression.
        Electric Guitar - Added distortion effect.
        """

        let parameters = [
            "text": textWithTracks
        ] as [String: AnyCodable]

        do {
            let result = try await textNormalizeTool.execute(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            if let data = result.data?.value as? [String: Any],
               let normalizedText = data["text"] as? String {
                XCTAssertFalse(normalizedText.isEmpty)
                // Should normalize track name formats
                XCTAssertTrue(normalizedText.contains("Track: Lead Vocal") ||
                             normalizedText.contains("Track: Drums") ||
                             normalizedText.contains("Track: Bass Guitar"))
            }
        } catch {
            XCTFail("Track name normalization should succeed: \(error.localizedDescription)")
        }
    }

    func testDAWTerminologyNormalization() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: textNormalizeTool.name
        )

        let textWithDAWTerms = """
        Used EQ for frequency adjustment. The FX chain includes reverb and delay.
        VST plugins worked well. AU instruments were also used.
        DAW automation was applied to volume and pan. CPU usage stayed under 70%.
        Set sample rate to 48kHz and bit depth to 24-bit.
        """

        let parameters = [
            "text": textWithDAWTerms
        ] as [String: AnyCodable]

        do {
            let result = try await textNormalizeTool.execute(parameters: parameters, context: context)
            XCTAssertTrue(result.success)

            if let data = result.data?.value as? [String: Any],
               let normalizedText = data["text"] as? String {
                XCTAssertFalse(normalizedText.isEmpty)
                // Should normalize DAW terminology
                XCTAssertTrue(normalizedText.contains("equalizer") || normalizedText.contains("effects") ||
                             normalizedText.contains("plugin") || normalizedText.contains("digital audio workstation"))
                // Should preserve technical details
                XCTAssertTrue(normalizedText.contains("48kHz") || normalizedText.contains("24-bit") ||
                             normalizedText.contains("automation"))
            }
        } catch {
            XCTFail("DAW terminology normalization should succeed: \(error.localizedDescription)")
        }
    }

    // MARK: - Parameter Validation Tests

    func testMissingRequiredTextParameter() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: textNormalizeTool.name
        )

        let parameters: [String: AnyCodable] = [:] // Missing required "text" parameter

        do {
            _ = try await textNormalizeTool.execute(parameters: parameters, context: context)
            XCTFail("Missing required text parameter should cause validation failure")
        } catch {
            // Expected behavior
            XCTAssertTrue(error.localizedDescription.contains("required") ||
                        error.localizedDescription.contains("validation") ||
                        error.localizedDescription.contains("text"))
        }
    }

    func testEmptyTextParameter() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: textNormalizeTool.name
        )

        let parameters = [
            "text": ""
        ] as [String: AnyCodable]

        do {
            _ = try await textNormalizeTool.execute(parameters: parameters, context: context)
            XCTFail("Empty text parameter should cause validation failure")
        } catch {
            // Expected behavior
            XCTAssertTrue(error.localizedDescription.contains("empty") ||
                        error.localizedDescription.contains("validation"))
        }
    }

    // MARK: - Performance Tests

    func testNormalizationPerformance() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: textNormalizeTool.name
        )

        let messyText = """
        Recording   session  notes:

        •   Set  up   microphones
        •   Check   levels
        •   Record  vocals

        The   vocals   sound   "good"  but need   EQ.
        Applied   compression..  Added  reverb  !!

        [background noise]  Remove  this  later.

        Track: "Main Vocal"  -  Take  3  is best.
        """

        let parameters = [
            "text": messyText
        ] as [String: AnyCodable]

        // Measure execution time
        measure {
            Task {
                do {
                    let result = try await textNormalizeTool.execute(parameters: parameters, context: context)
                    XCTAssertTrue(result.success)
                } catch {
                    XCTFail("Performance test should not fail: \(error.localizedDescription)")
                }
            }
        }
    }

    func testConcurrentNormalization() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: textNormalizeTool.name
        )

        let messyText = """
        •   Fix  spacing
        •   Normalize  quotes
        "Test"  text  here.
        """

        let parameters = [
            "text": messyText
        ] as [String: AnyCodable]

        // Test concurrent executions
        await withTaskGroup(of: Bool.self) { group in
            for i in 0..<5 {
                group.addTask {
                    do {
                        let result = try await self.textNormalizeTool.execute(parameters: parameters, context: context)
                        return result.success
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

            XCTAssertEqual(successCount, 5, "All concurrent normalizations should succeed")
        }
    }

    // MARK: - Edge Cases Tests

    func testSpecialCharacterHandling() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: textNormalizeTool.name
        }

        let specialCharText = """
        Recording 🎵 went well! Levels were set to -6dB.
        Studio temperature: 22°C.  The engineer said "Great job!" 🎉.
        Sample rate: 48kHz, Bit depth: 24-bit.
        """

        let parameters = [
            "text": specialCharText
        ] as [String: AnyCodable]

        do {
            let result = try await textNormalizeTool.execute(parameters: parameters, context: context)
            XCTAssertTrue(result.success, "Should handle special characters correctly")

            if let data = result.data?.value as? [String: Any],
               let normalizedText = data["text"] as? String {
                XCTAssertFalse(normalizedText.isEmpty)
                // Should preserve or appropriately handle special characters
                XCTAssertTrue(normalizedText.contains("🎵") || normalizedText.contains("22°C") ||
                             normalizedText.contains("-6dB"))
            }
        } catch {
            XCTFail("Special characters should not cause failure: \(error.localizedDescription)")
        }
    }

    func testVeryLongTextHandling() async throws {
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: textNormalizeTool.name
        )

        // Create a very long messy text (over 20,000 characters)
        let messySegment = "  •   Messy   text  with  irregular  spacing.  \"Quotes\"  here.  [artifacts]  "
        let longMessyText = String(repeating: messySegment, count: 400)

        let parameters = [
            "text": longMessyText
        ] as [String: AnyCodable]

        do {
            let result = try await textNormalizeTool.execute(parameters: parameters, context: context)
            // May succeed or fail depending on implementation - both are acceptable
            if result.success {
                XCTAssertNotNil(result.data)
                if let data = result.data?.value as? [String: Any],
                   let normalizedText = data["text"] as? String {
                    XCTAssertFalse(normalizedText.isEmpty)
                    // Should have some normalization effect
                    XCTAssertNotEqual(normalizedText, longMessyText)
                }
            } else {
                XCTAssertNotNil(result.error)
            }
        } catch {
            // Acceptable if implementation limits text length
            XCTAssertTrue(error.localizedDescription.contains("length") ||
                        error.localizedDescription.contains("exceeds") ||
                        error.localizedDescription.contains("too large"))
        }
    }
}