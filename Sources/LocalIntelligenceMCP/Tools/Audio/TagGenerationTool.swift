//
//  TagGenerationTool.swift
//  LocalIntelligenceMCP
//
//  Created on 2025-10-09.
//

import Foundation

/// Tag and keyword generation tool for audio domain content
/// Implements apple.tags.generate specification for generating retrieval and filtering tags
public final class TagGenerationTool: AudioDomainTool, @unchecked Sendable {

    // MARK: - Initialization

    public convenience init(
        logger: Logger,
        securityManager: SecurityManager
    ) {
        self.init(
            name: "apple_tags_generate",
            description: "Generate tags/keywords for retrieval & filtering from audio domain content with confidence scoring",
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
                "text": ["type": "string"],
                "limit": [
                    "type": "integer",
                    "minimum": 1,
                    "maximum": 20,
                    "default": 12
                ],
                "vocabulary": [
                    "type": "array",
                    "items": ["type": "string"]
                ],
                "audio_context": [
                    "type": "object",
                    "properties": [
                        "domain": ["type": "string"],
                        "content_type": ["type": "string"],
                        "min_confidence": ["type": "number", "minimum": 0, "maximum": 1],
                        "include_entities": ["type": "boolean"],
                        "include_technical": ["type": "boolean"],
                        "include_business": ["type": "boolean"]
                    ]
                ]
            ]),
            "required": AnyCodable(["text"])
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

    // MARK: - Tag Categories

    public enum TagCategory: String, CaseIterable, Codable, Sendable {
        case equipment = "equipment"
        case technical = "technical"
        case workflow = "workflow"
        case genre = "genre"
        case business = "business"
        case quality = "quality"
        case format = "format"
        case location = "location"
        case role = "role"
        case sentiment = "sentiment"
        case domain = "domain"
    }

    // MARK: - Tag Generation Result

    public struct TagGenerationResult: Codable, Sendable {
        let tags: [GeneratedTag]
        let confidence: [Double]
        let metadata: TagMetadata

        public init(tags: [GeneratedTag], confidence: [Double], metadata: TagMetadata) {
            self.tags = tags
            self.confidence = confidence
            self.metadata = metadata
        }

        /// Convenience initializer for simple tag arrays
        public init(tagStrings: [String], confidence: [Double], metadata: TagMetadata) {
            self.tags = tagStrings.enumerated().map { index, tag in
                GeneratedTag(text: tag, confidence: confidence[safe: index] ?? 0.5, category: .technical)
            }
            self.confidence = confidence
            self.metadata = metadata
        }
    }

    public struct GeneratedTag: Codable, Sendable {
        let text: String
        let confidence: Double
        let category: TagCategory
        let source: TagSource
        let context: String?

        public init(text: String, confidence: Double, category: TagCategory, source: TagSource = .extracted, context: String? = nil) {
            self.text = text
            self.confidence = confidence
            self.category = category
            self.source = source
            self.context = context
        }
    }

    public enum TagSource: String, Codable, Sendable {
        case extracted = "extracted"
        case vocabulary = "vocabulary"
        case inferred = "inferred"
        case domain = "domain"
    }

    public struct TagMetadata: Codable, Sendable {
        let processingTime: Double
        let textLength: Int
        let totalTags: Int
        let averageConfidence: Double
        let audioDomain: String
        let vocabularyUsed: Bool
        let categoriesCovered: [String]

        public init(
            processingTime: Double = 0.0,
            textLength: Int = 0,
            totalTags: Int = 0,
            averageConfidence: Double = 0.0,
            audioDomain: String = "general",
            vocabularyUsed: Bool = false,
            categoriesCovered: [String] = []
        ) {
            self.processingTime = processingTime
            self.textLength = textLength
            self.totalTags = totalTags
            self.averageConfidence = averageConfidence
            self.audioDomain = audioDomain
            self.vocabularyUsed = vocabularyUsed
            self.categoriesCovered = categoriesCovered
        }
    }

    // MARK: - AudioDomainTool Implementation

    internal override func performExecution(parameters: [String: AnyCodable], context: MCPExecutionContext) async throws -> MCPResponse {
        // Extract text content from parameters
        guard let text = parameters["text"]?.value as? String else {
            throw ToolsRegistryError.invalidParameters("text parameter is required")
        }

        // Convert AnyCodable parameters to regular [String: Any] for processing
        var processingParams: [String: Any] = [:]
        for (key, value) in parameters {
            processingParams[key] = value.value
        }

        // Process using the audio content method
        let result = try await processAudioContent(text, with: processingParams)

        return MCPResponse(
            success: true,
            data: AnyCodable(result),
            error: nil
        )
    }

    public override func processAudioContent(_ content: String, with parameters: [String: Any]) async throws -> String {
        let startTime = Date()

        await logger.debug("Starting tag generation", category: .general, metadata: [
            "contentLength": AnyCodable(content.count),
            "tool": AnyCodable(name)
        ])

        // Validate inputs
        guard !content.isEmpty else {
            throw AudioProcessingError.contentEmpty
        }

        let limit = min(parameters["limit"] as? Int ?? 12, 20)
        let vocabulary = parameters["vocabulary"] as? [String] ?? []
        let audioContext = parameters["audio_context"] as? [String: Any] ?? [:]

        let minConfidence = audioContext["min_confidence"] as? Double ?? 0.3
        let includeEntities = audioContext["include_entities"] as? Bool ?? true
        let includeTechnical = audioContext["include_technical"] as? Bool ?? true
        let includeBusiness = audioContext["include_business"] as? Bool ?? true

        do {
            // Generate tags from different sources
            var allTags: [GeneratedTag] = []

            // Extract entities as tags
            if includeEntities {
                let entityTags = extractEntityTags(from: content, context: audioContext)
                allTags.append(contentsOf: entityTags)
            }

            // Extract technical terms
            if includeTechnical {
                let technicalTags = extractTechnicalTags(from: content, context: audioContext)
                allTags.append(contentsOf: technicalTags)
            }

            // Extract business/role terms
            if includeBusiness {
                let businessTags = extractBusinessTags(from: content, context: audioContext)
                allTags.append(contentsOf: businessTags)
            }

            // Extract workflow and process tags
            let workflowTags = extractWorkflowTags(from: content, context: audioContext)
            allTags.append(contentsOf: workflowTags)

            // Extract genre/style tags
            let genreTags = extractGenreTags(from: content, context: audioContext)
            allTags.append(contentsOf: genreTags)

            // Add vocabulary-based tags
            let vocabularyTags = addVocabularyTags(to: content, vocabulary: vocabulary)
            allTags.append(contentsOf: vocabularyTags)

            // Extract domain-specific tags
            let domainTags = extractDomainTags(from: content, context: audioContext)
            allTags.append(contentsOf: domainTags)

            // Score, deduplicate, and limit tags
            let processedTags = processAndScoreTags(allTags, minConfidence: minConfidence, limit: limit)

            let processingTime = Date().timeIntervalSince(startTime)

            // Create result
            let result = TagGenerationResult(
                tags: processedTags,
                confidence: processedTags.map { $0.confidence },
                metadata: TagMetadata(
                    processingTime: processingTime,
                    textLength: content.count,
                    totalTags: processedTags.count,
                    averageConfidence: processedTags.isEmpty ? 0.0 : processedTags.reduce(0) { $0 + $1.confidence } / Double(processedTags.count),
                    audioDomain: audioContext["domain"] as? String ?? "general",
                    vocabularyUsed: !vocabulary.isEmpty,
                    categoriesCovered: Set(processedTags.map { $0.category.rawValue }).sorted()
                )
            )

            let response = try encodeJSON(result)

            await logger.info("Tag generation completed successfully", category: .general, metadata: [
                "tagCount": AnyCodable(processedTags.count),
                "averageConfidence": AnyCodable(result.metadata.averageConfidence),
                "processingTime": AnyCodable(processingTime)
            ])

            return response

        } catch {
            await logger.error("Tag generation failed", error: error, category: .general, metadata: [:])
            throw error
        }
    }

    // MARK: - Tag Extraction Methods

    /// Extract entity-based tags (equipment, brands, models)
    private func extractEntityTags(from text: String, context: [String: Any]) -> [GeneratedTag] {
        var tags: [GeneratedTag] = []

        // Microphone brands and models
        let microphonePatterns = [
            ("Neumann", ["U87", "TLM103", "KM184", "U47", "U67"]),
            ("AKG", ["C414", "C414XLII", "C12", "C451", "K240"]),
            ("Shure", ["SM58", "SM57", "SM7B", "Beta58A", "KSM32"]),
            ("Sennheiser", ["MKH416", "MD421", "e965", "MKH8060"]),
            ("Audio-Technica", ["AT4050", "AT4047", "AT2020", "AE2500"]),
            ("Rode", ["NT1A", "NT2A", "NT5", "NT1000", "Podcaster"])
        ]

        for (brand, models) in microphonePatterns {
            if text.contains(brand) {
                tags.append(GeneratedTag(text: brand, confidence: 0.9, category: .equipment, source: .extracted))

                for model in models {
                    if text.contains(model) {
                        tags.append(GeneratedTag(text: model, confidence: 0.85, category: .equipment, source: .extracted))
                    }
                }
            }
        }

        // Console brands
        let consoleBrands = ["SSL", "Neve", "API", "Focusrite", "Universal Audio", "Audient", "Midas"]
        for brand in consoleBrands {
            if text.localizedCaseInsensitiveContains(brand) {
                tags.append(GeneratedTag(text: brand, confidence: 0.9, category: .equipment, source: .extracted))
            }
        }

        // DAW software
        let dawSoftware = ["Pro Tools", "Logic Pro", "Ableton Live", "Cubase", "FL Studio", "Reaper", "Studio One"]
        for daw in dawSoftware {
            if text.localizedCaseInsensitiveContains(daw) {
                tags.append(GeneratedTag(text: daw, confidence: 0.9, category: .equipment, source: .extracted))
            }
        }

        return tags
    }

    /// Extract technical tags (frequencies, formats, etc.)
    private func extractTechnicalTags(from text: String, context: [String: Any]) -> [GeneratedTag] {
        var tags: [GeneratedTag] = []

        // Technical terms
        let technicalTerms = [
            "compression", "EQ", "equalization", "reverb", "delay", "chorus", "phaser",
            "limiter", "gate", "expander", "multiband", "stereo", "mono", "panning",
            "automation", "mixdown", "mastering", "tracking", "overdub", "bounce",
            "ADAT", "SPDIF", "MIDI", "USB", "Thunderbolt", "FireWire"
        ]

        for term in technicalTerms {
            if text.localizedCaseInsensitiveContains(term) {
                tags.append(GeneratedTag(text: term, confidence: 0.75, category: .technical, source: .extracted))
            }
        }

        // Audio formats
        let audioFormats = ["WAV", "MP3", "AIFF", "FLAC", "AAC", "OGG", "M4A", "DSD"]
        for format in audioFormats {
            if text.uppercased().contains(format) {
                tags.append(GeneratedTag(text: format, confidence: 0.8, category: .format, source: .extracted))
            }
        }

        // Sample rates
        let sampleRatePattern = "(\\d+(?:\\.\\d+)?)\\s*(Hz|kHz)"
        if let regex = try? NSRegularExpression(pattern: sampleRatePattern, options: [.caseInsensitive]) {
            let range = NSRange(location: 0, length: text.utf16.count)
            let matches = regex.matches(in: text, options: [], range: range)

            for match in matches {
                if let matchRange = Range(match.range, in: text) {
                    let value = String(text[matchRange])
                    tags.append(GeneratedTag(text: value, confidence: 0.85, category: .technical, source: .extracted))
                }
            }
        }

        return tags
    }

    /// Extract business and role tags
    private func extractBusinessTags(from text: String, context: [String: Any]) -> [GeneratedTag] {
        var tags: [GeneratedTag] = []

        // Professional roles
        let roles = [
            "producer", "engineer", "mixing engineer", "mastering engineer",
            "recording engineer", "assistant engineer", "artist", "musician",
            "composer", "songwriter", "arranger", "studio manager"
        ]

        for role in roles {
            if text.localizedCaseInsensitiveContains(role) {
                tags.append(GeneratedTag(text: role, confidence: 0.8, category: .role, source: .extracted))
            }
        }

        // Business terms
        let businessTerms = [
            "client", "project", "session", "budget", "deadline", "invoice",
            "studio", "label", "publisher", "rights", "royalty", "licensing"
        ]

        for term in businessTerms {
            if text.localizedCaseInsensitiveContains(term) {
                tags.append(GeneratedTag(text: term, confidence: 0.7, category: .business, source: .extracted))
            }
        }

        // Location types
        let locations = [
            "recording studio", "home studio", "live venue", "concert hall",
            "rehearsal space", "church", "auditorium", "outdoor"
        ]

        for location in locations {
            if text.localizedCaseInsensitiveContains(location) {
                tags.append(GeneratedTag(text: location, confidence: 0.75, category: .location, source: .extracted))
            }
        }

        return tags
    }

    /// Extract workflow and process tags
    private func extractWorkflowTags(from text: String, context: [String: Any]) -> [GeneratedTag] {
        var tags: [GeneratedTag] = []

        // Workflow stages
        let workflowStages = [
            "pre-production", "recording", "tracking", "overdubbing",
            "editing", "comping", "mixing", "mastering", "delivery",
            "setup", "soundcheck", "rehearsal", "performance"
        ]

        for stage in workflowStages {
            if text.localizedCaseInsensitiveContains(stage) {
                tags.append(GeneratedTag(text: stage, confidence: 0.85, category: .workflow, source: .extracted))
            }
        }

        // Actions and processes
        let actions = [
            "record", "mix", "master", "edit", "compress", "equalize",
            "quantize", "tune", "arrange", "compose", "produce",
            "capture", "process", "enhance", "restore", "clean"
        ]

        for action in actions {
            if text.localizedCaseInsensitiveContains(action) {
                tags.append(GeneratedTag(text: action, confidence: 0.7, category: .workflow, source: .extracted))
            }
        }

        return tags
    }

    /// Extract genre and style tags
    private func extractGenreTags(from text: String, context: [String: Any]) -> [GeneratedTag] {
        var tags: [GeneratedTag] = []

        // Music genres
        let genres = [
            "rock", "pop", "jazz", "classical", "electronic", "hip-hop",
            "country", "folk", "blues", "reggae", "metal", "punk",
            "indie", "alternative", "R&B", "soul", "funk", "disco",
            "ambient", "experimental", "world", "gospel", "orchestral"
        ]

        for genre in genres {
            if text.localizedCaseInsensitiveContains(" \(genre) ") ||
               text.localizedCaseInsensitiveContains("\(genre) ") ||
               text.localizedCaseInsensitiveContains(" \(genre)") {
                tags.append(GeneratedTag(text: genre, confidence: 0.75, category: .genre, source: .extracted))
            }
        }

        // Instrument types
        let instruments = [
            "vocals", "guitar", "bass", "drums", "piano", "keyboards",
            "violin", "cello", "trumpet", "saxophone", "flute", "clarinet",
            "synthesizer", "drum machine", " sampler", "turntables"
        ]

        for instrument in instruments {
            if text.localizedCaseInsensitiveContains(instrument) {
                tags.append(GeneratedTag(text: instrument, confidence: 0.8, category: .genre, source: .extracted))
            }
        }

        return tags
    }

    /// Add vocabulary-based tags
    private func addVocabularyTags(to text: String, vocabulary: [String]) -> [GeneratedTag] {
        guard !vocabulary.isEmpty else { return [] }

        var tags: [GeneratedTag] = []

        for term in vocabulary {
            if text.localizedCaseInsensitiveContains(term) {
                tags.append(GeneratedTag(text: term, confidence: 0.95, category: .technical, source: .vocabulary))
            }
        }

        return tags
    }

    /// Extract domain-specific tags
    private func extractDomainTags(from text: String, context: [String: Any]) -> [GeneratedTag] {
        var tags: [GeneratedTag] = []

        let domain = context["domain"] as? String ?? "general"

        switch domain.lowercased() {
        case "recording":
            tags.append(contentsOf: extractRecordingDomainTags(from: text))
        case "mixing":
            tags.append(contentsOf: extractMixingDomainTags(from: text))
        case "mastering":
            tags.append(contentsOf: extractMasteringDomainTags(from: text))
        case "live_sound":
            tags.append(contentsOf: extractLiveSoundDomainTags(from: text))
        default:
            tags.append(contentsOf: extractGeneralAudioTags(from: text))
        }

        return tags
    }

    private func extractRecordingDomainTags(from text: String) -> [GeneratedTag] {
        let terms = ["microphone placement", "room acoustics", "isolation booth", "overhead mics", "close miking"]
        return terms.map { GeneratedTag(text: $0, confidence: 0.7, category: .domain, source: .domain) }
            .filter { text.localizedCaseInsensitiveContains($0.text) }
    }

    private func extractMixingDomainTags(from text: String) -> [GeneratedTag] {
        let terms = ["automation", "send effects", "bus processing", "parallel compression", "mid-side processing"]
        return terms.map { GeneratedTag(text: $0, confidence: 0.7, category: .domain, source: .domain) }
            .filter { text.localizedCaseInsensitiveContains($0.text) }
    }

    private func extractMasteringDomainTags(from text: String) -> [GeneratedTag] {
        let terms = ["limiting", "EQ", "stereo enhancement", "dithering", "resolution"]
        return terms.map { GeneratedTag(text: $0, confidence: 0.7, category: .domain, source: .domain) }
            .filter { text.localizedCaseInsensitiveContains($0.text) }
    }

    private func extractLiveSoundDomainTags(from text: String) -> [GeneratedTag] {
        let terms = ["front of house", "monitor mix", "sound check", "feedback", "PA system"]
        return terms.map { GeneratedTag(text: $0, confidence: 0.7, category: .domain, source: .domain) }
            .filter { text.localizedCaseInsensitiveContains($0.text) }
    }

    private func extractGeneralAudioTags(from text: String) -> [GeneratedTag] {
        let terms = ["audio", "sound", "music", "production", "studio"]
        return terms.map { GeneratedTag(text: $0, confidence: 0.6, category: .domain, source: .domain) }
            .filter { text.localizedCaseInsensitiveContains($0.text) }
    }

    // MARK: - Tag Processing

    /// Process and score tags: deduplicate, sort by confidence, and limit
    private func processAndScoreTags(_ tags: [GeneratedTag], minConfidence: Double, limit: Int) -> [GeneratedTag] {
        // Filter by minimum confidence
        let filteredTags = tags.filter { $0.confidence >= minConfidence }

        // Deduplicate by text (keeping highest confidence)
        var deduplicatedTags: [String: GeneratedTag] = [:]
        for tag in filteredTags {
            let key = tag.text.lowercased()
            if let existing = deduplicatedTags[key] {
                if tag.confidence > existing.confidence {
                    deduplicatedTags[key] = tag
                }
            } else {
                deduplicatedTags[key] = tag
            }
        }

        // Sort by confidence (descending) then by text
        let sortedTags = deduplicatedTags.values.sorted { tag1, tag2 in
            if tag1.confidence == tag2.confidence {
                return tag1.text < tag2.text
            }
            return tag1.confidence > tag2.confidence
        }

        // Apply limit
        return Array(sortedTags.prefix(limit))
    }

    // MARK: - Utility Methods

    /// Encode result as JSON string
    private func encodeJSON(_ result: TagGenerationResult) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let data = try encoder.encode(result)
        return String(data: data, encoding: .utf8) ?? "{}"
    }
}

