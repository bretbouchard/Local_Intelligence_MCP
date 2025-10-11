//
//  SystemDataModelTests.swift
//  LocalIntelligenceMCP
//
//  Created on 2025-10-08.
//

import XCTest
@testable import LocalIntelligenceMCP

final class SystemDataModelTests: XCTestCase {

    // MARK: - Properties

    private var sampleSystemState: SystemStateDataModel!
    private var sampleSystemInfo: SystemInfo!
    private var samplePerformanceInfo: PerformanceInfo!
    private var sampleNetworkInfo: NetworkInfo!
    private var sampleStorageInfo: StorageInfo!
    private var sampleBatteryInfo: BatteryInfo!

    // MARK: - Setup and Teardown

    override func setUp() async throws {
        try await super.setUp()

        // Create sample system info
        sampleSystemInfo = SystemInfo(
            model: "MacBook Pro",
            manufacturer: "Apple",
            systemName: "macOS",
            systemVersion: "14.0",
            architecture: "arm64",
            processorCount: 8,
            memorySize: 16 * 1024 * 1024 * 1024, // 16GB
            hostname: "test-mac"
        )

        // Create sample performance info
        samplePerformanceInfo = PerformanceInfo(
            cpuUsage: 25.5,
            memoryUsage: 8.2 * 1024 * 1024 * 1024, // 8.2GB
            diskUsage: 256.5 * 1024 * 1024 * 1024, // 256.5GB
            networkIO: 1024 * 1024, // 1MB
            processCount: 150,
            loadAverage: [1.2, 1.5, 1.8]
        )

        // Create sample network info
        sampleNetworkInfo = NetworkInfo(
            interfaces: [
                NetworkInterface(
                    name: "en0",
                    displayName: "Wi-Fi",
                    type: .wifi,
                    status: .connected,
                    addresses: ["192.168.1.100"],
                    speed: 1000000000, // 1Gbps
                    mtu: 1500
                )
            ],
            connected: true,
            primaryInterface: "en0"
        )

        // Create sample storage info
        sampleStorageInfo = StorageInfo(
            totalCapacity: 512 * 1024 * 1024 * 1024, // 512GB
            availableCapacity: 256 * 1024 * 1024 * 1024, // 256GB
            usedCapacity: 256 * 1024 * 1024 * 1024, // 256GB
            volumes: [
                StorageVolume(
                    name: "Macintosh HD",
                    mountPoint: "/",
                    fileSystem: "APFS",
                    size: 512 * 1024 * 1024 * 1024,
                    availableSpace: 256 * 1024 * 1024 * 1024
                )
            ]
        )

        // Create sample battery info
        sampleBatteryInfo = BatteryInfo(
            isPresent: true,
            isCharging: false,
            chargePercent: 85.5,
            timeRemaining: 4.5 * 3600, // 4.5 hours in seconds
            batteryHealth: 95.0,
            temperature: 35.5,
            cycleCount: 150
        )

        // Create sample system state
        sampleSystemState = SystemStateDataModel(
            timestamp: Date(),
            systemInfo: sampleSystemInfo,
            performanceInfo: samplePerformanceInfo,
            networkInfo: sampleNetworkInfo,
            storageInfo: sampleStorageInfo,
            batteryInfo: sampleBatteryInfo,
            thermalState: .nominal,
            accessibilityFeatures: AccessibilityFeatures()
        )
    }

    override func tearDown() async throws {
        sampleSystemState = nil
        sampleSystemInfo = nil
        samplePerformanceInfo = nil
        sampleNetworkInfo = nil
        sampleStorageInfo = nil
        sampleBatteryInfo = nil

        try await super.tearDown()
    }

    // MARK: - SystemStateDataModel Tests

    func testSystemStateDataModelInitialization() async throws {
        XCTAssertNotNil(sampleSystemState)
        XCTAssertNotNil(sampleSystemState.timestamp)
        XCTAssertNotNil(sampleSystemState.systemInfo)
        XCTAssertNotNil(sampleSystemState.performanceInfo)
        XCTAssertNotNil(sampleSystemState.networkInfo)
        XCTAssertNotNil(sampleSystemState.storageInfo)
        XCTAssertNotNil(sampleSystemState.batteryInfo)
        XCTAssertEqual(sampleSystemState.thermalState, .nominal)
        XCTAssertNotNil(sampleSystemState.accessibilityFeatures)
    }

    func testSystemStateDataModelDefaultValues() async throws {
        let defaultSystemState = SystemStateDataModel()

        XCTAssertNotNil(defaultSystemState.timestamp)
        XCTAssertNotNil(defaultSystemState.systemInfo)
        XCTAssertNotNil(defaultSystemState.performanceInfo)
        XCTAssertNotNil(defaultSystemState.networkInfo)
        XCTAssertNotNil(defaultSystemState.storageInfo)
        XCTAssertNil(defaultSystemState.batteryInfo)
        XCTAssertEqual(defaultSystemState.thermalState, .nominal)
        XCTAssertNotNil(defaultSystemState.accessibilityFeatures)
    }

    func testSystemStateDataModelValidation() async throws {
        let validation = sampleSystemState.validate()
        XCTAssertTrue(validation.isValid)
        XCTAssertTrue(validation.errors.isEmpty)
    }

    func testSystemStateDataModelCodable() async throws {
        let encodedData = try JSONEncoder().encode(sampleSystemState)
        XCTAssertFalse(encodedData.isEmpty)

        let decodedSystemState = try JSONDecoder().decode(SystemStateDataModel.self, from: encodedData)
        XCTAssertEqual(decodedSystemState.systemInfo.model, sampleSystemState.systemInfo.model)
        XCTAssertEqual(decodedSystemState.performanceInfo.cpuUsage, sampleSystemState.performanceInfo.cpuUsage)
        XCTAssertEqual(decodedSystemState.networkInfo.connected, sampleSystemState.networkInfo.connected)
        XCTAssertEqual(decodedSystemState.storageInfo.totalCapacity, sampleSystemState.storageInfo.totalCapacity)
        XCTAssertEqual(decodedSystemState.batteryInfo?.chargePercent, sampleSystemState.batteryInfo?.chargePercent)
        XCTAssertEqual(decodedSystemState.thermalState, sampleSystemState.thermalState)
    }

    // MARK: - SystemInfo Tests

    func testSystemInfoInitialization() async throws {
        XCTAssertEqual(sampleSystemInfo.model, "MacBook Pro")
        XCTAssertEqual(sampleSystemInfo.manufacturer, "Apple")
        XCTAssertEqual(sampleSystemInfo.systemName, "macOS")
        XCTAssertEqual(sampleSystemInfo.systemVersion, "14.0")
        XCTAssertEqual(sampleSystemInfo.architecture, "arm64")
        XCTAssertEqual(sampleSystemInfo.processorCount, 8)
        XCTAssertEqual(sampleSystemInfo.memorySize, 16 * 1024 * 1024 * 1024)
        XCTAssertEqual(sampleSystemInfo.hostname, "test-mac")
    }

    func testSystemInfoValidation() async throws {
        // Valid system info
        let validation = sampleSystemInfo.validate()
        XCTAssertTrue(validation.isValid)

        // Invalid system info (empty model)
        let invalidSystemInfo = SystemInfo(
            model: "",
            manufacturer: "Apple",
            systemName: "macOS",
            systemVersion: "14.0",
            architecture: "arm64",
            processorCount: 8,
            memorySize: 16 * 1024 * 1024 * 1024
        )
        let invalidValidation = invalidSystemInfo.validate()
        XCTAssertFalse(invalidValidation.isValid)
        XCTAssertFalse(invalidValidation.errors.isEmpty)
    }

    func testSystemInfoCodable() async throws {
        let encodedData = try JSONEncoder().encode(sampleSystemInfo)
        XCTAssertFalse(encodedData.isEmpty)

        let decodedSystemInfo = try JSONDecoder().decode(SystemInfo.self, from: encodedData)
        XCTAssertEqual(decodedSystemInfo.model, sampleSystemInfo.model)
        XCTAssertEqual(decodedSystemInfo.manufacturer, sampleSystemInfo.manufacturer)
        XCTAssertEqual(decodedSystemInfo.systemName, sampleSystemInfo.systemName)
        XCTAssertEqual(decodedSystemInfo.systemVersion, sampleSystemInfo.systemVersion)
        XCTAssertEqual(decodedSystemInfo.architecture, sampleSystemInfo.architecture)
        XCTAssertEqual(decodedSystemInfo.processorCount, sampleSystemInfo.processorCount)
        XCTAssertEqual(decodedSystemInfo.memorySize, sampleSystemInfo.memorySize)
    }

    // MARK: - PerformanceInfo Tests

    func testPerformanceInfoInitialization() async throws {
        XCTAssertEqual(samplePerformanceInfo.cpuUsage, 25.5)
        XCTAssertEqual(samplePerformanceInfo.memoryUsage, 8.2 * 1024 * 1024 * 1024)
        XCTAssertEqual(samplePerformanceInfo.diskUsage, 256.5 * 1024 * 1024 * 1024)
        XCTAssertEqual(samplePerformanceInfo.networkIO, 1024 * 1024)
        XCTAssertEqual(samplePerformanceInfo.processCount, 150)
        XCTAssertEqual(samplePerformanceInfo.loadAverage, [1.2, 1.5, 1.8])
    }

    func testPerformanceInfoValidation() async throws {
        // Valid performance info
        let validation = samplePerformanceInfo.validate()
        XCTAssertTrue(validation.isValid)

        // Invalid performance info (negative CPU usage)
        let invalidPerformanceInfo = PerformanceInfo(
            cpuUsage: -5.0,
            memoryUsage: 8.2 * 1024 * 1024 * 1024,
            diskUsage: 256.5 * 1024 * 1024 * 1024,
            networkIO: 1024 * 1024,
            processCount: 150,
            loadAverage: [1.2, 1.5, 1.8]
        )
        let invalidValidation = invalidPerformanceInfo.validate()
        XCTAssertFalse(invalidValidation.isValid)
        XCTAssertFalse(invalidValidation.errors.isEmpty)
    }

    func testPerformanceInfoCodable() async throws {
        let encodedData = try JSONEncoder().encode(samplePerformanceInfo)
        XCTAssertFalse(encodedData.isEmpty)

        let decodedPerformanceInfo = try JSONDecoder().decode(PerformanceInfo.self, from: encodedData)
        XCTAssertEqual(decodedPerformanceInfo.cpuUsage, samplePerformanceInfo.cpuUsage)
        XCTAssertEqual(decodedPerformanceInfo.memoryUsage, samplePerformanceInfo.memoryUsage)
        XCTAssertEqual(decodedPerformanceInfo.diskUsage, samplePerformanceInfo.diskUsage)
        XCTAssertEqual(decodedPerformanceInfo.networkIO, samplePerformanceInfo.networkIO)
        XCTAssertEqual(decodedPerformanceInfo.processCount, samplePerformanceInfo.processCount)
        XCTAssertEqual(decodedPerformanceInfo.loadAverage, samplePerformanceInfo.loadAverage)
    }

    // MARK: - NetworkInfo Tests

    func testNetworkInfoInitialization() async throws {
        XCTAssertTrue(sampleNetworkInfo.connected)
        XCTAssertEqual(sampleNetworkInfo.primaryInterface, "en0")
        XCTAssertEqual(sampleNetworkInfo.interfaces.count, 1)

        let interface = sampleNetworkInfo.interfaces.first!
        XCTAssertEqual(interface.name, "en0")
        XCTAssertEqual(interface.displayName, "Wi-Fi")
        XCTAssertEqual(interface.type, .wifi)
        XCTAssertEqual(interface.status, .connected)
        XCTAssertEqual(interface.addresses, ["192.168.1.100"])
        XCTAssertEqual(interface.speed, 1000000000)
        XCTAssertEqual(interface.mtu, 1500)
    }

    func testNetworkInterfaceTypeRawValues() async throws {
        XCTAssertEqual(NetworkInterfaceType.ethernet.rawValue, "ethernet")
        XCTAssertEqual(NetworkInterfaceType.wifi.rawValue, "wifi")
        XCTAssertEqual(NetworkInterfaceType.cellular.rawValue, "cellular")
        XCTAssertEqual(NetworkInterfaceType.loopback.rawValue, "loopback")
        XCTAssertEqual(NetworkInterfaceType.other.rawValue, "other")
    }

    func testNetworkInterfaceStatusRawValues() async throws {
        XCTAssertEqual(NetworkInterfaceStatus.connected.rawValue, "connected")
        XCTAssertEqual(NetworkInterfaceStatus.disconnected.rawValue, "disconnected")
        XCTAssertEqual(NetworkInterfaceStatus.disabled.rawValue, "disabled")
    }

    func testNetworkInfoCodable() async throws {
        let encodedData = try JSONEncoder().encode(sampleNetworkInfo)
        XCTAssertFalse(encodedData.isEmpty)

        let decodedNetworkInfo = try JSONDecoder().decode(NetworkInfo.self, from: encodedData)
        XCTAssertEqual(decodedNetworkInfo.connected, sampleNetworkInfo.connected)
        XCTAssertEqual(decodedNetworkInfo.primaryInterface, sampleNetworkInfo.primaryInterface)
        XCTAssertEqual(decodedNetworkInfo.interfaces.count, sampleNetworkInfo.interfaces.count)

        let decodedInterface = decodedNetworkInfo.interfaces.first!
        let originalInterface = sampleNetworkInfo.interfaces.first!
        XCTAssertEqual(decodedInterface.name, originalInterface.name)
        XCTAssertEqual(decodedInterface.displayName, originalInterface.displayName)
        XCTAssertEqual(decodedInterface.type, originalInterface.type)
        XCTAssertEqual(decodedInterface.status, originalInterface.status)
    }

    // MARK: - StorageInfo Tests

    func testStorageInfoInitialization() async throws {
        XCTAssertEqual(sampleStorageInfo.totalCapacity, 512 * 1024 * 1024 * 1024)
        XCTAssertEqual(sampleStorageInfo.availableCapacity, 256 * 1024 * 1024 * 1024)
        XCTAssertEqual(sampleStorageInfo.usedCapacity, 256 * 1024 * 1024 * 1024)
        XCTAssertEqual(sampleStorageInfo.volumes.count, 1)

        let volume = sampleStorageInfo.volumes.first!
        XCTAssertEqual(volume.name, "Macintosh HD")
        XCTAssertEqual(volume.mountPoint, "/")
        XCTAssertEqual(volume.fileSystem, "APFS")
        XCTAssertEqual(volume.size, 512 * 1024 * 1024 * 1024)
        XCTAssertEqual(volume.availableSpace, 256 * 1024 * 1024 * 1024)
    }

    func testStorageInfoValidation() async throws {
        // Valid storage info
        let validation = sampleStorageInfo.validate()
        XCTAssertTrue(validation.isValid)

        // Invalid storage info (used > total)
        let invalidStorageInfo = StorageInfo(
            totalCapacity: 512 * 1024 * 1024 * 1024,
            availableCapacity: 100 * 1024 * 1024 * 1024,
            usedCapacity: 600 * 1024 * 1024 * 1024, // More than total
            volumes: []
        )
        let invalidValidation = invalidStorageInfo.validate()
        XCTAssertFalse(invalidValidation.isValid)
        XCTAssertFalse(invalidValidation.errors.isEmpty)
    }

    func testStorageInfoCodable() async throws {
        let encodedData = try JSONEncoder().encode(sampleStorageInfo)
        XCTAssertFalse(encodedData.isEmpty)

        let decodedStorageInfo = try JSONDecoder().decode(StorageInfo.self, from: encodedData)
        XCTAssertEqual(decodedStorageInfo.totalCapacity, sampleStorageInfo.totalCapacity)
        XCTAssertEqual(decodedStorageInfo.availableCapacity, sampleStorageInfo.availableCapacity)
        XCTAssertEqual(decodedStorageInfo.usedCapacity, sampleStorageInfo.usedCapacity)
        XCTAssertEqual(decodedStorageInfo.volumes.count, sampleStorageInfo.volumes.count)

        let decodedVolume = decodedStorageInfo.volumes.first!
        let originalVolume = sampleStorageInfo.volumes.first!
        XCTAssertEqual(decodedVolume.name, originalVolume.name)
        XCTAssertEqual(decodedVolume.mountPoint, originalVolume.mountPoint)
        XCTAssertEqual(decodedVolume.fileSystem, originalVolume.fileSystem)
    }

    // MARK: - BatteryInfo Tests

    func testBatteryInfoInitialization() async throws {
        XCTAssertTrue(sampleBatteryInfo.isPresent)
        XCTAssertFalse(sampleBatteryInfo.isCharging)
        XCTAssertEqual(sampleBatteryInfo.chargePercent, 85.5)
        XCTAssertEqual(sampleBatteryInfo.timeRemaining, 4.5 * 3600)
        XCTAssertEqual(sampleBatteryInfo.batteryHealth, 95.0)
        XCTAssertEqual(sampleBatteryInfo.temperature, 35.5)
        XCTAssertEqual(sampleBatteryInfo.cycleCount, 150)
    }

    func testBatteryInfoValidation() async throws {
        // Valid battery info
        let validation = sampleBatteryInfo.validate()
        XCTAssertTrue(validation.isValid)

        // Invalid battery info (charge percentage out of range)
        let invalidBatteryInfo = BatteryInfo(
            isPresent: true,
            isCharging: false,
            chargePercent: 150.0, // Over 100%
            timeRemaining: 4.5 * 3600,
            batteryHealth: 95.0,
            temperature: 35.5,
            cycleCount: 150
        )
        let invalidValidation = invalidBatteryInfo.validate()
        XCTAssertFalse(invalidValidation.isValid)
        XCTAssertFalse(invalidValidation.errors.isEmpty)
    }

    func testBatteryInfoCodable() async throws {
        let encodedData = try JSONEncoder().encode(sampleBatteryInfo)
        XCTAssertFalse(encodedData.isEmpty)

        let decodedBatteryInfo = try JSONDecoder().decode(BatteryInfo.self, from: encodedData)
        XCTAssertEqual(decodedBatteryInfo.isPresent, sampleBatteryInfo.isPresent)
        XCTAssertEqual(decodedBatteryInfo.isCharging, sampleBatteryInfo.isCharging)
        XCTAssertEqual(decodedBatteryInfo.chargePercent, sampleBatteryInfo.chargePercent)
        XCTAssertEqual(decodedBatteryInfo.timeRemaining, sampleBatteryInfo.timeRemaining)
        XCTAssertEqual(decodedBatteryInfo.batteryHealth, sampleBatteryInfo.batteryHealth)
        XCTAssertEqual(decodedBatteryInfo.temperature, sampleBatteryInfo.temperature)
        XCTAssertEqual(decodedBatteryInfo.cycleCount, sampleBatteryInfo.cycleCount)
    }

    // MARK: - ThermalState Tests

    func testThermalStateRawValues() async throws {
        XCTAssertEqual(ThermalState.nominal.rawValue, "nominal")
        XCTAssertEqual(ThermalState.fair.rawValue, "fair")
        XCTAssertEqual(ThermalState.serious.rawValue, "serious")
        XCTAssertEqual(ThermalState.critical.rawValue, "critical")
    }

    func testThermalStateCodable() async throws {
        let thermalStates: [ThermalState] = [.nominal, .fair, .serious, .critical]

        for thermalState in thermalStates {
            let encodedData = try JSONEncoder().encode(thermalState)
            XCTAssertFalse(encodedData.isEmpty)

            let decodedThermalState = try JSONDecoder().decode(ThermalState.self, from: encodedData)
            XCTAssertEqual(decodedThermalState, thermalState)
        }
    }

    // MARK: - AccessibilityFeatures Tests

    func testAccessibilityFeaturesInitialization() async throws {
        let features = AccessibilityFeatures(
            voiceOver: true,
            zoom: false,
            highContrast: true,
            reduceMotion: false,
            closedCaptions: true,
            switchControl: false
        )

        XCTAssertTrue(features.voiceOver)
        XCTAssertFalse(features.zoom)
        XCTAssertTrue(features.highContrast)
        XCTAssertFalse(features.reduceMotion)
        XCTAssertTrue(features.closedCaptions)
        XCTAssertFalse(features.switchControl)
    }

    func testAccessibilityFeaturesCodable() async throws {
        let features = AccessibilityFeatures(
            voiceOver: true,
            zoom: false,
            highContrast: true,
            reduceMotion: false,
            closedCaptions: true,
            switchControl: false
        )

        let encodedData = try JSONEncoder().encode(features)
        XCTAssertFalse(encodedData.isEmpty)

        let decodedFeatures = try JSONDecoder().decode(AccessibilityFeatures.self, from: encodedData)
        XCTAssertEqual(decodedFeatures.voiceOver, features.voiceOver)
        XCTAssertEqual(decodedFeatures.zoom, features.zoom)
        XCTAssertEqual(decodedFeatures.highContrast, features.highContrast)
        XCTAssertEqual(decodedFeatures.reduceMotion, features.reduceMotion)
        XCTAssertEqual(decodedFeatures.closedCaptions, features.closedCaptions)
        XCTAssertEqual(decodedFeatures.switchControl, features.switchControl)
    }

    // MARK: - Edge Cases Tests

    func testSystemStateWithMinimalData() async throws {
        let minimalSystemState = SystemStateDataModel(
            systemInfo: SystemInfo(
                model: "Test",
                manufacturer: "Test",
                systemName: "Test",
                systemVersion: "1.0",
                architecture: "x86_64",
                processorCount: 1,
                memorySize: 1024 * 1024 * 1024
            )
        )

        XCTAssertNotNil(minimalSystemState)
        XCTAssertNil(minimalSystemState.batteryInfo)
        XCTAssertEqual(minimalSystemState.thermalState, .nominal)
    }

    func testSystemStateWithMultipleNetworkInterfaces() async throws {
        let multiInterfaceNetworkInfo = NetworkInfo(
            interfaces: [
                NetworkInterface(
                    name: "en0",
                    displayName: "Wi-Fi",
                    type: .wifi,
                    status: .connected,
                    addresses: ["192.168.1.100"],
                    speed: 1000000000,
                    mtu: 1500
                ),
                NetworkInterface(
                    name: "en1",
                    displayName: "Ethernet",
                    type: .ethernet,
                    status: .connected,
                    addresses: ["10.0.0.100"],
                    speed: 10000000000,
                    mtu: 1500
                ),
                NetworkInterface(
                    name: "lo0",
                    displayName: "Loopback",
                    type: .loopback,
                    status: .connected,
                    addresses: ["127.0.0.1"],
                    speed: 0,
                    mtu: 16384
                )
            ],
            connected: true,
            primaryInterface: "en0"
        )

        let systemState = SystemStateDataModel(
            networkInfo: multiInterfaceNetworkInfo
        )

        XCTAssertEqual(systemState.networkInfo.interfaces.count, 3)
        XCTAssertEqual(systemState.networkInfo.primaryInterface, "en0")
    }

    func testSystemStateWithNoBattery() async throws {
        let noBatterySystemState = SystemStateDataModel(
            batteryInfo: nil
        )

        XCTAssertNil(noBatterySystemState.batteryInfo)
    }

    func testSystemStateTimestampAccuracy() async throws {
        let beforeDate = Date()
        let systemState = SystemStateDataModel()
        let afterDate = Date()

        XCTAssertGreaterThanOrEqual(systemState.timestamp, beforeDate)
        XCTAssertLessThanOrEqual(systemState.timestamp, afterDate)
    }
}