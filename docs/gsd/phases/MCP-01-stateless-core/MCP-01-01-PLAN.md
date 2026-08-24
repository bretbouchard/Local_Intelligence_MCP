---
phase: MCP-01-stateless-core
plan: 01
type: execute
wave: mcp-2026-07-28
depends_on: [MCP-00-01]
autonomous: true
files_modified: research-first
must_haves:
  truths:
    - Modern MCP requests do not depend on initialize or protocol sessions.
    - server/discover and per-request metadata are implemented correctly.
    - LI runtime capability truth remains distinct from MCP protocol discovery.
---
# MCP-01-01 — Stateless Core and Discovery

## Tasks
1. Upgrade/adapt MCP SDK integration for protocol 2026-07-28 without raising LI's macOS deployment floor unnecessarily.
2. Implement the modern stateless request path and remove initialize/session dependence from that path.
3. Parse/validate per-request protocol version, client info and client capabilities.
4. Implement required `server/discover` with supported versions, protocol capabilities, server metadata and truthful cache hints.
5. Preserve `local_capabilities` as the separate runtime/provider capability surface.
6. Implement structured unsupported-version behavior and explicit legacy fallback boundaries.
7. Add concurrency tests proving independent requests do not share hidden transport state.
8. Add security tests proving self-reported client/server info cannot grant authority.

## Evidence
Protocol fixtures for discovery, direct inline request, unsupported version, concurrent calls and legacy fallback.

## Done
LI has a real 2026-07-28 stateless protocol core with clean separation between protocol discovery and machine capability truth.