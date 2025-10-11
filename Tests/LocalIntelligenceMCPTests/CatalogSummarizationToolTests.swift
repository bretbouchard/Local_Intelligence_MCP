//
//  CatalogSummarizationToolTests.swift
//  LocalIntelligenceMCPTests
//
//  Created on 2025-10-09.
//

import XCTest
@testable import LocalIntelligenceMCP

final class CatalogSummarizationToolTests: XCTestCase {

    var catalogTool: CatalogSummarizationTool!

    override func setUp() {
        super.setUp()
        catalogTool = CatalogSummarizationTool()
    }

    override func tearDown() {
        catalogTool = nil
        super.tearDown()
    }

    // MARK: - Test Data Creation

    private func createTestPluginCatalog() -> CatalogSummarizationTool.PluginCatalog {
        let plugins = [
            CatalogSummarizationTool.PluginItem(
                id: "plugin1",
                name: "Pro Compressor",
                vendor: "AudioWorks",
                category: "Dynamics",
                price: 299.0,
                format: "VST3",
                description: "Professional-grade compressor with advanced knee control and automatic gain compensation.",
                tags: ["compressor", "dynamics", "professional", "vintage", "analog"],
                features: ["Sidechain", "Mid-Side", "Automatic Gain Compensation", "Variable Knee"]
            ),
            CatalogSummarizationTool.PluginItem(
                id: "plugin2",
                name: "Vintage EQ",
                vendor: "Analog Labs",
                category: "Equalizer",
                price: 199.0,
                format: "AU",
                description: "Classic analog-modeled equalizer with authentic transformer sound.",
                tags: ["eq", "equalizer", "vintage", "analog", "classic"],
                features: ["3-Band Parametric", "Transformer Saturation", "Vintage Mode"]
            ),
            CatalogSummarizationTool.PluginItem(
                id: "plugin3",
                name: "Space Reverb",
                vendor: "AudioWorks",
                category: "Reverb",
                price: 149.0,
                format: "VST3",
                description: "High-quality algorithmic reverb with multiple room types and modulation options.",
                tags: ["reverb", "space", "algorithmic", "modulation", "realistic"],
                features: ["9 Room Types", "Early Reflections", "Modulation", "Ducking"]
            ),
            CatalogSummarizationTool.PluginItem(
                id: "plugin4",
                name: "Loudness Maximizer",
                vendor: "MasterPro",
                category: "Mastering",
                price: 399.0,
                format: "AAX",
                description: "Professional loudness maximizer with advanced limiting and saturation options.",
                tags: ["limiter", "maximizer", "mastering", "loudness", "professional"],
                features: ["True Peak Limiting", "Saturation", "LUFS Metering", "Release Control"]
            ),
            CatalogSummarizationTool.PluginItem(
                id: "plugin5",
                name: "Free Delay",
                vendor: "OpenSource",
                category: "Delay",
                price: 0.0,
                format: "VST3",
                description: "Basic delay plugin with tap tempo and filtering options.",
                tags: ["delay", "free", "basic", "tempo", "filter"],
                features: ["Tap Tempo", "Low Pass Filter", "Ping Pong Mode"]
            ),
            CatalogSummarizationTool.PluginItem(
                id: "plugin6",
                name: "Channel Strip Pro",
                vendor: "Analog Labs",
                category: "Channel Strip",
                price: 249.0,
                format: "AU",
                description: "Complete channel strip with EQ, compression, and saturation.",
                tags: ["channel strip", "eq", "compressor", "saturation", "all-in-one"],
                features: ["4-Band EQ", "Compressor", "Gate", "Saturation"]
            )
        ]

        return CatalogSummarizationTool.PluginCatalog(
            name: "Test Plugin Catalog",
            plugins: plugins
        )
    }

    // MARK: - Plugin Overview Tests

    func testCalculatePluginOverview() {
        let catalog = createTestPluginCatalog()
        let overview = catalogTool.calculatePluginOverview(catalog.plugins)

        XCTAssertEqual(overview.totalPlugins, 6)
        XCTAssertEqual(overview.totalVendors, 3)
        XCTAssertEqual(overview.totalCategories, 5)
        XCTAssertEqual(overview.averagePrice, 215.66, accuracy: 0.01)
        XCTAssertEqual(overview.freePluginCount, 1)
        XCTAssertEqual(overview.priceRange.min, 0.0)
        XCTAssertEqual(overview.priceRange.max, 399.0)

        XCTAssertEqual(overview.vendorDistribution["AudioWorks"], 2)
        XCTAssertEqual(overview.vendorDistribution["Analog Labs"], 2)
        XCTAssertEqual(overview.vendorDistribution["MasterPro"], 1)
        XCTAssertEqual(overview.vendorDistribution["OpenSource"], 1)

        XCTAssertEqual(overview.categoryDistribution["Dynamics"], 1)
        XCTAssertEqual(overview.categoryDistribution["Equalizer"], 1)
        XCTAssertEqual(overview.categoryDistribution["Reverb"], 1)
        XCTAssertEqual(overview.categoryDistribution["Mastering"], 1)
        XCTAssertEqual(overview.categoryDistribution["Delay"], 1)
        XCTAssertEqual(overview.categoryDistribution["Channel Strip"], 1)

        XCTAssertEqual(overview.formatDistribution["VST3"], 3)
        XCTAssertEqual(overview.formatDistribution["AU"], 2)
        XCTAssertEqual(overview.formatDistribution["AAX"], 1)
    }

    func testCalculatePluginOverviewEmptyCatalog() {
        let overview = catalogTool.calculatePluginOverview([])

        XCTAssertEqual(overview.totalPlugins, 0)
        XCTAssertEqual(overview.totalVendors, 0)
        XCTAssertEqual(overview.totalCategories, 0)
        XCTAssertEqual(overview.averagePrice, 0.0, accuracy: 0.01)
        XCTAssertEqual(overview.freePluginCount, 0)
        XCTAssertEqual(overview.priceRange.min, 0.0)
        XCTAssertEqual(overview.priceRange.max, 0.0)
        XCTAssertTrue(overview.vendorDistribution.isEmpty)
        XCTAssertTrue(overview.categoryDistribution.isEmpty)
        XCTAssertTrue(overview.formatDistribution.isEmpty)
    }

    // MARK: - Clustering Tests

    func testClusterPluginsByCategory() {
        let catalog = createTestPluginCatalog()
        let clusters = catalogTool.clusterPluginsByCategory(catalog.plugins)

        XCTAssertEqual(clusters.count, 5)

        let dynamicsCluster = clusters.first { $0.name == "Dynamics" }
        XCTAssertNotNil(dynamicsCluster)
        XCTAssertEqual(dynamicsCluster?.plugins.count, 1)
        XCTAssertEqual(dynamicsCluster?.description, "Plugins for dynamic range processing including compression, limiting, and gating")

        let eqCluster = clusters.first { $0.name == "Equalizer" }
        XCTAssertNotNil(eqCluster)
        XCTAssertEqual(eqCluster?.plugins.count, 1)
        XCTAssertEqual(eqCluster?.description, "Equalizers for frequency balance and tonal shaping")
    }

    func testClusterPluginsByVendor() {
        let catalog = createTestPluginCatalog()
        let clusters = catalogTool.clusterPluginsByVendor(catalog.plugins)

        XCTAssertEqual(clusters.count, 3)

        let audioWorksCluster = clusters.first { $0.name == "AudioWorks" }
        XCTAssertNotNil(audioWorksCluster)
        XCTAssertEqual(audioWorksCluster?.plugins.count, 2)
        XCTAssertTrue(audioWorksCluster?.plugins.allSatisfy { $0.vendor == "AudioWorks" } == true)

        let analogLabsCluster = clusters.first { $0.name == "Analog Labs" }
        XCTAssertNotNil(analogLabsCluster)
        XCTAssertEqual(analogLabsCluster?.plugins.count, 2)
    }

    func testClusterPluginsByPriceRange() {
        let catalog = createTestPluginCatalog()
        let clusters = catalogTool.clusterPluginsByPriceRange(catalog.plugins)

        XCTAssertGreaterThanOrEqual(clusters.count, 2)

        let freeCluster = clusters.first { $0.name.contains("Free") }
        XCTAssertNotNil(freeCluster)
        XCTAssertEqual(freeCluster?.plugins.count, 1)
        XCTAssertEqual(freeCluster?.plugins.first?.price, 0.0)

        let budgetCluster = clusters.first { $0.name.contains("Budget") }
        if let budgetCluster = budgetCluster {
            XCTAssertTrue(budgetCluster.plugins.allSatisfy { $0.price > 0 && $0.price < 200 })
        }
    }

    func testClusterPluginsByCompatibility() {
        let catalog = createTestPluginCatalog()
        let clusters = catalogTool.clusterPluginsByCompatibility(catalog.plugins)

        XCTAssertEqual(clusters.count, 3)

        let vst3Cluster = clusters.first { $0.name == "VST3" }
        XCTAssertNotNil(vst3Cluster)
        XCTAssertEqual(vst3Cluster?.plugins.count, 3)
        XCTAssertTrue(vst3Cluster?.plugins.allSatisfy { $0.format == "VST3" } == true)

        let auCluster = clusters.first { $0.name == "AU" }
        XCTAssertNotNil(auCluster)
        XCTAssertEqual(auCluster?.plugins.count, 2)
    }

    func testClusterPluginsByFeatureSimilarity() {
        let catalog = createTestPluginCatalog()
        let clusters = catalogTool.clusterPluginsByFeatureSimilarity(catalog.plugins, threshold: 0.3)

        XCTAssertGreaterThanOrEqual(clusters.count, 1)

        // Should cluster plugins with similar features
        for cluster in clusters {
            if cluster.plugins.count > 1 {
                // Check that plugins in the same cluster have similar features
                let firstPluginFeatures = Set(cluster.plugins.first?.tags ?? [])
                for plugin in cluster.plugins {
                    let pluginFeatures = Set(plugin.tags)
                    let similarity = Double(firstPluginFeatures.intersection(pluginFeatures).count) / Double(firstPluginFeatures.union(pluginFeatures).count)
                    XCTAssertGreaterThanOrEqual(similarity, 0.3)
                }
            }
        }
    }

    func testClusterPluginsByUseCase() {
        let catalog = createTestPluginCatalog()
        let clusters = catalogTool.clusterPluginsByUseCase(catalog.plugins)

        XCTAssertGreaterThanOrEqual(clusters.count, 3)

        let masteringCluster = clusters.first { $0.name == "Mastering" }
        XCTAssertNotNil(masteringCluster)
        XCTAssertTrue(masteringCluster?.plugins.allSatisfy { plugin in
            plugin.category.lowercased().contains("master") ||
            plugin.tags.contains(where: { $0.lowercased().contains("master") }) ||
            plugin.description.lowercased().contains("master")
        } == true)

        let mixingCluster = clusters.first { $0.name == "Mixing" }
        XCTAssertNotNil(mixingCluster)
    }

    func testPerformHierarchicalClustering() {
        let catalog = createTestPluginCatalog()
        let clusters = catalogTool.performHierarchicalClustering(catalog.plugins, levels: 2)

        XCTAssertEqual(clusters.count, 2)

        // Should have at least top-level category clustering
        let categoryClusterNames = clusters.map { $0.name }
        XCTAssertTrue(categoryClusterNames.allSatisfy { $0.contains("Category") || $0.contains("Level") })

        // Each cluster should have plugins
        for cluster in clusters {
            XCTAssertGreaterThan(cluster.plugins.count, 0)
            XCTAssertGreaterThan(cluster.subclusters.count, 0)
        }
    }

    // MARK: - Metadata Tests

    func testCalculateMetadata() {
        let catalog = createTestPluginCatalog()
        let metadata = catalogTool.calculateMetadata(catalog.plugins)

        XCTAssertGreaterThanOrEqual(metadata.totalFeatures, 0)
        XCTAssertGreaterThanOrEqual(metadata.averagePluginRating, 0.0)
        XCTAssertGreaterThanOrEqual(metadata.mostCommonPriceRange.count, 0)
        XCTAssertGreaterThanOrEqual(metadata.compatibilityScore, 0.0)
        XCTAssertLessThanOrEqual(metadata.compatibilityScore, 1.0)
        XCTAssertGreaterThanOrEqual(metadata.featureVarietyScore, 0.0)
        XCTAssertLessThanOrEqual(metadata.featureVarietyScore, 1.0)
    }

    func testCalculateMetadataEmptyCatalog() {
        let metadata = catalogTool.calculateMetadata([])

        XCTAssertEqual(metadata.totalFeatures, 0)
        XCTAssertEqual(metadata.averagePluginRating, 0.0)
        XCTAssertTrue(metadata.mostCommonPriceRange.isEmpty)
        XCTAssertEqual(metadata.compatibilityScore, 0.0)
        XCTAssertEqual(metadata.featureVarietyScore, 0.0)
    }

    // MARK: - Main Summarization Method Tests

    func testSummarizeCatalogBasic() async throws {
        let catalog = createTestPluginCatalog()
        let input = CatalogSummarizationTool.CatalogSummarizationInput(
            catalog: catalog,
            includeMetadata: true,
            clusteringMethod: "category"
        )

        let result = try await catalogTool.handle(input)

        XCTAssertNotNil(result.summary)
        XCTAssertEqual(result.summary?.overview.totalPlugins, 6)
        XCTAssertEqual(result.summary?.overview.totalVendors, 3)
        XCTAssertGreaterThanOrEqual(result.summary?.metadata?.compatibilityScore ?? 0, 0.0)
    }

    func testSummarizeCatalogWithClustering() async throws {
        let catalog = createTestPluginCatalog()
        let input = CatalogSummarizationTool.CatalogSummarizationInput(
            catalog: catalog,
            includeMetadata: true,
            clusteringMethod: "vendor",
            maxClusters: 10
        )

        let result = try await catalogTool.handle(input)

        XCTAssertNotNil(result.summary)
        XCTAssertEqual(result.summary?.overview.totalPlugins, 6)
        XCTAssertEqual(result.summary?.clusters.count, 3)

        let vendorClusters = result.summary?.clusters ?? []
        for cluster in vendorClusters {
            let allSameVendor = cluster.plugins.allSatisfy { $0.vendor == cluster.name }
            XCTAssertTrue(allSameVendor, "Cluster '\(cluster.name)' should contain only plugins from the same vendor")
        }
    }

    func testSummarizeCatalogHierarchicalClustering() async throws {
        let catalog = createTestPluginCatalog()
        let input = CatalogSummarizationTool.CatalogSummarizationInput(
            catalog: catalog,
            includeMetadata: true,
            clusteringMethod: "hierarchical",
            maxClusters: 3
        )

        let result = try await catalogTool.handle(input)

        XCTAssertNotNil(result.summary)
        XCTAssertEqual(result.summary?.overview.totalPlugins, 6)
        XCTAssertGreaterThanOrEqual(result.summary?.clusters.count ?? 0, 1)
    }

    func testSummarizeCatalogFeatureSimilarity() async throws {
        let catalog = createTestPluginCatalog()
        let input = CatalogSummarizationTool.CatalogSummarizationInput(
            catalog: catalog,
            includeMetadata: true,
            clusteringMethod: "feature_similarity",
            maxClusters: 5
        )

        let result = try await catalogTool.handle(input)

        XCTAssertNotNil(result.summary)
        XCTAssertEqual(result.summary?.overview.totalPlugins, 6)
        XCTAssertGreaterThanOrEqual(result.summary?.clusters.count ?? 0, 1)
    }

    func testSummarizeCatalogEmpty() async throws {
        let emptyCatalog = CatalogSummarizationTool.PluginCatalog(name: "Empty", plugins: [])
        let input = CatalogSummarizationTool.CatalogSummarizationInput(
            catalog: emptyCatalog,
            includeMetadata: true,
            clusteringMethod: "category"
        )

        let result = try await catalogTool.handle(input)

        XCTAssertNotNil(result.summary)
        XCTAssertEqual(result.summary?.overview.totalPlugins, 0)
        XCTAssertEqual(result.summary?.overview.totalVendors, 0)
        XCTAssertTrue(result.summary?.clusters.isEmpty ?? true)
    }

    // MARK: - Error Handling Tests

    func testSummarizeCatalogInvalidClusteringMethod() async throws {
        let catalog = createTestPluginCatalog()
        let input = CatalogSummarizationTool.CatalogSummarizationInput(
            catalog: catalog,
            includeMetadata: true,
            clusteringMethod: "invalid_method"
        )

        // Should default to category clustering for invalid method
        let result = try await catalogTool.handle(input)

        XCTAssertNotNil(result.summary)
        XCTAssertEqual(result.summary?.overview.totalPlugins, 6)
        XCTAssertGreaterThanOrEqual(result.summary?.clusters.count ?? 0, 1)
    }

    func testSummarizeCatalogWithNilPlugins() async throws {
        var catalog = createTestPluginCatalog()
        catalog.plugins = []

        let input = CatalogSummarizationTool.CatalogSummarizationInput(
            catalog: catalog,
            includeMetadata: true,
            clusteringMethod: "category"
        )

        let result = try await catalogTool.handle(input)

        XCTAssertNotNil(result.summary)
        XCTAssertEqual(result.summary?.overview.totalPlugins, 0)
        XCTAssertTrue(result.summary?.clusters.isEmpty ?? true)
    }

    // MARK: - Performance Tests

    func testSummarizeLargeCatalogPerformance() async throws {
        // Create a larger catalog for performance testing
        var largePluginList: [CatalogSummarizationTool.PluginItem] = []

        for i in 1...50 {
            let plugin = CatalogSummarizationTool.PluginItem(
                id: "plugin\(i)",
                name: "Plugin \(i)",
                vendor: "Vendor \(i % 10)",
                category: "Category \(i % 8)",
                price: Double(i * 10),
                format: ["VST3", "AU", "AAX"][i % 3],
                description: "Test plugin number \(i) for performance testing",
                tags: ["tag\(i % 5)", "test\(i % 3)", "performance"],
                features: ["Feature \(i % 4)", "Setting \(i % 2)"]
            )
            largePluginList.append(plugin)
        }

        let largeCatalog = CatalogSummarizationTool.PluginCatalog(
            name: "Large Performance Test Catalog",
            plugins: largePluginList
        )

        let input = CatalogSummarizationTool.CatalogSummarizationInput(
            catalog: largeCatalog,
            includeMetadata: true,
            clusteringMethod: "category"
        )

        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try await catalogTool.handle(input)
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime

        XCTAssertNotNil(result.summary)
        XCTAssertEqual(result.summary?.overview.totalPlugins, 50)
        XCTAssertLessThan(timeElapsed, 5.0, "Summarization should complete within 5 seconds")
    }

    // MARK: - Edge Cases Tests

    func testSummarizeCatalogWithDuplicatePlugins() async throws {
        var catalog = createTestPluginCatalog()

        // Add duplicate plugins
        if let firstPlugin = catalog.plugins.first {
            catalog.plugins.append(firstPlugin)
            catalog.plugins.append(firstPlugin)
        }

        let input = CatalogSummarizationTool.CatalogSummarizationInput(
            catalog: catalog,
            includeMetadata: true,
            clusteringMethod: "category"
        )

        let result = try await catalogTool.handle(input)

        XCTAssertNotNil(result.summary)
        XCTAssertEqual(result.summary?.overview.totalPlugins, 8) // 6 original + 2 duplicates
        XCTAssertEqual(result.summary?.overview.totalVendors, 3) // Should not count duplicate vendors
    }

    func testSummarizeCatalogWithExtremePrices() async throws {
        var catalog = createTestPluginCatalog()

        // Add plugins with extreme prices
        let expensivePlugin = CatalogSummarizationTool.PluginItem(
            id: "expensive",
            name: "Ultra Expensive",
            vendor: "Luxury Audio",
            category: "Mastering",
            price: 99999.0,
            format: "AAX",
            description: "Extremely expensive mastering plugin",
            tags: ["mastering", "luxury", "expensive"],
            features: ["Luxury Processing"]
        )

        catalog.plugins.append(expensivePlugin)

        let input = CatalogSummarizationTool.CatalogSummarizationInput(
            catalog: catalog,
            includeMetadata: true,
            clusteringMethod: "price_range"
        )

        let result = try await catalogTool.handle(input)

        XCTAssertNotNil(result.summary)
        XCTAssertEqual(result.summary?.overview.totalPlugins, 7)
        XCTAssertEqual(result.summary?.overview.priceRange.max, 99999.0)
        XCTAssertGreaterThan(result.summary?.overview.averagePrice ?? 0, 1000.0)
    }

    func testSummarizeCatalogWithMinimalData() async throws {
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

        let minimalCatalog = CatalogSummarizationTool.PluginCatalog(
            name: "Minimal",
            plugins: [minimalPlugin]
        )

        let input = CatalogSummarizationTool.CatalogSummarizationInput(
            catalog: minimalCatalog,
            includeMetadata: true,
            clusteringMethod: "category"
        )

        let result = try await catalogTool.handle(input)

        XCTAssertNotNil(result.summary)
        XCTAssertEqual(result.summary?.overview.totalPlugins, 1)
        XCTAssertGreaterThanOrEqual(result.summary?.overview.totalVendors ?? 0, 0)
    }

    // MARK: - Vendor Analysis Integration Tests

    func testSummarizeCatalogWithVendorAnalysis() async throws {
        let catalog = createTestPluginCatalog()
        let input = CatalogSummarizationTool.CatalogSummarizationInput(
            catalog: catalog,
            includeMetadata: true,
            clusteringMethod: "vendor",
            includeVendorAnalysis: true,
            generateRecommendations: true,
            maxRecommendations: 2
        )

        let result = try await catalogTool.handle(input)

        XCTAssertNotNil(result.summary)
        XCTAssertNotNil(result.summary?.vendorAnalysis)
        XCTAssertNotNil(result.summary?.vendorAnalysis?.vendorDistribution)
        XCTAssertNotNil(result.summary?.vendorAnalysis?.marketInsights)
        XCTAssertNotNil(result.summary?.vendorAnalysis?.vendorComparison)
        XCTAssertGreaterThanOrEqual(result.summary?.vendorAnalysis?.vendorInsights?.count ?? 0, 0)
        XCTAssertGreaterThanOrEqual(result.summary?.vendorAnalysis?.alternativeSuggestions?.count ?? 0, 0)

        // Test vendor neutrality score calculation
        let vendorAnalysis = result.summary?.vendorAnalysis
        XCTAssertGreaterThanOrEqual(vendorAnalysis?.vendorNeutralityScore ?? 0, 0.0)
        XCTAssertLessThanOrEqual(vendorAnalysis?.vendorNeutralityScore ?? 0, 1.0)
    }

    func testSummarizeCatalogWithRecommendations() async throws {
        let catalog = createTestPluginCatalog()
        let input = CatalogSummarizationTool.CatalogSummarizationInput(
            catalog: catalog,
            includeMetadata: true,
            clusteringMethod: "feature_similarity",
            generateRecommendations: true,
            maxRecommendations: 3
        )

        let result = try await catalogTool.handle(input)

        XCTAssertNotNil(result.summary)
        XCTAssertNotNil(result.summary?.recommendations)

        if let recommendations = result.summary?.recommendations, !recommendations.isEmpty {
            for recommendation in recommendations {
                XCTAssertNotNil(recommendation.plugin)
                XCTAssertGreaterThanOrEqual(recommendation.similarityScore, 0.0)
                XCTAssertLessThanOrEqual(recommendation.similarityScore, 1.0)
                XCTAssertGreaterThanOrEqual(recommendation.compatibilityScore, 0.0)
                XCTAssertLessThanOrEqual(recommendation.compatibilityScore, 1.0)
                XCTAssertNotNil(recommendation.reasons)
                XCTAssertFalse(recommendation.reasons.isEmpty)
                XCTAssertNotNil(recommendation.useCaseAlignment)
            }
        }
    }
}