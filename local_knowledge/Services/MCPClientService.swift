import Foundation

class MCPClientService: @unchecked Sendable {
    private let baseURL: URL
    private let session = URLSession.shared

    init(baseURL: URL = URL(string: "http://localhost:3000")!) {
        self.baseURL = baseURL
    }

    func processDocumentContent(_ content: ProcessedContent, domain: BookDocument.DocumentDomain) async throws -> KnowledgeExtractionResult {
        let request = BookAnalysisRequest(
            content: content,
            domain: domain.rawValue,
            extractionTypes: [.concepts, .relationships, .examples, .guidelines]
        )

        let result = try await callMCPTool("book.analyze", with: request)
        return try JSONDecoder().decode(KnowledgeExtractionResult.self, from: result)
    }

    func searchKnowledge(query: String, domain: BookDocument.DocumentDomain? = nil) async throws -> [KnowledgeObject] {
        let request = KnowledgeSearchRequest(
            query: query,
            domain: domain?.rawValue,
            maxResults: 10
        )

        let result = try await callMCPTool("book.search", with: request)
        return try JSONDecoder().decode(KnowledgeSearchResponse.self, from: result).objects
    }

    private func callMCPTool(_ toolName: String, with request: Codable) async throws -> Data {
        let url = baseURL.appendingPathComponent("mcp/\(toolName)")

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestData = try JSONEncoder().encode(request)
        urlRequest.httpBody = requestData

        let (data, response) = try await session.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw MCPError.requestFailed
        }

        return data
    }
}

// MARK: - Request/Response Models

struct BookAnalysisRequest: Codable {
    let content: ProcessedContent
    let domain: String
    let extractionTypes: [ExtractionType]

    enum ExtractionType: String, Codable {
        case concepts = "concepts"
        case relationships = "relationships"
        case examples = "examples"
        case guidelines = "guidelines"
    }
}


struct KnowledgeSearchRequest: Codable {
    let query: String
    let domain: String?
    let maxResults: Int
}

struct KnowledgeSearchResponse: Codable {
    let objects: [KnowledgeObject]
    let totalFound: Int
    let searchTime: TimeInterval
}

enum MCPError: Error {
    case requestFailed
    case decodingFailed
}