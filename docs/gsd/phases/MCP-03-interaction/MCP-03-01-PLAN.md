---
phase: MCP-03-interaction
plan: 01
type: execute
wave: mcp-2026-07-28
depends_on: [MCP-02-01]
autonomous: false
files_modified: research-first
must_haves:
  truths:
    - Interactive approval/input works without protocol sessions.
    - Long-running work uses explicit task/application state.
    - Subscriptions cannot become a hidden session channel.
---
# MCP-03-01 — MRTR, Subscriptions and Tasks

## Tasks
1. Replace modern-path server→client interaction assumptions with MRTR input-required continuations.
2. Bind input/approval responses to originating operation, arguments, authority and freshness window.
3. Make pre-commit retry/re-entry idempotent; revalidate policy/world state immediately before consequential execution.
4. Integrate Obdurate/GSA approval evidence where governed execution is used.
5. Implement/reconcile `subscriptions/listen`; separate request-scoped progress/messages from opted-in change notifications.
6. Define privacy-safe notifications for registry/provider/model-readiness/permission changes.
7. Evaluate Tasks only for genuinely long-running LI operations; define task handles, state, cancellation, expiry and evidence.
8. Test cancellation, timeout, stale approval, replay, altered arguments, reconnect and duplicate notification delivery.

## Done
LI supports modern interactive and long-running workflows while remaining stateless at the protocol layer.