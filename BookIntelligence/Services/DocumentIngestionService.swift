import Foundation

class DocumentIngestionService {
    func ingestDocument(at url: URL) async -> BookDocument {
        // Stub implementation - will be expanded in Task 2
        var document = BookDocument(
            title: url.lastPathComponent,
            filePath: url,
            domain: .general,  // Will be classified later
            processedAt: nil
        )

        // Basic stub processing
        document.status = .pending

        return document
    }
}