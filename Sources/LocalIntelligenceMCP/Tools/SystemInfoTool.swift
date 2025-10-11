//
//  SystemInfoTool.swift
//  LocalIntelligenceMCP
//
//  Created on 2025-10-07.
//

import Foundation

/// Tool for retrieving system information
class SystemInfoTool: BaseMCPTool, @unchecked Sendable {

    init(logger: Logger, securityManager: SecurityManager) {
        let inputSchema: [String: Any] = [
            "type": "object",
            "properties": [
                "categories": [
                    "type": "array",
                    "items": [
                        "type": "string",
                        "enum": ["device", "os", "hardware", "network", "permissions", "server"]
                    ],
                    "description": "Information categories to retrieve"
                ],
                "includeSensitive": [
                    "type": "boolean",
                    "description": "Include potentially sensitive information (requires elevated permissions)",
                    "default": false
                ]
            ],
            "required": ["categories"],
            "description": "Retrieve system and server information"
        ]

        super.init(
            name: MCPConstants.Tools.systemInfo,
            description: "Retrieve system and server information including device details, OS info, hardware specs, network status, permissions, and server capabilities",
            inputSchema: inputSchema,
            category: .systemInfo,
            requiresPermission: [.systemInfo],
            offlineCapable: true,
            logger: logger,
            securityManager: securityManager
        )
    }

    override func performExecution(parameters: [String: AnyCodable], context: MCPExecutionContext) async throws -> MCPResponse {
        guard let categories = parameters["categories"]?.value as? [String] else {
            throw ToolsRegistryError.invalidParameters("categories parameter is required and must be an array")
        }

        let includeSensitive = parameters["includeSensitive"]?.value as? Bool ?? false
        let startTime = Date()
        let executionId = generateExecutionID()

        var result: [String: Any] = [:]
        var errors: [String] = []

        await logger.info("Retrieving system information", category: .systemInfo, metadata: [
            "categories": categories.joined(separator: ","),
            "includeSensitive": includeSensitive,
            "executionId": executionId,
            "clientId": context.clientId.uuidString
        ])

        // Process each category with error handling
        for category in categories {
            do {
                switch category {
                case "device":
                    result["deviceInfo"] = try await getDeviceInfo(includeSensitive: includeSensitive, context: context)
                case "os":
                    result["osInfo"] = try await getOSInfo()
                case "hardware":
                    result["hardwareInfo"] = try await getHardwareInfo()
                case "network":
                    result["networkInfo"] = try await getNetworkInfo(includeSensitive: includeSensitive)
                case "permissions":
                    result["permissions"] = try await getPermissionInfo(context: context)
                case "server":
                    result["serverInfo"] = try await getServerInfo()
                default:
                    errors.append("Unknown category: \(category)")
                }
            } catch {
                // Check if this is a permission error
                if case ToolsRegistryError.permissionDenied(let message) = error {
                    throw error // Re-throw permission errors immediately
                } else {
                    errors.append("Failed to retrieve \(category) info: \(error.localizedDescription)")
                }
            }
        }

        // Add metadata
        result["timestamp"] = Date().iso8601String
        result["executionId"] = executionId
        result["requestedCategories"] = categories
        result["successfulCategories"] = Array(result.keys.filter { $0.hasSuffix("Info") })

        if !errors.isEmpty {
            result["errors"] = errors
        }

        let executionTime = Date().timeIntervalSince(startTime)

        await logger.performance(
            "system_info_retrieval",
            duration: executionTime,
            metadata: [
                "categories": categories.count,
                "successfulCategories": result["successfulCategories"] as? [String] ?? [],
                "includeSensitive": includeSensitive,
                "executionId": executionId
            ]
        )

        return MCPResponse(
            success: errors.isEmpty,
            data: AnyCodable(result),
            executionTime: executionTime
        )
    }

    private func getDeviceInfo(includeSensitive: Bool, context: MCPExecutionContext) async throws -> [String: Any] {
        let processInfo = ProcessInfo.processInfo

        // Check for sensitive info permissions
        if includeSensitive {
            let hasPermission = try await securityManager.checkPermission(.systemInfo, context: context)
            if !hasPermission {
                throw ToolsRegistryError.permissionDenied("Access to sensitive device information requires elevated permissions")
            }
        }

        var deviceInfo: [String: Any] = [
            "deviceType": "Mac", // Could be enhanced to detect Mac/iPhone/iPad
            "name": processInfo.hostName,
            "platform": "macOS",
            "architecture": getSystemArchitecture(),
            "processorCount": processInfo.processorCount,
            "activeProcessorCount": processInfo.activeProcessorCount,
            "physicalMemory": processInfo.physicalMemory,
            "systemUptime": processInfo.systemUptime,
            "capabilities": getDeviceCapabilities()
        ]

        // Add sensitive information only if permitted
        if includeSensitive {
            deviceInfo["userName"] = NSUserName()
            deviceInfo["fullUserName"] = NSFullUserName()
            deviceInfo["hostName"] = processInfo.hostName
        }

        return deviceInfo
    }

    private func getSystemArchitecture() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineCode = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                ptr in String(validatingCString: ptr)
            }
        }
        return machineCode ?? "unknown"
    }

    private func getDeviceCapabilities() -> [String: Any] {
        return [
            "supportsVoiceControl": true,
            "supportsShortcuts": true,
            "supportsSystemInfo": true,
            "supportsNetworkAccess": true,
            "supportsAccessibility": true,
            "hardwareAccelerated": true,
            "supportsSecureEnclave": true, // Could be dynamically detected
            "supportsTouchID": true, // Could be dynamically detected
            "supportsApplePay": true, // Could be dynamically detected
            "supportsAirDrop": true // Could be dynamically detected
        ]
    }

    private func getOSInfo() async throws -> [String: Any] {
        let processInfo = ProcessInfo.processInfo
        let operatingSystemVersion = processInfo.operatingSystemVersion
        let versionString = "\(operatingSystemVersion.majorVersion).\(operatingSystemVersion.minorVersion).\(operatingSystemVersion.patchVersion)"

        return [
            "name": "macOS",
            "version": versionString,
            "majorVersion": operatingSystemVersion.majorVersion,
            "minorVersion": operatingSystemVersion.minorVersion,
            "patchVersion": operatingSystemVersion.patchVersion,
            "build": ProcessInfo.processInfo.operatingSystemVersionString,
            "systemUptime": processInfo.systemUptime,
            "formattedUptime": formatUptime(processInfo.systemUptime),
            "environment": getEnvironmentInfo(),
            "supportedFeatures": getOSSupportedFeatures()
        ]
    }

    private func formatUptime(_ uptime: TimeInterval) -> String {
        let days = Int(uptime) / 86400
        let hours = Int(uptime) % 86400 / 3600
        let minutes = Int(uptime) % 3600 / 60

        if days > 0 {
            return "\(days)d \(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    private func getEnvironmentInfo() -> [String: Any] {
        return [
            "isSimulator": false, // Could be detected
            "isDebugMode": false, // Could be detected from build config
            "isJailbroken": false, // iOS only, always false on macOS
            "isLowPowerMode": false, // Could be detected from system settings
            "thermalState": "nominal" // Could be detected from system APIs
        ]
    }

    private func getOSSupportedFeatures() -> [String] {
        return [
            "shortcuts",
            "voiceControl",
            "siri",
            "airDrop",
            "handoff",
            "universalClipboard",
            "applePay",
            "touchID",
            "faceID", // Not available on macOS but included for completeness
            "findMy",
            "keychain",
            "networkExtension"
        ]
    }

    private func getHardwareInfo() async throws -> [String: Any] {
        let processInfo = ProcessInfo.processInfo

        return [
            "cpu": [
                "type": getCPUType(),
                "architecture": getSystemArchitecture(),
                "coreCount": processInfo.processorCount,
                "activeCores": processInfo.activeProcessorCount,
                "frequency": nil // Could be detected with system APIs
            ],
            "memory": [
                "total": processInfo.physicalMemory,
                "available": processInfo.physicalMemory, // Could be calculated with system APIs
                "formatted": formatBytes(processInfo.physicalMemory)
            ],
            "storage": try await getDetailedDiskSpace(),
            "graphics": [
                "gpu": nil, // Could be detected with system APIs
                "supportsMetal": true,
                "supportsOpenGL": true,
                "supportsOpenCL": true
            ],
            "sensors": [
                "hasTouchID": true, // Could be dynamically detected
                "hasFaceID": false, // Not available on macOS
                "hasFingerprintSensor": true,
                "hasTemperatureSensor": true,
                "hasAmbientLightSensor": true
            ]
        ]
    }

    private func getCPUType() -> String {
        let machine = getSystemArchitecture()

        // Map common Mac architectures to CPU types
        switch machine {
        case "arm64", "arm64e":
            return "Apple Silicon"
        case "x86_64":
            return "Intel"
        case "i386":
            return "Intel (32-bit)"
        default:
            return "Unknown"
        }
    }

    private func formatBytes(_ bytes: UInt64) -> String {
        let byteCountFormatter = ByteCountFormatter()
        byteCountFormatter.allowedUnits = [.useGB, .useMB]
        byteCountFormatter.countStyle = .file
        return byteCountFormatter.string(fromByteCount: Int64(bytes))
    }

    private func getDetailedDiskSpace() async throws -> [String: Any] {
        let fileManager = FileManager.default
        let attributes = try fileManager.attributesOfFileSystem(forPath: "/")

        guard let totalSize = attributes[.systemSize] as? UInt64,
              let freeSize = attributes[ .systemFreeSize] as? UInt64 else {
            return ["error": "Unable to retrieve disk space information"]
        }

        let usedSize = totalSize - freeSize
        let usagePercentage = Double(usedSize) / Double(totalSize) * 100

        return [
            "total": totalSize,
            "free": freeSize,
            "used": usedSize,
            "formatted": [
                "total": formatBytes(totalSize),
                "free": formatBytes(freeSize),
                "used": formatBytes(usedSize)
            ],
            "usagePercentage": round(usagePercentage * 100) / 100,
            "status": getDiskStatus(usagePercentage: usagePercentage)
        ]
    }

    private func getDiskStatus(usagePercentage: Double) -> String {
        switch usagePercentage {
        case 0..<80:
            return "healthy"
        case 80..<90:
            return "warning"
        case 90..<95:
            return "critical"
        default:
            return "full"
        }
    }

    private func getDiskSpace() async throws -> [String: Any] {
        let fileManager = FileManager.default
        let attributes = try fileManager.attributesOfFileSystem(forPath: "/")

        guard let totalSize = attributes[.systemSize] as? UInt64,
              let freeSize = attributes[ .systemFreeSize] as? UInt64 else {
            return [:]
        }

        return [
            "total": totalSize,
            "free": freeSize,
            "used": totalSize - freeSize,
            "availablePercentage": Double(freeSize) / Double(totalSize) * 100
        ]
    }

    private func getNetworkInfo(includeSensitive: Bool) async throws -> [String: Any] {
        // Get primary network interface
        var addresses: [String] = []
        var macAddresses: [String] = []

        // Get all network interfaces
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while ptr != nil {
                let interface = ptr!.pointee
                ptr = interface.ifa_next

                guard let addr = interface.ifa_addr else {
                    continue
                }

                let interfaceName = String(cString: interface.ifa_name)

                // Get IP addresses
                if addr.pointee.sa_family == AF_INET {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    let sockLen = socklen_t(MemoryLayout<sockaddr_in>.size)
                    if getnameinfo(addr, sockLen, &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST) == 0 {
                        let nullTerminated = hostname.prefix(while: { $0 != 0 })
                        let uint8Array = Array(nullTerminated).map { UInt8(bitPattern: $0) }
                        let address = String(decoding: uint8Array, as: UTF8.self)

                        // Skip loopback addresses
                        if !address.hasPrefix("127.") && !interfaceName.hasPrefix("lo") {
                            addresses.append("\(interfaceName): \(address)")
                        }
                    }
                }

                // Get MAC addresses (only if sensitive info is allowed) - simplified for safety
                #if !os(Linux)
                if includeSensitive && addr.pointee.sa_family == AF_LINK {
                    // For now, skip MAC address extraction to avoid complex pointer arithmetic
                    // In a production implementation, you would safely extract the MAC address here
                    continue
                }
                #endif
            }
            freeifaddrs(ifaddr)
        }

        var networkInfo: [String: Any] = [
            "interfaces": addresses,
            "isConnected": addresses.count > 0,
            "primaryInterface": addresses.first ?? "none"
        ]

        if includeSensitive {
            networkInfo["macAddresses"] = macAddresses
        }

        return networkInfo
    }

    private func getPermissionInfo(context: MCPExecutionContext) async throws -> [String: Any] {
        // Check actual permissions through security manager
        let accessibilityPermission = try await securityManager.checkPermission(.accessibility, context: context)
        let shortcutsPermission = try await securityManager.checkPermission(.shortcuts, context: context)
        let microphonePermission = try await securityManager.checkPermission(.microphone, context: context)
        let systemInfoPermission = try await securityManager.checkPermission(.systemInfo, context: context)
        let networkPermission = try await securityManager.checkPermission(.network, context: context)

        return [
            "permissions": [
                "accessibility": [
                    "status": accessibilityPermission ? "authorized" : "denied",
                    "description": "Accessibility and Voice Control permissions",
                    "canRequest": true,
                    "requiredFor": ["voiceControl", "screenReader", "switchControl"],
                    "lastChecked": Date().iso8601String
                ],
                "shortcuts": [
                    "status": shortcutsPermission ? "authorized" : "denied",
                    "description": "Shortcuts app access permissions",
                    "canRequest": true,
                    "requiredFor": ["executeShortcut", "listShortcuts"],
                    "lastChecked": Date().iso8601String
                ],
                "microphone": [
                    "status": microphonePermission ? "authorized" : "denied",
                    "description": "Microphone access for voice input",
                    "canRequest": true,
                    "requiredFor": ["voiceInput", "speechRecognition"],
                    "lastChecked": Date().iso8601String
                ],
                "systemInfo": [
                    "status": systemInfoPermission ? "authorized" : "denied",
                    "description": "System information access permissions",
                    "canRequest": false,
                    "requiredFor": ["systemInfo", "deviceInfo", "hardwareInfo"],
                    "lastChecked": Date().iso8601String
                ],
                "network": [
                    "status": networkPermission ? "authorized" : "denied",
                    "description": "Network access permissions",
                    "canRequest": false,
                    "requiredFor": ["networkInfo", "remoteAccess"],
                    "lastChecked": Date().iso8601String
                ],
                "keychain": [
                    "status": "authorized", // Keychain access is always available to the app
                    "description": "Secure storage access permissions",
                    "canRequest": false,
                    "requiredFor": ["secureStorage", "credentialManagement"],
                    "lastChecked": Date().iso8601String
                ]
            ],
            "summary": [
                "totalPermissions": 6,
                "authorizedCount": [accessibilityPermission, shortcutsPermission, microphonePermission, systemInfoPermission, networkPermission, true].filter { $0 }.count,
                "deniedCount": [accessibilityPermission, shortcutsPermission, microphonePermission, systemInfoPermission, networkPermission, true].filter { !$0 }.count,
                "canRequestCount": 3,
                "overallStatus": getOverallPermissionStatus(
                    permissions: [accessibilityPermission, shortcutsPermission, microphonePermission, systemInfoPermission, networkPermission]
                )
            ]
        ]
    }

    private func getOverallPermissionStatus(permissions: [Bool]) -> String {
        let authorizedCount = permissions.filter { $0 }.count
        let totalCount = permissions.count

        switch authorizedCount {
        case totalCount:
            return "fullyAuthorized"
        case totalCount/2...totalCount:
            return "partiallyAuthorized"
        case 1...totalCount/2:
            return "limitedAccess"
        default:
            return "minimalAccess"
        }
    }

    private func getServerInfo() async throws -> [String: Any] {
        let processInfo = ProcessInfo.processInfo
        let serverStartTime = Date() // In a real implementation, this would be stored when server starts
        let uptime = Date().timeIntervalSince(serverStartTime)

        // Get available tools
        let availableTools = [
            MCPConstants.Tools.systemInfo,
            MCPConstants.Tools.executeShortcut,
            MCPConstants.Tools.listShortcuts,
            MCPConstants.Tools.voiceCommand,
            MCPConstants.Tools.checkPermission
        ]

        let serverCapabilities = [
            "tools": availableTools,
            "transports": ["stdio", "websocket"],
            "authentication": ["token", "certificate"],
            "features": [
                "audit_logging",
                "permission_management",
                "session_management",
                "structured_logging"
            ]
        ]

        return [
            "server": [
                "name": MCPConstants.Server.name,
                "version": MCPConstants.Server.version,
                "protocolVersion": MCPConstants.ProtocolInfo.version,
                "startTime": serverStartTime.iso8601String,
                "uptime": uptime,
                "status": "running"
            ],
            "capabilities": serverCapabilities,
            "configuration": [
                "maxClients": MCPConstants.Server.maxConcurrentClients,
                "defaultTimeout": MCPConstants.Timeouts.default,
                "auditLogging": true,
                "securityEnabled": true
            ],
            "statistics": [
                "activeConnections": 0, // Would get from actual server state
                "totalRequests": 0,
                "uptime": uptime
            ]
        ]
    }
}