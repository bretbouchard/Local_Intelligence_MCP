# LI MCP Security Model — Threat Model, Risk Contracts, Compatibility

**GSD Plans 5.1/5.2/5.3.** Date: 2026-08-31. Non-negotiable invariants live in
`docs/gsd/MASTER_PLAN.md`; this document is the security-facing contract.

## 1. Threat model (Plan 5.1)

Adversaries: a malicious/compromised MCP client, a prompt-injected model, and
untrusted content flowing through deterministic tools.

| Threat | Mitigation (shipped) |
|--------|----------------------|
| Shell injection via shortcut names | Direct `Process` argv (no shell); `-`-prefixed and NUL-containing names rejected (`ShortcutsProvider.validateShortcutName`) |
| Destructive automation | `SafetyGatedAutomationProvider`: destructive-name classification requires `confirm: true`; allow/deny lists; every decision audit-logged; best-effort classification documented (`AUTOMATION_BOUNDARIES.md`) |
| Model-initiated side effects | Model-callable tool set is allowlist-per-request and restricted to read-only text capabilities; `local_automation_execute`/`local_generate` are structurally excluded (`AppleFoundationProvider26.supportedModelTools`); PCC pinned-only |
| Cross-class fallback (local→cloud) | Router never crosses provider classes; PCC is pinned-only and policy-disabled by default (`LI_ALLOW_PCC`) |
| Path/URL abuse in image tooling | Local file paths only; extension allowlist; 20 MB cap; decode failures are clean errors |
| Untrusted content in extraction | `local_extract` is pure pattern matching — it cannot return entities that are not in the input |
| Crash-as-DoS via malformed payloads | All JSON serialization guarded by `isValidJSONObject` before use (book.analyze regression); hostile timeouts/time values clamped and validated |
| PII leakage in summaries | Default `piiRedact: true` on text tools; hash mode uses real SHA-256 |
| Policy bypass via pinning | Pinning restricts to one provider — it can only narrow, never widen, what can serve a request |
| Data race | Provider/registry state behind actors, `let` configuration, locks where mutable state is unavoidable |

Known limitations (documented, accepted):
- Destructive-name classification is heuristic (name-based); the safety net is
  confirmation + audit, not semantic understanding of a shortcut's actions.
- `automationPermissions.automation` reports `false` until proven granted —
  conservative, not exhaustive.
- The `shortcuts` CLI's stderr is surfaced verbatim (not parsed) — locale-proof
  but less structured.

## 2. Permission and approval contracts (Plan 5.2)

Every side-effect capability declares: risk class, required permission, policy
check, and approval requirement. Denial is a first-class result
(`PERMISSION_DENIED` / `POLICY_DENIED`).

| Capability | Risk | Required permission | Policy check | Approval |
|------------|------|--------------------|--------------|----------|
| `local_capabilities` | none | — | — | — |
| `local_summarize`/`local_extract`/`local_classify` | none (deterministic) | — | — | — |
| `local_generate` | model output | — | provider availability + policy | — |
| `local_image_understand` | none (deterministic OCR) / model output (apple engine) | — | availability + policy | — |
| `local_automation_list` | low (read-only) | `.shortcuts` verified | CLI presence | — |
| `local_automation_execute` | **side effect** | `.shortcuts` verified | safety gate (allow/deny/destructive) | `confirm: true` for destructive names |
| `book.analyze`, `apple_*` text tools | none (deterministic) | `.systemInfo` convention | — | — |

Registry enforcement: `ToolsRegistry.validatePermissions` verifies real state
(AX API, CLI presence) before execution; unverifiable permission types deny by
default.

## 3. Cross-version compatibility (Plan 5.3)

| Tier | OS | Build lane | Evidence |
|------|----|-----------|----------|
| Portable (Tier 0/1) | macOS 13+ | deployment target `.macOS(.v13)`; FM/PCC/multimodal behind `#if canImport` + `@available` | unit suites; FoundationModels paths skip on older runtimes |
| Apple Intelligence | macOS 26+ | `@available(macOS 26.0, *)` providers | physical generation dogfood (this Mac) |
| Multimodal + PCC | macOS 27+ | `@available(macOS 27.0, *)` | live on this machine (macOS 27 arm64) |

Policy: new Apple APIs must be availability-gated and every gate must have a
truthful runtime status (`UNSUPPORTED`/`DISABLED`/`NOT_READY`) — a build may
not raise the runtime floor silently. CI note: physical Apple-intelligence
behavior requires Apple hardware runners; unit suites must remain green without
the model (they skip, never fake).
