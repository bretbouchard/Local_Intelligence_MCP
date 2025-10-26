import SwiftUI

/// Main view for Claude Code integration with context extraction and formatting
struct ClaudeIntegrationView: View {
    @State private var currentQuery = ""
    @State private var suggestedContext: [String] = []
    @State private var formattedContext = ""
    @State private var isGeneratingContext = false
    @State private var showCopyAllFeedback = false
    @State private var contextObjectCount = 0

    @StateObject private var claudeService = ClaudeCodeIntegrationService()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Claude Code Integration")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("Generate contextual information from your book library to enhance your AI-assisted development workflow.")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)

                    // Query input section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Current Query")
                            .font(.headline)
                            .padding(.horizontal)

                        HStack(spacing: 12) {
                            TextField("Enter your technical query...", text: $currentQuery)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .onSubmit {
                                    generateContext()
                                }

                            Button(action: generateContext) {
                                HStack {
                                    if isGeneratingContext {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Image(systemName: "brain")
                                            .font(.system(size: 16, weight: .medium))
                                    }
                                    Text("Generate")
                                        .font(.system(size: 14, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(
                                            isGeneratingContext || currentQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                            ? Color.gray
                                            : Color.blue
                                        )
                                )
                            }
                            .disabled(currentQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isGeneratingContext)
                        }
                        .padding(.horizontal)
                    }

                    // Suggested context enhancements
                    if !suggestedContext.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Suggested Context Enhancements")
                                    .font(.headline)

                                Spacer()

                                Text("\(contextObjectCount) items found")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal)

                            LazyVStack(spacing: 8) {
                                ForEach(Array(suggestedContext.enumerated()), id: \.offset) { index, suggestion in
                                    SuggestionRow(suggestion: suggestion) {
                                        copyToClipboard(suggestion)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    // Formatted context output
                    if !formattedContext.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Formatted Context for Claude Code")
                                    .font(.headline)

                                Spacer()

                                Button(action: {
                                    copyToClipboard(formattedContext)
                                    showCopyAllFeedback = true
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                        showCopyAllFeedback = false
                                    }
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: showCopyAllFeedback ? "checkmark" : "doc.on.doc")
                                            .font(.system(size: 14, weight: .medium))
                                        Text(showCopyAllFeedback ? "Copied!" : "Copy All")
                                            .font(.system(size: 14, weight: .semibold))
                                    }
                                    .foregroundColor(showCopyAllFeedback ? .green : .blue)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(showCopyAllFeedback ? Color.green : Color.blue, lineWidth: 1)
                                    )
                                }
                            }
                            .padding(.horizontal)

                            // Context display
                            ScrollView {
                                Text(formattedContext)
                                    .font(.system(.body, design: .monospaced))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(.textBackgroundColor))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color(.separatorColor), lineWidth: 1)
                                            )
                                    )
                            }
                            .frame(maxHeight: 400)
                            .padding(.horizontal)

                            // Usage instructions
                            VStack(alignment: .leading, spacing: 8) {
                                Text("How to use this context:")
                                    .font(.subheadline)
                                    .fontWeight(.medium)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("• Copy the formatted context above")
                                    Text("• Paste it at the beginning of your Claude Code conversation")
                                    Text("• Ask your question with the benefit of book-specific context")
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)
                        }
                    }

                    // Empty state when no query
                    if currentQuery.isEmpty && suggestedContext.isEmpty && formattedContext.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "brain")
                                .font(.system(size: 48, weight: .light))
                                .foregroundColor(.blue)

                            VStack(spacing: 8) {
                                Text("Enter a query to get started")
                                    .font(.title3)
                                    .fontWeight(.medium)

                                Text("Type your technical question and we'll extract relevant context from your book library.")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }

                            // Example queries
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Example queries:")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)

                                VStack(alignment: .leading, spacing: 4) {
                                    ExampleQueryRow(query: "How to design an op-amp circuit")
                                    ExampleQueryRow(query: "Swift async/await best practices")
                                    ExampleQueryRow(query: "Power supply design principles")
                                }
                            }
                        }
                        .padding(.vertical, 40)
                        .padding(.horizontal, 32)
                    }

                    Spacer(minLength: 40)
                }
            }
            .navigationTitle("Claude Code")
        }
    }

    private func generateContext() {
        guard !currentQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        isGeneratingContext = true
        suggestedContext = []
        formattedContext = ""

        Task {
            let contextualObjects = claudeService.getContextForQuery(currentQuery)

            await MainActor.run {
                contextObjectCount = contextualObjects.count
                suggestedContext = claudeService.suggestContextEnhancements(for: currentQuery)
                formattedContext = claudeService.formatContextForClaude(contextualObjects)
                isGeneratingContext = false
            }
        }
    }

    private func copyToClipboard(_ text: String) {
        #if os(macOS)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        #elseif os(iOS)
        UIPasteboard.general.string = text
        #endif
    }
}

/// Row component for example query suggestions
private struct ExampleQueryRow: View {
    let query: String
    @State private var isHovered = false

    var body: some View {
        Button(action: {
            // This would need to be passed down from parent or handled via notification
        }) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)

                Text(query)
                    .font(.caption)
                    .foregroundColor(.primary)

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovered ? Color.blue.opacity(0.1) : Color(.controlBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color(.separatorColor), lineWidth: 0.5)
                    )
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

#Preview {
    ClaudeIntegrationView()
}