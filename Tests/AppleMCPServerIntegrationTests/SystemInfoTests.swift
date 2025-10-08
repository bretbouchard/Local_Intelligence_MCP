//
//  SystemInfoTests.swift
//  AppleMCPServerIntegrationTests
//
//  Created on 2025-10-07.
//

import XCTest
import Quick
import Nimble
@testable import AppleMCPServer

final class SystemInfoTests: QuickSpec {
    override func spec() {
        describe("SystemInfoTool") {
            var systemInfoTool: SystemInfoTool!
            var mockLogger: Logger!
            var mockSecurityManager: SecurityManager!

            beforeEach {
                mockLogger = MockLogger()
                mockSecurityManager = MockSecurityManager()
                systemInfoTool = SystemInfoTool(logger: mockLogger, securityManager: mockSecurityManager)
            }

            // MARK: - Acceptance Scenario 1: Basic Device Information

            describe("Basic Device Information Retrieval") {
                context("when requesting device information") {
                    it("should return accurate device information including OS version and device type") {
                        let parameters = ["categories": ["device"]]
                        let context = MCPExecutionContext(clientId: UUID(), requestId: UUID())

                        waitUntil(timeout: .seconds(10)) { done in
                            Task {
                                do {
                                    let response = try await systemInfoTool.performExecution(parameters: parameters, context: context)

                                    expect(response.success).to(beTrue())
                                    expect(response.data).toNot(beNil())

                                    let responseData = response.data!.value as! [String: Any]
                                    let deviceInfo = responseData["deviceInfo"] as! [String: Any]

                                    // Verify device structure
                                    expect(deviceInfo["deviceType"]).toNot(beNil())
                                    expect(deviceInfo["name"]).toNot(beNil())
                                    expect(deviceInfo["platform"]).to(equal("macOS"))
                                    expect(deviceInfo["architecture"]).toNot(beNil())
                                    expect(deviceInfo["processorCount"]).toNot(beNil())
                                    expect(deviceInfo["activeProcessorCount"]).toNot(beNil())
                                    expect(deviceInfo["physicalMemory"]).toNot(beNil())
                                    expect(deviceInfo["systemUptime"]).toNot(beNil())
                                    expect(deviceInfo["capabilities"]).toNot(beNil())

                                    // Verify metadata
                                    expect(responseData["timestamp"]).toNot(beNil())
                                    expect(responseData["executionId"]).toNot(beNil())
                                    expect(responseData["requestedCategories"]).to(equal(["device"]))
                                    expect(responseData["successfulCategories"]).to(contain("deviceInfo"))

                                    done()
                                } catch {
                                    fail("Unexpected error: \(error)")
                                    done()
                                }
                            }
                        }
                    }
                }

                context("when requesting OS information") {
                    it("should return accurate OS version and system details") {
                        let parameters = ["categories": ["os"]]
                        let context = MCPExecutionContext(clientId: UUID(), requestId: UUID())

                        waitUntil(timeout: .seconds(10)) { done in
                            Task {
                                do {
                                    let response = try await systemInfoTool.performExecution(parameters: parameters, context: context)

                                    expect(response.success).to(beTrue())
                                    expect(response.data).toNot(beNil())

                                    let responseData = response.data!.value as! [String: Any]
                                    let osInfo = responseData["osInfo"] as! [String: Any]

                                    // Verify OS structure
                                    expect(osInfo["name"]).to(equal("macOS"))
                                    expect(osInfo["version"]).toNot(beNil())
                                    expect(osInfo["majorVersion"]).toNot(beNil())
                                    expect(osInfo["minorVersion"]).toNot(beNil())
                                    expect(osInfo["patchVersion"]).toNot(beNil())
                                    expect(osInfo["build"]).toNot(beNil())
                                    expect(osInfo["systemUptime"]).toNot(beNil())
                                    expect(osInfo["formattedUptime"]).toNot(beNil())
                                    expect(osInfo["environment"]).toNot(beNil())
                                    expect(osInfo["supportedFeatures"]).toNot(beNil())

                                    // Verify supported features include expected items
                                    let supportedFeatures = osInfo["supportedFeatures"] as! [String]
                                    expect(supportedFeatures).to(contain("shortcuts"))
                                    expect(supportedFeatures).to(contain("voiceControl"))
                                    expect(supportedFeatures).to(contain("siri"))

                                    done()
                                } catch {
                                    fail("Unexpected error: \(error)")
                                    done()
                                }
                            }
                        }
                    }
                }

                context("when requesting hardware information") {
                    it("should return detailed hardware specifications") {
                        let parameters = ["categories": ["hardware"]]
                        let context = MCPExecutionContext(clientId: UUID(), requestId: UUID())

                        waitUntil(timeout: .seconds(10)) { done in
                            Task {
                                do {
                                    let response = try await systemInfoTool.performExecution(parameters: parameters, context: context)

                                    expect(response.success).to(beTrue())
                                    expect(response.data).toNot(beNil())

                                    let responseData = response.data!.value as! [String: Any]
                                    let hardwareInfo = responseData["hardwareInfo"] as! [String: Any]

                                    // Verify hardware structure
                                    expect(hardwareInfo["cpu"]).toNot(beNil())
                                    expect(hardwareInfo["memory"]).toNot(beNil())
                                    expect(hardwareInfo["storage"]).toNot(beNil())
                                    expect(hardwareInfo["graphics"]).toNot(beNil())
                                    expect(hardwareInfo["sensors"]).toNot(beNil())

                                    // Verify CPU details
                                    let cpu = hardwareInfo["cpu"] as! [String: Any]
                                    expect(cpu["type"]).toNot(beNil())
                                    expect(cpu["architecture"]).toNot(beNil())
                                    expect(cpu["coreCount"]).toNot(beNil())
                                    expect(cpu["activeCores"]).toNot(beNil())

                                    // Verify memory details
                                    let memory = hardwareInfo["memory"] as! [String: Any]
                                    expect(memory["total"]).toNot(beNil())
                                    expect(memory["formatted"]).toNot(beNil())

                                    // Verify storage details
                                    let storage = hardwareInfo["storage"] as! [String: Any]
                                    expect(storage["total"]).toNot(beNil())
                                    expect(storage["free"]).toNot(beNil())
                                    expect(storage["used"]).toNot(beNil())
                                    expect(storage["formatted"]).toNot(beNil())
                                    expect(storage["usagePercentage"]).toNot(beNil())
                                    expect(storage["status"]).toNot(beNil())

                                    done()
                                } catch {
                                    fail("Unexpected error: \(error)")
                                    done()
                                }
                            }
                        }
                    }
                }
            }

            // MARK: - Acceptance Scenario 2: Structured Data with Permissions

            describe("Structured Data with Permissions") {
                context("when permissions are granted for system information") {
                    beforeEach {
                        // Grant all permissions
                        let mockSM = mockSecurityManager as! MockSecurityManager
                        mockSM.grantPermission(.systemInfo)
                        mockSM.grantPermission(.accessibility)
                        mockSM.grantPermission(.shortcuts)
                        mockSM.grantPermission(.microphone)
                        mockSM.grantPermission(.network)
                    }

                    it("should return relevant data in structured format") {
                        let parameters = [
                            "categories": ["device", "os", "hardware", "permissions"],
                            "includeSensitive": false
                        ]
                        let context = MCPExecutionContext(clientId: UUID(), requestId: UUID())

                        waitUntil(timeout: .seconds(15)) { done in
                            Task {
                                do {
                                    let response = try await systemInfoTool.performExecution(parameters: parameters, context: context)

                                    expect(response.success).to(beTrue())
                                    expect(response.data).toNot(beNil())

                                    let responseData = response.data!.value as! [String: Any]

                                    // Verify all requested categories are present
                                    expect(responseData["deviceInfo"]).toNot(beNil())
                                    expect(responseData["osInfo"]).toNot(beNil())
                                    expect(responseData["hardwareInfo"]).toNot(beNil())
                                    expect(responseData["permissions"]).toNot(beNil())

                                    // Verify structured permission information
                                    let permissions = responseData["permissions"] as! [String: Any]
                                    expect(permissions["permissions"]).toNot(beNil())
                                    expect(permissions["summary"]).toNot(beNil())

                                    let permissionDetails = permissions["permissions"] as! [String: Any]
                                    expect(permissionDetails["accessibility"]).toNot(beNil())
                                    expect(permissionDetails["shortcuts"]).toNot(beNil())
                                    expect(permissionDetails["microphone"]).toNot(beNil())
                                    expect(permissionDetails["systemInfo"]).toNot(beNil())
                                    expect(permissionDetails["network"]).toNot(beNil())
                                    expect(permissionDetails["keychain"]).toNot(beNil())

                                    // Verify summary information
                                    let summary = permissions["summary"] as! [String: Any]
                                    expect(summary["totalPermissions"]).to(equal(6))
                                    expect(summary["authorizedCount"]).toNot(beNil())
                                    expect(summary["deniedCount"]).toNot(beNil())
                                    expect(summary["overallStatus"]).toNot(beNil())

                                    // Verify metadata
                                    expect(responseData["timestamp"]).toNot(beNil())
                                    expect(responseData["executionId"]).toNot(beNil())
                                    expect(responseData["requestedCategories"]).to(equal(["device", "os", "hardware", "permissions"]))
                                    expect(responseData["successfulCategories"]).to(contain("deviceInfo", "osInfo", "hardwareInfo", "permissions"))

                                    done()
                                } catch {
                                    fail("Unexpected error: \(error)")
                                    done()
                                }
                            }
                        }
                    }
                }

                context("when requesting network information with permissions") {
                    beforeEach {
                        let mockSM = mockSecurityManager as! MockSecurityManager
                        mockSM.grantPermission(.systemInfo)
                        mockSM.grantPermission(.network)
                    }

                    it("should return network interface information") {
                        let parameters = ["categories": ["network"]]
                        let context = MCPExecutionContext(clientId: UUID(), requestId: UUID())

                        waitUntil(timeout: .seconds(10)) { done in
                            Task {
                                do {
                                    let response = try await systemInfoTool.performExecution(parameters: parameters, context: context)

                                    expect(response.success).to(beTrue())
                                    expect(response.data).toNot(beNil())

                                    let responseData = response.data!.value as! [String: Any]
                                    let networkInfo = responseData["networkInfo"] as! [String: Any]

                                    // Verify network structure
                                    expect(networkInfo["interfaces"]).toNot(beNil())
                                    expect(networkInfo["isConnected"]).toNot(beNil())
                                    expect(networkInfo["primaryInterface"]).toNot(beNil())

                                    // Verify interfaces are provided
                                    let interfaces = networkInfo["interfaces"] as! [String]
                                    expect(interfaces.count).to(beGreaterThan(0))

                                    done()
                                } catch {
                                    fail("Unexpected error: \(error)")
                                    done()
                                }
                            }
                        }
                    }
                }
            }

            // MARK: - Acceptance Scenario 3: Permission Error Handling

            describe("Permission Error Handling") {
                context("when requesting sensitive information without permission") {
                    beforeEach {
                        // Deny system info permission
                        let mockSM = mockSecurityManager as! MockSecurityManager
                        mockSM.denyPermission(.systemInfo)
                    }

                    it("should return appropriate permission error messages") {
                        let parameters = [
                            "categories": ["device"],
                            "includeSensitive": true
                        ]
                        let context = MCPExecutionContext(clientId: UUID(), requestId: UUID())

                        waitUntil(timeout: .seconds(10)) { done in
                            Task {
                                do {
                                    let response = try await systemInfoTool.performExecution(parameters: parameters, context: context)

                                    expect(response.success).to(beFalse())
                                    expect(response.error).toNot(beNil())

                                    // Verify permission error structure
                                    expect(response.error?.type).to(equal("permissionDenied"))
                                    expect(response.error?.message).to(contain("Access to sensitive device information requires elevated permissions"))

                                    done()
                                } catch {
                                    // Expected behavior - should throw permission error
                                    expect((error as? ToolsRegistryError)?.type).to(equal("permissionDenied"))
                                    done()
                                }
                            }
                        }
                    }
                }

                context("when requesting sensitive network information without permission") {
                    beforeEach {
                        // Deny network permission
                        let mockSM = mockSecurityManager as! MockSecurityManager
                        mockSM.grantPermission(.systemInfo) // Allow basic system info
                        mockSM.denyPermission(.network)
                    }

                    it("should handle permission errors gracefully") {
                        let parameters = [
                            "categories": ["network"],
                            "includeSensitive": true
                        ]
                        let context = MCPExecutionContext(clientId: UUID(), requestId: UUID())

                        waitUntil(timeout: .seconds(10)) { done in
                            Task {
                                do {
                                    let response = try await systemInfoTool.performExecution(parameters: parameters, context: context)

                                    expect(response.success).to(beFalse())
                                    expect(response.error).toNot(beNil())

                                    done()
                                } catch {
                                    // Expected behavior - should throw permission error
                                    expect((error as? ToolsRegistryError)?.type).to(equal("permissionDenied"))
                                    done()
                                }
                            }
                        }
                    }
                }

                context("when some categories fail due to permissions") {
                    beforeEach {
                        // Grant some permissions but deny others
                        let mockSM = mockSecurityManager as! MockSecurityManager
                        mockSM.grantPermission(.systemInfo)
                        mockSM.denyPermission(.network)
                    }

                    it("should return partial results with error information") {
                        let parameters = ["categories": ["device", "network"]]
                        let context = MCPExecutionContext(clientId: UUID(), requestId: UUID())

                        waitUntil(timeout: .seconds(10)) { done in
                            Task {
                                do {
                                    let response = try await systemInfoTool.performExecution(parameters: parameters, context: context)

                                    // Network category should fail with permission error
                                    expect(response.success).to(beFalse())
                                    expect(response.error).toNot(beNil())

                                    done()
                                } catch {
                                    // Expected behavior - should throw permission error for network category
                                    expect((error as? ToolsRegistryError)?.type).to(equal("permissionDenied"))
                                    done()
                                }
                            }
                        }
                    }
                }
            }

            // MARK: - Additional Comprehensive Tests

            describe("Comprehensive System Information Tests") {
                context("when requesting all categories with proper permissions") {
                    beforeEach {
                        let mockSM = mockSecurityManager as! MockSecurityManager
                        mockSM.grantPermission(.systemInfo)
                        mockSM.grantPermission(.accessibility)
                        mockSM.grantPermission(.shortcuts)
                        mockSM.grantPermission(.microphone)
                        mockSM.grantPermission(.network)
                    }

                    it("should return complete system information") {
                        let parameters = ["categories": ["device", "os", "hardware", "network", "permissions", "server"]]
                        let context = MCPExecutionContext(clientId: UUID(), requestId: UUID())

                        waitUntil(timeout: .seconds(20)) { done in
                            Task {
                                do {
                                    let response = try await systemInfoTool.performExecution(parameters: parameters, context: context)

                                    expect(response.success).to(beTrue())
                                    expect(response.data).toNot(beNil())

                                    let responseData = response.data!.value as! [String: Any]

                                    // Verify all categories are present
                                    expect(responseData["deviceInfo"]).toNot(beNil())
                                    expect(responseData["osInfo"]).toNot(beNil())
                                    expect(responseData["hardwareInfo"]).toNot(beNil())
                                    expect(responseData["networkInfo"]).toNot(beNil())
                                    expect(responseData["permissions"]).toNot(beNil())
                                    expect(responseData["serverInfo"]).toNot(beNil())

                                    // Verify successful categories list
                                    let successfulCategories = responseData["successfulCategories"] as! [String]
                                    expect(successfulCategories.count).to(equal(6))

                                    // Verify no errors
                                    expect(responseData["errors"]).to(beNil())

                                    // Verify server information
                                    let serverInfo = responseData["serverInfo"] as! [String: Any]
                                    expect(serverInfo["server"]).toNot(beNil())
                                    expect(serverInfo["capabilities"]).toNot(beNil())
                                    expect(serverInfo["configuration"]).toNot(beNil())
                                    expect(serverInfo["statistics"]).toNot(beNil())

                                    done()
                                } catch {
                                    fail("Unexpected error: \(error)")
                                    done()
                                }
                            }
                        }
                    }
                }

                context("when requesting invalid categories") {
                    it("should handle unknown categories gracefully") {
                        let parameters = ["categories": ["invalidCategory", "device"]]
                        let context = MCPExecutionContext(clientId: UUID(), requestId: UUID())

                        waitUntil(timeout: .seconds(10)) { done in
                            Task {
                                do {
                                    let response = try await systemInfoTool.performExecution(parameters: parameters, context: context)

                                    expect(response.success).to(beFalse()) // Due to error in unknown category
                                    expect(response.data).toNot(beNil())

                                    let responseData = response.data!.value as! [String: Any]

                                    // Should have valid device info
                                    expect(responseData["deviceInfo"]).toNot(beNil())

                                    // Should have errors for unknown category
                                    let errors = responseData["errors"] as! [String]
                                    expect(errors.count).to(equal(1))
                                    expect(errors.first).to(contain("Unknown category: invalidCategory"))

                                    done()
                                } catch {
                                    fail("Unexpected error: \(error)")
                                    done()
                                }
                            }
                        }
                    }
                }

                context("when missing required parameters") {
                    it("should return validation error") {
                        let parameters: [String: Any] = [:] // Missing categories
                        let context = MCPExecutionContext(clientId: UUID(), requestId: UUID())

                        waitUntil(timeout: .seconds(5)) { done in
                            Task {
                                do {
                                    let response = try await systemInfoTool.performExecution(parameters: parameters, context: context)

                                    expect(response.success).to(beFalse())
                                    expect(response.error).toNot(beNil())
                                    expect(response.error?.type).to(equal("invalidParameters"))
                                    expect(response.error?.message).to(contain("categories parameter is required"))

                                    done()
                                } catch {
                                    fail("Unexpected error: \(error)")
                                    done()
                                }
                            }
                        }
                    }
                }

                context("when categories parameter is not an array") {
                    it("should return validation error") {
                        let parameters = ["categories": "device"] // String instead of array
                        let context = MCPExecutionContext(clientId: UUID(), requestId: UUID())

                        waitUntil(timeout: .seconds(5)) { done in
                            Task {
                                do {
                                    let response = try await systemInfoTool.performExecution(parameters: parameters, context: context)

                                    expect(response.success).to(beFalse())
                                    expect(response.error).toNot(beNil())
                                    expect(response.error?.type).to(equal("invalidParameters"))
                                    expect(response.error?.message).to(contain("categories parameter is required and must be an array"))

                                    done()
                                } catch {
                                    fail("Unexpected error: \(error)")
                                    done()
                                }
                            }
                        }
                    }
                }
            }

            // MARK: - Performance Tests

            describe("Performance Tests") {
                context("when requesting multiple categories") {
                    beforeEach {
                        let mockSM = mockSecurityManager as! MockSecurityManager
                        mockSM.grantPermission(.systemInfo)
                        mockSM.grantPermission(.network)
                    }

                    it("should complete within reasonable time") {
                        let parameters = ["categories": ["device", "os", "hardware", "network"]]
                        let context = MCPExecutionContext(clientId: UUID(), requestId: UUID())

                        waitUntil(timeout: .seconds(15)) { done in
                            Task {
                                do {
                                    let startTime = Date()
                                    let response = try await systemInfoTool.performExecution(parameters: parameters, context: context)
                                    let executionTime = Date().timeIntervalSince(startTime)

                                    expect(response.success).to(beTrue())
                                    expect(executionTime).to(beLessThan(10.0)) // Should complete within 10 seconds
                                    expect(response.executionTime).to(beLessThan(10.0))

                                    done()
                                } catch {
                                    fail("Unexpected error: \(error)")
                                    done()
                                }
                            }
                        }
                    }
                }
            }

            // MARK: - Security Tests

            describe("Security Tests") {
                context("when handling sensitive information") {
                    it("should properly check permissions before returning sensitive data") {
                        let parameters = [
                            "categories": ["device"],
                            "includeSensitive": true
                        ]
                        let context = MCPExecutionContext(clientId: UUID(), requestId: UUID())

                        // Initially deny permission
                        let mockSM = mockSecurityManager as! MockSecurityManager
                        mockSM.denyPermission(.systemInfo)

                        waitUntil(timeout: .seconds(10)) { done in
                            Task {
                                do {
                                    // Should fail with permission denied
                                    let response1 = try await systemInfoTool.performExecution(parameters: parameters, context: context)
                                    expect(response1.success).to(beFalse())

                                    // Now grant permission
                                    mockSM.grantPermission(.systemInfo)

                                    // Should succeed with sensitive information
                                    let response2 = try await systemInfoTool.performExecution(parameters: parameters, context: context)
                                    expect(response2.success).to(beTrue())

                                    let responseData = response2.data!.value as! [String: Any]
                                    let deviceInfo = responseData["deviceInfo"] as! [String: Any]

                                    // Should include sensitive information
                                    expect(deviceInfo["userName"]).toNot(beNil())
                                    expect(deviceInfo["fullUserName"]).toNot(beNil())
                                    expect(deviceInfo["hostName"]).toNot(beNil())

                                    done()
                                } catch {
                                    fail("Unexpected error: \(error)")
                                    done()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}