//
//  SchemaExtractionTool.swift
//  LocalIntelligenceMCP
//
//  Created on 2025-10-09.
//

import Foundation

/// Schema-based structured data extraction tool for audio domain content
/// Implements apple.schema.extract specification for extracting fields from free text
public final class SchemaExtractionTool: AudioDomainTool, @unchecked Sendable {

    // MARK: - Initialization

    public convenience init(
        logger: Logger,
        securityManager: SecurityManager
    ) {
        self.init(
            name: "apple_schema_extract",
            description: "Extract structured fields from free text according to provided schema for audio domain content",
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
                "schema": [
                    "type": "object",
                    "properties": [
                        "type": ["type": "object"],
                        "required": ["type": "array"],
                        "properties": ["type": "object"]
                    ]
                ],
                "audio_context": [
                    "type": "object",
                    "properties": [
                        "domain": ["type": "string"],
                        "document_type": ["type": "string"],
                        "confidence_threshold": ["type": "number", "minimum": 0, "maximum": 1]
                    ]
                ]
            ]),
            "required": AnyCodable(["text", "schema"])
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

    // MARK: - Audio Entity Types

    public enum AudioEntityType: String, CaseIterable, Codable, Sendable {
        // Equipment entities
        case microphone = "microphone"
        case preamplifier = "preamplifier"
        case console = "console"
        case plugin = "plugin"
        case daw = "daw"
        case interface = "interface"
        case headphone = "headphone"
        case monitor = "monitor"

        // Technical entities
        case frequency = "frequency"
        case decibel = "decibel"
        case bitrate = "bitrate"
        case samplerate = "samplerate"
        case bitdepth = "bitdepth"
        case format = "format"
        case codec = "codec"

        // Time entities
        case duration = "duration"
        case timestamp = "timestamp"
        case tempo = "tempo"
        case timesignature = "timesignature"

        // Action entities
        case recording = "recording"
        case mixing = "mixing"
        case mastering = "mastering"
        case editing = "editing"
        case processing = "processing"

        // Business entities
        case client = "client"
        case project = "project"
        case session = "session"
        case price = "price"
        case date = "date"

        // Quality entities
        case rating = "rating"
        case sentiment = "sentiment"
        case urgency = "urgency"
    }

    // MARK: - Extraction Result

    public struct ExtractionResult: Codable, Sendable {
        let extractedObject: [String: AnyCodable]
        let validity: Double
        let confidence: Double
        let missingFields: [String]
        let extractedEntities: [ExtractedEntity]
        let metadata: ExtractionMetadata

        public init(
            extractedObject: [String: AnyCodable],
            validity: Double,
            confidence: Double,
            missingFields: [String] = [],
            extractedEntities: [ExtractedEntity] = [],
            metadata: ExtractionMetadata = ExtractionMetadata()
        ) {
            self.extractedObject = extractedObject
            self.validity = validity
            self.confidence = confidence
            self.missingFields = missingFields
            self.extractedEntities = extractedEntities
            self.metadata = metadata
        }
    }

    public struct ExtractedEntity: Codable, Sendable {
        let type: AudioEntityType
        let text: String
        let value: AnyCodable
        let confidence: Double
        let startIndex: Int
        let endIndex: Int
        let context: String

        public init(
            type: AudioEntityType,
            text: String,
            value: AnyCodable,
            confidence: Double,
            startIndex: Int,
            endIndex: Int,
            context: String
        ) {
            self.type = type
            self.text = text
            self.value = value
            self.confidence = confidence
            self.startIndex = startIndex
            self.endIndex = endIndex
            self.context = context
        }
    }

    public struct ExtractionMetadata: Codable, Sendable {
        let processingTime: Double
        let textLength: Int
        let entityCount: Int
        let audioDomain: String
        let extractionStrategy: String

        public init(
            processingTime: Double = 0.0,
            textLength: Int = 0,
            entityCount: Int = 0,
            audioDomain: String = "general",
            extractionStrategy: String = "pattern_matching"
        ) {
            self.processingTime = processingTime
            self.textLength = textLength
            self.entityCount = entityCount
            self.audioDomain = audioDomain
            self.extractionStrategy = extractionStrategy
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

        await logger.debug("Starting schema extraction", category: .general, metadata: [
            "contentLength": AnyCodable(content.count),
            "tool": AnyCodable(name)
        ])

        // Validate inputs
        guard !content.isEmpty else {
            throw AudioProcessingError.contentEmpty
        }

        guard let schemaDict = parameters["schema"] as? [String: Any] else {
            throw AudioProcessingError.invalidInput("Schema parameter is required")
        }

        let audioContext = parameters["audio_context"] as? [String: Any] ?? [:]
        let confidenceThreshold = audioContext["confidence_threshold"] as? Double ?? 0.7

        do {
            // Extract entities based on schema
            let extractedEntities = try await extractEntities(from: content, schema: schemaDict, context: audioContext)

            // Build structured object from schema
            let extractedObject = try await buildStructuredObject(from: extractedEntities, schema: schemaDict)

            // Calculate validity and confidence
            let (validity, confidence, missingFields) = calculateValidity(
                object: extractedObject,
                schema: schemaDict,
                threshold: confidenceThreshold
            )

            let processingTime = Date().timeIntervalSince(startTime)

            // Create result
            let result = ExtractionResult(
                extractedObject: extractedObject,
                validity: validity,
                confidence: confidence,
                missingFields: missingFields,
                extractedEntities: extractedEntities,
                metadata: ExtractionMetadata(
                    processingTime: processingTime,
                    textLength: content.count,
                    entityCount: extractedEntities.count,
                    audioDomain: audioContext["domain"] as? String ?? "general",
                    extractionStrategy: "hybrid_pattern_ml"
                )
            )

            let response = try encodeJSON(result)

            await logger.info("Schema extraction completed successfully", category: .general, metadata: [
                "validity": AnyCodable(validity),
                "confidence": AnyCodable(confidence),
                "entityCount": AnyCodable(extractedEntities.count),
                "processingTime": AnyCodable(processingTime)
            ])

            return response

        } catch {
            await logger.error("Schema extraction failed", error: error, category: .general, metadata: [:])
            throw error
        }
    }

    // MARK: - Private Methods

    /// Extract entities from text based on schema and audio context
    private func extractEntities(
        from text: String,
        schema: [String: Any],
        context: [String: Any]
    ) async throws -> [ExtractedEntity] {
        var entities: [ExtractedEntity] = []

        // Extract equipment entities
        entities.append(contentsOf: extractEquipmentEntities(from: text))

        // Extract technical entities
        entities.append(contentsOf: extractTechnicalEntities(from: text))

        // Extract time entities
        entities.append(contentsOf: extractTimeEntities(from: text))

        // Extract action entities
        entities.append(contentsOf: extractActionEntities(from: text))

        // Extract business entities
        entities.append(contentsOf: extractBusinessEntities(from: text))

        // Filter entities based on schema requirements
        return filterEntitiesBySchema(entities, schema: schema)
    }

    /// Extract equipment entities (microphones, consoles, plugins, etc.)
    private func extractEquipmentEntities(from text: String) -> [ExtractedEntity] {
        var entities: [ExtractedEntity] = []

        // Microphone brands and models
        let microphonePatterns = [
            "Neumann\\s+(U\\d+[A-Za-z]*|TLM\\d+|KM\\d+)",
            "AKG\\s+(C\\d+|C\\d+[A-Za-z]*|K\\d+)",
            "Shure\\s+(SM\\d+|Beta\\d+[A-Za-z]*|KSM\\d+)",
            "Sennheiser\\s+(MKH\\d+|MD\\d+|e\\d+)",
            "Audio-Technica\\s+(AT\\d+[A-Za-z]*|AE\\d+)",
            "Rode\\s+(NT\\d+|NT\\d+-[A-Z]|Podcaster|Procaster)"
        ]

        for pattern in microphonePatterns {
            entities.append(contentsOf: extractPatternEntities(
                from: text,
                pattern: pattern,
                type: .microphone
            ))
        }

        // Console brands
        let consolePatterns = [
            "SSL\\s+(\\d+[A-Za-z]*|AWS\\d+|Matrix)",
            "Neve\\s+(\\d+[A-Za-z]*|88RS|Genesys)",
            "API\\s+(\\d+[A-Za-z]*|Vision|Legacy)",
            "Focusrite\\s+(Red\\d+|Saffire\\d+|Clarett\\d+)",
            "Universal Audio\\s+(Apollo\\d+|\\d+F|Console\\d+)"
        ]

        for pattern in consolePatterns {
            entities.append(contentsOf: extractPatternEntities(
                from: text,
                pattern: pattern,
                type: .console
            ))
        }

        return entities
    }

    /// Extract technical entities (frequencies, dB levels, etc.)
    private func extractTechnicalEntities(from text: String) -> [ExtractedEntity] {
        var entities: [ExtractedEntity] = []

        // Frequencies
        let frequencyPattern = "(\\d+(?:\\.\\d+)?)\\s*(Hz|kHz|MHz)"
        entities.append(contentsOf: extractPatternEntities(
            from: text,
            pattern: frequencyPattern,
            type: .frequency,
            valueTransformer: { match in
                let value = Double(match.groups[1])!
                let unit = match.groups[2]
                return unit == "kHz" ? value * 1000 : value
            }
        ))

        // Decibel levels
        let decibelPattern = "(-?\\d+(?:\\.\\d+)?)\\s*dB"
        entities.append(contentsOf: extractPatternEntities(
            from: text,
            pattern: decibelPattern,
            type: .decibel,
            valueTransformer: { match in
                Double(match.groups[1])!
            }
        ))

        // Sample rates
        let sampleRatePattern = "(\\d+(?:\\.\\d+)?)\\s*(Hz|kHz)\\s*(?:sample|sampling)"
        entities.append(contentsOf: extractPatternEntities(
            from: text,
            pattern: sampleRatePattern,
            type: .samplerate
        ))

        // Bit depths
        let bitDepthPattern = "(\\d+)-?bit"
        entities.append(contentsOf: extractPatternEntities(
            from: text,
            pattern: bitDepthPattern,
            type: .bitdepth
        ))

        return entities
    }

    /// Extract time entities (duration, tempo, etc.)
    private func extractTimeEntities(from text: String) -> [ExtractedEntity] {
        var entities: [ExtractedEntity] = []

        // Duration (minutes:seconds or time formats)
        let durationPattern = "(\\d{1,2}):(\\d{2})(?::(\\d{2}))?"
        entities.append(contentsOf: extractPatternEntities(
            from: text,
            pattern: durationPattern,
            type: .duration,
            valueTransformer: { match in
                let minutes = Int(match.groups[1])!
                let seconds = Int(match.groups[2])!
                return minutes * 60 + seconds
            }
        ))

        // Tempo (BPM)
        let tempoPattern = "(\\d+)\\s*(?:BPM|bpm)"
        entities.append(contentsOf: extractPatternEntities(
            from: text,
            pattern: tempoPattern,
            type: .tempo
        ))

        // Time signature
        let timeSignaturePattern = "(\\d)/(\\d)\\s*(?:time|signature)"
        entities.append(contentsOf: extractPatternEntities(
            from: text,
            pattern: timeSignaturePattern,
            type: .timesignature
        ))

        return entities
    }

    /// Extract action entities (recording, mixing, etc.)
    private func extractActionEntities(from text: String) -> [ExtractedEntity] {
        var entities: [ExtractedEntity] = []

        let actionPatterns: [(AudioEntityType, String)] = [
            (.recording, "\\b(?:record|recording|track|capture|lay\\s+down)\\b"),
            (.mixing, "\\b(?:mix|mixing|blend|balance)\\b"),
            (.mastering, "\\b(?:master|mastering|finalize|polish)\\b"),
            (.editing, "\\b(?:edit|editing|cut|trim|splice)\\b"),
            (.processing, "\\b(?:process|processing|treat|enhance)\\b")
        ]

        for (type, pattern) in actionPatterns {
            entities.append(contentsOf: extractPatternEntities(
                from: text,
                pattern: pattern,
                type: type
            ))
        }

        return entities
    }

    /// Extract business entities (clients, projects, prices, etc.)
    private func extractBusinessEntities(from text: String) -> [ExtractedEntity] {
        var entities: [ExtractedEntity] = []

        // Client names (simplified pattern - in production would use NER)
        let clientPattern = "\\b[A-Z][a-z]+\\s+(?:Studios|Production|Records|Media|Audio)\\b"
        entities.append(contentsOf: extractPatternEntities(
            from: text,
            pattern: clientPattern,
            type: .client
        ))

        // Prices
        let pricePattern = "\\$\\s*(\\d+(?:,\\d{3})*(?:\\.\\d{2})?)"
        entities.append(contentsOf: extractPatternEntities(
            from: text,
            pattern: pricePattern,
            type: .price,
            valueTransformer: { match in
                let cleaned = match.groups[1].replacingOccurrences(of: ",", with: "")
                return Double(cleaned)!
            }
        ))

        // Dates
        let datePattern = "(\\d{1,2})/(\\d{1,2})/(\\d{4})"
        entities.append(contentsOf: extractPatternEntities(
            from: text,
            pattern: datePattern,
            type: .date
        ))

        return entities
    }

    /// Extract entities using regex patterns
    private func extractPatternEntities(
        from text: String,
        pattern: String,
        type: AudioEntityType,
        valueTransformer: ((RegexMatch) -> Any)? = nil
    ) -> [ExtractedEntity] {
        var entities: [ExtractedEntity] = []

        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return entities
        }

        let range = NSRange(location: 0, length: text.utf16.count)
        let matches = regex.matches(in: text, options: [], range: range)

        for match in matches {
            let matchRange = Range(match.range, in: text)!
            let matchedText = String(text[matchRange])

            // Extract context (surrounding text)
            let contextStart = max(0, matchRange.lowerBound.utf16Offset(in: text) - 50)
            let contextEnd = min(text.utf16.count, matchRange.upperBound.utf16Offset(in: text) + 50)
            let contextRange = Range(NSRange(location: contextStart, length: contextEnd - contextStart), in: text)!
            let context = String(text[contextRange])

            // Determine value
            let value: Any
            if let transformer = valueTransformer,
               let regexMatch = createRegexMatch(from: match, text: text) {
                value = transformer(regexMatch)
            } else {
                value = matchedText
            }

            let entity = ExtractedEntity(
                type: type,
                text: matchedText,
                value: AnyCodable(value),
                confidence: 0.85, // Base confidence for pattern matches
                startIndex: matchRange.lowerBound.utf16Offset(in: text),
                endIndex: matchRange.upperBound.utf16Offset(in: text),
                context: context
            )

            entities.append(entity)
        }

        return entities
    }

    /// Create a regex match structure for value transformation
    private func createRegexMatch(from match: NSTextCheckingResult, text: String) -> RegexMatch? {
        guard match.numberOfRanges > 1 else { return nil }

        var groups: [String] = []
        for i in 1..<match.numberOfRanges {
            let range = match.range(at: i)
            if range.location != NSNotFound,
               let swiftRange = Range(range, in: text) {
                groups.append(String(text[swiftRange]))
            } else {
                groups.append("")
            }
        }

        return RegexMatch(groups: groups)
    }

    /// Filter entities based on schema requirements
    private func filterEntitiesBySchema(_ entities: [ExtractedEntity], schema: [String: Any]) -> [ExtractedEntity] {
        // For now, return all entities. In a production system, this would
        // analyze the schema and only return entities that match required fields
        return entities
    }

    /// Build structured object from extracted entities and schema
    private func buildStructuredObject(
        from entities: [ExtractedEntity],
        schema: [String: Any]
    ) async throws -> [String: AnyCodable] {
        var result: [String: AnyCodable] = [:]

        // Group entities by type
        let groupedEntities = Dictionary(grouping: entities) { $0.type }

        for (type, typeEntities) in groupedEntities {
            let key = type.rawValue

            if typeEntities.count == 1 {
                // Single entity
                result[key] = typeEntities.first!.value
            } else {
                // Multiple entities of same type
                let values = typeEntities.map { $0.value }
                result[key] = AnyCodable(values)
            }
        }

        // Add schema-specific fields
        if let properties = schema["properties"] as? [String: Any] {
            for (fieldName, fieldSchema) in properties {
                if !result.keys.contains(fieldName) {
                    // Try to find matching entities for this field
                    if let fieldValue = try await findValueForField(fieldName, schema: fieldSchema, entities: entities) {
                        result[fieldName] = fieldValue
                    }
                }
            }
        }

        return result
    }

    /// Find value for a specific schema field from entities
    private func findValueForField(
        _ fieldName: String,
        schema: Any,
        entities: [ExtractedEntity]
    ) async throws -> AnyCodable? {
        // Simple heuristic: look for entities whose context mentions the field name
        let matchingEntities = entities.filter { entity in
            entity.context.lowercased().contains(fieldName.lowercased())
        }

        guard let bestEntity = matchingEntities.max(by: { $0.confidence < $1.confidence }) else {
            return nil
        }

        return bestEntity.value
    }

    /// Calculate validity and confidence scores
    private func calculateValidity(
        object: [String: AnyCodable],
        schema: [String: Any],
        threshold: Double
    ) -> (validity: Double, confidence: Double, missingFields: [String]) {
        guard let required = schema["required"] as? [String] else {
            // No required fields specified
            return (1.0, 0.8, [])
        }

        var missingFields: [String] = []
        var fulfilledRequirements = 0

        for field in required {
            if object.keys.contains(field) {
                fulfilledRequirements += 1
            } else {
                missingFields.append(field)
            }
        }

        let validity = required.isEmpty ? 1.0 : Double(fulfilledRequirements) / Double(required.count)
        let confidence = validity >= threshold ? validity : validity * 0.7 // Penalty for missing required fields

        return (validity, confidence, missingFields)
    }

    /// Encode result as JSON string
    private func encodeJSON(_ result: ExtractionResult) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let data = try encoder.encode(result)
        return String(data: data, encoding: .utf8) ?? "{}"
    }
}

// MARK: - Supporting Types

private struct RegexMatch {
    let groups: [String]
}