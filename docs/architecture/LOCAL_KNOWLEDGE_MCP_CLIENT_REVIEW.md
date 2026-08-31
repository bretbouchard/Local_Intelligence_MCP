# Architectural Review: local_knowledge ↔ Local Intelligence MCP Integration

**Bead:** local_intelligence_mcp-5 · **Date:** 2026-08-31 · **Verdict:** Direct MCP client over **stdio** (spawn the server); do not build HTTP; use in-process FoundationModels only where no server tool adds value.

## Question

Should the local_knowledge SwiftUI app implement the MCP client protocol directly instead of HTTP requests to the Local Intelligence MCP server?

## Key finding: the HTTP premise is obsolete

The review's either/or assumed an HTTP deployment. The shipped server no longer has one: `StartCommand` wires **`StdioTransport` only** (`Sources/LocalIntelligenceMCP/Server.swift:125`); the legacy `MCPServer` class carries no transport wiring, and the docker HTTP configs predate the current architecture. So "keep using HTTP" is not a live option — some rework was required regardless.

Additionally, the server contract changed materially in the Phase 0+1 upgrade (2026-08-31): capability truth now lives in `local_capabilities`, tools are the stable `local_*` set, and unavailability is machine-readable (`UNSUPPORTED` / `DISABLED` / `NOT_READY` / `PERMISSION_DENIED`). Any integration should be built against these contracts, not against the old ad-hoc tool surface.

## Options considered

| Option | Assessment |
|--------|------------|
| A. HTTP client → server | ❌ Transport does not ship; adding Streamable HTTP (M-candidate M3) for one local app adds auth, header-validation and deployment surface for no local-first benefit. Revisit only if LAN/remote deployment becomes a requirement. |
| B. **MCP client over stdio** (embed MCP Swift SDK, spawn `local-intelligence-mcp` as a child process) | ✅ **Recommended.** Protocol-standard lifecycle (initialize → tools/list → tools/call), process isolation (server crash ≠ app crash), zero ports/auth (inherit stdio trust model), and the app automatically tracks the server's growing capability set (`local_*`, `book.analyze`, automation) via `local_capabilities` instead of hardcoded feature flags. |
| C. In-process package dependency (link the server's `ToolsRegistry`/`CapabilityRouter` directly) | ⚠️ Lowest latency, but couples the app to server internals (SecurityManager, Keychain access in the app's process), creates a second host for policy-gated tools, and bypasses the audit/policy boundary the server owns. Reject for now. |
| D. In-process Apple FoundationModels (no MCP) | ✅ **Complement, not replacement.** For pure on-device generation inside the app (macOS 26+), importing FoundationModels directly is simpler and lower-latency than any IPC. Use it for app-local LLM needs; use MCP (B) for the server-owned capabilities: deterministic text pipeline, PII redaction, Book Intelligence PDF analysis, Shortcuts automation, and capability-truth reporting. |

## Recommended architecture

```text
local_knowledge (SwiftUI, macOS 26+)
 ├─ FoundationModels in-process        → on-device generation for app-local features
 └─ MCP Swift SDK (stdio client)
      └─ spawns LocalIntelligenceMCP   → local_* tools, book.analyze, automation
```

Integration rules (aligning with GSD Phase 1 contracts):

1. **Discover, don't hardcode**: call `local_capabilities` on startup; gate UI on returned statuses (e.g. summarize is always available deterministically; `local_generate` availability is machine-truth, not an OS check in the app).
2. **Handle the error taxonomy**: render `UNSUPPORTED` / `DISABLED` / `NOT_READY` / `PERMISSION_DENIED` as distinct UI states (they are designed to be distinguishable).
3. **Deterministic-first**: prefer server deterministic tools (`local_summarize`/`local_extract`/`local_classify` default engine) unless the feature specifically needs model quality; opt into the Apple engine per-request, never as a hidden fallback.
4. **Process lifecycle**: spawn the server binary at app start, restart on abnormal exit, kill on app termination; requests are stateless, so restart is cheap.
5. **Latency note**: deterministic tool calls are sub-millisecond server-side; JSON-RPC over stdio adds ~1ms — imperceptible for document workflows.

## Migration sketch (for the app repo)

1. Add `https://github.com/modelcontextprotocol/swift-sdk.git` dependency.
2. Implement a thin `MCPClientService` actor: spawn process, `initialize`, `tools/list` cache, `tools/call` wrapper with typed errors.
3. Replace each existing HTTP call with the corresponding tool call (the HTTP endpoints were thin wrappers around these same tools).
4. Gate features on `local_capabilities` rather than version checks.

## Caveat

The app's source lives outside this repository; this review is written against the server's current, verified contract. Wiring details (exact spawn paths, sandboxing/entitlements for child processes if the app is sandboxed) must be confirmed in the app repo. Note: a sandboxed Mac App Store build cannot spawn child processes — if local_knowledge is sandboxed, in-process distribution (Option C) returns to the table with its coupling costs.

## Resolution

Recommendation adopted at architecture level; bead closed with this document as evidence. Follow-up implementation belongs to the local_knowledge app repository (tracked there), conditional on confirming the app's sandbox status.
