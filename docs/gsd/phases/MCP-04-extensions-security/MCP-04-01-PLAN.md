---
phase: MCP-04-extensions-security
plan: 01
type: execute
wave: mcp-2026-07-28
depends_on: [MCP-03-01]
autonomous: false
files_modified: research-first
must_haves:
  truths:
    - Extensions cannot bypass LI policy/capability routing.
    - Authorization follows 2026-07-28 hardening where applicable.
    - New architecture does not depend on deprecated MCP features.
---
# MCP-04-01 — Extensions, Authorization, Schema and Deprecations

## Tasks
1. Establish an extension registry contract with version/support/policy metadata and graceful unsupported behavior.
2. Evaluate MCP Apps for capability/permission inspection, approval explanation, evidence and diagnostics only where useful; keep native app UI canonical.
3. Ensure Tasks and Apps use the same LI capability router, permissions, approval and audit contracts as ordinary tools.
4. Reconcile remote authorization with RFC 9207 issuer validation and client metadata document direction where applicable.
5. Separate self-reported display identity from authenticated principal/authority.
6. Upgrade authoritative tool schemas/validators to JSON Schema 2020-12 and reuse them for Foundation Models tool adapters.
7. Inventory Roots/Sampling/Logging use; isolate compatibility shims and prohibit new dependencies.
8. Replace LI-owned sampling needs with LI provider/model routing and protocol logging needs with LI observability.
9. Threat-model issuer confusion, metadata spoofing, confused deputy, extension privilege escalation and schema ambiguity.

## Done
LI uses the new extension/security/schema model without creating alternate authority paths or future dependency on deprecated protocol features.