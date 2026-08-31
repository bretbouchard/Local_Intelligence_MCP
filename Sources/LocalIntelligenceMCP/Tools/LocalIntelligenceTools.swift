//
//  LocalIntelligenceTools.swift
//  LocalIntelligenceMCP
//
//  GSD Plan 1.4 — Stable capability-oriented MCP tools (`local_*`).
//  These tools route through the CapabilityRouter; they never select
//  providers or OS implementations directly.
//

import Foundation

// MARK: - local_capabilities

/// Reports the authoritative runtime capability snapshot (GSD Plan 1.1).
/// This is machine runtime truth — distinct from protocol-level discovery.
final class LocalCapabilitiesTool: BaseMCPTool, @unchecked Sendable {

    private let router: CapabilityRouter

    init(logger: Logger, securityManager: SecurityManager, router: CapabilityRouter) {
        self.router = router
        super.init(
            name: MCPConstants.Tools.localCapabilities,
            description: "Report what this Mac can actually do right now: OS tier, Apple Intelligence/model state, permissions, and available local capability IDs with truthful statuses.",
            inputSchema: [
                "type": "object",
                "properties": [:],
                "description": "No parameters."
            ],
            category: .systemInfo,
            requiresPermission: [],
            offlineCapable: true,
            logger: logger,
            securityManager: securityManager
        )
    }

    override func performExecution(parameters: [String: AnyCodable], context: MCPExecutionContext) async throws -> MCPResponse {
        let capabilities = RuntimeCapabilities(providers: await router.registeredProviders())

        var statuses: [String: String] = [:]
        for capability in StableCapability.allCases {
            statuses[capability.rawValue] = capabilities.status(for: capability).rawValue
        }

        let encoder = JSONEncoder()
        var response: [String: Any] = (try? JSONSerialization.jsonObject(with: encoder.encode(capabilities)) as? [String: Any]) ?? [:]
        response["capabilities"] = statuses.sorted { $0.key < $1.key }.reduce(into: [String: Any]()) { $0[$1.key] = $1.value }

        return MCPResponse(success: true, data: AnyCodable(response))
    }
}

// MARK: - local_generate

final class LocalGenerateTool: BaseMCPTool, @unchecked Sendable {

    private let router: CapabilityRouter

    init(logger: Logger, securityManager: SecurityManager, router: CapabilityRouter) {
        self.router = router
        super.init(
            name: MCPConstants.Tools.localGenerate,
            description: "Generate text with the best available local model (Apple on-device Foundation Models on macOS 26+). No remote fallback: unavailable providers surface truthful errors.",
            inputSchema: [
                "type": "object",
                "properties": [
                    "prompt": [
                        "type": "string",
                        "description": "Instruction for the model",
                        "minLength": 1
                    ],
                    "input": [
                        "type": "string",
                        "description": "Optional text the prompt operates on"
                    ],
                    "maxTokens": [
                        "type": "integer",
                        "description": "Maximum output tokens (approximate)",
                        "minimum": 1,
                        "maximum": 4096
                    ],
                    "temperature": [
                        "type": "number",
                        "description": "Sampling temperature (0.0-2.0)",
                        "minimum": 0.0,
                        "maximum": 2.0
                    ],
                    "provider": [
                        "type": "string",
                        "description": "Pin to a specific provider id (e.g. apple_foundation_models_26); disables fallback",
                        "enum": ["apple_foundation_models_26"]
                    ],
                    "timeout": [
                        "type": "number",
                        "description": "Deadline in seconds (default: 120)",
                        "minimum": 1,
                        "maximum": 600
                    ]
                ],
                "required": ["prompt"]
            ],
            category: .textProcessing,
            requiresPermission: [.systemInfo],
            offlineCapable: true,
            logger: logger,
            securityManager: securityManager
        )
    }

    override func performExecution(parameters: [String: AnyCodable], context: MCPExecutionContext) async throws -> MCPResponse {
        guard let prompt = parameters["prompt"]?.value as? String, !prompt.isEmpty else {
            throw CapabilityError.invalidRequest("prompt is required")
        }

        let request = GenerationRequest(
            capability: .localGenerate,
            prompt: prompt,
            input: parameters["input"]?.value as? String ?? "",
            maxOutputTokens: parameters["maxTokens"]?.value as? Int,
            temperature: parameters["temperature"]?.value as? Double,
            deadline: parameters["timeout"]?.value as? Double ?? 120,
            pinnedProvider: parameters["provider"]?.value as? String,
            fallbackAllowed: parameters["provider"]?.value == nil
        )

        let result = try await router.execute(request)
        return MCPResponse(
            success: true,
            data: AnyCodable([
                "text": result.text,
                "provider": [
                    "id": result.provider.id,
                    "displayName": result.provider.displayName,
                    "class": result.provider.providerClass.rawValue
                ],
                "durationSeconds": result.duration
            ])
        )
    }
}

// MARK: - local_summarize

final class LocalSummarizeTool: BaseMCPTool, @unchecked Sendable {

    private let router: CapabilityRouter

    init(logger: Logger, securityManager: SecurityManager, router: CapabilityRouter) {
        self.router = router
        super.init(
            name: MCPConstants.Tools.localSummarize,
            description: "Summarize text. Default engine is deterministic extractive analysis; the Apple on-device model is opt-in via engine parameter.",
            inputSchema: [
                "type": "object",
                "properties": [
                    "text": [
                        "type": "string",
                        "description": "Text to summarize",
                        "minLength": 1
                    ],
                    "sentenceLimit": [
                        "type": "integer",
                        "description": "Maximum sentences in the summary (default: 5)",
                        "minimum": 1,
                        "maximum": 50
                    ],
                    "engine": [
                        "type": "string",
                        "description": "Summarization engine. Default: deterministic (extractive). 'apple' uses the on-device model on macOS 26+ and surfaces truthful errors when unavailable.",
                        "enum": ["deterministic", "apple"]
                    ]
                ],
                "required": ["text"]
            ],
            category: .textProcessing,
            requiresPermission: [.systemInfo],
            offlineCapable: true,
            logger: logger,
            securityManager: securityManager
        )
    }

    override func performExecution(parameters: [String: AnyCodable], context: MCPExecutionContext) async throws -> MCPResponse {
        guard let text = parameters["text"]?.value as? String, !text.isEmpty else {
            throw CapabilityError.invalidRequest("text is required")
        }
        let engine = parameters["engine"]?.value as? String ?? "deterministic"
        let sentenceLimit = parameters["sentenceLimit"]?.value as? Int ?? 5

        let request = GenerationRequest(
            capability: .localSummarize,
            input: text,
            maxOutputTokens: sentenceLimit,
            pinnedProvider: engine == "apple" ? "apple_foundation_models_26" : "deterministic_text",
            fallbackAllowed: false
        )

        let result = try await router.execute(request)
        return MCPResponse(
            success: true,
            data: AnyCodable([
                "summary": result.text,
                "provider": [
                    "id": result.provider.id,
                    "class": result.provider.providerClass.rawValue
                ],
                "durationSeconds": result.duration
            ])
        )
    }
}

// MARK: - local_extract

final class LocalExtractTool: BaseMCPTool, @unchecked Sendable {

    private let router: CapabilityRouter

    init(logger: Logger, securityManager: SecurityManager, router: CapabilityRouter) {
        self.router = router
        super.init(
            name: MCPConstants.Tools.localExtract,
            description: "Extract entities (emails, URLs, dates, numbers) explicitly present in text. Deterministic pattern matching — no model mediation, no hallucinated entities.",
            inputSchema: [
                "type": "object",
                "properties": [
                    "text": [
                        "type": "string",
                        "description": "Text to extract from",
                        "minLength": 1
                    ]
                ],
                "required": ["text"]
            ],
            category: .textProcessing,
            requiresPermission: [.systemInfo],
            offlineCapable: true,
            logger: logger,
            securityManager: securityManager
        )
    }

    override func performExecution(parameters: [String: AnyCodable], context: MCPExecutionContext) async throws -> MCPResponse {
        guard let text = parameters["text"]?.value as? String, !text.isEmpty else {
            throw CapabilityError.invalidRequest("text is required")
        }
        let request = GenerationRequest(
            capability: .localExtract,
            input: text,
            pinnedProvider: "deterministic_text",
            fallbackAllowed: false
        )
        let result = try await router.execute(request)
        return MCPResponse(
            success: true,
            data: AnyCodable([
                "extractions": result.text,
                "provider": result.provider.id,
                "durationSeconds": result.duration
            ])
        )
    }
}

// MARK: - local_classify

final class LocalClassifyTool: BaseMCPTool, @unchecked Sendable {

    private let router: CapabilityRouter

    init(logger: Logger, securityManager: SecurityManager, router: CapabilityRouter) {
        self.router = router
        super.init(
            name: MCPConstants.Tools.localClassify,
            description: "Classify text with a transparent keyword rule set (question, bug_report, feature_request, complaint, praise, general). Apple model classification is opt-in on macOS 26+.",
            inputSchema: [
                "type": "object",
                "properties": [
                    "text": [
                        "type": "string",
                        "description": "Text to classify",
                        "minLength": 1
                    ],
                    "engine": [
                        "type": "string",
                        "description": "Classification engine. Default: deterministic (transparent rules).",
                        "enum": ["deterministic", "apple"]
                    ]
                ],
                "required": ["text"]
            ],
            category: .textProcessing,
            requiresPermission: [.systemInfo],
            offlineCapable: true,
            logger: logger,
            securityManager: securityManager
        )
    }

    override func performExecution(parameters: [String: AnyCodable], context: MCPExecutionContext) async throws -> MCPResponse {
        guard let text = parameters["text"]?.value as? String, !text.isEmpty else {
            throw CapabilityError.invalidRequest("text is required")
        }
        let engine = parameters["engine"]?.value as? String ?? "deterministic"

        let request = GenerationRequest(
            capability: .localClassify,
            input: text,
            pinnedProvider: engine == "apple" ? "apple_foundation_models_26" : "deterministic_text",
            fallbackAllowed: false
        )
        let result = try await router.execute(request)
        return MCPResponse(
            success: true,
            data: AnyCodable([
                "label": result.text,
                "provider": [
                    "id": result.provider.id,
                    "class": result.provider.providerClass.rawValue
                ],
                "durationSeconds": result.duration
            ])
        )
    }
}

// MARK: - local_automation_list

final class LocalAutomationListTool: BaseMCPTool, @unchecked Sendable {

    private let router: CapabilityRouter

    init(logger: Logger, securityManager: SecurityManager, router: CapabilityRouter) {
        self.router = router
        super.init(
            name: MCPConstants.Tools.localAutomationList,
            description: "List the Shortcuts actually installed on this Mac (read-only).",
            inputSchema: [
                "type": "object",
                "properties": [:],
                "description": "No parameters."
            ],
            category: .shortcuts,
            requiresPermission: [],
            offlineCapable: true,
            logger: logger,
            securityManager: securityManager
        )
    }

    override func performExecution(parameters: [String: AnyCodable], context: MCPExecutionContext) async throws -> MCPResponse {
        let names = try await router.listAutomation()
        return MCPResponse(
            success: true,
            data: AnyCodable([
                "shortcuts": names,
                "count": names.count
            ])
        )
    }
}

// MARK: - local_automation_execute

final class LocalAutomationExecuteTool: BaseMCPTool, @unchecked Sendable {

    private let router: CapabilityRouter

    init(logger: Logger, securityManager: SecurityManager, router: CapabilityRouter) {
        self.router = router
        super.init(
            name: MCPConstants.Tools.localAutomationExecute,
            description: "Execute a named Shortcut for real. The response reports didRun=true only when the shortcut actually ran; failures and timeouts are reported as failures.",
            inputSchema: [
                "type": "object",
                "properties": [
                    "name": [
                        "type": "string",
                        "description": "Exact user-visible name of the Shortcut to run",
                        "minLength": 1,
                        "maxLength": 255
                    ],
                    "input": [
                        "type": "string",
                        "description": "Optional text piped to the shortcut's standard input"
                    ],
                    "timeout": [
                        "type": "number",
                        "description": "Maximum execution time in seconds (default: 60)",
                        "minimum": 1,
                        "maximum": 300
                    ]
                ],
                "required": ["name"]
            ],
            category: .shortcuts,
            requiresPermission: [.shortcuts],
            offlineCapable: true,
            logger: logger,
            securityManager: securityManager
        )
    }

    override func performExecution(parameters: [String: AnyCodable], context: MCPExecutionContext) async throws -> MCPResponse {
        guard let name = parameters["name"]?.value as? String, !name.isEmpty else {
            throw CapabilityError.invalidRequest("name is required")
        }
        let input = parameters["input"]?.value as? String
        let timeout = parameters["timeout"]?.value as? Double ?? 60

        let execution = try await router.executeAutomation(name: name, input: input, timeout: timeout)
        return MCPResponse(
            success: execution.didRun,
            data: AnyCodable([
                "name": execution.name,
                "didRun": execution.didRun,
                "output": execution.output,
                "durationSeconds": execution.duration,
                "provider": execution.provider.id
            ])
        )
    }
}
