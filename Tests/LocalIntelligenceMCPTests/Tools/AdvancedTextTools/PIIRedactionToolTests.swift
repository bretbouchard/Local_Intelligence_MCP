//
//  PIIRedactionToolTests.swift
//  LocalIntelligenceMCPTests
//
//  Created on 2025-10-08.
//

import XCTest
@testable import LocalIntelligenceMCP

/// Comprehensive test suite for PIIRedactionTool
/// Tests all PII categories, redaction modes, audio term preservation, and custom patterns
final class PIIRedactionToolTests: XCTestCase {

    // MARK: - Properties

    private var tool: PIIRedactionTool!
    private var mockLogger: MockLogger!
    private var mockSecurityManager: MockSecurityManager!
    private var testContext: MCPExecutionContext!

    // MARK: - Setup and Teardown

    override func setUp() async throws {
        try await super.setUp()

        mockLogger = MockLogger()
        mockSecurityManager = MockSecurityManager()
        tool = PIIRedactionTool(logger: mockLogger, securityManager: mockSecurityManager)
        testContext = MCPExecutionContext(
            clientId: UUID(),
            requestId: UUID().uuidString,
            toolName: "apple.text.redact"
        )
    }

    override func tearDown() async throws {
        tool = nil
        mockLogger = nil
        mockSecurityManager = nil
        testContext = nil

        try await super.tearDown()
    }

    // MARK: - Tool Configuration Tests

    func testToolConfiguration() {
        XCTAssertEqual(tool.name, "apple.text.redact")
        XCTAssertFalse(tool.description.isEmpty)
        XCTAssertEqual(tool.category, .audioDomain)
        XCTAssertTrue(tool.offlineCapable)
        XCTAssertTrue(tool.requiresPermission.contains(.systemInfo))
    }

    func testInputSchemaStructure() {
        let schema = tool.inputSchema

        XCTAssertEqual(schema["type"] as? String, "object")
        XCTAssertNotNil(schema["properties"])

        let properties = schema["properties"] as? [String: Any]
        XCTAssertNotNil(properties?["text"])
        XCTAssertNotNil(properties?["mode"])
        XCTAssertNotNil(properties?["categories"])
        XCTAssertNotNil(properties?["preserve_audio_terms"])
        XCTAssertNotNil(properties?["custom_patterns"])
        XCTAssertNotNil(properties?["whitelist"])

        // Verify required parameters
        if let required = schema["required"] as? [String] {
            XCTAssertTrue(required.contains("text"))
        }
    }

    // MARK: - Redaction Mode Tests

    func testRedactionModes() throws {
        let textWithPII = """
        Session with John Smith at Studio A. Contact: john.smith@example.com or 555-123-4567.
        Address: 123 Main St, Los Angeles, CA. Used Neumann U87 microphone.
        """

        let modes: [PIIRedactionTool.RedactionMode] = [.replace, .hash, .mask, .remove]

        for mode in modes {
            let result = try await tool.execute(
                parameters: [
                    "text": textWithPII,
                    "mode": mode.rawValue,
                    "categories": ["names", "emails", "phones", "addresses"],
                    "preserve_audio_terms": true
                ],
                context: testContext
            )

            XCTAssertTrue(result.success, "Mode \(mode.rawValue) should succeed")
            XCTAssertNotNil(result.data, "Mode \(mode.rawValue) should return data")

            if let data = result.data?.value as? [String: Any],
               let redactedText = data["redacted_text"] as? String {
                XCTAssertFalse(redactedText.isEmpty, "Mode \(mode.rawValue) should produce non-empty output")
                XCTAssertNotEqual(redactedText, textWithPII, "Mode \(mode.rawValue) should modify the text")
            }
        }
    }

    func testReplaceMode() throws {
        let textWithPII = """
        Recording session with Jane Doe. Email: jane.doe@studiomail.com.
        Phone: (555) 987-6543. Used professional audio equipment.
        """

        let result = try await tool.execute(
            parameters: [
                "text": textWithPII,
                "mode": "replace",
                "categories": ["names", "emails", "phones"]
            ],
            context: testContext
        )

        XCTAssertTrue(result.success)

        if let data = result.data?.value as? [String: Any],
           let redactedText = data["redacted_text"] as? String {
            XCTAssertTrue(redactedText.contains("[NAME]"))
            XCTAssertTrue(redactedText.contains("[EMAIL]"))
            XCTAssertTrue(redactedText.contains("[PHONE]"))
            XCTAssertTrue(redactedText.contains("professional audio equipment")) // Should preserve audio terms
        }
    }

    func testMaskMode() throws {
        let textWithPII = """
        Client: Robert Johnson (robert.j@email.com). Phone: 555-555-0123.
        Project: Album mixing at professional studio.
        """

        let result = try await tool.execute(
            parameters: [
                "text": textWithPII,
                "mode": "mask",
                "categories": ["names", "emails", "phones"]
            ],
            context: testContext
        )

        XCTAssertTrue(result.success)

        if let data = result.data?.value as? [String: Any],
           let redactedText = data["redacted_text"] as? String {
            XCTAssertTrue(redactedText.contains("R***** J*******")) // Masked name
            XCTAssertTrue(redactedText.contains("ro***.@email.com")) // Masked email
            XCTAssertTrue(redactedText.contains("555-***-0123")) // Masked phone
            XCTAssertTrue(redactedText.contains("Album mixing")) // Should preserve audio terms
        }
    }

    func testHashMode() throws {
        let textWithPII = """
        Producer: Michael Davis. Contact: michael@proaudio.com.
        Used SSL console and Neve preamps.
        """

        let result = try await tool.execute(
            parameters: [
                "text": textWithPII,
                "mode": "hash",
                "categories": ["names", "emails"]
            ],
            context: testContext
        )

        XCTAssertTrue(result.success)

        if let data = result.data?.value as? [String: Any],
           let redactedText = data["redacted_text"] as? String {
            // Should contain hash values (8 character hex strings)
            let hashPattern = #"[a-f0-9]{8}"#
            let regex = try NSRegularExpression(pattern: hashPattern, options: [])
            let matches = regex.matches(in: redactedText, options: [], range: NSRange(redactedText.startIndex..<redactedText.endIndex, in: redactedText))
            XCTAssertGreaterThan(matches.count, 0, "Should contain hash values")
            XCTAssertTrue(redactedText.contains("SSL console")) // Should preserve audio terms
        }
    }

    func testRemoveMode() throws {
        let textWithPII = """
        Engineer: Sarah Wilson. Contact: sarah@studio.com.
        Phone: 555-123-9876. Mastered final tracks.
        """

        let result = try await tool.execute(
            parameters: [
                "text": textWithPII,
                "mode": "remove",
                "categories": ["names", "emails", "phones"]
            ],
            context: testContext
        )

        XCTAssertTrue(result.success)

        if let data = result.data?.value as? [String: Any],
           let redactedText = data["redacted_text"] as? String {
            XCTAssertFalse(redactedText.contains("Sarah Wilson"))
            XCTAssertFalse(redactedText.contains("sarah@studio.com"))
            XCTAssertFalse(redactedText.contains("555-123-9876"))
            XCTAssertTrue(redactedText.contains("Mastered final tracks")) // Should preserve audio terms
        }
    }

    // MARK: - PII Category Tests

    func testNamesCategory() throws {
        let textWithNames = """
        Recording session with John Smith and Jane Doe.
        Producer: Robert Johnson Jr. Assistant: Mary A. Brown.
        Used professional microphone techniques.
        """

        let result = try await tool.execute(
            parameters: [
                "text": textWithNames,
                "mode": "replace",
                "categories": ["names"]
            ],
            context: testContext
        )

        XCTAssertTrue(result.success)

        if let data = result.data?.value as? [String: Any],
           let redactedText = data["redacted_text"] as? String {
            // Should redact all names but preserve audio terms
            XCTAssertFalse(redactedText.contains("John Smith"))
            XCTAssertFalse(redactedText.contains("Jane Doe"))
            XCTAssertFalse(redactedText.contains("Robert Johnson Jr."))
            XCTAssertFalse(redactedText.contains("Mary A. Brown"))
            XCTAssertTrue(redactedText.contains("Recording session"))
            XCTAssertTrue(redactedText.contains("microphone techniques"))
        }
    }

    func testEmailsCategory() throws {
        let textWithEmails = """
        Contact information:
        Producer: john.smith@studiomail.com
        Engineer: jane.doe@proaudio.net
        Assistant: robert@music-producer.org
        Used digital audio workstation.
        """

        let result = try await tool.execute(
            parameters: [
                "text": textWithEmails,
                "mode": "replace",
                "categories": ["emails"]
            ],
            context: testContext
        )

        XCTAssertTrue(result.success)

        if let data = result.data?.value as? [String: Any],
           let redactedText = data["redacted_text"] as? String {
            // Should redact all emails but preserve other text
            XCTAssertFalse(redactedText.contains("john.smith@studiomail.com"))
            XCTAssertFalse(redactedText.contains("jane.doe@proaudio.net"))
            XCTAssertFalse(redactedText.contains("robert@music-producer.org"))
            XCTAssertTrue(redactedText.contains("Producer:"))
            XCTAssertTrue(redactedText.contains("digital audio workstation"))
        }
    }

    func testPhonesCategory() throws {
        let textWithPhones = """
        Contact details:
        Studio: (555) 123-4567
        Producer: 555-987-6543
        Mobile: 1-800-555-0123
        Emergency: 555.555.9999
        Recorded with analog equipment.
        """

        let result = try await tool.execute(
            parameters: [
                "text": textWithPhones,
                "mode": "replace",
                "categories": ["phones"]
            ],
            context: testContext
        )

        XCTAssertTrue(result.success)

        if let data = result.data?.value as? [String: Any],
           let redactedText = data["redacted_text"] as? String {
            // Should redact all phone numbers
            XCTAssertFalse(redactedText.contains("(555) 123-4567"))
            XCTAssertFalse(redactedText.contains("555-987-6543"))
            XCTAssertFalse(redactedText.contains("1-800-555-0123"))
            XCTAssertFalse(redactedText.contains("555.555.9999"))
            XCTAssertTrue(redactedText.contains("analog equipment"))
        }
    }

    func testAddressesCategory() throws {
        let textWithAddresses = """
        Studio locations:
        Main Studio: 123 Main Street, Los Angeles, CA 90028
        Recording Room: 456 Music Avenue, Nashville, TN 37203
        Mix Room: 789 Sound Boulevard, New York, NY 10001
        Used professional acoustic treatment.
        """

        let result = try await tool.execute(
            parameters: [
                "text": textWithAddresses,
                "mode": "replace",
                "categories": ["addresses"]
            ],
            context: testContext
        )

        XCTAssertTrue(result.success)

        if let data = result.data?.value as? [String: Any],
           let redactedText = data["redacted_text"] as? String {
            // Should redact all addresses
            XCTAssertFalse(redactedText.contains("123 Main Street"))
            XCTAssertFalse(redactedText.contains("456 Music Avenue"))
            XCTAssertFalse(redactedText.contains("789 Sound Boulevard"))
            XCTAssertTrue(redactedText.contains("acoustic treatment"))
        }
    }

    func testFinancialCategory() throws {
        let textWithFinancial = """
        Payment information:
        Credit Card: 4532-1234-5678-9012
        Bank Account: 987654321
        Routing: 123456789
        Studio rental: $150/hour
        Used vintage audio equipment.
        """

        let result = try await tool.execute(
            parameters: [
                "text": textWithFinancial,
                "mode": "replace",
                "categories": ["financial"]
            ],
            context: testContext
        )

        XCTAssertTrue(result.success)

        if let data = result.data?.value as? [String: Any],
           let redactedText = data["redacted_text"] as? String {
            // Should redact financial information
            XCTAssertFalse(redactedText.contains("4532-1234-5678-9012"))
            XCTAssertFalse(redactedText.contains("987654321"))
            XCTAssertFalse(redactedText.contains("123456789"))
            XCTAssertTrue(redactedText.contains("vintage audio equipment"))
        }
    }

    // MARK: - Audio Term Preservation Tests

    func testAudioTermsPreservation() throws {
        let textWithAudioAndPII = """
        Session with John Smith at Abbey Road Studios.
        Used Neumann U87 microphone through Neve 1073 preamp.
        Mixed on SSL console with Waves plugins.
        Contact: john.smith@abbeyroad.com
        Applied EQ and compression techniques.
        """

        let result = try await tool.execute(
            parameters: [
                "text": textWithAudioAndPII,
                "mode": "replace",
                "categories": ["names", "emails"],
                "preserve_audio_terms": true
            ],
            context: testContext
        )

        XCTAssertTrue(result.success)

        if let data = result.data?.value as? [String: Any],
           let redactedText = data["redacted_text"] as? String {
            // Should redact PII
            XCTAssertFalse(redactedText.contains("John Smith"))
            XCTAssertFalse(redactedText.contains("john.smith@abbeyroad.com"))

            // Should preserve audio terms
            XCTAssertTrue(redactedText.contains("Abbey Road Studios"))
            XCTAssertTrue(redactedText.contains("Neumann U87"))
            XCTAssertTrue(redactedText.contains("Neve 1073"))
            XCTAssertTrue(redactedText.contains("SSL console"))
            XCTAssertTrue(redactedText.contains("Waves plugins"))
            XCTAssertTrue(redactedText.contains("EQ and compression"))
        }
    }

    func testAudioTermsWithoutPreservation() throws {
        let textWithAudioAndPII = """
        Producer: John Smith
        Studio: Universal Audio
        Equipment: Neumann microphone
        Email: john.smith@universal.com
        """

        let result = try await tool.execute(
            parameters: [
                "text": textWithAudioAndPII,
                "mode": "replace",
                "categories": ["names", "emails"],
                "preserve_audio_terms": false
            ],
            context: testContext
        )

        XCTAssertTrue(result.success)

        if let data = result.data?.value as? [String: Any],
           let redactedText = data["redacted_text"] as? String {
            // Should still preserve obvious audio brand names even without preservation
            XCTAssertTrue(redactedText.contains("Universal Audio"))
            XCTAssertTrue(redactedText.contains("Neumann"))
        }
    }

    // MARK: - Custom Pattern Tests

    func testCustomPatterns() throws {
        let textWithCustomPII = """
        Project ID: PROJ-2024-001
        Session Code: REC-456-XYZ
        Client Ref: CLI-789-ABC
        Used Pro Tools DAW.
        """

        let customPatterns = [
            [
                "name": "Project IDs",
                "pattern": #"[A-Z]{3}-\d{4}-\d{3}"#,
                "replacement": "[PROJECT_ID]"
            ],
            [
                "name": "Session Codes",
                "pattern": #"[A-Z]{3}-\d{3}-[A-Z]{3}"#,
                "replacement": "[SESSION_CODE]"
            ]
        ]

        let result = try await tool.execute(
            parameters: [
                "text": textWithCustomPII,
                "mode": "replace",
                "categories": [],
                "custom_patterns": customPatterns
            ],
            context: testContext
        )

        XCTAssertTrue(result.success)

        if let data = result.data?.value as? [String: Any],
           let redactedText = data["redacted_text"] as? String {
            // Should apply custom patterns
            XCTAssertTrue(redactedText.contains("[PROJECT_ID]"))
            XCTAssertTrue(redactedText.contains("[SESSION_CODE]"))
            XCTAssertTrue(redactedText.contains("Pro Tools")) // Should preserve audio terms
        }
    }

    // MARK: - Whitelist Tests

    func testWhitelistProtection() throws {
        let textWithWhitelistTerms = """
        Engineer: John Smith
        Studio: Smith Recording Studio
        Client: Johnson Productions
        Email: smith@studio.com
        Used Smith brand microphone.
        """

        let whitelist = ["Smith Recording Studio", "Johnson Productions", "Smith brand"]

        let result = try await tool.execute(
            parameters: [
                "text": textWithWhitelistTerms,
                "mode": "replace",
                "categories": ["names", "emails"],
                "whitelist": whitelist
            ],
            context: testContext
        )

        XCTAssertTrue(result.success)

        if let data = result.data?.value as? [String: Any],
           let redactedText = data["redacted_text"] as? String {
            // Should redact non-whitelisted names
            XCTAssertTrue(redactedText.contains("[NAME]")) // John Smith should be redacted
            XCTAssertFalse(redactedText.contains("smith@studio.com")) // Email should be redacted

            // Should preserve whitelisted terms
            XCTAssertTrue(redactedText.contains("Smith Recording Studio"))
            XCTAssertTrue(redactedText.contains("Johnson Productions"))
            XCTAssertTrue(redactedText.contains("Smith brand"))
        }
    }

    // MARK: - Metadata Tests

    func testMetadataCompleteness() throws {
        let textWithPII = """
        Contact: John Smith (john.smith@email.com, 555-123-4567).
        Studio address: 123 Main St, Los Angeles, CA.
        Used professional recording equipment.
        """

        let result = try await tool.execute(
            parameters: [
                "text": textWithPII,
                "mode": "replace",
                "categories": ["names", "emails", "phones", "addresses"],
                "preserve_audio_terms": true,
                "custom_patterns": [],
                "whitelist": ["professional"]
            ],
            context: testContext
        )

        XCTAssertTrue(result.success)

        if let data = result.data?.value as? [String: Any],
           let metadata = data["metadata"] as? [String: Any] {

            // Verify required metadata fields
            XCTAssertNotNil(metadata["redaction_mode"])
            XCTAssertNotNil(metadata["categories_processed"])
            XCTAssertNotNil(metadata["preserve_audio_terms"])
            XCTAssertNotNil(metadata["custom_patterns_count"])
            XCTAssertNotNil(metadata["whitelist_size"])
            XCTAssertNotNil(metadata["redaction_counts"])
            XCTAssertNotNil(metadata["total_instances_redacted"])
            XCTAssertNotNil(metadata["detected_pii_instances"])
            XCTAssertNotNil(metadata["original_length"])
            XCTAssertNotNil(metadata["redacted_length"])
            XCTAssertNotNil(metadata["processing_timestamp"])

            // Verify metadata values
            XCTAssertEqual(metadata["redaction_mode"] as? String, "replace")
            XCTAssertEqual(metadata["preserve_audio_terms"] as? Bool, true)
            XCTAssertEqual(metadata["custom_patterns_count"] as? Int, 0)
            XCTAssertEqual(metadata["whitelist_size"] as? Int, 1)

            // Verify redaction counts
            if let redactionCounts = metadata["redaction_counts"] as? [String: Any] {
                XCTAssertNotNil(redactionCounts["names"])
                XCTAssertNotNil(redactionCounts["emails"])
                XCTAssertNotNil(redactionCounts["phones"])
                XCTAssertNotNil(redactionCounts["addresses"])
            }

            // Verify detected PII instances
            if let detectedInstances = metadata["detected_pii_instances"] as? [[String: Any]] {
                XCTAssertGreaterThan(detectedInstances.count, 0)
                for instance in detectedInstances {
                    XCTAssertNotNil(instance["category"])
                    XCTAssertNotNil(instance["matched_text"])
                    XCTAssertNotNil(instance["position"])
                    XCTAssertNotNil(instance["replacement"])
                }
            }
        }
    }

    func testRedactionCountAccuracy() throws {
        let textWithMultiplePII = """
        Contacts:
        - John Smith (john.smith@email.com, 555-123-4567)
        - Jane Doe (jane.doe@studio.net, 555-987-6543)
        - Bob Johnson (bob.johnson@music.com, 555-555-0123)
        """

        let result = try await tool.execute(
            parameters: [
                "text": textWithMultiplePII,
                "mode": "replace",
                "categories": ["names", "emails", "phones"]
            ],
            context: testContext
        )

        XCTAssertTrue(result.success)

        if let data = result.data?.value as? [String: Any],
           let metadata = data["metadata"] as? [String: Any],
           let redactionCounts = metadata["redaction_counts"] as? [String: Any],
           let totalRedacted = metadata["total_instances_redacted"] as? Int {

            XCTAssertEqual(redactionCounts["names"] as? Int, 3)
            XCTAssertEqual(redactionCounts["emails"] as? Int, 3)
            XCTAssertEqual(redactionCounts["phones"] as? Int, 3)
            XCTAssertEqual(totalRedacted, 9)
        }
    }

    // MARK: - Performance Tests

    func testPerformanceWithLargeText() throws {
        let largeTextWithPII = String(repeating: "Contact John Smith at john.smith@email.com or call 555-123-4567. ", count: 100)

        let startTime = Date()

        let result = try await tool.execute(
            parameters: [
                "text": largeTextWithPII,
                "mode": "replace",
                "categories": ["names", "emails", "phones"]
            ],
            context: testContext
        )

        let executionTime = Date().timeIntervalSince(startTime)

        XCTAssertTrue(result.success)
        XCTAssertLessThan(executionTime, 1.0, "Should complete within 1 second for large text")
    }

    func testConcurrentExecution() throws {
        let textWithPII = """
        Session with John Smith. Contact: john.smith@email.com.
        Phone: 555-123-4567. Used audio equipment.
        """

        let expectations = (1...5).map { i in
            XCTestExpectation(description: "Concurrent execution \(i)")
        }

        for (index, expectation) in expectations.enumerated() {
            Task {
                do {
                    let result = try await tool.execute(
                        parameters: [
                            "text": textWithPII,
                            "mode": "replace",
                            "categories": ["names", "emails", "phones"]
                        ],
                        context: testContext
                    )
                    XCTAssertTrue(result.success, "Concurrent execution \(index) should succeed")
                } catch {
                    XCTFail("Concurrent execution \(index) failed: \(error)")
                }
                expectation.fulfill()
            }
        }

        wait(for: expectations, timeout: 2.0)
    }

    // MARK: - Security Tests

    func testInputSanitization() throws {
        let maliciousText = """
        Contact: John Smith <script>alert('xss')</script>
        Email: john.smith@email.com
        DROP TABLE users;
        Phone: 555-123-4567
        ```rm -rf /```
        Audio session details here.
        """

        let result = try await tool.execute(
            parameters: [
                "text": maliciousText,
                "mode": "replace",
                "categories": ["names", "emails", "phones"]
            ],
            context: testContext
        )

        // Should either succeed with sanitized output or fail gracefully
        if result.success {
            if let data = result.data?.value as? [String: Any],
               let redactedText = data["redacted_text"] as? String {
                // Verify PII is redacted
                XCTAssertFalse(redactedText.contains("John Smith"))
                XCTAssertFalse(redactedText.contains("john.smith@email.com"))
                XCTAssertFalse(redactedText.contains("555-123-4567"))

                // Should preserve audio content
                XCTAssertTrue(redactedText.contains("Audio session"))
            }
        }
    }

    func testOutputSanitization() throws {
        let textWithPII = "Contact John Smith at john.smith@email.com. Audio session recorded."

        let result = try await tool.execute(
            parameters: [
                "text": textWithPII,
                "mode": "replace",
                "categories": ["names", "emails"]
            ],
            context: testContext
        )

        XCTAssertTrue(result.success)

        if let data = result.data?.value as? [String: Any],
           let redactedText = data["redacted_text"] as? String {
            // Verify output doesn't contain potentially dangerous patterns
            XCTAssertFalse(redactedText.contains("<script>"))
            XCTAssertFalse(redactedText.contains("javascript:"))
            XCTAssertFalse(redactedText.contains("data:"))
        }
    }

    // MARK: - Edge Cases

    func testEmptyCategoriesArray() throws {
        let textWithPII = "Contact John Smith at john.smith@email.com."

        let result = try await tool.execute(
            parameters: [
                "text": textWithPII,
                "mode": "replace",
                "categories": []
            ],
            context: testContext
        )

        XCTAssertTrue(result.success)

        if let data = result.data?.value as? [String: Any],
           let redactedText = data["redacted_text"] as? String {
            // Should not redact anything when no categories are specified
            XCTAssertEqual(redactedText, textWithPII)
        }
    }

    func testTextWithoutPII() throws {
        let cleanAudioText = """
        Recording session at professional studio.
        Used Neumann U87 microphone with SSL console.
        Applied EQ and compression techniques.
        Mixed in Pro Tools DAW.
        """

        let result = try await tool.execute(
            parameters: [
                "text": cleanAudioText,
                "mode": "replace",
                "categories": ["names", "emails", "phones", "addresses"]
            ],
            context: testContext
        )

        XCTAssertTrue(result.success)

        if let data = result.data?.value as? [String: Any],
           let redactedText = data["redacted_text"] as? String,
           let metadata = data["metadata"] as? [String: Any],
           let totalRedacted = metadata["total_instances_redacted"] as? Int {
            XCTAssertEqual(redactedText, cleanAudioText) // Should remain unchanged
            XCTAssertEqual(totalRedacted, 0) // No PII should be detected
        }
    }

    func testMinimumTextLength() throws {
        let shortText = "John Smith."  // Below minimum length

        do {
            _ = try await tool.execute(
                parameters: [
                    "text": shortText,
                    "mode": "replace",
                    "categories": ["names"]
                ],
                context: testContext
            )
            XCTFail("Should fail with text below minimum length")
        } catch {
            // Expected behavior
        }
    }

    func testInvalidRedactionMode() throws {
        let textWithPII = "Contact John Smith at john.smith@email.com."

        do {
            _ = try await tool.execute(
                parameters: [
                    "text": textWithPII,
                    "mode": "invalid_mode",
                    "categories": ["names"]
                ],
                context: testContext
            )
            XCTFail("Should fail with invalid redaction mode")
        } catch {
            // Expected behavior
        }
    }

    func testInvalidPIICategory() throws {
        let textWithPII = "Contact John Smith."

        do {
            _ = try await tool.execute(
                parameters: [
                    "text": textWithPII,
                    "mode": "replace",
                    "categories": ["invalid_category"]
                ],
                context: testContext
            )
            XCTFail("Should fail with invalid PII category")
        } catch {
            // Expected behavior
        }
    }

    func testCustomPatternValidation() throws {
        let text = "Test text with PROJ-123 code."

        let invalidCustomPatterns = [
            [
                "name": "Test Pattern"
                // Missing required "pattern" field
            ]
        ]

        // Should handle invalid custom patterns gracefully
        let result = try await tool.execute(
            parameters: [
                "text": text,
                "mode": "replace",
                "categories": [],
                "custom_patterns": invalidCustomPatterns
            ],
            context: testContext
        )

        // Should succeed but not apply the invalid pattern
        XCTAssertTrue(result.success)
    }
}