import Foundation

struct KnowledgeObject: Codable, Identifiable {
    let id: String
    let type: KnowledgeType
    let title: String
    let content: String
    let sourceReference: SourceReference
    let confidence: Double
    let metadata: [String: String]

    enum KnowledgeType: String, Codable {
        case concept = "concept"
        case procedure = "procedure"
        case example = "example"
        case principle = "principle"
        case component = "component"
        case circuit = "circuit"
    }
}

struct KnowledgeRelationship: Codable {
    let id: String
    let subject: String
    let predicate: String
    let object: String
    let confidence: Double
    let sourceReference: SourceReference
}

struct SourceReference: Codable {
    let documentTitle: String
    let pageNumber: Int?
    let section: String?
    let figureReference: String?
}

struct KnowledgeExtractionResult: Codable {
    let knowledgeObjects: [KnowledgeObject]
    let relationships: [KnowledgeRelationship]
    let confidence: Double
    let processingTime: TimeInterval
}