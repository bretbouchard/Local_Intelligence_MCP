import Foundation
import Combine

class DocumentIngestionService: ObservableObject {
    private let mcpClient = MCPClientService()

    @MainActor
    func ingestDocument(at url: URL) async -> BookDocument {
        // Create initial document record
        var document = BookDocument(
            title: url.lastPathComponent,
            filePath: url,
            domain: .general,  // Will be classified later
            processedAt: nil
        )

        do {
            document.status = .processing

            // Extract PDF content
            let processedContent = try await PDFProcessingService().extractText(from: url)

            // Classify document domain
            document.domain = classifyDocumentDomain(content: processedContent)

            // Send to MCP for knowledge extraction (run in background thread)
            let mcpClient = self.mcpClient
            let domain = document.domain
            let knowledgeResult = try await Task.detached {
                try await mcpClient.processDocumentContent(processedContent, domain: domain)
            }.value

            // TODO: Save knowledge objects to CoreData
            print("Extracted \(knowledgeResult.knowledgeObjects.count) knowledge objects")
            print("Found \(knowledgeResult.relationships.count) relationships")

            document.status = .completed
            document.processedAt = Date()

        } catch {
            document.status = .failed
            print("Document processing failed: \(error)")
        }

        return document
    }

    func classifyDocumentDomain(content: ProcessedContent) -> BookDocument.DocumentDomain {
        let fullText = content.pages.map { $0.text }.joined(separator: " ")

        // Basic keyword-based classification
        let electronicsKeywords = ["circuit", "transistor", "op-amp", "voltage", "current", "resistor", "capacitor"]
        let programmingKeywords = ["function", "class", "algorithm", "code", "programming", "software"]

        let electronicsScore = electronicsKeywords.filter { fullText.localizedCaseInsensitiveContains($0) }.count
        let programmingScore = programmingKeywords.filter { fullText.localizedCaseInsensitiveContains($0) }.count

        if electronicsScore > programmingScore {
            return .electronics
        } else if programmingScore > 0 {
            return .programming
        } else {
            return .general
        }
    }
}