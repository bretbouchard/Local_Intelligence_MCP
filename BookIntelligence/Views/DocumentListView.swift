import SwiftUI

struct DocumentListView: View {
    @State private var documents: [BookDocument] = []

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
                        // TODO: Implement document picker
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
}