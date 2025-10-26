import SwiftUI
import UniformTypeIdentifiers

struct DocumentListView: View {
    @State private var documents: [BookDocument] = []
    @State private var showingImporter = false
    @StateObject private var ingestionService = DocumentIngestionService()

    var body: some View {
        NavigationView {
            List(documents) { document in
                VStack(alignment: .leading) {
                    Text(document.title)
                        .font(.headline)
                    Text(document.domain.rawValue.capitalized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(document.status.rawValue.capitalized)
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(statusColor(for: document.status))
                        .cornerRadius(4)
                }
                .padding(.vertical, 2)
            }
            .navigationTitle("Book Library")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Add Document") {
                        showingImporter = true
                    }
                    .fileImporter(
                        isPresented: $showingImporter,
                        allowedContentTypes: [.pdf],
                        allowsMultipleSelection: false
                    ) { result in
                        switch result {
                        case .success(let urls):
                            if let url = urls.first {
                                Task {
                                    await ingestDocument(at: url)
                                }
                            }
                        case .failure(let error):
                            print("Document import failed: \(error)")
                        }
                    }
                }
            }
        }
    }

    private func statusColor(for status: BookDocument.ProcessingStatus) -> Color {
        switch status {
        case .pending: return .orange
        case .processing: return .blue
        case .completed: return .green
        case .failed: return .red
        }
    }

    private func ingestDocument(at url: URL) async {
        let document = await ingestionService.ingestDocument(at: url)
        Task { @MainActor in
            documents.append(document)
        }
    }
}