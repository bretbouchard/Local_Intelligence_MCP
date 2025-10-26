import SwiftUI

/// Row component for displaying individual context suggestions with copy functionality
struct SuggestionRow: View {
    let suggestion: String
    let onCopy: () -> Void
    @State private var showCopyFeedback = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Suggestion text
            VStack(alignment: .leading, spacing: 4) {
                Text(suggestion)
                    .font(.system(.body, design: .default))
                    .foregroundColor(.primary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }

            Spacer()

            // Copy button with feedback
            Button(action: {
                onCopy()
                showCopyFeedback = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    showCopyFeedback = false
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: showCopyFeedback ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(showCopyFeedback ? .green : .blue)

                    if showCopyFeedback {
                        Text("Copied!")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .animation(.easeInOut(duration: 0.2), value: showCopyFeedback)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.separatorColor), lineWidth: 0.5)
                )
        )
    }
}

#Preview {
    VStack(spacing: 8) {
        SuggestionRow(suggestion: "Based on 'The Art of Electronics' (p. 245): Operational Amplifier Design - The 741 op-amp is a widely used general-purpose operational amplifier...") {
            // Copy action
        }

        SuggestionRow(suggestion: "Based on 'Clean Code' (p. 89): Function Naming - Functions should be named with verbs that clearly describe their actions and purpose...") {
            // Copy action
        }
    }
    .padding()
}