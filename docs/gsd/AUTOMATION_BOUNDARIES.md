# Apple Automation Boundaries: App Intents (Plan 2.2) and Accessibility (Plan 2.3)

**Date:** 2026-08-31 · **Decision:** documented boundary — no invented APIs.

## Plan 2.2 — App Intents capability investigation

**Finding:** Apple's App Intents framework exposes intents to the system (Siri,
Shortcuts, Spotlight, widgets) from *inside an owning app*. There is no supported
API for an external process to enumerate arbitrary installed App Intents and
invoke them generically. The supported external surface for intent-like
automation **is the Shortcuts database**, which LI MCP already covers genuinely
via the `shortcuts` CLI (`local_automation_list` / `local_automation_execute`).

**Decision:** do not implement a generic App Intents adapter. Document the
boundary instead (this file). Any future expansion must ride on a supported
surface (e.g. a user explicitly sharing specific intents as Shortcuts, which
then appear through the existing provider).

## Plan 2.3 — Accessibility fallback

**Finding:** macOS Accessibility automation (AXUIElement APIs) can drive other
apps' UI, but only for processes holding the Accessibility TCC permission, and
Apple explicitly reserves "Voice Control" as an end-user accessibility feature
with no external control API. The previous "voice_command" tool simulated both
recognition and execution (fabricated confidence scores); it now reports
`UNSUPPORTED` truthfully.

**Decision:** if UI automation is ever genuinely needed, it must be:

1. a **separate opt-in provider** (never presented as "Voice Control");
2. gated on a verified Accessibility grant surfaced in `local_capabilities`;
3. restricted to a narrow, documented action set with policy allow/deny and
   full audit evidence;
4. off by default in the shipped configuration.

None of these exist today, so no accessibility capability is advertised —
`local_capabilities` reports nothing for it, and clients get `UNSUPPORTED`
rather than a simulation.

## Related: automation safety (Plan 2.4, shipped 2026-08-31)

Real shortcut execution is wrapped by `SafetyGatedAutomationProvider`:
- `LI_AUTOMATION_ALLOWLIST` / `LI_AUTOMATION_DENYLIST` environment allow/deny;
- destructive-name classification (delete/erase/send/format/…) requires
  explicit `confirm: true` on `local_automation_execute`;
- every decision is audit-logged with the shortcut name and outcome;
- timeouts are clamped to a policy maximum;
- injection vectors (option-prefixed names, NUL bytes) are rejected before any
  process is spawned.
