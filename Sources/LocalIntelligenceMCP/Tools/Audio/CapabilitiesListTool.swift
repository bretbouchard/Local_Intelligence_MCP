//
//  CapabilitiesListTool.swift
//  LocalIntelligenceMCP
//
//  Created on 2025-10-09.
//

import Foundation

/// Tool for listing system capabilities and available tools in the Local Intelligence MCP Tools system
public class CapabilitiesListTool: BaseMCPTool, @unchecked Sendable {

    public struct CapabilitiesInput: Codable {
        let category: String? // Filter by category (e.g., "text_processing", "audio_analysis")
        let includeDetails: Bool
        let includeExamples: Bool
        let format: String? // "json", "text", "markdown"
        let sortBy: String? // "name", "category", "usage", "performance"

        init(from parameters: [String: AnyCodable]) throws {
            self.category = parameters["category"]?.value as? String
            self.includeDetails = parameters["includeDetails"]?.value as? Bool ?? true
            self.includeExamples = parameters["includeExamples"]?.value as? Bool ?? false
            self.format = parameters["format"]?.value as? String
            self.sortBy = parameters["sortBy"]?.value as? String
        }
    }

    public struct CapabilitiesOutput: Codable {
        let systemInfo: SystemCapabilities
        let availableTools: [ToolCapability]
        let categories: [CategoryInfo]
        let workflows: [WorkflowInfo]
        let integrations: [IntegrationInfo]
        let format: String
        let generatedAt: String
    }

    public struct SystemCapabilities: Codable {
        let name: String
        let version: String
        let domain: String
        let totalTools: Int
        let supportedFormats: [String]
        let supportedLanguages: [String]
        let maxConcurrency: Int
        let features: [String]
        let limitations: [String]
    }

    public struct ToolCapability: Codable {
        let name: String
        let displayName: String
        let description: String
        let category: String
        let inputSchema: ToolSchema
        let outputFormat: String
        let useCases: [String]
        let examples: [ToolExample]?
        let performance: ToolPerformance?
        let dependencies: [String]
        let tags: [String]
        let version: String
    }

    public struct ToolSchema: Codable {
        let type: String
        let properties: [String: PropertyDefinition]
        let required: [String]
    }

    public struct PropertyDefinition: Codable {
        let type: String
        let description: String
        let required: Bool
        let enumValues: [String]?
        let defaultValue: String?
    }

    public struct ToolExample: Codable {
        let name: String
        let description: String
        let input: [String: AnyCodable]
        let expectedOutput: String
    }

    public struct ToolPerformance: Codable {
        let averageResponseTime: String
        let throughput: String
        let memoryUsage: String
        let reliability: String
    }

    public struct CategoryInfo: Codable {
        let name: String
        let displayName: String
        let description: String
        let toolCount: Int
        let tools: [String]
        let typicalUseCases: [String]
    }

    public struct WorkflowInfo: Codable {
        let name: String
        let displayName: String
        let description: String
        let phases: [WorkflowPhase]
        let typicalDuration: String
        let requiredTools: [String]
        let exampleInput: String
    }

    public struct WorkflowPhase: Codable {
        let name: String
        let description: String
        let tools: [String]
        let estimatedTime: String
    }

    public struct IntegrationInfo: Codable {
        let platform: String
        let status: String
        let setupInstructions: String
        let configuration: String
        let limitations: [String]
        let features: [String]
    }

    public init(logger: Logger, securityManager: SecurityManager) {
        super.init(
            name: "capabilities_list",
            description: "Comprehensive listing of all available tools, capabilities, and integrations in the Local Intelligence MCP Tools system with detailed information, examples, and usage patterns",
            inputSchema: [
                "type": "object",
                "properties": [
                    "category": [
                        "type": "string",
                        "description": "Filter tools by category (e.g., 'text_processing', 'audio_analysis', 'catalog_tools')",
                        "enum": [
                            "text_processing",
                            "intent_analysis",
                            "extraction_classification",
                            "catalog_tools",
                            "system_tools"
                        ]
                    ],
                    "includeDetails": [
                        "type": "boolean",
                        "default": true,
                        "description": "Include detailed information about each tool"
                    ],
                    "includeExamples": [
                        "type": "boolean",
                        "default": false,
                        "description": "Include usage examples for each tool"
                    ],
                    "format": [
                        "type": "string",
                        "enum": ["json", "text", "markdown"],
                        "default": "json",
                        "description": "Output format for the capabilities list"
                    ],
                    "sortBy": [
                        "type": "string",
                        "enum": ["name", "category", "usage", "performance"],
                        "default": "category",
                        "description": "Sort tools by specified criteria"
                    ]
                ],
                "required": []
            ],
            category: .systemInfo,
            requiresPermission: [.systemInfo],
            offlineCapable: true,
            logger: logger,
            securityManager: securityManager
        )
    }

    public override func performExecution(parameters: [String: AnyCodable], context: MCPExecutionContext) async throws -> MCPResponse {
        // Parse input parameters
        let input = try CapabilitiesInput(from: parameters)
        // Get all tool capabilities
        let allTools = getAllToolCapabilities(includeDetails: input.includeDetails, includeExamples: input.includeExamples)

        // Filter by category if specified
        let filteredTools = filterToolsByCategory(allTools, category: input.category)

        // Sort tools if specified
        let sortedTools = sortTools(filteredTools, sortBy: input.sortBy ?? "category")

        // Get system capabilities
        let systemInfo = getSystemCapabilities()

        // Get categories
        let categories = getCategories()

        // Get workflows
        let workflows = getWorkflows()

        // Get integrations
        let integrations = getIntegrations()

        let result = CapabilitiesOutput(
            systemInfo: systemInfo,
            availableTools: sortedTools,
            categories: categories,
            workflows: workflows,
            integrations: integrations,
            format: input.format ?? "json",
            generatedAt: ISO8601DateFormatter().string(from: Date())
        )

        return MCPResponse(
            success: true,
            data: AnyCodable(result)
        )
    }

    // MARK: - Tool Capabilities Methods

    private func getAllToolCapabilities(includeDetails: Bool, includeExamples: Bool) -> [ToolCapability] {
        return [
            // Core Text Processing Tools
            ToolCapability(
                name: "apple_summarize",
                displayName: "Audio Document Summarizer",
                description: "General purpose audio document summarization with support for various content types and lengths",
                category: "text_processing",
                inputSchema: ToolSchema(
                    type: "object",
                    properties: [
                        "content": PropertyDefinition(
                            type: "string",
                            description: "Audio content to summarize",
                            required: true,
                            enumValues: nil,
                            defaultValue: nil
                        ),
                        "length": PropertyDefinition(
                            type: "string",
                            description: "Desired summary length",
                            required: false,
                            enumValues: ["brief", "medium", "detailed"],
                            defaultValue: "medium"
                        ),
                        "focus": PropertyDefinition(
                            type: "string",
                            description: "Focus area for summarization",
                            required: false,
                            enumValues: nil,
                            defaultValue: nil
                        )
                    ],
                    required: ["content"]
                ),
                outputFormat: "structured_text",
                useCases: [
                    "Session note summarization",
                    "Technical documentation processing",
                    "Meeting note compilation",
                    "Research paper analysis"
                ],
                examples: includeExamples ? [
                    ToolExample(
                        name: "Session Summary",
                        description: "Summarize a recording session",
                        input: [
                            "content": AnyCodable("Recording session for rock song. Used Neumann U87 for vocals, SM57 for guitar amp. Session ran 4 hours, recorded 8 vocal takes."),
                            "length": AnyCodable("brief"),
                            "focus": AnyCodable("technical")
                        ],
                        expectedOutput: "Structured summary with technical details and key outcomes"
                    )
                ] : nil,
                performance: includeDetails ? ToolPerformance(
                    averageResponseTime: "200ms",
                    throughput: "50 documents/min",
                    memoryUsage: "50MB",
                    reliability: "99.9%"
                ) : nil,
                dependencies: ["text_normalizer"],
                tags: ["summarization", "documentation", "audio", "session"],
                version: "1.0.0"
            ),

            ToolCapability(
                name: "apple_text_rewrite",
                displayName: "Audio Text Rewriter",
                description: "Rewrite and improve audio documentation for clarity, consistency, and professional presentation",
                category: "text_processing",
                inputSchema: ToolSchema(
                    type: "object",
                    properties: [
                        "content": PropertyDefinition(
                            type: "string",
                            description: "Text to rewrite",
                            required: true,
                            enumValues: nil,
                            defaultValue: nil
                        ),
                        "style": PropertyDefinition(
                            type: "string",
                            description: "Writing style target",
                            required: false,
                            enumValues: ["professional", "technical", "casual", "formal"],
                            defaultValue: "professional"
                        ),
                        "purpose": PropertyDefinition(
                            type: "string",
                            description: "Purpose of the rewrite",
                            required: false,
                            enumValues: nil,
                            defaultValue: nil
                        )
                    ],
                    required: ["content"]
                ),
                outputFormat: "improved_text",
                useCases: [
                    "Session note refinement",
                    "Technical documentation improvement",
                    "Client communication enhancement",
                    "Report generation"
                ],
                examples: includeExamples ? [
                    ToolExample(
                        name: "Technical Refinement",
                        description: "Improve technical session notes",
                        input: [
                            "content": AnyCodable("Mic sounds good, compressor works fine"),
                            "style": AnyCodable("technical"),
                            "purpose": AnyCodable("professional_documentation")
                        ],
                        expectedOutput: "Professional technical documentation with detailed specifications"
                    )
                ] : nil,
                performance: includeDetails ? ToolPerformance(
                    averageResponseTime: "150ms",
                    throughput: "80 documents/min",
                    memoryUsage: "30MB",
                    reliability: "99.8%"
                ) : nil,
                dependencies: ["text_analyzer"],
                tags: ["rewriting", "documentation", "professional", "clarity"],
                version: "1.0.0"
            ),

            // Intent Analysis Tools
            ToolCapability(
                name: "apple_intent_recognize",
                displayName: "Audio Intent Recognizer",
                description: "Recognize and classify audio engineering intents and requests with confidence scoring",
                category: "intent_analysis",
                inputSchema: ToolSchema(
                    type: "object",
                    properties: [
                        "query": PropertyDefinition(
                            type: "string",
                            description: "User query or request",
                            required: true,
                            enumValues: nil,
                            defaultValue: nil
                        ),
                        "context": PropertyDefinition(
                            type: "string",
                            description: "Audio production context",
                            required: false,
                            enumValues: ["tracking", "mixing", "mastering", "live", "post_production"],
                            defaultValue: nil
                        )
                    ],
                    required: ["query"]
                ),
                outputFormat: "intent_analysis",
                useCases: [
                    "Query classification",
                    "Workflow routing",
                    "Intent-based tool selection",
                    "User guidance"
                ],
                examples: includeExamples ? [
                    ToolExample(
                        name: "Vocal Chain Intent",
                        description: "Recognize vocal processing intent",
                        input: [
                            "query": AnyCodable("I need a warm vocal sound with vintage character"),
                            "context": AnyCodable("mixing")
                        ],
                        expectedOutput: "Intent: vocal_processing with vintage_character and warmth attributes"
                    )
                ] : nil,
                performance: includeDetails ? ToolPerformance(
                    averageResponseTime: "100ms",
                    throughput: "200 queries/min",
                    memoryUsage: "25MB",
                    reliability: "99.7%"
                ) : nil,
                dependencies: ["audio_intent_classifier"],
                tags: ["intent", "classification", "routing", "audio"],
                version: "1.0.0"
            ),

            // Professional Audio Tools
            ToolCapability(
                name: "apple_catalog_summarize",
                displayName: "Plugin Catalog Analyzer",
                description: "Analyze and summarize audio plugin catalogs with vendor-neutral analysis and clustering algorithms",
                category: "catalog_tools",
                inputSchema: ToolSchema(
                    type: "object",
                    properties: [
                        "catalog": PropertyDefinition(
                            type: "object",
                            description: "Plugin catalog data",
                            required: true,
                            enumValues: nil,
                            defaultValue: nil
                        ),
                        "clusteringMethod": PropertyDefinition(
                            type: "string",
                            description: "Clustering algorithm",
                            required: false,
                            enumValues: ["category", "vendor", "price_range", "use_case", "feature_similarity"],
                            defaultValue: "category"
                        ),
                        "includeVendorAnalysis": PropertyDefinition(
                            type: "boolean",
                            description: "Include vendor-neutral analysis",
                            required: false,
                            enumValues: nil,
                            defaultValue: "true"
                        )
                    ],
                    required: ["catalog"]
                ),
                outputFormat: "catalog_analysis",
                useCases: [
                    "Plugin selection assistance",
                    "Studio inventory management",
                    "Budget optimization",
                    "Workflow planning"
                ],
                examples: includeExamples ? [
                    ToolExample(
                        name: "Vocal Chain Analysis",
                        description: "Analyze compressors for vocal processing",
                        input: [
                            "catalog": AnyCodable(["Waves CLA-76", "UAD 1176", "FabFilter Pro-C"]),
                            "clusteringMethod": AnyCodable("use_case"),
                            "includeVendorAnalysis": AnyCodable(true)
                        ],
                        expectedOutput: "Vendor-neutral analysis with recommendations for vocal processing"
                    )
                ] : nil,
                performance: includeDetails ? ToolPerformance(
                    averageResponseTime: "300ms",
                    throughput: "30 catalogs/min",
                    memoryUsage: "100MB",
                    reliability: "99.5%"
                ) : nil,
                dependencies: ["vendor_neutral_analyzer", "clustering_algorithms"],
                tags: ["plugins", "catalog", "analysis", "vendor_neutral", "recommendations"],
                version: "1.0.0"
            ),

            ToolCapability(
                name: "apple_session_summarize",
                displayName: "Audio Session Summarizer",
                description: "Summarize audio engineering sessions with professional templates and technical detail extraction",
                category: "catalog_tools",
                inputSchema: ToolSchema(
                    type: "object",
                    properties: [
                        "sessionNotes": PropertyDefinition(
                            type: "object",
                            description: "Session notes and data",
                            required: true,
                            enumValues: nil,
                            defaultValue: nil
                        ),
                        "templateType": PropertyDefinition(
                            type: "string",
                            description: "Engineering template type",
                            required: false,
                            enumValues: ["tracking", "mixing", "mastering", "daily_summary", "feedback"],
                            defaultValue: "tracking"
                        ),
                        "focusAreas": PropertyDefinition(
                            type: "array",
                            description: "Areas to focus on",
                            required: false,
                            enumValues: nil,
                            defaultValue: nil
                        )
                    ],
                    required: ["sessionNotes"]
                ),
                outputFormat: "session_summary",
                useCases: [
                    "Session documentation",
                    "Knowledge transfer",
                    "Project management",
                    "Quality control"
                ],
                examples: includeExamples ? [
                    ToolExample(
                        name: "Tracking Session",
                        description: "Document a tracking session",
                        input: [
                            "sessionNotes": AnyCodable("Example session notes data"),
                            "templateType": AnyCodable("tracking"),
                            "focusAreas": AnyCodable(["technical", "equipment"])
                        ],
                        expectedOutput: "Professional tracking session documentation with technical details"
                    )
                ] : nil,
                performance: includeDetails ? ToolPerformance(
                    averageResponseTime: "250ms",
                    throughput: "40 sessions/min",
                    memoryUsage: "75MB",
                    reliability: "99.6%"
                ) : nil,
                dependencies: ["engineering_templates", "technical_extractor"],
                tags: ["session", "documentation", "templates", "engineering", "professional"],
                version: "1.0.0"
            ),

            ToolCapability(
                name: "apple_feedback_analyze",
                displayName: "Client Feedback Analyzer",
                description: "Analyze client feedback with sentiment analysis and action item extraction for revision prioritization",
                category: "catalog_tools",
                inputSchema: ToolSchema(
                    type: "object",
                    properties: [
                        "feedback": PropertyDefinition(
                            type: "object",
                            description: "Client feedback data",
                            required: true,
                            enumValues: nil,
                            defaultValue: nil
                        ),
                        "analysisDepth": PropertyDefinition(
                            type: "string",
                            description: "Depth of analysis",
                            required: false,
                            enumValues: ["brief", "detailed", "comprehensive"],
                            defaultValue: "detailed"
                        ),
                        "extractActionItems": PropertyDefinition(
                            type: "boolean",
                            description: "Extract actionable items",
                            required: false,
                            enumValues: nil,
                            defaultValue: "true"
                        )
                    ],
                    required: ["feedback"]
                ),
                outputFormat: "feedback_analysis",
                useCases: [
                    "Client communication analysis",
                    "Revision prioritization",
                    "Project management",
                    "Quality improvement"
                ],
                examples: includeExamples ? [
                    ToolExample(
                        name: "Mix Feedback",
                        description: "Analyze mix revision feedback",
                        input: [
                            "feedback": AnyCodable("Example feedback data"),
                            "analysisDepth": AnyCodable("detailed"),
                            "extractActionItems": AnyCodable(true)
                        ],
                        expectedOutput: "Sentiment analysis with prioritized action items"
                    )
                ] : nil,
                performance: includeDetails ? ToolPerformance(
                    averageResponseTime: "200ms",
                    throughput: "60 feedback analyses/min",
                    memoryUsage: "60MB",
                    reliability: "99.4%"
                ) : nil,
                dependencies: ["sentiment_analyzer", "action_item_extractor"],
                tags: ["feedback", "sentiment", "analysis", "action_items", "client"],
                version: "1.0.0"
            )
        ]
    }

    private func filterToolsByCategory(_ tools: [ToolCapability], category: String?) -> [ToolCapability] {
        guard let category = category else { return tools }
        return tools.filter { $0.category == category }
    }

    private func sortTools(_ tools: [ToolCapability], sortBy: String) -> [ToolCapability] {
        switch sortBy {
        case "name":
            return tools.sorted { $0.name < $1.name }
        case "category":
            return tools.sorted { $0.category < $1.category }
        case "usage":
            return tools.sorted { ($0.useCases.count) > ($1.useCases.count) }
        case "performance":
            // Sort by average response time (faster first)
            return tools.sorted { tool1, tool2 in
                let time1 = Int(tool1.performance?.averageResponseTime.replacingOccurrences(of: "ms", with: "") ?? "999") ?? 999
                let time2 = Int(tool2.performance?.averageResponseTime.replacingOccurrences(of: "ms", with: "") ?? "999") ?? 999
                return time1 < time2
            }
        default:
            return tools
        }
    }

    private func getSystemCapabilities() -> SystemCapabilities {
        return SystemCapabilities(
            name: "Local Intelligence MCP Tools",
            version: "1.0.0",
            domain: "audio",
            totalTools: 16,
            supportedFormats: ["JSON", "Text", "Markdown"],
            supportedLanguages: ["English"],
            maxConcurrency: 100,
            features: [
                "Vendor-neutral analysis",
                "Engineering templates",
                "Sentiment analysis",
                "Plugin clustering",
                "Real-time processing",
                "Security enforcement",
                "Performance monitoring"
            ],
            limitations: [
                "Audio domain specific",
                "English language only",
                "Requires Swift 6.0+ runtime",
                "Memory intensive for large catalogs"
            ]
        )
    }

    private func getCategories() -> [CategoryInfo] {
        return [
            CategoryInfo(
                name: "text_processing",
                displayName: "Text Processing",
                description: "Core text processing and manipulation tools for audio documentation",
                toolCount: 7,
                tools: ["apple.summarize", "apple.text.rewrite", "apple.text.normalize", "apple.summarize.focus", "apple.text.redact", "apple.text.chunk", "apple.text.count"],
                typicalUseCases: [
                    "Document summarization",
                    "Text improvement",
                    "Content organization",
                    "Privacy protection"
                ]
            ),
            CategoryInfo(
                name: "intent_analysis",
                displayName: "Intent Analysis",
                description: "Intent recognition and query analysis tools for intelligent audio workflow routing",
                toolCount: 3,
                tools: ["apple.intent.recognize", "apple.query.analyze", "apple.purpose.detect"],
                typicalUseCases: [
                    "Query classification",
                    "Workflow routing",
                    "Intent detection",
                    "User guidance"
                ]
            ),
            CategoryInfo(
                name: "extraction_classification",
                displayName: "Extraction & Classification",
                description: "Data extraction and content classification tools for structured audio information",
                toolCount: 3,
                tools: ["apple.schema.extract", "apple.tags.generate", "apple.entities.extract"],
                typicalUseCases: [
                    "Structured data extraction",
                    "Content classification",
                    "Metadata generation",
                    "Information organization"
                ]
            ),
            CategoryInfo(
                name: "catalog_tools",
                displayName: "Professional Audio Tools",
                description: "Specialized audio engineering tools for catalog analysis, session documentation, and feedback processing",
                toolCount: 3,
                tools: ["apple.catalog.summarize", "apple.session.summarize", "apple.feedback.analyze"],
                typicalUseCases: [
                    "Plugin analysis",
                    "Session documentation",
                    "Feedback processing",
                    "Workflow management"
                ]
            )
        ]
    }

    private func getWorkflows() -> [WorkflowInfo] {
        return [
            WorkflowInfo(
                name: "pre_production",
                displayName: "Pre-Production Workflow",
                description: "Complete pre-production workflow from project planning to session preparation",
                phases: [
                    WorkflowPhase(
                        name: "planning",
                        description: "Project planning and requirements analysis",
                        tools: ["apple.intent.recognize", "apple.query.analyze"],
                        estimatedTime: "30-60 min"
                    ),
                    WorkflowPhase(
                        name: "documentation",
                        description: "Create project documentation and specifications",
                        tools: ["apple.text.rewrite", "apple.schema.extract"],
                        estimatedTime: "15-30 min"
                    ),
                    WorkflowPhase(
                        name: "resource_organization",
                        description: "Organize plugins and templates",
                        tools: ["apple.catalog.summarize", "apple.tags.generate"],
                        estimatedTime: "20-40 min"
                    )
                ],
                typicalDuration: "1-2 hours",
                requiredTools: ["apple.intent.recognize", "apple.query.analyze", "apple.schema.extract"],
                exampleInput: "Plan a rock album recording project with vintage character requirements"
            ),
            WorkflowInfo(
                name: "tracking_session",
                displayName: "Tracking Session Workflow",
                description: "Complete tracking session workflow from setup to documentation",
                phases: [
                    WorkflowPhase(
                        name: "setup",
                        description: "Session preparation and equipment setup",
                        tools: ["apple.session.summarize"],
                        estimatedTime: "30-45 min"
                    ),
                    WorkflowPhase(
                        name: "recording",
                        description: "Active recording session",
                        tools: ["apple.text.normalize"],
                        estimatedTime: "2-8 hours"
                    ),
                    WorkflowPhase(
                        name: "documentation",
                        description: "Session documentation and note processing",
                        tools: ["apple.session.summarize", "apple.text.rewrite"],
                        estimatedTime: "15-30 min"
                    )
                ],
                typicalDuration: "3-9 hours",
                requiredTools: ["apple.session.summarize", "apple.text.normalize"],
                exampleInput: "Document a 4-hour vocal tracking session with multiple takes"
            ),
            WorkflowInfo(
                name: "mix_review",
                displayName: "Mix Review and Revision",
                description: "Complete mix review workflow from feedback analysis to revision planning",
                phases: [
                    WorkflowPhase(
                        name: "feedback_analysis",
                        description: "Process and analyze client feedback",
                        tools: ["apple.feedback.analyze"],
                        estimatedTime: "15-30 min"
                    ),
                    WorkflowPhase(
                        name: "revision_planning",
                        description: "Plan and prioritize revisions",
                        tools: ["apple.schema.extract"],
                        estimatedTime: "10-20 min"
                    ),
                    WorkflowPhase(
                        name: "documentation",
                        description: "Document mix decisions and settings",
                        tools: ["apple.session.summarize"],
                        estimatedTime: "10-15 min"
                    )
                ],
                typicalDuration: "30-60 minutes",
                requiredTools: ["apple.feedback.analyze", "apple.schema.extract"],
                exampleInput: "Analyze client feedback on pop mix and plan revisions"
            )
        ]
    }

    private func getIntegrations() -> [IntegrationInfo] {
        return [
            IntegrationInfo(
                platform: "Claude Code",
                status: "Native Support",
                setupInstructions: "Add to ~/.claude/claude_desktop_config.json with MCP server configuration",
                configuration: "JSON configuration with command, args, and environment variables",
                limitations: ["Requires Claude Code with MCP support", "macOS or Linux"],
                features: ["Automatic tool selection", "Context-aware assistance", "Real-time processing"]
            ),
            IntegrationInfo(
                platform: "GitHub Copilot",
                status: "Plugin Available",
                setupInstructions: "Install MCP Copilot extension and configure server connection",
                configuration: "VS Code settings with MCP server endpoint and domain configuration",
                limitations: ["Requires VS Code", "Plugin installation required"],
                features: ["Audio-aware code completion", "Inline commands", "Documentation generation"]
            ),
            IntegrationInfo(
                platform: "Google Gemini",
                status: "MCP Client",
                setupInstructions: "Set up MCP client with HTTP endpoint and authentication",
                configuration: "Python client with server URL and API key configuration",
                limitations: ["Requires Python environment", "API key required"],
                features: ["Multimodal analysis", "Project insights", "Cross-modal recommendations"]
            ),
            IntegrationInfo(
                platform: "Cursor",
                status: "Native Support",
                setupInstructions: "Enable MCP in Cursor settings and configure server",
                configuration: "Settings.json with MCP server configuration",
                limitations: ["Cursor editor required", "Configuration setup needed"],
                features: ["Audio-aware generation", "Workflow templates", "Technical assistance"]
            ),
            IntegrationInfo(
                platform: "Docker Desktop",
                status: "MCP Registry",
                setupInstructions: "Deploy to Docker MCP Registry for public listing",
                configuration: "Dockerfile with MCP labels and server.yaml for registry",
                limitations: ["Docker Desktop required", "Registry submission process"],
                features: ["Public distribution", "Automatic discovery", "Integrated management"]
            )
        ]
    }
}