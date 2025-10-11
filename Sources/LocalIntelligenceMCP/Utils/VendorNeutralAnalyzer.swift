//
//  VendorNeutralAnalyzer.swift
//  LocalIntelligenceMCP
//
//  Created on 2025-10-09.
//

import Foundation

/// Utility class for vendor-neutral plugin analysis and comparison
/// Provides agnostic comparison capabilities across different plugin vendors and formats
public struct VendorNeutralAnalyzer: @unchecked Sendable {

    // MARK: - Plugin Feature Analysis

    /// Analyze plugin features regardless of vendor
    public static func analyzePluginFeatures(_ plugin: CatalogSummarizationTool.PluginItem) -> PluginFeatureAnalysis {
        var features: Set<String> = []
        var capabilities: Set<String> = []
        var signalTypes: Set<String> = []
        var processingTypes: Set<String> = []

        // Extract features from various sources
        features.formUnion(plugin.tags.map { $0.lowercased() })
        if let pluginFeatures = plugin.features {
            features.formUnion(pluginFeatures.map { $0.lowercased() })
        }
        features.formUnion(extractFeaturesFromDescription(plugin.description).map { $0.lowercased() })

        // Categorize features
        for feature in features {
            if capabilities.contains(feature) {
                continue
            }

            switch feature {
            // Dynamics
            case "compressor", "compression", "limiter", "limiting", "gate", "gating", "expander", "expansion", "multiband", "dynamics":
                capabilities.insert("dynamics_processing")
                processingTypes.insert("dynamics")

            // EQ and Filtering
            case "eq", "equalizer", "filter", "filtering", "parametric", "graphic", "shelf", "bell", "notch", "peak":
                capabilities.insert("equalization")
                processingTypes.insert("frequency_processing")

            // Time-based effects
            case "reverb", "delay", "echo", "chorus", "phaser", "flanger", "modulation", "time":
                capabilities.insert("time_based_effects")
                processingTypes.insert("time_processing")

            // Distortion and Saturation
            case "distortion", "saturation", "overdrive", "tube", "amp", "fuzz", "clipping":
                capabilities.insert("distortion_saturation")
                processingTypes.insert("harmonic_processing")

            // Spatial Processing
            case "stereo", "mono", "imager", "widener", "pan", "balance", "surround", "binaural":
                capabilities.insert("spatial_processing")
                processingTypes.insert("spatial_processing")

            // Restoration
            case "denoiser", "de-esser", "declipper", "restoration", "noise", "cleanup":
                capabilities.insert("restoration")
                processingTypes.insert("restoration_processing")

            // Analysis Tools
            case "analyzer", "spectrum", "meter", "scope", "visual", "measurement":
                capabilities.insert("analysis")
                processingTypes.insert("analysis_tools")

            // Utility
            case "utility", "gain", "volume", "mute", "bypass", "routing":
                capabilities.insert("utility")
                processingTypes.insert("utility_tools")

            default:
                if feature.contains("vintage") || feature.contains("analog") {
                    capabilities.insert("vintage_character")
                }
                if feature.contains("digital") {
                    capabilities.insert("digital_precision")
                }
            }
        }

        // Determine signal types from category and description
        if plugin.category?.lowercased().contains("vocal") == true ||
           plugin.description.lowercased().contains("vocal") ||
           plugin.tags.contains(where: { $0.lowercased().contains("vocal") }) {
            signalTypes.insert("vocal")
        }

        if plugin.category?.lowercased().contains("drum") == true ||
           plugin.description.lowercased().contains("drum") ||
           plugin.tags.contains(where: { $0.lowercased().contains("drum") }) {
            signalTypes.insert("drums")
        }

        if plugin.category?.lowercased().contains("bass") == true ||
           plugin.description.lowercased().contains("bass") ||
           plugin.tags.contains(where: { $0.lowercased().contains("bass") }) {
            signalTypes.insert("bass")
        }

        if plugin.category?.lowercased().contains("master") == true ||
           plugin.description.lowercased().contains("master") ||
           plugin.tags.contains(where: { $0.lowercased().contains("master") }) {
            signalTypes.insert("mastering")
        }

        if plugin.category?.lowercased().contains("mix") == true ||
           plugin.description.lowercased().contains("mix") ||
           plugin.tags.contains(where: { $0.lowercased().contains("mix") }) {
            signalTypes.insert("mixing")
        }

        return PluginFeatureAnalysis(
            capabilities: Array(capabilities).sorted(),
            processingTypes: Array(processingTypes).sorted(),
            signalTypes: Array(signalTypes).sorted(),
            featureDensity: calculateFeatureDensity(features: Array(features)),
            complexity: calculateComplexity(features: Array(features))
        )
    }

    /// Compare two plugins agnostically
    public static func comparePlugins(_ plugin1: CatalogSummarizationTool.PluginItem, _ plugin2: CatalogSummarizationTool.PluginItem) -> PluginComparison {
        let analysis1 = analyzePluginFeatures(plugin1)
        let analysis2 = analyzePluginFeatures(plugin2)

        let capabilities1 = Set(analysis1.capabilities)
        let capabilities2 = Set(analysis2.capabilities)
        let commonCapabilities = capabilities1.intersection(capabilities2)
        let uniqueCapabilities1 = capabilities1.subtracting(capabilities2)
        let uniqueCapabilities2 = capabilities2.subtracting(capabilities1)

        let similarityScore = calculateSimilarityScore(analysis1, analysis2)

        return PluginComparison(
            similarityScore: similarityScore,
            commonCapabilities: Array(commonCapabilities).sorted(),
            uniqueCapabilities1: Array(uniqueCapabilities1).sorted(),
            uniqueCapabilities2: Array(uniqueCapabilities2).sorted(),
            recommendation: generateComparisonRecommendation(plugin1, plugin2, similarity: similarityScore)
        )
    }

    /// Generate vendor-neutral plugin recommendations
    public static func generateRecommendations(
        for plugin: CatalogSummarizationTool.PluginItem,
        from alternatives: [CatalogSummarizationTool.PluginItem]
    ) -> [PluginRecommendation] {
        let targetAnalysis = analyzePluginFeatures(plugin)
        var recommendations: [PluginRecommendation] = []

        for alternative in alternatives {
            let alternativeAnalysis = analyzePluginFeatures(alternative)
            let similarity = calculateSimilarityScore(targetAnalysis, alternativeAnalysis)
            let compatibilityScore = calculateCompatibilityScore(targetAnalysis, alternativeAnalysis)

            if similarity > 0.3 { // Only include reasonably similar alternatives
                let recommendation = PluginRecommendation(
                    plugin: alternative,
                    similarityScore: similarity,
                    compatibilityScore: compatibilityScore,
                    reasons: generateRecommendationReasons(targetAnalysis, alternativeAnalysis, similarity: similarity),
                    useCaseAlignment: calculateUseCaseAlignment(targetAnalysis, alternativeAnalysis)
                )
                recommendations.append(recommendation)
            }
        }

        return recommendations.sorted { $0.similarityScore > $1.similarityScore }
    }

    // MARK: - Private Helper Methods

    private static func extractFeaturesFromDescription(_ description: String) -> [String] {
        let featureKeywords = [
            "compressor", "eq", "equalizer", "reverb", "delay", "chorus", "phaser", "flanger",
            "distortion", "saturation", "limiter", "gate", "expander", "multiband", "stereo",
            "analog", "digital", "vintage", "modern", "tube", "solid-state", "parametric",
            "graphic", "shelf", "bypass", "automation", "midi", "sidechain", "parallel"
        ]

        let lowercaseDescription = description.lowercased()
        var extractedFeatures: [String] = []

        for keyword in featureKeywords {
            if lowercaseDescription.contains(keyword) {
                extractedFeatures.append(keyword)
            }
        }

        return extractedFeatures
    }

    private static func calculateFeatureDensity(features: [String]) -> Double {
        return Double(features.count) / 20.0 // Normalize to 0-1 range
    }

    private static func calculateComplexity(features: [String]) -> String {
        let complexityKeywords = [
            "multiband", "parallel", "sidechain", "automation", "mid-side", "dynamic"
        ]

        let complexityScore = features.filter { feature in
            complexityKeywords.contains { keyword in
                feature.lowercased().contains(keyword)
            }
        }.count

        switch complexityScore {
        case 0...1:
            return "simple"
        case 2...3:
            return "moderate"
        default:
            return "advanced"
        }
    }

    private static func calculateSimilarityScore(_ analysis1: PluginFeatureAnalysis, _ analysis2: PluginFeatureAnalysis) -> Double {
        let capabilities1 = Set(analysis1.capabilities)
        let capabilities2 = Set(analysis2.capabilities)

        let intersection = capabilities1.intersection(capabilities2)
        let union = capabilities1.union(capabilities2)

        if union.isEmpty {
            return 0.0
        }

        let jaccardSimilarity = Double(intersection.count) / Double(union.count)

        // Adjust for feature density and complexity similarity
        let densitySimilarity = 1.0 - abs(analysis1.featureDensity - analysis2.featureDensity)

        // Weighted average
        return (jaccardSimilarity * 0.7) + (densitySimilarity * 0.3)
    }

    private static func calculateCompatibilityScore(_ analysis1: PluginFeatureAnalysis, _ analysis2: PluginFeatureAnalysis) -> Double {
        let processingTypes1 = Set(analysis1.processingTypes)
        let processingTypes2 = Set(analysis2.processingTypes)

        let commonProcessing = processingTypes1.intersection(processingTypes2)
        let allProcessing = processingTypes1.union(processingTypes2)

        if allProcessing.isEmpty {
            return 0.0
        }

        return Double(commonProcessing.count) / Double(allProcessing.count)
    }

    private static func generateComparisonRecommendation(
        _ plugin1: CatalogSummarizationTool.PluginItem,
        _ plugin2: CatalogSummarizationTool.PluginItem,
        similarity: Double
    ) -> String {
        switch similarity {
        case 0.8...1.0:
            return "Very similar - can be used interchangeably in most scenarios"
        case 0.6..<0.8:
            return "Similar - good alternatives with minor differences"
        case 0.4..<0.6:
            return "Moderately similar - different approaches to similar problems"
        case 0.2..<0.4:
            return "Somewhat related - different tools for related tasks"
        default:
            return "Different - serve different purposes"
        }
    }

    private static func generateRecommendationReasons(
        _ target: PluginFeatureAnalysis,
        _ alternative: PluginFeatureAnalysis,
        similarity: Double
    ) -> [String] {
        var reasons: [String] = []

        switch similarity {
        case 0.8...1.0:
            reasons.append("Nearly identical functionality")
            reasons.append("High compatibility")
        case 0.6..<0.8:
            reasons.append("Strong feature overlap")
            reasons.append("Good alternative choice")
        case 0.4..<0.6:
            reasons.append("Similar capabilities")
            reasons.append("Consider for different workflow")
        case 0.2..<0.4:
            reasons.append("Related functionality")
            reasons.append("Different approach to similar problem")
        default:
            reasons.append("Complementary tool")
        }

        return reasons
    }

    private static func calculateUseCaseAlignment(_ target: PluginFeatureAnalysis, _ alternative: PluginFeatureAnalysis) -> String {
        let targetSignalTypes = Set(target.signalTypes)
        let alternativeSignalTypes = Set(alternative.signalTypes)

        let alignment = targetSignalTypes.intersection(alternativeSignalTypes)

        if !alignment.isEmpty {
            return "excellent"
        } else if let firstProcessingType = alternative.processingTypes.first, target.processingTypes.contains(firstProcessingType) {
            return "good"
        } else {
            return "complementary"
        }
    }
}

// MARK: - Supporting Types

public struct PluginFeatureAnalysis: Codable, Sendable {
    let capabilities: [String]
    let processingTypes: [String]
    let signalTypes: [String]
    let featureDensity: Double
    let complexity: String

    public init(
        capabilities: [String],
        processingTypes: [String],
        signalTypes: [String],
        featureDensity: Double,
        complexity: String
    ) {
        self.capabilities = capabilities
        self.processingTypes = processingTypes
        self.signalTypes = signalTypes
        self.featureDensity = featureDensity
        self.complexity = complexity
    }
}

public struct PluginComparison: Codable, Sendable {
    let similarityScore: Double
    let commonCapabilities: [String]
    let uniqueCapabilities1: [String]
    let uniqueCapabilities2: [String]
    let recommendation: String

    public init(
        similarityScore: Double,
        commonCapabilities: [String],
        uniqueCapabilities1: [String],
        uniqueCapabilities2: [String],
        recommendation: String
    ) {
        self.similarityScore = similarityScore
        self.commonCapabilities = commonCapabilities
        self.uniqueCapabilities1 = uniqueCapabilities1
        self.uniqueCapabilities2 = uniqueCapabilities2
        self.recommendation = recommendation
    }
}

public struct PluginRecommendation: Codable, Sendable {
    let plugin: CatalogSummarizationTool.PluginItem
    let similarityScore: Double
    let compatibilityScore: Double
    let reasons: [String]
    let useCaseAlignment: String

    public init(
        plugin: CatalogSummarizationTool.PluginItem,
        similarityScore: Double,
        compatibilityScore: Double,
        reasons: [String],
        useCaseAlignment: String
    ) {
        self.plugin = plugin
        self.similarityScore = similarityScore
        self.compatibilityScore = compatibilityScore
        self.reasons = reasons
        self.useCaseAlignment = useCaseAlignment
    }
}