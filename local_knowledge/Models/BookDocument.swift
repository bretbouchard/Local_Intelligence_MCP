import Foundation

struct BookDocument: Identifiable, Codable {
    let id: UUID
    let title: String
    let filePath: URL
    let domain: DocumentDomain
    let processedAt: Date?
    var status: ProcessingStatus = .pending

    init(title: String, filePath: URL, domain: DocumentDomain, processedAt: Date? = nil) {
        self.id = UUID()
        self.title = title
        self.filePath = filePath
        self.domain = domain
        self.processedAt = processedAt
    }

    enum DocumentDomain: String, CaseIterable, Codable {
        case electronics = "electronics"
        case programming = "programming"
        case general = "general"
    }

    enum ProcessingStatus: String, CaseIterable, Codable {
        case pending = "pending"
        case processing = "processing"
        case completed = "completed"
        case failed = "failed"
    }
}