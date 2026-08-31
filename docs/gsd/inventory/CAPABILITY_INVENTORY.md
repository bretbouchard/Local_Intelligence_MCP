# LI MCP Capability Inventory — Truth Baseline

**GSD Plan 0.1 evidence.** Status of every advertised tool as of 2026-08-31,
post Phase 0.2/1.x implementation. This file is the source of truth for what
shipped; README claims must match it (Master Plan definition of done).

Implementation statuses: `genuine` (real side effect / real computation),
`deterministic` (pure computation, reproducible), `unavailable-by-design`
(tool exists, reports truthful machine-readable unavailability),
`quarantined` (code excluded from build; needs rewrite).

## Registered MCP tools (33)

### Stable local_* capability tools (Phase 1.4)

| Tool | Status | Implementation | Tests |
|------|--------|----------------|-------|
| `local_capabilities` | genuine | `Tools/LocalIntelligenceTools.swift` → `Core/RuntimeCapabilities.swift`; live OS/model/permission snapshot | `CapabilityKernelTests`, `RuntimeCapabilitiesFeatureTests` |
| `local_generate` | genuine (macOS 26+) | `Providers/AppleFoundationProvider26.swift` via `CapabilityRouter`; FoundationModels `LanguageModelSession.respond` | `CapabilityKernelTests` |
| `local_summarize` | deterministic (default) / genuine (apple engine) | `Providers/DeterministicTextProvider.swift` extractive summarizer; opt-in Apple model | `CapabilityKernelTests` |
| `local_extract` | deterministic | pattern extraction (email/url/date/number); never invents entities | `CapabilityKernelTests` |
| `local_classify` | deterministic | transparent keyword rules | `CapabilityKernelTests` |
| `local_automation_list` | genuine | `Providers/ShortcutsProvider.swift` → `/usr/bin/shortcuts list` | verified by dogfood |
| `local_automation_execute` | genuine side effect | `/usr/bin/shortcuts run <name>`; `didRun` truthful; no shell interpolation; timeout kill | `CapabilityKernelTests` (validation) |

### Legacy compatibility tools

| Tool | Status | Notes |
|------|--------|-------|
| `execute_shortcut` | genuine (rewired 2026-08-31) | Previously **simulated** (random sleep + fabricated success). Now routes through CapabilityRouter → ShortcutsProvider. |
| `list_shortcuts` | genuine (rewired 2026-08-31) | Previously returned a **fabricated catalog** (5 mock shortcuts with invented metadata). Now real enumeration. |
| `voice_command` | unavailable-by-design | Previously **simulated** recognition/execution (fabricated confidence scores). macOS exposes no supported external Voice Control API; now returns `UNSUPPORTED`. Per Plan 2.3, do not re-add simulation. |
| `system_info`, `get_permission_status`, `check_permission` | genuine (deterministic) | SystemInfoTool / PermissionTool |
| `book.analyze` | genuine (deterministic analysis) | BookIntelligenceAnalyzerTool; PDF knowledge extraction |
| `apple_*` text tools (15) | deterministic | Audio-domain text processing tools (summarize, rewrite, normalize, redact, chunk, tokens, intent, query, purpose, schema, tags, catalog, session, feedback) |
| `model_info`, `health_ping`, `capabilities_list` | deterministic | System integration tools |
| `embedding_generation`, `similarity_ranking` | deterministic | Local embedding/similarity computation |

## Providers (CapabilityRouter registry)

| Provider | Class | Capabilities | Availability source |
|----------|-------|--------------|---------------------|
| `apple_foundation_models_26` | appleFoundationModel | generate (+opt-in summarize/extract/classify) | `SystemLanguageModel.default.availability` — physical evidence: generated text on macOS 27 arm64 (dogfood 2026-08-31) |
| `deterministic_text` | deterministic | summarize/extract/classify | always available |
| `shortcuts_cli` | appleAutomation | automation list/execute | `/usr/bin/shortcuts` presence, macOS 12+ |

Routing rules (Plan 1.2): deterministic priority; pinned provider = no
fallback; fallback never crosses outside registered providers; automation
never falls through after an execution attempt (double side effect unsafe).

## Documentation mismatches fixed

- README claimed Voice Control execution; tool was simulated → now documented unavailable.
- Server instructions advertised Shortcuts/Voice Control/Accessibility → rewritten to shipped truth.
- `tools/list` returned empty `properties: {}` for every tool → now exposes authoritative schemas.

## Known gaps / quarantined work

- **Legacy test corpus quarantined** (Package.swift `sources:` allowlist): 25+ test files
  written against long-gone APIs (duplicate mocks, non-open subclassing, corrupted
  array literals). Compile-quarantined, tracked for rewrite; healthy suites:
  `CapabilityKernelTests` (15), `EngineeringTemplatesTests` (40), BDS feature tests (13).
- `MCPConstants.ProtocolInfo.version` string is stale ("2024-11-05"); actual protocol
  negotiation is owned by the MCP Swift SDK (dogfood: negotiated 2025-06-18). Cleanup
  belongs to M1/M2 (MCP 2026-07-28 reconciliation).
- App Intents (Plan 2.2), Accessibility provider (Plan 2.3), structured generation
  with guided schemas (Plan 3.2), FM tool adapter (Plan 3.3): not started.
