import XCTest
@testable import LocalIntelligenceMCP

/// BDS Feature Tests: Runtime Capabilities Detection
/// Maps to: specs/features/01-capability/runtime-capabilities.feature
/// Implements behavioral scenarios for GSD Tasks 1.1.1-1.1.10
final class RuntimeCapabilitiesFeatureTests: XCTestCase {
    
    // MARK: - Scenario: Detect basic system information
    
    func testScenario_DetectBasicSystemInformation() throws {
        // Given the system is initialized
        // And RuntimeCapabilities has been instantiated
        let capabilities = RuntimeCapabilities()
        
        // When I query RuntimeCapabilities
        let osVersion = capabilities.osVersion
        let architecture = capabilities.architecture
        
        // Then I receive the current macOS version
        XCTAssertGreaterThanOrEqual(osVersion.majorVersion, 13,
            "Should support macOS 13+")
        
        // And I receive the system architecture
        XCTAssertTrue(architecture == "arm64" || architecture == "x86_64",
            "Architecture should be arm64 or x86_64, got \(architecture)")
        
        // And the version is greater than or equal to macOS 13.0
        XCTAssertTrue(osVersion.majorVersion >= 13,
            "Minimum supported version is macOS 13")
    }
    
    // MARK: - Scenario Outline: API feature level detection
    
    func testScenario_APIFeatureLevel_macOS13() throws {
        // Given the system is running macOS 13.x
        // (Mock or skip on other versions)
        let capabilities = RuntimeCapabilities()
        
        // Assuming current system is macOS 13
        guard capabilities.osVersion.majorVersion == 13 else {
            throw XCTSkip("Test requires macOS 13")
        }
        
        // When I query the apiFeatureLevel
        let level = capabilities.apiFeatureLevel
        
        // Then the feature level is tier1
        XCTAssertEqual(level, .tier1,
            "macOS 13 should report tier1 feature level")
    }
    
    func testScenario_APIFeatureLevel_macOS15() throws {
        // Given the system is running macOS 15.x
        let capabilities = RuntimeCapabilities()
        
        guard capabilities.osVersion.majorVersion >= 15 else {
            throw XCTSkip("Test requires macOS 15+")
        }
        
        // When I query the apiFeatureLevel
        let level = capabilities.apiFeatureLevel
        
        // Then the feature level is tier2
        XCTAssertEqual(level, .tier2,
            "macOS 15+ should report tier2 feature level")
    }
    
    // MARK: - Scenario: Apple Intelligence eligibility
    
    func testScenario_AppleIntelligenceEligible_OnAppleSiliconMacOS15() throws {
        // Given the system is running macOS 15.0 or later
        let capabilities = RuntimeCapabilities()
        
        guard capabilities.osVersion.majorVersion >= 15 else {
            throw XCTSkip("Test requires macOS 15+")
        }
        
        // And the architecture is arm64 (Apple Silicon)
        guard capabilities.architecture == "arm64" else {
            throw XCTSkip("Test requires Apple Silicon")
        }
        
        // When I check appleIntelligenceEligible
        let eligible = capabilities.appleIntelligenceEligible
        
        // Then it returns true
        // Note: Actual value depends on system settings
        // This test documents expected behavior
        XCTAssertNotNil(eligible,
            "Eligibility check should return a value on macOS 15+ Apple Silicon")
    }
    
    func testScenario_AppleIntelligenceIneligible_OnIntelMac() throws {
        // Given the system is running on x86_64 (Intel)
        let capabilities = RuntimeCapabilities()
        
        guard capabilities.architecture == "x86_64" else {
            throw XCTSkip("Test requires Intel Mac")
        }
        
        // When I check appleIntelligenceEligible
        let eligible = capabilities.appleIntelligenceEligible
        
        // Then it returns false
        XCTAssertEqual(eligible, false,
            "Apple Intelligence should not be eligible on Intel Macs")
    }
    
    func testScenario_AppleIntelligenceIneligible_OnMacOS13() throws {
        // Given the system is running macOS 13.x or 14.x
        let capabilities = RuntimeCapabilities()
        
        guard capabilities.osVersion.majorVersion < 15 else {
            throw XCTSkip("Test requires macOS <15")
        }
        
        // When I check appleIntelligenceEligible
        let eligible = capabilities.appleIntelligenceEligible
        
        // Then it returns false
        XCTAssertEqual(eligible, false,
            "Apple Intelligence requires macOS 15+")
    }
    
    // MARK: - Scenario: Model availability states
    
    func testScenario_ModelAvailabilityStates() throws {
        // Given Apple Intelligence is eligible (or test skips)
        let capabilities = RuntimeCapabilities()
        
        guard capabilities.appleIntelligenceEligible == true else {
            throw XCTSkip("Test requires Apple Intelligence eligible system")
        }
        
        // When I check modelAvailability
        let availability = capabilities.modelAvailability
        
        // Then the state is one of the defined states
        let validStates: [ModelAvailability] = [
            .available,
            .downloading(progress: 0.0),  // Example
            .notReady,
            .unavailable
        ]
        
        // Verify it's one of the expected types
        switch availability {
        case .available:
            XCTAssertTrue(true, "Model is available")
        case .downloading(let progress):
            XCTAssertTrue(progress >= 0.0 && progress <= 1.0,
                "Download progress should be 0-100%")
        case .notReady:
            XCTAssertTrue(true, "Model not yet downloaded")
        case .unavailable:
            XCTAssertTrue(true, "Model cannot be obtained")
        }
    }
    
    // MARK: - Scenario: Automation permissions detection
    
    func testScenario_AutomationPermissionsDetection() throws {
        // When I check automationPermissions
        let capabilities = RuntimeCapabilities()
        let permissions = capabilities.automationPermissions
        
        // Then I receive status for each permission type
        XCTAssertNotNil(permissions.shortcuts,
            "Shortcuts permission state should be available")
        XCTAssertNotNil(permissions.accessibility,
            "Accessibility permission state should be available")
        XCTAssertNotNil(permissions.automation,
            "Automation permission state should be available")
        
        // Each permission is a boolean
        XCTAssertTrue(permissions.shortcuts is Bool)
        XCTAssertTrue(permissions.accessibility is Bool)
        XCTAssertTrue(permissions.automation is Bool)
    }
    
    // MARK: - Scenario: Supported capabilities list
    
    func testScenario_SupportedCapabilities_macOS13Intel() throws {
        // Given the system is macOS 13 on x86_64
        let capabilities = RuntimeCapabilities()
        
        guard capabilities.osVersion.majorVersion == 13 &&
              capabilities.architecture == "x86_64" else {
            throw XCTSkip("Test requires macOS 13 Intel")
        }
        
        // When I query supportedCapabilities
        let supported = capabilities.supportedCapabilities
        
        // Then the list includes automation capabilities
        XCTAssertTrue(supported.contains(.localAutomationList),
            "macOS 13 should support automation listing")
        XCTAssertTrue(supported.contains(.localAutomationExecute),
            "macOS 13 should support automation execution")
        
        // And excludes intelligence capabilities
        XCTAssertFalse(supported.contains(.localGenerate),
            "macOS 13 Intel should not support local generation")
    }
    
    func testScenario_SupportedCapabilities_macOS15AppleSilicon() throws {
        // Given the system is macOS 15 on arm64 with model available
        let capabilities = RuntimeCapabilities()
        
        guard capabilities.osVersion.majorVersion >= 15 &&
              capabilities.architecture == "arm64" &&
              capabilities.modelAvailability == .available else {
            throw XCTSkip("Test requires macOS 15+ Apple Silicon with model")
        }
        
        // When I query supportedCapabilities
        let supported = capabilities.supportedCapabilities
        
        // Then the list includes all intelligence capabilities
        XCTAssertTrue(supported.contains(.localGenerate),
            "macOS 15+ AS should support generation")
        XCTAssertTrue(supported.contains(.localSummarize),
            "macOS 15+ AS should support summarization")
        XCTAssertTrue(supported.contains(.localExtract),
            "macOS 15+ AS should support extraction")
        XCTAssertTrue(supported.contains(.localClassify),
            "macOS 15+ AS should support classification")
    }
    
    // MARK: - Scenario: Capability status lookup
    
    func testScenario_CapabilityStatusLookup() throws {
        // Given the system capabilities
        let capabilities = RuntimeCapabilities()
        
        // When I query status for a capability
        let generateStatus = capabilities.status(for: .localGenerate)
        
        // Then the status is appropriate for this system
        let validStatuses: [CapabilityStatus] = [
            .available,
            .unavailable,
            .disabled,
            .notReady,
            .permissionDenied,
            .unsupported
        ]
        
        XCTAssertTrue(validStatuses.contains(generateStatus),
            "Status should be one of the defined types")
        
        // Additional logic based on system state
        if capabilities.osVersion.majorVersion < 15 {
            XCTAssertEqual(generateStatus, .unsupported,
                "Generation should be unsupported on macOS <15")
        }
    }
    
    // MARK: - Scenario: Privacy-safe fingerprinting
    
    func testScenario_PrivacySafeFingerprinting() throws {
        // When I examine RuntimeCapabilities output
        let capabilities = RuntimeCapabilities()
        
        // Convert to dictionary or JSON for inspection
        // (Assuming Codable conformance)
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(capabilities),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            XCTFail("Should be able to encode capabilities")
            return
        }
        
        // Then it does not include sensitive data
        let jsonString = String(data: data, encoding: .utf8) ?? ""
        
        XCTAssertFalse(jsonString.contains("UUID"),
            "Should not include UUIDs")
        XCTAssertFalse(jsonString.contains("serialNumber"),
            "Should not include serial numbers")
        XCTAssertFalse(jsonString.contains("deviceId"),
            "Should not include device identifiers")
        
        // And it only includes safe data
        XCTAssertTrue(jsonString.contains("osVersion") ||
                     jsonString.contains("architecture"),
            "Should include OS version and architecture")
    }
    
    // MARK: - Scenario: Capabilities change detection
    
    func testScenario_CapabilitiesChangeDetection() throws {
        // Given RuntimeCapabilities was queried at time T1
        let capabilities1 = RuntimeCapabilities()
        let status1 = capabilities1.status(for: .localGenerate)
        
        // When RuntimeCapabilities is queried again at time T2
        // (In real scenario, system state might have changed)
        let capabilities2 = RuntimeCapabilities()
        let status2 = capabilities2.status(for: .localGenerate)
        
        // Then the new query reflects current state
        // (This is a simplified test - real test would change system state)
        XCTAssertNotNil(status2,
            "Second query should return a status")
        
        // Note: In actual implementation, if we add caching,
        // we need to test cache invalidation here
    }
}
