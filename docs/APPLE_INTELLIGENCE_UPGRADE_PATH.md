# Local Intelligence MCP — Apple Intelligence Upgrade Path

Status: SHIPPED 2026-08-31 — see docs/gsd/inventory/CAPABILITY_INVENTORY.md for the
shipped state and docs/gsd/reviews/ for the council review evidence.
Target: preserve broad macOS compatibility while progressively exposing Apple-native intelligence when available.

## Product direction

Local Intelligence MCP is a lightweight bridge between MCP clients/agents and useful Apple-local capabilities. The server must not require the newest OS just to run. Instead, it discovers capabilities at runtime and exposes the best implementation available on that Mac.

The project therefore has two independent layers:

1. **Portable MCP shell** — protocol, schemas, policy enforcement, permissions, logging, security, health, basic deterministic text/system tools.
2. **Apple capability providers** — Shortcuts/App Intents, Foundation Models, Vision, Spotlight, and newer Apple Intelligence facilities gated by OS, hardware, user settings, and model availability.

Do not make Foundation Models the server architecture. It is one provider behind a stable MCP contract.

## Current codebase assessment

### Strong foundation already present

- Swift 6 package and executable MCP server.
- MCP Swift SDK integration.
- Tool registry / standardized tool abstraction.
- Policy enforcement and permission concepts.
- Security, validation, logging, metrics and health infrastructure.
- Shortcuts, system information and voice-control tool surfaces already modeled.
- Audio-domain tool infrastructure exists and can remain optional.
- Deployment target currently allows macOS 13+, which is appropriate for the compatibility goal.

### Critical gaps / misleading current behavior

- `ShortcutsTool` does not execute an Apple Shortcut. Metadata is mocked and execution sleeps, synthesizes a success result, and returns simulated output.
- `VoiceControlTool` does not drive macOS Accessibility or Voice Control. Availability, recognition and command execution are simulated.
- `Package.swift` contains no FoundationModels integration or conditional Apple Intelligence target.
- There is currently no `SystemLanguageModel`, `LanguageModelSession`, guided generation, Apple `Tool` bridge, Dynamic Profiles, multimodal attachment support, Vision system-tool bridge, Spotlight semantic search, Private Cloud Compute provider, Evaluations integration, or `fm` CLI/Python integration.
- Capability reporting needs to describe actual runtime availability instead of assuming a configured feature is implemented or usable.
- The README currently describes several capabilities as production integrations that the implementation does not yet provide. Rewrite documentation alongside implementation and clearly label compatibility tiers.

## Compatibility model

Use runtime capability discovery rather than a single minimum OS bump.

### Tier 0 — macOS 13+

Purpose: universal MCP utility layer.

Keep working:
- MCP transport and tool discovery
- security/policy layer
- deterministic text transforms that do not depend on an LLM
- PII redaction
- system information
- health / capability inspection
- logging and auditing

Apple actions should be exposed only where a genuine implementation exists.

### Tier 1 — Apple automation provider

Implement real macOS automation independently of Foundation Models so older Macs remain useful.

Add:
- real Shortcuts enumeration and execution using supported macOS mechanisms
- deterministic input/output passing
- actual timeout/cancellation behavior
- permission and availability reporting
- optional App Intents bridge where an installed application exposes useful intents
- Accessibility automation only as an explicitly permissioned fallback, never simulated Voice Control

The public tool should describe the action generically; the provider reports which backend it is using.

### Tier 2 — macOS 26 / Foundation Models v1

Conditionally import FoundationModels and add an Apple on-device language-model provider.

Add:
- `SystemLanguageModel.default` availability detection
- `LanguageModelSession`
- streaming response support
- guided generation / `@Generable` for structured MCP results
- Apple Foundation Models `Tool` adapter backed by the existing MCP tool registry
- transcript/session handling
- explicit fallback when Apple Intelligence hardware/settings/model availability make the system model unavailable

Initial MCP tools:
- `apple_model_status`
- `apple_generate`
- `apple_generate_structured`
- `apple_summarize`
- `apple_extract`
- `apple_classify`

Do not use the on-device model for deterministic computation or code generation where Apple advises other mechanisms. Preserve existing deterministic implementations as tools/fallbacks.

### Tier 3 — macOS 27 / Foundation Models v2

Add the 2026 Foundation Models expansion while retaining the same MCP API where possible.

Add:
- `LanguageModel` provider abstraction so Apple on-device, Private Cloud Compute and optional third-party providers can sit behind one internal protocol
- multimodal image attachments
- Vision system tools such as OCR/barcode/image understanding where available
- Spotlight/semantic-search system tooling where appropriate
- Dynamic Profiles for runtime composition of model + tools + instructions
- improved context management and model/session error mapping
- next-generation on-device model behavior tests
- Private Cloud Compute provider as an opt-in capability when eligibility and platform requirements are satisfied
- Evaluations framework suites for prompts, structured generation, tool selection and agent behavior
- optional `fm` CLI interoperability on macOS 27
- optional Foundation Models Python SDK adapter for non-Swift clients/tests; MCP remains the primary cross-client interface

## Architecture changes

Introduce these boundaries:

```text
MCP client
   |
MCPServer / ToolsRegistry
   |
CapabilityRouter
   +-- DeterministicProvider        macOS 13+
   +-- AppleAutomationProvider      supported older/newer macOS
   +-- AppleFoundationProvider26    macOS 26+ / Apple Intelligence available
   +-- AppleFoundationProvider27    macOS 27+ enhancements
   +-- OptionalExternalProvider     future LanguageModel adapters
```

### New core types

- `CapabilityID`
- `CapabilityStatus`
- `RuntimeCapabilities`
- `CapabilityRouter`
- `IntelligenceProvider`
- `GenerationRequest`
- `GenerationResult`
- `StructuredGenerationRequest`
- `ModelAvailabilityReason`

`RuntimeCapabilities` must include OS version, architecture, Apple Intelligence/model availability, relevant permissions, supported Foundation Models feature level, and provider state without leaking sensitive system data.

## File plan

Recommended structure:

```text
Sources/LocalIntelligenceMCP/
  Intelligence/
    IntelligenceProvider.swift
    CapabilityRouter.swift
    RuntimeCapabilities.swift
    Apple26/
      AppleFoundationModelsProvider.swift
      AppleFoundationToolAdapter.swift
      AppleStructuredGeneration.swift
    Apple27/
      AppleDynamicProfileProvider.swift
      AppleMultimodalProvider.swift
      AppleSystemToolsProvider.swift
      ApplePCCProvider.swift
  Automation/
    AppleShortcutsProvider.swift
    AppIntentsProvider.swift
    AccessibilityProvider.swift
  Tools/
    Intelligence/
      ModelStatusTool.swift
      GenerateTool.swift
      StructuredGenerateTool.swift
      SummarizeTool.swift
      ExtractTool.swift
      ClassifyTool.swift
```

Keep Apple-version-specific types isolated behind availability checks so the package can retain the older deployment target.

## Tool design rule

MCP tool names should describe capability, not OS implementation.

Prefer:
- `local_generate`
- `local_summarize`
- `local_extract`
- `local_image_understand`
- `local_automation_execute`

Avoid making clients depend on names such as `foundation_models_27_generate`.

Every result should optionally include provider metadata such as `apple_on_device`, `apple_pcc`, `deterministic`, or another configured provider.

## Testing

### Tier matrix

CI/build validation:
- oldest supported Swift/macOS-compatible path
- macOS 26 build
- macOS 27 build

Runtime tests must distinguish:
- OS supports API but device is not Apple Intelligence eligible
- eligible but Apple Intelligence disabled
- model downloading/not ready
- model available
- permission denied
- provider/tool unavailable

### Behavioral tests

- no tool may return a simulated success for an unperformed side effect
- structured generation schema validity
- tool-call selection and argument validity
- cancellation/timeout correctness
- transcript/context boundaries
- fallback behavior
- prompt regression tests for both macOS 26 and the changed macOS 27 system model
- Evaluations framework suites on macOS 27 in addition to conventional tests

## Migration sequence

### Wave 1 — Truth and capability discovery

1. Add `RuntimeCapabilities` and `CapabilityRouter`.
2. Rewrite health/capabilities output around actual runtime state.
3. Replace simulated Shortcuts success with real execution or explicit unsupported error.
4. Replace simulated Voice Control with a real explicitly-permissioned backend or remove the tool until implemented.
5. Rewrite README to state the actual Apple integration clearly and accurately.

Exit: LI MCP never claims an action happened when it did not.

### Wave 2 — macOS 26 Apple Intelligence

1. Add conditional FoundationModels provider.
2. Availability checks and fallback.
3. Text generation + streaming.
4. Guided/structured generation.
5. Existing MCP tool registry -> Foundation Models `Tool` adapter.
6. Summarize/extract/classify tools migrated to the Apple provider where appropriate.

Exit: MCP clients can use Apple's on-device model through stable tools on supported Macs while macOS 13–25 continues to run the non-FM server.

### Wave 3 — macOS 27 agentic expansion

1. Adopt the `LanguageModel` abstraction internally.
2. Dynamic Profiles.
3. Multimodal image input.
4. Vision and Spotlight system tools.
5. context-management/error API updates.
6. Private Cloud Compute provider.
7. Evaluations suites.
8. `fm` interoperability and optional Python SDK examples.

Exit: one MCP presents the best Apple intelligence available on the machine without forcing every user onto macOS 27.

### Wave 4 — hardening and public release

1. Cross-version compatibility matrix in CI/documentation.
2. Real integration/E2E tests for every side-effecting Apple tool.
3. Performance benchmarks.
4. Security review of model-to-tool boundary.
5. README/API docs/examples rewritten around Apple-native local intelligence.
6. Remove stale claims, placeholder license text, mock terminology and unsupported platform claims.

## Public positioning

Suggested first-line description:

> Local Intelligence MCP is a lightweight Swift MCP server that gives AI agents practical access to Apple's local intelligence and automation stack, using the best capabilities available on each Mac while preserving graceful support for older systems.

The README should explicitly name Apple Foundation Models, Shortcuts/App Intents, Vision/Spotlight where implemented, on-device execution, and runtime capability fallback. Do not imply that Linux can expose Apple capabilities; Linux/portable builds, if retained, should be described as the portable MCP core only.

## Apple references to verify during implementation

Use current Apple Developer documentation for:
- Foundation Models framework
- Foundation Models updates (June 2026)
- generating content / model availability
- expanding generation with tool calling
- WWDC26 Foundation Models updates
- macOS 27 / Apple Intelligence developer guides

The API surface is changing quickly; implementation must compile against the intended Xcode SDK rather than relying solely on this plan.