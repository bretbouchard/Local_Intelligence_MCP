---
phase: MCP-00-protocol-reconciliation
plan: 01
type: execute
wave: mcp-2026-07-28
requires: [docs/gsd/MCP_2026_07_28_RECONCILIATION.md]
autonomous: true
files_modified: research-first
must_haves:
  truths:
    - Every MCP 2026-07-28 breaking delta is mapped to current LI code, tests or explicit non-applicability.
    - No protocol-session assumption remains unidentified.
---
# MCP-00-01 — Protocol Inventory and Gap Matrix

## Objective
Produce the authoritative migration inventory before changing transport behavior.

## Tasks
1. Record the currently pinned MCP Swift SDK/version and supported transports.
2. Find all initialize/initialized, session ID, transport GET/DELETE, connection-scoped capability and connection-scoped auth assumptions.
3. Find server→client request, roots, sampling, logging, resource subscription and notification dependencies.
4. Inspect tools/resources/prompts discovery for unstable ordering or per-connection variation.
5. Inspect authorization for any reliance on self-reported client identity or connection state.
6. Map each final 2026-07-28 change to source locations, required migration, test evidence and owner phase.
7. Check existing Apple 26/27 plans for assumptions invalidated by the stateless protocol.
8. Commit the resulting matrix as durable repo evidence; unresolved items become explicit plans/beads rather than prose TODOs.

## Verification
- Matrix covers all items in the reconciliation document.
- Repository searches for known legacy concepts are accounted for.
- A second agent can identify every protocol migration location without chat history.

## Done
The repository itself contains a complete, source-linked MCP migration map.