//
//  PatternCache.swift
//  LocalIntelligenceMCP
//
//  Created on 2025-10-09.
//

import Foundation

/// High-performance cache for pre-compiled regex patterns
/// Optimizes memory usage and compilation overhead for frequently used patterns
public actor PatternCache {

    // MARK: - Singleton

    public static let shared = PatternCache()

    // MARK: - Properties

    private var compiledPatterns: [String: NSRegularExpression] = [:]
    private var accessCounts: [String: Int] = [:]
    private var lastAccessed: [String: Date] = [:]

    private let maxCacheSize: Int
    private let cleanupThreshold: Int
    private let maxAge: TimeInterval

    // MARK: - Initialization

    private init(maxCacheSize: Int = 100, cleanupThreshold: Int = 150, maxAge: TimeInterval = 3600) {
        self.maxCacheSize = maxCacheSize
        self.cleanupThreshold = cleanupThreshold
        self.maxAge = maxAge
    }

    // MARK: - Public Interface

    /// Get or compile a regex pattern with automatic caching
    /// - Parameters:
    ///   - pattern: The regex pattern string
    ///   - options: Regular expression options
    /// - Returns: Compiled NSRegularExpression
    /// - Throws: Pattern compilation error
    public func getPattern(_ pattern: String, options: NSRegularExpression.Options = []) throws -> NSRegularExpression {
        let cacheKey = "\(pattern)_\(options.rawValue)"

        // Update access metadata
        accessCounts[cacheKey, default: 0] += 1
        lastAccessed[cacheKey] = Date()

        // Return cached pattern if available
        if let cachedPattern = compiledPatterns[cacheKey] {
            return cachedPattern
        }

        // Compile new pattern
        let compiledPattern = try NSRegularExpression(pattern: pattern, options: options)

        // Cache management - cleanup if needed
        if compiledPatterns.count >= cleanupThreshold {
            Task {
                await performCleanup()
            }
        }

        // Add to cache
        compiledPatterns[cacheKey] = compiledPattern

        return compiledPattern
    }

    /// Get multiple patterns efficiently (batch operation)
    /// - Parameter patterns: Array of pattern strings
    /// - Returns: Dictionary of pattern to compiled regex
    /// - Throws: Pattern compilation error
    public func getPatterns(_ patterns: [String]) throws -> [String: NSRegularExpression] {
        var result: [String: NSRegularExpression] = [:]

        for pattern in patterns {
            result[pattern] = try getPattern(pattern)
        }

        return result
    }

    /// Preload common patterns for optimal performance
    /// - Parameter patterns: Array of common patterns to preload
    /// - Throws: Pattern compilation error
    public func preloadCommonPatterns(_ patterns: [String]) async throws {
        for pattern in patterns {
            try getPattern(pattern)
        }
    }

    // MARK: - Cache Management

    /// Remove least recently used patterns to maintain cache size
    private func performCleanup() async {
        guard compiledPatterns.count > maxCacheSize else { return }

        // Sort by last accessed time and access count
        let sortedKeys = compiledPatterns.keys.sorted { key1, key2 in
            let score1 = calculateScore(for: key1)
            let score2 = calculateScore(for: key2)
            return score1 < score2
        }

        // Remove least valuable patterns
        let keysToRemove = Array(sortedKeys.prefix(compiledPatterns.count - maxCacheSize))

        for key in keysToRemove {
            compiledPatterns.removeValue(forKey: key)
            accessCounts.removeValue(forKey: key)
            lastAccessed.removeValue(forKey: key)
        }

        // Also remove old patterns
        let now = Date()
        let oldKeys = compiledPatterns.keys.compactMap { key -> String? in
            if let lastAccess = lastAccessed[key], now.timeIntervalSince(lastAccess) > maxAge {
                return key
            }
            return nil
        }

        for key in oldKeys {
            compiledPatterns.removeValue(forKey: key)
            accessCounts.removeValue(forKey: key)
            lastAccessed.removeValue(forKey: key)
        }
    }

    /// Calculate score for pattern cache ranking (higher = more valuable)
    private func calculateScore(for key: String) -> Double {
        let accessCount = Double(accessCounts[key] ?? 0)
        let timeSinceAccess = lastAccessed[key]?.timeIntervalSinceNow ?? 0
        let recencyFactor = exp(-timeSinceAccess / 300) // Decay over 5 minutes

        return accessCount * recencyFactor
    }

    /// Clear cache manually
    public func clearCache() async {
        compiledPatterns.removeAll()
        accessCounts.removeAll()
        lastAccessed.removeAll()
    }

    /// Get cache statistics for monitoring
    public func getCacheStats() -> CacheStats {
        return CacheStats(
            totalPatterns: compiledPatterns.count,
            maxCacheSize: maxCacheSize,
            mostAccessed: getMostAccessedPatterns(),
            cacheHitRatio: calculateCacheHitRatio()
        )
    }

    // MARK: - Private Helpers

    private func getMostAccessedPatterns(limit: Int = 5) -> [(String, Int)] {
        return accessCounts.sorted { $0.value > $1.value }.prefix(limit).map { ($0.key, $0.value) }
    }

    private func calculateCacheHitRatio() -> Double {
        let totalAccesses = accessCounts.values.reduce(0, +)
        let uniquePatterns = compiledPatterns.count
        guard uniquePatterns > 0 else { return 0.0 }
        return Double(totalAccesses) / Double(uniquePatterns)
    }
}

// MARK: - Cache Statistics

/// Cache performance statistics
public struct CacheStats {
    public let totalPatterns: Int
    public let maxCacheSize: Int
    public let mostAccessed: [(String, Int)]
    public let cacheHitRatio: Double

    public init(totalPatterns: Int, maxCacheSize: Int, mostAccessed: [(String, Int)], cacheHitRatio: Double) {
        self.totalPatterns = totalPatterns
        self.maxCacheSize = maxCacheSize
        self.mostAccessed = mostAccessed
        self.cacheHitRatio = cacheHitRatio
    }
}

// MARK: - Common Audio Patterns

/// Common regex patterns used in audio processing
public enum CommonAudioPatterns {
    public static let email = #"[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}"#
    public static let phone = #"\b\d{3}[-.]?\d{3}[-.]?\d{4}\b"#
    public static let apiKey = #"[a-zA-Z0-9]{20,}"#
    public static let url = #"https?://[^\s/$.?#].[^\s]*"#
    public static let ipAddress = #"\b(?:\d{1,3}\.){3}\d{1,3}\b"#
    public static let creditCard = #"\b\d{4}[-\s]?\d{4}[-\s]?\d{4}[-\s]?\d{4}\b"#
    public static let ssn = #"\b\d{3}-\d{2}-\d{4}\b"#

    /// Audio-specific patterns
    public static let audioFormat = #"\.(wav|mp3|aiff|flac|m4a|aac|ogg|wma)\b"#
    public static let sampleRate = #"\b\d{1,3}(?:\.\d{1,2})?\s*Hz\b"#
    public static let bitDepth = #"\b\d{1,2}\s*bit\b"#
    public static let duration = #"\b\d{1,2}:\d{2}(?::\d{2})?\b"#
    public static let frequency = #"\b\d{1,5}\s*Hz\b"#

    /// Get all common patterns for preloading
    public static let allPatterns: [String] = [
        email, phone, apiKey, url, ipAddress, creditCard, ssn,
        audioFormat, sampleRate, bitDepth, duration, frequency
    ]
}

// MARK: - Performance Monitoring

/// Extension for performance monitoring
extension PatternCache {

    /// Benchmark pattern compilation performance
    /// - Parameters:
    ///   - patterns: Patterns to benchmark
    ///   - iterations: Number of iterations per pattern
    /// - Returns: Performance metrics
    public func benchmarkPerformance(patterns: [String], iterations: Int = 1000) async -> PatternCachePerformanceMetrics {
        var compilationTimes: [TimeInterval] = []
        var cacheHitTimes: [TimeInterval] = []

        for pattern in patterns {
            // Measure cold compilation
            let coldStart = Date()
            _ = try? getPattern(pattern)
            let coldTime = Date().timeIntervalSince(coldStart)
            compilationTimes.append(coldTime)

            // Measure cache hits
            for _ in 0..<iterations {
                let hitStart = Date()
                _ = try? getPattern(pattern)
                let hitTime = Date().timeIntervalSince(hitStart)
                cacheHitTimes.append(hitTime)
            }
        }

        return PatternCachePerformanceMetrics(
            averageCompilationTime: compilationTimes.reduce(0, +) / Double(compilationTimes.count),
            averageCacheHitTime: cacheHitTimes.reduce(0, +) / Double(cacheHitTimes.count),
            speedupFactor: compilationTimes.reduce(0, +) / cacheHitTimes.reduce(0, +),
            totalPatternsTested: patterns.count
        )
    }
}

/// Performance metrics for pattern cache
public struct PatternCachePerformanceMetrics {
    public let averageCompilationTime: TimeInterval
    public let averageCacheHitTime: TimeInterval
    public let speedupFactor: Double
    public let totalPatternsTested: Int

    public init(averageCompilationTime: TimeInterval, averageCacheHitTime: TimeInterval, speedupFactor: Double, totalPatternsTested: Int) {
        self.averageCompilationTime = averageCompilationTime
        self.averageCacheHitTime = averageCacheHitTime
        self.speedupFactor = speedupFactor
        self.totalPatternsTested = totalPatternsTested
    }
}