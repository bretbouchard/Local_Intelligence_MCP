import SwiftUI

/// Main tab view containing all app sections
struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var showingWelcome = false

    var body: some View {
        TabView(selection: $selectedTab) {
            // Library Tab
            DocumentListView()
                .tabItem {
                    Image(systemName: "book")
                    Text("Library")
                }
                .tag(0)

            // Search Tab
            SearchView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Search")
                }
                .tag(1)

            // Claude Code Integration Tab
            ClaudeIntegrationView()
                .tabItem {
                    Image(systemName: "brain")
                    Text("Claude Code")
                }
                .tag(2)
        }
        .onAppear {
            // Show welcome screen on first launch
            if !UserDefaults.standard.bool(forKey: "hasLaunchedBefore") {
                showingWelcome = true
                UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
            }
        }
        .sheet(isPresented: $showingWelcome) {
            WelcomeView {
                showingWelcome = false
            }
        }
    }
}

/// Placeholder view for Claude Code integration (Task 6)
struct ClaudeIntegrationPlaceholderView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Icon
                Image(systemName: "brain")
                    .font(.system(size: 64, weight: .light))
                    .foregroundColor(.blue)

                // Title
                Text("Claude Code Integration")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                // Description
                VStack(spacing: 16) {
                    Text("Coming in Task 6")
                        .font(.headline)
                        .foregroundColor(.blue)

                    Text("Generate contextual information from your book library to enhance your AI-assisted development workflow.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    // Features preview
                    VStack(alignment: .leading, spacing: 12) {
                        FeatureRow(
                            icon: "doc.text.magnifyingglass",
                            title: "Automatic Context Extraction",
                            description: "Relevant book content automatically extracted based on your queries"
                        )

                        FeatureRow(
                            icon: "brain.head.profile",
                            title: "Smart Context Formatting",
                            description: "Book information formatted for optimal AI understanding"
                        )

                        FeatureRow(
                            icon: "arrow.triangle.2.circlepath",
                            title: "Seamless Integration",
                            description: "Direct integration with Claude Code for enhanced development"
                        )
                    }
                    .padding(.horizontal, 24)
                }

                Spacer()

                // Call to action
                VStack(spacing: 8) {
                    Text("To prepare for this feature:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("Import and process your PDF books in the Library tab")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
                .padding(.bottom, 16)
            }
            .navigationTitle("Claude Code")
        }
    }
}

/// Feature row for placeholder view
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)

                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()
        }
    }
}

/// Welcome view for first-time users
struct WelcomeView: View {
    let onDismiss: () -> Void
    @State private var currentPage = 0

    private let pages = [
        WelcomePage(
            icon: "book",
            title: "Welcome to Book Intelligence",
            description: "Transform your PDF library into a searchable knowledge base powered by AI.",
            feature: "Import and process technical books"
        ),
        WelcomePage(
            icon: "magnifyingglass",
            title: "Natural Language Search",
            description: "Search your entire library using everyday language. Find concepts, examples, and information instantly.",
            feature: "Query across all your documents"
        ),
        WelcomePage(
            icon: "brain",
            title: "AI-Powered Knowledge",
            description: "Automatically extract relationships between concepts and generate contextual information for development.",
            feature: "Enhanced learning and discovery"
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Skip button
            HStack {
                Spacer()
                Button("Skip") {
                    onDismiss()
                }
                .padding()
            }

            // Page content
            TabView(selection: $currentPage) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    WelcomePageView(page: page, isLastPage: index == pages.count - 1) {
                        if index == pages.count - 1 {
                            onDismiss()
                        } else {
                            withAnimation {
                                currentPage = index + 1
                            }
                        }
                    }
                    .tag(index)
                }
            }

            // Page indicators (simplified for macOS)
            HStack(spacing: 8) {
                ForEach(0..<pages.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentPage ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .scaleEffect(index == currentPage ? 1.2 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
                }
            }
            .padding(.bottom, 20)
        }
    }
}

/// Welcome page data
struct WelcomePage {
    let icon: String
    let title: String
    let description: String
    let feature: String
}

/// Welcome page view
struct WelcomePageView: View {
    let page: WelcomePage
    let isLastPage: Bool
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Icon
            Image(systemName: page.icon)
                .font(.system(size: 80, weight: .light))
                .foregroundColor(.blue)

            // Content
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)

                Text(page.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                // Feature highlight
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)

                    Text(page.feature)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
            }

            Spacer()

            // Continue button
            Button(action: onContinue) {
                HStack {
                    Text(isLastPage ? "Get Started" : "Continue")
                        .font(.system(size: 16, weight: .semibold))

                    if isLastPage {
                        Image(systemName: "arrow.right")
                    } else {
                        Image(systemName: "arrow.right")
                    }
                }
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(Color.blue)
                .cornerRadius(12)
            }
            .padding(.bottom, 40)
        }
        .padding(.horizontal, 24)
    }
}

#Preview {
    MainTabView()
}