import PDFKit
import Vision

class PDFProcessingService {
    func extractText(from url: URL) async throws -> ProcessedContent {
        guard let document = PDFDocument(url: url) else {
            throw ProcessingError.invalidPDF
        }

        var pages: [PageContent] = []

        for pageIndex in 0..<document.pageCount {
            guard let page = document.page(at: pageIndex) else { continue }

            let pageText = page.string ?? ""
            let pageSize = page.bounds(for: .mediaBox)

            // Extract structured content
            let structuredContent = Self.extractStructuredContent(from: page, pageIndex: pageIndex)

            let pageContent = PageContent(
                pageIndex: pageIndex,
                text: pageText,
                size: pageSize,
                structuredContent: structuredContent
            )

            pages.append(pageContent)
        }

        return ProcessedContent(
            sourceURL: url,
            pages: pages,
            extractedAt: Date()
        )
    }

    private static func extractStructuredContent(from page: PDFPage, pageIndex: Int) -> [StructuredContent] {
        var content: [StructuredContent] = []

        // Extract figures and captions
        let annotations = page.annotations
        if !annotations.isEmpty {
            for annotation in annotations {
                if annotation.contents != nil {
                    content.append(StructuredContent(
                        type: .figure,
                        text: annotation.contents ?? "",
                        bounds: annotation.bounds,
                        pageIndex: pageIndex
                    ))
                }
            }
        }

        return content
    }
}