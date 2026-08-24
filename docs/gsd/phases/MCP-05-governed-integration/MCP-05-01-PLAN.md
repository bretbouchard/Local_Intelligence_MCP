---
phase: MCP-05-governed-integration
plan: 01
type: execute
wave: mcp-2026-07-28
depends_on: [MCP-04-01]
autonomous: false
files_modified: research-first
must_haves:
  truths:
    - GSA authority/evidence survives stateless continuation.
    - Michelle can reason about protocol and runtime capabilities without conflating them.
    - Model/provider swaps do not change MCP capability contracts.
---
# MCP-05-01 — GSA and Michelle Integration

## Tasks
1. Define the MCP request-context projection into GSA without granting authority from self-reported MCP metadata.
2. Carry capability authority, approvals, evidence identifiers and causal history across MRTR/task continuations using explicit application handles.
3. Make durable handles compatible with DAID/evidence identity where appropriate.
4. Expose separate projections for MCP protocol capabilities and LI runtime/provider capabilities to Michelle.
5. Ensure Michelle's model fabric/provider routing can swap Foundation Models/MLX/other permitted processors behind stable LI capability contracts.
6. Verify domain-native applications remain owners of their work; LI MCP supplies local capabilities rather than becoming a second world model.
7. Add cross-repo contract fixtures/tests for denial, stale authority, replay, restart, model swap and concurrent change.
8. Record any required GSA/Michelle companion changes as explicit plans in those repos rather than hidden LI TODOs.

## Done
The MCP upgrade composes cleanly with GSA governance and Michelle orchestration instead of bypassing or duplicating them.