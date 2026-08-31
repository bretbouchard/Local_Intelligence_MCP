---
phase: MCP-06-compat-dogfood
plan: 01
type: execute
wave: mcp-2026-07-28
depends_on: [MCP-05-01]
autonomous: false
files_modified: research-first
must_haves:
  truths:
    - Modern and supported legacy paths have explicit executable evidence.
    - Apple OS tiers remain valid after protocol modernization.
    - Release is blocked by governance, truthfulness or compatibility regressions.
---
# MCP-06-01 — Compatibility, Dogfood and Release

## Tasks
1. Build protocol compatibility fixtures for modern stdio, modern HTTP if shipped, modern→legacy fallback and supported legacy→LI compatibility.
2. Run compatibility across macOS 13 portable, macOS 26 Foundation Models and macOS 27+ intelligence tiers.
3. Exercise discover/list/cache expiry/runtime capability change/MRTR/subscriptions/extensions and unsupported states.
4. Dogfood real deterministic tools, Shortcut execution, local generation, model tool calling, approval denial/staleness, restart and concurrent clients.
5. Run malformed/mismatched header and authorization negative suites.
6. Produce a release evidence bundle containing protocol, Apple runtime, security, governance and documentation-claim evidence.
7. Rewrite examples/README compatibility sections to match shipped behavior exactly.
8. Block release on simulated success, hidden modern session state, unsafe caching, authority from self-reported metadata, approval bypass, undocumented fallback or unsupported claims.

## Done
LI MCP 2026-07-28 support is proven in reality across its supported Apple tiers and governed integrations.