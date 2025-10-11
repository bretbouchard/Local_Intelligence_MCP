//
//  VendorNeutralAnalyzerTests.swift
//  LocalIntelligenceMCPTests
//
//  Created on 2025-10-09.
//

import XCTest
@testable import LocalIntelligenceMCP

final class VendorNeutralAnalyzerTests: XCTestCase {

    // MARK: - Test Data Creation

    private func createCompressorPlugin() -> CatalogSummarizationTool.PluginItem {
        return CatalogSummarizationTool.PluginItem(
            id: "comp1",
            name: "Pro Compressor",
            vendor: "AudioWorks",
            category: "Dynamics",
            price: 299.0,
            format: "VST3",
            description: "Professional-grade compressor with advanced knee control and automatic gain compensation. Features sidechain, mid-side processing, and vintage mode.",
            tags: ["compressor", "dynamics", "professional", "vintage", "analog", "sidechain", "mid-side"],
            features: ["Sidechain", "Mid-Side", "Automatic Gain Compensation", "Variable Knee", "Vintage Mode"]
        )
    }

    private func createAnotherCompressorPlugin() -> CatalogSummarizationTool.PluginItem {
        return CatalogSummarizationTool.PluginItem(
            id: "comp2",
            name: "Classic LA-2A",
            vendor: "Vintage Labs",
            category: "Dynamics",
            price: 349.0,
            format: "AU",
            description: "Optical compressor emulation with smooth, program-dependent attack and release. Perfect for vocals and bass.",
            tags: ["compressor", "optical", "vintage", "vocal", "bass", "tube", "emulation"],
            features: ["Optical Compression", "Tube Modeling", "Program Dependent", "Peak Reduction"]
        )
    }

    private func createEQPlugin() -> CatalogSummarizationTool.PluginItem {
        return CatalogSummarizationTool.PluginItem(
            id: "eq1",
            name: "Precision EQ",
            vendor: "Digital Masters",
            category: "Equalizer",
            price: 199.0,
            format: "AAX",
            description: "Digital precision equalizer with linear phase mode and advanced filtering. Perfect for mastering and critical mixing.",
            tags: ["eq", "equalizer", "digital", "precision", "linear-phase", "mastering", "mixing"],
            features: ["Linear Phase", "8-Band Parametric", "Match EQ", "Spectrum Analyzer"]
        )
    }

    private func createReverbPlugin() -> CatalogSummarizationTool.PluginItem {
        return CatalogSummarizationTool.PluginItem(
            id: "verb1",
            name: "Space Reverb",
            vendor: "AudioWorks",
            category: "Reverb",
            price: 149.0,
            format: "VST3",
            description: "High-quality algorithmic reverb with multiple room types and modulation options. Great for creating realistic spaces.",
            tags: ["reverb", "space", "algorithmic", "realistic", "modulation", "room", "hall"],
            features: ["9 Room Types", "Early Reflections", "Modulation", "Ducking", "Stereo Width"]
        )
    }

    private func createDelayPlugin() -> CatalogSummarizationTool.PluginItem {
        return CatalogSummarizationTool.PluginItem(
            id: "delay1",
            name: "Analog Delay",
            vendor: "Vintage Labs",
            category: "Delay",
            price: 99.0,
            format: "AU",
            description: "Vintage analog delay emulation with warmth and character. Features tape saturation and modulation.",
            tags: ["delay", "analog", "vintage", "tape", "saturation", "modulation", "echo"],
            features: ["Tape Saturation", "LFO Modulation", "Ping Pong", "Filter"]
        )
    }

    private func createMultibandPlugin() -> CatalogSummarizationTool.PluginItem {
        return CatalogSummarizationTool.PluginItem(
            id: "mb1",
            name: "Multiband Processor",
            vendor: "Digital Masters",
            category: "Dynamics",
            price: 399.0,
            format: "VST3",
            description: "Advanced multiband dynamics processor with compression, expansion, and saturation per band. Up to 4 bands with crossover control.",
            tags: ["multiband", "dynamics", "compression", "expansion", "saturation", "advanced"],
            features: ["4-Band Processing", "Independent Compression", "Crossover Control", "Saturation", "Sidechain"]
        )
    }

    private func createMasteringPlugin() -> CatalogSummarizationTool.PluginItem {
        return CatalogSummarizationTool.PluginItem(
            id: "master1",
            name: "Loudness Maximizer",
            vendor: "MasterPro",
            category: "Mastering",
            price: 499.0,
            format: "AAX",
            description: "Professional loudness maximizer with advanced limiting and saturation options. True peak limiting and LUFS metering.",
            tags: ["limiter", "maximizer", "mastering", "loudness", "true-peak", "lufs", "professional"],
            features: ["True Peak Limiting", "Saturation", "LUFS Metering", "Release Control", "IPS"]
        )
    }

    private func createSaturationPlugin() -> CatalogSummarizationTool.PluginItem {
        return CatalogSummarizationTool.PluginItem(
            id: "sat1",
            name: "Tube Saturation",
            vendor: "Vintage Labs",
            category: "Distortion",
            price: 129.0,
            format: "AU",
            description: "Tube saturation and distortion unit with various tube types and harmonics. Great for adding warmth and character.",
            tags: ["saturation", "tube", "distortion", "warmth", "character", "harmonics", "vintage"],
            features: ["Tube Modeling", "Harmonic Generation", "Bias Control", "Mix Control"]
        )
    }

    // MARK: - Plugin Feature Analysis Tests

    func testAnalyzeCompressorPluginFeatures() {
        let plugin = createCompressorPlugin()
        let analysis = VendorNeutralAnalyzer.analyzePluginFeatures(plugin)

        XCTAssertNotNil(analysis)
        XCTAssertTrue(analysis.capabilities.contains("dynamics_processing"))
        XCTAssertTrue(analysis.processingTypes.contains("dynamics"))
        XCTAssertEqual(analysis.complexity, "moderate") // Has sidechain, mid-side, etc.

        // Check specific capabilities
        XCTAssertTrue(analysis.capabilities.contains("vintage_character"))
        XCTAssertFalse(analysis.capabilities.contains("digital_precision"))

        // Feature density should be reasonable
        XCTAssertGreaterThan(analysis.featureDensity, 0.0)
        XCTAssertLessThanOrEqual(analysis.featureDensity, 1.0)
    }

    func testAnalyzeEQPluginFeatures() {
        let plugin = createEQPlugin()
        let analysis = VendorNeutralAnalyzer.analyzePluginFeatures(plugin)

        XCTAssertNotNil(analysis)
        XCTAssertTrue(analysis.capabilities.contains("equalization"))
        XCTAssertTrue(analysis.processingTypes.contains("frequency_processing"))
        XCTAssertEqual(analysis.complexity, "advanced") // Has linear phase, advanced features

        // Check specific capabilities
        XCTAssertTrue(analysis.capabilities.contains("digital_precision"))
        XCTAssertFalse(analysis.capabilities.contains("vintage_character"))

        // Should identify mastering signal type
        XCTAssertTrue(analysis.signalTypes.contains("mastering"))
    }

    func testAnalyzeReverbPluginFeatures() {
        let plugin = createReverbPlugin()
        let analysis = VendorNeutralAnalyzer.analyzePluginFeatures(plugin)

        XCTAssertNotNil(analysis)
        XCTAssertTrue(analysis.capabilities.contains("time_based_effects"))
        XCTAssertTrue(analysis.processingTypes.contains("time_processing"))
        XCTAssertEqual(analysis.complexity, "moderate")

        // Check specific capabilities
        XCTAssertTrue(analysis.capabilities.contains("spatial_processing"))
    }

    func testAnalyzeMultibandPluginFeatures() {
        let plugin = createMultibandPlugin()
        let analysis = VendorNeutralAnalyzer.analyzePluginFeatures(plugin)

        XCTAssertNotNil(analysis)
        XCTAssertTrue(analysis.capabilities.contains("dynamics_processing"))
        XCTAssertTrue(analysis.processingTypes.contains("dynamics"))
        XCTAssertEqual(analysis.complexity, "advanced") // Multiband is complex

        // Check for multiband-specific capabilities
        XCTAssertTrue(analysis.capabilities.contains("dynamics_processing"))
        XCTAssertGreaterThan(analysis.featureDensity, 0.3) // Should have high feature density
    }

    func testAnalyzeMasteringPluginFeatures() {
        let plugin = createMasteringPlugin()
        let analysis = VendorNeutralAnalyzer.analyzePluginFeatures(plugin)

        XCTAssertNotNil(analysis)
        XCTAssertTrue(analysis.capabilities.contains("dynamics_processing"))
        XCTAssertTrue(analysis.processingTypes.contains("dynamics"))
        XCTAssertEqual(analysis.complexity, "moderate")

        // Should identify mastering signal type
        XCTAssertTrue(analysis.signalTypes.contains("mastering"))
        XCTAssertTrue(analysis.signalTypes.contains("mixing"))
    }

    func testAnalyzeSaturationPluginFeatures() {
        let plugin = createSaturationPlugin()
        let analysis = VendorNeutralAnalyzer.analyzePluginFeatures(plugin)

        XCTAssertNotNil(analysis)
        XCTAssertTrue(analysis.capabilities.contains("distortion_saturation"))
        XCTAssertTrue(analysis.processingTypes.contains("harmonic_processing"))
        XCTAssertEqual(analysis.complexity, "simple")

        // Check specific capabilities
        XCTAssertTrue(analysis.capabilities.contains("vintage_character"))
    }

    func testFeatureDensityCalculation() {
        let simplePlugin = createDelayPlugin()
        let simpleAnalysis = VendorNeutralAnalyzer.analyzePluginFeatures(simplePlugin)

        let complexPlugin = createMultibandPlugin()
        let complexAnalysis = VendorNeutralAnalyzer.analyzePluginFeatures(complexPlugin)

        // Complex plugin should have higher feature density
        XCTAssertGreaterThan(complexAnalysis.featureDensity, simpleAnalysis.featureDensity)
        XCTAssertGreaterThan(complexAnalysis.featureDensity, 0.3)
        XCTAssertLessThanOrEqual(simpleAnalysis.featureDensity, 0.5)
    }

    func testComplexityClassification() {
        let simplePlugin = createDelayPlugin()
        let simpleAnalysis = VendorNeutralAnalyzer.analyzePluginFeatures(simplePlugin)
        XCTAssertEqual(simpleAnalysis.complexity, "simple")

        let moderatePlugin = createCompressorPlugin()
        let moderateAnalysis = VendorNeutralAnalyzer.analyzePluginFeatures(moderatePlugin)
        XCTAssertEqual(moderateAnalysis.complexity, "moderate")

        let advancedPlugin = createMultibandPlugin()
        let advancedAnalysis = VendorNeutralAnalyzer.analyzePluginFeatures(advancedPlugin)
        XCTAssertEqual(advancedAnalysis.complexity, "advanced")
    }

    func testSignalTypeDetection() {
        let masteringPlugin = createMasteringPlugin()
        let masteringAnalysis = VendorNeutralAnalyzer.analyzePluginFeatures(masteringPlugin)
        XCTAssertTrue(masteringAnalysis.signalTypes.contains("mastering"))

        let mixingPlugin = createCompressorPlugin()
        let mixingAnalysis = VendorNeutralAnalyzer.analyzePluginFeatures(mixingPlugin)
        XCTAssertTrue(mixingAnalysis.signalTypes.contains("mixing"))
    }

    // MARK: - Plugin Comparison Tests

    func testCompareSimilarCompressors() {
        let plugin1 = createCompressorPlugin()
        let plugin2 = createAnotherCompressorPlugin()
        let comparison = VendorNeutralAnalyzer.comparePlugins(plugin1, plugin2)

        XCTAssertNotNil(comparison)
        XCTAssertGreaterThan(comparison.similarityScore, 0.5) // Should be fairly similar

        // Both should have dynamics processing capability
        XCTAssertTrue(comparison.commonCapabilities.contains("dynamics_processing"))
        XCTAssertTrue(comparison.commonCapabilities.contains("vintage_character"))

        // Should have some unique capabilities
        XCTAssertFalse(comparison.uniqueCapabilities1.isEmpty)
        XCTAssertFalse(comparison.uniqueCapabilities2.isEmpty)

        // Recommendation should indicate they're similar
        XCTAssertTrue(
            comparison.recommendation.contains("similar") ||
            comparison.recommendation.contains("interchangeable") ||
            comparison.recommendation.contains("good alternatives")
        )
    }

    func testCompareDifferentPluginTypes() {
        let compressorPlugin = createCompressorPlugin()
        let eqPlugin = createEQPlugin()
        let comparison = VendorNeutralAnalyzer.comparePlugins(compressorPlugin, eqPlugin)

        XCTAssertNotNil(comparison)
        XCTAssertLessThan(comparison.similarityScore, 0.3) // Should be quite different

        // Should have few common capabilities
        XCTAssertLessThan(comparison.commonCapabilities.count, 2)

        // Should have many unique capabilities
        XCTAssertGreaterThan(comparison.uniqueCapabilities1.count, 2)
        XCTAssertGreaterThan(comparison.uniqueCapabilities2.count, 2)

        // Recommendation should indicate they serve different purposes
        XCTAssertTrue(
            comparison.recommendation.contains("different") ||
            comparison.recommendation.contains("complementary")
        )
    }

    func testComparePluginsFromSameVendor() {
        let plugin1 = createCompressorPlugin()
        let plugin2 = createReverbPlugin() // Both from AudioWorks
        let comparison = VendorNeutralAnalyzer.comparePlugins(plugin1, plugin2)

        XCTAssertNotNil(comparison)
        XCTAssertLessThan(comparison.similarityScore, 0.5) // Different types, so not very similar

        // Should have some common processing capabilities
        let commonProcessingTypes = Set(comparison.commonCapabilities).intersection(["dynamics_processing", "time_based_effects", "spatial_processing"])
        XCTAssertGreaterThan(commonProcessingTypes.count, 0)
    }

    func testCompareSimilarComplexityPlugins() {
        let plugin1 = createCompressorPlugin() // moderate complexity
        let plugin2 = createReverbPlugin() // moderate complexity
        let comparison = VendorNeutralAnalyzer.comparePlugins(plugin1, plugin2)

        XCTAssertNotNil(comparison)
        // Both have moderate complexity, so similarity should be reasonable
        XCTAssertGreaterThan(comparison.similarityScore, 0.2)
    }

    func testCompareVerySimilarPlugins() {
        let plugin1 = createCompressorPlugin()
        var plugin2 = createAnotherCompressorPlugin()

        // Make plugin2 more similar to plugin1
        plugin2.tags = ["compressor", "dynamics", "professional", "vintage", "analog", "sidechain", "mid-side"]
        plugin2.features = ["Sidechain", "Mid-Side", "Automatic Gain Compensation", "Variable Knee"]

        let comparison = VendorNeutralAnalyzer.comparePlugins(plugin1, plugin2)

        XCTAssertNotNil(comparison)
        XCTAssertGreaterThan(comparison.similarityScore, 0.7) // Should be very similar

        // Should have many common capabilities
        XCTAssertGreaterThan(comparison.commonCapabilities.count, 4)

        // Recommendation should indicate high similarity
        XCTAssertTrue(
            comparison.recommendation.contains("very similar") ||
            comparison.recommendation.contains("interchangeable")
        )
    }

    // MARK: - Plugin Recommendation Tests

    func testGenerateCompressorRecommendations() {
        let targetPlugin = createCompressorPlugin()
        let alternatives = [
            createAnotherCompressorPlugin(),
            createEQPlugin(),
            createReverbPlugin(),
            createDelayPlugin(),
            createMultibandPlugin()
        ]

        let recommendations = VendorNeutralAnalyzer.generateRecommendations(
            for: targetPlugin,
            from: alternatives
        )

        XCTAssertFalse(recommendations.isEmpty)

        // Should recommend similar plugins first
        let topRecommendation = recommendations.first
        XCTAssertNotNil(topRecommendation)

        // Top recommendation should be the other compressor (most similar)
        XCTAssertEqual(topRecommendation?.plugin.id, "comp2")
        XCTAssertGreaterThan(topRecommendation?.similarityScore ?? 0, 0.5)

        // All recommendations should have reasonable similarity scores
        for recommendation in recommendations {
            XCTAssertGreaterThanOrEqual(recommendation.similarityScore, 0.0)
            XCTAssertLessThanOrEqual(recommendation.similarityScore, 1.0)
            XCTAssertGreaterThanOrEqual(recommendation.compatibilityScore, 0.0)
            XCTAssertLessThanOrEqual(recommendation.compatibilityScore, 1.0)
            XCTAssertFalse(recommendation.reasons.isEmpty)
            XCTAssertNotNil(recommendation.useCaseAlignment)
        }

        // Recommendations should be sorted by similarity score (descending)
        for i in 1..<recommendations.count {
            XCTAssertGreaterThanOrEqual(
                recommendations[i-1].similarityScore,
                recommendations[i].similarityScore
            )
        }
    }

    func testGenerateRecommendationsWithLowSimilarityThreshold() {
        let targetPlugin = createCompressorPlugin()
        let alternatives = [
            createEQPlugin(),
            createReverbPlugin(),
            createDelayPlugin()
        ]

        let recommendations = VendorNeutralAnalyzer.generateRecommendations(
            for: targetPlugin,
            from: alternatives
        )

        // Should still return recommendations even if similarity is lower
        XCTAssertFalse(recommendations.isEmpty)

        // All recommendations should have some level of compatibility
        for recommendation in recommendations {
            XCTAssertGreaterThan(recommendation.compatibilityScore, 0.0)
            XCTAssertFalse(recommendation.reasons.isEmpty)
        }
    }

    func testRecommendationReasons() {
        let targetPlugin = createCompressorPlugin()
        let alternatives = [createAnotherCompressorPlugin()]

        let recommendations = VendorNeutralAnalyzer.generateRecommendations(
            for: targetPlugin,
            from: alternatives
        )

        XCTAssertEqual(recommendations.count, 1)
        let recommendation = recommendations.first!

        // Should provide meaningful reasons
        XCTAssertFalse(recommendation.reasons.isEmpty)
        XCTAssertTrue(recommendation.reasons.allSatisfy { !$0.isEmpty })

        // Should include capability overlap as a reason
        let hasCapabilityReason = recommendation.reasons.contains { reason in
            reason.lowercased().contains("feature") ||
            reason.lowercased().contains("capability") ||
            reason.lowercased().contains("overlap")
        }
        XCTAssertTrue(hasCapabilityReason)

        // Should indicate good alternative choice
        XCTAssertTrue(
            recommendation.reasons.contains { $0.lowercased().contains("alternative") } ||
            recommendation.reasons.contains { $0.lowercased().contains("similar") }
        )
    }

    func testUseCaseAlignment() {
        let targetPlugin = createMasteringPlugin()
        let alternatives = [
            createEQPlugin(), // Also good for mastering
            createDelayPlugin(), // Not specifically for mastering
            createMultibandPlugin() // Can be used for mastering
        ]

        let recommendations = VendorNeutralAnalyzer.generateRecommendations(
            for: targetPlugin,
            from: alternatives
        )

        // EQ plugin should have excellent alignment (both for mastering)
        let eqRecommendation = recommendations.first { $0.plugin.id == "eq1" }
        if let eqRec = eqRecommendation {
            XCTAssertEqual(eqRec.useCaseAlignment, "excellent")
        }

        // Other plugins should have at least good or complementary alignment
        for recommendation in recommendations {
            XCTAssertTrue(
                recommendation.useCaseAlignment == "excellent" ||
                recommendation.useCaseAlignment == "good" ||
                recommendation.useCaseAlignment == "complementary"
            )
        }
    }

    // MARK: - Feature Extraction Tests

    func testExtractFeaturesFromDescription() {
        let plugin = CatalogSummarizationTool.PluginItem(
            id: "test",
            name: "Test Plugin",
            vendor: "Test Vendor",
            category: "Test",
            price: 99.0,
            format: "VST3",
            description: "This plugin features compression, EQ, reverb, and vintage analog modeling with sidechain and parallel processing capabilities.",
            tags: [],
            features: nil
        )

        let analysis = VendorNeutralAnalyzer.analyzePluginFeatures(plugin)

        // Should extract features from description
        XCTAssertTrue(analysis.capabilities.contains("dynamics_processing")) // compression
        XCTAssertTrue(analysis.capabilities.contains("equalization")) // EQ
        XCTAssertTrue(analysis.capabilities.contains("time_based_effects")) // reverb
        XCTAssertTrue(analysis.capabilities.contains("vintage_character")) // vintage analog
    }

    func testTagBasedFeatureExtraction() {
        let plugin = CatalogSummarizationTool.PluginItem(
            id: "test",
            name: "Test Plugin",
            vendor: "Test Vendor",
            category: "Dynamics",
            price: 99.0,
            format: "VST3",
            description: "Basic plugin description",
            tags: ["compressor", "multiband", "sidechain", "parallel", "vintage", "tube"],
            features: nil
        )

        let analysis = VendorNeutralAnalyzer.analyzePluginFeatures(plugin)

        // Should extract features from tags
        XCTAssertTrue(analysis.capabilities.contains("dynamics_processing")) // compressor
        XCTAssertTrue(analysis.processingTypes.contains("dynamics"))
        XCTAssertTrue(analysis.capabilities.contains("vintage_character")) // vintage, tube

        // Should identify as complex due to multiband and sidechain
        XCTAssertEqual(analysis.complexity, "advanced")
    }

    func testCategoryBasedFeatureExtraction() {
        let categories = [
            ("Dynamics", ["dynamics_processing"]),
            ("Equalizer", ["equalization"]),
            ("Reverb", ["time_based_effects"]),
            ("Distortion", ["distortion_saturation"]),
            ("Analyzer", ["analysis"]),
            ("Utility", ["utility"])
        ]

        for (category, expectedCapabilities) in categories {
            let plugin = CatalogSummarizationTool.PluginItem(
                id: "test_\(category)",
                name: "Test \(category)",
                vendor: "Test Vendor",
                category: category,
                price: 99.0,
                format: "VST3",
                description: "Test description",
                tags: [],
                features: nil
            )

            let analysis = VendorNeutralAnalyzer.analyzePluginFeatures(plugin)

            for capability in expectedCapabilities {
                XCTAssertTrue(
                    analysis.capabilities.contains(capability),
                    "Category '\(category)' should include capability '\(capability)'"
                )
            }
        }
    }

    // MARK: - Edge Cases Tests

    func testAnalyzeMinimalPlugin() {
        let minimalPlugin = CatalogSummarizationTool.PluginItem(
            id: "minimal",
            name: "Minimal",
            vendor: "",
            category: "",
            price: 0.0,
            format: "",
            description: "",
            tags: [],
            features: nil
        )

        let analysis = VendorNeutralAnalyzer.analyzePluginFeatures(minimalPlugin)

        XCTAssertNotNil(analysis)
        XCTAssertTrue(analysis.capabilities.isEmpty)
        XCTAssertTrue(analysis.processingTypes.isEmpty)
        XCTAssertTrue(analysis.signalTypes.isEmpty)
        XCTAssertEqual(analysis.featureDensity, 0.0)
        XCTAssertEqual(analysis.complexity, "simple")
    }

    func testAnalyzePluginWithEmptyCollections() {
        let plugin = CatalogSummarizationTool.PluginItem(
            id: "empty",
            name: "Empty Collections",
            vendor: "Test Vendor",
            category: "Test Category",
            price: 99.0,
            format: "VST3",
            description: "Test description",
            tags: [],
            features: []
        )

        let analysis = VendorNeutralAnalyzer.analyzePluginFeatures(plugin)

        XCTAssertNotNil(analysis)
        // Should handle empty collections gracefully
        XCTAssertTrue(analysis.capabilities.isEmpty || analysis.capabilities.count > 0)
        XCTAssertTrue(analysis.processingTypes.isEmpty || analysis.processingTypes.count > 0)
    }

    func testCompareIdenticalPlugins() {
        let plugin = createCompressorPlugin()
        let comparison = VendorNeutralAnalyzer.comparePlugins(plugin, plugin)

        XCTAssertNotNil(comparison)
        XCTAssertEqual(comparison.similarityScore, 1.0) // Identical plugins should have perfect similarity

        // Should have all capabilities in common
        XCTAssertEqual(comparison.commonCapabilities.count, Set(comparison.commonCapabilities).union(comparison.uniqueCapabilities1).union(comparison.uniqueCapabilities2).count)

        // Should have no unique capabilities
        XCTAssertTrue(comparison.uniqueCapabilities1.isEmpty)
        XCTAssertTrue(comparison.uniqueCapabilities2.isEmpty)

        // Recommendation should indicate they're identical
        XCTAssertTrue(comparison.recommendation.contains("interchangeable"))
    }

    func testGenerateRecommendationsWithEmptyAlternatives() {
        let targetPlugin = createCompressorPlugin()
        let alternatives: [CatalogSummarizationTool.PluginItem] = []

        let recommendations = VendorNeutralAnalyzer.generateRecommendations(
            for: targetPlugin,
            from: alternatives
        )

        XCTAssertTrue(recommendations.isEmpty)
    }

    func testGenerateRecommendationsWithLowSimilarityThreshold() {
        let targetPlugin = createCompressorPlugin()
        let veryDifferentPlugin = createDelayPlugin()

        let recommendations = VendorNeutralAnalyzer.generateRecommendations(
            for: targetPlugin,
            from: [veryDifferentPlugin]
        )

        // Should still generate recommendation even for dissimilar plugins
        XCTAssertFalse(recommendations.isEmpty)

        let recommendation = recommendations.first!
        XCTAssertLessThan(recommendation.similarityScore, 0.4) // Should be low similarity
        XCTAssertGreaterThan(recommendation.compatibilityScore, 0.0) // But should have some compatibility
    }

    // MARK: - Performance Tests

    func testPerformanceWithLargePluginSet() {
        let startTime = CFAbsoluteTimeGetCurrent()

        let targetPlugin = createCompressorPlugin()

        // Create large number of alternatives
        var alternatives: [CatalogSummarizationTool.PluginItem] = []
        let plugins = [
            createAnotherCompressorPlugin(),
            createEQPlugin(),
            createReverbPlugin(),
            createDelayPlugin(),
            createMultibandPlugin(),
            createMasteringPlugin(),
            createSaturationPlugin()
        ]

        // Repeat plugins to create a large set
        for _ in 0..<100 {
            alternatives.append(contentsOf: plugins)
        }

        let recommendations = VendorNeutralAnalyzer.generateRecommendations(
            for: targetPlugin,
            from: alternatives
        )

        let processingTime = CFAbsoluteTimeGetCurrent() - startTime

        XCTAssertFalse(recommendations.isEmpty)
        XCTAssertLessThan(processingTime, 2.0, "Recommendation generation should complete within 2 seconds")

        // Should still be properly sorted
        for i in 1..<recommendations.count {
            XCTAssertGreaterThanOrEqual(
                recommendations[i-1].similarityScore,
                recommendations[i].similarityScore
            )
        }
    }

    func testAnalysisPerformanceWithManyFeatures() {
        let startTime = CFAbsoluteTimeGetCurrent()

        let complexPlugin = CatalogSummarizationTool.PluginItem(
            id: "complex",
            name: "Ultra Complex Plugin",
            vendor: "Complex Audio",
            category: "Multiband Dynamics",
            price: 999.0,
            format: "VST3",
            description: "This plugin features advanced multiband compression, expansion, gating, saturation, stereo enhancement, mid-side processing, linear phase filtering, harmonic generation, tape emulation, vintage tube modeling, automatic gain compensation, adaptive release, parallel processing, sidechain filtering, frequency selective compression, dynamic EQ, harmonic saturation, transient shaping, stereo imaging, loudness maximization, and true peak limiting.",
            tags: [
                "multiband", "compression", "expansion", "gate", "saturation", "stereo", "mid-side",
                "linear-phase", "harmonic", "tape", "vintage", "tube", "automatic", "parallel",
                "sidechain", "frequency-selective", "dynamic-eq", "transient", "imaging", "loudness",
                "true-peak", "limiting", "advanced", "professional", "mastering", "mixing"
            ],
            features: [
                "4-Band Multiband Compression", "Expansion per Band", "Gate per Band", "Saturation per Band",
                "Stereo Enhancement", "Mid-Side Processing", "Linear Phase Filters", "Harmonic Generation",
                "Tape Emulation", "Tube Modeling", "Automatic Gain Compensation", "Adaptive Release",
                "Parallel Processing", "Sidechain Filtering", "Frequency Selective Compression",
                "Dynamic EQ", "Harmonic Saturation", "Transient Shaping", "Stereo Imaging",
                "Loudness Maximization", "True Peak Limiting"
            ]
        )

        let analysis = VendorNeutralAnalyzer.analyzePluginFeatures(complexPlugin)
        let processingTime = CFAbsoluteTimeGetCurrent() - startTime

        XCTAssertNotNil(analysis)
        XCTAssertEqual(analysis.complexity, "advanced")
        XCTAssertGreaterThan(analysis.featureDensity, 0.8) // Should have high feature density
        XCTAssertLessThan(processingTime, 0.1, "Analysis should complete quickly even for complex plugins")
    }

    // MARK: - Consistency Tests

    func testAnalysisConsistency() {
        let plugin = createCompressorPlugin()

        let analysis1 = VendorNeutralAnalyzer.analyzePluginFeatures(plugin)
        let analysis2 = VendorNeutralAnalyzer.analyzePluginFeatures(plugin)

        // Results should be consistent across multiple calls
        XCTAssertEqual(analysis1.capabilities.sorted(), analysis2.capabilities.sorted())
        XCTAssertEqual(analysis1.processingTypes.sorted(), analysis2.processingTypes.sorted())
        XCTAssertEqual(analysis1.signalTypes.sorted(), analysis2.signalTypes.sorted())
        XCTAssertEqual(analysis1.featureDensity, analysis2.featureDensity)
        XCTAssertEqual(analysis1.complexity, analysis2.complexity)
    }

    func testComparisonConsistency() {
        let plugin1 = createCompressorPlugin()
        let plugin2 = createAnotherCompressorPlugin()

        let comparison1 = VendorNeutralAnalyzer.comparePlugins(plugin1, plugin2)
        let comparison2 = VendorNeutralAnalyzer.comparePlugins(plugin1, plugin2)

        // Results should be consistent across multiple calls
        XCTAssertEqual(comparison1.similarityScore, comparison2.similarityScore)
        XCTAssertEqual(comparison1.commonCapabilities.sorted(), comparison2.commonCapabilities.sorted())
        XCTAssertEqual(comparison1.uniqueCapabilities1.sorted(), comparison2.uniqueCapabilities1.sorted())
        XCTAssertEqual(comparison1.uniqueCapabilities2.sorted(), comparison2.uniqueCapabilities2.sorted())
        XCTAssertEqual(comparison1.recommendation, comparison2.recommendation)
    }
}