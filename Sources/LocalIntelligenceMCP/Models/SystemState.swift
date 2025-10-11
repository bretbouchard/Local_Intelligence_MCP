//
//  SystemState.swift
//  LocalIntelligenceMCP
//
//  Created on 2025-10-07.
//

import Foundation

/// Data model for System State information
/// Aligns with the data-model.md specification
struct SystemStateDataModel: Codable {
    let timestamp: Date
    let systemInfo: SystemInfo
    let performanceInfo: PerformanceInfo
    let networkInfo: NetworkInfo
    let storageInfo: StorageInfo
    let batteryInfo: BatteryInfo?
    let thermalState: ThermalState
    let accessibilityFeatures: AccessibilityFeatures

    init(
        timestamp: Date = Date(),
        systemInfo: SystemInfo = SystemInfo(),
        performanceInfo: PerformanceInfo = PerformanceInfo(),
        networkInfo: NetworkInfo = NetworkInfo(),
        storageInfo: StorageInfo = StorageInfo(),
        batteryInfo: BatteryInfo? = nil,
        thermalState: ThermalState = .nominal,
        accessibilityFeatures: AccessibilityFeatures = AccessibilityFeatures()
    ) {
        self.timestamp = timestamp
        self.systemInfo = systemInfo
        self.performanceInfo = performanceInfo
        self.networkInfo = networkInfo
        self.storageInfo = storageInfo
        self.batteryInfo = batteryInfo
        self.thermalState = thermalState
        self.accessibilityFeatures = accessibilityFeatures
    }

    /// Validate system state model
    func validate() -> ValidationResult {
        var errors: [ValidationError] = []

        // Validate system info
        let systemValidation = systemInfo.validate()
        errors.append(contentsOf: systemValidation.errors)

        // Validate performance info
        let performanceValidation = performanceInfo.validate()
        errors.append(contentsOf: performanceValidation.errors)

        // Validate network info
        let networkValidation = networkInfo.validate()
        errors.append(contentsOf: networkValidation.errors)

        // Validate storage info
        let storageValidation = storageInfo.validate()
        errors.append(contentsOf: storageValidation.errors)

        // Validate battery info if present
        if let batteryInfo = batteryInfo {
            let batteryValidation = batteryInfo.validate()
            errors.append(contentsOf: batteryValidation.errors)
        }

        return ValidationResult(errors: errors)
    }

    /// Export system state for MCP format
    func exportForMCP() -> [String: Any] {
        var result: [String: Any] = [
            "timestamp": timestamp.iso8601String,
            "systemInfo": systemInfo.export(),
            "performanceInfo": performanceInfo.export(),
            "networkInfo": networkInfo.export(),
            "storageInfo": storageInfo.export(),
            "thermalState": thermalState.rawValue,
            "accessibilityFeatures": accessibilityFeatures.export()
        ]

        if let batteryInfo = batteryInfo {
            result["batteryInfo"] = batteryInfo.export()
        }

        return result
    }
}

/// Basic system information
struct SystemInfo: Codable {
    let computerName: String
    let systemVersion: String
    let kernelVersion: String
    let hostname: String
    let architecture: String
    let processorType: String
    let processorCount: Int
    let physicalMemory: Int64
    let deviceModel: String
    let serialNumber: String? // Redacted in exports
    let uptime: TimeInterval

    init(
        computerName: String = ProcessInfo.processInfo.hostName,
        systemVersion: String = "", // Would be filled by system calls
        kernelVersion: String = "",
        hostname: String = ProcessInfo.processInfo.hostName,
        architecture: String = "", // Would be filled by system calls
        processorType: String = "",
        processorCount: Int = ProcessInfo.processInfo.processorCount,
        physicalMemory: Int64 = 0, // Would be filled by system calls
        deviceModel: String = "",
        serialNumber: String? = nil, // Redacted for privacy
        uptime: TimeInterval = ProcessInfo.processInfo.systemUptime
    ) {
        self.computerName = computerName
        self.systemVersion = systemVersion
        self.kernelVersion = kernelVersion
        self.hostname = hostname
        self.architecture = architecture
        self.processorType = processorType
        self.processorCount = processorCount
        self.physicalMemory = physicalMemory
        self.deviceModel = deviceModel
        self.serialNumber = serialNumber
        self.uptime = uptime
    }

    /// Validate system info
    func validate() -> ValidationResult {
        var errors: [ValidationError] = []

        if computerName.isEmpty {
            errors.append(ValidationError(
                code: "INVALID_COMPUTER_NAME",
                message: "Computer name cannot be empty",
                field: "computerName",
                value: computerName
            ))
        }

        if processorCount <= 0 {
            errors.append(ValidationError(
                code: "INVALID_PROCESSOR_COUNT",
                message: "Processor count must be greater than 0",
                field: "processorCount",
                value: processorCount
            ))
        }

        if physicalMemory <= 0 {
            errors.append(ValidationError(
                code: "INVALID_PHYSICAL_MEMORY",
                message: "Physical memory must be greater than 0",
                field: "physicalMemory",
                value: physicalMemory
            ))
        }

        if uptime < 0 {
            errors.append(ValidationError(
                code: "INVALID_UPTIME",
                message: "Uptime cannot be negative",
                field: "uptime",
                value: uptime
            ))
        }

        return ValidationResult(errors: errors)
    }

    /// Export system info (with sensitive data redacted)
    func export() -> [String: Any] {
        return [
            "computerName": computerName,
            "systemVersion": systemVersion,
            "kernelVersion": kernelVersion,
            "hostname": hostname,
            "architecture": architecture,
            "processorType": processorType,
            "processorCount": processorCount,
            "physicalMemory": physicalMemory,
            "deviceModel": deviceModel,
            "uptime": uptime
        ]
    }
}

/// Performance information
struct PerformanceInfo: Codable {
    let cpuUsage: Double // Percentage (0.0 - 1.0)
    let memoryUsage: MemoryUsage
    let diskUsage: DiskUsage
    let networkUsage: NetworkUsage
    let processCount: Int
    let threadCount: Int
    let loadAverage: [Double] // 1, 5, 15 minute averages

    init(
        cpuUsage: Double = 0.0,
        memoryUsage: MemoryUsage = MemoryUsage(),
        diskUsage: DiskUsage = DiskUsage(),
        networkUsage: NetworkUsage = NetworkUsage(),
        processCount: Int = 0,
        threadCount: Int = 0,
        loadAverage: [Double] = [0.0, 0.0, 0.0]
    ) {
        self.cpuUsage = cpuUsage
        self.memoryUsage = memoryUsage
        self.diskUsage = diskUsage
        self.networkUsage = networkUsage
        self.processCount = processCount
        self.threadCount = threadCount
        self.loadAverage = loadAverage
    }

    /// Validate performance info
    func validate() -> ValidationResult {
        var errors: [ValidationError] = []

        if cpuUsage < 0.0 || cpuUsage > 1.0 {
            errors.append(ValidationError(
                code: "INVALID_CPU_USAGE",
                message: "CPU usage must be between 0.0 and 1.0",
                field: "cpuUsage",
                value: cpuUsage
            ))
        }

        if processCount < 0 {
            errors.append(ValidationError(
                code: "INVALID_PROCESS_COUNT",
                message: "Process count cannot be negative",
                field: "processCount",
                value: processCount
            ))
        }

        if threadCount < 0 {
            errors.append(ValidationError(
                code: "INVALID_THREAD_COUNT",
                message: "Thread count cannot be negative",
                field: "threadCount",
                value: threadCount
            ))
        }

        if loadAverage.count != 3 {
            errors.append(ValidationError(
                code: "INVALID_LOAD_AVERAGE",
                message: "Load average must contain exactly 3 values (1, 5, 15 minutes)",
                field: "loadAverage",
                value: loadAverage
            ))
        }

        return ValidationResult(errors: errors)
    }

    /// Export performance info
    func export() -> [String: Any] {
        return [
            "cpuUsage": cpuUsage,
            "memoryUsage": memoryUsage.export(),
            "diskUsage": diskUsage.export(),
            "networkUsage": networkUsage.export(),
            "processCount": processCount,
            "threadCount": threadCount,
            "loadAverage": loadAverage
        ]
    }
}

/// Memory usage information
struct MemoryUsage: Codable {
    let total: Int64
    let used: Int64
    let free: Int64
    let active: Int64
    let inactive: Int64
    let wired: Int64
    let compressed: Int64

    init(
        total: Int64 = 0,
        used: Int64 = 0,
        free: Int64 = 0,
        active: Int64 = 0,
        inactive: Int64 = 0,
        wired: Int64 = 0,
        compressed: Int64 = 0
    ) {
        self.total = total
        self.used = used
        self.free = free
        self.active = active
        self.inactive = inactive
        self.wired = wired
        self.compressed = compressed
    }

    /// Calculate memory usage percentage
    var usagePercentage: Double {
        guard total > 0 else { return 0.0 }
        return Double(used) / Double(total)
    }

    /// Export memory usage
    func export() -> [String: Any] {
        return [
            "total": total,
            "used": used,
            "free": free,
            "active": active,
            "inactive": inactive,
            "wired": wired,
            "compressed": compressed,
            "usagePercentage": usagePercentage
        ]
    }
}

/// Disk usage information
struct DiskUsage: Codable {
    let total: Int64
    let used: Int64
    let free: Int64
    let readBytes: Int64
    let writeBytes: Int64
    let readOperations: Int64
    let writeOperations: Int64

    init(
        total: Int64 = 0,
        used: Int64 = 0,
        free: Int64 = 0,
        readBytes: Int64 = 0,
        writeBytes: Int64 = 0,
        readOperations: Int64 = 0,
        writeOperations: Int64 = 0
    ) {
        self.total = total
        self.used = used
        self.free = free
        self.readBytes = readBytes
        self.writeBytes = writeBytes
        self.readOperations = readOperations
        self.writeOperations = writeOperations
    }

    /// Calculate disk usage percentage
    var usagePercentage: Double {
        guard total > 0 else { return 0.0 }
        return Double(used) / Double(total)
    }

    /// Export disk usage
    func export() -> [String: Any] {
        return [
            "total": total,
            "used": used,
            "free": free,
            "readBytes": readBytes,
            "writeBytes": writeBytes,
            "readOperations": readOperations,
            "writeOperations": writeOperations,
            "usagePercentage": usagePercentage
        ]
    }
}

/// Network usage information
struct NetworkUsage: Codable {
    let bytesReceived: Int64
    let bytesSent: Int64
    let packetsReceived: Int64
    let packetsSent: Int64
    let errorsIn: Int64
    let errorsOut: Int64

    init(
        bytesReceived: Int64 = 0,
        bytesSent: Int64 = 0,
        packetsReceived: Int64 = 0,
        packetsSent: Int64 = 0,
        errorsIn: Int64 = 0,
        errorsOut: Int64 = 0
    ) {
        self.bytesReceived = bytesReceived
        self.bytesSent = bytesSent
        self.packetsReceived = packetsReceived
        self.packetsSent = packetsSent
        self.errorsIn = errorsIn
        self.errorsOut = errorsOut
    }

    /// Export network usage
    func export() -> [String: Any] {
        return [
            "bytesReceived": bytesReceived,
            "bytesSent": bytesSent,
            "packetsReceived": packetsReceived,
            "packetsSent": packetsSent,
            "errorsIn": errorsIn,
            "errorsOut": errorsOut
        ]
    }
}

/// Network information
struct NetworkInfo: Codable {
    let primaryInterface: String?
    let interfaces: [NetworkInterface]
    let isOnline: Bool
    let connectionType: ConnectionType

    init(
        primaryInterface: String? = nil,
        interfaces: [NetworkInterface] = [],
        isOnline: Bool = false,
        connectionType: ConnectionType = .unknown
    ) {
        self.primaryInterface = primaryInterface
        self.interfaces = interfaces
        self.isOnline = isOnline
        self.connectionType = connectionType
    }

    /// Validate network info
    func validate() -> ValidationResult {
        // Basic validation for network info
        return ValidationResult(errors: [])
    }

    /// Export network info
    func export() -> [String: Any] {
        return [
            "primaryInterface": primaryInterface as Any,
            "interfaces": interfaces.map { $0.export() },
            "isOnline": isOnline,
            "connectionType": connectionType.rawValue
        ]
    }
}

/// Network interface information
struct NetworkInterface: Codable, Identifiable {
    let id: UUID
    let name: String
    let displayName: String
    let isActive: Bool
    let isUp: Bool
    let macAddress: String? // Redacted in exports
    let ipAddress: [String]
    let connectionType: ConnectionType

    init(
        id: UUID = UUID(),
        name: String,
        displayName: String,
        isActive: Bool = false,
        isUp: Bool = false,
        macAddress: String? = nil,
        ipAddress: [String] = [],
        connectionType: ConnectionType = .unknown
    ) {
        self.id = id
        self.name = name
        self.displayName = displayName
        self.isActive = isActive
        self.isUp = isUp
        self.macAddress = macAddress
        self.ipAddress = ipAddress
        self.connectionType = connectionType
    }

    /// Export network interface (with MAC address redacted)
    func export() -> [String: Any] {
        return [
            "name": name,
            "displayName": displayName,
            "isActive": isActive,
            "isUp": isUp,
            "ipAddress": ipAddress,
            "connectionType": connectionType.rawValue
        ]
    }
}

/// Connection type enumeration
enum ConnectionType: String, Codable, CaseIterable {
    case unknown = "unknown"
    case ethernet = "ethernet"
    case wifi = "wifi"
    case cellular = "cellular"
    case bluetooth = "bluetooth"
    case vpn = "vpn"
    case loopback = "loopback"

    var displayName: String {
        switch self {
        case .unknown:
            return "Unknown"
        case .ethernet:
            return "Ethernet"
        case .wifi:
            return "Wi-Fi"
        case .cellular:
            return "Cellular"
        case .bluetooth:
            return "Bluetooth"
        case .vpn:
            return "VPN"
        case .loopback:
            return "Loopback"
        }
    }
}

/// Storage information
struct StorageInfo: Codable {
    let volumes: [StorageVolume]

    init(volumes: [StorageVolume] = []) {
        self.volumes = volumes
    }

    /// Validate storage info
    func validate() -> ValidationResult {
        var errors: [ValidationError] = []

        for (index, volume) in volumes.enumerated() {
            let volumeValidation = volume.validate()
            errors.append(contentsOf: volumeValidation.errors.map { error in
                ValidationError(
                    code: error.code,
                    message: "Volume '\(volume.name)': \(error.message)",
                    field: "volumes[\(index)]",
                    value: error.value
                )
            })
        }

        return ValidationResult(errors: errors)
    }

    /// Export storage info
    func export() -> [String: Any] {
        return [
            "volumes": volumes.map { $0.export() }
        ]
    }
}

/// Storage volume information
struct StorageVolume: Codable, Identifiable {
    let id: UUID
    let name: String
    let fileSystem: String
    let mountPoint: String
    let totalCapacity: Int64
    let availableCapacity: Int64
    let usedCapacity: Int64
    let isEncrypted: Bool
    let isRemovable: Bool
    let isInternal: Bool

    init(
        id: UUID = UUID(),
        name: String,
        fileSystem: String,
        mountPoint: String,
        totalCapacity: Int64,
        availableCapacity: Int64,
        usedCapacity: Int64,
        isEncrypted: Bool = false,
        isRemovable: Bool = false,
        isInternal: Bool = true
    ) {
        self.id = id
        self.name = name
        self.fileSystem = fileSystem
        self.mountPoint = mountPoint
        self.totalCapacity = totalCapacity
        self.availableCapacity = availableCapacity
        self.usedCapacity = usedCapacity
        self.isEncrypted = isEncrypted
        self.isRemovable = isRemovable
        self.isInternal = isInternal
    }

    /// Calculate usage percentage
    var usagePercentage: Double {
        guard totalCapacity > 0 else { return 0.0 }
        return Double(usedCapacity) / Double(totalCapacity)
    }

    /// Validate storage volume
    func validate() -> ValidationResult {
        var errors: [ValidationError] = []

        if name.isEmpty {
            errors.append(ValidationError(
                code: "INVALID_VOLUME_NAME",
                message: "Volume name cannot be empty",
                field: "name",
                value: name
            ))
        }

        if totalCapacity <= 0 {
            errors.append(ValidationError(
                code: "INVALID_TOTAL_CAPACITY",
                message: "Total capacity must be greater than 0",
                field: "totalCapacity",
                value: totalCapacity
            ))
        }

        if availableCapacity < 0 {
            errors.append(ValidationError(
                code: "INVALID_AVAILABLE_CAPACITY",
                message: "Available capacity cannot be negative",
                field: "availableCapacity",
                value: availableCapacity
            ))
        }

        if usedCapacity < 0 {
            errors.append(ValidationError(
                code: "INVALID_USED_CAPACITY",
                message: "Used capacity cannot be negative",
                field: "usedCapacity",
                value: usedCapacity
            ))
        }

        return ValidationResult(errors: errors)
    }

    /// Export storage volume
    func export() -> [String: Any] {
        return [
            "name": name,
            "fileSystem": fileSystem,
            "mountPoint": mountPoint,
            "totalCapacity": totalCapacity,
            "availableCapacity": availableCapacity,
            "usedCapacity": usedCapacity,
            "usagePercentage": usagePercentage,
            "isEncrypted": isEncrypted,
            "isRemovable": isRemovable,
            "isInternal": isInternal
        ]
    }
}

/// Battery information
struct BatteryInfo: Codable {
    let isPresent: Bool
    let isCharging: Bool
    let chargePercentage: Double // 0.0 - 1.0
    let timeRemaining: TimeInterval? // Seconds until empty/full, nil if unknown
    let batteryHealth: BatteryHealth
    let cycleCount: Int?
    let temperature: Double? // Celsius

    init(
        isPresent: Bool = false,
        isCharging: Bool = false,
        chargePercentage: Double = 0.0,
        timeRemaining: TimeInterval? = nil,
        batteryHealth: BatteryHealth = .unknown,
        cycleCount: Int? = nil,
        temperature: Double? = nil
    ) {
        self.isPresent = isPresent
        self.isCharging = isCharging
        self.chargePercentage = chargePercentage
        self.timeRemaining = timeRemaining
        self.batteryHealth = batteryHealth
        self.cycleCount = cycleCount
        self.temperature = temperature
    }

    /// Validate battery info
    func validate() -> ValidationResult {
        var errors: [ValidationError] = []

        if isPresent {
            if chargePercentage < 0.0 || chargePercentage > 1.0 {
                errors.append(ValidationError(
                    code: "INVALID_CHARGE_PERCENTAGE",
                    message: "Charge percentage must be between 0.0 and 1.0",
                    field: "chargePercentage",
                    value: chargePercentage
                ))
            }

            if let cycleCount = cycleCount, cycleCount < 0 {
                errors.append(ValidationError(
                    code: "INVALID_CYCLE_COUNT",
                    message: "Cycle count cannot be negative",
                    field: "cycleCount",
                    value: cycleCount
                ))
            }

            if let temperature = temperature, temperature < -50.0 || temperature > 100.0 {
                errors.append(ValidationError(
                    code: "INVALID_TEMPERATURE",
                    message: "Battery temperature must be within reasonable range",
                    field: "temperature",
                    value: temperature
                ))
            }
        }

        return ValidationResult(errors: errors)
    }

    /// Export battery info
    func export() -> [String: Any] {
        var result: [String: Any] = [
            "isPresent": isPresent,
            "batteryHealth": batteryHealth.rawValue
        ]

        if isPresent {
            result["isCharging"] = isCharging
            result["chargePercentage"] = chargePercentage
            if let timeRemaining = timeRemaining {
                result["timeRemaining"] = timeRemaining
            }
            if let cycleCount = cycleCount {
                result["cycleCount"] = cycleCount
            }
            if let temperature = temperature {
                result["temperature"] = temperature
            }
        }

        return result
    }
}

/// Battery health enumeration
enum BatteryHealth: String, Codable, CaseIterable {
    case unknown = "unknown"
    case good = "good"
    case fair = "fair"
    case poor = "poor"
    case needsReplacement = "needsReplacement"

    var displayName: String {
        switch self {
        case .unknown:
            return "Unknown"
        case .good:
            return "Good"
        case .fair:
            return "Fair"
        case .poor:
            return "Poor"
        case .needsReplacement:
            return "Needs Replacement"
        }
    }
}

/// Thermal state enumeration
enum ThermalState: String, Codable, CaseIterable {
    case nominal = "nominal"
    case fair = "fair"
    case serious = "serious"
    case critical = "critical"

    var displayName: String {
        switch self {
        case .nominal:
            return "Nominal"
        case .fair:
            return "Fair"
        case .serious:
            return "Serious"
        case .critical:
            return "Critical"
        }
    }
}

/// Accessibility features information
struct AccessibilityFeatures: Codable {
    let voiceOverEnabled: Bool
    let zoomEnabled: Bool
    let switchControlEnabled: Bool
    let assistiveTouchEnabled: Bool
    let reduceMotionEnabled: Bool
    let highContrastEnabled: Bool
    let closedCaptionsEnabled: Bool
    let voiceControlEnabled: Bool

    init(
        voiceOverEnabled: Bool = false,
        zoomEnabled: Bool = false,
        switchControlEnabled: Bool = false,
        assistiveTouchEnabled: Bool = false,
        reduceMotionEnabled: Bool = false,
        highContrastEnabled: Bool = false,
        closedCaptionsEnabled: Bool = false,
        voiceControlEnabled: Bool = false
    ) {
        self.voiceOverEnabled = voiceOverEnabled
        self.zoomEnabled = zoomEnabled
        self.switchControlEnabled = switchControlEnabled
        self.assistiveTouchEnabled = assistiveTouchEnabled
        self.reduceMotionEnabled = reduceMotionEnabled
        self.highContrastEnabled = highContrastEnabled
        self.closedCaptionsEnabled = closedCaptionsEnabled
        self.voiceControlEnabled = voiceControlEnabled
    }

    /// Export accessibility features
    func export() -> [String: Any] {
        return [
            "voiceOverEnabled": voiceOverEnabled,
            "zoomEnabled": zoomEnabled,
            "switchControlEnabled": switchControlEnabled,
            "assistiveTouchEnabled": assistiveTouchEnabled,
            "reduceMotionEnabled": reduceMotionEnabled,
            "highContrastEnabled": highContrastEnabled,
            "closedCaptionsEnabled": closedCaptionsEnabled,
            "voiceControlEnabled": voiceControlEnabled
        ]
    }
}