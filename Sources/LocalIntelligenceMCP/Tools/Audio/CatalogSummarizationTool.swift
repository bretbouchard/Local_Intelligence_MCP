//
//  CatalogSummarizationTool.swift
//  LocalIntelligenceMCP
//
//  Created on 2025-10-09.
//

import Foundation

/// Plugin catalog summarization tool with vendor-neutral analysis
/// Implements apple.catalog.summarize specification for clustering and summarizing plugin catalogs
public final class CatalogSummarizationTool: AudioDomainTool, @unchecked Sendable {

    // MARK: - Initialization

    public convenience init(
        logger: Logger,
        securityManager: SecurityManager
    ) {
        self.init(
            name: "apple_catalog_summarize",
            description: "Summarize plugin catalog entries generically (vendor-neutral)",
            inputSchema: nil,
            logger: logger,
            securityManager: securityManager
        )
    }

    public override init(
        name: String,
        description: String,
        inputSchema: [String: Any]? = nil,
        logger: Logger,
        securityManager: SecurityManager,
        requiresPermission: [PermissionType] = [.systemInfo],
        offlineCapable: Bool = true
    ) {
        let defaultInputSchema: [String: AnyCodable] = [
            "type": AnyCodable("object"),
            "properties": AnyCodable([
                "items": [
                    "type": "array",
                    "items": [
                        "type": "object",
                        "properties": [
                            "id": ["type": "string"],
                            "name": ["type": "string"],
                            "vendor": ["type": "string"],
                            "tags": [
                                "type": "array",
                                "items": ["type": "string"]
                            ],
                            "desc": ["type": "string"],
                            "price": ["type": "string"],
                            "category": ["type": "string"],
                            "features": [
                                "type": "array",
                                "items": ["type": "string"]
                            ],
                            "compatibility": [
                                "type": "array",
                                "items": ["type": "string"]
                            ]
                        ]
                    ]
                ],
                "focus": [
                    "type": "array",
                    "items": ["type": "string"]
                ],
                "grouping": [
                    "type": "string",
                    "enum": ["category", "vendor", "price_range", "compatibility", "feature_similarity", "use_case", "hierarchical", "none"],
                    "default": "category"
                ],
                "max_overviews": [
                    "type": "integer",
                    "minimum": 5,
                    "maximum": 50,
                    "default": 20
                ],
                "summary_length": [
                    "type": "string",
                    "enum": ["brief", "detailed", "comprehensive"],
                    "default": "detailed"
                ],
                "include_clusters": [
                    "type": "boolean",
                    "default": true
                ],
                "vendor_analysis": [
                    "type": "boolean",
                    "default": false,
                    "description": "Perform vendor-neutral analysis and comparison"
                ],
                "recommend_alternatives": [
                    "type": "boolean",
                    "default": false,
                    "description": "Generate alternative plugin recommendations"
                ]
            ]),
            "required": AnyCodable(["items"])
        ]

        super.init(
            name: name,
            description: description,
            inputSchema: inputSchema ?? defaultInputSchema,
            logger: logger,
            securityManager: securityManager,
            requiresPermission: requiresPermission,
            offlineCapable: offlineCapable
        )
    }

    // MARK: - Plugin Catalog Types

    public struct PluginItem: Codable, Sendable {
        let id: String
        let name: String
        let vendor: String
        let tags: [String]
        let description: String
        let price: String?
        let category: String?
        let features: [String]?
        let compatibility: [String]?

        public init(
            id: String,
            name: String,
            vendor: String,
            tags: [String] = [],
            description: String = "",
            price: String? = nil,
            category: String? = nil,
            features: [String]? = nil,
            compatibility: [String]? = nil
        ) {
            self.id = id
            self.name = name
            self.vendor = vendor
            self.tags = tags
            self.description = description
            self.price = price
            self.category = category
            self.features = features
            self.compatibility = compatibility
        }
    }

    public struct PluginOverview: Codable, Sendable {
        let id: String
        let gist: String
        let tags: [String]
        let keyFeatures: [String]
        let vendor: String
        let priceRange: String?
        let confidence: Double

        public init(
            id: String,
            gist: String,
            tags: [String],
            keyFeatures: [String],
            vendor: String,
            priceRange: String? = nil,
            confidence: Double = 0.8
        ) {
            self.id = id
            self.gist = gist
            self.tags = tags
            self.keyFeatures = keyFeatures
            self.vendor = vendor
            self.priceRange = priceRange
            self.confidence = confidence
        }
    }

    public struct PluginCluster: Codable, Sendable {
        let label: String
        let itemIds: [String]
        let category: String?
        let description: String
        let count: Int
        let representativeItems: [String]

        public init(
            label: String,
            itemIds: [String],
            category: String? = nil,
            description: String = "",
            count: Int,
            representativeItems: [String] = []
        ) {
            self.label = label
            self.itemIds = itemIds
            self.category = category
            self.description = description
            self.count = count
            self.representativeItems = representativeItems
        }
    }

    public struct CatalogSummaryResult: Codable, Sendable {
        let overviews: [PluginOverview]
        let clusters: [PluginCluster]
        let metadata: CatalogMetadata
        let vendorAnalysis: VendorAnalysisResult?

        public init(
            overviews: [PluginOverview],
            clusters: [PluginCluster],
            metadata: CatalogMetadata,
            vendorAnalysis: VendorAnalysisResult? = nil
        ) {
            self.overviews = overviews
            self.clusters = clusters
            self.metadata = metadata
            self.vendorAnalysis = vendorAnalysis
        }
    }

    public struct CatalogMetadata: Codable, Sendable {
        let totalPlugins: Int
        let totalVendors: Int
        let totalCategories: Int
        let processingTime: Double
        let groupingStrategy: String
        let focusApplied: [String]
        let summaryType: String
        let confidenceAverage: Double

        public init(
            totalPlugins: Int,
            totalVendors: Int,
            totalCategories: Int,
            processingTime: Double,
            groupingStrategy: String,
            focusApplied: [String],
            summaryType: String,
            confidenceAverage: Double
        ) {
            self.totalPlugins = totalPlugins
            self.totalVendors = totalVendors
            self.totalCategories = totalCategories
            self.processingTime = processingTime
            self.groupingStrategy = groupingStrategy
            self.focusApplied = focusApplied
            self.summaryType = summaryType
            self.confidenceAverage = confidenceAverage
        }
    }

    // MARK: - Vendor Analysis Types

    public struct VendorAnalysisResult: Codable, Sendable {
        let vendorDiversity: VendorDiversityAnalysis
        let featureDistribution: FeatureDistributionAnalysis
        let alternativeRecommendations: [PluginRecommendation]
        let vendorNeutralityScore: Double

        public init(
            vendorDiversity: VendorDiversityAnalysis,
            featureDistribution: FeatureDistributionAnalysis,
            alternativeRecommendations: [PluginRecommendation],
            vendorNeutralityScore: Double
        ) {
            self.vendorDiversity = vendorDiversity
            self.featureDistribution = featureDistribution
            self.alternativeRecommendations = alternativeRecommendations
            self.vendorNeutralityScore = vendorNeutralityScore
        }
    }

    public struct VendorDiversityAnalysis: Codable, Sendable {
        let totalVendors: Int
        let dominantVendor: String?
        let vendorDistribution: [String: Int]
        let diversityScore: Double
        let marketConcentration: String

        public init(
            totalVendors: Int,
            dominantVendor: String?,
            vendorDistribution: [String: Int],
            diversityScore: Double,
            marketConcentration: String
        ) {
            self.totalVendors = totalVendors
            self.dominantVendor = dominantVendor
            self.vendorDistribution = vendorDistribution
            self.diversityScore = diversityScore
            self.marketConcentration = marketConcentration
        }
    }

    public struct FeatureDistributionAnalysis: Codable, Sendable {
        let capabilityCategories: [String: Int]
        let processingTypes: [String: Int]
        let signalTypes: [String: Int]
        let featureDensity: String
        let complexityDistribution: [String: Int]

        public init(
            capabilityCategories: [String: Int],
            processingTypes: [String: Int],
            signalTypes: [String: Int],
            featureDensity: String,
            complexityDistribution: [String: Int]
        ) {
            self.capabilityCategories = capabilityCategories
            self.processingTypes = processingTypes
            self.signalTypes = signalTypes
            self.featureDensity = featureDensity
            self.complexityDistribution = complexityDistribution
        }
    }

    // MARK: - AudioDomainTool Implementation

    internal override func performExecution(parameters: [String: AnyCodable], context: MCPExecutionContext) async throws -> MCPResponse {
        // Extract items from parameters
        guard let itemsData = parameters["items"]?.value else {
            throw ToolsRegistryError.invalidParameters("items parameter is required")
        }

        // Convert AnyCodable items to PluginItem array
        guard let itemsArray = itemsData as? [[String: Any]] else {
            throw ToolsRegistryError.invalidParameters("items must be an array of objects")
        }

        let items = itemsArray.compactMap { itemDict -> PluginItem? in
            guard let id = itemDict["id"] as? String,
                  let name = itemDict["name"] as? String,
                  let vendor = itemDict["vendor"] as? String else {
                return nil
            }

            return PluginItem(
                id: id,
                name: name,
                vendor: vendor,
                tags: itemDict["tags"] as? [String] ?? [],
                description: itemDict["desc"] as? String ?? itemDict["description"] as? String ?? "",
                price: itemDict["price"] as? String,
                category: itemDict["category"] as? String,
                features: itemDict["features"] as? [String],
                compatibility: itemDict["compatibility"] as? [String]
            )
        }

        // Extract other parameters
        var processingParams: [String: Any] = [:]
        for (key, value) in parameters {
            processingParams[key] = value.value
        }

        // Convert items to JSON string for processing
        let itemsJSON = try JSONEncoder().encode(items)
        let itemsString = String(data: itemsJSON, encoding: .utf8) ?? "[]"

        // Process using the audio content method
        let result = try await processAudioContent(itemsString, with: processingParams)

        return MCPResponse(
            success: true,
            data: AnyCodable(result),
            error: nil
        )
    }

    public override func processAudioContent(_ content: String, with parameters: [String: Any]) async throws -> String {
        let startTime = Date()

        await logger.debug("Starting catalog summarization", category: .general, metadata: [
            "tool": AnyCodable(name)
        ])

        // Parse JSON string back to PluginItem array
        guard let jsonData = content.data(using: .utf8) else {
            throw AudioProcessingError.invalidInput("Content must be valid JSON string")
        }

        guard let items = try? JSONDecoder().decode([PluginItem].self, from: jsonData) else {
            throw AudioProcessingError.invalidInput("Content must be valid JSON array of PluginItem objects")
        }

        guard !items.isEmpty else {
            throw AudioProcessingError.contentEmpty
        }

        // Extract parameters
        let focus = parameters["focus"] as? [String] ?? []
        let grouping = parameters["grouping"] as? String ?? "category"
        let maxOverviews = min(parameters["max_overviews"] as? Int ?? 20, 50)
        let summaryLength = parameters["summary_length"] as? String ?? "detailed"
        let includeClusters = parameters["include_clusters"] as? Bool ?? true
        let vendorAnalysis = parameters["vendor_analysis"] as? Bool ?? false
        let recommendAlternatives = parameters["recommend_alternatives"] as? Bool ?? false

        do {
            // Generate overviews
            let overviews = try await generatePluginOverviews(
                from: items,
                focus: focus,
                maxCount: maxOverviews,
                summaryLength: summaryLength
            )

            // Generate clusters if requested
            var clusters: [PluginCluster] = []
            if includeClusters {
                clusters = try await generatePluginClusters(
                    from: items,
                    grouping: grouping,
                    overviews: overviews
                )
            }

            // Perform vendor analysis if requested
            var vendorAnalysisResult: VendorAnalysisResult?
            if vendorAnalysis || recommendAlternatives {
                vendorAnalysisResult = try await performVendorAnalysis(
                    for: items,
                    includeRecommendations: recommendAlternatives
                )
            }

            // Calculate metadata
            let metadata = CatalogMetadata(
                totalPlugins: items.count,
                totalVendors: Set(items.map { $0.vendor }).count,
                totalCategories: Set(items.compactMap { $0.category }).count,
                processingTime: Date().timeIntervalSince(startTime),
                groupingStrategy: grouping,
                focusApplied: focus,
                summaryType: summaryLength,
                confidenceAverage: overviews.isEmpty ? 0.0 : overviews.reduce(0) { $0 + $1.confidence } / Double(overviews.count)
            )

            // Create result
            let result = CatalogSummaryResult(
                overviews: overviews,
                clusters: clusters,
                metadata: metadata,
                vendorAnalysis: vendorAnalysisResult
            )

            let response = try encodeJSON(result)

            await logger.info("Catalog summarization completed successfully", category: .general, metadata: [
                "totalPlugins": AnyCodable(items.count),
                "overviewsGenerated": AnyCodable(overviews.count),
                "clustersGenerated": AnyCodable(clusters.count),
                "processingTime": AnyCodable(result.metadata.processingTime)
            ])

            return response

        } catch {
            await logger.error("Catalog summarization failed", error: error, category: .general, metadata: [:])
            throw error
        }
    }

    // MARK: - Private Methods

    /// Generate plugin overviews with vendor-neutral analysis
    private func generatePluginOverviews(
        from items: [PluginItem],
        focus: [String],
        maxCount: Int,
        summaryLength: String
    ) async throws -> [PluginOverview] {

        var overviews: [PluginOverview] = []

        for item in items.prefix(maxCount) {
            let overview = try await generateSinglePluginOverview(
                for: item,
                focus: focus,
                summaryLength: summaryLength
            )
            overviews.append(overview)
        }

        // Sort by confidence and relevance
        overviews.sort { (overview1: PluginOverview, overview2: PluginOverview) -> Bool in
            if overview1.confidence != overview2.confidence {
                return overview1.confidence > overview2.confidence
            }

            // If focus is applied, prioritize items matching focus
            if !focus.isEmpty {
                let focus1 = calculateFocusScore(for: overview1, focus: focus)
                let focus2 = calculateFocusScore(for: overview2, focus: focus)
                if focus1 != focus2 {
                    return focus1 > focus2
                }
            }

            return overview1.id < overview2.id
        }

        return overviews
    }

    /// Generate overview for a single plugin
    private func generateSinglePluginOverview(
        for item: PluginItem,
        focus: [String],
        summaryLength: String
    ) async throws -> PluginOverview {

        // Generate summary based on length preference
        let gist = try await generateSummary(
            for: item,
            length: summaryLength,
            focus: focus
        )

        // Extract key features
        let keyFeatures = extractKeyFeatures(from: item)

        // Generate price range
        let priceRange = extractPriceRange(from: item.price)

        // Calculate confidence based on data quality
        let confidence = calculateConfidence(for: item)

        return PluginOverview(
            id: item.id,
            gist: gist,
            tags: item.tags,
            keyFeatures: keyFeatures,
            vendor: item.vendor,
            priceRange: priceRange,
            confidence: confidence
        )
    }

    /// Generate summary for a plugin based on length and focus
    private func generateSummary(
        for item: PluginItem,
        length: String,
        focus: [String]
    ) async throws -> String {

        var summaryParts: [String] = []

        // Start with basic description
        if !item.description.isEmpty {
            if length == "brief" {
                // Extract first sentence or create brief description
                let briefDesc = item.description.prefix(100).components(separatedBy: ".").first ?? String(item.description.prefix(100))
                summaryParts.append(briefDesc)
            } else if length == "detailed" {
                summaryParts.append(item.description)
            } else { // comprehensive
                summaryParts.append(item.description)

                // Add key features
                if let features = item.features, !features.isEmpty {
                    summaryParts.append("Key features: \(features.joined(separator: ", "))")
                }

                // Add compatibility info
                if let compatibility = item.compatibility, !compatibility.isEmpty {
                    summaryParts.append("Compatible with: \(compatibility.joined(separator: ", "))")
                }
            }
        } else {
            // Generate description from available data
            let baseDesc = "\(item.name) by \(item.vendor)"
            if let category = item.category {
                summaryParts.append("\(baseDesc) - \(category) plugin")
            } else {
                summaryParts.append(baseDesc)
            }

            if let features = item.features, !features.isEmpty {
                summaryParts.append("Features: \(features.prefix(3).joined(separator: ", "))")
            }
        }

        // Apply focus modifications
        if !focus.isEmpty {
            summaryParts = applyFocusToSummary(summaryParts, focus: focus, item: item)
        }

        return summaryParts.joined(separator: ". ")
    }

    /// Extract key features from plugin data
    private func extractKeyFeatures(from item: PluginItem) -> [String] {
        var features: [String] = []

        // Extract from tags
        features.append(contentsOf: item.tags.filter { tag in
            tag.lowercased().contains("eq") ||
            tag.lowercased().contains("compressor") ||
            tag.lowercased().contains("reverb") ||
            tag.lowercased().contains("delay") ||
            tag.lowercased().contains("analog") ||
            tag.lowercased().contains("vintage")
        })

        // Extract from features array
        if let itemFeatures = item.features {
            features.append(contentsOf: itemFeatures)
        }

        // Extract from description (simple keyword extraction)
        let technicalTerms = extractTechnicalTerms(from: item.description)
        features.append(contentsOf: technicalTerms)

        // Remove duplicates and limit to key features
        let uniqueFeatures = Array(Set(features)).prefix(5).sorted()

        return Array(uniqueFeatures)
    }

    /// Extract technical terms from text
    private func extractTechnicalTerms(from text: String) -> [String] {
        let technicalTerms = [
            "analog", "digital", "vintage", "modern", "classic", "tube", "solid-state",
            "parametric", "graphic", "multi-band", "stereo", "mono", "surround",
            "vst", "au", "aax", "rtas", "standalone", "plugin", "effect",
            "equalizer", "compressor", "limiter", "gate", "expander",
            "reverb", "delay", "chorus", "phaser", "flanger", "distortion"
        ]

        return technicalTerms.filter { term in
            text.lowercased().contains(term)
        }
    }

    /// Extract price range from price string
    private func extractPriceRange(from price: String?) -> String? {
        guard let priceString = price, !priceString.isEmpty else { return nil }

        // Extract numeric price
        let pricePattern = "\\$([\\d,]+(?:\\.\\d{2})?)"
        guard let regex = try? NSRegularExpression(pattern: pricePattern),
              let match = regex.firstMatch(in: priceString, range: NSRange(priceString.startIndex..., in: priceString)) else {
            return priceString
        }

        guard let matchRange = Range(match.range(at: 1), in: priceString) else {
            return priceString
        }

        let priceValue = String(priceString[matchRange])

        // Categorize price range
        if let numericPrice = Double(priceValue.replacingOccurrences(of: ",", with: "")) {
            if numericPrice < 50 {
                return "Budget (<$50)"
            } else if numericPrice < 150 {
                return "Mid-range ($50-$150)"
            } else if numericPrice < 300 {
                return "Premium ($150-$300)"
            } else if numericPrice < 500 {
                return "Professional ($300-$500)"
            } else {
                return "High-end ($500+)"
            }
        }

        return priceString
    }

    /// Calculate confidence score for plugin data quality
    private func calculateConfidence(for item: PluginItem) -> Double {
        var confidence: Double = 0.5 // Base confidence

        // Add confidence for complete data
        if !item.description.isEmpty {
            confidence += 0.2
        }

        if !item.tags.isEmpty {
            confidence += 0.1
        }

        if item.features != nil && !item.features!.isEmpty {
            confidence += 0.1
        }

        // Add confidence for vendor reputation (simple heuristic)
        let knownVendors = ["Waves", "Native Instruments", "Universal Audio", "FabFilter", "Soundtoys", "Valhalla", "Softube"]
        if knownVendors.contains(item.vendor) {
            confidence += 0.1
        }

        return min(confidence, 1.0)
    }

    /// Calculate focus score for overview ranking
    private func calculateFocusScore(for overview: PluginOverview, focus: [String]) -> Double {
        var score: Double = 0.0

        for focusTerm in focus {
            let lowerFocus = focusTerm.lowercased()

            // Check in gist, tags, and keyFeatures
            if overview.gist.lowercased().contains(lowerFocus) {
                score += 0.8
            }

            if overview.tags.contains(where: { $0.lowercased().contains(lowerFocus) }) {
                score += 0.6
            }

            if overview.keyFeatures.contains(where: { $0.lowercased().contains(lowerFocus) }) {
                score += 0.4
            }
        }

        return score
    }

    /// Apply focus modifications to summary parts
    private func applyFocusToSummary(_ parts: [String], focus: [String], item: PluginItem) -> [String] {
        guard !focus.isEmpty else { return parts }

        var modifiedParts = parts

        // Check if current summary already addresses focus
        let currentContent = parts.joined(separator: " ").lowercased()
        let focusAddressed = focus.allSatisfy { term in
            currentContent.contains(term.lowercased())
        }

        if focusAddressed {
            return parts // Focus is already addressed
        }

        // Add focus-specific information
        let focusInfo = generateFocusInformation(for: item, focus: focus)
        if !focusInfo.isEmpty {
            modifiedParts.append(focusInfo)
        }

        return modifiedParts
    }

    /// Generate focus-specific information
    private func generateFocusInformation(for item: PluginItem, focus: [String]) -> String {
        var focusInfo: [String] = []

        for focusTerm in focus {
            switch focusTerm.lowercased() {
            case "vintage":
                if item.description.lowercased().contains("vintage") || item.tags.contains(where: { $0.lowercased().contains("vintage") }) {
                    focusInfo.append("Vintage character and warmth")
                }
            case "analog":
                if item.tags.contains(where: { $0.lowercased().contains("analog") }) {
                    focusInfo.append("Analog circuitry and sound")
                }
            case "professional":
                if item.price != nil && extractPriceRange(from: item.price)?.contains("Professional") == true {
                    focusInfo.append("Professional-grade quality")
                }
            default:
                break
            }
        }

        return focusInfo.joined(separator: "; ")
    }

    /// Generate plugin clusters based on grouping strategy
    private func generatePluginClusters(
        from items: [PluginItem],
        grouping: String,
        overviews: [PluginOverview]
    ) async throws -> [PluginCluster] {

        switch grouping {
        case "category":
            return generateCategoryClusters(from: items, overviews: overviews)
        case "vendor":
            return generateVendorClusters(from: items, overviews: overviews)
        case "price_range":
            return generatePriceRangeClusters(from: items, overviews: overviews)
        case "compatibility":
            return generateCompatibilityClusters(from: items, overviews: overviews)
        case "feature_similarity":
            return generateFeatureSimilarityClusters(from: items, overviews: overviews)
        case "use_case":
            return generateUseCaseClusters(from: items, overviews: overviews)
        case "hierarchical":
            return generateHierarchicalClusters(from: items, overviews: overviews)
        case "none":
            return []
        default:
            return generateCategoryClusters(from: items, overviews: overviews)
        }
    }

    /// Generate clusters by category
    private func generateCategoryClusters(from items: [PluginItem], overviews: [PluginOverview]) -> [PluginCluster] {
        let categoryGroups = Dictionary(grouping: items) { item in
            item.category ?? "Uncategorized"
        }

        var clusters: [PluginCluster] = []

        for (category, categoryItems) in categoryGroups {
            let itemIds = categoryItems.map { $0.id }
            let itemCount = categoryItems.count

            // Find representative items (first 2-3 items)
            let representativeItems = categoryItems.prefix(3).map { $0.name }

            // Generate cluster description
            let description = "\(itemCount) plugins in \(category) category"

            let cluster = PluginCluster(
                label: category,
                itemIds: itemIds,
                category: category,
                description: description,
                count: itemCount,
                representativeItems: representativeItems
            )
            clusters.append(cluster)
        }

        return clusters.sorted { $0.count > $1.count }
    }

    /// Generate clusters by vendor
    private func generateVendorClusters(from items: [PluginItem], overviews: [PluginOverview]) -> [PluginCluster] {
        let vendorGroups = Dictionary(grouping: items) { item in
            item.vendor
        }

        var clusters: [PluginCluster] = []

        for (vendor, vendorItems) in vendorGroups {
            let itemIds = vendorItems.map { $0.id }
            let itemCount = vendorItems.count

            // Find representative items
            let representativeItems = vendorItems.prefix(2).map { $0.name }

            let description = "\(itemCount) plugins by \(vendor)"

            let cluster = PluginCluster(
                label: vendor,
                itemIds: itemIds,
                description: description,
                count: itemCount,
                representativeItems: representativeItems
            )
            clusters.append(cluster)
        }

        return clusters.sorted { $0.count > $1.count }
    }

    /// Generate clusters by price range
    private func generatePriceRangeClusters(from items: [PluginItem], overviews: [PluginOverview]) -> [PluginCluster] {
        let priceGroups = Dictionary(grouping: items) { item in
            extractPriceRange(from: item.price) ?? "Unknown"
        }

        var clusters: [PluginCluster] = []

        for (priceRange, priceRangeItems) in priceGroups.sorted(by: { $0.key < $1.key }) {
            let itemIds = priceRangeItems.map { $0.id }
            let itemCount = priceRangeItems.count

            let representativeItems = priceRangeItems.prefix(2).map { $0.name }
            let description = "\(itemCount) plugins in \(priceRange) price range"

            let cluster = PluginCluster(
                label: priceRange,
                itemIds: itemIds,
                description: description,
                count: itemCount,
                representativeItems: representativeItems
            )
            clusters.append(cluster)
        }

        return clusters
    }

    /// Generate clusters by compatibility
    private func generateCompatibilityClusters(from items: [PluginItem], overviews: [PluginOverview]) -> [PluginCluster] {
        var compatibilityGroups: [String: [PluginItem]] = [:]

        for item in items {
            let compatibilities = item.compatibility ?? ["Unknown"]
            let primaryCompatibility = compatibilities.first ?? "Unknown"

            if compatibilityGroups[primaryCompatibility] == nil {
                compatibilityGroups[primaryCompatibility] = []
            }
            compatibilityGroups[primaryCompatibility]?.append(item)
        }

        var clusters: [PluginCluster] = []

        for (compatibility, compatibilityItems) in compatibilityGroups {
            let itemIds = compatibilityItems.map { $0.id }
            let itemCount = compatibilityItems.count

            let representativeItems = compatibilityItems.prefix(2).map { $0.name }
            let description = "\(itemCount) plugins with \(compatibility) compatibility"

            let cluster = PluginCluster(
                label: compatibility,
                itemIds: itemIds,
                description: description,
                count: itemCount,
                representativeItems: representativeItems
            )
            clusters.append(cluster)
        }

        return clusters
    }

    /// Generate clusters by feature similarity
    private func generateFeatureSimilarityClusters(from items: [PluginItem], overviews: [PluginOverview]) -> [PluginCluster] {
        var clusters: [PluginCluster] = []
        var processedItems: Set<String> = []

        // Define feature categories for similarity analysis
        let featureCategories: [String: [String]] = [
            "Dynamics": ["compressor", "limiter", "gate", "expander", "multiband"],
            "EQ & Filtering": ["eq", "equalizer", "filter", "parametric", "graphic"],
            "Time & Space": ["reverb", "delay", "echo", "chorus", "phaser", "flanger"],
            "Distortion & Saturation": ["distortion", "saturation", "tube", "overdrive", "fuzz"],
            "Restoration": ["denoiser", "de-esser", "noise", "restoration", "cleanup"]
        ]

        for (categoryName, keywords) in featureCategories {
            let similarItems = items.filter { item in
                !processedItems.contains(item.id) && itemMatchesKeywords(item, keywords: keywords)
            }

            if similarItems.count >= 2 {
                let itemIds = similarItems.map { $0.id }
                let representativeItems = similarItems.prefix(3).map { $0.name }

                let cluster = PluginCluster(
                    label: categoryName,
                    itemIds: itemIds,
                    category: "feature_similarity",
                    description: "\(similarItems.count) plugins with similar \(categoryName.lowercased()) characteristics",
                    count: similarItems.count,
                    representativeItems: representativeItems
                )
                clusters.append(cluster)

                // Mark items as processed
                for item in similarItems {
                    processedItems.insert(item.id)
                }
            }
        }

        // Add remaining items as "miscellaneous" cluster
        let remainingItems = items.filter { !processedItems.contains($0.id) }
        if !remainingItems.isEmpty {
            let itemIds = remainingItems.map { $0.id }
            let representativeItems = remainingItems.prefix(3).map { $0.name }

            let cluster = PluginCluster(
                label: "Other",
                itemIds: itemIds,
                category: "feature_similarity",
                description: "\(remainingItems.count) plugins with unique characteristics",
                count: remainingItems.count,
                representativeItems: representativeItems
            )
            clusters.append(cluster)
        }

        return clusters.sorted { $0.count > $1.count }
    }

    /// Generate clusters by use case
    private func generateUseCaseClusters(from items: [PluginItem], overviews: [PluginOverview]) -> [PluginCluster] {
        let useCasePatterns: [String: [String]] = [
            "Mixing": ["mix", "balance", "stereo", "mono", "pan", "levels"],
            "Mastering": ["master", "final", "loudness", "commercial", "limiting"],
            "Recording": ["record", "tracking", "mic", "preamp", "input"],
            "Sound Design": ["sound design", "foley", "ambient", "texture", "cinematic"],
            "Live Performance": ["live", "performance", "real-time", "low latency"],
            "Broadcast": ["broadcast", "radio", "podcast", "streaming", "voice"]
        ]

        var clusters: [PluginCluster] = []
        var processedItems: Set<String> = []

        for (useCase, keywords) in useCasePatterns {
            let useCaseItems = items.filter { item in
                !processedItems.contains(item.id) && itemMatchesUseCase(item, keywords: keywords)
            }

            if !useCaseItems.isEmpty {
                let itemIds = useCaseItems.map { $0.id }
                let representativeItems = useCaseItems.prefix(3).map { $0.name }

                let cluster = PluginCluster(
                    label: useCase,
                    itemIds: itemIds,
                    category: "use_case",
                    description: "\(useCaseItems.count) plugins suitable for \(useCase.lowercased())",
                    count: useCaseItems.count,
                    representativeItems: representativeItems
                )
                clusters.append(cluster)

                for item in useCaseItems {
                    processedItems.insert(item.id)
                }
            }
        }

        return clusters.sorted { $0.count > $1.count }
    }

    /// Generate hierarchical clusters (category -> price within category)
    private func generateHierarchicalClusters(from items: [PluginItem], overviews: [PluginOverview]) -> [PluginCluster] {
        var clusters: [PluginCluster] = []

        // First group by category
        let categoryGroups = Dictionary(grouping: items) { item in
            item.category ?? "Uncategorized"
        }

        for (category, categoryItems) in categoryGroups {
            // Then group by price within each category
            let priceGroups = Dictionary(grouping: categoryItems) { item in
                extractPriceRange(from: item.price) ?? "Unknown"
            }

            for (priceRange, priceItems) in priceGroups {
                if priceItems.count >= 1 {
                    let itemIds = priceItems.map { $0.id }
                    let representativeItems = priceItems.prefix(2).map { $0.name }

                    let clusterLabel = priceRange == "Unknown" ? category : "\(category) - \(priceRange)"

                    let cluster = PluginCluster(
                        label: clusterLabel,
                        itemIds: itemIds,
                        category: "hierarchical",
                        description: "\(priceItems.count) \(category.lowercased()) plugins in \(priceRange.lowercased()) range",
                        count: priceItems.count,
                        representativeItems: representativeItems
                    )
                    clusters.append(cluster)
                }
            }
        }

        return clusters.sorted { $0.count > $1.count }
    }

    /// Check if item matches given keywords
    private func itemMatchesKeywords(_ item: PluginItem, keywords: [String]) -> Bool {
        let combinedText = "\(item.name) \(item.description) \(item.tags.joined(separator: " "))".lowercased()

        return keywords.contains { keyword in
            combinedText.contains(keyword.lowercased())
        }
    }

    /// Check if item matches use case keywords
    private func itemMatchesUseCase(_ item: PluginItem, keywords: [String]) -> Bool {
        let searchableText = """
        \(item.name) \(item.description) \(item.tags.joined(separator: " ")) \(item.features?.joined(separator: " ") ?? "")
        """.lowercased()

        return keywords.contains { keyword in
            searchableText.contains(keyword.lowercased())
        }
    }

    /// Encode result as JSON string
    private func encodeJSON(_ result: CatalogSummaryResult) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let data = try encoder.encode(result)
        return String(data: data, encoding: .utf8) ?? "{}"
    }

    // MARK: - Vendor Analysis Methods

    /// Perform comprehensive vendor analysis
    private func performVendorAnalysis(
        for items: [PluginItem],
        includeRecommendations: Bool
    ) async throws -> VendorAnalysisResult {

        // Analyze vendor diversity
        let vendorDiversity = analyzeVendorDiversity(items)

        // Analyze feature distribution
        let featureDistribution = analyzeFeatureDistribution(items)

        // Generate alternative recommendations if requested
        var recommendations: [PluginRecommendation] = []
        if includeRecommendations && items.count > 1 {
            recommendations = generateAlternativeRecommendations(items)
        }

        // Calculate vendor neutrality score
        let neutralityScore = calculateVendorNeutralityScore(vendorDiversity: vendorDiversity, featureDistribution: featureDistribution)

        return VendorAnalysisResult(
            vendorDiversity: vendorDiversity,
            featureDistribution: featureDistribution,
            alternativeRecommendations: recommendations,
            vendorNeutralityScore: neutralityScore
        )
    }

    /// Analyze vendor diversity in the plugin collection
    private func analyzeVendorDiversity(_ items: [PluginItem]) -> VendorDiversityAnalysis {
        let vendorCounts = Dictionary(grouping: items) { $0.vendor }
            .mapValues { $0.count }

        let totalVendors = vendorCounts.count
        let totalPlugins = items.count

        // Find dominant vendor (if any)
        let dominantVendor = vendorCounts.max { $0.value < $1.value }?.key
        let dominantShare = dominantVendor != nil ? Double(vendorCounts[dominantVendor!] ?? 0) / Double(totalPlugins) : 0.0

        // Calculate diversity score (1 - HHI, where HHI is Herfindahl-Hirschman Index)
        let marketShares = vendorCounts.map { Double($0.value) / Double(totalPlugins) }
        let hhi = marketShares.map { $0 * $0 }.reduce(0, +)
        let diversityScore = 1.0 - hhi

        // Determine market concentration
        let marketConcentration: String
        switch dominantShare {
        case 0..<0.3:
            marketConcentration = "Highly competitive"
        case 0.3..<0.5:
            marketConcentration = "Moderately competitive"
        case 0.5..<0.7:
            marketConcentration = "Concentrated"
        default:
            marketConcentration = "Highly concentrated"
        }

        return VendorDiversityAnalysis(
            totalVendors: totalVendors,
            dominantVendor: dominantVendor,
            vendorDistribution: vendorCounts,
            diversityScore: diversityScore,
            marketConcentration: marketConcentration
        )
    }

    /// Analyze feature distribution across plugins
    private func analyzeFeatureDistribution(_ items: [PluginItem]) -> FeatureDistributionAnalysis {
        var capabilityCategories: [String: Int] = [:]
        var processingTypes: [String: Int] = [:]
        var signalTypes: [String: Int] = [:]
        var complexityDistribution: [String: Int] = [:]
        var totalFeatureDensity: Double = 0.0

        for item in items {
            let analysis = VendorNeutralAnalyzer.analyzePluginFeatures(item)

            // Count capabilities
            for capability in analysis.capabilities {
                capabilityCategories[capability, default: 0] += 1
            }

            // Count processing types
            for processingType in analysis.processingTypes {
                processingTypes[processingType, default: 0] += 1
            }

            // Count signal types
            for signalType in analysis.signalTypes {
                signalTypes[signalType, default: 0] += 1
            }

            // Count complexity
            complexityDistribution[analysis.complexity, default: 0] += 1

            totalFeatureDensity += analysis.featureDensity
        }

        // Determine overall feature density
        let averageFeatureDensity = totalFeatureDensity / Double(items.count)
        let featureDensityCategory: String
        switch averageFeatureDensity {
        case 0..<0.2:
            featureDensityCategory = "Light"
        case 0.2..<0.4:
            featureDensityCategory = "Moderate"
        case 0.4..<0.6:
            featureDensityCategory = "Feature-rich"
        default:
            featureDensityCategory = "Comprehensive"
        }

        return FeatureDistributionAnalysis(
            capabilityCategories: capabilityCategories,
            processingTypes: processingTypes,
            signalTypes: signalTypes,
            featureDensity: featureDensityCategory,
            complexityDistribution: complexityDistribution
        )
    }

    /// Generate alternative plugin recommendations
    private func generateAlternativeRecommendations(_ items: [PluginItem]) -> [PluginRecommendation] {
        var recommendations: [PluginRecommendation] = []

        // For each plugin, find alternatives from different vendors
        for plugin in items {
            let alternatives = items.filter { $0.vendor != plugin.vendor }

            if !alternatives.isEmpty {
                let pluginRecommendations = VendorNeutralAnalyzer.generateRecommendations(
                    for: plugin,
                    from: alternatives
                )

                // Take top 2-3 recommendations per plugin
                recommendations.append(contentsOf: pluginRecommendations.prefix(3))
            }
        }

        // Remove duplicates and sort by similarity score
        let uniqueRecommendations = Array(Set(recommendations.map { $0.plugin.id }))
            .compactMap { pluginId in
                recommendations.first { $0.plugin.id == pluginId }
            }
            .sorted { $0.similarityScore > $1.similarityScore }

        return Array(uniqueRecommendations.prefix(10)) // Limit to top 10 recommendations
    }

    /// Calculate vendor neutrality score
    private func calculateVendorNeutralityScore(
        vendorDiversity: VendorDiversityAnalysis,
        featureDistribution: FeatureDistributionAnalysis
    ) -> Double {
        // Base score from vendor diversity
        let diversityScore = vendorDiversity.diversityScore

        // Bonus for balanced capability distribution
        let capabilityBalance = calculateCapabilityBalance(featureDistribution.capabilityCategories)

        // Bonus for processing type diversity
        let processingDiversity = Double(featureDistribution.processingTypes.count) / 10.0 // Normalize to 0-1

        // Combined neutrality score
        let neutralityScore = (diversityScore * 0.5) + (capabilityBalance * 0.3) + (processingDiversity * 0.2)

        return min(neutralityScore, 1.0)
    }

    /// Calculate capability distribution balance
    private func calculateCapabilityBalance(_ capabilities: [String: Int]) -> Double {
        guard !capabilities.isEmpty else { return 0.0 }

        let total = capabilities.values.reduce(0, +)
        let expected = Double(total) / Double(capabilities.count)

        let variance = capabilities.values.map {
            let diff = Double($0) - expected
            return diff * diff
        }.reduce(0, +) / Double(capabilities.count)

        // Lower variance = higher balance
        let balance = 1.0 - min(variance / (expected * expected), 1.0)
        return balance
    }
}