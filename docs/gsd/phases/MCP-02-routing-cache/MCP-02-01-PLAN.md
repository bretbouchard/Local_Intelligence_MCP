---
phase: MCP-02-routing-cache
plan: 01
type: execute
wave: mcp-2026-07-28
depends_on: [MCP-01-01]
autonomous: true
files_modified: research-first
must_haves:
  truths:
    - Header routing never weakens body validation or policy.
    - Catalog ordering and cache semantics are deterministic and privacy-safe.
---
# MCP-02-01 — Header Routing and Cacheable Catalogs

## Tasks
1. Support `MCP-Protocol-Version`, `Mcp-Method` and `Mcp-Name` for Streamable HTTP where that transport is shipped.
2. Reject/normalize malformed, duplicate and header/body contradictory routing data.
3. Permit cheap gateway/policy routing while re-validating authoritative policy at execution.
4. Make tools/list, resources/list, prompts/list and discovery output deterministically ordered.
5. Define cache TTL/scope and invalidation rules for registry and runtime capability changes.
6. Ensure permission- or machine-sensitive output is never marked with an unsafe cache scope.
7. Stabilize schema serialization to reduce prompt-cache churn.
8. Benchmark routing/discovery overhead against existing baseline.

## Done
LI's protocol surface is routable, cacheable and stable without leaking state or weakening authorization.