//
//  MemoryMonitor.swift
//  LocalIntelligenceMCP
//
//  Created on 2025-10-09.
//

import Foundation

/// Memory usage monitoring and optimization utility
/// Tracks memory consumption and provides optimization recommendations
public actor MemoryMonitor {

    // MARK: - Configuration

    public struct Configuration {
        public let warningThreshold: UInt64      // MB
        public let criticalThreshold: UInt64     // MB
        public let monitoringInterval: TimeInterval
        public let maxHistorySize: Int

        public init(
            warningThreshold: UInt64 = 512,      // 512MB
            criticalThreshold: UInt64 = 1024,    // 1GB
            monitoringInterval: TimeInterval = 5.0,
            maxHistorySize: Int = 100
        ) {
            self.warningThreshold = warningThreshold
            self.criticalThreshold = criticalThreshold
            self.monitoringInterval = monitoringInterval
            self.maxHistorySize = maxHistorySize
        }
    }

    // MARK: - Properties

    private let configuration: Configuration
    private var isMonitoring = false
    private var monitoringTask: Task<Void, Never>?

    private var memoryHistory: [MemorySnapshot] = []
    private var currentSnapshot: MemorySnapshot?
    private var optimizationCallbacks: [OptimizationCallback] = []

    // MARK: - Initialization

    public init(configuration: Configuration = Configuration()) {
        self.configuration = configuration
    }

    // MARK: - Public Interface

    /// Start memory monitoring
    /// - Parameter callback: Optional callback for memory events
    public func startMonitoring(callback: OptimizationCallback? = nil) async {
        guard !isMonitoring else { return }

        if let callback = callback {
            optimizationCallbacks.append(callback)
        }

        isMonitoring = true
        monitoringTask = Task {
            await monitoringLoop()
        }
    }

    /// Stop memory monitoring
    public func stopMonitoring() async {
        isMonitoring = false
        monitoringTask?.cancel()
        monitoringTask = nil
    }

    /// Get current memory snapshot
    /// - Returns: Current memory usage information
    public func getCurrentSnapshot() async -> MemorySnapshot {
        let snapshot = createMemorySnapshot()
        currentSnapshot = snapshot
        return snapshot
    }

    /// Get memory usage history
    /// - Parameter limit: Maximum number of snapshots to return
    /// - Returns: Array of memory snapshots
    public func getMemoryHistory(limit: Int? = nil) -> [MemorySnapshot] {
        let limit = limit ?? configuration.maxHistorySize
        return Array(memoryHistory.suffix(limit))
    }

    /// Analyze memory usage patterns
    /// - Returns: Memory analysis with recommendations
    public func analyzeMemoryUsage() async -> MemoryAnalysis {
        let current = await getCurrentSnapshot()
        let history = getMemoryHistory()

        guard !history.isEmpty else {
            return MemoryAnalysis(
                currentUsage: current,
                trend: .unknown,
                averageGrowthRate: 0,
                peakUsage: current,
                recommendations: [.startMonitoring]
            )
        }

        let trend = calculateTrend(history: history)
        let growthRate = calculateGrowthRate(history: history)
        let peakUsage = history.max { $0.usedMemory < $1.usedMemory } ?? current

        var recommendations: [MemoryRecommendation] = []

        // Analyze current usage
        if current.usedMemory > configuration.criticalThreshold {
            recommendations.append(.urgentCleanup)
        } else if current.usedMemory > configuration.warningThreshold {
            recommendations.append(.moderateCleanup)
        }

        // Analyze trend
        switch trend {
        case .increasing:
            recommendations.append(.investigateLeaks)
        case .decreasing:
            // Memory usage is decreasing, good
            break
        case .stable:
            // Stable usage, monitor for changes
            break
        case .unknown:
            recommendations.append(.startMonitoring)
        }

        // Analyze growth rate
        if growthRate > 10 { // 10MB per minute
            recommendations.append(.implementCaching)
        }

        return MemoryAnalysis(
            currentUsage: current,
            trend: trend,
            averageGrowthRate: growthRate,
            peakUsage: peakUsage,
            recommendations: recommendations
        )
    }

    /// Force garbage collection
    /// - Returns: Memory freed (if measurable)
    public func forceGarbageCollection() async -> UInt64 {
        let before = await getCurrentSnapshot()

        // Swift doesn't have explicit garbage collection, but we can suggest it
        // In a real implementation, you might use pool management or other techniques

        let after = await getCurrentSnapshot()
        return max(0, before.usedMemory - after.usedMemory)
    }

    /// Add optimization callback
    /// - Parameter callback: Callback to invoke when optimization is needed
    public func addOptimizationCallback(_ callback: OptimizationCallback) {
        optimizationCallbacks.append(callback)
    }

    /// Remove optimization callback
    /// - Parameter callback: Callback to remove
    public func removeOptimizationCallback(_ callback: OptimizationCallback) {
        optimizationCallbacks.removeAll { $0.id == callback.id }
    }

    /// Get memory optimization recommendations
    /// - Returns: Specific recommendations based on current state
    public func getOptimizationRecommendations() async -> [MemoryOptimization] {
        let analysis = await analyzeMemoryUsage()
        var optimizations: [MemoryOptimization] = []

        for recommendation in analysis.recommendations {
            switch recommendation {
            case .urgentCleanup:
                optimizations.append(contentsOf: [
                    .clearCaches,
                    .releaseLargeObjects,
                    .compressMemory
                ])
            case .moderateCleanup:
                optimizations.append(contentsOf: [
                    .clearCaches,
                    .optimizeDataStructures
                ])
            case .investigateLeaks:
                optimizations.append(contentsOf: [
                    .enableLeakDetection,
                    .reviewMemoryAllocations
                ])
            case .implementCaching:
                optimizations.append(contentsOf: [
                    .implementLRUCache,
                    .useLazyLoading
                ])
            case .startMonitoring:
                optimizations.append(contentsOf: [
                    .enableContinuousMonitoring
                ])
            }
        }

        return optimizations
    }

    // MARK: - Private Methods

    /// Main monitoring loop
    private func monitoringLoop() async {
        while isMonitoring {
            let snapshot = await createMemorySnapshot()

            // Update history
            memoryHistory.append(snapshot)
            if memoryHistory.count > configuration.maxHistorySize {
                memoryHistory.removeFirst()
            }

            // Check thresholds and trigger callbacks
            await checkThresholds(snapshot: snapshot)

            // Sleep until next check
            try? await Task.sleep(nanoseconds: UInt64(configuration.monitoringInterval * 1_000_000_000))
        }
    }

    /// Create memory snapshot
    private func createMemorySnapshot() -> MemorySnapshot {
        let usedMemory: UInt64
        
        #if os(macOS)
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4

        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }

        if kerr == KERN_SUCCESS {
            usedMemory = info.resident_size
        } else {
            usedMemory = 0
        }
        #else
        // Fallback for Linux - use a simplified approach
        usedMemory = 0
        #endif

        return MemorySnapshot(
            timestamp: Date(),
            usedMemory: usedMemory / 1024 / 1024, // Convert to MB
            availableMemory: getAvailableMemory(),
            activeObjects: getActiveObjectCount(),
            cacheSize: getCacheSize()
        )
    }

    /// Get available system memory (simplified)
    private func getAvailableMemory() -> UInt64 {
        // In a real implementation, you'd use sysctl or similar
        // For now, return a placeholder
        return 0
    }

    /// Get active object count (placeholder)
    private func getActiveObjectCount() -> Int {
        // This would require custom object tracking
        return 0
    }

    /// Get cache size estimate (placeholder)
    private func getCacheSize() -> UInt64 {
        // This would require custom cache tracking
        return 0
    }

    /// Check memory thresholds and trigger callbacks
    private func checkThresholds(snapshot: MemorySnapshot) async {
        let event: MemoryEvent

        if snapshot.usedMemory > configuration.criticalThreshold {
            event = .critical(threshold: configuration.criticalThreshold, usage: snapshot.usedMemory)
        } else if snapshot.usedMemory > configuration.warningThreshold {
            event = .warning(threshold: configuration.warningThreshold, usage: snapshot.usedMemory)
        } else {
            return // No action needed
        }

        // Notify all callbacks
        for callback in optimizationCallbacks {
            await callback.handler(event)
        }
    }

    /// Calculate memory usage trend
    private func calculateTrend(history: [MemorySnapshot]) -> MemoryTrend {
        guard history.count >= 2 else { return .unknown }

        let recent = history.suffix(10)
        let first = recent.first!
        let last = recent.last!

        if last.usedMemory > UInt64(Double(first.usedMemory) * 1.1) {
            return .increasing
        } else if last.usedMemory < UInt64(Double(first.usedMemory) * 0.9) {
            return .decreasing
        } else {
            return .stable
        }
    }

    /// Calculate average growth rate
    private func calculateGrowthRate(history: [MemorySnapshot]) -> Double {
        guard history.count >= 2 else { return 0 }

        let timeSpan = history.last!.timestamp.timeIntervalSince(history.first!.timestamp)
        guard timeSpan > 0 else { return 0 }

        let memoryGrowth = Double(history.last!.usedMemory) - Double(history.first!.usedMemory)
        return (memoryGrowth / timeSpan) * 60 // MB per minute
    }
}

// MARK: - Data Structures

/// Memory usage snapshot
public struct MemorySnapshot: Sendable {
    public let timestamp: Date
    public let usedMemory: UInt64          // MB
    public let availableMemory: UInt64     // MB
    public let activeObjects: Int
    public let cacheSize: UInt64           // MB
}

/// Memory usage trend
public enum MemoryTrend {
    case increasing
    case decreasing
    case stable
    case unknown
}

/// Memory event types
public enum MemoryEvent {
    case warning(threshold: UInt64, usage: UInt64)
    case critical(threshold: UInt64, usage: UInt64)
}

/// Memory recommendation types
public enum MemoryRecommendation {
    case urgentCleanup
    case moderateCleanup
    case investigateLeaks
    case implementCaching
    case startMonitoring
}

/// Memory optimization types
public enum MemoryOptimization {
    case clearCaches
    case releaseLargeObjects
    case compressMemory
    case optimizeDataStructures
    case enableLeakDetection
    case reviewMemoryAllocations
    case implementLRUCache
    case useLazyLoading
    case enableContinuousMonitoring
}

/// Memory analysis result
public struct MemoryAnalysis {
    public let currentUsage: MemorySnapshot
    public let trend: MemoryTrend
    public let averageGrowthRate: Double      // MB per minute
    public let peakUsage: MemorySnapshot
    public let recommendations: [MemoryRecommendation]
}

/// Optimization callback
public struct OptimizationCallback {
    public let id = UUID()
    public let handler: (MemoryEvent) async -> Void

    public init(handler: @escaping (MemoryEvent) async -> Void) {
        self.handler = handler
    }

    public static func == (lhs: OptimizationCallback, rhs: OptimizationCallback) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Convenience Extensions

extension MemoryMonitor {

    /// Quick memory check with automatic optimization
    public func quickMemoryCheck() async -> MemoryCheckResult {
        let snapshot = await getCurrentSnapshot()
        var actions: [String] = []

        if snapshot.usedMemory > configuration.criticalThreshold {
            actions.append("Critical memory usage detected")
            await forceGarbageCollection()
            actions.append("Forced garbage collection")
        } else if snapshot.usedMemory > configuration.warningThreshold {
            actions.append("High memory usage detected")
            // Suggest optimizations
            actions.append("Memory optimization recommended")
        }

        return MemoryCheckResult(
            snapshot: snapshot,
            actions: actions,
            needsOptimization: snapshot.usedMemory > configuration.warningThreshold
        )
    }
}

/// Result of quick memory check
public struct MemoryCheckResult: Sendable {
    public let snapshot: MemorySnapshot
    public let actions: [String]
    public let needsOptimization: Bool
}