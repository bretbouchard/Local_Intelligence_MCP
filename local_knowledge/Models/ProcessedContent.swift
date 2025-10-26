import Foundation

struct ProcessedContent: Codable {
    let sourceURL: URL
    let pages: [PageContent]
    let extractedAt: Date
}

struct PageContent: Codable {
    let pageIndex: Int
    let text: String
    let size: CGRect
    let structuredContent: [StructuredContent]
}

struct StructuredContent: Codable {
    let type: ContentType
    let text: String
    let bounds: CGRect
    let pageIndex: Int

    enum ContentType: String, Codable {
        case heading = "heading"
        case paragraph = "paragraph"
        case figure = "figure"
        case table = "table"
        case equation = "equation"
    }
}

enum ProcessingError: Error {
    case invalidPDF
    case extractionFailed
}