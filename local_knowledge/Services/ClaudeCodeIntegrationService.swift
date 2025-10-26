import Foundation

/// Service for integrating with Claude Code by providing relevant context from the knowledge graph
@MainActor
class ClaudeCodeIntegrationService: ObservableObject {
    private let knowledgeGraphService = KnowledgeGraphService()

    /// Get relevant knowledge objects for a query, filtered by confidence and limited
    /// - Parameters:
    ///   - query: The query to find context for
    ///   - maxContextItems: Maximum number of context items to return (default: 5)
    /// - Returns: Array of relevant knowledge objects
    func getContextForQuery(_ query: String, maxContextItems: Int = 5) -> [KnowledgeObject] {
        // Search for relevant knowledge objects
        let searchResults = knowledgeGraphService.searchKnowledge(
            query: query,
            domain: nil,
            limit: maxContextItems * 2  // Get more to filter by confidence
        )

        // Rank and filter for Claude Code context
        let contextualObjects = searchResults
            .filter { $0.confidence > 0.7 }  // High confidence only
            .sorted { first, second in
                // Sort by confidence first, then by relevance (title matches)
                if first.confidence != second.confidence {
                    return first.confidence > second.confidence
                }

                // Prefer titles that contain query terms
                let firstTitleMatch = first.title.localizedCaseInsensitiveContains(query)
                let secondTitleMatch = second.title.localizedCaseInsensitiveContains(query)

                if firstTitleMatch != secondTitleMatch {
                    return firstTitleMatch && !secondTitleMatch
                }

                return first.title < second.title
            }
            .prefix(maxContextItems)

        return Array(contextualObjects)
    }

    /// Format knowledge objects as markdown context for Claude Code
    /// - Parameter objects: Knowledge objects to format
    /// - Returns: Formatted markdown string
    func formatContextForClaude(_ objects: [KnowledgeObject]) -> String {
        guard !objects.isEmpty else {
            return "# Context from Book Library\n\nNo relevant context found in your book library for this query."
        }

        var contextText = "# Context from Book Library\n\n"
        contextText += "Found \(objects.count) relevant items from your processed books:\n\n"

        for (index, object) in objects.enumerated() {
            contextText += "## \(index + 1). \(object.title)\n\n"
            contextText += "**Type:** \(object.type.rawValue.capitalized)\n"
            contextText += "**Source:** \(object.sourceReference.documentTitle)"

            if let page = object.sourceReference.pageNumber {
                contextText += ", Page \(page)"
            }

            if let section = object.sourceReference.section {
                contextText += ", Section: \(section)"
            }

            if let figure = object.sourceReference.figureReference {
                contextText += ", Figure: \(figure)"
            }

            contextText += "\n**Confidence:** \(Int(object.confidence * 100))%\n\n"
            contextText += "**Content:**\n\(object.content)\n\n"

            if !object.metadata.isEmpty {
                contextText += "**Additional Details:**\n"
                for (key, value) in object.metadata {
                    contextText += "- \(key): \(value)\n"
                }
                contextText += "\n"
            }

            contextText += "---\n\n"
        }

        contextText += "*This context was automatically extracted from your personal book library to help with your query.*\n\n"
        contextText += "*Use this information to provide more accurate and specific responses based on the books you have processed.*"

        return contextText
    }

    /// Generate brief context enhancement suggestions for a query
    /// - Parameter query: The query to generate suggestions for
    /// - Returns: Array of brief suggestion strings
    func suggestContextEnhancements(for query: String) -> [String] {
        let contextualObjects = getContextForQuery(query)

        return contextualObjects.map { object in
            var suggestion = "Based on \"\(object.sourceReference.documentTitle)\""

            if let page = object.sourceReference.pageNumber {
                suggestion += " (p. \(page))"
            }

            suggestion += ": \(object.title)"

            // Add brief content preview
            let contentPreview = object.content
                .components(separatedBy: .whitespacesAndNewlines)
                .joined(separator: " ")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            if contentPreview.count > 100 {
                let endIndex = contentPreview.index(contentPreview.startIndex, offsetBy: 97)
                suggestion += " - \(contentPreview[..<endIndex])..."
            } else {
                suggestion += " - \(contentPreview)"
            }

            return suggestion
        }
    }

    /// Get available domains for context filtering
    /// - Returns: Array of available document domains
    func getAvailableDomains() -> [String] {
        // This would typically query the database for available domains
        // For now, return common domains
        return ["electronics", "programming", "general", "mathematics", "physics"]
    }

    /// Get context statistics for debugging and monitoring
    /// - Returns: Dictionary with context statistics
    func getContextStatistics() -> [String: Any] {
        let totalObjects = knowledgeGraphService.getTotalKnowledgeObjectCount()

        return [
            "totalKnowledgeObjects": totalObjects,
            "maxContextItems": 5,
            "confidenceThreshold": 0.7,
            "lastUpdated": Date().timeIntervalSince1970
        ]
    }
}