import XCTest
@testable import AppleMCPServer

/// Test suite for Apple MCP Server security components
final class SecurityTests: XCTestCase {

    private var securityManager: SecurityManager!

    override func setUp() {
        super.setUp()
        securityManager = SecurityManager()
    }

    override func tearDown() async throws {
        // Clean up any test credentials
        try await securityManager.removeCredentials(identifier: "test-credentials")
        securityManager = nil
        super.tearDown()
    }

    // MARK: - SecurityManager Tests

    func testSecurityManagerInitialization() throws {
        // Test: SecurityManager initializes with default configuration
        XCTAssertNotNil(securityManager)

        // Test default configuration values
        let defaultConfig = SecurityManagerConfiguration.default
        XCTAssertEqual(defaultConfig.sessionTimeout, 3600)
        XCTAssertEqual(defaultConfig.maxAuditEntries, 1000)
        XCTAssertTrue(defaultConfig.requireCredentialsEncryption)
        XCTAssertTrue(defaultConfig.auditLoggingEnabled)
    }

    func testSecurityManagerCredentialStorageAndRetrieval() async throws {
        // Test: Credentials can be stored and retrieved securely
        let testIdentifier = "test-credentials"
        let testCredentials = Credentials(
            identifier: testIdentifier,
            apiKey: "test-api-key-12345",
            secret: "test-secret-67890",
            isEncrypted: true,
            createdAt: Date(),
            expiresAt: Date().addingTimeInterval(3600)
        )

        // Store credentials
        try await securityManager.storeCredentials(identifier: testIdentifier, credentials: testCredentials)

        // Retrieve credentials
        let retrievedCredentials = try await securityManager.retrieveCredentials(identifier: testIdentifier)

        XCTAssertNotNil(retrievedCredentials)
        XCTAssertEqual(retrievedCredentials?.identifier, testIdentifier)
        XCTAssertEqual(retrievedCredentials?.apiKey, "test-api-key-12345")
        XCTAssertEqual(retrievedCredentials?.secret, "test-secret-67890")
        XCTAssertTrue(retrievedCredentials?.isEncrypted ?? false)
        XCTAssertTrue(retrievedCredentials?.isValid ?? false)
    }

    func testSecurityManagerCredentialDeletion() async throws {
        // Test: Stored credentials can be properly deleted
        let testIdentifier = "test-delete-credentials"
        let testCredentials = Credentials(
            identifier: testIdentifier,
            apiKey: "delete-test-key",
            secret: nil,
            isEncrypted: false,
            createdAt: Date(),
            expiresAt: nil
        )

        // Store credentials first
        try await securityManager.storeCredentials(identifier: testIdentifier, credentials: testCredentials)

        // Verify they exist
        let retrievedBefore = try await securityManager.retrieveCredentials(identifier: testIdentifier)
        XCTAssertNotNil(retrievedBefore)

        // Delete credentials
        try await securityManager.removeCredentials(identifier: testIdentifier)

        // Verify they're deleted
        let retrievedAfter = try await securityManager.retrieveCredentials(identifier: testIdentifier)
        XCTAssertNil(retrievedAfter)
    }

    func testSecurityManagerInvalidCredentialValidation() async {
        // Test: Invalid credentials are properly rejected
        let invalidCredentials = Credentials(
            identifier: "",  // Empty identifier should be invalid
            apiKey: "",     // Empty API key should be invalid
            secret: nil,
            isEncrypted: false,
            createdAt: Date(),
            expiresAt: nil
        )

        // Should throw an error when trying to store invalid credentials
        do {
            try await securityManager.storeCredentials(identifier: "invalid", credentials: invalidCredentials)
            XCTFail("Expected SecurityError.invalidCredentials to be thrown")
        } catch SecurityError.invalidCredentials(let message) {
            XCTAssertTrue(message.contains("empty"))
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testSecurityManagerSessionTokenGeneration() throws {
        // Test: Session tokens are generated and validated correctly
        let clientInfo = ClientInfo(
            id: UUID(),
            name: "Test Client",
            version: "1.0.0",
            capabilities: ["test-capability"]
        )

        let sessionToken = securityManager.generateSessionToken(for: clientInfo)

        XCTAssertNotNil(sessionToken)
        XCTAssertFalse(sessionToken.value.isEmpty)
        XCTAssertEqual(sessionToken.clientInfo.name, "Test Client")
        XCTAssertEqual(sessionToken.clientInfo.version, "1.0.0")
        XCTAssertFalse(sessionToken.isExpired)

        // Test validation
        let isValid = securityManager.validateSessionToken(sessionToken)
        XCTAssertTrue(isValid)
    }

    func testSecurityManagerSessionTokenExpiration() throws {
        // Test: Expired session tokens are properly rejected
        let clientInfo = ClientInfo(
            id: UUID(),
            name: "Test Client",
            version: "1.0.0",
            capabilities: []
        )

        // Create token with very short expiration
        let securityConfig = SecurityManagerConfiguration(sessionTimeout: 0.001) // 1ms
        let tempSecurityManager = SecurityManager(configuration: securityConfig)
        let sessionToken = tempSecurityManager.generateSessionToken(for: clientInfo)

        // Wait for token to expire
        Thread.sleep(forTimeInterval: 0.01)

        // Should now be expired
        let isValid = tempSecurityManager.validateSessionToken(sessionToken)
        XCTAssertFalse(isValid)
    }

    func testSecurityManagerAuditLogging() throws {
        // Test: Security events are properly logged
        let initialCount = securityManager.getAuditEntries().count

        // Generate a session token (which should log an event)
        let clientInfo = ClientInfo(id: UUID(), name: "Audit Test", version: "1.0.0", capabilities: [])
        _ = securityManager.generateSessionToken(for: clientInfo)

        // Check that audit log has increased
        let auditEntries = securityManager.getAuditEntries()
        XCTAssertGreaterThan(auditEntries.count, initialCount)

        // Find the session creation event
        let sessionEvents = auditEntries.filter { $0.event == .sessionCreated }
        XCTAssertGreaterThan(sessionEvents.count, 0)

        let sessionEvent = sessionEvents.last!
        XCTAssertEqual(sessionEvent.event.rawValue, "session_created")
        XCTAssertNotNil(sessionEvent.timestamp)
    }

    func testSecurityManagerPermissionChecking() async throws {
        // Test: Permission checking works as expected
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: "test-request",
            timestamp: Date(),
            metadata: [:]
        )

        // Test different permission types
        let permissions: [PermissionType] = [.accessibility, .shortcuts, .microphone, .systemInfo, .network]

        for permission in permissions {
            let hasPermission = try await securityManager.checkPermission(permission, context: context)
            XCTAssertTrue(hasPermission, "Permission \(permission.rawValue) should be granted in development")
        }
    }

    // MARK: - PermissionValidator Tests

    func testPermissionValidatorInitialization() throws {
        // Test: PermissionValidator initializes correctly
        let permissionValidator = PermissionValidator()
        XCTAssertNotNil(permissionValidator)
    }

    // MARK: - Security Configuration Tests

    func testSecurityConfigurationDefaults() {
        // Test: Default security configuration is valid
        let config = SecurityManagerConfiguration.default

        XCTAssertEqual(config.sessionTimeout, 3600)
        XCTAssertEqual(config.maxAuditEntries, 1000)
        XCTAssertTrue(config.requireCredentialsEncryption)
        XCTAssertTrue(config.auditLoggingEnabled)
        XCTAssertEqual(config.allowedClients, ["localhost", "127.0.0.1"])
    }
}