# M0 — Protocol Inventory and Gap Matrix (MCP 2026-07-28 Reconciliation)

**Date:** 2026-08-31 · **Baseline:** swift-sdk 0.12.1, stdio transport, negotiated
protocol `2025-06-18` (dogfood evidence). Target: MCP `2026-07-28`.

Per `MCP_2026_07_28_RECONCILIATION.md` workstream M0: inventory the current
protocol surface, locate session-era assumptions, and map each 2026-07-28
delta to code/tests/docs or mark it not-applicable.

## Current protocol surface

| Area | Today | Source of truth |
|------|-------|-----------------|
| Transport | stdio only | `Server.swift:125` (`StdioTransport`) |
| Protocol version negotiation | owned by MCP Swift SDK | dogfood: negotiated `2025-06-18` |
| Initialize/session | SDK handshake; **no application session state** — every tool call is independently processable from its envelope | `Server.swift` handlers; stateless core (M1 satisfied at app layer) |
| Server→client requests (sampling/roots) | none registered | `Server.swift` |
| Subscriptions / resource updates | none | — |
| `tools/list` | deterministic, sorted; real per-tool input schemas | `ToolsRegistry.getAvailableTools()` |
| `tools/call` | registry lookup → permission/parameter validation → execute; error envelopes preserved | `StartCommand.handleToolCall` |
| Tool schemas | JSON Schema (draft-era keywords) per tool; new structured subset validated explicitly | tool `inputSchema`s; `JSONSchemaValidator` |
| Auth | none — local stdio trust model; policy enforced per execution (safety gates, permission checks) | `ToolsRegistry`, `SafetyGatedAutomationProvider` |
| Catalog caching hints | not emitted (deterministic ordering makes caching safe) | — |
| Runtime capability truth | `local_capabilities` (separate from protocol discovery) | `RuntimeCapabilities` |

## Gap matrix: 2026-07-28 delta → action

| 2026-07-28 requirement | Status | Action / evidence |
|---|---|---|
| M1 stateless request core | **satisfied at app layer** | No hidden transport-session dependency: independent stdio clients (dogfood) and concurrent calls (tests). SDK handshake remains protocol-plumbing only. |
| M2 `server/discover` + two-layer truth | **gap: protocol discovery method** | Newer SDK required (track upstream release implementing 2026-07-28 discovery). LI `local_capabilities` already provides the runtime layer; document distinction (done, README + inventory). |
| M3 `Mcp-Method`/`Mcp-Name` header routing | **N/A (stdio)** | No HTTP transport shipped. Revisit only if HTTP returns (see LOCAL_KNOWLEDGE_MCP_CLIENT_REVIEW.md). |
| M4 deterministic cacheable catalogs | **satisfied** | `tools/list` byte-stable apart from tool set changes (sorted emission; deterministic provider metadata). No cache hints emitted (truthful default). |
| M5 MRTR input-required continuation | **gap** | No interactive tools remain; automation uses explicit `confirm` flag instead of mid-flight prompts. Revisit if a genuine input-required workflow appears. |
| M6 subscriptions | **gap (optional surface)** | `tools/listChanged: true` capability declared; notifications are SDK-managed. `subscriptions/listen` not implemented — needs SDK support. |
| M7 extensions (Tasks / MCP Apps) | **not applicable yet** | No long-running task semantics shipped (deadlines + provider-owned timeouts cover current workloads). No server-rendered UI. |
| M8 authorization 2026 hardening | **N/A (local-first)** | No OAuth surface exists to harden; stdio trust model documented. Applies if HTTP ever ships. |
| M9 JSON Schema 2020-12 | **partial** | Tool input schemas are per-tool JSON Schema; the structured-generation path uses an explicit 2020-12 subset validator that rejects unsupported constructs (`JSONSchemaValidator`). Remaining: regenerate per-tool schemas with `$schema: 2020-12` declared. |
| M10 deprecation containment (Roots/Sampling/Logging) | **satisfied** | No architectural dependency on any deprecated feature. |
| M11 GSA/Michelle integration | **not started** | External governance stack; out of scope until the governance repo defines its MCP client contract. |
| M12 compatibility matrix | **partial** | stdio modern client (dogfood), macOS 26 FM tier (physical evidence), portable tier via test suite. Legacy-client fallback not exercised (no legacy server exists). |
| M13 dogfood gates | **satisfied for shipped scope** | discover→list→call, capability-vs-protocol separation, real shortcut execution with approval, macOS 26 generation, denial paths, restart between calls, malformed input handling — all exercised. |

## Exit status for M0

Every breaking 2026-07-28 delta maps to: shipped code/tests (M1 app-layer,
M4, M10, partial M9/M12/M13), a documented N/A (M3/M8), a documented boundary
(M5/M7), or an upstream-SDK-blocked gap (M2/M6) with the LI-side contract
already prepared (`local_capabilities`, deterministic catalogs).
