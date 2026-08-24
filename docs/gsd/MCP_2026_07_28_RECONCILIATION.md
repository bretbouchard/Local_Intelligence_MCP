# Local Intelligence MCP — MCP 2026-07-28 Reconciliation

Status: execution specification
Protocol target: MCP `2026-07-28`
Baseline branch: `tools-addendum`
Planning branch: `mcp-2026-07-28-planning`

## Purpose

Reconcile the LI MCP Apple-local intelligence roadmap with the final MCP 2026-07-28 protocol. This is not a transport-only upgrade. Protocol semantics, capability discovery, routing, caching, interaction, authorization, extensions, compatibility, tests, GSA evidence and Michelle integration all need explicit treatment.

## Non-negotiable architecture decisions

1. MCP transport state is not application state. LI MCP uses the stateless 2026-07-28 core; durable or cross-call state is represented by explicit handles/contracts owned by the application layer.
2. `server/discover` is authoritative protocol/capability discovery. Runtime Apple capability truth remains a separate LI MCP concern exposed through `local_capabilities`.
3. Every 2026-07-28 request is self-describing. Protocol version, client identity and client capabilities are handled per request rather than assumed from a session handshake.
4. HTTP routing/authorization may use `Mcp-Method` and `Mcp-Name`, but security decisions must still be validated against the parsed request and LI policy. Headers are routing hints/contracts, not sufficient authorization evidence by themselves.
5. Long-running or interactive work must use explicit protocol mechanisms: MRTR for input-required continuation and Tasks where task semantics are appropriate. Do not recreate hidden transport sessions.
6. List results are deterministic and cache-aware. Tool/resource/prompt catalogs must not vary accidentally by connection or unordered registry iteration.
7. Extensions are opt-in capabilities with explicit contracts. MCP Apps, Tasks and future extensions cannot bypass LI capability routing, policy, approvals, audit or GSA governance.
8. Deprecated Roots/Sampling/Logging are compatibility surfaces only. New LI architecture must not depend on them.
9. JSON Schema 2020-12 is the schema target for tool contracts and generated adapters.
10. Backward compatibility is deliberate and tested. Legacy MCP support must never contaminate the 2026-07-28 core with hidden session assumptions.

## Workstreams

### M0 — Protocol inventory and gap matrix

- Inventory current MCP SDK/version and all initialize/session assumptions.
- Locate `Mcp-Session-Id`, initialize/initialized, GET/DELETE transport paths, server-to-client request code, subscriptions, roots, sampling and logging dependencies.
- Inventory tool/resource/prompt list ordering and per-client variation.
- Inventory auth assumptions tied to connection/session identity.
- Produce source → protocol requirement → migration action → test evidence matrix.

Exit: every breaking 2026-07-28 delta maps to code/tests/docs or is explicitly not applicable.

### M1 — Stateless request core

- Implement/upgrade SDK support for 2026-07-28.
- Remove protocol-level initialize/session dependence on the modern path.
- Consume per-request protocol/client metadata.
- Return server identity metadata where appropriate.
- Implement structured unsupported-version behavior.
- Prove concurrent requests can land independently without shared transport session state.

Exit: a modern request is independently processable from its request envelope plus application-owned state.

### M2 — `server/discover` and two-layer capability truth

- Implement required `server/discover` behavior.
- Advertise supported protocol versions and protocol capabilities.
- Add deterministic cache metadata for discovery.
- Keep LI `local_capabilities` as runtime/provider truth: OS eligibility, model readiness, permissions, providers and capability IDs.
- Document why protocol capability discovery and machine runtime capability discovery are different layers.
- Never use self-reported client/server identity as a security principal.

Exit: clients can discover protocol shape without confusing it with Apple runtime eligibility.

### M3 — Header routing and authorization

- Support/validate `MCP-Protocol-Version`, `Mcp-Method` and `Mcp-Name` on Streamable HTTP.
- Ensure routing can occur without decoding arbitrary tool arguments.
- Cross-check headers against JSON-RPC body to prevent mismatch/smuggling behavior.
- Map method/name to LI policy before execution while retaining authoritative execution-time policy checks.
- Add negative tests for missing, malformed, duplicated and contradictory routing metadata.

Exit: routing becomes cheap and observable without weakening policy.

### M4 — Deterministic cacheable catalogs

- Make tools/list, resources/list and prompts/list deterministic.
- Define invalidation/version rules when runtime capabilities change.
- Emit cache hints/TTL/scope only when truthful.
- Prevent permission-sensitive or machine-sensitive catalogs from being cached with an unsafe scope.
- Stabilize schema serialization so upstream prompt caches do not churn from ordering noise.

Exit: repeated unchanged list/discovery calls are byte/semantic stable apart from explicitly non-stable metadata.

### M5 — MRTR and approval/input continuation

- Replace modern-path server→client request assumptions with Multi Round-Trip Requests.
- Represent missing user input/approval as `input_required` continuation.
- Bind returned input responses to the originating operation and validate freshness.
- Integrate LI automation approval policy and GSA/Obdurate authority checks.
- Ensure retry/re-entry is idempotent until the consequential commit boundary.
- Test cancellation, timeout, stale approval, altered arguments and replay.

Exit: interactive tools work over a stateless protocol without weakening approval semantics.

### M6 — Subscriptions and notifications

- Reconcile legacy GET/resource subscription behavior with `subscriptions/listen`.
- Separate request-scoped progress/messages from opted-in change subscriptions.
- Define which LI changes can generate list/resource notifications: provider availability, permission changes, model readiness and registry changes.
- Ensure notification content does not leak sensitive machine state.
- Prove reconnect and duplicate-delivery behavior is safe.

Exit: LI can communicate useful changes without restoring protocol sessions.

### M7 — Extensions framework

#### M7.1 Tasks
- Determine which LI operations genuinely need durable/long-running task semantics.
- Candidate operations: model download/readiness workflows only where controllable, long automation, evaluation runs, large local indexing/analysis.
- Define task state, cancellation, expiry, evidence and explicit application handles.
- Do not turn ordinary quick tool calls into tasks.

#### M7.2 MCP Apps
- Treat server-rendered UI as an optional projection, not the canonical application UI.
- Candidate LI surfaces: capability/permission inspection, approval explanation, evaluation evidence and local provider diagnostics.
- MCP Apps must consume the same capability/policy contracts as native clients.
- Never let an MCP App become an alternate privileged execution channel.

#### M7.3 Extension registry discipline
- Every extension has version/support metadata, tests, policy implications and graceful unsupported behavior.
- Unknown extensions do not silently alter execution semantics.

Exit: extensions add capability without creating a second architecture.

### M8 — Authorization 2026 hardening

- Reconcile current auth with RFC 9207 issuer validation requirements.
- Evaluate migration away from Dynamic Client Registration assumptions toward client metadata documents where applicable.
- Separate client display identity from authenticated principal/authority.
- Threat-model confused deputy, redirect/issuer confusion, metadata spoofing and header/body disagreement.
- Preserve local-first operation without inventing OAuth where no remote authorization boundary exists.

Exit: remote/authorized deployments meet modern MCP requirements while local stdio remains minimal and truthful.

### M9 — Schema 2020-12 and generated contracts

- Upgrade tool input/output schemas to JSON Schema 2020-12 semantics.
- Validate schemas produced from LI stable capability contracts and Apple Foundation Models tool adapters.
- Add round-trip schema tests and fixtures for structured generation.
- Reject unsupported schema constructs explicitly rather than degrading silently.

Exit: one authoritative schema model feeds MCP presentation, model tool adapters and validation.

### M10 — Deprecation containment

- Mark Roots, Sampling and Logging dependencies and compatibility shims.
- New work may not introduce architectural dependency on deprecated features.
- Replace sampling use with LI provider/model routing where LI owns inference.
- Replace protocol logging dependency with LI observability contracts.
- Treat roots as legacy client context only; do not make filesystem authority depend on it.
- Establish removal gates based on MCP deprecation window and supported-client telemetry/evidence.

Exit: deprecated MCP features can disappear without redesigning LI.

### M11 — GSA/Michelle integration

- Map MCP request identity/capabilities into GSA context without granting authority from self-reported metadata.
- Preserve Obdurate approval, capability authority, evidence and Historian recording across MRTR/task continuations.
- Make explicit handles DAID/evidence-friendly where durable identity matters.
- Expose protocol and runtime capability projections to Michelle separately.
- Ensure Michelle model routing can swap local providers without changing MCP capability contracts.
- Test denial, stale authority, replay, model swap and restart across LI ↔ GSA ↔ Michelle boundaries.

Exit: MCP modernization strengthens rather than bypasses governed execution.

### M12 — Compatibility matrix

Test at minimum:

- 2026-07-28 stdio client/server;
- 2026-07-28 Streamable HTTP client/server if HTTP remains supported;
- modern client against supported legacy server fallback;
- supported legacy client against LI compatibility path;
- macOS 13 portable tier;
- macOS 26 Foundation Models tier;
- macOS 27+ provider-neutral/multimodal tier;
- protocol discovery cache expiry;
- runtime capability changes after discovery;
- MRTR approval/input continuation;
- subscription reconnect;
- extension unsupported/disabled states.

Exit: compatibility behavior is intentional, documented and regression-tested.

### M13 — Dogfood and release gates

Dogfood through real clients before declaring the protocol upgrade complete.

Required scenarios:
- discover → list → deterministic tool call;
- local capability discovery distinct from protocol discovery;
- real Shortcut execution with approval where required;
- macOS 26 local generation and model tool call;
- input-required MRTR flow;
- denial and stale approval;
- long-running Task candidate if retained;
- capability/list change notification;
- restart between independent calls;
- legacy compatibility/fallback;
- malformed/mismatched headers;
- concurrent clients;
- README/examples generated from shipped truth.

Release blockers:
- simulated success;
- hidden transport-session dependency on modern path;
- non-deterministic catalogs without justification;
- security decisions based on self-reported client/server info;
- approval bypass through MRTR/Tasks/Apps;
- untested legacy fallback;
- docs claiming unsupported Apple or MCP capabilities.

## Sequencing

`M0 → M1 → M2 → M3/M4 → M5/M6 → M7/M8/M9/M10 → M11 → M12 → M13`

Apple capability work in existing Phases 0–6 continues, but protocol-facing implementations must use the contracts above as soon as M1–M4 stabilize.

## Evidence rule

No item is complete because code compiles or an SDK exposes an API. Completion requires executable evidence at the appropriate layer: unit contract, protocol fixture, integration test, physical-Mac test where Apple hardware/runtime behavior matters, security negative test, or dogfood transcript/evidence bundle.
